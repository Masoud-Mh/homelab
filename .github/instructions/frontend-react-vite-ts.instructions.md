---
name: Frontend React/Vite/TS Rules
description: Apply when changing frontend migration files
applyTo: app/frontend/**
---
# Frontend migration rules
- Implement roadmap phases in order from [docs/frontend-react-vite-ts-roadmap.md](../../docs/frontend-react-vite-ts-roadmap.md).
- Maintain visual/behavior parity first, then improve.
- Use `VITE_API_BASE_URL` for backend URL in frontend code.
- Ensure polling effects include cleanup (`clearInterval`, race-safety guard).
- Keep TypeScript strict checks passing.
- Validate with `npm run build` for each substantive change.
- Update memory files in `.ai/memory/` after each finished frontend batch.
