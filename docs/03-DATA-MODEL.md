# 03 — Model Data, RLS, dan Sinkronisasi

12 entitas inti sesuai Gambar 6.4 proposal, ditambah tabel pendukung yang dibutuhkan implementasi nyata. Rancangan memisahkan **identitas, profil anak, pelaksanaan aktivitas, dan pengetahuan** agar kebijakan akses bisa dibedakan per kelompok dan penghapusan menyeluruh mudah dilakukan.

---

## 1. Entitas inti

```sql
-- Identitas
create table pengguna (
  id uuid primary key references auth.users on delete cascade,
  peran text not null check (peran in ('pengasuh','profesional','admin')),
  nama text not null,
  email text not null,
  mode_tenang boolean not null default false,
  skala_teks text not null default 'standar' check (skala_teks in ('standar','besar','sangat_besar')),
  kurangi_gerak boolean not null default false,
  adalah_demo boolean not null default false,
  dibuat_pada timestamptz not null default now()
);

-- Profil anak
create table profil_anak (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  nama_panggilan text not null,
  usia int not null check (usia between 1 and 18),
  kemampuan_komunikasi text not null
    check (kemampuan_komunikasi in ('belum_verbal','beberapa_kata','kalimat_pendek','lancar')),
  sensitivitas_sensorik text[] not null default '{}',
  fokus_perkembangan text[] not null default '{}',
  dibuat_pada timestamptz not null default now()
);

-- Katalog aktivitas (dikelola sistem, dibaca semua)
create table aktivitas (
  id uuid primary key default gen_random_uuid(),
  kategori text not null
    check (kategori in ('komunikasi','motorik','sensorik','kemandirian','sosial')),
  tingkat int not null check (tingkat between 1 and 4),
  judul text not null,
  tujuan text not null,
  durasi_menit int not null check (durasi_menit between 5 and 45),
  alat text[] not null default '{}',
  langkah jsonb not null,           -- [{urutan, teks}]
  saran_lingkungan text,            -- dipakai saat mesin adaptasi menurunkan tingkat
  cocok_untuk_komunikasi text[] not null default '{}'
);

-- Rencana
create table rencana (
  id uuid primary key default gen_random_uuid(),
  profil_anak_id uuid not null references profil_anak on delete cascade,
  periode_mulai date not null,
  periode_selesai date not null,
  status text not null default 'aktif' check (status in ('aktif','selesai','digantikan')),
  dibuat_pada timestamptz not null default now()
);

create table jadwal_aktivitas (
  id uuid primary key default gen_random_uuid(),
  rencana_id uuid not null references rencana on delete cascade,
  aktivitas_id uuid not null references aktivitas,
  tanggal date not null,
  waktu time not null,
  urutan int not null,
  durasi_menit int not null,
  tingkat_disesuaikan int not null check (tingkat_disesuaikan between 1 and 4)
);

-- Pelaksanaan
create table catatan_respons (
  id uuid primary key default gen_random_uuid(),
  jadwal_aktivitas_id uuid not null references jadwal_aktivitas on delete cascade,
  nilai text not null check (nilai in ('mudah','pas','sulit')),
  catatan text,
  dicatat_pada timestamptz not null default now(),
  klien_id text unique                 -- idempotensi untuk sinkronisasi luring
);

create table catatan_pengasuh (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  tanggal date not null,
  kondisi int not null check (kondisi between 1 and 5),   -- berat..baik
  unique (pengguna_id, tanggal)
);

-- Laporan
create table laporan (
  id uuid primary key default gen_random_uuid(),
  profil_anak_id uuid not null references profil_anak on delete cascade,
  periode_mulai date not null,
  periode_selesai date not null,
  metrik jsonb not null,        -- {aktivitas_selesai, catatan_tercatat, rata_sesi_harian}
  per_kategori jsonb not null,  -- [{kategori, persen, tren}]
  ringkasan text not null,      -- narasi hasil peringkasan
  penanda_perhatian text[] not null default '{}',
  dibuat_pada timestamptz not null default now()
);

-- Pengetahuan
create table dokumen_pengetahuan (
  id uuid primary key default gen_random_uuid(),
  judul text not null,
  penerbit text not null,
  tahun int not null,
  url text not null,
  status_tinjauan text not null default 'menunggu'
    check (status_tinjauan in ('menunggu','ditinjau_profesional','ditolak')),
  versi_id uuid references versi_basis_pengetahuan,
  dibuat_pada timestamptz not null default now()
);

create table potongan_dokumen (
  id uuid primary key default gen_random_uuid(),
  dokumen_id uuid not null references dokumen_pengetahuan on delete cascade,
  halaman int,
  teks text not null,
  embedding vector(768),        -- sesuaikan dimensi dengan model embedding yang dipakai
  tsv tsvector generated always as (to_tsvector('indonesian', teks)) stored
);

-- Profesional dan izin
create table profesional (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  nama_lengkap text not null,
  gelar text,
  spesialisasi text not null,
  tentang text,
  layanan text[] not null default '{}',
  jadwal_praktik jsonb not null default '[]',
  lokasi_lat double precision,
  lokasi_lng double precision,
  kota text,
  terverifikasi boolean not null default false,
  diverifikasi_pada timestamptz
);

create table izin_berbagi (
  id uuid primary key default gen_random_uuid(),
  laporan_id uuid not null references laporan on delete cascade,
  profesional_id uuid not null references profesional on delete cascade,
  ruang_lingkup text not null default 'laporan',
  status text not null default 'aktif' check (status in ('aktif','dicabut')),
  diberikan_pada timestamptz not null default now(),
  dicabut_pada timestamptz
);
```

## 2. Tabel pendukung

```sql
create table versi_basis_pengetahuan (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  catatan text,
  diterbitkan_pada timestamptz not null default now()
);

create table adaptasi_log (
  id uuid primary key default gen_random_uuid(),
  rencana_id uuid not null references rencana on delete cascade,
  aturan_id text not null,           -- 'A_naik','B_turun','C_porsi','D_tandai','E_jadwal'
  kategori text,
  nilai_sebelum jsonb,
  nilai_sesudah jsonb,
  alasan text not null,              -- Bahasa Indonesia, ditampilkan ke pengguna
  dikoreksi_manual boolean not null default false,
  dibuat_pada timestamptz not null default now()
);

create table log_batas_aman (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid references pengguna on delete set null,
  pertanyaan text not null,
  lapisan_pemicu text not null,      -- 'leksikon','klasifikasi','verifikasi_keluaran'
  kategori text not null,            -- 'diagnosis','tingkat_spektrum','obat','dosis','klaim_sembuh'
  dibuat_pada timestamptz not null default now()
);

create table tanggapan_profesional (
  id uuid primary key default gen_random_uuid(),
  laporan_id uuid not null references laporan on delete cascade,
  profesional_id uuid not null references profesional on delete cascade,
  isi text not null,
  dibuat_pada timestamptz not null default now()
);

create table postingan_komunitas (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  topik text not null,
  judul text not null,
  isi text not null,
  anonim boolean not null default false,
  status text not null default 'terbit' check (status in ('terbit','ditinjau','dihapus')),
  dibuat_pada timestamptz not null default now()
);

create table balasan_komunitas (
  id uuid primary key default gen_random_uuid(),
  postingan_id uuid not null references postingan_komunitas on delete cascade,
  pengguna_id uuid not null references pengguna on delete cascade,
  isi text not null,
  anonim boolean not null default false,
  dibuat_pada timestamptz not null default now()
);

create table notifikasi (
  id uuid primary key default gen_random_uuid(),
  pengguna_id uuid not null references pengguna on delete cascade,
  jenis text not null,   -- 'penyesuaian','belum_dicatat','balasan','artikel','jadwal'
  judul text not null,
  dibaca boolean not null default false,
  dibuat_pada timestamptz not null default now()
);
```

## 3. Indeks

```sql
create index on potongan_dokumen using ivfflat (embedding vector_cosine_ops) with (lists = 100);
create index on potongan_dokumen using gin (tsv);
create index on jadwal_aktivitas (rencana_id, tanggal);
create index on catatan_respons (jadwal_aktivitas_id);
create index on izin_berbagi (profesional_id, status);
create index on profil_anak (pengguna_id);
```

Jalankan `ANALYZE` setelah memuat korpus agar `ivfflat` memilih rencana query yang benar.

---

## 4. Row Level Security

**Aktifkan RLS di setiap tabel. Default deny.** Ini bukan formalitas — ini bukti privasi yang akan Anda tunjukkan di video, dan ini yang memenuhi KNF-03/KNF-04 serta Bab 4.3 proposal.

```sql
alter table profil_anak enable row level security;

-- Pengasuh hanya melihat anaknya sendiri
create policy "pengasuh_baca_anak_sendiri" on profil_anak
  for select using (pengguna_id = auth.uid());
create policy "pengasuh_tulis_anak_sendiri" on profil_anak
  for all using (pengguna_id = auth.uid()) with check (pengguna_id = auth.uid());

-- Laporan: pemilik ATAU profesional dengan izin aktif
alter table laporan enable row level security;
create policy "pemilik_baca_laporan" on laporan
  for select using (
    exists (select 1 from profil_anak p
            where p.id = laporan.profil_anak_id and p.pengguna_id = auth.uid())
  );
create policy "profesional_baca_laporan_berizin" on laporan
  for select using (
    exists (
      select 1 from izin_berbagi i
      join profesional pr on pr.id = i.profesional_id
      where i.laporan_id = laporan.id
        and i.status = 'aktif'
        and pr.pengguna_id = auth.uid()
    )
  );

-- Pengetahuan: dibaca semua yang terautentikasi, ditulis hanya admin
alter table dokumen_pengetahuan enable row level security;
create policy "semua_baca_pengetahuan" on dokumen_pengetahuan
  for select using (auth.role() = 'authenticated');
create policy "admin_kelola_pengetahuan" on dokumen_pengetahuan
  for all using (
    exists (select 1 from pengguna u where u.id = auth.uid() and u.peran = 'admin')
  );
```

Terapkan pola yang sama untuk `rencana`, `jadwal_aktivitas`, `catatan_respons`, `catatan_pengasuh`, `notifikasi`, `adaptasi_log`. Komunitas boleh dibaca semua pengguna terautentikasi, tetapi kolom identitas **tidak boleh dikirim ke klien** saat `anonim = true` — gunakan view yang menyembunyikannya di sisi peladen, jangan andalkan klien untuk menyembunyikan.

> **Catatan migrasi.** Project Supabase yang dibuat setelah 30 Mei 2026 memerlukan grant Postgres eksplisit untuk akses PostgREST, dan project free lama terdampak mulai 30 Oktober 2026. Periksa apakah project Anda perlu grant tambahan sebelum menyimpulkan RLS Anda rusak.

### Uji RLS wajib

`scripts/test_rls.sql` — buat dua pengasuh dan satu profesional, lalu buktikan:

1. Pengasuh A membaca `profil_anak` milik B → **0 baris**
2. Profesional tanpa izin membaca laporan A → **0 baris**
3. Profesional dengan izin aktif → **1 baris**
4. Setelah izin dicabut, profesional yang sama → **0 baris**
5. Pengasuh mencoba menulis `dokumen_pengetahuan` → **ditolak**

Kalau salah satu gagal, itu blocker. Jangan lanjut ke fase berikutnya.

---

## 5. Sinkronisasi luring

Yang harus jalan luring (KNF-02): membuka rencana yang sudah diunduh, membuka detail aktivitas, mencatat respons, mengisi check-in kondisi.

Yang **butuh** jaringan: asisten, penyusunan rencana baru, pembuatan laporan.

**Pola:**
- Drift menyimpan cache baca untuk `rencana`, `jadwal_aktivitas`, `aktivitas`, dan antrean tulis `catatan_respons` + `catatan_pengasuh`
- Setiap catatan luring mendapat `klien_id` berupa UUID yang dibuat di perangkat. Kolom itu `unique` di peladen, jadi pengiriman ulang bersifat idempoten — sinkronisasi ganda tidak menghasilkan baris ganda
- `connectivity_plus` memicu pengurasan antrean saat jaringan kembali
- Konflik diselesaikan dengan **penulisan terakhir menang berdasarkan `dicatat_pada`**, karena satu aktivitas hanya punya satu respons dan pengasuh tunggal per anak
- Pita luring tampil di header saat antrean tidak kosong: "Tersimpan di perangkat. 3 catatan menunggu sinkronisasi."

Uji ini secara eksplisit: matikan jaringan, catat 5 respons, tutup aplikasi, buka lagi, nyalakan jaringan, pastikan tepat 5 baris muncul di peladen — bukan 4, bukan 10.
