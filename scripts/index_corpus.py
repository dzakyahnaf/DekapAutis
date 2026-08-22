#!/usr/bin/env python3
"""Chunk, embed, and load the knowledge corpus.

Reads a CSV manifest of real documents, splits each into overlapping chunks,
embeds them with Gemini, and writes them to dokumen_pengetahuan and
potongan_dokumen.

Idempotent by design: running it twice must not duplicate a chunk. Documents are
keyed on their URL and chunks on (dokumen_id, halaman, ordinal), so a re-run
updates in place. docs/07 §6 requires this, and it matters more than it sounds -
a corpus quietly doubled makes every retrieval score meaningless.

This script cannot invent the corpus. Forty real Indonesian documents with
openable URLs is human work: Kemenkes, IDAI, WHO in Indonesian, open-access
journals, professional bodies. If a judge opens one link and the page is gone,
the credibility of the whole RAG pillar goes with it - which costs far more than
a small corpus does.

Manifest columns (scripts/korpus.csv):

    judul,penerbit,tahun,url,berkas,status_tinjauan

`berkas` points at a local .txt or .md holding the extracted text. Keep the
extraction step manual and visible: a silent PDF scrape that mangles a table is
how wrong health text ends up in a corpus nobody re-reads.

Usage:
    python scripts/index_corpus.py --manifes scripts/korpus.csv
    python scripts/index_corpus.py --manifes scripts/korpus.csv --kering
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

# 600-800 tokens with 100 overlap (docs/04 §2). Indonesian averages roughly four
# characters per token, so the character budget is derived rather than guessed.
KARAKTER_PER_TOKEN = 4
TARGET_TOKEN = 700
TUMPANG_TINDIH_TOKEN = 100
TARGET_KARAKTER = TARGET_TOKEN * KARAKTER_PER_TOKEN
TUMPANG_KARAKTER = TUMPANG_TINDIH_TOKEN * KARAKTER_PER_TOKEN

DIMENSI = 768  # Locked. Changing it means re-embedding everything.

STATUS_SAH = {"menunggu", "ditinjau_profesional", "ditolak"}


@dataclass
class Dokumen:
    judul: str
    penerbit: str
    tahun: int
    url: str
    berkas: Path
    status_tinjauan: str


def baca_manifes(path: Path) -> list[Dokumen]:
    wajib = {"judul", "penerbit", "tahun", "url", "berkas"}
    dokumen: list[Dokumen] = []
    with path.open(encoding="utf-8", newline="") as f:
        pembaca = csv.DictReader(f)
        hilang = wajib - set(pembaca.fieldnames or [])
        if hilang:
            sys.exit(f"Manifes kekurangan kolom: {', '.join(sorted(hilang))}")
        for i, baris in enumerate(pembaca, start=2):
            status = (baris.get("status_tinjauan") or "menunggu").strip()
            if status not in STATUS_SAH:
                sys.exit(f"Baris {i}: status_tinjauan '{status}' tidak dikenal")
            url = baris["url"].strip()
            if not url.startswith(("http://", "https://")):
                sys.exit(f"Baris {i}: URL harus dapat dibuka, bukan '{url}'")
            berkas = Path(baris["berkas"].strip())
            if not berkas.is_file():
                sys.exit(f"Baris {i}: berkas teks tidak ditemukan: {berkas}")
            dokumen.append(
                Dokumen(
                    judul=baris["judul"].strip(),
                    penerbit=baris["penerbit"].strip(),
                    tahun=int(baris["tahun"]),
                    url=url,
                    berkas=berkas,
                    status_tinjauan=status,
                )
            )
    return dokumen


def potong(teks: str) -> list[str]:
    """Split on paragraph boundaries, never mid-sentence.

    A chunk cut through the middle of a sentence retrieves badly and quotes
    worse - and the Source Panel shows the chunk verbatim, so a mangled one is
    visible to the reader.
    """
    paragraf = [p.strip() for p in re.split(r"\n\s*\n", teks) if p.strip()]
    potongan: list[str] = []
    sekarang = ""

    for p in paragraf:
        if len(sekarang) + len(p) + 2 <= TARGET_KARAKTER:
            sekarang = f"{sekarang}\n\n{p}" if sekarang else p
            continue
        if sekarang:
            potongan.append(sekarang)
            ekor = sekarang[-TUMPANG_KARAKTER:]
            # Start the overlap at a sentence boundary where one is available.
            titik = ekor.find(". ")
            sekarang = (ekor[titik + 2 :] if titik != -1 else ekor) + "\n\n" + p
        else:
            # A single paragraph longer than the budget: cut it, with overlap.
            for i in range(0, len(p), TARGET_KARAKTER - TUMPANG_KARAKTER):
                potongan.append(p[i : i + TARGET_KARAKTER])
            sekarang = ""

    if sekarang:
        potongan.append(sekarang)
    return [p for p in potongan if len(p.strip()) > 80]


def embed(teks: str, kunci: str) -> list[float]:
    permintaan = urllib.request.Request(
        "https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-embedding-001:embedContent",
        data=json.dumps(
            {
                "content": {"parts": [{"text": teks}]},
                "outputDimensionality": DIMENSI,
                "taskType": "RETRIEVAL_DOCUMENT",
            }
        ).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": kunci},
        method="POST",
    )
    try:
        with urllib.request.urlopen(permintaan, timeout=30) as r:
            vektor = json.loads(r.read())["embedding"]["values"]
    except urllib.error.HTTPError as e:
        sys.exit(f"Gemini menjawab {e.code}: {e.read().decode()[:300]}")

    if len(vektor) != DIMENSI:
        sys.exit(f"Dimensi embedding {len(vektor)}, seharusnya {DIMENSI}")

    # Truncated Matryoshka outputs are not unit length, and pgvector's cosine
    # distance assumes they are. Normalise here so the stored corpus and the
    # query vector are measured on the same scale.
    panjang = sum(x * x for x in vektor) ** 0.5
    return [x / panjang for x in vektor] if panjang else vektor


def sql_literal(v: str) -> str:
    return "'" + v.replace("'", "''") + "'"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--manifes", type=Path, default=Path("scripts/korpus.csv"))
    p.add_argument(
        "--keluaran",
        type=Path,
        default=Path("supabase/seed/korpus.sql"),
        help="Berkas SQL yang dihasilkan, siap dijalankan psql.",
    )
    p.add_argument(
        "--kering",
        action="store_true",
        help="Hitung dan potong saja, tanpa memanggil API embedding.",
    )
    argumen = p.parse_args()

    kunci = os.environ.get("GEMINI_API_KEY")
    if not argumen.kering and not kunci:
        sys.exit(
            "GEMINI_API_KEY belum diset. Jalankan dengan --kering untuk "
            "memeriksa manifes dan pemotongan tanpa memanggil API."
        )

    dokumen = baca_manifes(argumen.manifes)
    print(f"{len(dokumen)} dokumen di manifes")
    if len(dokumen) < 40:
        print(
            f"  PERINGATAN: PLAN.md F5 meminta minimal 40 dokumen nyata, "
            f"baru ada {len(dokumen)}."
        )

    baris_sql: list[str] = [
        "-- Dihasilkan oleh scripts/index_corpus.py. Jangan disunting tangan.",
        "-- Idempoten: dokumen dikunci pada URL, potongan pada (dokumen, halaman, urutan).",
        "begin;",
    ]
    total_potongan = 0

    for d in dokumen:
        teks = d.berkas.read_text(encoding="utf-8")
        potongan = potong(teks)
        total_potongan += len(potongan)
        print(f"  {d.judul[:52]:<52} {len(potongan):>3} potongan")

        baris_sql.append(
            "insert into dokumen_pengetahuan (judul, penerbit, tahun, url, status_tinjauan)\n"
            f"values ({sql_literal(d.judul)}, {sql_literal(d.penerbit)}, {d.tahun}, "
            f"{sql_literal(d.url)}, {sql_literal(d.status_tinjauan)})\n"
            "on conflict (url) do update set judul = excluded.judul, "
            "penerbit = excluded.penerbit, tahun = excluded.tahun, "
            "status_tinjauan = excluded.status_tinjauan;"
        )
        # Re-indexing replaces this document's chunks rather than adding to them.
        baris_sql.append(
            "delete from potongan_dokumen where dokumen_id = "
            f"(select id from dokumen_pengetahuan where url = {sql_literal(d.url)});"
        )

        for i, isi in enumerate(potongan, start=1):
            vektor = (
                "null"
                if argumen.kering
                else "'" + json.dumps(embed(isi, kunci or "")) + "'::vector(768)"
            )
            baris_sql.append(
                "insert into potongan_dokumen (dokumen_id, halaman, teks, embedding)\n"
                f"values ((select id from dokumen_pengetahuan where url = {sql_literal(d.url)}), "
                f"{i}, {sql_literal(isi)}, {vektor});"
            )

    baris_sql += ["analyze potongan_dokumen;", "commit;"]
    argumen.keluaran.parent.mkdir(parents=True, exist_ok=True)
    argumen.keluaran.write_text("\n\n".join(baris_sql) + "\n", encoding="utf-8")

    print(f"\n{total_potongan} potongan ditulis ke {argumen.keluaran}")
    if argumen.kering:
        print("Mode kering: embedding kosong. Jalankan tanpa --kering untuk memuat.")
    else:
        print("Muat dengan: psql \"$SUPABASE_DB_URL\" -f " + str(argumen.keluaran))


if __name__ == "__main__":
    main()
