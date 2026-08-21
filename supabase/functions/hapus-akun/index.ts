// hapus-akun - permanently deletes the calling account and all of its data.
//
// Why this exists at all: removing a row from auth.users requires the service
// role key, and that key must never be present on a device (CLAUDE.md rule 4).
// So the client asks, and the deletion happens here.
//
// Every user-owned table cascades from auth.users, so one delete is the whole
// operation. scripts/test_hapus_akun.sql proves that by counting rows in each
// table afterwards - the cascade is verified, not assumed.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const headerCors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** Errors reach the user, so they are Indonesian and say what to do next. */
function gagal(pesan: string, status: number): Response {
  return new Response(JSON.stringify({ pesan }), {
    status,
    headers: { ...headerCors, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: headerCors });
  }
  if (req.method !== 'POST') {
    return gagal('Permintaan tidak dikenali.', 405);
  }

  const authorization = req.headers.get('Authorization');
  if (!authorization) {
    return gagal('Sesi Anda sudah berakhir. Masuk kembali, lalu ulangi.', 401);
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRoleKey) {
    return gagal('Layanan sedang tidak dapat memproses permintaan ini.', 500);
  }

  // Identify the caller from their own token. The account deleted is always the
  // caller's own: there is no id parameter, so no request can be crafted to
  // delete someone else.
  const sebagaiPengguna = createClient(url, serviceRoleKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await sebagaiPengguna.auth.getUser();
  if (userError || !userData?.user) {
    return gagal('Sesi Anda sudah berakhir. Masuk kembali, lalu ulangi.', 401);
  }

  const penggunaId = userData.user.id;

  const admin = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });

  // Hard delete. `shouldSoftDelete` defaults to false and is passed explicitly
  // so nobody later reads this line as ambiguous: Bab 4.3 promises removal, not
  // a flag, and a soft delete would leave the child's records in place.
  const { error: hapusError } = await admin.auth.admin.deleteUser(penggunaId, false);
  if (hapusError) {
    return gagal(
      'Penghapusan akun belum berhasil. Data Anda belum berubah. Coba lagi sebentar lagi.',
      500,
    );
  }

  return new Response(
    JSON.stringify({ pesan: 'Akun dan seluruh data terkait telah dihapus.' }),
    { headers: { ...headerCors, 'Content-Type': 'application/json' } },
  );
});
