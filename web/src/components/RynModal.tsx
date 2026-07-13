import type { ReactNode } from 'react'
import { useEffect, useRef } from 'react'
import { AnimatedPanel } from './AnimatedPanel'
import { cn } from '@/lib/utils'
import { useLocale } from '@/hooks/useLocale'

const FOCUSABLE =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'

interface RynModalProps {
  open: boolean
  onClose: () => void
  children: ReactNode
  animationKey?: string
  maxWidth?: string
  tone?: 'default' | 'danger'
  labelledBy?: string
}

export function RynModal({
  open,
  onClose,
  children,
  animationKey,
  maxWidth = 'max-w-md',
  tone = 'default',
  labelledBy,
}: RynModalProps) {
  const { t } = useLocale()
  const panelRef = useRef<HTMLDivElement>(null)
  const previouslyFocused = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (!open) return

    previouslyFocused.current = document.activeElement as HTMLElement | null
    const panel = panelRef.current
    if (!panel) return

    const focusables = () =>
      Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE)).filter(
        (el) => !el.hasAttribute('disabled') && el.getAttribute('aria-hidden') !== 'true',
      )

    const initial = focusables()[0]
    initial?.focus()

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Tab') return
      const items = focusables()
      if (items.length === 0) return
      const first = items[0]
      const last = items[items.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first.focus()
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => {
      window.removeEventListener('keydown', onKeyDown)
      previouslyFocused.current?.focus?.()
    }
  }, [open])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={onClose}
        aria-label={t('close')}
        tabIndex={-1}
      />
      <AnimatedPanel className={cn('relative w-full', maxWidth)} animationKey={animationKey ?? 'modal'}>
        <div
          ref={panelRef}
          role="dialog"
          aria-modal="true"
          aria-labelledby={labelledBy}
          className={cn('ryn-panel', tone === 'danger' && 'ryn-panel--danger')}
        >
          {children}
        </div>
      </AnimatedPanel>
    </div>
  )
}
