import React from 'react'

interface SyntaxHighlighterProps {
  children: string
  style?: any
  language?: string
  PreTag?: string
  className?: string
}

const SyntaxHighlighter: React.FC<SyntaxHighlighterProps> = ({ children, className, language }) => {
  return (
    <pre className={className} data-testid="syntax-highlighter" data-language={language}>
      <code>{children}</code>
    </pre>
  )
}

export { SyntaxHighlighter as Prism }