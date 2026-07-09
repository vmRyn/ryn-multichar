import { useEffect, useRef } from 'react'
import { createScope } from 'animejs'

export function useAnimeScope<T extends HTMLElement = HTMLDivElement>() {
  const rootRef = useRef<T>(null)
  const scopeRef = useRef<ReturnType<typeof createScope> | null>(null)

  useEffect(() => {
    const root = rootRef.current
    if (!root) return

    scopeRef.current = createScope({ root })

    return () => {
      scopeRef.current?.revert()
      scopeRef.current = null
    }
  }, [])

  return { rootRef, scopeRef }
}
