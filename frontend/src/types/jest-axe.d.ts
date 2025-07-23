declare module 'jest-axe' {
  export function axe(container: Element, options?: any): Promise<any>
  export const toHaveNoViolations: any
}
