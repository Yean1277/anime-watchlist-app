// =====================================================================
// Edge Function: add-to-watchlist
//
// Responsibilities:
//   1. Verify the caller's JWT.
//   2. Check anime cache freshness; only hit Jikan when it's stale
//      (writes the cache with the service_role client).
//   3. Kick episode sync to the background (EdgeRuntime.waitUntil) so it
//      never blocks the response.
//   4. Write user_anime using the caller's own identity, so RLS still
//      applies (least privilege).
//
// Changes here only take effect after a redeploy:
//   supabase functions deploy add-to-watchlist
// Contract details live in docs/API_DESIGN.md.
// =====================================================================
import { createClient } from 'npm:@supabase/supabase-js@2'

// Type declaration for the global the Supabase Edge Runtime provides.
declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void }

const JIKAN = 'https://api.jikan.moe/v4'
const JIKAN_DELAY_MS = 400 // Jikan rate limit is ~3 req/s; leave headroom.
const MAX_EPISODE_PAGES = 30 // 100 episodes/page, 30 pages = 3000 episode cap.
const FRESH_HOURS_AIRING = 24 // Airing shows: re-sync after 24h.
const FRESH_HOURS_FINISHED = 720 // Finished shows: 30 days, rarely changes.

// These three env vars are auto-injected by Supabase; no manual secrets setup needed.
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

// service_role client: only used to write the cache tables (anime / genres / episodes),
// bypassing RLS.
const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

const VALID_STATUS = ['plan_to_watch', 'watching', 'completed', 'on_hold', 'dropped']

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms))

const JIKAN_TIMEOUT_MS = 8_000 // Per-request deadline; a hung Jikan fetch must not hang the function.
const JIKAN_MAX_ATTEMPTS = 3
const JIKAN_RETRY_BASE_MS = 400
const JIKAN_MAX_HONORED_RETRY_AFTER_MS = 2_000

// Jikan gives ISO timestamps; our columns are `date`, so just take the first 10 chars.
const toDate = (iso: string | null | undefined) => (iso ? iso.slice(0, 10) : null)

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

// 429/5xx from Jikan are routinely transient, so retry with a short backoff
// (honoring small integer Retry-After values) before surfacing an error.
async function fetchJikan(path: string) {
  for (let attempt = 0; attempt < JIKAN_MAX_ATTEMPTS; attempt++) {
    const isLastAttempt = attempt === JIKAN_MAX_ATTEMPTS - 1
    const backoffMs = JIKAN_RETRY_BASE_MS * 2 ** attempt

    let res: Response
    try {
      res = await fetch(`${JIKAN}${path}`, { signal: AbortSignal.timeout(JIKAN_TIMEOUT_MS) })
    } catch (e) {
      if (isLastAttempt) {
        throw Object.assign(new Error('Jikan did not respond in time'), { status: 504, cause: e })
      }
      await sleep(backoffMs)
      continue
    }

    if (res.ok) return res.json()
    if (res.status === 404) throw Object.assign(new Error('Anime not found on MAL'), { status: 404 })

    if (res.status === 429) {
      const retryAfterMs = parseRetryAfterMs(res)
      if (isLastAttempt || (retryAfterMs !== null && retryAfterMs > JIKAN_MAX_HONORED_RETRY_AFTER_MS)) {
        throw Object.assign(new Error('Jikan rate limited, retry later'), { status: 503 })
      }
      await sleep(retryAfterMs ?? backoffMs)
      continue
    }

    if (res.status >= 500 && !isLastAttempt) {
      await sleep(backoffMs)
      continue
    }
    throw Object.assign(new Error(`Jikan error ${res.status}`), { status: 502 })
  }
  throw Object.assign(new Error('Jikan retries exhausted'), { status: 502 }) // unreachable
}

// Integer-seconds Retry-After (the form Jikan uses); null for absent/HTTP-date values.
function parseRetryAfterMs(res: Response): number | null {
  const raw = res.headers.get('retry-after')
  if (!raw) return null
  const seconds = Number.parseInt(raw.trim(), 10)
  return Number.isNaN(seconds) ? null : seconds * 1000
}

// ---------- Sync anime core data + genres (1 Jikan request, blocking but fast) ----------
async function syncAnime(malId: number) {
  const { data: a } = await fetchJikan(`/anime/${malId}`)
  const { error } = await admin.from('anime').upsert(
    {
      mal_id: a.mal_id,
      title: a.title,
      title_english: a.title_english,
      title_japanese: a.title_japanese,
      synopsis: a.synopsis,
      type: a.type,
      source: a.source,
      status: a.status,
      episodes: a.episodes,
      aired_from: toDate(a.aired?.from),
      aired_to: toDate(a.aired?.to),
      season: a.season,
      year: a.year,
      score: a.score,
      rank: a.rank,
      popularity: a.popularity,
      image_url: a.images?.jpg?.large_image_url ?? a.images?.jpg?.image_url,
      trailer_url: a.trailer?.url,
      synced_at: new Date().toISOString(),
    },
    { onConflict: 'mal_id' },
  )
  if (error) throw error

  // Jikan splits tags into 4 groups, but they share one mal_id namespace.
  const tagGroups: [string, { mal_id: number; name: string }[]][] = [
    ['genre', a.genres ?? []],
    ['genre', a.explicit_genres ?? []],
    ['theme', a.themes ?? []],
    ['demographic', a.demographics ?? []],
  ]
  const rows = tagGroups.flatMap(([category, list]) =>
    list.map((g) => ({ mal_id: g.mal_id, name: g.name, category })),
  )
  // A single upsert batch can't contain duplicate keys, so dedupe first.
  // Genres are cosmetic cache data: once the anime row has landed, a genre
  // write failure must not fail the user's add. Self-heals on the next sync.
  const uniq = [...new Map(rows.map((g) => [g.mal_id, g])).values()]
  if (uniq.length > 0) {
    const { error: gErr } = await admin.from('genres').upsert(uniq, { onConflict: 'mal_id' })
    if (gErr) {
      console.error(`genre sync failed for ${malId}:`, gErr)
      return
    }
    const { error: agErr } = await admin.from('anime_genres').upsert(
      uniq.map((g) => ({ anime_id: malId, genre_id: g.mal_id })),
      { onConflict: 'anime_id,genre_id', ignoreDuplicates: true },
    )
    if (agErr) console.error(`anime_genres sync failed for ${malId}:`, agErr)
  }
}

// ---------- Background episode sync (long-running shows can span many pages; never blocks the response) ----------
async function syncEpisodes(malId: number) {
  try {
    for (let page = 1; page <= MAX_EPISODE_PAGES; page++) {
      const { data: eps, pagination } = await fetchJikan(`/anime/${malId}/episodes?page=${page}`)
      if (!eps || eps.length === 0) break
      const rows = eps.map((e: any) => ({
        anime_id: malId,
        episode_number: e.mal_id, // Jikan's episode mal_id is the episode number.
        title: e.title,
        aired: toDate(e.aired),
        filler: e.filler ?? false,
        recap: e.recap ?? false,
        synced_at: new Date().toISOString(),
      }))
      const { error } = await admin
        .from('anime_episodes')
        .upsert(rows, { onConflict: 'anime_id,episode_number' })
      if (error) throw error
      if (!pagination?.has_next_page) break
      await sleep(JIKAN_DELAY_MS) // Respect Jikan's rate limit.
    }
  } catch (e) {
    // A background failure doesn't affect the user's request; it retries next time the cache expires.
    // (This is also why watched_episodes doesn't FK to anime_episodes.)
    console.error(`episode sync failed for ${malId}:`, e)
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    // ---------- 1. Authenticate the caller ----------
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401)
    // Client scoped to the caller's identity: RLS still applies when writing user_anime.
    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser()
    if (authError || !user) return json({ error: 'Invalid token' }, 401)

    // ---------- 2. Validate input ----------
    let body: { mal_id?: unknown; status?: unknown }
    try {
      body = await req.json()
    } catch (_) {
      return json({ error: 'Invalid JSON body' }, 400)
    }
    const { mal_id, status = 'plan_to_watch' } = body
    const malId = Number(mal_id)
    if (!Number.isInteger(malId) || malId <= 0) return json({ error: 'Invalid mal_id' }, 400)
    if (typeof status !== 'string' || !VALID_STATUS.includes(status)) {
      return json({ error: 'Invalid status' }, 400)
    }

    // ---------- 3. Check cache freshness; only hit Jikan when stale ----------
    const { data: cached } = await admin
      .from('anime')
      .select('synced_at, status')
      .eq('mal_id', malId)
      .maybeSingle()
    const freshHours =
      cached?.status === 'Finished Airing' ? FRESH_HOURS_FINISHED : FRESH_HOURS_AIRING
    const isFresh =
      cached && Date.now() - new Date(cached.synced_at).getTime() < freshHours * 3600 * 1000
    if (!isFresh) {
      await syncAnime(malId) // Must land the anime row first; user_anime has an FK dependency.
      EdgeRuntime.waitUntil(syncEpisodes(malId)) // Episodes go to the background; proceed immediately.
    }

    // ---------- 4. Write user_anime under the caller's identity ----------
    // ignoreDuplicates: re-adding an existing entry leaves it untouched (won't reset
    // "watching" back to "plan_to_watch").
    const { data: inserted, error: insertError } = await userClient
      .from('user_anime')
      .upsert(
        { user_id: user.id, anime_id: malId, status },
        { onConflict: 'user_id,anime_id', ignoreDuplicates: true },
      )
      .select('*, anime(*)')
      .maybeSingle()
    if (insertError) throw insertError

    // Duplicate add: the ignored upsert returns null, so fetch the existing
    // row and return it — the response always carries the entry, sparing
    // clients a follow-up query. (Older clients that still expect a possible
    // null entry keep working: entry is simply never null anymore.)
    let entry = inserted
    const alreadyInList = inserted === null
    if (alreadyInList) {
      const { data: existing, error: fetchError } = await userClient
        .from('user_anime')
        .select('*, anime(*)')
        .eq('user_id', user.id)
        .eq('anime_id', malId)
        .maybeSingle()
      if (fetchError) throw fetchError
      entry = existing
    }

    return json({ ok: true, entry, already_in_list: alreadyInList })
  } catch (e) {
    console.error(e)
    return json({ error: (e as Error).message }, (e as any).status ?? 500)
  }
})
