export function ProjectsSection() {
  return (
    <section id="projects" className="section">
      <h2>Projects</h2>
      <div className="grid">
        <div className="card">
          <h3>Homelab Platform (this site)</h3>
          <p className="muted">
            Production-style setup: no inbound ports, Cloudflare Tunnel + Access, Traefik routing, Docker Compose, GitHub Actions
            builds and pushes backend images to GHCR, manual approved deploys on a self-hosted runner.
          </p>
          <div className="row">
            <span className="pill muted">Docker</span>
            <span className="pill muted">Traefik</span>
            <span className="pill muted">Cloudflare Tunnel</span>
            <span className="pill muted">GitHub Actions</span>
          </div>
        </div>

        <div className="card">
          <h3>FastAPI Backend</h3>
          <p className="muted">
            A small backend service exposed at <strong>api.masoud-mh.com</strong> with health checks and CORS settings. Built as an
            artifact (Docker image) and deployed via an auditable workflow.
          </p>
          <div className="row">
            <span className="pill muted">FastAPI</span>
            <span className="pill muted">Python</span>
            <span className="pill muted">Docker</span>
          </div>
        </div>
      </div>
    </section>
  )
}