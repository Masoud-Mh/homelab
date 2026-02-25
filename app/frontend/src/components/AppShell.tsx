import type { PropsWithChildren } from 'react'

export function AppShell({ children }: PropsWithChildren) {
  return (
    <div className="wrap">
      <header className="nav">
        <div className="row">
          <strong>Masoud</strong>
          <span className="muted">Backend / Platform</span>
        </div>
        <nav className="row">
          <a href="#projects">Projects</a>
          <a href="#skills">Skills</a>
          <a href="#about">About</a>
          <a href="#contact">Contact</a>
          <a className="pill" href="https://github.com/Masoud-Mh" target="_blank" rel="noreferrer">
            GitHub
          </a>
        </nav>
      </header>

      <main>
        {children}
        <footer className="footer">© {new Date().getFullYear()} Masoud — Built on a homelab. Deployed with GitHub Actions.</footer>
      </main>
    </div>
  )
}