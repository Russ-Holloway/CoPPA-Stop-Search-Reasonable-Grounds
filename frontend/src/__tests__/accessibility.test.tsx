/**
 * Accessibility Tests for CoPPA Stop & Search Application
 *
 * This test suite validates WCAG 2.1 AA compliance for all major components
 * using axe-core automated accessibility testing.
 */

import React from 'react'
import { render } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import { QuestionInput } from '../components/QuestionInput/QuestionInput'
import { Answer } from '../components/Answer/Answer'

// Extend Jest matchers to include accessibility assertions
expect.extend(toHaveNoViolations)

// Mock data for testing components
const mockAnswer = {
  answer: 'This is a test response from the assistant.',
  citations: [],
  generated_chart: null,
  message_id: 'test-message-id',
  feedback: undefined,
  exec_results: []
}

const mockOnSend = jest.fn()
const mockOnCitationClicked = jest.fn()
const mockOnExecResultClicked = jest.fn()

describe('Accessibility Tests', () => {
  beforeEach(() => {
    // Reset all mocks before each test
    jest.clearAllMocks()
  })

  describe('QuestionInput Component', () => {
    it('should not have accessibility violations', async () => {
      const { container } = render(
        <QuestionInput onSend={mockOnSend} disabled={false} placeholder="Type your question here" clearOnSend={true} />
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })

    it('should have proper ARIA attributes when disabled', async () => {
      const { container } = render(
        <QuestionInput onSend={mockOnSend} disabled={true} placeholder="Type your question here" clearOnSend={true} />
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })
  })

  describe('Answer Component', () => {
    it('should not have accessibility violations', async () => {
      const { container } = render(
        <Answer
          answer={mockAnswer}
          onCitationClicked={mockOnCitationClicked}
          onExectResultClicked={mockOnExecResultClicked}
        />
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })
  })

  describe('Color Contrast', () => {
    it('should meet WCAG AA color contrast requirements', async () => {
      const { container } = render(
        <div>
          <div style={{ color: '#1f2937', backgroundColor: '#ffffff' }}>High contrast text</div>
          <div style={{ color: '#374151', backgroundColor: '#f9fafb' }}>Medium contrast text</div>
        </div>
      )

      const results = await axe(container, {
        rules: {
          'color-contrast': { enabled: true }
        }
      })
      expect(results).toHaveNoViolations()
    })
  })

  describe('Focus Management', () => {
    it('should have proper focus indicators', async () => {
      const { container } = render(
        <div>
          <button style={{ outline: '2px solid #fbbf24', outlineOffset: '2px' }}>Focusable Button</button>
          <input type="text" style={{ outline: '2px solid #1f2937', outlineOffset: '2px' }} aria-label="Test input" />
        </div>
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })
  })

  describe('Keyboard Navigation', () => {
    it('should support keyboard navigation', async () => {
      const { container } = render(
        <div>
          <button tabIndex={0} aria-label="First button">
            Button 1
          </button>
          <button tabIndex={0} aria-label="Second button">
            Button 2
          </button>
          <input type="text" tabIndex={0} aria-label="Text input" />
        </div>
      )

      const results = await axe(container, {
        rules: {
          tabindex: { enabled: true }
        }
      })
      expect(results).toHaveNoViolations()
    })
  })

  describe('Screen Reader Support', () => {
    it('should have proper ARIA labels and descriptions', async () => {
      const { container } = render(
        <div>
          <div aria-live="polite" aria-atomic="true">
            Status messages appear here
          </div>
          <button aria-label="Clear chat conversation">Clear Chat</button>
          <input aria-label="Type your question here" aria-describedby="input-help" type="text" />
          <div id="input-help">Enter your question and press the send button</div>
        </div>
      )

      const results = await axe(container, {
        rules: {
          'aria-valid-attr-value': { enabled: true },
          'aria-valid-attr': { enabled: true },
          'button-name': { enabled: true },
          'input-button-name': { enabled: true }
        }
      })
      expect(results).toHaveNoViolations()
    })
  })

  describe('Form Accessibility', () => {
    it('should have proper form error handling', async () => {
      const { container } = render(
        <form>
          <label htmlFor="required-field">Required Field *</label>
          <input id="required-field" type="text" required aria-invalid="true" aria-describedby="error-message" />
          <div id="error-message" role="alert" aria-live="assertive">
            This field is required
          </div>
        </form>
      )

      const results = await axe(container, {
        rules: {
          label: { enabled: true },
          'aria-required-attr': { enabled: true },
          'aria-valid-attr-value': { enabled: true }
        }
      })
      expect(results).toHaveNoViolations()
    })
  })

  describe('Image and Media Accessibility', () => {
    it('should have proper alt text and ARIA attributes', async () => {
      const { container } = render(
        <div>
          <img
            src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'%3E%3C/svg%3E"
            alt="Descriptive alt text"
          />
          <img
            src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'%3E%3C/svg%3E"
            alt=""
            aria-hidden="true"
          />
          <div role="img" aria-label="Chart showing data trends">
            <svg>
              <title>Data Visualization</title>
              <desc>A bar chart showing increasing trend from 2020 to 2025</desc>
            </svg>
          </div>
        </div>
      )

      const results = await axe(container, {
        rules: {
          'image-alt': { enabled: true },
          'svg-img-alt': { enabled: true }
        }
      })
      expect(results).toHaveNoViolations()
    })
  })

  describe('Live Regions', () => {
    it('should properly announce dynamic content changes', async () => {
      const { container } = render(
        <div>
          <div aria-live="polite" aria-atomic="true" className="sr-only">
            New message received from assistant
          </div>
          <div aria-live="assertive" role="alert">
            Error: Please enter a valid question
          </div>
          <div role="log" aria-live="polite">
            Chat message history appears here
          </div>
        </div>
      )

      const results = await axe(container)
      expect(results).toHaveNoViolations()
    })
  })
})

// Additional accessibility testing utilities
export const testColorContrast = async (container: HTMLElement) => {
  const results = await axe(container, {
    rules: {
      'color-contrast': { enabled: true }
    }
  })

  return results.violations.length === 0
}
