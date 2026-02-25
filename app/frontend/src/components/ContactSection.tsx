export function ContactSection() {
  return (
    <section id="contact" className="section">
      <h2>Contact</h2>
      <div className="row">
        <a className="pill" href="mailto:masoud.mohtadifar@gmail.com">
          Email
        </a>
        <a className="pill" href="https://github.com/Masoud-Mh" target="_blank" rel="noreferrer">
          GitHub
        </a>
        <a className="pill" href="https://www.linkedin.com/in/masoud-mohtadifar-5b6b758a/" target="_blank" rel="noreferrer">
          LinkedIn
        </a>
      </div>
      <p className="muted contact-note">Prefer short messages: what you’re building, what you need, and a link.</p>
    </section>
  )
}