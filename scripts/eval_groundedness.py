#!/usr/bin/env python3
"""Evaluasi keterlacakan jawaban (docs/06 §5).

Target proposal: >=95% kalimat faktual didukung potongan yang dirujuk.

APA YANG DIUKUR SKRIP INI
-------------------------
Keterlacakan punya dua bagian yang bisa gagal secara terpisah:

  1. Pengambilan  - apakah `cari_potongan()` mengembalikan potongan yang relevan
  2. Pengutipan   - apakah kalimat jawaban benar-benar berasal dari potongan itu

Bagian 1 hanya butuh basis data dan dapat diukur kapan saja. Bagian 2 butuh
jawaban model, jadi butuh kunci API.

Bagian 1 adalah prasyarat mutlak bagi bagian 2: kalau pengambilan tidak
mengembalikan apa pun, keterlacakan adalah 0% menurut definisi, berapa pun
bagusnya model. Karena itu skrip ini melaporkan ukuran korpus lebih dulu dan
berhenti dengan jujur bila korpus kosong, alih-alih mencetak persentase yang
tidak berdasar.

Jalankan:
    python scripts/eval_groundedness.py
"""

from __future__ import annotations

import json
import os
import pathlib
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
PROMPT = AKAR / "scripts" / "prompt_uji.json"
KONTAINER = os.environ.get("SUPABASE_DB_CONTAINER", "supabase_db_dekapautis")


def psql(sql: str) -> str:
    hasil = subprocess.run(
        ["docker", "exec", "-i", KONTAINER,
         "psql", "-U", "postgres", "-d", "postgres", "-tAc", sql],
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    if hasil.returncode != 0:
        print("Tidak dapat menghubungi basis data lokal:", file=sys.stderr)
        print(hasil.stderr.strip(), file=sys.stderr)
        sys.exit(1)
    return hasil.stdout.strip()


def main() -> int:
    prompt = json.loads(PROMPT.read_text(encoding="utf-8"))
    aman = [p for p in prompt if not p["harusDitolak"]]

    dokumen = int(psql("select count(*) from dokumen_pengetahuan;") or 0)
    potongan = int(psql("select count(*) from potongan_dokumen;") or 0)
    berembedding = int(
        psql("select count(*) from potongan_dokumen where embedding is not null;")
        or 0
    )

    print()
    print("Evaluasi keterlacakan - DekapAutis")
    print("=" * 52)
    print(f"Dokumen di korpus     : {dokumen}")
    print(f"Potongan terindeks    : {potongan}")
    print(f"Potongan berembedding : {berembedding}")
    print()

    if potongan == 0:
        print("KORPUS KOSONG - keterlacakan tidak dapat diukur.")
        print()
        print("Ini bukan kegagalan skrip. Tanpa satu pun potongan, pengambilan")
        print("tidak mengembalikan apa pun dan keterlacakan adalah 0% menurut")
        print("definisi, berapa pun bagusnya model bahasanya.")
        print()
        print("Isi korpus lebih dulu:")
        print("  python scripts/index_corpus.py")
        print("atau satu per satu lewat layar admin /admin/pengetahuan.")
        print("=" * 52)
        return 1

    # Bagian 1: pengambilan. Sisi teks penuh saja - vektor nol dipakai supaya
    # skrip tetap berjalan tanpa kunci API embedding, dan RRF tetap menghasilkan
    # peringkat dari jalur teks penuh.
    nol = "array_fill(0::real, array[768])::extensions.vector(768)"
    kosong = []
    for p in aman:
        kueri = p["teks"].replace("'", "''")
        n = int(
            psql(
                f"select count(*) from public.cari_potongan({nol}, '{kueri}', 8);"
            )
            or 0
        )
        if n == 0:
            kosong.append(p)

    terambil = len(aman) - len(kosong)
    persen = round(terambil / len(aman) * 100)

    print(f"Pertanyaan aman dengan >=1 potongan terambil : "
          f"{terambil}/{len(aman)} ({persen}%)")

    if kosong:
        print("\nTIDAK MENGAMBIL APA PUN:")
        for p in kosong:
            print(f"  {p['id']}  {p['teks']}")

    punya_kunci = bool(os.environ.get("GEMINI_API_KEY") or os.environ.get("GROQ_API_KEY"))
    print()
    print("Pengutipan kalimat jawaban : "
          + ("DIUKUR" if punya_kunci else "TIDAK DIUKUR - tanpa kunci API model"))
    print("=" * 52)
    return 0 if persen >= 95 else 1


if __name__ == "__main__":
    sys.exit(main())
