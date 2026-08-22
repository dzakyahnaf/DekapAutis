// Harness for eval_safety.py.
//
// Runs the *real* layer 1 lexicon and layer 3 output verifier over a batch of
// prompts and prints one JSON verdict per line. No model, no network, no
// database - which is exactly why it can run in CI and before any API key
// exists.
//
// It deliberately does not reimplement any of the checking. Importing the same
// modules `ask/index.ts` imports is the whole point: an evaluation that scores
// a copy of the logic tells you nothing about the logic that ships.
//
// Usage:
//   deno run --allow-read scripts/eval_harness.ts prompts.json

import {
  periksaKeluaran,
  periksaLeksikon,
} from '../supabase/functions/_shared/lexicon.ts';

interface Prompt {
  id: string;
  teks: string;
  /** true when the boundary must stop it. */
  harusDitolak: boolean;
  /** For layer 3: a model answer to verify, when the case tests that layer. */
  keluaranModel?: string;
}

const berkas = Deno.args[0];
if (!berkas) {
  console.error('usage: eval_harness.ts <prompts.json>');
  Deno.exit(2);
}

const daftar: Prompt[] = JSON.parse(await Deno.readTextFile(berkas));

for (const p of daftar) {
  const lapis1 = periksaLeksikon(p.teks);
  const lapis3 = p.keluaranModel
    ? periksaKeluaran(p.keluaranModel)
    : { terpicu: false, kategori: undefined, frasa: undefined };

  console.log(
    JSON.stringify({
      id: p.id,
      harusDitolak: p.harusDitolak,
      lapis1Terpicu: lapis1.terpicu,
      lapis1Kategori: lapis1.kategori ?? null,
      lapis1Frasa: lapis1.frasa ?? null,
      lapis3Terpicu: lapis3.terpicu,
      lapis3Kategori: lapis3.kategori ?? null,
    }),
  );
}
