import type { ReactNode } from 'react'
import { AnimatedPanel } from './AnimatedPanel'
import { cn } from '@/lib/utils'

interface RynModalProps {
  open: boolean
  onClose: () => void
  children: ReactNode
  animationKey?: string
  maxWidth?: string
}

export function RynModal({
  open,
  onClose,
  children,
  animationKey,
  maxWidth = 'max-w-md',
}: RynModalProps) {
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center px-6 pt-[8vh] pb-[min(40vh,360px)]">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={onClose}
        aria-label="Close"
      />
      <AnimatedPanel className={cn('relative w-full', maxWidth)} animationKey={animationKey ?? 'modal'}>
        <div className="ryn-panel">{children}</div>
      </AnimatedPanel>
    </div>
  )
}
