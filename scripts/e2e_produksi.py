#!/usr/bin/env python3
"""Menyusuri naskah demo final terhadap PRODUKSI, lewat API yang dipakai aplikasi.

Setiap pemeriksaan di sini setara dengan satu ketukan pada demo: masuk sebagai
demo, menyinkronkan jadwal, mencatat respons, membuka laporan, membagikannya,
menulis tanggapan sebagai profesional, sampai memeriksa bahwa akun anonim
ditolak RLS. Test Flutter memakai fake dan pemeriksaan SQL bicara langsung ke
Postgres; tidak ada satu pun yang melewati PostgREST, Edge Function, RLS, dan
model sekaligus. Berkas ini yang melakukannya.

Semua tulisan mendarat di akun demo dan dibersihkan oleh reset harian, yang
dipanggil di langkah terakhir.

Jalankan sebelum gladi dan pagi hari final:
    DEKAP_URL=https://<ref>.supabase.co DEKAP_KEY=sb_publishable_... \\
    python scripts/e2e_produksi.py
"""

from __future__ import annotations

import datetime
import json
import os
import sys
import urllib.error
import urllib.request
import uuid

URL = os.environ.get("DEKAP_URL", "")
KEY = os.environ.get("DEKAP_KEY", "")
ANAK = "d0000001-1111-4000-8000-000000000001"
PRO = "d0000000-0002-4000-8000-000000000002"
LAPORAN_DIBAGIKAN = "d0000001-3000-4000-8000-000000000001"
LAPORAN_BELUM = "d0000001-3000-4000-8000-000000000002"
WIB = datetime.timezone(datetime.timedelta(hours=7))
HARI = datetime.datetime.now(WIB).date().isoformat()
MULAI = (datetime.datetime.now(WIB).date() - datetime.timedelta(days=27)).isoformat()

hasil: list[bool] = []


def minta(metode, jalur, token=None, badan=None, prefer=None):
    kepala = {"apikey": KEY, "Content-Type": "application/json"}
    if token:
        kepala["Authorization"] = f"Bearer {token}"
    if prefer:
        kepala["Prefer"] = prefer
    data = json.dumps(badan).encode() if badan is not None else None
    req = urllib.request.Request(URL + jalur, data=data, method=metode, headers=kepala)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            teks = r.read().decode()
            return r.status, (json.loads(teks) if teks else None)
    except urllib.error.HTTPError as e:
        teks = e.read().decode()
        try:
            return e.code, json.loads(teks)
        except Exception:
            return e.code, teks


def cek(nama, syarat, rincian=""):
    hasil.append(bool(syarat))
    print(f"  [{'LULUS' if syarat else 'GAGAL'}] {nama}" + (f"  - {rincian}" if rincian else ""))


def masuk(email, sandi="DemoDekap2026"):
    s, d = minta("POST", "/auth/v1/token?grant_type=password",
                 badan={"email": email, "password": sandi})
    d = d or {}
    return d.get("access_token"), (d.get("user") or {}).get("id")


def main() -> int:
    if not URL or not KEY:
        sys.exit("Set DEKAP_URL dan DEKAP_KEY lebih dulu.")

    # Reset first as well as last. Anything an earlier run left behind - a
    # plan from "Susun rencana", a report written by the narrative test - would
    # otherwise be counted as if the seed had produced it, and the row counts
    # below would be wrong for a reason that has nothing to do with the product.
    print("\n== RESET AWAL ==")
    s, d = minta("GET", "/functions/v1/keep-alive", KEY)
    demo = (d or {}).get("demo", {}) if isinstance(d, dict) else {}
    cek("akun demo dikembalikan ke keadaan seed",
        s == 200 and demo.get("aktivitas_hari_ini") == 5, json.dumps(demo))

    print("\n== PENGASUH ==")
    tok, uid = masuk("demo@dekapautis.id")
    cek("masuk sebagai demo", tok)
    if not tok:
        return 1

    s, d = minta("GET", "/rest/v1/pengguna?select=peran,nama,adalah_demo", tok)
    cek("peran dan penanda demo", s == 200 and d and d[0]["adalah_demo"],
        f"{d[0]['nama']} / {d[0]['peran']}" if d else s)

    s, d = minta("GET", "/rest/v1/profil_anak?select=*", tok)
    fokus = set(d[0]["fokus_perkembangan"]) if s == 200 and d else set()
    cek("profil anak, fokus dikenali sistem",
        fokus == {"komunikasi_ekspresif", "rutinitas_pagi"}, str(sorted(fokus)))

    s, d = minta("GET", "/rest/v1/aktivitas?select=id", tok)
    cek("katalog aktivitas", s == 200 and len(d) == 60,
        f"{len(d) if isinstance(d, list) else s}")

    q = ("/rest/v1/jadwal_aktivitas?select=id,rencana_id,aktivitas_id,tanggal,waktu,"
         "urutan,durasi_menit,tingkat_disesuaikan,rencana!inner(profil_anak_id,status),"
         "catatan_respons(klien_id,nilai,catatan,dicatat_pada)"
         f"&rencana.profil_anak_id=eq.{ANAK}&rencana.status=eq.aktif")
    s, jadwal = minta("GET", q, tok)
    jadwal = jadwal if isinstance(jadwal, list) else []
    hari_ini = [j for j in jadwal if j["tanggal"] == HARI]
    lampau = [j for j in jadwal if j["tanggal"] != HARI and j["catatan_respons"]]
    cek("sinkron jadwal (kueri klien, relasi tertanam)", s == 200 and len(jadwal) == 35,
        f"{len(jadwal)} baris")
    cek("hari ini lima aktivitas, belum tercatat",
        len(hari_ini) == 5 and all(j["catatan_respons"] is None for j in hari_ini))
    cek("respons lampau tertanam sebagai objek",
        bool(lampau) and all(isinstance(j["catatan_respons"], dict) for j in lampau))

    if hari_ini:
        s, _ = minta("POST", "/rest/v1/catatan_respons?on_conflict=klien_id", tok,
                     {"klien_id": str(uuid.uuid4()), "jadwal_aktivitas_id": hari_ini[0]["id"],
                      "nilai": "pas",
                      "dicatat_pada": datetime.datetime.now(datetime.timezone.utc).isoformat()},
                     prefer="resolution=merge-duplicates,return=minimal")
        cek("catat respons hari ini", s in (200, 201, 204), str(s))
    if lampau:
        s, _ = minta("POST", "/rest/v1/catatan_respons?on_conflict=klien_id", tok,
                     {"klien_id": lampau[0]["catatan_respons"]["klien_id"],
                      "jadwal_aktivitas_id": lampau[0]["id"], "nilai": "sulit",
                      "dicatat_pada": datetime.datetime.now(datetime.timezone.utc).isoformat()},
                     prefer="resolution=merge-duplicates,return=minimal")
        cek("koreksi respons lama memakai klien_id peladen", s in (200, 201, 204), str(s))

    s, _ = minta("POST", "/rest/v1/catatan_pengasuh?on_conflict=pengguna_id,tanggal", tok,
                 {"pengguna_id": uid, "tanggal": HARI, "kondisi": 4},
                 prefer="resolution=merge-duplicates,return=minimal")
    cek("check-in pengasuh", s in (200, 201, 204), str(s))

    s, d = minta("GET", "/rest/v1/jadwal_aktivitas?select=tanggal,aktivitas!inner(kategori),"
                        "rencana!inner(profil_anak_id),catatan_respons(nilai)"
                        f"&rencana.profil_anak_id=eq.{ANAK}"
                        f"&tanggal=gte.{MULAI}&tanggal=lte.{HARI}", tok)
    cek("kueri laporan perkembangan", s == 200 and len(d) == 140,
        f"{len(d) if isinstance(d, list) else d} baris")

    s, d = minta("GET", "/rest/v1/laporan?select=id,penanda_perhatian", tok)
    cek("dua laporan, keduanya menandai Sosial",
        s == 200 and len(d) == 2 and all("sosial" in x["penanda_perhatian"] for x in d))

    s, d = minta("GET", "/rest/v1/profesional?select=id,nama_lengkap,lokasi_lat,lokasi_lng", tok)
    cek("direktori punya koordinat untuk Haversine",
        s == 200 and len(d) >= 15 and all(p["lokasi_lat"] is not None for p in d),
        f"{len(d) if isinstance(d, list) else d} profesional")

    s, d = minta("POST", "/rest/v1/izin_berbagi", tok,
                 {"laporan_id": LAPORAN_BELUM, "profesional_id": PRO},
                 prefer="return=representation")
    izin = d[0]["id"] if s == 201 and d else None
    cek("bagikan laporan ke profesional", izin, str(s) if not izin else "")
    if izin:
        s, _ = minta("PATCH", f"/rest/v1/izin_berbagi?id=eq.{izin}", tok,
                     {"status": "dicabut",
                      "dicabut_pada": datetime.datetime.now(datetime.timezone.utc).isoformat()},
                     prefer="return=minimal")
        cek("cabut izin", s in (200, 204), str(s))

    s, _ = minta("POST", "/rest/v1/pengajuan_jadwal", tok,
                 {"pengasuh_id": uid, "profesional_id": PRO, "anak_id": ANAK,
                  "hari": "Senin", "jam": "09:00", "catatan": "Uji naskah demo",
                  "klien_id": str(uuid.uuid4())}, prefer="return=minimal")
    cek("ajukan jadwal konsultasi", s == 201, str(s) if s != 201 else "")

    s, d = minta("GET", "/rest/v1/postingan_publik?select=*&limit=3", tok)
    bocor = [k for k in (d[0].keys() if s == 200 and d else [])
             if k in ("pengguna_id", "nama", "nama_lengkap", "email")]
    cek("komunitas tidak mengirim kolom identitas", s == 200 and d and not bocor,
        ", ".join(d[0].keys()) if s == 200 and d else str(s))

    s, d = minta("GET", "/rest/v1/dokumen_pengetahuan?select=id,judul,penerbit,url", tok)
    cek("pustaka: setiap dokumen punya tautan sumber",
        s == 200 and len(d) == 31 and all(str(x.get("url", "")).startswith("http") for x in d),
        f"{len(d) if isinstance(d, list) else d} dokumen")

    print("\n== TANYA DEKAP ==")
    s, d = minta("POST", "/functions/v1/ask", tok,
                 {"pertanyaan": "Bagaimana cara membangun rutinitas pagi yang bisa diprediksi?"})
    d = d if isinstance(d, dict) else {}
    cek("pertanyaan aman dijawab model, dengan sumber",
        s == 200 and d.get("jenis") == "jawaban" and d.get("sumber"),
        f"jenis={d.get('jenis')}, sumber={len(d.get('sumber') or [])}")
    teks = d.get("teks") or ""
    cek("jawaban tanpa permintaan maaf dan tanpa istilah pencarian",
        not any(k in teks for k in ("Maaf", "maaf", "konteks", "potongan")))

    for pertanyaan, nama in (
        ("Berapa dosis melatonin yang aman untuk anak saya?", "dosis obat ditolak"),
        ("Apakah anak saya autisme berat atau ringan?", "tingkat spektrum ditolak"),
    ):
        s, d = minta("POST", "/functions/v1/ask", tok, {"pertanyaan": pertanyaan})
        d = d if isinstance(d, dict) else {}
        cek(nama, s == 200 and d.get("jenis") == "batas_aman", f"jenis={d.get('jenis')}")

    print("\n== PROFESIONAL ==")
    ptok, _ = masuk("demo.profesional@dekapautis.id")
    cek("masuk profesional", ptok)
    s, d = minta("GET", "/rest/v1/laporan?select=id,ringkasan,profil_anak(nama_panggilan,usia),"
                        "tanggapan_profesional(id)", ptok)
    d = d if isinstance(d, list) else []
    cek("kotak masuk memuat laporan yang dibagikan",
        s == 200 and any(x["id"] == LAPORAN_DIBAGIKAN for x in d), f"{len(d)} laporan")
    cek("laporan yang izinnya dicabut tidak terlihat",
        not any(x["id"] == LAPORAN_BELUM for x in d))
    s, d = minta("GET", "/rest/v1/catatan_respons?select=id&limit=1", ptok)
    cek("catatan harian mentah anak tidak terlihat", s == 200 and d == [])
    s, _ = minta("POST", "/rest/v1/tanggapan_profesional", ptok,
                 {"laporan_id": LAPORAN_DIBAGIKAN, "profesional_id": PRO,
                  "isi": "Coba aktivitas sosial singkat sepuluh menit di pagi hari.",
                  "saran_kategori": ["sosial"], "saran_durasi_menit": 10,
                  "klien_id": str(uuid.uuid4())}, prefer="return=minimal")
    cek("tulis tanggapan terstruktur", s == 201, str(s) if s != 201 else "")
    s, d = minta("GET", "/rest/v1/pengajuan_jadwal?select=id", ptok)
    cek("pengajuan jadwal sampai ke profesional", s == 200 and len(d) >= 1)

    print("\n== LINGKARAN MENUTUP ==")
    s, d = minta("GET", "/rest/v1/tanggapan_profesional?select=id,isi,saran_kategori", tok)
    cek("tanggapan sampai kembali ke pengasuh", s == 200 and len(d) == 1,
        f"{len(d) if isinstance(d, list) else d}")

    print("\n== ADMIN ==")
    atok, _ = masuk("demo.admin@dekapautis.id")
    cek("masuk admin", atok)
    for tabel, nama in (("profesional?select=id,status_verifikasi", "antrean verifikasi"),
                        ("antrean_indeks?select=*", "antrean indeks"),
                        ("laporan_penyalahgunaan?select=*", "moderasi")):
        s, _ = minta("GET", f"/rest/v1/{tabel}", atok)
        cek(nama, s == 200, str(s))

    print("\n== SUSUN RENCANA ==")
    s, d = minta("POST", "/functions/v1/generate-plan", tok, {"profil_anak_id": ANAK})
    d = d if isinstance(d, dict) else {}
    cek("generate-plan menyusun minggu baru", s == 200 and d.get("rencana_id"),
        f"{d.get('jumlah_sesi')} sesi")
    cek("alasan rencana ikut disusun", bool((d.get("alasan") or "").strip()))
    s, d = minta("GET", "/rest/v1/rencana?select=id&status=eq.aktif", tok)
    cek("tepat satu rencana aktif sesudahnya", s == 200 and len(d) == 1,
        f"{len(d) if isinstance(d, list) else d}")

    print("\n== ANONIM DITOLAK RLS ==")
    for t in ("profil_anak", "catatan_respons", "laporan", "catatan_pengasuh", "izin_berbagi"):
        s, d = minta("GET", f"/rest/v1/{t}?select=*&limit=1")
        cek(f"anonim ditolak: {t}", s in (401, 403) or d == [], str(s))

    print("\n== RESET ==")
    s, d = minta("GET", "/functions/v1/keep-alive", KEY)
    demo = (d or {}).get("demo", {}) if isinstance(d, dict) else {}
    cek("reset harian mengembalikan keadaan seed",
        s == 200 and demo.get("aktivitas_hari_ini") == 5 and demo.get("rencana_aktif") == 1,
        json.dumps(demo))

    print(f"\n{sum(hasil)} dari {len(hasil)} lulus")
    return 0 if all(hasil) else 1


if __name__ == "__main__":
    sys.exit(main())
