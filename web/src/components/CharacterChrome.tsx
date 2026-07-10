import { useLocale } from '@/hooks/useLocale'

import { cn } from '@/lib/utils'

interface CharacterChromeProps {
  characterCount: number
  slotLimit: number
  logo?: string
  hidden?: boolean
}

export function CharacterChrome({ characterCount, slotLimit, logo, hidden = false }: CharacterChromeProps) {
  const { t } = useLocale()

  return (
    <div className={cn('ryn-chrome', hidden && 'ryn-chrome--hidden')} data-animate="chrome">
      <div className="ryn-brand">
        {logo ? (
          <img src={logo} alt="" className="ryn-brand-logo" />
        ) : (
          <>
            <span className="ryn-brand-mark" aria-hidden>R</span>
            <span className="ryn-wordmark">{t('brand')}</span>
          </>
        )}
      </div>
      <div className="ryn-meta" aria-label={t('slotsMeta', { count: characterCount, limit: slotLimit })}>
        <strong>{characterCount}</strong>
        <span>/</span>
        <span>{slotLimit}</span>
      </div>
    </div>
  )
}
