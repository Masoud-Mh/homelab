# Decisions Log

## 2026-06-17
- Established **session-limit awareness** as a standing operating principle (owner on Claude Max). Built `scripts/session-guard/`: `check-usage.sh` (normalized JSON; `/usage` authoritative, `ccusage --json` fallback, ~300s cache, `--fast` for hooks, always exit 0), `wait-until-reset.sh` (background-only chunked auto-sleep with sentinel + 6h max-wait guardrail), `hook_usage.py`+`run-usage-hook.sh` (advisory hooks), and a Node `session-guard` MCP server (`get_usage`/`wait_for_reset`/`get_wait_status`) registered in `.mcp.json`. Wired hooks in `.claude/settings.json`: SessionStart, UserPromptSubmit, PreToolUse(Task) gate. Added `/usage-check` command. Policy: adaptive (no hard numeric gate) — weigh session+week %, model in use (Opus > Sonnet/Haiku cost), task size, fan-out; near limit → persist state + auto-sleep until reset then resume. Harness constraints driving design: foreground `sleep` blocked, tool timeout cap 10min, hook timeout ~15-20s → waits must be background-detached.
- Known limits accepted: `claude -p /usage` text is not a stable API (regex-parsed, variable latency); `ccusage` is a 5h-block proxy with no weekly view; mid-turn limit hits can't be fully prevented (checks are at decision points; PreToolUse(Task) targets fan-out).
- Adopted **architecture principles** (`docs/architecture-principles.md`) as the bar for all work: microservices (B+), scalability (C+), K8s readiness (D), portability/12-factor (C-), test/validation (D+). Phased remediation in `docs/architecture-roadmap.md`: P1 de-hardcode host paths, P2 containerize frontend as OCI image, P3 Vitest/pytest harness, P4 (blocked) K8s/Helm manifests. Referenced from `CLAUDE.md` + `AGENTS.md`.
- MCP server deps: `node_modules` gitignored; requires `npm install` in `scripts/session-guard/mcp/` per machine (package-lock committed).
- Handed primary development/maintenance to Claude Code (from GitHub Copilot). Owner expects no re-briefing on project state per session.
- Added Claude Code ownership scaffolding (committed `e20e4f4` on `dev`): `.claude/agents/` (deploy-operator, infra-reviewer, frontend-dev), `.claude/commands/` (stack-status, deploy-frontend, deploy-backend, smoke-test, sync-memory), `.claude/settings.json` (SessionStart+PreCompact hook → `scripts/ai-memory/run-memory-hook.sh`; read-only permission allowlist).
- Populated Claude Code native memory at `~/.claude/projects/-data-repos-homelab-stack/memory/` mirroring durable facts; `.ai/memory/` remains canonical git-tracked state (bridged).
- Installed `gh` CLI to `~/.local/bin` (v2.94.0; apt/sudo unavailable non-interactively); user authenticated (scopes: repo, workflow, write:packages).
- Added `docs/credential-rotation-runbook.md` for P0 token rotation (manual; named to avoid `.gitignore` `**/*token*`/`**/*secret*`).
- Kept legacy Copilot-era `.github/{agents,instructions,prompts}` and `copilot-instructions.md` for reference, not wired into Claude Code.

## 2026-02-25
- Adopted workspace-native Copilot files: `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.github/agents/*.agent.md`, `.github/prompts/*.prompt.md`.
- Added hook-based memory enforcement with `scripts/ai-memory/hook_memory.py` and `.github/hooks/ai-memory.json`.
- Enforced end-of-session memory marker `[MEMORY_UPDATED]` when `.ai/memory/enforce-memory-update.flag` exists.
- Kept model selection generic to avoid locking to unavailable SKUs; require free Copilot-supported model choice at runtime.
- Validated hook script syntax with `python3 -m py_compile` and smoke-tested SessionStart/Stop JSON output.
- Replaced direct `python3` hook invocation with `scripts/ai-memory/run-memory-hook.sh` runtime resolver.
- Added uv-compatible script metadata (`uv run --script`) to `hook_memory.py` with `dependencies = []`.
- Added `scripts/ai-memory/setup-hook-env.sh` for optional project-local `.venv` provisioning.
- Added reusable slash prompt `.github/prompts/audit-ai-setup.prompt.md` for independent end-to-end AI setup audit in new sessions.
- Audited AI setup: verified hook runtime robustness, memory protocol behavior, and configuration validity.
- Fixed `app/docker-compose.dev.yml` by moving frontend volume mount from backend to frontend service.
- Removed `whoami` and `whoami_alt` services from `infra/traefik/docker-compose.yml` to isolate production Traefik compose.
- Frontend roadmap sequencing explicitly overridden by user: execute frontend first; keep P0 token rotation manual in parallel.
- Production frontend rollout decision: keep existing host-sync model first (`/srv/site/frontend`), defer container/image rollout to later batch.
- Frontend implementation baseline standardized on Vite React TS with strict TypeScript and `VITE_API_BASE_URL` env handling.
- Deployment consistency decision: frontend CI/CD mirrors backend workflow style (manual `workflow_dispatch` deploy on self-hosted runner).
- Follow-up diagnostics decision: use named imports from `react` and `react-dom/client`, and add `tsconfig.node.json` for `vite.config.ts` module resolution.
- Deployment operations decision: keep a dedicated runbook in `docs/frontend-deploy-smoke-runbook.md` for repeatable frontend deploy, smoke checks, and rollback steps.
