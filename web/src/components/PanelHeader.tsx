import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface PanelHeaderProps {
  eyebrow?: string
  title: string
  subtitle?: ReactNode
  className?: string
  eyebrowClassName?: string
  titleId?: string
}

export function PanelHeader({
  eyebrow,
  title,
  subtitle,
  className,
  eyebrowClassName,
  titleId,
}: PanelHeaderProps) {
  return (
    <header className={cn('mb-6', className)}>
      {eyebrow && (
        <p className={cn('ryn-eyebrow', eyebrowClassName)}>{eyebrow}</p>
      )}
      <h2 id={titleId} className="ryn-title">
        {title}
      </h2>
      {subtitle && <p className="ryn-subtitle">{subtitle}</p>}
    </header>
  )
}
