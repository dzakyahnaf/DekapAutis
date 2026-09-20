// Language model access, and the failover chain behind it.
//
// Gemini ──429/5xx──▶ Groq ──gagal──▶ full-text search only, labelled "mode terbatas"
//
// The rest of the codebase must never know which provider answered. That is not
// tidiness: judging runs for ten days without us present, and the difference
// between a degraded answer and a white screen is the difference between a
// product that survives the week and one that does not.
//
// API keys live only in Edge Function secrets. If one ever appears on the
// client that is a blocker-level bug (CLAUDE.md rule 4), and CI fails the branch
// when the pattern shows up in the tree.

export interface Pesan {
  peran: 'system' | 'user' | 'assistant';
  teks: string;
}

export interface OpsiChat {
  suhu?: number;
  maksToken?: number;
  /** Ask for strict JSON. Used by the layer 2 intent classifier. */
  json?: boolean;
  /** Wall-clock budget. KNF-01 gives the whole answer five seconds on 4G. */
  batasMs?: number;
}

export interface LlmProvider {
  readonly nama: string;
  chat(pesan: Pesan[], opsi?: OpsiChat): Promise<string>;
  /**
   * Null means this provider has no embedding endpoint at all - which is the
   * case for Groq. That is different from an embedding call that failed, and
   * the chain treats it differently.
   */
  embed(teks: string): Promise<number[] | null>;
}

/** Thrown when every provider in the chain is unreachable. */
export class SemuaPenyediaGagal extends Error {
  constructor(public readonly sebab: string[]) {
    super('semua penyedia model gagal');
  }
}

/**
 * Whether the next provider is worth trying.
 *
 * Rate limits (429) and outages (5xx) were always covered. Two more belong
 * here, and both were found the hard way on 2026-09-20: a retired model
 * answers 404 - llama-3.3-70b-versatile had been dead on Groq for some time -
 * and a rejected key answers 401 or 403. Neither says anything about the other
 * provider, yet both used to stop the chain before it ever reached it, which
 * turned "failover otomatis" into a claim that only held for outages.
 *
 * Only a malformed request (400, 422) is ours: it would fail the same way
 * everywhere, so failing over would just cost another round trip.
 */
function layakDicoba(status: number): boolean {
  return status !== 400 && status !== 422;
}

async function ambil(
  url: string,
  init: RequestInit,
  batasMs: number,
): Promise<Response> {
  return fetch(url, { ...init, signal: AbortSignal.timeout(batasMs) });
}

// ------------------------------------------------------------------ Gemini --

export class GeminiProvider implements LlmProvider {
  readonly nama = 'gemini';

  // Measured against the project's own key on 2026-09-20:
  //
  //   gemini-2.5-flash        404 "no longer available to new users"
  //   gemini-2.5-flash-lite   404, same
  //   gemini-3.8/3.7-flash    503, free tier saturated
  //   gemini-3.5-flash        200 but 14.5s - past the 12s budget below
  //   gemini-flash-lite-latest 200 in 1.3s, JSON mode included
  //
  // An alias rather than a pinned version: a pinned one answers 404 the day it
  // is retired, and the judging demo is live. Overridable by secret so a model
  // that starts failing can be swapped without a redeploy.
  constructor(
    private readonly kunci: string,
    private readonly modelChat = Deno.env.get('GEMINI_MODEL') ??
      'gemini-flash-lite-latest',
    private readonly modelEmbed = Deno.env.get('GEMINI_EMBED_MODEL') ??
      'gemini-embedding-001',
  ) {}

  async chat(pesan: Pesan[], opsi: OpsiChat = {}): Promise<string> {
    const sistem = pesan.filter((p) => p.peran === 'system');
    const sisa = pesan.filter((p) => p.peran !== 'system');

    const res = await ambil(
      `https://generativelanguage.googleapis.com/v1beta/models/${this.modelChat}:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': this.kunci },
        body: JSON.stringify({
          ...(sistem.length > 0
            ? { systemInstruction: { parts: sistem.map((p) => ({ text: p.teks })) } }
            : {}),
          contents: sisa.map((p) => ({
            role: p.peran === 'assistant' ? 'model' : 'user',
            parts: [{ text: p.teks }],
          })),
          generationConfig: {
            temperature: opsi.suhu ?? 0.3,
            maxOutputTokens: opsi.maksToken ?? 1024,
            ...(opsi.json ? { responseMimeType: 'application/json' } : {}),
          },
        }),
      },
      opsi.batasMs ?? 12000,
    );

    if (!res.ok) {
      throw new PenyediaError(this.nama, res.status, layakDicoba(res.status));
    }
    const data = await res.json();
    const teks: string | undefined =
      data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!teks) throw new PenyediaError(this.nama, 502, true);
    return teks.trim();
  }

  async embed(teks: string): Promise<number[] | null> {
    const res = await ambil(
      `https://generativelanguage.googleapis.com/v1beta/models/${this.modelEmbed}:embedContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': this.kunci },
        body: JSON.stringify({
          content: { parts: [{ text: teks }] },
          // 768 to match the vector(768) column. Locked: changing it means
          // re-embedding the whole corpus.
          outputDimensionality: 768,
          taskType: 'RETRIEVAL_QUERY',
        }),
      },
      8000,
    );

    if (!res.ok) {
      throw new PenyediaError(this.nama, res.status, layakDicoba(res.status));
    }
    const data = await res.json();
    const vektor: number[] | undefined = data?.embedding?.values;
    if (!vektor || vektor.length === 0) {
      throw new PenyediaError(this.nama, 502, true);
    }
    // Truncated Matryoshka outputs are not unit length, and cosine distance in
    // pgvector assumes they are. Normalising here rather than in SQL keeps the
    // stored corpus and the query vector on the same footing.
    return normalkan(vektor);
  }
}

// -------------------------------------------------------------------- Groq --

export class GroqProvider implements LlmProvider {
  readonly nama = 'groq';

  // llama-3.3-70b-versatile answers 404 on Groq as of 2026-09-20: retired. The
  // fallback had therefore been dead the whole time, which only shows when the
  // primary fails - exactly when it is needed. qwen3.8-27b answered in 0.5s and
  // is the one candidate that held to JSON mode; the gpt-oss models failed
  // Groq's JSON validation, which the intent classifier depends on.
  constructor(
    private readonly kunci: string,
    private readonly model = Deno.env.get('GROQ_MODEL') ?? 'qwen/qwen3.8-27b',
  ) {}

  async chat(pesan: Pesan[], opsi: OpsiChat = {}): Promise<string> {
    const res = await ambil(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.kunci}`,
        },
        body: JSON.stringify({
          model: this.model,
          temperature: opsi.suhu ?? 0.3,
          max_tokens: opsi.maksToken ?? 1024,
          ...(opsi.json ? { response_format: { type: 'json_object' } } : {}),
          messages: pesan.map((p) => ({
            role: p.peran === 'assistant' ? 'assistant' : p.peran,
            content: p.teks,
          })),
        }),
      },
      opsi.batasMs ?? 12000,
    );

    if (!res.ok) {
      throw new PenyediaError(this.nama, res.status, layakDicoba(res.status));
    }
    const data = await res.json();
    const teks: string | undefined = data?.choices?.[0]?.message?.content;
    if (!teks) throw new PenyediaError(this.nama, 502, true);
    return teks.trim();
  }

  /**
   * Groq has no embeddings endpoint. Returning null rather than throwing is
   * deliberate: it tells the chain "not my job" instead of "I am broken", so a
   * failed Gemini embedding drops straight to full-text search rather than
   * pretending Groq might rescue it.
   */
  embed(_teks: string): Promise<number[] | null> {
    return Promise.resolve(null);
  }
}

export class PenyediaError extends Error {
  constructor(
    public readonly penyedia: string,
    public readonly status: number,
    public readonly bolehGantiPenyedia: boolean,
  ) {
    super(`${penyedia} menjawab ${status}`);
  }
}

function normalkan(v: number[]): number[] {
  let jumlah = 0;
  for (const x of v) jumlah += x * x;
  const panjang = Math.sqrt(jumlah);
  return panjang === 0 ? v : v.map((x) => x / panjang);
}

// ------------------------------------------------------------------- chain --

export interface HasilChat {
  teks: string;
  penyedia: string;
}

export interface HasilEmbed {
  vektor: number[];
  penyedia: string;
}

/**
 * Tries each provider in order and reports which one answered.
 *
 * Callers get the answer and a provider name, never a branch on which model is
 * in use. Anything that had to know would be coupling the product to a vendor
 * we may have to swap in the middle of judging week.
 */
export class RantaiLlm {
  constructor(private readonly penyedia: LlmProvider[]) {}

  get kosong(): boolean {
    return this.penyedia.length === 0;
  }

  async chat(pesan: Pesan[], opsi?: OpsiChat): Promise<HasilChat> {
    const sebab: string[] = [];
    for (const p of this.penyedia) {
      try {
        return { teks: await p.chat(pesan, opsi), penyedia: p.nama };
      } catch (e) {
        sebab.push(`${p.nama}: ${(e as Error).message}`);
        // A 400 means the request itself is wrong; the next provider would
        // reject it too. Only retry what is worth retrying.
        if (e instanceof PenyediaError && !e.bolehGantiPenyedia) break;
      }
    }
    throw new SemuaPenyediaGagal(sebab);
  }

  /**
   * Null means no vector is available and the caller should fall back to
   * full-text search alone. That is a supported path, not a failure: docs/04
   * calls it "mode terbatas", and the user still gets sourced information.
   */
  async embed(teks: string): Promise<HasilEmbed | null> {
    for (const p of this.penyedia) {
      try {
        const vektor = await p.embed(teks);
        if (vektor === null) continue; // provider has no embeddings at all
        return { vektor, penyedia: p.nama };
      } catch {
        continue;
      }
    }
    return null;
  }
}

/**
 * Builds the chain from whatever secrets are present.
 *
 * An empty chain is a legitimate configuration, not an error. With no keys the
 * assistant answers from full-text search and labels itself limited, which is
 * exactly how it behaves when a quota runs out mid-judging.
 */
export function rantaiDariEnv(): RantaiLlm {
  const penyedia: LlmProvider[] = [];
  const gemini = Deno.env.get('GEMINI_API_KEY');
  const groq = Deno.env.get('GROQ_API_KEY');
  if (gemini) penyedia.push(new GeminiProvider(gemini));
  if (groq) penyedia.push(new GroqProvider(groq));
  return new RantaiLlm(penyedia);
}
