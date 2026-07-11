import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'

interface SelectHeaderProps {
  characterCount: number
  slotLimit: number
  logo?: string
  serverName?: string
  hidden?: boolean
}

function resolveServerBrand(serverName?: string, fallback = 'RYN') {
  const name = (serverName ?? '').trim() || fallback
  return {
    name,
    initial: name.charAt(0).toUpperCase(),
  }
}

export function SelectHeader({
  characterCount,
  slotLimit,
  logo,
  serverName,
  hidden = false,
}: SelectHeaderProps) {
  const { t } = useLocale()
  const brand = resolveServerBrand(serverName, t('brand'))

  return (
    <header className={cn('ryn-select-header', hidden && 'ryn-select-header--hidden')} data-animate="chrome">
      <div className="ryn-select-header__brand">
        {logo ? (
          <img src={logo} alt="" className="ryn-brand-logo" />
        ) : (
          <span className="ryn-brand-mark" aria-hidden>
            {brand.initial}
          </span>
        )}
        <span className="ryn-wordmark">{brand.name}</span>
      </div>

      <div className="ryn-select-header__center">
        <h1 className="ryn-select-header__title">{t('multicharacter')}</h1>
        <p className="ryn-select-header__subtitle">{t('selectCharacter')}</p>
        <div className="ryn-select-header__rule" aria-hidden>
          <span className="ryn-select-header__rule-line" />
          <span className="ryn-select-header__rule-mark" />
          <span className="ryn-select-header__rule-line" />
        </div>
      </div>

      <div
        className="ryn-meta"
        aria-label={t('slotsMeta', { count: characterCount, limit: slotLimit })}
      >
        <strong>{characterCount}</strong>
        <span>/</span>
        <span>{slotLimit}</span>
      </div>
    </header>
  )
}
