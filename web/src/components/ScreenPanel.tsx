import type { ReactNode } from 'react'
import { AnimatedPanel } from './AnimatedPanel'
import { cn } from '@/lib/utils'

interface ScreenPanelProps {
  children: ReactNode
  animationKey: string
  maxWidth?: 'md' | 'lg'
  className?: string
  bodyClassName?: string
  onBackdropClick?: () => void
}

export function ScreenPanel({
  children,
  animationKey,
  maxWidth = 'md',
  className,
  bodyClassName,
  onBackdropClick,
}: ScreenPanelProps) {
  return (
    <div className="absolute inset-0 z-30 flex items-center justify-center p-6 sm:p-8">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={onBackdropClick}
        aria-label="Close"
      />
      <AnimatedPanel
        className={cn('relative w-full', maxWidth === 'lg' ? 'max-w-lg' : 'max-w-md', className)}
        animationKey={animationKey}
      >
        <div className={cn('ryn-surface', bodyClassName)}>
          <div className="ryn-surface-inner">{children}</div>
        </div>
      </AnimatedPanel>
    </div>
  )
}
