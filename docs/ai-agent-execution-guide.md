# AI Agent Execution Guide

This project now includes a built-in agent operating model for VS Code Copilot.

## What was configured
- Always-on instructions: `.github/copilot-instructions.md`
- Cross-agent contract: `AGENTS.md`
- File-scoped instructions: `.github/instructions/*.instructions.md`
- Custom agents: `.github/agents/*.agent.md`
- Slash prompts: `.github/prompts/*.prompt.md`
- Memory hooks: `.github/hooks/ai-memory.json` + `scripts/ai-memory/hook_memory.py`
- Memory files: `.ai/memory/*`

## Default execution flow
1. Run planning with custom agent `homelab-planner`.
2. Execute roadmap with `/run-frontend-roadmap`.
3. Execute technical debt with `/run-techdebt-batches`.
4. Refresh memory with `/sync-memory`.

## Free-model requirement
For autonomous/background runs, select a free model available in your Copilot plan from the model picker before starting the session.

## Automatic memory behavior
- Hooks write runtime logs to `.ai/memory/runtime/`.
- On session end, hook checks for `[MEMORY_UPDATED]` marker.
- If missing, the session is blocked once and agent must update memory files before finishing.

## Hook runtime resolution
- Hook command now runs `scripts/ai-memory/run-memory-hook.sh`.
- Runtime selection order:
	1. project `.venv/bin/python`
	2. `uv run --script` (from inline metadata in `hook_memory.py`)
	3. `python3`
	4. `python`
- Optional setup for a project-local Python runtime:
	- `./scripts/ai-memory/setup-hook-env.sh`

## Required end-of-task updates
- `.ai/memory/active-context.md`
- `.ai/memory/decisions.md`
- `.ai/memory/roadmap-status.md` or `.ai/memory/batch-status.md`

## Optional extension research result
Built-in Copilot features are sufficient for this setup. Optional memory extensions were reviewed, but not required for this repository-level system.
