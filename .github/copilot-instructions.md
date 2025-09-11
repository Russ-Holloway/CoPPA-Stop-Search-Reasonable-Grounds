# Copilot Instructions for CoPA Stop & Search Application

## General Development Guidelines

### Project Context
This is a police stop and search application built with Python Flask backend and TypeScript/React frontend. The application handles sensitive police data and must maintain strict accessibility and security standards.

### Code Style and Best Practices
- Follow TypeScript strict mode conventions
- Use semantic HTML elements for accessibility
- Implement WCAG 2.1 AA compliance standards
- Use CSS modules for component styling
- Prefer functional React components with hooks
- Follow Python PEP 8 standards for backend code
- Use absolute imports where possible
- Maintain separation of concerns between frontend and backend
- **Always prioritize code simplicity and readability over complexity**
- Review all code changes for unnecessary complexity and refactor to simpler solutions
- Prefer clear, self-documenting code over clever or overly abstracted solutions

### Tool Usage Guidelines
When helping with development tasks:
- **Always explore the codebase first** using `file_search`, `semantic_search`, or `grep_search` before making changes
- **Read existing files** to understand current patterns and architecture
- **Check for existing implementations** before creating new components or functions
- **Use `get_errors` tool** to identify and fix compilation or linting issues
- **Test changes thoroughly** and verify functionality before completion

### Project Structure Understanding
- **Frontend**: React/TypeScript application in `frontend/` directory
- **Backend**: Python Flask application in root and `backend/` directories  
- **Infrastructure**: Azure deployment configs in `infra/` and `infrastructure/` directories
- **Documentation**: Various `.md` files for setup, deployment, and guidelines
- **Key files**: `app.py` (main Flask app), `requirements.txt`, `package.json`
- **Search before creating**: Always check if similar functionality already exists

## CSS and Layout Best Practices

### CSS Architecture
- Use CSS modules (*.module.css) for component-specific styles
- Follow BEM methodology for CSS class naming when not using modules
- Use CSS custom properties (variables) for consistent theming
- Implement mobile-first responsive design approach
- Use flexbox and CSS Grid for modern layouts
- Avoid inline styles unless absolutely necessary for dynamic values

### Layout Instructions Implementation
When implementing layout changes:
1. **Analyze existing CSS structure** before making changes
2. **Use CSS Grid for 2D layouts** (rows and columns)
3. **Use Flexbox for 1D layouts** (single direction alignment)
4. **Implement responsive breakpoints** using mobile-first approach
5. **Maintain accessibility** with proper focus management and ARIA labels
6. **Test layout changes** across different viewport sizes
7. **Use CSS logical properties** (margin-inline, padding-block) for internationalization

### Responsive Design Standards
```css
/* Mobile-first breakpoints */
/* Mobile: 0-767px (default) */
/* Tablet: 768px-1023px */
@media (min-width: 768px) { }
/* Desktop: 1024px+ */
@media (min-width: 1024px) { }
/* Large Desktop: 1440px+ */
@media (min-width: 1440px) { }
```

### CSS Performance Guidelines
- Use efficient selectors (avoid deep nesting)
- Leverage CSS containment for performance isolation
- Use transform and opacity for animations
- Implement CSS loading strategies for critical vs non-critical styles
- Minimize layout thrashing with will-change property when appropriate

## Component-Specific Guidelines

### Answer Component Styling
The Answer component requires special attention to:
- **Full-width content**: Ensure all answer text spans the complete available width
- **Citation handling**: Disable interactive citation links while maintaining visual consistency
- **Accessibility**: Maintain proper heading hierarchy and screen reader compatibility
- **Layout flexibility**: Support both single-column and two-column layouts with citations

### Form Components
- Use consistent form field styling across the application
- Implement proper error state styling with ARIA live regions
- Ensure form labels are properly associated with inputs
- Use CSS Grid for complex form layouts

### Navigation Components
- Implement consistent focus indicators for keyboard navigation
- Use semantic navigation landmarks
- Ensure mobile navigation is touch-friendly (44px minimum touch targets)

## Accessibility Requirements

### WCAG 2.1 AA Compliance
- Maintain minimum 4.5:1 contrast ratio for normal text
- Maintain minimum 3:1 contrast ratio for large text and UI components
- Ensure all interactive elements are keyboard accessible
- Provide alternative text for images and icons
- Use semantic HTML elements appropriately
- Implement proper heading hierarchy (h1-h6)

### Focus Management
- Provide visible focus indicators for all interactive elements
- Implement logical tab order
- Use skip links for main content navigation
- Manage focus when showing/hiding content dynamically

## Microsoft Documentation Integration

### Reference Standards
- Follow Microsoft Fluent UI design principles: https://developer.microsoft.com/en-us/fluentui
- Use Microsoft's accessibility guidelines: https://docs.microsoft.com/en-us/accessibility/
- Reference Microsoft's CSS best practices: https://docs.microsoft.com/en-us/previous-versions/windows/apps/hh465498(v=win.10)
- Follow Microsoft's responsive design patterns: https://docs.microsoft.com/en-us/windows/apps/design/layout/

### API Integration Guidelines
- When working with Microsoft APIs, reference: https://learn.microsoft.com/api/mcp
- Use proper error handling for API responses
- Implement appropriate loading states for asynchronous operations
- Follow Microsoft's authentication patterns for secure API access

## File Organization

### CSS File Structure
```
frontend/src/
├── components/
│   ├── Answer/
│   │   ├── Answer.tsx
│   │   ├── Answer.module.css
│   │   └── index.ts
│   └── [ComponentName]/
│       ├── [ComponentName].tsx
│       ├── [ComponentName].module.css
│       └── index.ts
├── styles/
│   ├── globals.css
│   ├── variables.css
│   └── utilities.css
```

### Import Standards
- Use absolute imports for components: `@/components/Answer`
- Use relative imports for local files: `./Answer.module.css`
- Group imports: React imports first, then third-party, then local

## Security Considerations

### Data Protection and Privacy
- **Never log or expose sensitive police data** in console outputs, error messages, or debugging
- **Sanitize all user inputs** before processing or storing
- **Use environment variables** for all sensitive configuration (API keys, database credentials)
- **Implement proper data encryption** for sensitive data at rest and in transit
- **Follow data minimization principles** - only collect and store necessary data
- **Ensure secure session management** with proper timeout and invalidation

### CSS Security
- Avoid user-generated content in CSS values
- Sanitize any dynamic CSS content
- Use Content Security Policy (CSP) for style sources
- Avoid CSS injection vulnerabilities

### Data Handling
- Never expose sensitive police data in client-side code
- Use proper data validation on both frontend and backend
- Implement proper error handling without exposing system details
- **Use HTTPS for all data transmission**
- **Implement proper authentication and authorization checks**
- **Log security events appropriately** without exposing sensitive information

## Performance Guidelines

### CSS Performance
- Use CSS containment for component isolation
- Implement critical CSS loading for above-the-fold content
- Use CSS custom properties for theming instead of JavaScript
- Minimize reflows and repaints during layout changes

### Bundle Optimization
- Use CSS modules to enable tree shaking
- Implement code splitting for route-based components
- Optimize font loading with font-display: swap
- Use CSS Grid and Flexbox instead of JavaScript layout solutions

## Testing Requirements

### Code Quality Assurance
- **Run existing tests** before making changes to ensure baseline functionality
- **Write tests for new functionality** following existing test patterns
- **Use appropriate testing frameworks** (Jest for frontend, pytest for backend)
- **Test edge cases and error conditions** especially for data validation
- **Mock external dependencies** in tests to ensure reliable, fast execution

### CSS Testing
- Test layout changes across multiple browsers
- Verify responsive design at different viewport sizes
- Test with CSS disabled for accessibility
- Validate CSS with proper linting tools

### Accessibility Testing
- Test with screen readers (NVDA, JAWS, VoiceOver)
- Verify keyboard navigation functionality
- Test with high contrast mode enabled
- Validate color contrast ratios

### Backend Testing
- **Test API endpoints** with various input combinations
- **Verify database operations** don't compromise data integrity
- **Test authentication and authorization** flows thoroughly
- **Validate error handling** returns appropriate responses

## Change Implementation Strategy

### Code Simplicity Principles
- **Always choose the simplest solution that meets requirements**
- Remove unnecessary abstractions, complex patterns, or over-engineering
- Prefer explicit, readable code over implicit or "clever" solutions
- Refactor complex logic into smaller, focused functions
- Eliminate duplicate code through simple, clear abstractions
- Use standard patterns and conventions rather than custom solutions
- Write code that can be easily understood by other developers

### Implementation Workflow
1. **Explore existing codebase** using search tools to understand current patterns
2. **Identify reusable components** or patterns before creating new ones
3. **Follow established conventions** found in existing code
4. **Make minimal changes** that achieve the desired functionality
5. **Test thoroughly** including edge cases and accessibility
6. **Document decisions** when deviating from established patterns

### Making Layout Changes
1. **Analyze current CSS**: Understand existing layout structure
2. **Plan responsive behavior**: Consider all viewport sizes
3. **Implement progressively**: Start with mobile, enhance for larger screens
4. **Test thoroughly**: Verify across browsers and devices
5. **Document changes**: Update comments and documentation
6. **Review accessibility**: Ensure no accessibility regressions

### CSS Debugging
- Use browser DevTools for layout debugging
- Implement CSS Grid and Flexbox debugging
- Use accessibility auditing tools
- Validate HTML structure before CSS changes

## Error Handling

### CSS Fallbacks
- Provide fallbacks for newer CSS features
- Use feature queries (@supports) for progressive enhancement
- Implement graceful degradation for older browsers
- Test with CSS disabled

When receiving layout instructions, always:
1. Assess the current CSS structure
2. Implement changes using modern CSS best practices
3. Ensure responsive behavior across all breakpoints
4. Maintain accessibility standards
5. Test the implementation thoroughly
6. Document any complex layout decisions
