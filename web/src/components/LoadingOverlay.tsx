import { useLocale } from '@/hooks/useLocale'

export function LoadingOverlay({ label }: { label: string }) {
  const { t } = useLocale()

  return (
    <div
      className="ryn-loading-overlay"
      role="status"
      aria-live="polite"
      aria-busy="true"
    >
      <div className="ryn-loading-overlay__card">
        <span className="ryn-loading-overlay__spinner" aria-hidden />
        <p className="ryn-loading-overlay__label">{label || t('loading')}</p>
      </div>
    </div>
  )
}
