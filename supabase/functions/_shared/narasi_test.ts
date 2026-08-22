// The number check on the report narrative.
//
// A fabricated figure here is worse than one anywhere else in the product: the
// document goes to a therapist, who cannot tell an invented percentage from a
// measured one and may act on it. So the check is tested against the shapes a
// model actually produces - a plausible-looking total, a rounded average, a
// percentage nobody computed.
//
// Run:  docker run --rm -v "$PWD:/w" -w /w --entrypoint deno denoland/deno:alpine \
//         test --allow-import supabase/functions/_shared/narasi_test.ts

import { assert, assertEquals } from 'jsr:@std/assert@1';
import {
  angkaDalam,
  angkaSah,
  type MetrikMasukan,
  narasiDeterministik,
  normalkanAngka,
  verifikasiAngka,
  verifikasiBahasa,
} from './narasi.ts';

function metrik(ubah: Partial<MetrikMasukan> = {}): MetrikMasukan {
  return {
    aktivitas_terjadwal: 140,
    aktivitas_tercatat: 120,
    persen_tercatat: 86,
    rata_sesi_harian: 4.3,
    jumlah_hari: 28,
    tren_mingguan: [
      { persen: 45, jumlah: 30 },
      { persen: 58, jumlah: 31 },
      { persen: 66, jumlah: 29 },
      { persen: 78, jumlah: 30 },
    ],
    per_kategori: [
      { kategori: 'komunikasi', label: 'Komunikasi', persen: 78, jumlah: 34, tren: 'naik' },
      { kategori: 'sosial', label: 'Sosial', persen: 40, jumlah: 22, tren: 'menurun' },
    ],
    penanda_perhatian: ['sosial'],
    periode_mulai: '2026-08-03',
    periode_selesai: '2026-08-30',
    ...ubah,
  };
}

Deno.test('number extraction finds every shape a narrative uses', () => {
  assertEquals(
    angkaDalam('Dari 140 aktivitas, 120 tercatat (86%), rata-rata 4,3 per hari.'),
    ['140', '120', '86', '4,3'],
  );
});

Deno.test('a comma and a full stop are the same number', () => {
  assertEquals(normalkanAngka('4,3'), normalkanAngka('4.3'));
  assertEquals(normalkanAngka('86'), '86');
});

Deno.test('the valid set holds every figure the report publishes', () => {
  const sah = angkaSah(metrik());
  for (const n of ['140', '120', '86', '28', '4.3', '45', '78', '34', '40', '22']) {
    assert(sah.has(normalkanAngka(n)), `${n} tidak ada di himpunan sah`);
  }
});

Deno.test('a faithful narrative passes', () => {
  const m = metrik();
  const narasi =
    'Dari 140 aktivitas yang terjadwal, 120 tercatat responsnya (86%). ' +
    'Respons Mudah pada Komunikasi 78% dari 34 catatan, Sosial 40% dari 22 catatan.';
  assert(verifikasiAngka(narasi, m).sah, verifikasiAngka(narasi, m).alasan);
});

Deno.test('the deterministic narrative passes its own check', () => {
  // It has to: it is the fallback used when a generated one is rejected.
  const m = metrik();
  const hasil = verifikasiAngka(narasiDeterministik(m), m);
  assert(hasil.sah, hasil.alasan);
  assert(verifikasiBahasa(narasiDeterministik(m)).sah);
});

Deno.test('an invented total is rejected', () => {
  const m = metrik();
  // 132 is plausible, sits between two real figures, and nobody computed it.
  const hasil = verifikasiAngka(
    'Dari 140 aktivitas yang terjadwal, 132 tercatat responsnya.',
    m,
  );
  assert(!hasil.sah);
  assertEquals(hasil.angkaAsing, ['132']);
});

Deno.test('an invented percentage is rejected', () => {
  const hasil = verifikasiAngka(
    'Respons Mudah pada Komunikasi meningkat menjadi 91%.',
    metrik(),
  );
  assert(!hasil.sah);
  assertEquals(hasil.angkaAsing, ['91']);
});

Deno.test('a computed difference is still an invented number', () => {
  // 78 minus 45 is 33. It is arithmetic the model did, not a figure we
  // published, and a therapist has no way to know which is which.
  const hasil = verifikasiAngka(
    'Respons Mudah naik 33 poin selama periode ini.',
    metrik(),
  );
  assert(!hasil.sah);
  assertEquals(hasil.angkaAsing, ['33']);
});

Deno.test('a rounded average is accepted, since both forms were published', () => {
  const m = metrik();
  assert(verifikasiAngka('Rata-rata 4,3 sesi per hari.', m).sah);
  assert(verifikasiAngka('Rata-rata 4.3 sesi per hari.', m).sah);
  assert(verifikasiAngka('Sekitar 4 sesi per hari.', m).sah);
});

Deno.test('dates in the period sentence are accepted', () => {
  const m = metrik();
  const hasil = verifikasiAngka(
    'Laporan ini mencakup 28 hari, dari 3 Agustus 2026 sampai 30 Agustus 2026.',
    m,
  );
  assert(hasil.sah, hasil.alasan);
});

Deno.test('a narrative with no numbers at all passes the number check', () => {
  // Vacuous, but not false. The prompt asks for figures; a narrative without
  // them is poor rather than dangerous, and rejecting it here would only push
  // the model towards inventing some.
  assert(verifikasiAngka('Catatan tersedia untuk periode ini.', metrik()).sah);
});

Deno.test('clinical language is rejected', () => {
  for (const narasi of [
    'Anak menunjukkan keterlambatan pada kategori Sosial.',
    'Kondisi ini termasuk autis ringan.',
    'Skor keseluruhan berada di bawah rata-rata.',
    'Perkembangannya belum normal untuk anak seusianya.',
    'Diagnosis sementara mengarah pada gangguan komunikasi.',
  ]) {
    const hasil = verifikasiBahasa(narasi);
    assert(!hasil.sah, `lolos: "${narasi}"`);
  }
});

Deno.test('praise dressed as observation is rejected', () => {
  // docs/04 §4 is explicit: "respons pada aktivitas komunikasi meningkat dari
  // 45% menjadi 78%", not "menunjukkan kemajuan yang baik".
  const hasil = verifikasiBahasa(
    'Bima menunjukkan kemajuan yang baik selama empat minggu terakhir.',
  );
  assert(!hasil.sah);
});

Deno.test('descriptive language passes', () => {
  for (const narasi of [
    'Respons Mudah pada Komunikasi bergerak dari 45% menjadi 78%.',
    'Dari 140 aktivitas terjadwal, 120 tercatat responsnya.',
    'Kategori yang ditandai untuk dibahas: Sosial.',
  ]) {
    const hasil = verifikasiBahasa(narasi);
    assert(hasil.sah, `${hasil.alasan} pada: "${narasi}"`);
  }
});

Deno.test('the deterministic narrative names the flagged category', () => {
  const teks = narasiDeterministik(metrik());
  assert(teks.includes('Sosial'), teks);
  assert(teks.includes('ditandai'), teks);
});

Deno.test('an empty period still produces a readable narrative', () => {
  const kosong = metrik({
    aktivitas_terjadwal: 0,
    aktivitas_tercatat: 0,
    persen_tercatat: 0,
    rata_sesi_harian: 0,
    tren_mingguan: [],
    per_kategori: [],
    penanda_perhatian: [],
  });
  const teks = narasiDeterministik(kosong);
  assert(teks.length > 40, teks);
  assert(verifikasiAngka(teks, kosong).sah, verifikasiAngka(teks, kosong).alasan);
});

Deno.test('the narrative never contains a single overall score', () => {
  const teks = narasiDeterministik(metrik()).toLowerCase();
  for (const kata of ['skor', 'nilai keseluruhan', 'total nilai', 'indeks']) {
    assert(!teks.includes(kata), `memuat "${kata}"`);
  }
});
