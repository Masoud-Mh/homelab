# Agent tooling — what's installed, watchlisted, and rejected

This is the durable record of the agent toolset (MCP servers, plugins, skills) curated for
this repo. The goal is a **lean active set**: tools that serve work that recurs *now* or is
clearly *coming on the roadmap*, not generic best practice. Speculative tools live on the
watchlist with a concrete install trigger, so we're prepared without paying the cost early.

Decided 2026-06-18. Re-evaluate when the roadmap moves (K8s cluster provisioned, P2
observability started, frontend redesign begun).

## Cost model (why the split below)

- **MCP servers** carry a runtime footprint: a live connection + tool-selection noise, and
  (classically) a per-session schema tax. Note: this Claude Code build resolves MCP tool
  schemas **lazily at runtime** (`claude plugin details` reports `~0 tok always-on` for
  both context7 and playwright), so the per-session token tax is smaller than the classic
  model — but the connection + selection-noise cost still argues for keeping live MCPs few.
- **Plugins / skills / commands** are lazy-loaded and cheap to keep installed.

## Already in place (baseline — not re-litigated here)

Custom subagents `deploy-operator`, `frontend-dev`, `infra-reviewer`; slash commands
`/deploy-backend`, `/deploy-frontend`, `/smoke-test`, `/stack-status`, `/sync-memory`,
`/usage-check`; the `session-guard` MCP; the `.ai/memory` bridge; built-in skills
`/code-review`, `/simplify`, `/verify`, `/security-review`, `/deep-research`; WebSearch /
WebFetch.

## 1. Installed now

| Tool | Form | Source | Why it earns its place |
|------|------|--------|------------------------|
| **context7** | Plugin (bundles 1 MCP) | official marketplace, `external_plugins/` | Version-accurate docs for the fast-moving stack (React 19, Vite 7, FastAPI, Traefik, K8s) on demand — beats stale-knowledge guesses across hardening / K8s / observability work. |
| **playwright** | Plugin (bundles 1 MCP) | official marketplace, `external_plugins/` | Automates the currently-**manual** browser smoke checks (sections render, SPA nav, API-badge transition) in `docs/frontend-deploy-smoke-runbook.md` — a recurring per-deploy task. |
| **frontend-design** | Plugin (commands/skills, no MCP) | official marketplace, `plugins/` (Anthropic) | Lazy-loaded; readies the eventual "redesign later" frontend phase noted in CLAUDE.md. |
| **skill-creator** | Plugin (skill, no MCP) | official marketplace, `plugins/` (Anthropic) | Lazy-loaded; this repo authors its own tooling regularly — ready for the next custom command/skill (e.g. a k8s-deploy or observability command). |

Install (all user-scope, via the registered `claude-plugins-official` marketplace):
```
claude plugin marketplace add anthropics/claude-plugins-official   # already registered
claude plugin install context7@claude-plugins-official
claude plugin install playwright@claude-plugins-official
claude plugin install frontend-design@claude-plugins-official
claude plugin install skill-creator@claude-plugins-official
npx playwright install chromium                                    # browser binary, once per machine
```
- **context7** works keyless at basic rate limits. If rate-limited, add a free key
  (context7.com/dashboard) as `CONTEXT7_API_KEY` in the MCP env — never commit it.
- **playwright** drives a local headless browser only (no inbound ports opened — consistent
  with the no-inbound-ports architecture). Browser cache lives in `~/.cache/ms-playwright`.

## 2. Watchlist — install when the trigger fires

| Tool | Future need it serves | Install trigger | Form / source |
|------|-----------------------|-----------------|---------------|
| **serena** | Token-efficient semantic code navigation/editing on a large codebase | Repo outgrows comfortable Grep/Read/Explore scale (multi-package, or a refactor spanning many files) — today it's small enough that built-in search wins | Plugin/MCP, official `external_plugins/serena` |
| **kubernetes MCP** (e.g. `mcp-server-kubernetes`) | Driving the P4 K8s manifests against a real cluster | A cluster + ingress controller is provisioned and we move off Docker Compose | MCP, third-party — vet at install time |
| **observability MCP** (Grafana / Prometheus) | P2 observability baseline (structured logs + container metrics) | The P2 observability batch is picked up and a metrics/log backend is chosen | MCP, third-party — vet at install time |
| **pr-review-toolkit** | Heavier multi-aspect PR review automation | PR volume/complexity outgrows built-in `/code-review` + the `infra-reviewer` subagent | Plugin, official `plugins/` |

## 3. Rejected — and the deciding cost

| Tool | Deciding cost / reason cut |
|------|----------------------------|
| **firecrawl** | No scraping/crawling need anywhere on the roadmap; adds a paid cloud API + key. Pure cost, zero fit. |
| **Scrapling** | A Python scraping *library*, not a Claude MCP/plugin/skill — wrong category; and no scraping need regardless. |
| **superpowers** (obra) | Third-party marketplace with SessionStart context injection (permanent token tax) and an opinionated TDD/plan/execute methodology that overlaps this repo's own AGENTS.md workflow + `.ai/memory` system. Trust + cost both lose. |
| **code-review** (plugin) | Redundant — the built-in `/code-review` skill (incl. `ultra` cloud mode) is already available. |
| **postman** | Backend is 2 endpoints (`/`, `/healthz`) already covered by pytest contract tests + curl smoke checks. Heavy MCP + external account for nothing extra. |
| **remember** | Native memory + the repo's `.ai/memory` bridge + `/sync-memory` already cover durable context. Pure overlap. |
| **feature-dev** (plugin) | Overlaps plan mode + the `frontend-dev` subagent; project is in maintenance/hardening mode, not greenfield. |
| **claude-code-setup** (plugin) | Harness setup is already complete (hooks, MCP, subagents, commands); the built-in `update-config` skill handles settings changes. Low marginal value. |

## Overlap calls (where several tools cover the same ground)

- **Browser automation vs scraping** — picked **playwright** (browser automation/e2e for the
  smoke runbook) and rejected **firecrawl** / **Scrapling** (scraping), because the need here
  is *driving the rendered site*, not extracting data from third-party pages.
- **Code review** — kept the built-in `/code-review` skill; rejected the **code-review**
  plugin (redundant) and watchlisted **pr-review-toolkit** (only if review load grows).
- **Docs** — picked **context7** over ad-hoc **WebFetch** for version-pinned library docs.

## Follow-on opportunity

With playwright in place, a natural next task is a `/smoke-test-browser` command (or extend
`/smoke-test`) that scripts the runbook's manual browser checks via the Playwright MCP —
converting a recurring manual step into an automated one.
