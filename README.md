# Homelab Stack — Traefik + Cloudflare Tunnel + FastAPI

This repository contains my **production-style homelab stack**, built to demonstrate modern infrastructure practices:

- No port forwarding
- Secure public exposure via Cloudflare Tunnel
- Reverse proxy with Traefik
- Containerized frontend and backend
- Clear separation between application and infrastructure

This setup mirrors real-world patterns used in small teams and startups.

---

## 🧱 Architecture (High Level)

```

Internet
↓
Cloudflare Edge (DNS + HTTPS + WAF)
↓
Cloudflare Tunnel (cloudflared)
↓
Traefik (reverse proxy, hostname routing)
↓
Docker services
├── Frontend (Nginx static site)
└── Backend (FastAPI)

```

**Key properties**
- No inbound ports opened on the router
- TLS handled entirely by Cloudflare
- Internal services never exposed directly

---

## 📁 Repository Structure

```
homelab-stack/
├── .github/
│   └── workflows/
│       ├── backend-ci.yml          # CI: build & push to GHCR
│       └── deploy-backend.yml      # Deployment: manual trigger, self-hosted runner
│
├── infra/
│   ├── traefik/
│   │   ├── docker-compose.yml
│   │   └── config/
│   │       └── traefik.yml
│   ├── cloudflared/
│   │   ├── docker-compose.yml
│   │   └── .env.example
│   └── github_action_runner/       # Self-hosted Actions runner setup
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── README.md
│       └── remove-runner.sh
│
├── app/
│   ├── docker-compose.yml
│   ├── deploy-backend.sh           # Deployment script (used by CI/CD)
│   ├── frontend/
│   │   └── index.html
│   └── backend/
│       ├── Dockerfile
│       ├── main.py
│       └── requirements.txt
│
└── README.md
```

---

## ⚙️ Components

### Traefik
- Acts as the internal reverse proxy
- Routes traffic by hostname
- Provides a dashboard (protected via Cloudflare Access)

### Cloudflare Tunnel (`cloudflared`)
- Creates outbound-only tunnel to Cloudflare
- Eliminates the need for port forwarding
- Handles public HTTPS access

### Frontend
- Static HTML served via Nginx
- Communicates with backend over HTTPS

### Backend
- FastAPI application
- Health endpoint at `/healthz`
- CORS configured via environment variables

---

## 🌍 Public URLs (via Cloudflare)

| Service | URL |
|------|----|
| Frontend | `https://masoud-mh.com` |
| Frontend (www) | `https://www.masoud-mh.com` |
| Backend API | `https://api.masoud-mh.com` |
| Traefik Dashboard | `https://traefik.masoud-mh.com` (Access-protected) |

---

## 🖥️ Local LAN Access (hosts file)

For local development or LAN access, add entries to your machine’s hosts file:

```

<server-ip> site.local <server-ip> api.site.local <server-ip> traefik.local

```

Examples:
- `http://site.local`
- `http://api.site.local`
- `http://traefik.local/dashboard`

---

## 🔐 Secrets & Environment Variables

Secrets are **never committed**.

### Cloudflare Tunnel
Create a local `.env` file:

```

infra/cloudflared/.env

```

Example:
```

CLOUDFLARE_TUNNEL_TOKEN=your_real_token_here

```

### Backend
CORS is configured via environment variables:

```

CORS_ORIGINS=[https://masoud-mh.com,https://www.masoud-mh.com](https://masoud-mh.com,https://www.masoud-mh.com)

````

---

## ▶️ How to Run

### Local Manual Setup

#### 1️⃣ Start Traefik
```bash
cd infra/traefik
sudo docker compose up -d
```

#### 2️⃣ Start Application Stack
```bash
cd app
sudo docker compose up -d
```

#### 3️⃣ Start Cloudflare Tunnel
```bash
cd infra/cloudflared
sudo docker compose up -d
```

### Automated Deployment (Production)

#### Prerequisites
- Self-hosted GitHub Actions Runner installed and running on homelab (`infra/github_action_runner/`)
- Push access to GitHub repo

#### Deployment Steps

1. **Push code to trigger CI:**
   ```bash
   git push origin main
   ```
   → `backend-ci` workflow builds and pushes image to GHCR

2. **Deploy to homelab:**
   - Go to GitHub repo → Actions → `deploy-backend` → Click "Run workflow"
   - Optional: Specify a tag (e.g., `v1.0.0`) or leave blank for latest main commit
   - Runner pulls image and restarts backend container

**Example workflow:**
```
Feature branch pushed → PR opened → backend-ci validates build ✓
PR reviewed and merged → Pushed to main → backend-ci builds & pushes to GHCR
Manual: Click "Run workflow" → deploy-backend pulls & restarts container
```

---

## 🔎 Useful Commands

Check status:

```bash
sudo docker ps
```

Logs:

```bash
sudo docker logs traefik --tail 100
sudo docker logs cloudflared --tail 100
sudo docker logs site_backend --tail 100
```

Health check:

```bash
curl https://api.masoud-mh.com/healthz
```

---

## 🛡️ Security Notes

* No inbound firewall rules required
* Traefik dashboard protected with Cloudflare Access
* Cloudflare handles TLS, WAF, and DDoS protection
* Internal Docker network isolates services

---

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

#### `backend-ci` (build-and-push)
- **Triggers**: Push to `main`, version tags (`v*`), or Pull Requests
- **PR jobs**: Validates Docker build (no push to registry)
- **Release jobs**: Builds and pushes image to GHCR with automatic tagging:
  - `latest` (only for main branch)
  - Branch and tag names
  - Git SHA-based versions

**Image location**: `ghcr.io/Masoud-Mh/homelab-backend`

#### `deploy-backend` (automated deployment)
- **Trigger**: Manual via GitHub UI (workflow_dispatch)
- **Runner**: Self-hosted runner on homelab (requires GitHub Actions Runner setup)
- **Environment**: Production
- **Accepts**: Optional tag input (defaults to latest main commit)
- **Actions**: Pulls image from GHCR and restarts backend container

---

## 🤖 AI Agent Workflow

This repository includes workspace-level agent configuration and memory files for long-running AI execution.

- Setup and usage guide: `docs/ai-agent-execution-guide.md`
- Always-on instructions: `.github/copilot-instructions.md` and `AGENTS.md`
- Custom agents and slash prompts: `.github/agents/` and `.github/prompts/`
- Memory system: `.ai/memory/`

### Self-Hosted Runner
Located in `infra/github_action_runner/`:
- Runs on homelab server
- Pulls images from GHCR
- Executes deployment scripts with local Docker access
- See [GitHub Actions Runner README](infra/github_action_runner/README.md)

---

## 🚀 Roadmap

Planned next steps:

* Observability (metrics & logs with Prometheus/Grafana)
* Multi-environment support (staging / production separation)
* Database integration & migrations
* Monitoring and alerting

---

## 📌 Why this project exists

This homelab is intentionally designed to reflect **real-world infrastructure decisions**, not just to “make it work”:

* Security-first
* Minimal but correct
* Understandable by other engineers
* Maintainable long-term
