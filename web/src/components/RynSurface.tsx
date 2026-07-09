import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface RynSurfaceProps {
  children: ReactNode
  className?: string
  innerClassName?: string
  compact?: boolean
}

/** Dark glass surface — AAA NUI tokens */
export function RynSurface({ children, className, innerClassName, compact }: RynSurfaceProps) {
  return (
    <div className={cn('ryn-surface', className)}>
      <div className={cn('ryn-surface-inner', compact && 'ryn-surface-inner--compact', innerClassName)}>
        {children}
      </div>
    </div>
  )
}
