// ask - the assistant, with the medical boundary built into the pipeline.
//
//   Pertanyaan
//        │
//   [Lapis 1] lexicon, deterministic ──terpicu──▶ pemberitahuan batas aman
//        │ lolos                                   (tanpa memanggil model sama sekali)
//   [Lapis 2] klasifikasi maksud oleh model ──terlarang──▶ pemberitahuan batas aman
//        │ aman
//   embed → cari_potongan (pgvector + teks penuh, RRF, 8 teratas)
//        │
//   pembangkitan: jawab HANYA dari konteks, wajib menyebut nomor rujukan
//        │
//   [Lapis 3] verifikasi keluaran ──tak berdasar──▶ "informasi belum tersedia"
//        │                        └─menyebut obat/tingkat──▶ jawaban DIBUANG
//   jawaban + keping rujukan bernomor
//
// Layer 3 is not optional and is not a formatting pass. If the model names a
// medicine or grades the child despite being told not to, the answer is thrown
// away rather than edited: an answer that had to be repaired is one we cannot
// vouch for. Every trip is written to log_batas_aman, because a rise in
// verifikasi_keluaran means the model started leaking something it was
// instructed against, and we want to know that before a judge does.

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import { rantaiDariEnv, SemuaPenyediaGagal } from '../_shared/llm.ts';
import {
  type KategoriBatas,
  PESAN_BATAS,
  periksaKeluaran,
  periksaLeksikon,
  YANG_BISA_DIBANTU,
} from '../_shared/lexicon.ts';

const headerCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface Potongan {
  id: string;
  dokumen_id: string;
  halaman: number | null;
  teks: string;
  judul: string;
  penerbit: string;
  tahun: number;
  url: string;
}

function jawab(isi: unknown, status = 200): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: { ...headerCors, 'Content-Type': 'application/json' },
  });
}

function gagal(pesan: string, status: number): Response {
  return jawab({ jenis: 'galat', pesan }, status);
}

/** The safety notice payload the L.5 screen renders. */
function payloadBatas(kategori: KategoriBatas) {
  const pesan = PESAN_BATAS[kategori];
  return {
    jenis: 'batas_aman' as const,
    batas: {
      kategori,
      judul: pesan.judul,
      isi: pesan.isi,
      yang_bisa_dibantu: YANG_BISA_DIBANTU,
    },
  };
}

/**
 * Records a boundary trip.
 *
 * Written with the service role because log_batas_aman has no insert policy for
 * signed-in accounts, and deliberately so: the questions recorded here are the
 * most identifying text in the system, since a caregiver only trips the
 * boundary by asking about their own child. Failing to log must never fail the
 * request - the user still needs their notice.
 */
async function catatBatas(
  admin: SupabaseClient | null,
  penggunaId: string | null,
  pertanyaan: string,
  lapisan: 'leksikon' | 'klasifikasi' | 'verifikasi_keluaran',
  kategori: KategoriBatas,
): Promise<void> {
  if (!admin) return;
  try {
    await admin.from('log_batas_aman').insert({
      pengguna_id: penggunaId,
      pertanyaan,
      lapisan_pemicu: lapisan,
      kategori,
    });
  } catch {
    // Logging is observability, not correctness.
  }
}

const KATEGORI_SAH: KategoriBatas[] = [
  'diagnosis',
  'tingkat_spektrum',
  'obat',
  'dosis',
  'klaim_sembuh',
  'terapi_medis',
];

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: headerCors });
  if (req.method !== 'POST') return gagal('Permintaan tidak dikenali.', 405);

  const authorization = req.headers.get('Authorization');
  if (!authorization) {
    return gagal('Sesi Anda sudah berakhir. Masuk kembali, lalu ulangi.', 401);
  }

  const url = Deno.env.get('SUPABASE_URL');
  const anon = Deno.env.get('SUPABASE_ANON_KEY') ??
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY');
  const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !anon) {
    return gagal('Layanan sedang tidak dapat memproses permintaan ini.', 500);
  }

  const db = createClient(url, anon, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const admin = service
    ? createClient(url, service, { auth: { persistSession: false } })
    : null;

  let badan: { pertanyaan?: string; profil_anak_id?: string };
  try {
    badan = await req.json();
  } catch {
    badan = {};
  }
  const pertanyaan = (badan.pertanyaan ?? '').trim();
  if (pertanyaan.length < 3) {
    return gagal('Tuliskan pertanyaan Anda lebih dulu.', 400);
  }

  const { data: userData } = await db.auth.getUser();
  const penggunaId = userData?.user?.id ?? null;

  // ===================================================== Lapis 1: leksikon ==
  // Deterministic, cheap, and first. When it fires no model is consulted at
  // all - a guardrail that asks a model whether to guard is not a guardrail.
  const leksikon = periksaLeksikon(pertanyaan);
  if (leksikon.terpicu && leksikon.kategori) {
    await catatBatas(admin, penggunaId, pertanyaan, 'leksikon', leksikon.kategori);
    return jawab(payloadBatas(leksikon.kategori));
  }

  const rantai = rantaiDariEnv();

  // ================================================ Lapis 2: klasifikasi ==
  // Catches the paraphrases layer 1 cannot: "Menurut Anda Bima ini termasuk
  // yang mana ya kalau dibandingkan anak lain seusianya?" contains no banned
  // phrase and is still a request to grade a child.
  //
  // A parse failure is treated as safe but noted. Letting a malformed model
  // reply block every question would be a worse failure than the one it guards
  // against, and layer 3 still stands behind it.
  if (!rantai.kosong) {
    try {
      const hasil = await rantai.chat(
        [
          {
            peran: 'system',
            teks: [
              'Anda mengklasifikasikan maksud satu pertanyaan dari pengasuh anak dengan spektrum autisme.',
              'Kembalikan HANYA JSON, tanpa pembuka dan tanpa pagar kode:',
              '{"kategori":"aman|diagnosis|tingkat_spektrum|obat|dosis|klaim_sembuh|terapi_medis","alasan":"..."}',
              '',
              'Pilih selain "aman" hanya jika pertanyaan meminta:',
              '- kesimpulan apakah anak berada dalam spektrum (diagnosis)',
              '- penilaian tingkat, derajat, atau perbandingan dengan anak lain (tingkat_spektrum)',
              '- anjuran obat, suplemen, atau vitamin (obat)',
              '- takaran atau dosis (dosis)',
              '- kesembuhan atau cara menyembuhkan (klaim_sembuh)',
              '- prosedur medis seperti khelasi atau oksigen hiperbarik (terapi_medis)',
              '',
              'Pertanyaan tentang rutinitas, komunikasi, sensorik, sekolah, atau',
              'penjelasan umum layanan seperti terapi okupasi adalah "aman".',
            ].join('\n'),
          },
          { peran: 'user', teks: pertanyaan },
        ],
        { json: true, suhu: 0, maksToken: 200, batasMs: 6000 },
      );

      const bersih = hasil.teks.replace(/^```(?:json)?|```$/g, '').trim();
      const parsed = JSON.parse(bersih) as { kategori?: string };
      const kategori = parsed.kategori as KategoriBatas | 'aman' | undefined;

      if (kategori && kategori !== 'aman' && KATEGORI_SAH.includes(kategori)) {
        await catatBatas(admin, penggunaId, pertanyaan, 'klasifikasi', kategori);
        return jawab(payloadBatas(kategori));
      }
    } catch {
      // Unreachable model or unparseable reply. Continue; layers 1 and 3 hold.
    }
  }

  // ======================================================= pengambilan ==
  // A failed embedding is not a failed request: retrieval drops to full-text
  // alone and the answer is labelled "mode terbatas". The user still gets
  // sourced information, which is the promise that matters.
  const embed = await rantai.embed(pertanyaan);

  const { data: potonganData, error: cariError } = await db.rpc('cari_potongan', {
    p_embedding: embed ? JSON.stringify(embed.vektor) : null,
    p_kueri: pertanyaan,
    p_batas: 8,
  });

  if (cariError) {
    return gagal(
      'Basis pengetahuan sedang tidak dapat dibaca. Coba lagi sebentar lagi.',
      503,
    );
  }

  const potongan = (potonganData ?? []) as Potongan[];
  const sumber = potongan.map((p, i) => ({
    nomor: i + 1,
    dokumen_id: p.dokumen_id,
    judul: p.judul,
    penerbit: p.penerbit,
    tahun: p.tahun,
    halaman: p.halaman,
    kutipan: p.teks,
    url: p.url,
  }));

  const { data: jumlahDokumen } = await db.rpc('jumlah_dokumen_terindeks');

  // Nothing retrieved means nothing to ground an answer in. Saying so is the
  // correct answer, not a failure to produce one.
  if (potongan.length === 0) {
    return jawab({
      jenis: 'belum_tersedia',
      teks:
        'Informasi untuk pertanyaan ini belum tersedia di basis pengetahuan '
        + 'DekapAutis. Anda dapat menanyakannya kepada tenaga profesional yang '
        + 'mendampingi anak Anda.',
      sumber: [],
      jumlah_dokumen: jumlahDokumen ?? 0,
      mode_terbatas: embed === null,
    });
  }

  // ================================== mode terbatas: tidak ada model sama sekali ==
  if (rantai.kosong) {
    return jawab({
      jenis: 'mode_terbatas',
      teks:
        'Layanan perangkuman sedang terbatas, jadi kutipan sumber ditampilkan '
        + 'apa adanya di bawah ini.',
      sumber,
      jumlah_dokumen: jumlahDokumen ?? 0,
      mode_terbatas: true,
      penyedia: null,
    });
  }

  // ========================================================= pembangkitan ==
  const konteks = potongan
    .map((p, i) => `[${i + 1}] ${p.judul} (${p.penerbit}, ${p.tahun})\n${p.teks}`)
    .join('\n\n');

  let teksJawaban: string;
  let penyedia: string;
  try {
    const hasil = await rantai.chat(
      [
        {
          peran: 'system',
          teks: [
            'Anda adalah pendamping informasi untuk orang tua dan pengasuh anak dengan spektrum autisme.',
            '',
            'Aturan yang tidak boleh dilanggar:',
            '- Jawab HANYA dari potongan konteks yang diberikan. Jika konteks tidak memuat jawabannya, katakan informasi belum tersedia dan sarankan berkonsultasi dengan tenaga profesional.',
            '- Sertakan nomor rujukan seperti [1] atau [2] yang menunjuk ke potongan yang Anda pakai. Setiap paragraf wajib memuat minimal satu nomor.',
            '- Jangan pernah mendiagnosis, menilai tingkat atau derajat spektrum, membandingkan anak dengan anak lain, atau menyebut obat, suplemen, maupun dosis.',
            '- Jangan menyebut anak sebagai penderita atau penyandang. Gunakan "anak".',
            '- Bahasa Indonesia, sapaan "Anda", maksimal empat kalimat.',
          ].join('\n'),
        },
        {
          peran: 'user',
          teks: `Konteks:\n\n${konteks}\n\nPertanyaan pengasuh: ${pertanyaan}`,
        },
      ],
      { suhu: 0.2, maksToken: 600, batasMs: 12000 },
    );
    teksJawaban = hasil.teks;
    penyedia = hasil.penyedia;
  } catch (e) {
    // Every provider is down. Fall back to the sources themselves rather than
    // to a white screen: the user still gets information they can open.
    if (e instanceof SemuaPenyediaGagal) {
      return jawab({
        jenis: 'mode_terbatas',
        teks:
          'Layanan perangkuman sedang tidak tersedia, jadi kutipan sumber '
          + 'ditampilkan apa adanya di bawah ini.',
        sumber,
        jumlah_dokumen: jumlahDokumen ?? 0,
        mode_terbatas: true,
        penyedia: null,
      });
    }
    return gagal('Jawaban belum dapat disusun. Coba lagi sebentar lagi.', 502);
  }

  // ============================================ Lapis 3: verifikasi keluaran ==

  // 3a. An answer citing nothing is an answer we cannot trace, whatever it
  //     says. KNF-07 requires potongan_dirujuk never to be empty on success.
  const dirujuk = [...teksJawaban.matchAll(/\[(\d{1,2})\]/g)]
    .map((m) => Number(m[1]))
    .filter((n) => n >= 1 && n <= sumber.length);
  const nomorUnik = [...new Set(dirujuk)];

  if (nomorUnik.length === 0) {
    return jawab({
      jenis: 'belum_tersedia',
      teks:
        'Informasi untuk pertanyaan ini belum dapat ditelusuri ke sumber yang '
        + 'ada. Anda dapat menanyakannya kepada tenaga profesional yang '
        + 'mendampingi anak Anda.',
      sumber: [],
      jumlah_dokumen: jumlahDokumen ?? 0,
      mode_terbatas: embed === null,
    });
  }

  // 3b. The model was told not to name medicines or grade the child. If it did
  //     anyway, the answer is discarded rather than trimmed - and the event is
  //     recorded, because it means the instruction stopped holding.
  const keluaran = periksaKeluaran(teksJawaban);
  if (keluaran.terpicu && keluaran.kategori) {
    await catatBatas(
      admin,
      penggunaId,
      pertanyaan,
      'verifikasi_keluaran',
      keluaran.kategori,
    );
    return jawab(payloadBatas(keluaran.kategori));
  }

  // Only the sources the answer actually cited are returned, renumbered from
  // one. The text has to be renumbered with them: an answer that says [3] while
  // the panel shows two chips is worse than no citation at all, because the
  // reader has no way to tell which claim came from where.
  const urut = [...nomorUnik].sort((a, b) => a - b);
  const petaNomor = new Map(urut.map((lama, i) => [lama, i + 1]));
  const teksAkhir = teksJawaban.replace(
    /\[(\d{1,2})\]/g,
    (cocok, angka) => {
      const baru = petaNomor.get(Number(angka));
      return baru === undefined ? cocok : `[${baru}]`;
    },
  );

  return jawab({
    jenis: 'jawaban',
    teks: teksAkhir,
    sumber: urut.map((n, i) => ({ ...sumber[n - 1], nomor: i + 1 })),
    jumlah_dokumen: jumlahDokumen ?? 0,
    mode_terbatas: embed === null,
    penyedia,
  });
});
