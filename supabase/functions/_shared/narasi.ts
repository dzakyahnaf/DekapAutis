// Narrative verification for the report summary.
//
// The division of labour is absolute: every figure is computed in Dart, and the
// model receives them already finished. Its only job is to arrange them into
// sentences. That is what makes this check possible - a narrative can be
// verified against a closed set of numbers precisely because the numbers were
// never the model's to produce.
//
// A fabricated figure here is worse than a fabricated sentence anywhere else in
// the product. This document goes to a therapist, who has no way to tell an
// invented percentage from a measured one, and may act on it.

export interface MetrikMasukan {
  aktivitas_terjadwal: number;
  aktivitas_tercatat: number;
  persen_tercatat: number;
  rata_sesi_harian: number;
  jumlah_hari: number;
  tren_mingguan: Array<{ persen: number; jumlah: number }>;
  per_kategori: Array<{
    kategori: string;
    label: string;
    persen: number;
    jumlah: number;
    tren: string;
  }>;
  penanda_perhatian: string[];
  periode_mulai: string;
  periode_selesai: string;
}

/** Every number the narrative is permitted to contain, normalised. */
export function angkaSah(m: MetrikMasukan): Set<string> {
  const sah = new Set<string>();
  const tambah = (n: number | string) => sah.add(normalkanAngka(String(n)));

  tambah(m.aktivitas_terjadwal);
  tambah(m.aktivitas_tercatat);
  tambah(m.persen_tercatat);
  tambah(m.jumlah_hari);
  tambah(m.rata_sesi_harian);
  tambah(m.rata_sesi_harian.toFixed(1));
  tambah(Math.round(m.rata_sesi_harian));
  tambah(m.tren_mingguan.length);
  tambah(m.per_kategori.length);

  for (const t of m.tren_mingguan) {
    tambah(t.persen);
    tambah(t.jumlah);
  }
  for (const k of m.per_kategori) {
    tambah(k.persen);
    tambah(k.jumlah);
  }
  // Dates appear in the period sentence, so their parts are legitimate.
  for (const tanggal of [m.periode_mulai, m.periode_selesai]) {
    for (const bagian of tanggal.split('-')) tambah(Number(bagian));
  }
  return sah;
}

/** "2,4" and "2.4" are the same fact; Indonesian writes the comma. */
export function normalkanAngka(s: string): string {
  const bersih = s.replace(',', '.');
  const n = Number(bersih);
  return Number.isFinite(n) ? String(n) : bersih;
}

/** Every numeric token in a piece of prose. */
export function angkaDalam(teks: string): string[] {
  return [...teks.matchAll(/\d+(?:[.,]\d+)?/g)].map((m) => m[0]);
}

export interface HasilVerifikasi {
  sah: boolean;
  angkaAsing: string[];
  alasan?: string;
}

/**
 * Rejects a narrative containing any figure that was not in the input.
 *
 * There is no attempt to repair one. A narrative that had to be corrected is a
 * narrative whose reasoning we cannot see, and the deterministic template below
 * is a perfectly good document - plainer, and true.
 */
export function verifikasiAngka(
  narasi: string,
  m: MetrikMasukan,
): HasilVerifikasi {
  const sah = angkaSah(m);
  const asing = angkaDalam(narasi)
    .map(normalkanAngka)
    .filter((a) => !sah.has(a));

  return asing.length === 0
    ? { sah: true, angkaAsing: [] }
    : {
        sah: false,
        angkaAsing: [...new Set(asing)],
        alasan: `angka tidak berasal dari data: ${[...new Set(asing)].join(', ')}`,
      };
}

/**
 * Language a report for a therapist must not contain.
 *
 * Two separate prohibitions. Clinical vocabulary because the app does not
 * diagnose or grade, and a professional reading this needs to know it is
 * looking at a caregiver's notes rather than an assessment. Evaluative
 * vocabulary because "Bima menunjukkan kemajuan yang baik" is an opinion
 * dressed as an observation - docs/04 §4 asks for the descriptive form instead.
 */
const KATA_TERLARANG = [
  'diagnos', 'derajat', 'keparahan', 'spektrum ringan', 'spektrum berat',
  'autis ringan', 'autis berat', 'penderita', 'penyandang', 'pasien',
  'obat', 'dosis', 'terapi khelasi', 'sembuh',
  'skor', 'nilai anak', 'peringkat', 'indeks kemampuan',
  'normal', 'tidak normal', 'terlambat', 'keterlambatan', 'gangguan',
  'prognosis', 'kemajuan yang baik', 'perkembangan pesat', 'membanggakan',
  'dibandingkan anak lain', 'anak seusianya', 'seharusnya sudah',
];

export function verifikasiBahasa(narasi: string): HasilVerifikasi {
  const teks = narasi.toLowerCase();
  const ketemu = KATA_TERLARANG.filter((k) => teks.includes(k));
  return ketemu.length === 0
    ? { sah: true, angkaAsing: [] }
    : {
        sah: false,
        angkaAsing: [],
        alasan: `bahasa klinis atau penilaian: ${ketemu.join(', ')}`,
      };
}

function tanggalIndonesia(iso: string): string {
  const bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  const [y, m, d] = iso.split('-').map(Number);
  return `${d} ${bulan[m - 1]} ${y}`;
}

function gabungIndonesia(bagian: string[]): string {
  if (bagian.length <= 1) return bagian.join('');
  if (bagian.length === 2) return `${bagian[0]} dan ${bagian[1]}`;
  return `${bagian.slice(0, -1).join(', ')}, dan ${bagian[bagian.length - 1]}`;
}

/**
 * The narrative built from the numbers alone.
 *
 * This ships whenever no model is reachable and whenever a generated narrative
 * fails verification, and it is deliberately good enough to ship on its own.
 * Descriptive throughout: "respons Mudah pada Komunikasi naik dari 45% menjadi
 * 78%", never "menunjukkan kemajuan yang baik".
 */
export function narasiDeterministik(m: MetrikMasukan): string {
  const kalimat: string[] = [];

  kalimat.push(
    `Laporan ini mencakup ${m.jumlah_hari} hari, dari ` +
      `${tanggalIndonesia(m.periode_mulai)} sampai ` +
      `${tanggalIndonesia(m.periode_selesai)}.`,
  );

  kalimat.push(
    `Dari ${m.aktivitas_terjadwal} aktivitas yang terjadwal, ` +
      `${m.aktivitas_tercatat} tercatat responsnya (${m.persen_tercatat}%), ` +
      `rata-rata ${m.rata_sesi_harian.toFixed(1).replace('.', ',')} sesi per hari.`,
  );

  if (m.per_kategori.length > 0) {
    const bagian = m.per_kategori.map(
      (k) => `${k.label} ${k.persen}% dari ${k.jumlah} catatan`,
    );
    kalimat.push(
      `Respons Mudah per kategori: ${gabungIndonesia(bagian)}.`,
    );
  }

  if (m.tren_mingguan.length >= 2) {
    const awal = m.tren_mingguan[0];
    const akhir = m.tren_mingguan[m.tren_mingguan.length - 1];
    kalimat.push(
      `Selama ${m.tren_mingguan.length} minggu tercatat, respons Mudah ` +
        `bergerak dari ${awal.persen}% pada minggu pertama menjadi ` +
        `${akhir.persen}% pada minggu terakhir.`,
    );
  }

  if (m.penanda_perhatian.length > 0) {
    const label = m.per_kategori
      .filter((k) => m.penanda_perhatian.includes(k.kategori))
      .map((k) => k.label);
    kalimat.push(
      `Kategori yang ditandai untuk dibahas: ` +
        `${gabungIndonesia(label.length > 0 ? label : m.penanda_perhatian)}.`,
    );
  }

  return kalimat.join(' ');
}
