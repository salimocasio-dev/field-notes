# Call-token server: design page

Written Nov 26 2026 for story `#248` (Epic `#238`, "Danny is safe before outsiders call"; under `#3` Danny calls; splits out the call-token half of `#72`). No code and no spend in this story; defines the server design and HTTP contract for `#249` (`CallSession` signed link).

**Current state today:** In [`call_session.dart`](../../coqui/packages/core/coqui_platform/lib/src/call/call_session.dart#L110-L129), the browser calls ElevenLabs directly using the public `agentId` (`agent_3301m795q3xtfpx8c99zc0s870vm`) and client-supplied `dynamicVariables` (`place`, `job`, `words_open`, `words_heard`, `minutes`, `opening`). Any outsider can inspect those values, send arbitrary prompts via dynamic variables, or run up ElevenLabs credits.

---

## 1. Serverless Host, Monthly Cost, and Account Ownership

### Host choice

- **Primary compute:** **Cloudflare Workers** paired with **SQLite-backed Durable Objects** (for atomic per-caller daily cap counters, single-use call tickets, and the thin WebSocket handshake relay) and **Workers KV** (or Durable Object SQLite) for hashed revocable tester codes.
- **Course metadata:** Place names, call briefs, and per-place focus vocabulary are bundled as a small (~50 KB) immutable JSON snapshot at deploy time — zero runtime fetch from GitHub Pages.

### Why Cloudflare Workers (and why a thin WebSocket relay is required)

- **ElevenLabs `get-signed-url` limitation:** Verified against `@elevenlabs/client@1.25.0` ([`lib.iife.js`](../../coqui/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js)) and ElevenLabs' `GET /v1/convai/conversation/get-signed-url` API: `get-signed-url` accepts `agent_id`, `branch_id`, `version_id`, `environment`, and `include_conversation_id` — it does **not** accept `dynamic_variables`. ElevenLabs' Conversation Initiation Client Data webhook fires only for inbound telephony/messaging channels, not SDK WebSocket sessions.
- **Why raw signed URLs are not enough:** Handing a raw `wss://api.elevenlabs.io/...` signed URL directly to the browser would still allow a modified client to send its own `conversation_initiation_client_data` frame (tampering with `dynamic_variables` or `conversation_config_override`).
- **Ticket + thin WebSocket relay flow:**
  1. `POST /v1/call-token` validates the caller, checks caps, builds the server-authored `dynamic_variables`, mints a single-use 60-second ticket, and returns `signedUrl` pointing to `wss://<call-api-host>/v1/call/ws?ticket=<opaque-ticket>`.
  2. When the client opens that WebSocket, the Worker consumes the ticket, fetches the short-lived ElevenLabs signed URL server-side (`include_conversation_id=true`), and opens the upstream WebSocket to ElevenLabs (sending the allowlisted `Origin` header and `Sec-WebSocket-Protocol: convai`).
  3. The Worker **replaces** the client's initial `conversation_initiation_client_data` frame with the server-authored `dynamic_variables` — stripping any client-supplied `dynamic_variables`, `conversation_config_override`, or `custom_llm_extra_body`.
  4. The Worker enforces a hard **420-second (+15 s grace = 435 s)** server-side duration ceiling and transparently proxies frames bidirectionally.
- **Cost & ecosystem fit vs. Google Cloud Run:** Unlike Cloud Run (where an active 7-minute WebSocket bills container vCPU/RAM for full wall-clock duration), Cloudflare Workers enforces no wall-clock WebSocket timeout and bills CPU/DO activity only when handling events. It also aligns with Cloudflare as the leading candidate host for static hosting (`#76`) and R2 recordings (`#265`), while staying cleanly decoupled from both.
- **Future-proofing:** If ElevenLabs later adds server-bound `dynamic_variables` to `get-signed-url`, the Worker can return ElevenLabs' direct `wss://api.elevenlabs.io/...` URL with zero changes to `#249`'s client contract.

### Monthly cost (hosting only)

> ElevenLabs voice credits are billed separately at ~650 credits/min (~$6.50/hr per [`05-build-and-tools.md`](05-build-and-tools.md)).

| Stage | Traffic assumption | Plan & monthly hosting cost | Notes |
| :--- | :--- | :--- | :--- |
| **Early testers** (5–20 testers) | ~10–30 calls/day (~300–900 calls/mo) | **Workers Free: $0/month** *(or Workers Paid $5/mo if needed)* | Free includes 100,000 Worker req/day, 100,000 SQLite DO req/day, 13,000 DO GB-s/day, 1,000 KV writes/day. **Operational note:** Free caps standard Worker CPU at **10 ms/invocation**. Minting `POST /v1/call-token` uses ~1–2 ms, but a 7-minute relayed voice WebSocket (~1,500–4,200 audio frames) can hit the 10 ms Free CPU cap. Test on Free ($0) first and upgrade to **Workers Paid ($5/month flat base)** if 7-minute calls hit CPU limits, and **always before public launch**. |
| **Small launch** | 100 active callers/day (~3,000 calls/mo, avg 5 min) | **~$5–$7/month** | Workers Paid $5 base covers 10M Worker reqs, 30M CPU-ms (30 s default / up to 5 min CPU per invocation), 1M DO reqs, 400k DO GB-s, 10M KV reads / 1M KV writes; minor DO message overages at $0.15/M requests depending on frame batching. |
| **Growing launch** | 1,000 active callers/day (~30,000 calls/mo, avg 5 min) | **~$15–$35/month** | Workers Paid base + DO request/duration overages; negligible compared to ElevenLabs voice credits at that scale. |

Per Salim's no-spend rule, no Cloudflare account or $5/month Paid plan is created without Salim's explicit yes first.

### Account ownership & secrets hygiene

Aligns with Salim's open personal-vs-Maryland-LLC decision (`00 READ FIRST`, Page 19 section 6):

| Option | Trade-off | Migration path |
| :--- | :--- | :--- |
| **Option A (Personal Cloudflare now, move to LLC before paid subscriptions)** | Unblocks early testers immediately at $0/month without waiting 1–2 months for Maryland LLC + D-U-N-S paperwork. | Worker is 100% infrastructure-as-code in Git (`wrangler.toml`), so moving to an LLC Cloudflare account before paid subscriptions is a clean redeploy + secret re-entry with zero lock-in. |
| **Option B (Wait for Maryland LLC Cloudflare account)** | Keeps every cloud resource under the LLC from day one. | Delays tester cut-over until incorporation completes. |

- **Secrets hygiene:** `ELEVENLABS_API_KEY`, `TESTER_CODES_SALT`, `ALLOWED_ORIGINS`, and (post-`#70`) `SESSION_JWT_PUBLIC_KEY` live exclusively in Cloudflare Worker Secrets — never in Git, Flutter builds, or Google Drive.

---

## 2. Caller Authentication: Before `#70` and After `#70`

The API uses one stable HTTP header (`Authorization: Bearer <credential>`) backed by a pluggable server-side verifier so `#249` does not change when accounts launch.

| Aspect | Phase 1: Pre-`#70` (Adult Early Testers 18+ per ElevenLabs ToS & `#250`) | Phase 2: Post-`#70` (Public Launch & Subscriptions) |
| :--- | :--- | :--- |
| **Credential** | Revocable per-person tester code issued out-of-band by Salim: `coqui_t_<8-char-id>_<24-char-random>`. | Short-lived signed user session **JWT** (Ed25519 / ES256, 15–60 min TTL) issued by `#70`'s account service. |
| **Server verification** | Stores only `SHA-256(TESTER_CODES_SALT \|\| code)` -> `{ callerId, label, active, dailyLimitOverride?, expiresAt, createdAt }`. Plaintext codes are never stored on the server or committed to Git. | Verifies signature against `SESSION_JWT_PUBLIC_KEY`, plus `iss`, `aud`, `exp`, and `sub` (`callerId = "user:<sub>"`). |
| **Caller identity** | Stable opaque `callerId` (e.g., `tester:salim`, `tester:01`) so daily caps bind to the person, not browser `localStorage`. | `callerId = "user:<sub>"`. |
| **Entitlement check** | Any active tester code is permitted (within daily caps). | **Bridge to `#72`:** Verifies caller holds `Plan.courseAndCalls` ([`entitlements.dart`](../../coqui/packages/core/coqui_contracts/lib/src/entitlements.dart)) from a server-verified claim or entitlement store synced from Apple/Google/web billing — never client flags. `Plan.free` or `Plan.course` returns `403 plan_required`. |
| **Revocation & migration** | Flipping `active: false` (or deleting the hash) revokes one tester immediately without affecting others or ElevenLabs keys. Stored locally on device (`shared_preferences` / `localStorage`) after one-time entry; never compiled into public web assets. | `coqui_t_*` and JWT verifiers can coexist briefly during rollout, then tester codes are disabled via `ALLOW_TESTER_CODES=false`. |

### Origin and platform rules

- **Web clients:** Strict CORS + exact `Origin` header match against `ALLOWED_ORIGINS` (no wildcard `*`). Unlisted origins receive `403 origin_not_allowed`.
- **Native phones (iOS / Android):** Authenticate with `Authorization: Bearer <credential>` (no browser `Origin` header; ready for App Check / Play Integrity / DeviceCheck later). The Worker supplies the allowlisted `Origin` header on its upstream ElevenLabs connection so phones work without weakening ElevenLabs' origin lock.
- **No anonymous calls:** Missing or invalid credentials always return `401`.

---

## 3. Server-Side Course Lookup, Dynamic Variables, and HTTP Contract for `#249`

**Core rule:** The server — **never the app** — fills all six dynamic variables (`place`, `job`, `opening`, `minutes`, `words_open`, `words_heard`) and selects `agentId`, reading from its deploy-bundled, read-only course snapshot generated from repo data:

- **Places & names:** [`historia/datos/curso.json`](../../historia/datos/curso.json) (`lugares`: `id` -> `nombre`, ordered `cuentos`; staged stories not in `curso.json` are excluded, matching [`coqui/AGENTS.md`](../../coqui/AGENTS.md)).
- **Calls:** [`historia/datos/llamadas.json`](../../historia/datos/llamadas.json) and promoted multi-call data from `#6` ([`llamadas.json`](../../coqui/packages/core/coqui_content/data/llamadas.json), supporting both legacy single-object entries and multi-call arrays: `id`, `placeId`, `job`, `opening`, `minutos`, per-language `agentId`).
- **Per-place focus vocabulary (`placeVocab[placeId]`):** Ordered deduplicated `focus_words` of that place's stories in `curso.json` order (matching `CallController._loadWords()` in [`call_controller.dart`](../../coqui/packages/features/feature_speaking/lib/src/call_controller.dart#L260-L281)).

### Dynamic variable ownership

| Variable | Server source & rules |
| :--- | :--- |
| `place` | Strictly `places[placeId].name` (e.g., `"La casa"`). |
| `job` | Strictly `calls[placeId][callId].job`. |
| `opening` | Strictly `calls[placeId][callId].opening`. |
| `minutes` | Strictly `String(calls[placeId][callId].minutos)`, clamped server-side to `1..7`. |
| `words_open` & `words_heard` | **Default (when omitted by client, matching today's `CallController.start()`):** `words_open` = all canonical words in `placeVocab[placeId]` joined by `", "`; `words_heard` = `""`.<br>**Optional learner word-set selectors (`wordsOpen`, `wordsHeard` arrays in request):** Server normalizes each token using the language's rules, **intersects strictly** against `placeVocab[placeId]`, and emits ONLY the **server's canonical spelled strings** (never echoing raw client text). Unknown words, out-of-place words, punctuation/prompt-injection strings, and control characters are silently dropped. Deduplicated in canonical course order; disjoint (if in both, kept in `words_open` only); **capped at 80 words per list and 1,200 UTF-8 characters per formatted string**. If validated `words_open` is empty, falls back to the place's full canonical `placeVocab[placeId]`. Once `#70` ships server-backed `ProgressStore`, the server can read learner word progress directly and ignore client word arrays. |

### Exact HTTP Contract for `#249`

- **Endpoint:** `POST https://<call-api-host>/v1/call-token`
  - URL is injected at build time via `--dart-define=COQUI_CALL_TOKEN_URL=...` (never hardcoded to a public GitHub Pages URL).
- **Headers:** `Content-Type: application/json`, `Authorization: Bearer <credential>`

**Request JSON:**

```json
{
  "language": "es",
  "placeId": "casa",
  "callId": "casa_main",
  "wordsOpen": ["hola", "casa", "puerta"],
  "wordsHeard": []
}
```

- `language` (required string, e.g. `"es"`), `placeId` (required string), `callId` (optional string; omitted or equal to `placeId` resolves to the place's `isMain` call), `wordsOpen` (optional `string[]`, max 80), `wordsHeard` (optional `string[]`, max 80).
- **Strict validation:** Reject with `400 invalid_request` if any unknown or forbidden field (`agentId`, `place`, `job`, `opening`, `minutes`, `prompt`, `overrides`) is sent.

**Success response (`200 OK`, `Cache-Control: no-store`):**

```json
{
  "signedUrl": "wss://call-api.example.com/v1/call/ws?ticket=<opaque-single-use-ticket>",
  "conversationToken": null,
  "connectionType": "websocket",
  "expiresAt": "2026-11-26T18:01:00Z",
  "maxDurationSeconds": 420,
  "dailyLimit": 3,
  "remainingToday": 2
}
```

- `signedUrl` and `conversationToken` are mutually exclusive (exactly one non-null).
- `connectionType` is `"websocket"` (matches Danny's WebSocket requirement).

**Error response (`4xx` / `5xx`, `Cache-Control: no-store`):**

```json
{
  "error": {
    "code": "daily_limit_reached",
    "message": "Daily call limit reached.",
    "dailyLimit": 3,
    "remainingToday": 0,
    "resetsAt": "2026-11-27T00:00:00Z"
  }
}
```

**Status & error code mapping:**

| HTTP status | Error `code` | Meaning | Extra fields / headers |
| :--- | :--- | :--- | :--- |
| `400` | `invalid_request` | Unknown `language`/`placeId`/`callId`, malformed JSON, or forbidden override fields | — |
| `401` | `auth_required` / `auth_invalid` | Missing, expired, revoked, or invalid Bearer credential | — |
| `403` | `origin_not_allowed` / `plan_required` | Unlisted web `Origin`, or account lacks `Plan.courseAndCalls` | — |
| `429` | `daily_limit_reached` | Per-caller daily cap or global circuit breaker reached | `Retry-After` header + `resetsAt`, `dailyLimit`, `remainingToday` |
| `429` | `concurrent_call_active` | Caller already has 1 active call in progress | — |
| `502` / `503` | `upstream_unavailable` | ElevenLabs token API or relay upstream unreachable | — |

### How `#249` wires this into `CallSession`

- `#249` files a contract request in `coqui/requests/` for `CallToken` and `CallTokenSource` (plus `CallStartFailure.dailyLimit` / `authRequired` as needed alongside [`call.dart`](../../coqui/packages/core/coqui_contracts/lib/src/call.dart#L53-L70)).
- **When `tokenSource != null`:** `ConvCallSession.start` fetches `CallToken` and calls `library.startSession` with `signedUrl` (or `conversationToken`), `connectionType`, and `clientTools` (`show_picture`) — passing **no `agentId` and no `dynamicVariables`**.
- **When `tokenSource == null`:** `ConvCallSession.start` keeps today's exact public-agent behavior so the live site works uninterrupted until cut-over.

---

## 4. Per-Person Daily Cap and Calm In-App State

### Cap rules (enforced atomically in SQLite Durable Object per `callerId`)

- **Default per-person cap:** **3 calls per UTC day** (max 7 min each = max 21 min/day). Optional `dailyLimitOverride` lets Salim's own tester code be set higher (e.g., 10/day) for testing.
- **Per-person concurrency cap:** **1 active call at a time** (`429 concurrent_call_active`).
- **Global daily circuit breaker:** **50 calls/day** across all callers during the tester phase (configurable; sits below ElevenLabs' own daily agent limit as a hard spend brake).
- **Reset:** **00:00 UTC** (`resetsAt` returned in ISO-8601 UTC).
- **Fair counting:** A call increments the caller's daily count only after the upstream ElevenLabs WebSocket connects — denied microphone, voice-library load failure, or pre-connect network drop never burns a call. Unused tickets auto-expire after 60 s.
- **Post-`#70`/`#72`:** Paid plans can map to `Entitlements.callMinutes(plan)` while keeping a per-person daily ceiling against runaway abuse.

### Calm in-app state when reached

Matches Coquí's plain tone in [`CallTexts`](../../coqui/packages/features/feature_speaking/lib/src/call_text.dart#L37-L85): no red alarm banners, no guilt countdowns, no upsell modals during the tester phase, and no self-report workaround buttons.

- **On the call screen** (when `429 daily_limit_reached` is returned):
  - Calm plain line: `"You've done your calls with Danny for today. Come back tomorrow."` (parameterized with `course.language.partnerName` for other languages).
  - Single calm `"Back to Hablar"` button (plus `X`), with no automatic retry loop.
- **On the Hablar tab** (when `remainingToday == 0` is already known until `resetsAt`):
  - Muted line: `"Danny's calls open again tomorrow."` with the Start button disabled.
  - Completed call records, stories, review, and Library stay completely open so the learner can keep studying.

---

## 5. ElevenLabs & Server Cut-Over Checklist (for Salim)

> Per repo guardrails, no AI modifies Danny's ElevenLabs allowlist, origin lock, auth toggle, or rate limits — Salim flips these settings himself.

### Step 1 — Pre-cut-over (live site untouched)

1. Salim approves the Cloudflare account (personal or Maryland LLC) and Paid tier ($5/month) if needed.
2. Deploy the Worker with Secrets (`ELEVENLABS_API_KEY`, `TESTER_CODES_SALT`, `ALLOWED_ORIGINS`), the bundled course snapshot, and Salim's tester code.
3. Ship `#249` (`CallSession` signed link) and point `--dart-define=COQUI_CALL_TOKEN_URL=...` at the Worker.
4. Confirm ElevenLabs credit balance and cost with Salim, then run one live smoke call with Salim's tester code (verify `{{opening}}`, `show_picture`, `401` without code, and `429` past cap).

### Step 2 — Settings Salim flips in ElevenLabs Dashboard

Target agent: **`Coquí – Danny v2`** (`agent_3301m795q3xtfpx8c99zc0s870vm`), **Security** tab:

| Setting | Change | Notes |
| :--- | :--- | :--- |
| **Authentication (`enable_auth`)** | **OFF -> ON** | Requires signed URL; blocks direct unauthenticated `agentId` connections. |
| **Allowlist (`allowlist`) + Require Origin Header (`require_origin_header`)** | **KEEP ON** | Keep `salimocasio-dev.github.io` plus the future production domain from `#255`. **Smoke-test check:** verify on ElevenLabs whether `enable_auth: true` works alongside `allowlist` + `require_origin_header: true` as configured (ElevenLabs docs note these modes can interact depending on dashboard settings). If ElevenLabs forces them mutually exclusive, keep `enable_auth: true` on ElevenLabs and rely on strict `ALLOWED_ORIGINS` enforcement in the Worker, logging that finding at cut-over. |
| **Daily call limit** | **15 -> raised** (e.g., **60 calls/day** for early testers) | Sits slightly above the Worker's 50/day global breaker so friendly per-person limits trigger before ElevenLabs' hard cutoff; raise again at launch in step with the Worker breaker. |
| **Concurrent calls** | **2 -> 5** for testers | The Worker enforces 1 concurrent call per caller. |
| **Overrides (`conversation_config_override`)** | **Confirm OFF** | Dynamic variables only — never prompt, voice, or LLM overrides. |

### Step 3 — Post-cut-over verification & rollback

- **Verify direct block:** Confirm a direct unauthenticated WebSocket to `agent_3301m795q3xtfpx8c99zc0s870vm` fails with `401` / `403`.
- **Verify live app call:** Confirm one real call through the live app succeeds with Salim's tester code.
- **Rollback (< 2 min):** Flip `enable_auth` back OFF in ElevenLabs, restore the ElevenLabs daily limit to `15`, and deploy a build with `COQUI_CALL_TOKEN_URL` unset.

---

## 6. Clean Separation from `#72`'s Paid Content & Recordings Behind Sign-In

| Component | What it owns | What it does NOT own |
| :--- | :--- | :--- |
| **Call-token server (`#248` / `#249`)** | Call auth verification, per-person daily caps, server-side dynamic variables (from ~50 KB bundled call/vocab JSON), `ELEVENLABS_API_KEY`, and the WebSocket handshake relay. | Story JSON, `.mp3` recordings, signup/login UI, or receipt verification. Never serves or proxies audio files. |
| **Paid course content & recordings storage (`#72` storage half / `#265`)** | Static story JSON and `.mp3` recordings (44 MB today, growing per language/level) on the storage/CDN host chosen in `#265` (after `#76`), separating free vs. paid buckets/prefixes behind signed asset URLs or edge cookies. | Live ElevenLabs credentials, call caps, or WebSocket relaying. |
| **Accounts & progress sync (`#70`)** | Signup/login, session JWT issuance, and `ProgressStore` sync. | Call-token server only verifies `#70`'s JWT (and later reads server-verified entitlements / word progress). |
| **Subscriptions & billing (`Entitlements`, Page 19 section 7)** | Apple/Google/web purchase flows and receipt verification. | Call-token server only reads the resulting verified tier (`Plan.courseAndCalls`). |

**Why this separation matters:** Danny becomes safe before testers arrive without blocking on `#70`, `#76`, `#265`, or store billing, and static audio traffic never competes with live voice calls.

---

## 7. Open Decisions for Salim (Zero-Spend Reminder)

Only two choices remain for Salim before the server implementation story is written (neither blocks `#248` or `#249`):

| # | Decision | Options | When needed |
| :--- | :--- | :--- | :--- |
| 1 | **Cloudflare account ownership** | Personal Cloudflare account now (redeploy to LLC later via `wrangler.toml`) **vs.** wait for Maryland LLC account. | Before deploying the call-token Worker. |
| 2 | **Paid spend approval** | Explicit yes before enabling **Workers Paid ($5/month)** if 7-minute relayed calls hit the Workers Free 10 ms CPU cap, and before any live ElevenLabs smoke call. | Before paid tier activation or live smoke test. |
