import { useEffect, useRef } from 'react'
import { animatePanelIn } from '@/lib/animations'

interface AnimatedPanelProps {
  children: React.ReactNode
  className?: string
  animationKey?: string | number
}

export function AnimatedPanel({ children, className, animationKey }: AnimatedPanelProps) {
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!ref.current) return
    animatePanelIn(ref.current)
  }, [animationKey])

  return (
    <div ref={ref} className={className}>
      {children}
    </div>
  )
}
