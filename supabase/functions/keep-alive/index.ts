// Keeps the Supabase project awake during judging.
//
// A free project pauses after 7 days without database activity. Judging runs
// 2-11 September, which is ten days - so without this the product can go dark
// partway through, and a judge who opens a paused project sees a network error
// rather than an application.
//
// It touches the database on purpose rather than merely returning 200: an HTTP
// handler that answers without a query proves the Edge Function is alive and
// says nothing at all about the database, which is the thing that pauses.
//
// Deliberately cheap and read-only. A cron that writes a row every day leaves a
// table nobody wanted, growing for a week and a half.

import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async () => {
  const mulai = Date.now();

  try {
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Counting the activity catalogue reaches a real table with a real index.
    const { count, error } = await admin
      .from('aktivitas')
      .select('id', { count: 'exact', head: true });

    if (error) throw error;

    // Roll the demo window forward so it still ends today.
    //
    // The seed anchors its dates to the day it ran, so the data goes stale one
    // day at a time while judging continues to 11 September. Doing it here
    // rather than in a second cron costs nothing: this function already runs
    // daily and already holds the service-role key. A failure is reported but
    // not thrown - a stale demo is bad, a keep-alive that stops answering is
    // worse, and this endpoint exists to keep the project awake.
    const { data: demo, error: demoError } = await admin
      .rpc('segarkan_tanggal_demo')
      .maybeSingle();

    return new Response(
      JSON.stringify({
        status: 'bangun',
        aktivitas: count,
        demo: demoError ? { gagal: demoError.message } : demo,
        ms: Date.now() - mulai,
        pada: new Date().toISOString(),
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    // Answering 500 matters: a cron that always succeeds cannot tell anyone the
    // database stopped responding, which is the one thing it exists to notice.
    return new Response(
      JSON.stringify({
        status: 'gagal',
        pesan: e instanceof Error ? e.message : String(e),
        ms: Date.now() - mulai,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
