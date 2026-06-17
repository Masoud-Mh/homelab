# Architecture Principles

These are the standing engineering principles for homelab-stack. **All work — new
features and remediation of existing code — is held to them.** Each principle lists its
definition, the current grade (baseline assessment 2026-06-17), and the rule for new work.

Phased remediation toward these grades is tracked in
[architecture-roadmap.md](architecture-roadmap.md).

---

## 1. Microservice architecture — current: **B+**

**Definition.** Independently deployable, loosely coupled services with clear
boundaries, communicating over well-defined interfaces. No shared in-process state.

**Where we are.** Two services (frontend nginx + FastAPI backend) on the external
`traefik_proxy` network, label-driven routing, backend shipped as an immutable GHCR
image. Clean separation of `app/` (deployed) vs `infra/` (platform).

**Rule for new work.**
- A new capability that has its own lifecycle, scaling profile, or data store is a new
  service, not a module bolted onto an existing one.
- Services communicate over HTTP/declared contracts, never shared files or implicit
  global state. Keep the backend surface explicit (today: `/` + `/healthz`).
- Preserve label-driven Traefik routing; never hardcode routes in a service.

## 2. Scalability — current: **C+**

**Definition.** Services scale horizontally (stateless, replicas behind a balancer)
without code changes; no single-instance assumptions.

**Where we are.** Frontend is stateless static content (trivially scalable). Backend is
a single instance; Traefik *could* load-balance replicas but none are defined.

**Rule for new work.**
- Keep services **stateless**; push state to external stores (DB/cache/object storage),
  never to container-local disk or in-memory singletons that assume one replica.
- No sticky in-process sessions. Anything that breaks under N>1 replicas is a defect.
- Make concurrency/limits configurable via env, not hardcoded.

## 3. Kubernetes readiness — current: **D**

**Definition.** Services can be expressed as declarative K8s objects (Deployment,
Service, Ingress, ConfigMap/Secret) and run unmodified on a cluster.

**Where we are.** No manifests. Hard blockers: host-path mounts (`/srv/site`), frontend
served from host-synced files rather than an image, deploy-by-shell-script.

**Rule for new work.**
- Every service must be a self-contained **OCI image** (no host-path source mounts for
  app code). Config via env/files injected at runtime, not baked host paths.
- Expose a health endpoint suitable for liveness/readiness probes (backend has
  `/healthz`; new services must provide one).
- Don't add new host-path dependencies; if persistence is needed, model it as a volume
  that maps cleanly to a PVC.

## 4. Environment-agnostic & containerized (portable) — current: **C-**

**Definition.** The stack runs on any host/cluster with no machine-specific assumptions.
12-factor config: everything environment-specific comes from the environment.

**Where we are.** Good: env-driven CORS, `VITE_API_BASE_URL`, GHCR-tagged backend, and
`.env.example` templates. Poor: `/srv/site`, `/srv/site-dev`, and
`/data/repos/homelab-stack` are baked into compose, deploy scripts, and workflows.

**Rule for new work.**
- **No hardcoded host paths.** Use env vars with sane defaults (e.g. `SITE_ROOT`,
  `REPO_ROOT`) and document them in `.env.example`.
- Frontend↔backend coupling stays build-time-explicit via `VITE_`-prefixed vars.
- A change must run identically on a second host with only a different `.env`.

## 5. Test & validation — current: **D+**

**Definition.** Automated gates prove changes are correct before they ship: typecheck,
unit/contract/integration tests, and image checks in CI.

**Where we are.** Only gate is `npm run build` (embedded `tsc`) for the frontend and a
Docker build for the backend. No unit/integration/E2E tests; manual smoke runbook only.

**Rule for new work.**
- New backend endpoints ship with a contract test (pytest). New frontend logic/components
  ship with a Vitest test. The build/typecheck remains the floor, not the ceiling.
- Wire every new test type into the matching CI workflow so it actually gates PRs.
- Prefer root-cause fixes with a regression test over patches.

---

## How these interact with existing guardrails

These principles sit **alongside** the hard guardrails in `AGENTS.md` / `CLAUDE.md`:
preserve Traefik + Cloudflare routing, never expose secrets, smallest safe change set,
no destructive commands. When a principle and a guardrail seem to conflict (e.g. moving
to images touches routing), the guardrail wins — make the change behind parity and verify
routing is intact before flipping over.
