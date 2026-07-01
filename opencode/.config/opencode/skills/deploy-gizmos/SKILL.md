---
name: deploy-gizmos
description: Deploy or iterate on an app on the TELUS Gizmos platform. Builds bundled projects (Vite/Webpack/Rollup) when present, previews the upload via `gizmos push --dry-run`, then pushes to production (gizmos.run), the shared non-prod env (dev.gizmos.run), or a local loader. Use when the user asks to deploy, push, ship, preview, or iterate on a gizmo.
user-invocable: true
---

# Deploy to Gizmos

Deploy the current directory's app files to the Gizmos platform using `gizmos push`.

## Prerequisites

Deploys go through the `gizmos` CLI. Inside a Gizmos dev environment or
Studio it's already on `PATH`. Anywhere else, install it (and this skill)
in one line:

```bash
curl -fsSL https://gizmos.run/skills/install.sh | bash
```

On Windows (PowerShell): `irm https://gizmos.run/skills/install.ps1 | iex`.

It puts the `gizmos` binary in `~/.local/bin` and installs the skill into the
nearest `.claude` directory (walking up from the cwd), falling back to
`~/.claude/skills`. Override with `--dir <skills-dir>` (e.g.
`bash -s -- --dir "$PWD/.claude/skills"`) or `$CLAUDE_SKILLS_DIR`. Alternatives:
`npm i -g gizmos-cli`, or run the copy bundled next to this skill with
`node ~/.claude/skills/deploy-gizmos/gizmos.mjs <subcommand>`.

It needs two env vars:
- `GIZMOS_API_KEY` — generate one at the hub's `/settings` page (`gzm_…`)
- `GIZMOS_URL` — the Gizmos base URL (e.g. `https://gizmos.run`)

## Steps

### 1. Check for API key

```bash
echo $GIZMOS_API_KEY
```

If empty, tell the user:

> No GIZMOS_API_KEY found. Generate one at your hub's Settings page,
> then run: `export GIZMOS_API_KEY=gzm_...`

Stop here if no key is available.

### 2. Check for Gizmos URL

```bash
echo $GIZMOS_URL
```

If empty, ask the user for the URL and suggest they export it.

For shared E2E testing against the non-prod environment, set
`GIZMOS_URL=https://dev.gizmos.run` and use a `dev`-env API key generated
from `dev.gizmos.run/settings`. The dev environment redeploys on every
push to `main` and has fully isolated D1/R2/KV — safe to break. Note that
the app name `dev` itself is reserved and names ending in `dev` are
rejected to avoid wildcard catches.

### 3. Build first if this is a bundled project (REQUIRED)

Before deploying, check whether the project has a real bundler:

- `package.json` exists and has a `build` script
- One of `vite.config.{ts,js,mjs}`, `webpack.config.*`, or `rollup.config.*` is present

If both are true, the build is **required**, not optional. The platform's
runtime bundler does not run Vite/Webpack/Rollup plugins, JSX runtimes, or
path aliases — pushing source for these projects will deploy successfully
and then fail at request time with a 500 / "Could not determine server
entry point" error.

```bash
npm install     # if node_modules is missing
npm run build   # or pnpm run build / yarn build
```

Confirm the build produced a `dist/` (or `build/`) directory. Deploy from
there in steps 4 and 5. If `gizmos push` prints a `[warn]` about a
detected bundler config, **stop and run the build first** — do not
proceed with a source push.

If there's no build script, no bundler config, or the project is a plain
static site (HTML/CSS/JS), skip this step and deploy the project root.

### 4. Preview the deploy

Run a dry-run first to show what will be uploaded. Point at the built
output (`dist/` / `build/`) if you built in step 3, otherwise the project
root:

```bash
gizmos push --dry-run dist
# or
gizmos push --dry-run .
```

This lists all files, the app name (from `wrangler.toml`), and the total
payload size.

If the app name is wrong, override it with `--app <name>`.

### 5. Deploy

```bash
gizmos push dist
# or
gizmos push .
```

### 6. Report result

On success, the CLI prints the live URL. Share it with the user.

On failure, the CLI prints the error. Common cases:
- **Invalid API key (401)**: direct the user to regenerate at `/settings`
- **App owned by someone else (403)**: suggest `--app <different-name>`

## Iterating locally

For fast iteration — especially with an AI agent driving — run the loader
locally with `DEV_SKIP_AUTH=true`. Auth is bypassed, so the agent can
`curl http://<app>.localhost:8787/...` directly after each push.

See [`docs/local-dev.md`](../docs/local-dev.md) for the setup.

Deploy against the local loader by passing `--url`:

```bash
gizmos push \
  --url http://localhost:8787 \
  --api-key <local-key> \
  ./my-app
```

## When writing the app

The loader wraps D1 with a `D1Proxy` (`loader/src/binding-proxies.ts`) that
matches the standard Cloudflare `D1Database` shape. Both the standard
`prepare()` chain and a pair of gizmos-specific shortcut methods are
available.

**Standard CF D1 API** — `prepare()` returns a lazy `D1PreparedStatement`;
SQL doesn't execute until a terminal method is called:

```ts
const { results } = await db.prepare("SELECT * FROM users WHERE id = ?")
                            .bind(userId).all();
const row = await db.prepare("SELECT * FROM users WHERE id = ?")
                     .bind(userId).first();
const { meta } = await db.prepare("INSERT INTO users (name) VALUES (?)")
                          .bind(name).run();
const rows = await db.prepare("SELECT * FROM users").raw(); // rows as arrays
```

**Shortcuts** — skip the prepare-handle round trip when you don't need
chaining or batching:

| Want | Standard | Shortcut |
|------|----------|----------|
| First row | `await db.prepare(sql).bind(...).first()` | `await db.first(sql, ...params)` |
| Run a mutation | `await db.prepare(sql).bind(...).run()` | `await db.run(sql, ...params)` |
| DDL (multi-statement OK) | — | `await db.exec(sql)` |

**Batch transactions** — pass `prepare()` handles to `db.batch([...])` for
an ordered, single-rollback transaction. Because `prepare()` is lazy, each
handle is cheap and only the batch call hits the DB:

```ts
await db.batch([
  db.prepare("INSERT INTO a VALUES (?)").bind(1),
  db.prepare("INSERT INTO b VALUES (?)").bind(2),
]);
```

The `examples/app/src/index.ts` counter uses the shortcut form;
`loader/src/binding-proxies.ts` is the source of truth for the proxy shape.

### Ship a favicon

Drop a `favicon.ico` at the root of the deploy bundle (or in `dist/` for
built sites). It powers the browser tab, bookmark icon, and the avatar on
the community list. Without one, the community list falls back to a
deterministic colored-initials avatar — fine but generic. A 32×32 ICO
works; multi-resolution (16/32/48) renders crisper at every size. The
deploy pipeline preserves binary assets verbatim; there is no separate
upload step.

## Access control + metadata

Four API-key–authenticated endpoints under `/__push/*` let a CLI or agent
manage access, visibility, and the metadata that surfaces on the community
list — without opening the hub UI:

| Method & path | Body | Returns |
|---|---|---|
| `GET /__push/apps/:name/shares` | — | `200 { shares: [...] }` |
| `POST /__push/apps/:name/shares` | `{ email, role? }` | `201 { ok: true }` |
| `DELETE /__push/apps/:name/shares/:email` | — | `200 { ok: true }` |
| `PATCH /__push/apps/:name` | `{ visibility?, labels?, description? }` | `200 { ok: true }` |

`role` is one of `viewer` (default), `editor`, `admin`. `POST /shares` is
upsert — re-POSTing the same email with a new role changes the role.
`DELETE /shares/:email` is idempotent — it returns `200` whether or not
the share existed.

PATCH accepts any combination of:

- `visibility` — `"private"` or `"public"`. Flipping to `"public"` triggers
  a home-page health check; failure returns `409` with `{status, reason}`.
- `labels` — an array of strings (lowercase kebab-case, 1–5 chips).
  Replaces the app's full label set (passing `[]` clears all). The same
  field the Hub UI's LabelsEditor writes, and what Fuelix auto-generates
  on first push for an unlabeled app when `FUELIX_API_KEY` is configured
  on the loader.
- `description` — a string ≤ 160 chars, or `null` to clear it. Surfaces on
  the community-list row alongside the app name and owner. The 160 cap
  matches the row's line-clamp truncation. The Hub's deploy wizard and
  About card offer a **Generate** button that synthesizes a description
  from the deployed source via Fuelix — agents driving via the CLI should
  PATCH this field explicitly rather than relying on the UI path.

Examples:

```bash
# Make an app discoverable to all TELUS employees
curl -X PATCH "$GIZMOS_URL/__push/apps/my-app" \
  -H "authorization: Bearer $GIZMOS_API_KEY" \
  -H "content-type: application/json" \
  -d '{"visibility":"public"}'

# Set a description and a couple of labels in one call
curl -X PATCH "$GIZMOS_URL/__push/apps/my-app" \
  -H "authorization: Bearer $GIZMOS_API_KEY" \
  -H "content-type: application/json" \
  -d '{"description":"Apparel mockup designer powered by Gemini.","labels":["ai","design"]}'
```

### Guardrails

- **Domain-match on email shares.** An email-based share-with must share
  the API-key owner's email domain. Sharing `alex@example.com`'s apps with
  `attacker@evil.com` is rejected with `403`. Prevents a leaked key from
  silently granting a backdoor to an external account.
- **Org-aware shares extend the surface (#146, #260).** Beyond plain
  email shares, the push API also honors **member rules** (resolved via
  the TELUS directory by chairman / VP / director / cost-centre) and
  **org-admin** rules. Access can therefore land via any of three rule
  kinds — email, member, or org-admin. Highest-privilege-wins resolution
  (#158) means an email share at `viewer` doesn't shadow a member rule at
  `admin`.
- **Share-role admins ≈ owners for shares/visibility/metadata (#164).**
  The capability framework lets a share-role `admin` (not just the
  registered `owner`) manage shares, visibility, and metadata on an app.
  `gizmos db *` stays strictly owner-only — admins don't get the DB keys.
- **Audit log.** Every share add/remove and visibility/metadata change
  via the push API writes a row to `app_share_audit` with the actor's
  sub, key id, before/after state, IP, User-Agent, and CF-Ray. After a
  key rotation, an operator reviews the log to enumerate and reverse
  anything the leaked key did.
- **"Public" is not internet-open.** Gizmos `public` still requires TELUS
  SSO (`org_internal`). Flipping an app to `public` makes it discoverable
  to other TELUS employees; it does not expose it to unauthenticated
  traffic.

### Common error codes

| Status | Meaning |
|---|---|
| `400` | Missing or malformed body — bad email, invalid role, invalid visibility, malformed URL encoding |
| `401` | API key missing or revoked |
| `403` | Insufficient role (not owner / share-admin), OR shared-with email domain doesn't match the key owner's domain |
| `404` | App doesn't exist (the push API creates apps on first `/deploy`, but share/visibility routes require an existing app) |
| `409` | Visibility flip to `"public"` failed the home-page health check; body has `{status, reason}` |
| `410` | App soft-deleted — restore it first. 7-day undo window before the daily purge cron runs (#239); after that, it's gone. |

## API key bindings (M2M / webhooks / public APIs)

Apps can declare an **API key binding** in `wrangler.toml` to carve out
specific URL paths that accept `Authorization: Bearer gzak_…` instead of
the platform's OIDC flow. Use this for webhooks (Slack, GitHub),
machine-to-machine APIs, scheduled callers, and partner integrations.

### Declaring the binding

```toml
[[gizmos_api_keys]]
name = "slack"
description = "Slack webhook receiver"
paths = ["/webhooks/slack", "/webhooks/slack/*"]

[[gizmos_api_keys]]
name = "public_api"
paths = ["/api/v1/**"]
```

Path syntax is a two-token glob:
- `*` matches one URL segment (e.g. `/api/v1/*` matches `/api/v1/foo` but
  not `/api/v1/foo/bar` or `/api/v1/`).
- `**` matches anything below the prefix.

Patterns are validated at deploy time. Paths must start with `/`, contain
only `[a-zA-Z0-9._\-/*]`, and reject `..`, `//`, `?`, `#`, percent-
encodings, and `**/**`.

### Issuing a key

Two options:

**Hub UI** — open the app's settings page, find the "API Keys" card,
click **Issue key**, pick a name and expiry (30 / 90 / 365 days, or
never). The full `gzak_…` value is shown once. Copy it then.

**Programmatically from the gizmo** — each binding shows up on the
worker's `env` as an object with `list()`, `issue()`, and `revoke()`
methods. The `actor: req` argument is required so the binding can verify
the inbound request's identity. Calls from api-key-authed requests
(`role=api`) are rejected — keys cannot mint more keys.

```ts
// In your worker
export default {
  async fetch(req, env) {
    if (req.url.endsWith('/admin/rotate')) {
      const { key } = await env.SLACK.issue({
        name: 'rotated-' + Date.now(),
        expiresInSeconds: 90 * 86400,
        actor: req,
      })
      return Response.json({ key })  // shown once
    }
    return new Response('ok')
  }
}
```

### Calling the API

Send the key as a Bearer token. Allowed paths bypass OIDC.

```bash
curl https://my-app.gizmos.run/webhooks/slack \
  -H "Authorization: Bearer gzak_8f3c9a1b2d4e..." \
  -X POST -d '{"type":"event_callback","event":{"type":"app_mention"}}'
```

Inside the worker, api-key-authed requests carry these headers:

| Header | Value |
|---|---|
| `x-gizmos-role` | `api` |
| `x-gizmos-api-key-id` | The key's id (no secret) |
| `x-gizmos-api-key-name` | The label given at issue time |
| `x-gizmos-api-key-binding` | The binding's `name` from wrangler.toml |
| `x-gizmos-claim` | HMAC-signed identity claim (used by the binding RPC; opaque to the app) |

The usual `x-gizmos-user` / `x-gizmos-sub` headers also appear, but with
synthetic values (`api-key:<id>`) — there's no human user to attribute.

### Error codes

Invalid keys always return `401` with a JSON body. They never redirect
to OIDC.

| Code | Meaning |
|---|---|
| `invalid_key` | Key not recognized or hash mismatch. |
| `expired_key` | Key past its `expires_at`. |
| `revoked_key` | Key revoked by an owner / admin. |
| `binding_inactive` | The `[[gizmos_api_keys]]` section was removed in a later deploy. Re-add it to reactivate. |
| `path_not_allowed` | Path doesn't match any of the binding's globs. |

### Security model

- Path scoping is the gate — a leaked key only works on its binding's
  paths. Issue separate bindings per concern (one for Slack, one for a
  partner API) to keep blast radius small.
- Keys are stored as SHA-256 hashes; only the prefix is recoverable.
- Mutations through the binding RPC require an HMAC-signed claim, so an
  api-key-authed inbound request cannot bootstrap more keys.
- Per-issuance expiration; up to 5 active keys per binding for zero-
  downtime rotation.
- Audit rows for every issue / revoke / binding-state change in
  `app_api_key_audit`.

## Container bindings (Cloudflare Containers)

Apps can declare a **container binding** to exec arbitrary commands inside
a Cloudflare Container. Useful when you need to run untrusted code,
shell out to a tool that isn't a Worker (Python, ML inference, ffmpeg, a
language interpreter), or build a per-user scratch environment for an
AI app.

### Declaring the binding

```toml
[[gizmos_containers]]
binding = "RUNNER"
description = "Sandboxed compute"

[[gizmos_containers]]
binding = "ML"
description = "Python + ONNX runtime"
```

Each binding is a namespace; the actual container for a given key
materializes lazily on the first `instance(key)` call. There's no
shared "default" container — every call MUST go through
`instance(key)`. Declare as many bindings as your app needs; they're
independent (separate `/workspace`, processes, exposed ports, egress
policy).

### API surface

```ts
type ContainerBinding = {
  // Mint a scope addressing the container for `key`.
  instance(key: string): ContainerScope;
};

type ContainerScope = {
  // Shell exec + code interpreter
  exec(command: string, opts?: { cwd?: string; env?: Record<string,string>; timeout?: number }):
    Promise<{ stdout: string; stderr: string; exitCode: number; success: boolean }>;
  runCode(code: string, opts?: { language?: "python" | "javascript" | "typescript"; timeout?: number }):
    Promise<{ stdout: string; stderr: string; exitCode: number; success: boolean }>;

  // File ops on /workspace (and elsewhere)
  readFile(path: string): Promise<{ content: string; encoding: "utf-8" | "base64" }>;
  writeFile(path: string, content: string): Promise<void>;
  listFiles(path: string): Promise<Array<{ name: string; path: string; size: number; isDirectory: boolean; modified: string }>>;
  deleteFile(path: string): Promise<void>;
  mkdir(path: string): Promise<void>;
  exists(path: string): Promise<boolean>;

  // Background processes
  startProcess(command: string, opts?): Promise<{ id: string; pid: number; command: string; status: string; startedAt: string }>;
  listProcesses(): Promise<ProcessInfo[]>;
  killProcess(processId: string): Promise<void>;

  // Public preview URLs — hostname is derived from BASE_DOMAIN (cannot be overridden)
  exposePort(port: number): Promise<{ url: string }>;
  unexposePort(port: number): Promise<void>;
  getExposedPorts(): Promise<Array<{ port: number; url: string; token: string }>>;
};
```

### Per-key isolation

```ts
const alice = env.RUNNER.instance("alice@example.com");
await alice.writeFile("/workspace/session.json", "{}");
await alice.exec("python /workspace/solver.py");

// Different key, different container — alice's writes are invisible:
const bob = env.RUNNER.instance("bob@example.com");
await bob.exists("/workspace/session.json"); // false
```

`key` is NFC-normalized, capped at 256 chars, rejects ASCII control
chars, then SHA-256-hashed (96 bits) to derive the container id. Two
callers passing the same key share the same container. The platform
caps per-binding instances at 10,000 — bounds the reverse-lookup table
against random-key floods. Containers materialize on demand and CF
Containers idles them out on their own timers.

**SECURITY**: never pass raw request input as the key. Use an
authenticated principal id (OIDC `sub`, verified session cookie,
authed bearer). Anyone who can forge the key can claim that instance.

### Persistent data via R2 mounts

The container's `/workspace` (and everything else on local disk) is wiped
when the DO hibernates. For data that needs to survive across cold
starts, mount an R2 binding into the container:

```toml
# wrangler.toml
[[r2_buckets]]
binding = "MY_FILES"
bucket_name = "my-files"

[[gizmos_containers]]
binding = "AGENT"
```

```ts
async function getAgent(user: string) {
  const c = env.AGENT.instance(user);
  await c.mountBucket("MY_FILES", "/data"); // idempotent
  return c;
}

const c = await getAgent("alice");
await c.exec("python3 -c 'open(\"/data/notes.txt\",\"a\").write(\"hi\\n\")'");

// Worker-side reads see the same data:
const obj = await env.MY_FILES.get("notes.txt");
```

The mount maps R2 path `apps/<appId>/MY_FILES/...` (the same prefix
`R2Proxy` uses for worker-side reads) to the container's `/data`. Files
written from either surface are visible from the other.

Key things to know:

- **Call before every `exec`.** The mount lives in the container's
  in-process state and does NOT survive hibernation. `mountBucket` is
  idempotent — on warm containers it returns `{alreadyMounted: true}`
  without throwing.
- **Not POSIX-fast.** R2 underneath, via FUSE. Last-write-wins, no
  file locks, periodic sync delay between writes and visibility. Fine
  for user files / workspaces; bad for hot multi-writer state (don't
  put a SQLite write-heavy DB there).
- **Per-instance isolation is the app's responsibility.** All instances
  of `AGENT` mount the same prefix; put user files under
  `/data/users/<id>/` if you want per-user separation in R2.
- **No cross-app access.** The mount prefix is scoped to your app's
  binding name; app A can't see app B's data even if it tries to mount
  "B_BUCKET".

### Egress policy

Every binding has a default-closed egress policy seeded at deploy time
with a curated allow-list (github.com, npmjs.org, pypi.org,
anthropic.com, etc. — see `DEFAULT_APP_CONTAINER_EGRESS_ALLOW_LIST` in
`loader/src/devenv-egress.ts`). Every instance under the binding
inherits the same policy. RFC1918 / link-local / IMDS ranges are
denied by the platform regardless of rule edits.

Per-request egress decisions are audited to the
`gizmos_container_egress_events` Analytics Engine dataset (query via
the GraphQL Analytics API).

### Lifecycle

- **First call to a new key**: container starts cold (~seconds for a
  fresh image, ~hundreds of ms on warm cache).
- **Idle**: containers hibernate after inactivity. `/workspace`
  preserved.
- **Reset**: the hub's Settings → Containers card has a **Reset** button
  per binding. Reset destroys EVERY instance under that binding (one
  per key); in-flight calls fail mid-flight; next `instance(key)`
  rebuilds fresh.
- **Binding removal**: drop the `[[gizmos_containers]]` section and
  redeploy. The row is soft-deactivated; the daily cron enumerates and
  destroys every instance DO 24h later.

### Example: AI code interpreter

```toml
# wrangler.toml
[[gizmos_containers]]
binding = "SANDBOX"
```

```ts
// worker.ts
export default {
  async fetch(req, env) {
    const { code, sessionId } = await req.json();
    // Verify sessionId came from your auth before this line.
    const c = env.SANDBOX.instance(sessionId);
    const { stdout, stderr, success } = await c.runCode(code, {
      language: "python",
      timeout: 30_000,
    });
    return Response.json({ stdout, stderr, success });
  }
};
```

### Limits

- Default egress allow-list is fixed at deploy time.
- 10,000 instances per binding (soft cap; returns 429 beyond).
- No CPU / memory quotas exposed to the app — sized by the underlying
  CF Containers tier.
- Exposed-port preview URLs are public for as long as the port is
  exposed — don't surface anything you wouldn't want a stranger
  reaching.
- The bundled container image is whatever `sandbox/Dockerfile` ships
  (Debian + Python + Node + curl + the usual). No per-app custom
  images yet.

### Quirks worth knowing

- **All values cross an RPC boundary.** Arguments and return values
  must be structured-clonable: plain JSON, `Uint8Array`, `Date`. No
  functions, no class instances, no streams. `exec()` returns the
  final stdout/stderr buffers, not a `ReadableStream`.
- **`readFile` returns `{content, encoding}`.** Encoding is `"utf-8"`
  for text or `"base64"` for binary blobs — check before treating
  content as text.
- **`writeFile` content is UTF-8.** For binary, base64-encode on the
  worker side and decode inside the container.
- **Exec timeout defaults to 10 min.** Long-running work belongs in
  `startProcess()` so the call returns immediately.
- **`instance(key)` is deterministic.** Two callers with the same key
  share the container by design.
- **Reset destroys every instance.** No per-key reset from the UI; do
  it from your worker via
  `await env.X.instance(key).exec("rm -rf /workspace/*")`.

## R2 presigned URLs — storing and serving large files

Deploy bundles cap at 10 MB. For large assets (videos, PDFs, images) use R2 presigned
URLs: the worker mints a short-lived S3 SigV4 URL; the caller (upload) or browser
(playback) talks directly to R2. Zero worker memory on the data path.

### Binding type

```ts
type R2Binding = {
  createPresignedUrl(
    key: string,
    options: { method: "GET" | "PUT"; expiresIn?: number },
  ): Promise<string>;
  // + standard get / put / delete / list
};
```

`expiresIn` is seconds. Minimum 60, maximum 604 800 (7 days).

### wrangler.toml

```toml
[[r2_buckets]]
binding = "FILES"
```

No bucket name, no account ID — the loader auto-provisions and namespaces by app.

### Worker endpoints

```ts
const FILE_KEY = "my-video.mp4"

export default {
  async fetch(req, env) {
    const url = new URL(req.url)

    // Mint a presigned PUT URL (protect with [[gizmos_api_keys]] in production)
    if (req.method === "GET" && url.pathname === "/upload-url") {
      const uploadUrl = await env.FILES.createPresignedUrl(FILE_KEY, {
        method: "PUT",
        expiresIn: 300,           // 5 min — enough for a curl upload
      })
      return Response.json({ url: uploadUrl })
    }

    // Mint a presigned GET URL for browser playback / download
    if (req.method === "GET" && url.pathname === "/file-url") {
      const fileUrl = await env.FILES.createPresignedUrl(FILE_KEY, {
        method: "GET",
        expiresIn: 3600,          // 1 h — mint fresh on each page load
      })
      return new Response(fileUrl, {
        headers: { "content-type": "text/plain", "cache-control": "no-store" },
      })
    }

    return new Response("Not found", { status: 404 })
  },
}
```

### Uploading a file (two-step curl)

```bash
# Step 1 — get a presigned PUT URL (valid 5 min)
PUT_URL=$(curl -s https://my-app.gizmos.run/upload-url \
  -H "Authorization: Bearer gzak_..."   # only needed if you added an API key binding
  | jq -r .url)

# Step 2 — PUT the file straight to R2
# --data-binary is required; it sets Content-Length. -d or --upload-file won't work.
curl -X PUT "$PUT_URL" \
  -H "Content-Type: video/mp4" \
  --data-binary @/path/to/file.mp4
# Expected: empty 200 from R2
```

### Using the presigned GET URL in HTML

```html
<video id="v" controls></video>
<script>
  fetch('/file-url').then(r => r.text()).then(src => {
    document.getElementById('v').src = src
  })
</script>
```

Same pattern for `<img src>` or `<a href>` downloads. Always fetch the URL fresh —
never cache it past its `expiresIn` window.

### Locking down the upload endpoint

Add a `[[gizmos_api_keys]]` binding so only holders of a `gzak_…` key can mint upload
URLs. Without it, any authenticated TELUS user can call `/upload-url`.

```toml
[[r2_buckets]]
binding = "FILES"

[[gizmos_api_keys]]
name = "uploader"
description = "Mint presigned PUT URLs"
paths = ["/upload-url"]
```

Issue the key from the hub's app settings page → **API Keys** → binding: `uploader`.

### Local development

The loader ships a presign emulator. When `DEV_SKIP_AUTH=true` is set, presigned URLs
resolve to `http://<app>.localhost:8787/__r2-presign/...` and are verified + dispatched
against miniflare R2. No real Cloudflare credentials needed.

**Required:** add placeholder values to `loader/.dev.vars` — the emulator still needs
non-empty strings to sign and verify with:

```
R2_ACCESS_KEY_ID     = "local-dev-key-id"
R2_SECRET_ACCESS_KEY = "local-dev-secret-key"
```

Without these, `createPresignedUrl` throws even in local dev:
`R2Proxy.createPresignedUrl: R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY must be set on the loader.`

### Production requirements

The gizmos loader needs real R2 API tokens set as wrangler secrets:

```bash
cd loader
wrangler secret list           # check R2_ACCESS_KEY_ID + R2_SECRET_ACCESS_KEY exist
wrangler secret list --env dev # same for dev env
```

If missing, mint tokens at **Cloudflare dashboard → R2 → Manage R2 API Tokens**
(scope: read+write on `gizmo-apps` / `gizmo-apps-dev`), then:

```bash
echo -n "<key-id>"     | npx wrangler secret put R2_ACCESS_KEY_ID
echo -n "<key-secret>" | npx wrangler secret put R2_SECRET_ACCESS_KEY
# add --env dev for the dev environment
```

### Gotchas

| Gotcha | Detail |
|---|---|
| `env.uploader` unused warning | The `[[gizmos_api_keys]]` binding protects the path at the platform level — the worker doesn't need to reference `env.uploader` in code. The warning is a false positive; the gate is active. |
| `411 Length Required` on PUT | R2 SigV4 presigned PUT requires `Content-Length`. Use `--data-binary` in curl. Streaming bodies without a length header fail. |
| URL expiry | Presigned URLs are single-use time windows. Mint a new one if the previous one expired. `expiresIn: 300` gives 5 min; scale up if the file is very large. |
| `path_not_allowed` on API key call | The key was issued against an old binding path. Redeploy with the correct `paths` in `wrangler.toml`, then issue a new key. |
| Management API (`/api/*`) needs OIDC | `gzm_` platform keys only work on `/__push/*`. Issue app API keys (`gzak_`) from the hub UI or via `curl -X POST /api/apps/:name/api-keys` — which requires an OIDC session (works in local dev because `DEV_SKIP_AUTH` injects a synthetic session for every request). |

## Retrieving server-side logs

Use `gizmos logs <app>` to fetch logs for a deployed app from the platform's
Cloudflare Workers Observability store. Output is newline-delimited JSON
(one event per line) so it pipes cleanly into `jq`.

```bash
gizmos logs my-app --since 1h
gizmos logs my-app --since 30m --level error
gizmos logs my-app --grep "connection refused" | jq .
```

Filters available:

| Flag | Default | Notes |
|---|---|---|
| `--since <duration\|iso>` | `1h` | `30m`, `2h`, `7d`, or ISO timestamp |
| `--limit <n>` | `100` | Capped at 1000 server-side |
| `--level <level>` | (any) | One of `debug`, `info`, `warn`, `error`, `log` |
| `--grep <pattern>` | (none) | Substring match on log message |

Each output event includes `ts`, `level`, `message`, an optional `request`
(`method`, `url`, `status`), and a `raw` passthrough of the underlying
Cloudflare row for advanced consumers.

## Managing app databases (`gizmos db`)

`gizmos db` is the management surface for an app's D1 binding(s) — running
ad-hoc SQL, applying migrations, dumping the schema, or (destructively)
resetting the database. Owner-only. Rate-limited to 30 `db exec` calls per
minute per app.

```bash
# Run inline SQL (results render as an ASCII table)
gizmos db exec my-app --binding DB --sql 'SELECT count(*) FROM users'

# Run a SQL file (read locally, base64-encoded for transport)
gizmos db exec my-app --binding DB --file ./scripts/seed.sql

# Apply pending migrations against every declared D1 binding
gizmos db migrate my-app

# See what would run without executing
gizmos db migrate my-app --status

# Dump the schema (no data) to stdout or a file
gizmos db pull my-app --binding DB --output schema.sql

# Drop every user table and re-run migrations (interactive confirm + --confirm)
gizmos db reset my-app --binding DB --confirm
```

`gizmos db reset` is destructive: `--confirm` is required *and* the CLI
interactively prompts the operator to type the app name out before firing.

### D1 auto-init at deploy time

Drop migration files into `migrations/*.sql` in your deploy bundle and
the platform applies them automatically on every deploy — same flow that
`gizmos db migrate` triggers on demand. State lives in a
`_gizmos_migrations` table inside the user's own D1, same convention as
Rails / Prisma / Supabase. No extra wiring needed.

## CLI reference

```
Usage: gizmos <subcommand> [options]

Subcommands:
  push  [options] [directory]   Deploy app files to Gizmos
  logs  <app>     [options]     Retrieve server-side logs
  db    <action>  <app> [opts]  Manage app databases (run SQL, migrations, reset)
```
