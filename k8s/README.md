# Kubernetes manifests (draft — roadmap P4)

Declarative manifests expressing the homelab-stack on Kubernetes. **Draft / not
deployed** — there is no cluster yet; production runs on Docker Compose. These exist to
prove K8s readiness (principle 3) and to be the migration target once a cluster exists.

## What's here

| File | Objects |
|------|---------|
| `namespace.yaml` | `homelab` namespace |
| `backend.yaml` | ConfigMap (`CORS_ORIGINS`) + Deployment + Service (FastAPI, port 8000, `/healthz` probes) |
| `frontend.yaml` | Deployment + Service (nginx image, port 80, `/` probes) |
| `ingress.yaml` | Ingress mapping public hosts → services |

Both Deployments run the **GHCR images** built by CI (`homelab-backend`,
`homelab-frontend`) — the same artifacts the Compose stack uses after the P2 cutover.

## Routing parity with Compose/Traefik

| Public host | Compose (Traefik label) | K8s (Ingress) |
|-------------|-------------------------|---------------|
| `masoud-mh.com`, `www.masoud-mh.com` | router `site` → frontend:80 | `ingress.yaml` → `frontend:80` |
| `api.masoud-mh.com` | router `api` → backend:8000 | `ingress.yaml` → `backend:8000` |

`.local` hosts (`site.local`, `api.site.local`) are dev/internal and omitted here.
TLS terminates at Cloudflare today, so the Ingress is HTTP (no `tls:` block) — matching
the current edge model. `ingressClassName: traefik` matches the existing reverse proxy.

## Prerequisites before a real deploy (not done here)

1. A cluster + an ingress controller (Traefik or other).
2. A GHCR image pull secret named `ghcr-pull` in the `homelab` namespace (images are private):
   ```
   kubectl -n homelab create secret docker-registry ghcr-pull \
     --docker-server=ghcr.io --docker-username=<user> --docker-password=<token>
   ```
3. DNS / Cloudflare pointing the hosts at the cluster ingress (or keep the tunnel in front).

## Validate

No cluster/`kubectl` is required to sanity-check structure:
```
kubectl apply --dry-run=client -f k8s/    # when kubectl is available
# or: kubeconform -strict k8s/
```
Pin images to a `sha-<sha>` tag (not `latest`) for real, reproducible deploys.
