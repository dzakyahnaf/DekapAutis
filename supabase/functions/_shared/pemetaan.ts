// Deterministic rules that turn a child profile into a weekly plan.
//
// This file is the whole of decision 17 in KEPUTUSAN.md. It is deliberately
// separate from generate-plan so the rules can be reviewed and changed without
// touching anything else, and so they can be tested without a database.
//
// The language model is never consulted here. It does not choose a category, a
// level, an activity or a time. Bab 4.2 forbids the product from grading a
// child, and a model picking the "right" level from a profile is exactly that
// with extra steps. Selection is arithmetic; the model only rewrites the
// explanation sentence into something warmer, and only in generate-plan.

export type Kategori =
  | 'komunikasi'
  | 'motorik'
  | 'sensorik'
  | 'kemandirian'
  | 'sosial';

export const SEMUA_KATEGORI: Kategori[] = [
  'komunikasi',
  'motorik',
  'sensorik',
  'kemandirian',
  'sosial',
];

export type KemampuanKomunikasi =
  | 'belum_verbal'
  | 'beberapa_kata'
  | 'kalimat_pendek'
  | 'lancar';

export interface ProfilAnak {
  id: string;
  nama_panggilan: string;
  usia: number;
  kemampuan_komunikasi: KemampuanKomunikasi;
  sensitivitas_sensorik: string[];
  fokus_perkembangan: string[];
}

/** Weekly ceiling per category. Raised from 3 to 7, see docs/DEVIATIONS.md. */
export const MAKS_SESI_MINGGUAN = 7;

/** Daily ceiling across all categories (docs/04 §3). */
export const MAKS_SESI_HARIAN = 5;

const SESI_DASAR = 2;

const TINGKAT_KOMUNIKASI: Record<KemampuanKomunikasi, number> = {
  belum_verbal: 1,
  beberapa_kata: 2,
  kalimat_pendek: 3,
  lancar: 4,
};

/** Which category each development focus adds sessions to. */
const FOKUS_KE_KATEGORI: Record<string, Kategori> = {
  komunikasi_ekspresif: 'komunikasi',
  memahami_instruksi: 'komunikasi',
  rutinitas_pagi: 'kemandirian',
  makan_berpakaian: 'kemandirian',
  bermain_bersama: 'sosial',
  menenangkan_diri: 'sensorik',
};

/**
 * Starting level for one category.
 *
 * Communication and social levels follow how the child communicates today.
 * Motor, sensory and independence follow age instead, because speech is not a
 * proxy for how well a child can jump or dress - treating it as one would turn
 * one answer into a general ranking of the child, which Bab 4.2 forbids.
 *
 * Either way this is only where the plan starts. The adaptation engine moves it
 * within days based on what actually happened, which is the number that means
 * something.
 */
export function tingkatAwal(kategori: Kategori, profil: ProfilAnak): number {
  if (kategori === 'komunikasi' || kategori === 'sosial') {
    return TINGKAT_KOMUNIKASI[profil.kemampuan_komunikasi] ?? 2;
  }
  const u = profil.usia;
  if (u <= 4) return 1;
  if (u <= 7) return 2;
  if (u <= 11) return 3;
  return 4;
}

/** Sessions per week for each category. */
export function porsiMingguan(profil: ProfilAnak): Record<Kategori, number> {
  const porsi = Object.fromEntries(
    SEMUA_KATEGORI.map((k) => [k, SESI_DASAR]),
  ) as Record<Kategori, number>;

  for (const fokus of profil.fokus_perkembangan ?? []) {
    const kategori = FOKUS_KE_KATEGORI[fokus];
    if (kategori) porsi[kategori] += 2;
  }

  // Any recorded sensory sensitivity earns one more sensory session: the point
  // is practice at recognising and managing it, on the child's own terms.
  if ((profil.sensitivitas_sensorik ?? []).length > 0) porsi.sensorik += 1;

  for (const k of SEMUA_KATEGORI) {
    porsi[k] = Math.min(porsi[k], MAKS_SESI_MINGGUAN);
  }
  return porsi;
}

/**
 * Small deterministic hash, so the same profile and week always produce the
 * same plan. Variety across children comes from the profile id; variety across
 * weeks comes from the start date. Math.random would make the plan unreproducible
 * and impossible to test.
 */
export function cacah(...bagian: (string | number)[]): number {
  let h = 2166136261;
  for (const b of bagian.join('|')) {
    h ^= b.charCodeAt(0);
    h = Math.imul(h, 16777619);
  }
  return Math.abs(h);
}

export interface Aktivitas {
  id: string;
  kategori: Kategori;
  tingkat: number;
  judul: string;
  durasi_menit: number;
  cocok_untuk_komunikasi: string[];
}

export interface Slot {
  aktivitas_id: string;
  kategori: Kategori;
  tanggal: string; // yyyy-mm-dd
  waktu: string; // HH:MM
  urutan: number;
  durasi_menit: number;
  tingkat_disesuaikan: number;
}

/** Hour blocks a session may start in. Rule E_jadwal narrows this in F4. */
const BLOK_JAM = [8, 10, 16];

function tanggalPlus(mulai: Date, hari: number): string {
  const d = new Date(mulai);
  d.setUTCDate(d.getUTCDate() + hari);
  return d.toISOString().slice(0, 10);
}

/**
 * Builds one week of scheduled activities.
 *
 * Selection order is fixed and auditable: for each category, take the levelled
 * activities that suit how the child communicates, then walk them with a
 * profile-derived offset so two children with the same profile shape do not get
 * an identical list while the same child gets a stable one.
 */
export function susunJadwal(
  profil: ProfilAnak,
  katalog: Aktivitas[],
  mulai: Date,
): Slot[] {
  const porsi = porsiMingguan(profil);
  const perHari: Slot[][] = Array.from({ length: 7 }, () => []);

  // Deterministic order, so a category is not always scheduled first.
  const urutanKategori = [...SEMUA_KATEGORI].sort(
    (a, b) => cacah(profil.id, a) - cacah(profil.id, b),
  );

  for (const kategori of urutanKategori) {
    const tingkat = tingkatAwal(kategori, profil);

    // Prefer activities marked as suiting this child's communication. If that
    // leaves nothing, fall back to the level alone rather than to no activity:
    // an empty day is worse than a slightly mismatched one.
    const padaTingkat = katalog.filter(
      (a) => a.kategori === kategori && a.tingkat === tingkat,
    );
    const cocok = padaTingkat.filter((a) =>
      (a.cocok_untuk_komunikasi ?? []).includes(profil.kemampuan_komunikasi),
    );
    const pilihan = (cocok.length > 0 ? cocok : padaTingkat).sort((a, b) =>
      a.judul.localeCompare(b.judul, 'id'),
    );
    if (pilihan.length === 0) continue;

    const geser = cacah(profil.id, kategori) % pilihan.length;

    for (let n = 0; n < porsi[kategori]; n++) {
      // Spread a category's sessions across the week rather than stacking them.
      const langkahHari = Math.max(1, Math.floor(7 / porsi[kategori]));
      let hari = (cacah(profil.id, kategori, 'hari') + n * langkahHari) % 7;

      // Respect the daily ceiling by walking forward to the next day with room.
      let putaran = 0;
      while (perHari[hari].length >= MAKS_SESI_HARIAN && putaran < 7) {
        hari = (hari + 1) % 7;
        putaran++;
      }
      if (perHari[hari].length >= MAKS_SESI_HARIAN) continue;

      const aktivitas = pilihan[(geser + n) % pilihan.length];
      const jam = BLOK_JAM[perHari[hari].length % BLOK_JAM.length];

      perHari[hari].push({
        aktivitas_id: aktivitas.id,
        kategori,
        tanggal: tanggalPlus(mulai, hari),
        waktu: `${String(jam).padStart(2, '0')}:00`,
        urutan: 0,
        durasi_menit: aktivitas.durasi_menit,
        tingkat_disesuaikan: tingkat,
      });
    }
  }

  // Number each day in time order, so "1 dari 5" on the routine card matches
  // what the caregiver actually sees.
  const slot: Slot[] = [];
  for (const hari of perHari) {
    hari.sort((a, b) => a.waktu.localeCompare(b.waktu));
    hari.forEach((s, i) => slot.push({ ...s, urutan: i + 1 }));
  }
  return slot;
}

/**
 * Joins a list the way Indonesian writes one: commas, then "dan" before the
 * last item. Joining with "dan" throughout reads as broken Indonesian, and this
 * sentence is shown to every caregiver on the plan screen.
 */
export function gabungIndonesia(bagian: string[]): string {
  if (bagian.length <= 1) return bagian.join('');
  if (bagian.length === 2) return `${bagian[0]} dan ${bagian[1]}`;
  return `${bagian.slice(0, -1).join(', ')}, dan ${bagian[bagian.length - 1]}`;
}

/**
 * The plain-language explanation, built from the numbers themselves.
 *
 * This is what ships when no model is reachable, and it is deliberately good
 * enough to ship on its own: the model's only job later is to make the same
 * facts read more warmly, never to add a fact that is not here.
 */
export function alasanDeterministik(
  profil: ProfilAnak,
  porsi: Record<Kategori, number>,
): string {
  const nama = profil.nama_panggilan;
  const label: Record<Kategori, string> = {
    komunikasi: 'Komunikasi',
    motorik: 'Motorik',
    sensorik: 'Sensorik',
    kemandirian: 'Kemandirian',
    sosial: 'Sosial',
  };

  const terbanyak = SEMUA_KATEGORI.filter((k) => porsi[k] > SESI_DASAR)
    .sort((a, b) => porsi[b] - porsi[a])
    .map((k) => `${label[k]} ${porsi[k]} sesi`);

  const total = SEMUA_KATEGORI.reduce((n, k) => n + porsi[k], 0);

  const bagian = [
    `Rencana minggu ini berisi ${total} sesi untuk ${nama}, tersebar di lima kategori.`,
  ];
  if (terbanyak.length > 0) {
    bagian.push(
      `Porsi terbesar ada di ${gabungIndonesia(terbanyak)}, mengikuti fokus yang Anda pilih.`,
    );
  }
  if ((profil.sensitivitas_sensorik ?? []).length > 0) {
    bagian.push(
      'Satu sesi sensorik tambahan disiapkan karena Anda mencatat ada sensitivitas sensorik.',
    );
  }
  bagian.push(
    'Tingkat awal ini akan menyesuaikan sendiri setelah Anda mencatat beberapa respons.',
  );
  return bagian.join(' ');
}
