import type { Config } from '@jest/types'

const config: Config.InitialOptions = {
  verbose: true,
  testEnvironment: 'jsdom',
  transform: {
    '^.+\\.tsx?$': 'ts-jest'
  },
  setupFilesAfterEnv: ['<rootDir>/polyfills.js', '<rootDir>/src/jest-setup.ts'],
  moduleNameMapper: {
    '\\.(css|less|scss|sass)$': 'identity-obj-proxy',
    '^react-markdown$': '<rootDir>/src/__mocks__/react-markdown.tsx',
    '^react-syntax-highlighter$': '<rootDir>/src/__mocks__/react-syntax-highlighter.tsx',
    '^react-syntax-highlighter/dist/esm/styles/prism$': '<rootDir>/src/__mocks__/syntax-highlighter-styles.ts',
    '^remark-gfm$': '<rootDir>/src/__mocks__/remark-plugins.ts',
    '^rehype-raw$': '<rootDir>/src/__mocks__/remark-plugins.ts',
    '^remark-supersub$': '<rootDir>/src/__mocks__/remark-plugins.ts'
  },
  transformIgnorePatterns: [
    'node_modules/(?!(react-syntax-highlighter|react-markdown|remark-.*|rehype-.*|unified|bail|is-plain-obj|trough|vfile)/)'
  ]
}

export default config
