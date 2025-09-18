import React from 'react'

const ReactMarkdown: React.FC<{ children: string; className?: string }> = ({ children, className }) => {
  return <div className={className} data-testid="react-markdown">{children}</div>
}

export default ReactMarkdown