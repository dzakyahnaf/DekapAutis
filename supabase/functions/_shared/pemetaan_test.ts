// Tests for the deterministic plan rules.
//
// These matter more than most: this file is the evidence for KF-03 ("different
// profiles produce different plans"), and it is the reason we can say the
// language model does not choose activities - a rule set that is testable
// without a model is one the model demonstrably has no part in.
//
// Run:  docker run --rm -v "$PWD:/w" -w /w denoland/deno:alpine \
//         test --allow-none supabase/functions/_shared/pemetaan_test.ts

import { assert, assertEquals } from 'jsr:@std/assert@1';
import {
  type Aktivitas,
  alasanDeterministik,
  cacah,
  gabungIndonesia,
  type Kategori,
  MAKS_SESI_HARIAN,
  MAKS_SESI_MINGGUAN,
  porsiMingguan,
  type ProfilAnak,
  SEMUA_KATEGORI,
  susunJadwal,
  tingkatAwal,
} from './pemetaan.ts';

const SEMUA_KOMUNIKASI = [
  'belum_verbal',
  'beberapa_kata',
  'kalimat_pendek',
  'lancar',
] as const;

function profil(ubah: Partial<ProfilAnak> = {}): ProfilAnak {
  return {
    id: 'anak-uji-0001',
    nama_panggilan: 'Anak',
    usia: 6,
    kemampuan_komunikasi: 'beberapa_kata',
    sensitivitas_sensorik: [],
    fokus_perkembangan: [],
    ...ubah,
  };
}

/** Stand-in catalogue with the same shape as the seeded one: 5 x 4 x 3. */
function katalog(): Aktivitas[] {
  const out: Aktivitas[] = [];
  for (const kategori of SEMUA_KATEGORI) {
    for (let tingkat = 1; tingkat <= 4; tingkat++) {
      for (let v = 1; v <= 3; v++) {
        out.push({
          id: `${kategori}-${tingkat}-${v}`,
          kategori,
          tingkat,
          judul: `${kategori} ${tingkat} varian ${v}`,
          durasi_menit: 5 + tingkat * 4,
          cocok_untuk_komunikasi: [...SEMUA_KOMUNIKASI],
        });
      }
    }
  }
  return out;
}

const SENIN = new Date(Date.UTC(2026, 7, 24));

// ------------------------------------------------------------- levels --

Deno.test('communication and social levels follow how the child communicates', () => {
  const harapan: Record<string, number> = {
    belum_verbal: 1,
    beberapa_kata: 2,
    kalimat_pendek: 3,
    lancar: 4,
  };
  for (const k of SEMUA_KOMUNIKASI) {
    const p = profil({ kemampuan_komunikasi: k });
    assertEquals(tingkatAwal('komunikasi', p), harapan[k]);
    assertEquals(tingkatAwal('sosial', p), harapan[k]);
  }
});

Deno.test('motor, sensory and independence levels follow age, not speech', () => {
  // The point of the split: a child who does not speak yet is not therefore a
  // level-1 jumper. Tying every category to speech would turn one answer into a
  // general ranking of the child.
  for (const kategori of ['motorik', 'sensorik', 'kemandirian'] as Kategori[]) {
    const belumVerbal = profil({ kemampuan_komunikasi: 'belum_verbal', usia: 10 });
    const lancar = profil({ kemampuan_komunikasi: 'lancar', usia: 10 });
    assertEquals(tingkatAwal(kategori, belumVerbal), tingkatAwal(kategori, lancar));
    assertEquals(tingkatAwal(kategori, belumVerbal), 3);
  }
});

Deno.test('age bands map to levels 1 to 4 and never outside', () => {
  for (let usia = 1; usia <= 18; usia++) {
    const t = tingkatAwal('motorik', profil({ usia }));
    assert(t >= 1 && t <= 4, `usia ${usia} menghasilkan tingkat ${t}`);
  }
  assertEquals(tingkatAwal('motorik', profil({ usia: 4 })), 1);
  assertEquals(tingkatAwal('motorik', profil({ usia: 5 })), 2);
  assertEquals(tingkatAwal('motorik', profil({ usia: 8 })), 3);
  assertEquals(tingkatAwal('motorik', profil({ usia: 12 })), 4);
});

// -------------------------------------------------------------- portions --

Deno.test('every category starts at two sessions a week', () => {
  const porsi = porsiMingguan(profil());
  for (const k of SEMUA_KATEGORI) assertEquals(porsi[k], 2);
});

Deno.test('each chosen focus adds two sessions to its own category only', () => {
  const porsi = porsiMingguan(
    profil({ fokus_perkembangan: ['komunikasi_ekspresif', 'rutinitas_pagi'] }),
  );
  assertEquals(porsi.komunikasi, 4);
  assertEquals(porsi.kemandirian, 4);
  assertEquals(porsi.motorik, 2);
  assertEquals(porsi.sosial, 2);
});

Deno.test('two focuses on the same category stack', () => {
  const porsi = porsiMingguan(
    profil({ fokus_perkembangan: ['komunikasi_ekspresif', 'memahami_instruksi'] }),
  );
  assertEquals(porsi.komunikasi, 6);
});

Deno.test('any sensory sensitivity adds one sensory session', () => {
  assertEquals(porsiMingguan(profil({ sensitivitas_sensorik: ['suara_keras'] })).sensorik, 3);
  // Three sensitivities is still one extra session, not three.
  assertEquals(
    porsiMingguan(
      profil({ sensitivitas_sensorik: ['suara_keras', 'cahaya_terang', 'bau'] }),
    ).sensorik,
    3,
  );
});

Deno.test('the weekly ceiling holds even when everything is selected', () => {
  const porsi = porsiMingguan(
    profil({
      fokus_perkembangan: [
        'komunikasi_ekspresif', 'memahami_instruksi', 'rutinitas_pagi',
        'makan_berpakaian', 'bermain_bersama', 'menenangkan_diri',
      ],
      sensitivitas_sensorik: ['suara_keras', 'cahaya_terang'],
    }),
  );
  for (const k of SEMUA_KATEGORI) {
    assert(porsi[k] <= MAKS_SESI_MINGGUAN, `${k} = ${porsi[k]}`);
  }
});

Deno.test('an unknown focus value is ignored rather than crashing', () => {
  const porsi = porsiMingguan(profil({ fokus_perkembangan: ['tidak_dikenal'] }));
  assertEquals(porsi.komunikasi, 2);
});

// -------------------------------------------------------------- schedule --

Deno.test('the same profile always produces exactly the same week', () => {
  const p = profil({ fokus_perkembangan: ['komunikasi_ekspresif'] });
  const a = susunJadwal(p, katalog(), SENIN);
  const b = susunJadwal(p, katalog(), SENIN);
  assertEquals(JSON.stringify(a), JSON.stringify(b));
});

Deno.test('different profiles produce different plans - KF-03', () => {
  const k = katalog();
  const rencana = [
    profil({ id: 'a', kemampuan_komunikasi: 'belum_verbal', usia: 4 }),
    profil({ id: 'b', kemampuan_komunikasi: 'lancar', usia: 12 }),
    profil({ id: 'c', fokus_perkembangan: ['bermain_bersama'] }),
    profil({ id: 'd', sensitivitas_sensorik: ['keramaian'] }),
  ].map((p) => JSON.stringify(susunJadwal(p, k, SENIN)));

  assertEquals(new Set(rencana).size, rencana.length,
    'dua profil berbeda menghasilkan rencana yang identik');
});

Deno.test('the number of sessions matches the portions exactly', () => {
  const p = profil({
    fokus_perkembangan: ['komunikasi_ekspresif'],
    sensitivitas_sensorik: ['suara_keras'],
  });
  const porsi = porsiMingguan(p);
  const slot = susunJadwal(p, katalog(), SENIN);

  for (const kategori of SEMUA_KATEGORI) {
    assertEquals(
      slot.filter((s) => s.kategori === kategori).length,
      porsi[kategori],
      `jumlah sesi ${kategori} tidak sesuai porsi`,
    );
  }
});

Deno.test('no day ever exceeds the daily ceiling', () => {
  const p = profil({
    fokus_perkembangan: [
      'komunikasi_ekspresif', 'memahami_instruksi', 'rutinitas_pagi',
      'makan_berpakaian', 'bermain_bersama', 'menenangkan_diri',
    ],
    sensitivitas_sensorik: ['suara_keras'],
  });
  const perHari = new Map<string, number>();
  for (const s of susunJadwal(p, katalog(), SENIN)) {
    perHari.set(s.tanggal, (perHari.get(s.tanggal) ?? 0) + 1);
  }
  for (const [tanggal, n] of perHari) {
    assert(n <= MAKS_SESI_HARIAN, `${tanggal} berisi ${n} aktivitas`);
  }
});

Deno.test('every slot falls inside the seven-day week', () => {
  const slot = susunJadwal(profil(), katalog(), SENIN);
  const sah = new Set(
    Array.from({ length: 7 }, (_, i) => {
      const d = new Date(SENIN);
      d.setUTCDate(d.getUTCDate() + i);
      return d.toISOString().slice(0, 10);
    }),
  );
  for (const s of slot) assert(sah.has(s.tanggal), `tanggal di luar minggu: ${s.tanggal}`);
});

Deno.test('positions are numbered from one per day, in time order', () => {
  const slot = susunJadwal(
    profil({ fokus_perkembangan: ['komunikasi_ekspresif', 'rutinitas_pagi'] }),
    katalog(),
    SENIN,
  );
  const perHari = new Map<string, typeof slot>();
  for (const s of slot) {
    perHari.set(s.tanggal, [...(perHari.get(s.tanggal) ?? []), s]);
  }
  for (const [, harian] of perHari) {
    const urut = harian.map((s) => s.urutan).sort((a, b) => a - b);
    assertEquals(urut, harian.map((_, i) => i + 1));
    const waktu = harian.sort((a, b) => a.urutan - b.urutan).map((s) => s.waktu);
    assertEquals(waktu, [...waktu].sort());
  }
});

Deno.test('a slot only ever uses an activity at the level the rules chose', () => {
  const p = profil({ usia: 10, kemampuan_komunikasi: 'belum_verbal' });
  const k = katalog();
  for (const s of susunJadwal(p, k, SENIN)) {
    const aktivitas = k.find((a) => a.id === s.aktivitas_id)!;
    assertEquals(aktivitas.kategori, s.kategori);
    assertEquals(aktivitas.tingkat, tingkatAwal(s.kategori, p));
    assertEquals(s.tingkat_disesuaikan, aktivitas.tingkat);
  }
});

Deno.test('activities not suited to the child are skipped when alternatives exist', () => {
  const k = katalog().map((a) =>
    a.kategori === 'komunikasi' && a.judul.endsWith('varian 1')
      ? { ...a, cocok_untuk_komunikasi: ['lancar'] }
      : a
  );
  const p = profil({ kemampuan_komunikasi: 'belum_verbal' });
  const dipakai = susunJadwal(p, k, SENIN)
    .filter((s) => s.kategori === 'komunikasi')
    .map((s) => s.aktivitas_id);

  for (const id of dipakai) {
    const a = k.find((x) => x.id === id)!;
    assert(
      a.cocok_untuk_komunikasi.includes('belum_verbal'),
      `${a.judul} tidak cocok untuk anak ini tetapi tetap dijadwalkan`,
    );
  }
});

Deno.test('an empty day beats no plan: level match is relaxed before dropping a category', () => {
  // Nothing in the catalogue suits this child. Rather than returning nothing,
  // the rules fall back to the level alone.
  const k = katalog().map((a) => ({ ...a, cocok_untuk_komunikasi: ['lancar'] }));
  const slot = susunJadwal(profil({ kemampuan_komunikasi: 'belum_verbal' }), k, SENIN);
  assert(slot.length > 0, 'rencana kosong padahal katalog berisi');
});

Deno.test('a missing category in the catalogue does not break the rest', () => {
  const k = katalog().filter((a) => a.kategori !== 'motorik');
  const slot = susunJadwal(profil(), k, SENIN);
  assertEquals(slot.filter((s) => s.kategori === 'motorik').length, 0);
  assert(slot.length > 0);
});

// ------------------------------------------------------------ narrative --

Deno.test('the explanation only ever states numbers that are real', () => {
  const p = profil({
    nama_panggilan: 'Anak',
    fokus_perkembangan: ['komunikasi_ekspresif'],
    sensitivitas_sensorik: ['suara_keras'],
  });
  const porsi = porsiMingguan(p);
  const total = SEMUA_KATEGORI.reduce((n, k) => n + porsi[k], 0);
  const alasan = alasanDeterministik(p, porsi);

  assert(alasan.includes(String(total)), 'total sesi tidak disebut');
  assert(alasan.includes('Anak'), 'nama anak tidak disebut');

  const sah = new Set([String(total), String(porsi.komunikasi), String(porsi.sensorik)]);
  for (const angka of alasan.match(/\d+/g) ?? []) {
    assert(sah.has(angka), `angka ${angka} tidak berasal dari data`);
  }
});

Deno.test('the explanation never grades the child or names a diagnosis', () => {
  for (const k of SEMUA_KOMUNIKASI) {
    const p = profil({ kemampuan_komunikasi: k });
    const alasan = alasanDeterministik(p, porsiMingguan(p)).toLowerCase();
    for (const terlarang of [
      'autis', 'diagnos', 'derajat', 'keparahan', 'penderita', 'penyandang',
      'obat', 'dosis', 'skor', 'nilai anak', 'terlambat',
    ]) {
      assert(!alasan.includes(terlarang), `alasan memuat kata "${terlarang}"`);
    }
  }
});

Deno.test('lists read as Indonesian, not as a chain of "dan"', () => {
  assertEquals(gabungIndonesia([]), '');
  assertEquals(gabungIndonesia(['A']), 'A');
  assertEquals(gabungIndonesia(['A', 'B']), 'A dan B');
  assertEquals(gabungIndonesia(['A', 'B', 'C']), 'A, B, dan C');
  assertEquals(gabungIndonesia(['A', 'B', 'C', 'D']), 'A, B, C, dan D');
});

Deno.test('the hash is stable and order-sensitive', () => {
  assertEquals(cacah('a', 'b'), cacah('a', 'b'));
  assert(cacah('a', 'b') !== cacah('b', 'a'));
});
