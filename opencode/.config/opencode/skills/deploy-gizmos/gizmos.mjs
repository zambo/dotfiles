#!/usr/bin/env node

// gizmos — CLI for the Gizmos app platform.
//
// Usage:
//   gizmos push  [options] [directory]   Deploy app files to Gizmos.
//   gizmos logs  <app>     [options]     Retrieve server-side logs.
//   gizmos db    <action>  <app> [opts]  Manage app databases (SQL, migrations, reset).
//
// Global options (apply to every subcommand):
//   --app <name>         App name (default: read from wrangler.toml when relevant)
//   --api-key <key>      API key (default: $GIZMOS_API_KEY)
//   --url <url>          Gizmos base URL (default: $GIZMOS_URL)
//   --help               Show this help message

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { execSync } from "node:child_process";
import { resolve } from "node:path";
import { createInterface } from "node:readline";

// Keep in sync with package.json "version". Sent as x-gizmos-cli-version on
// every request; the loader echoes the version it currently ships back as
// x-gizmos-cli-latest and the CLI warns when this is behind.
const CLI_VERSION = "1.11.0";

function isOutdated(current, latest) {
  const a = current.split(".").map(Number);
  const b = latest.split(".").map(Number);
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const x = a[i] || 0, y = b[i] || 0;
    if (x < y) return true;
    if (x > y) return false;
  }
  return false;
}

function warnIfOutdated(res, baseUrl) {
  const latest = res.headers.get("x-gizmos-cli-latest");
  if (latest && isOutdated(CLI_VERSION, latest)) {
    process.stderr.write(
      `\n[warn] gizmos CLI ${CLI_VERSION} is out of date (latest ${latest}).\n` +
        `       Update:  curl -fsSL ${baseUrl}/skills/install.sh | bash\n`,
    );
  }
}

function topUsage() {
  console.log(`Usage: gizmos <subcommand> [options]

Subcommands:
  push  [options] [directory]   Deploy app files to Gizmos
  logs  <app>     [options]     Retrieve server-side logs
  db    <action>  <app> [opts]  Manage app databases (run SQL, migrations, reset)

Run "gizmos <subcommand> --help" for subcommand-specific options.
Run "gizmos --version" to print the CLI version.`);
}

function pushUsage() {
  console.log(`Usage: gizmos push [options] [directory]

Options:
  --app <name>         App name (default: from wrangler.toml)
  --api-key <key>      API key (default: $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default: $GIZMOS_URL)
  --org <slug>         Target org slug. Defaults to the API-key owner's
                       primary org. Required when the owner is a member
                       of multiple orgs and the target isn't primary.
  --dry-run            List files without deploying
  --wait               Block until the AI security + data-classification
                       scan completes; print findings before exiting. Use
                       in CI gates. Exit code is still 0 if the scan
                       returns findings (this is a warning, not a block).
  --help               Show this help`);
}

function logsUsage() {
  console.log(`Usage: gizmos logs <app> [options]

Options:
  --since <duration|iso>   Time range start (default 1h). E.g. 30m, 2h, 7d, 2026-04-27T12:00.
  --limit <n>              Max events (default 100, max 1000).
  --level <level>          Filter to one of: debug, info, warn, error, log.
  --grep <pattern>         Substring match on log message.
  --api-key <key>          API key (default $GIZMOS_API_KEY).
  --url <url>              Gizmos base URL (default $GIZMOS_URL).
  --org <slug>             Target org slug. Defaults to the API-key owner's
                           primary org. Required when the owner is a member
                           of multiple orgs and the target isn't primary.
  --help                   Show this help

Output is newline-delimited JSON (one event per line). Pipe to jq for analysis.`);
}

function dbUsage() {
  console.log(`Usage: gizmos db <action> <app> [options]

Actions:
  exec     <app> --binding <name> [--sql <sql> | --file <path>]
  migrate  <app> [--status]
  reset    <app> --binding <name> --confirm
  pull     <app> --binding <name> [--output <path>]

Common options:
  --api-key <key>      API key (default $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default $GIZMOS_URL)
  --help               Show this help

Run "gizmos db <action> --help" for action-specific options.`);
}

function dbExecUsage() {
  console.log(`Usage: gizmos db exec <app> --binding <name> (--sql <sql> | --file <path>)

Run arbitrary SQL against the app's D1 binding.

Options:
  --binding <name>     D1 binding name (as declared in wrangler.toml)
  --sql <sql>          Inline SQL (single string, can be multi-statement)
  --file <path>        Path to a .sql file (read and base64-encoded for transport)
  --api-key <key>      API key (default $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default $GIZMOS_URL)
  --help               Show this help

Either --sql or --file is required (not both).`);
}

function dbMigrateUsage() {
  console.log(`Usage: gizmos db migrate <app> [--status]

Apply pending migrations from the deployed bundle's migrations/ folder against
every declared D1 binding (the same flow auto-init runs at deploy time).

Options:
  --status             Show applied/pending migrations without running them
  --api-key <key>      API key (default $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default $GIZMOS_URL)
  --help               Show this help`);
}

function dbResetUsage() {
  console.log(`Usage: gizmos db reset <app> --binding <name> --confirm

DESTRUCTIVE: drop every user table on the binding and re-run all migrations.

You will be prompted to type the app name interactively to confirm; --confirm
gates the action but is not by itself sufficient.

Options:
  --binding <name>     D1 binding name (as declared in wrangler.toml)
  --confirm            Acknowledge the destructive action (still prompts)
  --api-key <key>      API key (default $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default $GIZMOS_URL)
  --help               Show this help`);
}

function dbPullUsage() {
  console.log(`Usage: gizmos db pull <app> --binding <name> [--output <path>]

Dump the binding's schema (no data) as SQL.

Options:
  --binding <name>     D1 binding name (as declared in wrangler.toml)
  --output <path>      Write to a file instead of stdout
  --api-key <key>      API key (default $GIZMOS_API_KEY)
  --url <url>          Gizmos base URL (default $GIZMOS_URL)
  --help               Show this help`);
}

function die(msg, code = 1) {
  console.error(`Error: ${msg}`);
  process.exit(code);
}

function detectAppName(dir) {
  const tomlPath = resolve(dir, "wrangler.toml");
  if (!existsSync(tomlPath)) return null;
  const content = readFileSync(tomlPath, "utf-8");
  const match = content.match(/^name\s*=\s*"([^"]+)"/m);
  return match ? match[1] : null;
}

// ---------------------------------------------------------------------------
// Shared auth + URL resolution (matches push/logs pattern)
// ---------------------------------------------------------------------------

function resolveAuth(args) {
  const apiKey = args.apiKey || process.env.GIZMOS_API_KEY;
  if (!apiKey) {
    die("No API key found.\nSet GIZMOS_API_KEY or pass --api-key <key>.\nGenerate one at your hub's /settings page.");
  }
  const baseUrl = args.url || process.env.GIZMOS_URL;
  if (!baseUrl) {
    die("No Gizmos URL found.\nSet GIZMOS_URL or pass --url <url>.\nExample: https://gizmos.run");
  }
  return { apiKey, baseUrl: baseUrl.replace(/\/$/, "") };
}

// ---------------------------------------------------------------------------
// gizmos push
// ---------------------------------------------------------------------------

function parsePushArgs(argv) {
  const args = { dir: ".", app: null, apiKey: null, url: null, org: null, dryRun: false, wait: false };
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") { pushUsage(); process.exit(0); }
    else if (arg === "--app") args.app = argv[++i];
    else if (arg === "--api-key") args.apiKey = argv[++i];
    else if (arg === "--url") args.url = argv[++i];
    else if (arg === "--org") args.org = argv[++i];
    else if (arg === "--dry-run") args.dryRun = true;
    else if (arg === "--wait") args.wait = true;
    else if (!arg.startsWith("-")) args.dir = arg;
    else die(`Unknown option: ${arg}`);
    i++;
  }
  return args;
}

function detectBundledProjectShape(dir) {
  const pkgPath = resolve(dir, "package.json");
  if (!existsSync(pkgPath)) return null;
  let pkg;
  try { pkg = JSON.parse(readFileSync(pkgPath, "utf-8")); } catch { return null; }
  if (!pkg.scripts?.build) return null;
  const bundlerConfigs = [
    "vite.config.ts", "vite.config.js", "vite.config.mjs",
    "webpack.config.js", "webpack.config.ts",
    "rollup.config.js", "rollup.config.mjs", "rollup.config.ts",
  ];
  const bundler = bundlerConfigs.find((c) => existsSync(resolve(dir, c)));
  if (!bundler) return null;
  const basename = dir.split("/").filter(Boolean).pop() ?? "";
  if (basename === "dist" || basename === "build") return null;
  return { bundler, buildScript: pkg.scripts.build };
}

async function collectFiles(dir) {
  const absDir = resolve(dir);
  try {
    const output = execSync("git ls-files --cached --others --exclude-standard", {
      cwd: absDir, encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"],
    });
    return output
      .split("\n").map((f) => f.trim()).filter(Boolean)
      .filter((f) => (
        !f.startsWith("node_modules/") &&
        !f.startsWith(".git/") &&
        !f.startsWith("dist/") &&
        !f.startsWith("build/") &&
        !f.startsWith(".wrangler/") &&
        f !== ".DS_Store"
      ));
  } catch {
    const { readdirSync } = await import("node:fs");
    const SKIP = new Set(["node_modules", ".git", "dist", "build", ".wrangler"]);
    const result = [];
    (function walk(d, prefix) {
      for (const entry of readdirSync(d, { withFileTypes: true })) {
        if (SKIP.has(entry.name)) continue;
        const full = resolve(d, entry.name);
        const rel = prefix ? `${prefix}/${entry.name}` : entry.name;
        if (entry.isDirectory()) walk(full, rel);
        else result.push(rel);
      }
    })(absDir, "");
    return result;
  }
}

async function cmdPush(argv) {
  const args = parsePushArgs(argv);
  const dir = resolve(args.dir);

  const apiKey = args.apiKey || process.env.GIZMOS_API_KEY;
  if (!apiKey && !args.dryRun) {
    die("No API key found.\nSet GIZMOS_API_KEY or pass --api-key <key>.\nGenerate one at your hub's /settings page.");
  }
  const baseUrl = args.url || process.env.GIZMOS_URL;
  if (!baseUrl && !args.dryRun) {
    die("No Gizmos URL found.\nSet GIZMOS_URL or pass --url <url>.\nExample: https://gizmos.run");
  }
  const appName = args.app || detectAppName(dir);
  if (!appName) {
    die("Could not determine app name.\nAdd name = \"my-app\" to wrangler.toml or pass --app <name>.");
  }

  const filePaths = await collectFiles(dir);
  if (filePaths.length === 0) die("No files found to deploy.");

  const bundled = detectBundledProjectShape(dir);
  if (bundled) {
    const bundlerName = bundled.bundler.split(".")[0];
    process.stderr.write(
      `\n[warn] This looks like a ${bundlerName} project — bundled projects must be built before deploy.\n` +
        `       Run the build, then push the output directory:\n\n` +
        `         npm run build && gizmos push --app ${appName} dist/\n\n` +
        `       The platform's runtime bundler does not run ${bundlerName} plugins, JSX runtimes,\n` +
        `       or path aliases — pushing source directly will fail to serve.\n\n`,
    );
  }

  console.log(`App:   ${appName}`);
  console.log(`Files: ${filePaths.length}`);

  if (args.dryRun) {
    console.log("\nFiles that would be uploaded:");
    for (const f of filePaths) console.log(`  ${f}`);
    return;
  }

  const files = {};
  for (const f of filePaths) {
    const content = readFileSync(resolve(dir, f));
    files[f] = content.toString("base64");
  }
  const body = JSON.stringify({ files });
  console.log(`Size:  ${(body.length / 1024).toFixed(1)} KB`);
  console.log(`\nDeploying to ${appName}...`);

  const url = `${baseUrl.replace(/\/$/, "")}/__push/apps/${encodeURIComponent(appName)}/deploy`;
  // --org overrides the API-key owner's primary_org_id. Required when the
  // owner is a member of multiple orgs and the target isn't their primary.
  const headers = { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json", "X-Gizmos-CLI-Version": CLI_VERSION };
  if (args.org) headers["X-Gizmos-Org-Slug"] = args.org;
  let res;
  try {
    res = await fetch(url, { method: "POST", headers, body });
  } catch (err) {
    console.error(`\nError: Could not connect to ${baseUrl}`);
    console.error(err.cause?.message || err.message);
    process.exit(1);
  }

  const resBody = await res.json().catch(() => null);
  warnIfOutdated(res, baseUrl.replace(/\/$/, ""));
  if ((res.status === 200 || res.status === 207) && resBody?.ok) {
    console.log(`\nDeployed! Live at: ${resBody.url}`);
    if (resBody.warnings?.length) {
      for (const w of resBody.warnings) process.stderr.write(`[warn] ${w}\n`);
    }

    // AI security + data-classification scan handling. The push handler
    // returns scan: { status: 'pending', poll_url } because the scan
    // runs deferred via ctx.waitUntil(). Tell the user; poll if --wait.
    if (resBody.scan?.status === "pending") {
      if (args.wait) {
        await pollScanAndPrint(baseUrl, apiKey, resBody.scan.poll_url);
      } else {
        console.log(
          "\nA security + data-classification scan is running in the background.",
        );
        console.log(
          "Pass --wait to block on findings, or check the hub UI for results.",
        );
      }
    }
  } else if (res.status === 401) {
    die("API key is invalid or revoked.\nGenerate a new one at your hub's /settings page.");
  } else if (res.status === 403) {
    die(`App "${appName}" is owned by someone else.\nChoose a different name in wrangler.toml or pass --app <name>.`);
  } else {
    console.error(`\nError: Deploy failed (HTTP ${res.status})`);
    if (resBody) console.error(JSON.stringify(resBody, null, 2));
    process.exit(1);
  }
}

// Poll GET poll_url every 2s for up to ~3 minutes. Each row carries
// status='pending'|'ok'|'failed' — exit the loop on anything other than
// pending. We treat 404 as still-pending (the row might not have been
// committed yet at the very first tick).
async function pollScanAndPrint(baseUrl, apiKey, pollUrl) {
  const url = `${baseUrl.replace(/\/$/, "")}${pollUrl}`;
  const start = Date.now();
  const TIMEOUT_MS = 3 * 60 * 1000;
  const INTERVAL_MS = 2000;
  process.stderr.write("Waiting for scan results");
  while (Date.now() - start < TIMEOUT_MS) {
    let scanRes;
    try {
      scanRes = await fetch(url, {
        headers: { Authorization: `Bearer ${apiKey}` },
      });
    } catch {
      process.stderr.write(".");
      await new Promise((r) => setTimeout(r, INTERVAL_MS));
      continue;
    }
    if (scanRes.status === 404) {
      process.stderr.write(".");
      await new Promise((r) => setTimeout(r, INTERVAL_MS));
      continue;
    }
    if (!scanRes.ok) {
      process.stderr.write(`\n[warn] scan poll returned HTTP ${scanRes.status}\n`);
      return;
    }
    const body = await scanRes.json().catch(() => null);
    if (!body || body.status === "pending") {
      process.stderr.write(".");
      await new Promise((r) => setTimeout(r, INTERVAL_MS));
      continue;
    }
    process.stderr.write("\n");
    printScanResult(body);
    return;
  }
  process.stderr.write("\n[warn] scan timed out — check the hub UI for results\n");
}

function printScanResult(scan) {
  if (scan.status === "failed") {
    process.stderr.write(`[warn] Scan failed: ${scan.failureReason ?? "unknown reason"}\n`);
    return;
  }
  const findings = Array.isArray(scan.findings) ? scan.findings : [];
  if (findings.length === 0) {
    console.log("\nSecurity + data-classification scan: no issues found.");
    if (scan.summary) console.log(`  ${scan.summary}`);
    return;
  }
  const byClass = findings.filter((f) => typeof f.type === "string" && f.type.startsWith("data_class:"));
  const high = findings.filter((f) => f.severity === "high").length;
  console.log(
    `\nSecurity + data-classification scan: ${findings.length} finding${findings.length === 1 ? "" : "s"}` +
      (high > 0 ? ` (${high} high severity)` : ""),
  );
  if (scan.summary) console.log(`  ${scan.summary}`);
  if (byClass.length > 0) {
    console.log(
      `\n  ⚠ ${byClass.length} restricted-data finding${byClass.length === 1 ? "" : "s"} (DNTL/PHI/PII/PCI).`,
    );
    console.log(
      "  Gizmos is not approved for restricted data — see https://habitat.telus.com/security/en/security-policy-standards-library/",
    );
    console.log("  and reach out in #g-developers (Slack) or @g-developers (Google Chat).");
  }
  for (const f of findings) {
    const tag = typeof f.type === "string" && f.type.startsWith("data_class:")
      ? `[${f.type.slice("data_class:".length).toUpperCase()}] `
      : "";
    console.log(`  - [${f.severity}] ${tag}${f.file}:${f.line} — ${f.message}`);
  }
}

// ---------------------------------------------------------------------------
// gizmos logs
// ---------------------------------------------------------------------------

function parseLogsArgs(argv) {
  const args = { app: null, apiKey: null, url: null, org: null, since: null, limit: null, level: null, grep: null };
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") { logsUsage(); process.exit(0); }
    else if (arg === "--app") args.app = argv[++i];
    else if (arg === "--api-key") args.apiKey = argv[++i];
    else if (arg === "--url") args.url = argv[++i];
    else if (arg === "--org") args.org = argv[++i];
    else if (arg === "--since") args.since = argv[++i];
    else if (arg === "--limit") args.limit = argv[++i];
    else if (arg === "--level") args.level = argv[++i];
    else if (arg === "--grep") args.grep = argv[++i];
    else if (!arg.startsWith("-") && !args.app) args.app = arg;
    else die(`Unknown option: ${arg}`);
    i++;
  }
  return args;
}

async function cmdLogs(argv) {
  const args = parseLogsArgs(argv);
  if (!args.app) {
    logsUsage();
    process.exit(1);
  }

  const apiKey = args.apiKey || process.env.GIZMOS_API_KEY;
  if (!apiKey) {
    die("No API key found.\nSet GIZMOS_API_KEY or pass --api-key <key>.\nGenerate one at your hub's /settings page.");
  }
  const baseUrl = args.url || process.env.GIZMOS_URL;
  if (!baseUrl) {
    die("No Gizmos URL found.\nSet GIZMOS_URL or pass --url <url>.\nExample: https://gizmos.run");
  }

  const params = new URLSearchParams();
  if (args.since) params.set("since", args.since);
  if (args.limit) params.set("limit", args.limit);
  if (args.level) params.set("level", args.level);
  if (args.grep) params.set("grep", args.grep);

  const url = `${baseUrl.replace(/\/$/, "")}/__push/apps/${encodeURIComponent(args.app)}/logs${params.toString() ? `?${params}` : ""}`;
  const headers = { Authorization: `Bearer ${apiKey}`, "X-Gizmos-CLI-Version": CLI_VERSION };
  if (args.org) headers["X-Gizmos-Org-Slug"] = args.org;
  let res;
  try {
    res = await fetch(url, { headers });
  } catch (err) {
    process.stderr.write(JSON.stringify({ error: err.cause?.message || err.message, status: 0 }) + "\n");
    process.exit(1);
  }

  const body = await res.json().catch(() => null);
  if (res.status === 200 && body?.events) {
    for (const ev of body.events) {
      process.stdout.write(JSON.stringify(ev) + "\n");
    }
    return;
  }
  process.stderr.write(JSON.stringify({ error: body?.error ?? `HTTP ${res.status}`, status: res.status }) + "\n");
  process.exit(1);
}

// ---------------------------------------------------------------------------
// gizmos db (manages app databases via the management API endpoints landed
// in PR #143). Same Bearer-token API-key auth as push/logs, against the
// /api/apps/:name/db/* surface.
// ---------------------------------------------------------------------------

/**
 * Shared db-arg parser. Each db sub-action takes <app> as the first positional
 * plus a small set of flags. We parse them inline (rather than nesting yet
 * another helper) to keep with the existing parsePushArgs / parseLogsArgs
 * shape.
 */
function parseDbCommonArgs(argv, accept) {
  const args = { app: null, apiKey: null, url: null };
  for (const k of Object.keys(accept)) args[k] = accept[k];
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === "--help" || arg === "-h") return { ...args, _help: true };
    else if (arg === "--api-key") args.apiKey = argv[++i];
    else if (arg === "--url") args.url = argv[++i];
    else if (arg in accept) {
      // Boolean flag (initial value is false) vs. value flag.
      if (typeof accept[arg] === "boolean") args[arg] = true;
      else args[arg] = argv[++i];
    } else if (!arg.startsWith("-") && !args.app) {
      args.app = arg;
    } else {
      die(`Unknown option: ${arg}`);
    }
    i++;
  }
  return args;
}

/**
 * Render a 2D array of strings as a simple ASCII table. Keep it dependency-free
 * — D1 result sets are usually small and a basic monospace box is plenty.
 */
function renderTable(headers, rows) {
  const cols = headers.length;
  const widths = headers.map((h, i) =>
    Math.max(String(h).length, ...rows.map((r) => String(r[i] ?? "").length)),
  );
  const sep = "+" + widths.map((w) => "-".repeat(w + 2)).join("+") + "+";
  const fmt = (row) =>
    "| " + row.map((c, i) => String(c ?? "").padEnd(widths[i])).join(" | ") + " |";
  const out = [sep, fmt(headers), sep];
  for (const r of rows) out.push(fmt(r));
  out.push(sep);
  return out.join("\n");
}

function renderResults(results) {
  if (!Array.isArray(results) || results.length === 0) return "(no rows)";
  const headers = Object.keys(results[0]);
  const rows = results.map((r) => headers.map((h) => r[h]));
  return renderTable(headers, rows);
}

async function dbFetch(method, baseUrl, apiKey, path, body) {
  const url = `${baseUrl}${path}`;
  const init = { method, headers: { Authorization: `Bearer ${apiKey}`, "X-Gizmos-CLI-Version": CLI_VERSION } };
  if (body !== undefined) {
    init.headers["Content-Type"] = "application/json";
    init.body = typeof body === "string" ? body : JSON.stringify(body);
  }
  let res;
  try {
    res = await fetch(url, init);
  } catch (err) {
    die(`Could not connect to ${baseUrl}\n${err.cause?.message || err.message}`);
  }
  return res;
}

async function readJsonOrNull(res) {
  return res.json().catch(() => null);
}

function reportAuthError(res) {
  if (res.status === 401) {
    die("API key is invalid or revoked.\nGenerate a new one at your hub's /settings page.");
  }
  if (res.status === 403) {
    die("Forbidden. The db subcommands are owner-only — only the app's owner can run them.");
  }
  if (res.status === 404) {
    die("App not found. Check the app name and that it has been deployed.");
  }
  if (res.status === 429) {
    die("Rate limit exceeded — server allows max 30 db/exec calls/minute per app.");
  }
}

// ---- gizmos db exec ----

function parseDbExecArgs(argv) {
  return parseDbCommonArgs(argv, {
    "--binding": null,
    "--sql": null,
    "--file": null,
  });
}

async function cmdDbExec(argv) {
  const args = parseDbExecArgs(argv);
  if (args._help) { dbExecUsage(); process.exit(0); }
  if (!args.app) { dbExecUsage(); process.exit(1); }
  if (!args["--binding"]) die("--binding is required.");
  if (!args["--sql"] && !args["--file"]) die("Either --sql or --file is required.");
  if (args["--sql"] && args["--file"]) die("Pass --sql or --file, not both.");

  const { apiKey, baseUrl } = resolveAuth(args);
  const body = { binding: args["--binding"] };
  if (args["--sql"]) {
    body.sql = args["--sql"];
  } else {
    const path = resolve(args["--file"]);
    if (!existsSync(path)) die(`SQL file not found: ${path}`);
    const sql = readFileSync(path, "utf-8");
    body.file = Buffer.from(sql, "utf-8").toString("base64");
  }

  const res = await dbFetch(
    "POST",
    baseUrl,
    apiKey,
    `/api/apps/${encodeURIComponent(args.app)}/db/exec`,
    body,
  );
  reportAuthError(res);

  const json = await readJsonOrNull(res);
  if (res.status === 200 && json?.ok) {
    if (Array.isArray(json.results) && json.results.length > 0) {
      console.log(renderResults(json.results));
    } else {
      const parts = [`ok`];
      if (typeof json.count === "number") parts.push(`count=${json.count}`);
      if (typeof json.duration === "number") parts.push(`duration=${json.duration}ms`);
      console.log(parts.join(" "));
    }
    return;
  }
  console.error(`Error: db exec failed (HTTP ${res.status})`);
  if (json) console.error(JSON.stringify(json, null, 2));
  process.exit(1);
}

// ---- gizmos db migrate ----

function parseDbMigrateArgs(argv) {
  return parseDbCommonArgs(argv, { "--status": false });
}

function printBindingMigrationResult(b) {
  const header = `binding: ${b.binding}`;
  const lines = [header];
  if (b.error) lines.push(`  error: ${b.error}`);
  if (Array.isArray(b.applied)) {
    lines.push(b.applied.length === 0
      ? `  applied: (none)`
      : `  applied:\n${b.applied.map((m) => `    - ${m}`).join("\n")}`);
  }
  if (Array.isArray(b.skipped)) {
    lines.push(b.skipped.length === 0
      ? `  skipped: (none)`
      : `  skipped:\n${b.skipped.map((m) => `    - ${m}`).join("\n")}`);
  }
  if (Array.isArray(b.pending)) {
    lines.push(b.pending.length === 0
      ? `  pending: (none)`
      : `  pending:\n${b.pending.map((m) => `    - ${m}`).join("\n")}`);
  }
  return lines.join("\n");
}

async function cmdDbMigrate(argv) {
  const args = parseDbMigrateArgs(argv);
  if (args._help) { dbMigrateUsage(); process.exit(0); }
  if (!args.app) { dbMigrateUsage(); process.exit(1); }

  const { apiKey, baseUrl } = resolveAuth(args);
  const path = `/api/apps/${encodeURIComponent(args.app)}/db/migrate`;

  let res;
  if (args["--status"]) {
    res = await dbFetch("GET", baseUrl, apiKey, `${path}?status=true`);
  } else {
    res = await dbFetch("POST", baseUrl, apiKey, path, {});
  }
  reportAuthError(res);

  const json = await readJsonOrNull(res);
  // Treat 200 and 207 (multi-status from #143's reset/migrate) as success-ish:
  // print the per-binding breakdown, exit non-zero only if any binding errored.
  if ((res.status === 200 || res.status === 207) && Array.isArray(json?.bindings)) {
    if (json.bindings.length === 0) {
      console.log("(no D1 bindings declared)");
      return;
    }
    for (const b of json.bindings) console.log(printBindingMigrationResult(b));
    if (json.bindings.some((b) => b.error)) process.exit(1);
    return;
  }
  console.error(`Error: db migrate failed (HTTP ${res.status})`);
  if (json) console.error(JSON.stringify(json, null, 2));
  process.exit(1);
}

// ---- gizmos db reset ----

function parseDbResetArgs(argv) {
  return parseDbCommonArgs(argv, {
    "--binding": null,
    "--confirm": false,
  });
}

function promptYesNo(question) {
  const rl = createInterface({ input: process.stdin, output: process.stderr });
  return new Promise((resolveAns) => {
    rl.question(question, (answer) => {
      rl.close();
      resolveAns(answer.trim());
    });
  });
}

async function cmdDbReset(argv) {
  const args = parseDbResetArgs(argv);
  if (args._help) { dbResetUsage(); process.exit(0); }
  if (!args.app) { dbResetUsage(); process.exit(1); }
  if (!args["--binding"]) die("--binding is required.");
  if (!args["--confirm"]) {
    die("--confirm is required (and you'll still be prompted to type the app name).");
  }

  const { apiKey, baseUrl } = resolveAuth(args);

  // Server requires { confirm: <app-name> }, but we also gate interactively
  // because --confirm alone is a foot-gun (one stray history-search and it
  // fires). Make the user type the name out loud.
  process.stderr.write(
    `\nDestructive: this will drop EVERY user table on binding "${args["--binding"]}"\n` +
      `of app "${args.app}" and re-run all migrations. Data is unrecoverable.\n\n`,
  );
  const typed = await promptYesNo(`Type the app name to confirm ("${args.app}"): `);
  if (typed !== args.app) {
    die("Aborted: app name did not match.");
  }

  const res = await dbFetch(
    "POST",
    baseUrl,
    apiKey,
    `/api/apps/${encodeURIComponent(args.app)}/db/reset`,
    { binding: args["--binding"], confirm: args.app },
  );
  reportAuthError(res);

  const json = await readJsonOrNull(res);
  if ((res.status === 200 || res.status === 207) && json) {
    if (typeof json.dropped === "number") console.log(`tables dropped: ${json.dropped}`);
    if (Array.isArray(json.applied)) {
      console.log(json.applied.length === 0
        ? "migrations re-applied: (none)"
        : `migrations re-applied:\n${json.applied.map((m) => `  - ${m}`).join("\n")}`);
    }
    if (Array.isArray(json.skipped) && json.skipped.length > 0) {
      console.log(`migrations skipped:\n${json.skipped.map((m) => `  - ${m}`).join("\n")}`);
    }
    if (json.error) {
      console.error(`error: ${json.error}`);
      process.exit(1);
    }
    return;
  }
  console.error(`Error: db reset failed (HTTP ${res.status})`);
  if (json) console.error(JSON.stringify(json, null, 2));
  process.exit(1);
}

// ---- gizmos db pull ----

function parseDbPullArgs(argv) {
  return parseDbCommonArgs(argv, {
    "--binding": null,
    "--output": null,
  });
}

async function cmdDbPull(argv) {
  const args = parseDbPullArgs(argv);
  if (args._help) { dbPullUsage(); process.exit(0); }
  if (!args.app) { dbPullUsage(); process.exit(1); }
  if (!args["--binding"]) die("--binding is required.");

  const { apiKey, baseUrl } = resolveAuth(args);
  const params = new URLSearchParams({ binding: args["--binding"] });
  const res = await dbFetch(
    "GET",
    baseUrl,
    apiKey,
    `/api/apps/${encodeURIComponent(args.app)}/db/pull?${params}`,
  );
  reportAuthError(res);

  // /db/pull returns text/plain SQL on success, JSON error otherwise.
  if (res.status === 200) {
    const sql = await res.text();
    if (args["--output"]) {
      writeFileSync(resolve(args["--output"]), sql);
      console.error(`wrote ${sql.length} bytes to ${args["--output"]}`);
    } else {
      process.stdout.write(sql);
      if (!sql.endsWith("\n")) process.stdout.write("\n");
    }
    return;
  }
  const json = await readJsonOrNull(res);
  console.error(`Error: db pull failed (HTTP ${res.status})`);
  if (json) console.error(JSON.stringify(json, null, 2));
  process.exit(1);
}

// ---- gizmos db dispatcher ----

async function cmdDb(argv) {
  const sub = argv[0];
  const rest = argv.slice(1);
  if (!sub || sub === "--help" || sub === "-h") {
    dbUsage();
    process.exit(sub ? 0 : 1);
  }
  if (sub === "exec") return cmdDbExec(rest);
  if (sub === "migrate") return cmdDbMigrate(rest);
  if (sub === "reset") return cmdDbReset(rest);
  if (sub === "pull") return cmdDbPull(rest);
  die(`Unknown db action: ${sub}\n\nRun "gizmos db --help" for the list of actions.`);
}

// ---------------------------------------------------------------------------
// Dispatcher
// ---------------------------------------------------------------------------

const cmd = process.argv[2];
const rest = process.argv.slice(3);

if (cmd === "--version" || cmd === "-v") {
  console.log(CLI_VERSION);
  process.exit(0);
}

if (!cmd || cmd === "--help" || cmd === "-h") {
  topUsage();
  process.exit(cmd ? 0 : 1);
}

if (cmd === "push") {
  await cmdPush(rest);
} else if (cmd === "logs") {
  await cmdLogs(rest);
} else if (cmd === "db") {
  await cmdDb(rest);
} else {
  die(`Unknown subcommand: ${cmd}\n\nRun "gizmos --help" for the list of subcommands.`);
}
