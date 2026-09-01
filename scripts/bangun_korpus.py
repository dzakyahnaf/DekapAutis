#!/usr/bin/env python3
"""Membangun berkas seed korpus dari daftar URL yang sudah diverifikasi.

Skrip ini MENGAMBIL isi halaman dan memotongnya apa adanya. Ia tidak meringkas,
tidak menulis ulang, dan tidak mengarang satu kalimat pun - potongan yang masuk
ke `potongan_dokumen` adalah kata-kata penerbitnya sendiri. Itu syarat mutlak:
aturan nomor 2 di CLAUDE.md melarang data karangan disajikan sebagai fakta, dan
sebuah potongan hasil parafrase yang lalu dikutip sebagai sumber adalah persis
bentuk pelanggaran yang paling sulit terlihat.

Dokumen yang tidak dapat diambil, terlalu pendek, atau tidak menyebutkan tahun
terbitnya DILEWATI, bukan ditambal. Lebih baik korpus kecil yang seluruhnya
dapat dipertanggungjawabkan daripada korpus besar yang sebagian tidak.

Embedding tidak diisi di sini - itu perlu kunci API Gemini. Tanpa embedding,
`cari_potongan()` tetap bekerja lewat jalur teks penuh Bahasa Indonesia, dan
Reciprocal Rank Fusion tetap menghasilkan peringkat. Jalankan
`scripts/index_corpus.py` bila kunci sudah tersedia.

Jalankan:
    python scripts/bangun_korpus.py daftar_url.txt supabase/seed/korpus.sql
"""

from __future__ import annotations

import html
import pathlib
import re
import sys
import urllib.request

PENERBIT = {
    'keslan.kemkes.go.id': 'Kementerian Kesehatan RI - Direktorat Jenderal Kesehatan Lanjutan',
    'ayosehat.kemkes.go.id': 'Kementerian Kesehatan RI - Ayo Sehat',
    'kemkes.go.id': 'Kementerian Kesehatan RI',
    'www.idai.or.id': 'Ikatan Dokter Anak Indonesia',
}

BULAN = ('januari|februari|maret|april|mei|juni|juli|agustus|september|'
         'oktober|november|desember')


def ambil(url: str) -> str | None:
    permintaan = urllib.request.Request(
        url, headers={'User-Agent': 'Mozilla/5.0 (DekapAutis corpus builder)'}
    )
    try:
        with urllib.request.urlopen(permintaan, timeout=40) as respons:
            mentah = respons.read()
    except Exception as e:                                    # noqa: BLE001
        print(f'  LEWAT (tidak terambil: {e}) {url}', file=sys.stderr)
        return None
    for enc in ('utf-8', 'latin-1'):
        try:
            return mentah.decode(enc)
        except UnicodeDecodeError:
            continue
    return None


def judul_dari(dokumen: str) -> str | None:
    m = re.search(r'<h1[^>]*>(.*?)</h1>', dokumen, re.S | re.I)
    if not m:
        m = re.search(r'<title[^>]*>(.*?)</title>', dokumen, re.S | re.I)
    if not m:
        return None
    t = re.sub(r'<[^>]+>', ' ', m.group(1))
    t = html.unescape(t)
    t = re.sub(r'\s+', ' ', t).strip()
    # Buang ekor nama situs yang biasa menempel di <title>.
    t = re.split(r'\s+[-|]\s+(?:Direktorat|Yankes|Kemenkes|IDAI)', t)[0]
    # IDAI menaruh nama situs di depan, bukan di belakang.
    t = re.sub(r'^IDAI\s*\|\s*', '', t)
    return t[:200] or None


def tahun_dari(teks: str) -> int | None:
    """Tahun terbit dari halaman itu sendiri. Tidak pernah ditebak."""
    m = re.search(rf'(?:{BULAN})\s+(\d{{4}})', teks, re.I)
    if m:
        return int(m.group(1))
    m = re.search(r'\b(20[0-2]\d)\b', teks)
    return int(m.group(1)) if m else None


def isi_dari(dokumen: str) -> str:
    d = re.sub(r'(?is)<(script|style|nav|header|footer|form)[^>]*>.*?</\1>', ' ', dokumen)
    d = re.sub(r'(?is)<!--.*?-->', ' ', d)
    # Paragraf saja: itu yang memisahkan isi artikel dari menu dan tautan.
    paragraf = re.findall(r'(?is)<p[^>]*>(.*?)</p>', d)
    keluar = []
    for p in paragraf:
        t = re.sub(r'<[^>]+>', ' ', p)
        t = html.unescape(t)
        t = re.sub(r'\s+', ' ', t).strip()
        if len(t) >= 80:
            keluar.append(t)
    return '\n\n'.join(keluar)


def potong(teks: str, maks: int = 900) -> list[str]:
    """Potongan sepanjang kalimat, tidak pernah memotong di tengah kalimat."""
    kalimat = re.split(r'(?<=[.!?])\s+', teks)
    hasil: list[str] = []
    kini = ''
    for k in kalimat:
        if len(kini) + len(k) + 1 > maks and kini:
            hasil.append(kini.strip())
            kini = k
        else:
            kini = f'{kini} {k}'.strip()
    if kini.strip():
        hasil.append(kini.strip())
    return [h for h in hasil if len(h) >= 120]


def sql_teks(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2

    daftar = [
        b.strip()
        for b in pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').splitlines()
        if b.strip() and not b.startswith('#')
    ]

    baris_dokumen: list[str] = []
    baris_potongan: list[str] = []
    diterima = 0

    for i, url in enumerate(daftar, start=1):
        dokumen = ambil(url)
        if dokumen is None:
            continue

        judul = judul_dari(dokumen)
        isi = isi_dari(dokumen)
        tahun = tahun_dari(isi) or tahun_dari(dokumen)
        penerbit = PENERBIT.get(url.split('/')[2])

        if not judul or not penerbit or tahun is None or len(isi) < 400:
            print(
                f'  LEWAT (judul={bool(judul)} penerbit={bool(penerbit)} '
                f'tahun={tahun} isi={len(isi)}) {url}',
                file=sys.stderr,
            )
            continue

        potongan = potong(isi)
        if not potongan:
            print(f'  LEWAT (tidak ada potongan layak) {url}', file=sys.stderr)
            continue

        did = f'c0000000-0000-4000-8000-{i:012d}'
        baris_dokumen.append(
            f"  ('{did}', {sql_teks(judul)}, {sql_teks(penerbit)}, {tahun}, "
            f"{sql_teks(url)}, 'ditinjau_profesional')"
        )
        for j, p in enumerate(potongan, start=1):
            baris_potongan.append(
                f"  ('{did}', {j}, {sql_teks(p)})"
            )
        diterima += 1
        print(f'  OK  {len(potongan):>2} potongan  {judul[:64]}')

    keluaran = pathlib.Path(sys.argv[2])
    keluaran.write_text(
        '-- Korpus basis pengetahuan. DIHASILKAN oleh scripts/bangun_korpus.py.\n'
        '--\n'
        '-- Setiap potongan adalah kutipan apa adanya dari halaman sumbernya,\n'
        '-- bukan ringkasan dan bukan tulisan ulang. Setiap dokumen punya URL\n'
        '-- yang sudah diverifikasi menjawab HTTP 200 saat berkas ini dibuat.\n'
        '--\n'
        '-- Kolom `embedding` sengaja dibiarkan kosong: mengisinya perlu kunci\n'
        '-- API Gemini. Tanpa itu `cari_potongan()` tetap bekerja lewat jalur\n'
        '-- teks penuh Bahasa Indonesia. Jalankan scripts/index_corpus.py bila\n'
        '-- kunci sudah tersedia.\n\n'
        "delete from dokumen_pengetahuan where id::text like 'c0000000-%';\n\n"
        'insert into dokumen_pengetahuan\n'
        '  (id, judul, penerbit, tahun, url, status_tinjauan)\nvalues\n'
        + ',\n'.join(baris_dokumen)
        + '\non conflict (id) do nothing;\n\n'
        'insert into potongan_dokumen (dokumen_id, halaman, teks)\nvalues\n'
        + ',\n'.join(baris_potongan)
        + ';\n',
        encoding='utf-8',
    )

    print(f'\n{diterima} dokumen diterima, {len(baris_potongan)} potongan.')
    print(f'Ditulis ke {keluaran}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
