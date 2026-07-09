export function isDevMode(): boolean {
  return import.meta.env.DEV && typeof (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName !== 'function'
}
