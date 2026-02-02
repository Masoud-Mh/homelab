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
├── infra/
│   ├── traefik/
│   │   ├── docker-compose.yml
│   │   └── config/
│   │       └── traefik.yml
│   └── cloudflared/
│       ├── docker-compose.yml
│       └── .env.example
│
├── app/
│   ├── docker-compose.yml
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

### 1️⃣ Start Traefik
```bash
cd infra/traefik
sudo docker compose up -d
````

### 2️⃣ Start Application Stack

```bash
cd app
sudo docker compose up -d
```

### 3️⃣ Start Cloudflare Tunnel

```bash
cd infra/cloudflared
sudo docker compose up -d
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

## 🚀 Roadmap

Planned next steps:

* GitHub Actions:

  * Build backend image
  * Push to GitHub Container Registry (GHCR)
* Automated deployment to homelab
* Environment separation (dev / prod)
* Observability (metrics & logs)

---

## 📌 Why this project exists

This homelab is intentionally designed to reflect **real-world infrastructure decisions**, not just to “make it work”:

* Security-first
* Minimal but correct
* Understandable by other engineers
* Maintainable long-term
