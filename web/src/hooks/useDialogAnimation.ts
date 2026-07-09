import { useEffect, useRef } from 'react'
import { animatePanelIn } from '@/lib/animations'

export function useDialogAnimation(open: boolean) {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open || !ref.current) return
    animatePanelIn(ref.current)
  }, [open])

  return ref
}
