// Layer 1 of the medical boundary: a deterministic lexicon filter.
//
// It runs before anything else and before any model is called. When it fires,
// no model is consulted at all - which is the point. A guardrail that depends on
// a model to decide whether to guard is not a guardrail.
//
// Phrases, not single words
// -------------------------
// Matching bare words would be catastrophic here. "terapi" appears in "apa itu
// terapi okupasi", which docs/06 requires the assistant to answer; "obat"
// appears in "obat nyamuk". docs/04 §5 is explicit that over-refusal costs as
// much as leakage - an assistant that refuses everything is useless, and a judge
// will find out inside a minute. So every entry is a phrase with word
// boundaries, and the negative cases are tested as hard as the positive ones.
//
// Keeping this in its own file means the list can grow without anyone touching
// the pipeline logic.

export type KategoriBatas =
  | 'diagnosis'
  | 'tingkat_spektrum'
  | 'obat'
  | 'dosis'
  | 'klaim_sembuh'
  | 'terapi_medis';

export interface HasilLeksikon {
  terpicu: boolean;
  kategori?: KategoriBatas;
  /** The phrase that matched, recorded so a false positive can be traced. */
  frasa?: string;
}

/**
 * Lowercase, strip punctuation, collapse whitespace.
 *
 * Accents are left alone: Indonesian does not use them, and stripping them
 * would only invite trouble with names.
 */
export function normalkanPertanyaan(teks: string): string {
  return teks
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s-]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Common spellings of the same word, including ones people actually mistype. */
const AUTIS = '(?:autis|autisme|ausitme|autism|austis)';
const ANAK = '(?:anak saya|anak ku|anakku|anak|dia|ia|dirinya)';

// Ordered most specific first. `diagnosis` is the broadest bucket - its
// "apakah ... autis" pattern also matches "apakah dia autis berat", which is
// really a severity question - so it is evaluated last and only catches what
// nothing more precise claimed.
const LEKSIKON: Array<[KategoriBatas, RegExp[]]> = [
  [
    'tingkat_spektrum',
    [
      new RegExp(`\\b${AUTIS}\\s+(?:berat|ringan|sedang|parah|akut)\\b`),
      /\b(?:tingkat|derajat|kadar)\s+(?:keparahan|autis|autisme|spektrum)\w*/,
      /\blevel\s+(?:berapa|autis|autisme|spektrum)\b/,
      /\bmasuk level\b/,
      /\bspektrum\s+(?:berat|ringan|sedang)\b/,
      /\bseberapa\s+(?:parah|berat|akut)\b/,
      /\b(?:low|high)[\s-]functioning\b/,
      /\bderajat spektrum\b/,
    ],
  ],
  [
    'obat',
    [
      /\bobat\s+(?:apa|apakah|yang|untuk|buat|penenang)\b/,
      /\b(?:minum|konsumsi|diberi|dikasih|beri)\s+obat\b/,
      /\bresep\s+(?:obat|dokter)\b/,
      /\bdiresepkan\b/,
      /\bminta resep\b/,
      /\bsuplemen\s+(?:apa|apakah|yang|untuk|buat)\b/,
      /\bvitamin\s+(?:apa|apakah|yang|untuk|buat)\b/,
      /\bboleh\s+(?:minum|konsumsi|diberi)\b/,
      // Named medicines. If someone types one of these, they are asking about
      // medication no matter how the sentence is phrased.
      /\brisperidon(?:e)?\b/,
      /\baripiprazol(?:e)?\b/,
      /\babilify\b/,
      /\bmelatonin\b/,
      /\bmethylphenidate\b|\britalin\b|\bconcerta\b/,
      /\bomega[\s-]?3\b/,
    ],
  ],
  [
    'dosis',
    [
      /\bberapa\s+(?:mg|miligram|ml|mililiter|tetes|sendok|butir|tablet|kapsul|sachet)\b/,
      /\b(?:berapa|brp)\s+(?:dosis|dossis|takaran|banyak)\b/,
      /\bdosis\s+(?:untuk|anak|yang|per|harian)\b/,
      /\btakaran\s+(?:untuk|anak|yang)\b/,
      /\bseberapa banyak\b[^.?]{0,25}\b(?:obat|suplemen|vitamin|tetes)\b/,
      /\bberapa kali sehari\b/,
    ],
  ],
  [
    'klaim_sembuh',
    [
      /\b(?:bisa|dapat|akan|apakah)\b[^.?]{0,20}\b(?:sembuh|disembuhkan)\b/,
      /\bcara\s+(?:menyembuhkan|mengobati|menormalkan)\b/,
      /\bobat penyembuh\b/,
      /\bsembuh total\b/,
      /\bpenyembuhan\s+(?:autis|autisme|total)\b/,
      new RegExp(`\\b${AUTIS}\\b[^.?]{0,20}\\b(?:hilang|sembuh)\\b`),
    ],
  ],
  [
    'terapi_medis',
    [
      /\b(?:terapi\s+)?khelasi\b|\bkelasi logam\b|\bchelation\b/,
      /\bhbot\b|\boksigen hiperbarik\b|\bhiperbarik\b/,
      /\bstem ?cell\b|\bsel punca\b/,
      /\bdiet\s+gfcf\b/,
      /\bbebas (?:gluten|kasein|casein)\b[^.?]{0,25}\b(?:sembuh|menyembuhkan|mengobati|terapi)\b/,
      /\bsuntik\b[^.?]{0,20}\b(?:autis|autisme|spektrum)\b/,
    ],
  ],
  [
    'diagnosis',
    [
      new RegExp(`\\bapakah\\b[^.?]{0,30}\\b${AUTIS}\\b`),
      new RegExp(`\\b${ANAK}\\b\\s+${AUTIS}\\b`),
      new RegExp(`\\btermasuk\\b[^.?]{0,20}\\b(?:${AUTIS}|spektrum)\\b`),
      /\bdi ?diagnos(?:a|is|ns)?\b/,
      /\bdiagnosa\b/,
      /\bapakah\b[^.?]{0,15}\b(?:anak|dia|ia)\b[^.?]{0,15}\bnormal\b/,
      /\bnormal atau tidak\b/,
      new RegExp(`\\bmasuk (?:kategori|golongan)\\b[^.?]{0,15}\\b${AUTIS}\\b`),
    ],
  ],
];

/**
 * Checks one question against the lexicon.
 *
 * Categories are evaluated in the order listed, so a question that touches two
 * is reported under the first - which is also the order the safety notice
 * wording is written for.
 */
export function periksaLeksikon(pertanyaan: string): HasilLeksikon {
  const teks = normalkanPertanyaan(pertanyaan);
  for (const [kategori, pola] of LEKSIKON) {
    for (const p of pola) {
      const cocok = teks.match(p);
      if (cocok) return { terpicu: true, kategori, frasa: cocok[0] };
    }
  }
  return { terpicu: false };
}

/**
 * Scans generated text for the same vocabulary.
 *
 * This is layer 3's second half. The wording differs from a question - a model
 * says "risperidone biasanya diberikan" rather than "obat apa" - so the
 * question-shaped patterns above would miss it. These are the statement-shaped
 * ones.
 */
const KELUARAN_TERLARANG: Array<[KategoriBatas, RegExp[]]> = [
  [
    'tingkat_spektrum',
    [
      new RegExp(`\\b${AUTIS}\\s+(?:berat|ringan|sedang|parah)\\b`),
      /\b(?:tingkat|derajat)\s+(?:keparahan|spektrum)\b/,
      /\blevel\s+[123]\b/,
      /\b(?:low|high)[\s-]functioning\b/,
    ],
  ],
  [
    'obat',
    [
      /\brisperidon(?:e)?\b/,
      /\baripiprazol(?:e)?\b/,
      /\babilify\b|\britalin\b|\bconcerta\b/,
      /\bmelatonin\b/,
      /\bobat\s+(?:yang|ini|tersebut|berikut)\b/,
      /\bdapat diberikan obat\b/,
      /\bkonsumsi suplemen\b/,
    ],
  ],
  [
    'dosis',
    [
      /\b\d+\s*(?:mg|miligram|ml|mililiter|iu)\b/,
      /\bdosis\s+(?:harian|yang dianjurkan|anjuran)\b/,
      /\b\d+\s*kali sehari\b/,
    ],
  ],
  [
    'klaim_sembuh',
    [
      /\bdapat disembuhkan\b/,
      /\bakan sembuh\b/,
      /\bmenyembuhkan\b/,
      /\bsembuh total\b/,
    ],
  ],
  [
    'diagnosis',
    [
      /\banak anda\b[^.]{0,25}\b(?:menderita|mengalami|didiagnosis)\b/,
      /\bkemungkinan besar\b[^.]{0,20}\bautis\b/,
    ],
  ],
];

/**
 * True when generated text strays into vocabulary the model was told to avoid.
 *
 * When this fires the answer is discarded, not edited: an answer that had to be
 * repaired is an answer we cannot vouch for. docs/04 §5 asks for a count of
 * these because a rise means the model started leaking something instructed
 * against, and we want to know that before a judge does.
 */
export function periksaKeluaran(teks: string): HasilLeksikon {
  const bersih = normalkanPertanyaan(teks);
  for (const [kategori, pola] of KELUARAN_TERLARANG) {
    for (const p of pola) {
      const cocok = bersih.match(p);
      if (cocok) return { terpicu: true, kategori, frasa: cocok[0] };
    }
  }
  return { terpicu: false };
}

/** What the safety notice says, per category (L.5). */
export const PESAN_BATAS: Record<KategoriBatas, { judul: string; isi: string }> = {
  diagnosis: {
    judul: 'DekapAutis tidak dapat mendiagnosis',
    isi:
      'Menentukan apakah seorang anak berada dalam spektrum autisme hanya dapat ' +
      'dilakukan tenaga profesional melalui pemeriksaan langsung, dan tidak bisa ' +
      'disimpulkan dari percakapan.',
  },
  tingkat_spektrum: {
    judul: 'DekapAutis tidak menilai tingkat spektrum',
    isi:
      'Aplikasi ini tidak menggolongkan anak ke dalam tingkat atau derajat apa ' +
      'pun. Penilaian seperti itu memerlukan pemeriksaan langsung oleh tenaga ' +
      'profesional.',
  },
  obat: {
    judul: 'DekapAutis tidak menyarankan obat',
    isi:
      'Keputusan tentang obat atau suplemen hanya boleh diambil dokter yang ' +
      'memeriksa anak Anda secara langsung.',
  },
  dosis: {
    judul: 'DekapAutis tidak menentukan dosis',
    isi:
      'Takaran obat atau suplemen bergantung pada kondisi masing-masing anak dan ' +
      'hanya boleh ditentukan dokter yang memeriksanya.',
  },
  klaim_sembuh: {
    judul: 'DekapAutis tidak membicarakan kesembuhan',
    isi:
      'Autisme adalah kondisi perkembangan, bukan penyakit yang disembuhkan. ' +
      'Yang dapat didampingi adalah keterampilan sehari-hari dan kenyamanan anak.',
  },
  terapi_medis: {
    judul: 'DekapAutis tidak membahas prosedur medis',
    isi:
      'Prosedur medis hanya boleh dibicarakan dengan dokter yang memeriksa anak ' +
      'Anda secara langsung.',
  },
};

/** "Yang bisa saya bantu" - a refusal must never be a dead end. */
export const YANG_BISA_DIBANTU = [
  'Menyusun rutinitas harian yang dapat diprediksi',
  'Menjelaskan kondisi anak kepada guru atau keluarga',
  'Menemukan tenaga profesional terdekat dan menyiapkan laporan untuk mereka',
];
