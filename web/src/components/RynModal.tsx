import type { ReactNode } from 'react'
import { AnimatedPanel } from './AnimatedPanel'
import { cn } from '@/lib/utils'

interface RynModalProps {
  open: boolean
  onClose: () => void
  children: ReactNode
  animationKey?: string
  maxWidth?: string
  tone?: 'default' | 'danger'
}

export function RynModal({
  open,
  onClose,
  children,
  animationKey,
  maxWidth = 'max-w-md',
  tone = 'default',
}: RynModalProps) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={onClose}
        aria-label="Close"
      />
      <AnimatedPanel className={cn('relative w-full', maxWidth)} animationKey={animationKey ?? 'modal'}>
        <div className={cn('ryn-panel', tone === 'danger' && 'ryn-panel--danger')}>{children}</div>
      </AnimatedPanel>
    </div>
  )
}
