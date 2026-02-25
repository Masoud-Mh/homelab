# Decisions Log

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
