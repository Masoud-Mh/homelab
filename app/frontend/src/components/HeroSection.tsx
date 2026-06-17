import { ApiHealthBadge } from './ApiHealthBadge'

export function HeroSection() {
  return (
    <section className="hero">
      <div className="kicker">Portfolio</div>
      <h1>Building reliable services and infrastructure.</h1>
      <p className="subtitle">
        I work on backend services, automation, and production-style infrastructure. This site is hosted on my homelab stack:
        Docker + Traefik + Cloudflare Tunnel, with CI/CD pushing immutable images to GHCR.
      </p>

      <div className="section row">
        <ApiHealthBadge />
        <span className="pill muted">Norway (Oslo time)</span>
      </div>
    </section>
  )
}