#!/usr/bin/env python3
"""Mengisi embedding untuk potongan korpus yang belum punya vektor.

KENAPA SKRIP INI ADA
--------------------
Korpus produksi (31 dokumen, 190 potongan) dimuat oleh `bangun_korpus.py`
tanpa kunci API, jadi kolom `embedding` seluruhnya NULL. Akibatnya pencarian
"hibrida" di `cari_potongan()` selama ini hanya berjalan di sisi teks penuh;
sisi pgvector tidak pernah menyumbang apa pun. `index_corpus.py` tidak bisa
dipakai untuk memperbaikinya karena ia membangun ulang korpus dari nol.

Skrip ini hanya mengisi yang kosong. Idempoten: menjalankannya dua kali tidak
mengubah apa pun pada putaran kedua.

HARUS SAMA DENGAN SISI KUERI
----------------------------
`_shared/llm.ts` meng-embed pertanyaan dengan gemini-embedding-001, 768
dimensi, lalu menormalkan vektornya. Potongan di sini memakai model dan dimensi
yang sama, dengan taskType RETRIEVAL_DOCUMENT, dan dinormalkan dengan cara yang
sama. Kalau salah satunya berbeda, jarak kosinus membandingkan dua ruang yang
tidak sejajar dan peringkatnya tidak bermakna.

Jalankan:
    GEMINI_API_KEY=... DEKAP_DB_URL=postgresql://... python scripts/embed_potongan.py
"""

from __future__ import annotations

import json
import math
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

MODEL = "gemini-embedding-001"
DIMENSI = 768  # Terkunci ke kolom vector(768).
PER_BATCH = 90  # batchEmbedContents menerima sampai 100 permintaan.


def psql_bin() -> str:
    for kandidat in (
        shutil.which("psql"),
        r"C:\Program Files\PostgreSQL\18\bin\psql.exe",
        r"C:\Program Files\PostgreSQL\17\bin\psql.exe",
    ):
        if kandidat and os.path.exists(kandidat):
            return kandidat
    sys.exit("psql tidak ditemukan.")


def psql(db: str, sql: str, stdin: str | None = None) -> str:
    hasil = subprocess.run(
        [psql_bin(), db, "-v", "ON_ERROR_STOP=1", "-tA", "-c", sql]
        if stdin is None
        else [psql_bin(), db, "-v", "ON_ERROR_STOP=1", "-tA"],
        input=stdin,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if hasil.returncode != 0:
        sys.exit("psql gagal:\n" + hasil.stderr.strip())
    return hasil.stdout.strip()


def normalkan(v: list[float]) -> list[float]:
    panjang = math.sqrt(sum(x * x for x in v)) or 1.0
    return [x / panjang for x in v]


def embed_batch(kunci: str, teks: list[str]) -> list[list[float]]:
    badan = {
        "requests": [
            {
                "model": f"models/{MODEL}",
                "content": {"parts": [{"text": t}]},
                "taskType": "RETRIEVAL_DOCUMENT",
                "outputDimensionality": DIMENSI,
            }
            for t in teks
        ]
    }
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:batchEmbedContents",
        data=json.dumps(badan).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": kunci},
        method="POST",
    )
    for percobaan in range(4):
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                data = json.loads(r.read())
            vektor = [e["values"] for e in data["embeddings"]]
            if any(len(v) != DIMENSI for v in vektor):
                sys.exit(f"Dimensi tidak {DIMENSI}. Jangan lanjutkan.")
            return [normalkan(v) for v in vektor]
        except urllib.error.HTTPError as e:
            # 429 berarti kuota per menit habis; tunggu lalu coba lagi.
            if e.code == 429 and percobaan < 3:
                time.sleep(20 * (percobaan + 1))
                continue
            sys.exit(f"Gemini menolak ({e.code}): {e.read().decode()[:300]}")
    sys.exit("Gemini terus menolak karena kuota.")


def main() -> int:
    kunci = os.environ.get("GEMINI_API_KEY", "")
    db = os.environ.get("DEKAP_DB_URL", "")
    if not kunci or not db:
        sys.exit("Set GEMINI_API_KEY dan DEKAP_DB_URL lebih dulu.")

    baris = json.loads(
        psql(
            db,
            "select coalesce(json_agg(json_build_object('id', id, 'teks', teks) "
            "order by id), '[]') from potongan_dokumen where embedding is null;",
        )
        or "[]"
    )
    total = int(psql(db, "select count(*) from potongan_dokumen;") or 0)
    print(f"Potongan: {total}, belum bervektor: {len(baris)}")
    if not baris:
        print("Tidak ada yang perlu diisi.")
        return 0

    selesai = 0
    for i in range(0, len(baris), PER_BATCH):
        potong = baris[i : i + PER_BATCH]
        vektor = embed_batch(kunci, [b["teks"] for b in potong])
        perintah = ["begin;"]
        for b, v in zip(potong, vektor):
            literal = "[" + ",".join(f"{x:.7f}" for x in v) + "]"
            perintah.append(
                f"update potongan_dokumen set embedding = '{literal}' "
                f"where id = '{b['id']}' and embedding is null;"
            )
        perintah.append("commit;")
        psql(db, "", stdin="\n".join(perintah))
        selesai += len(potong)
        print(f"  {selesai}/{len(baris)} terisi")

    sisa = int(
        psql(db, "select count(*) from potongan_dokumen where embedding is null;")
        or 0
    )
    print(f"Selesai. Belum bervektor: {sisa}")
    return 0 if sisa == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
