// generate-plan - builds one week of stimulation activities from a child profile.
//
// The split that matters: activity selection is entirely deterministic
// arithmetic in _shared/pemetaan.ts, and the language model is only ever asked
// to rewrite an explanation sentence that was already true before it was called.
// A model that picked levels from a profile would be grading the child, which
// Bab 4.2 forbids - and it would also make the plan unreproducible and
// untestable.
//
// If no model key is configured, or the call fails, the deterministic
// explanation ships as-is. That is not a degraded mode worth apologising for:
// it is the same facts in slightly plainer words.

import { createClient } from 'jsr:@supabase/supabase-js@2';
import {
  alasanDeterministik,
  type Aktivitas,
  porsiMingguan,
  type ProfilAnak,
  susunJadwal,
} from '../_shared/pemetaan.ts';

const headerCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jawab(isi: unknown, status = 200): Response {
  return new Response(JSON.stringify(isi), {
    status,
    headers: { ...headerCors, 'Content-Type': 'application/json' },
  });
}

/** Errors reach the user, so they are Indonesian and name the next step. */
function gagal(pesan: string, status: number): Response {
  return jawab({ pesan }, status);
}

/** Monday of the week containing `d`, so plans line up with the day picker. */
function awalMinggu(d: Date): Date {
  const s = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const geser = (s.getUTCDay() + 6) % 7;
  s.setUTCDate(s.getUTCDate() - geser);
  return s;
}

/**
 * Asks the model to rewrite the explanation.
 *
 * Guarded three ways: it only ever sees the sentence we already wrote, its
 * output is discarded if it grew far beyond the original or mentions a number
 * that was not in the input, and any failure falls back silently. It cannot
 * introduce a fact because it is never given the raw data to invent one from.
 */
async function haluskanNarasi(alasan: string): Promise<string> {
  const kunci = Deno.env.get('GEMINI_API_KEY');
  if (!kunci) return alasan;

  const angkaAsli = new Set(alasan.match(/\d+/g) ?? []);

  try {
    const res = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': kunci },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{
              text: [
                'Anda menulis ulang satu paragraf Bahasa Indonesia agar terasa hangat dan mudah dibaca.',
                'Aturan mutlak:',
                '- Jangan menambah, mengubah, atau menghilangkan satu pun angka.',
                '- Jangan menambah fakta baru, saran, atau penilaian apa pun tentang anak.',
                '- Jangan menyebut diagnosis, tingkat spektrum, obat, atau dosis.',
                '- Jangan menyebut anak sebagai penderita atau penyandang.',
                '- Sapa pembaca dengan Anda. Maksimal tiga kalimat.',
                'Keluarkan hanya paragrafnya, tanpa pembuka dan tanpa pagar kode.',
              ].join('\n'),
            }],
          },
          contents: [{ role: 'user', parts: [{ text: alasan }] }],
          generationConfig: { temperature: 0.3, maxOutputTokens: 300 },
        }),
        signal: AbortSignal.timeout(8000),
      },
    );
    if (!res.ok) return alasan;

    const data = await res.json();
    const teks: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    if (!teks) return alasan;

    // A number that was not in the input is an invented fact. Discard the whole
    // rewrite rather than trying to repair it.
    const angkaBaru = (teks.match(/\d+/g) ?? []).filter((n: string) => !angkaAsli.has(n));
    if (angkaBaru.length > 0) return alasan;

    if (teks.length > alasan.length * 2) return alasan;
    if (/\b(diagnos|autis berat|autis ringan|level|obat|dosis|penderita|penyandang)/i.test(teks)) {
      return alasan;
    }
    return teks;
  } catch {
    return alasan;
  }
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

  // Acting as the caller, not as service_role: the plan is written under the
  // caregiver's own RLS policies, so this function cannot reach another
  // account's child even if it were asked to.
  const db = createClient(url, anon, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });

  let badan: { profil_anak_id?: string; mulai?: string };
  try {
    badan = await req.json();
  } catch {
    badan = {};
  }
  if (!badan.profil_anak_id) {
    return gagal('Profil anak belum dipilih.', 400);
  }

  const { data: profil, error: profilError } = await db
    .from('profil_anak')
    .select('id, nama_panggilan, usia, kemampuan_komunikasi, sensitivitas_sensorik, fokus_perkembangan')
    .eq('id', badan.profil_anak_id)
    .maybeSingle();

  if (profilError || !profil) {
    return gagal('Profil anak tidak ditemukan atau bukan milik akun ini.', 404);
  }

  const { data: katalog, error: katalogError } = await db
    .from('aktivitas')
    .select('id, kategori, tingkat, judul, durasi_menit, cocok_untuk_komunikasi');

  if (katalogError || !katalog || katalog.length === 0) {
    return gagal('Katalog aktivitas belum tersedia. Coba lagi sebentar lagi.', 503);
  }

  const mulai = awalMinggu(badan.mulai ? new Date(badan.mulai) : new Date());
  const selesai = new Date(mulai);
  selesai.setUTCDate(selesai.getUTCDate() + 6);

  const slot = susunJadwal(
    profil as ProfilAnak,
    katalog as Aktivitas[],
    mulai,
  );
  if (slot.length === 0) {
    return gagal('Rencana belum dapat disusun dari profil ini.', 422);
  }

  // A regenerated week replaces the previous one rather than sitting beside it,
  // so the plan screen never shows two versions of the same day.
  await db
    .from('rencana')
    .update({ status: 'digantikan' })
    .eq('profil_anak_id', profil.id)
    .eq('periode_mulai', mulai.toISOString().slice(0, 10))
    .eq('status', 'aktif');

  const { data: rencana, error: rencanaError } = await db
    .from('rencana')
    .insert({
      profil_anak_id: profil.id,
      periode_mulai: mulai.toISOString().slice(0, 10),
      periode_selesai: selesai.toISOString().slice(0, 10),
    })
    .select()
    .single();

  if (rencanaError || !rencana) {
    return gagal('Rencana belum tersimpan. Periksa koneksi Anda, lalu coba lagi.', 500);
  }

  const { error: jadwalError } = await db.from('jadwal_aktivitas').insert(
    slot.map((s) => ({
      rencana_id: rencana.id,
      aktivitas_id: s.aktivitas_id,
      tanggal: s.tanggal,
      waktu: s.waktu,
      urutan: s.urutan,
      durasi_menit: s.durasi_menit,
      tingkat_disesuaikan: s.tingkat_disesuaikan,
    })),
  );

  if (jadwalError) {
    await db.from('rencana').delete().eq('id', rencana.id);
    return gagal('Jadwal belum tersimpan. Periksa koneksi Anda, lalu coba lagi.', 500);
  }

  const porsi = porsiMingguan(profil as ProfilAnak);
  const alasan = alasanDeterministik(profil as ProfilAnak, porsi);

  return jawab({
    rencana_id: rencana.id,
    periode_mulai: rencana.periode_mulai,
    periode_selesai: rencana.periode_selesai,
    jumlah_sesi: slot.length,
    porsi,
    alasan: await haluskanNarasi(alasan),
  });
});
