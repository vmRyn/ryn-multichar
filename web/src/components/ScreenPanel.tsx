import type { ReactNode } from 'react'
import { useEffect, useRef } from 'react'
import { AnimatedPanel } from './AnimatedPanel'
import { cn } from '@/lib/utils'
import { useLocale } from '@/hooks/useLocale'

const FOCUSABLE =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'

interface ScreenPanelProps {
  children: ReactNode
  animationKey: string
  maxWidth?: 'md' | 'lg'
  className?: string
  bodyClassName?: string
  onBackdropClick?: () => void
  labelledBy?: string
}

export function ScreenPanel({
  children,
  animationKey,
  maxWidth = 'md',
  className,
  bodyClassName,
  onBackdropClick,
  labelledBy,
}: ScreenPanelProps) {
  const { t } = useLocale()
  const panelRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const panel = panelRef.current
    if (!panel) return

    const focusables = () =>
      Array.from(panel.querySelectorAll<HTMLElement>(FOCUSABLE)).filter(
        (el) => !el.hasAttribute('disabled') && el.getAttribute('aria-hidden') !== 'true',
      )

    const initial = focusables().find((el) => el.tagName === 'INPUT') ?? focusables()[0]
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
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [])

  return (
    <div className="absolute inset-0 z-30 flex items-center justify-center p-6 sm:p-8">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={onBackdropClick}
        aria-label={t('close')}
        tabIndex={-1}
      />
      <AnimatedPanel
        className={cn('relative w-full', maxWidth === 'lg' ? 'max-w-lg' : 'max-w-md', className)}
        animationKey={animationKey}
      >
        <div
          ref={panelRef}
          role="dialog"
          aria-modal="true"
          aria-labelledby={labelledBy}
          className={cn('ryn-surface', bodyClassName)}
        >
          <div className="ryn-surface-inner">{children}</div>
        </div>
      </AnimatedPanel>
    </div>
  )
}
