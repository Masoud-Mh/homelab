import { AppShell } from './components/AppShell'
import { HeroSection } from './components/HeroSection'
import { ProjectsSection } from './components/ProjectsSection'
import { SkillsSection } from './components/SkillsSection'
import { AboutSection } from './components/AboutSection'
import { ContactSection } from './components/ContactSection'

function App() {
  return (
    <AppShell>
      <HeroSection />
      <ProjectsSection />
      <SkillsSection />
      <AboutSection />
      <ContactSection />
    </AppShell>
  )
}

export default App