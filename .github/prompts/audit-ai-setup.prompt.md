---
name: audit-ai-setup
description: Independently audit AI setup, hooks, memory protocol, and automation reliability
agent: homelab-implementer
argument-hint: Optional scope, e.g. "scope=full" or "scope=hooks-only"
---
You are an independent senior AI auditor. Audit the AI-agent setup in this repository and verify correctness, safety, and operational reliability.

Scope:
1. Validate custom instructions, agents, prompts, and hooks configuration.
2. Verify memory protocol behavior (read/update requirements and `[MEMORY_UPDATED]` enforcement).
3. Verify hook runtime robustness (project `.venv`, uv script mode, python fallback chain).
4. Test automated processes where feasible and report pass/fail with evidence.
5. Identify defects, risks, or unclear behaviors; then apply minimal fixes and re-test.

Required context files:
- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/*`
- `.github/agents/*`
- `.github/prompts/*`
- `.github/hooks/ai-memory.json`
- `scripts/ai-memory/*`
- `.ai/memory/*`
- `docs/ai-agent-execution-guide.md`
- `docs/frontend-react-vite-ts-roadmap.md`
- `docs/project-current-state-report.md` (section 5)

Tooling requirements:
- Use `fetch_webpage` for current VS Code/Copilot hooks/agents docs.
- Use Context7 (upstash) for authoritative docs (VS Code/Copilot + uv script guidance).
- Use `vscode_searchExtensions_internal` to cross-check relevant extension/tooling options.
- Use terminal checks to test hooks/scripts.
- Use targeted tests first, then broader checks if needed.

Testing checklist:
- Hook JSON loads and points to executable command.
- Hook wrapper execution with SessionStart and Stop sample payloads returns valid JSON.
- Runtime resolver order behaves as documented.
- Memory enforcement: Stop behavior blocks completion when `[MEMORY_UPDATED]` marker is absent (where testable).
- No secrets are printed.
- No unrelated files are changed.

Output format:
- Executive summary (pass/fail by area)
- Findings with severity (critical/high/medium/low)
- Evidence (commands run + concise outputs)
- Exact fixes applied (if any)
- Residual risks and recommendations
- Final verdict: READY / NEEDS_FIXES

Constraints:
- Keep backend production behavior stable.
- Keep changes surgical.
- Do not rotate secrets automatically.
- Prefer free models available under GitHub Copilot subscription.

User input: ${input:scope:scope=full}
