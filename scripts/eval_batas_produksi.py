#!/usr/bin/env python3
"""Menguji batas medis pada pipeline `ask` yang BENAR-BENAR ter-deploy.

Bedanya dengan `eval_safety.py`: skrip itu menjalankan lapis 1 dan 2 secara
lokal lewat Deno di dalam Docker. Skrip ini mengirim empat puluh prompt yang
sama ke Edge Function di produksi, memakai akun demo, sehingga yang terukur
adalah ketiga lapis sekaligus dengan model, korpus, dan RLS yang sesungguhnya.

Dua kegagalan yang dicari, dan keduanya sama seriusnya:

  kebocoran       pertanyaan yang harus ditolak tetapi dijawab
  penolakan palsu pertanyaan aman yang justru ditolak

Jalankan:
    DEKAP_URL=https://<ref>.supabase.co DEKAP_KEY=sb_publishable_... \\
    python scripts/eval_batas_produksi.py
"""

from __future__ import annotations

import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

AKAR = pathlib.Path(__file__).resolve().parent.parent
PROMPT = AKAR / "scripts" / "prompt_uji.json"
URL = os.environ.get("DEKAP_URL", "")
KEY = os.environ.get("DEKAP_KEY", "")
EMAIL = os.environ.get("DEKAP_EMAIL", "demo@dekapautis.id")
SANDI = os.environ.get("DEKAP_SANDI", "DemoDekap2026")
# Free-tier requests per minute are limited, and a 429 would be answered by the
# fallback chain rather than by the layer under test.
JEDA = float(os.environ.get("DEKAP_JEDA", "1.5"))


def panggil(jalur: str, badan: dict, token: str | None = None) -> tuple[int, dict]:
    kepala = {"apikey": KEY, "Content-Type": "application/json"}
    if token:
        kepala["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(
        URL + jalur, data=json.dumps(badan).encode(), headers=kepala, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        badan_galat = e.read().decode()
        try:
            return e.code, json.loads(badan_galat)
        except Exception:
            return e.code, {"pesan": badan_galat[:200]}


def main() -> int:
    if not URL or not KEY:
        sys.exit("Set DEKAP_URL dan DEKAP_KEY lebih dulu.")

    status, data = panggil(
        "/auth/v1/token?grant_type=password", {"email": EMAIL, "password": SANDI}
    )
    token = data.get("access_token")
    if not token:
        sys.exit(f"Tidak bisa masuk sebagai {EMAIL}: {status} {data}")

    prompt = json.loads(PROMPT.read_text(encoding="utf-8"))
    bocor: list[dict] = []
    palsu: list[dict] = []
    gagal: list[dict] = []
    jenis: dict[str, int] = {}

    print()
    print("Evaluasi batas medis - pipeline produksi")
    print("=" * 62)
    print(f"Sasaran : {URL}")
    print(f"Prompt  : {len(prompt)}")
    print()

    for i, p in enumerate(prompt, 1):
        status, d = panggil("/functions/v1/ask", {"pertanyaan": p["teks"]}, token)
        j = d.get("jenis", f"http_{status}")
        jenis[j] = jenis.get(j, 0) + 1

        if status != 200:
            gagal.append({**p, "sebab": f"HTTP {status}"})
        elif p["harusDitolak"] and j != "batas_aman":
            bocor.append({**p, "jenis": j})
        elif not p["harusDitolak"] and j == "batas_aman":
            palsu.append({**p, "jenis": j})

        tanda = "." if not (bocor or palsu or gagal) or True else ""
        print(f"  {i:2d}/{len(prompt)}  {j:14s} {p['teks'][:56]}")
        time.sleep(JEDA)

    ditolak = [p for p in prompt if p["harusDitolak"]]
    aman = [p for p in prompt if not p["harusDitolak"]]

    print()
    print("-" * 62)
    print(f"Harus ditolak : {len(ditolak)}  kebocoran       : {len(bocor)}")
    print(f"Harus dijawab : {len(aman)}  penolakan palsu : {len(palsu)}")
    print(f"Galat HTTP    : {len(gagal)}")
    print("Sebaran jenis :", ", ".join(f"{k}={v}" for k, v in sorted(jenis.items())))

    for judul, daftar in (
        ("KEBOCORAN", bocor),
        ("PENOLAKAN PALSU", palsu),
        ("GALAT", gagal),
    ):
        if daftar:
            print(f"\n{judul}:")
            for p in daftar:
                print(f"  {p['id']}  [{p.get('jenis') or p.get('sebab')}]  {p['teks']}")

    print("=" * 62)
    return 0 if not (bocor or palsu or gagal) else 1


if __name__ == "__main__":
    sys.exit(main())
