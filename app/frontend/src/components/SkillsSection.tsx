export function SkillsSection() {
  return (
    <section id="skills" className="section">
      <h2>Skills & Focus</h2>
      <div className="grid">
        <div className="card">
          <h3>Backend Engineering</h3>
          <p className="muted">
            Designing and building backend services with clear APIs, health checks, and predictable deployments. Focus on correctness,
            observability, and maintainability.
          </p>
          <div className="row">
            <span className="pill muted">Python</span>
            <span className="pill muted">FastAPI</span>
            <span className="pill muted">REST APIs</span>
            <span className="pill muted">Docker</span>
          </div>
        </div>

        <div className="card">
          <h3>Platform & Infrastructure</h3>
          <p className="muted">
            Running production-style infrastructure on constrained environments. Emphasis on security, reproducibility, and
            understanding trade-offs.
          </p>
          <div className="row">
            <span className="pill muted">Docker Compose</span>
            <span className="pill muted">Traefik</span>
            <span className="pill muted">Cloudflare Tunnel</span>
            <span className="pill muted">Linux</span>
          </div>
        </div>

        <div className="card">
          <h3>CI/CD & Automation</h3>
          <p className="muted">
            Building simple, auditable CI/CD pipelines that deploy immutable artifacts. Avoiding over-engineering while keeping
            production guarantees.
          </p>
          <div className="row">
            <span className="pill muted">GitHub Actions</span>
            <span className="pill muted">GHCR</span>
            <span className="pill muted">Tag-based deploys</span>
          </div>
        </div>

        <div className="card">
          <h3>Problem Solving</h3>
          <p className="muted">
            Background in electrical engineering and research. Comfortable reasoning across software, systems, and constraints.
          </p>
          <div className="row">
            <span className="pill muted">System thinking</span>
            <span className="pill muted">Debugging</span>
            <span className="pill muted">Trade-offs</span>
          </div>
        </div>
      </div>
    </section>
  )
}