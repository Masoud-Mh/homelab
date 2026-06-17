import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'

import { AboutSection } from '../AboutSection'

describe('AboutSection', () => {
  it('renders the About heading and intro copy', () => {
    render(<AboutSection />)
    expect(screen.getByRole('heading', { name: 'About' })).toBeTruthy()
    expect(screen.getByText(/electrical engineering/i)).toBeTruthy()
  })
})
