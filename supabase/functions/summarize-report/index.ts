// summarize-report - turns finished figures into sentences a therapist can read.
//
// The model computes nothing. Every number arrives already calculated in Dart,
// and the model is asked only to arrange them. Anything it writes is then
// checked against the closed set of figures it was given, and rejected outright
// if it contains one that was not there.
//
// There is no repair step. A narrative that had to be corrected is one whose
// reasoning we cannot see, and the deterministic template is a perfectly good
// document - plainer, and true. This matters more here than anywhere else in
// the product: the reader is a professional who cannot tell an invented
// percentage from a measured one, and may act on it.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import { rantaiDariEnv } from '../_shared/llm.ts';
import {
  type MetrikMasukan,
  narasiDeterministik,
  verifikasiAngka,
  verifikasiBahasa,
} from '../_shared/narasi.ts';

const headerCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jawab(isi: unknown, status = 200): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: { ...headerCors, 'Content-Type': 'application/json' },
  });
}

function gagal(pesan: string, status: number): Response {
  return jawab({ pesan }, status);
}

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
  if (!url || !anon) {
    return gagal('Layanan sedang tidak dapat memproses permintaan ini.', 500);
  }

  const db = createClient(url, anon, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });

  let badan: { profil_anak_id?: string; metrik?: MetrikMasukan };
  try {
    badan = await req.json();
  } catch {
    badan = {};
  }
  const m = badan.metrik;
  if (!badan.profil_anak_id || !m) {
    return gagal('Data laporan belum lengkap.', 400);
  }

  // The baseline. Everything below either improves on its wording or falls back
  // to it, and it is written to be shippable on its own.
  const bawaan = narasiDeterministik(m);
  let narasi = bawaan;
  let sumberNarasi: 'model' | 'templat' = 'templat';
  let alasanTolak: string | null = null;

  const rantai = rantaiDariEnv();
  if (!rantai.kosong) {
    try {
      const hasil = await rantai.chat(
        [
          {
            peran: 'system',
            teks: [
              'Anda menulis ringkasan untuk tenaga profesional dari catatan harian pengasuh anak dengan spektrum autisme.',
              '',
              'Aturan yang tidak boleh dilanggar:',
              '- Gunakan HANYA angka yang ada pada data. Jangan menghitung selisih, rata-rata, atau persentase baru. Satu angka yang tidak ada pada data membuat seluruh ringkasan dibuang.',
              '- Tanpa interpretasi klinis, tanpa diagnosis, tanpa tingkat atau derajat spektrum, tanpa prognosis.',
              '- Tanpa skor tunggal atas kemampuan anak.',
              '- Jangan membandingkan anak dengan anak lain atau dengan "anak seusianya".',
              '- Jangan menyebut anak sebagai penderita atau penyandang.',
              '- Nada deskriptif, bukan memuji. Tulis "respons Mudah pada Komunikasi bergerak dari 45% menjadi 78%", bukan "menunjukkan kemajuan yang baik".',
              '- Bahasa Indonesia, 3 sampai 5 kalimat, sapaan "Anda" bila perlu menyapa.',
              '',
              'Keluarkan hanya paragrafnya, tanpa pembuka dan tanpa pagar kode.',
            ].join('\n'),
          },
          {
            peran: 'user',
            teks:
              'Data laporan (JSON):\n' + JSON.stringify(m, null, 2) +
              '\n\nRingkasan versi datar yang sudah benar, susun ulang agar lebih mudah dibaca ' +
              'tanpa mengubah satu pun angkanya:\n' + bawaan,
          },
        ],
        { suhu: 0.2, maksToken: 500, batasMs: 12000 },
      );

      const calon = hasil.teks.replace(/^```(?:\w+)?|```$/g, '').trim();

      // The check the whole design exists for.
      const angka = verifikasiAngka(calon, m);
      const bahasa = verifikasiBahasa(calon);

      if (angka.sah && bahasa.sah && calon.length > 40) {
        narasi = calon;
        sumberNarasi = 'model';
      } else {
        alasanTolak = angka.alasan ?? bahasa.alasan ?? 'ringkasan terlalu pendek';
      }
    } catch {
      alasanTolak = 'model tidak dapat dihubungi';
    }
  }

  const { data: laporan, error } = await db
    .from('laporan')
    .insert({
      profil_anak_id: badan.profil_anak_id,
      periode_mulai: m.periode_mulai,
      periode_selesai: m.periode_selesai,
      metrik: {
        aktivitas_terjadwal: m.aktivitas_terjadwal,
        aktivitas_tercatat: m.aktivitas_tercatat,
        persen_tercatat: m.persen_tercatat,
        rata_sesi_harian: m.rata_sesi_harian,
        jumlah_hari: m.jumlah_hari,
      },
      per_kategori: m.per_kategori,
      ringkasan: narasi,
      penanda_perhatian: m.penanda_perhatian,
    })
    .select()
    .single();

  if (error || !laporan) {
    return gagal(
      'Laporan belum tersimpan. Periksa koneksi Anda, lalu coba lagi.',
      500,
    );
  }

  return jawab({
    laporan_id: laporan.id,
    ringkasan: narasi,
    // Surfaced so a rejection is visible in logs rather than silent. A rise in
    // rejections means the instruction stopped holding, and we want to know
    // before a therapist reads one.
    sumber_narasi: sumberNarasi,
    alasan_tolak: alasanTolak,
  });
});
