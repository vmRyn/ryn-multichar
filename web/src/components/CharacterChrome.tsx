import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'

interface CharacterChromeProps {
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

export function CharacterChrome({
  characterCount,
  slotLimit,
  logo,
  serverName,
  hidden = false,
}: CharacterChromeProps) {
  const { t } = useLocale()
  const brand = resolveServerBrand(serverName, t('brand'))

  return (
    <div className={cn('ryn-chrome', hidden && 'ryn-chrome--hidden')} data-animate="chrome">
      <div className="ryn-brand">
        {logo ? (
          <img src={logo} alt="" className="ryn-brand-logo" />
        ) : (
          <>
            <span className="ryn-brand-mark" aria-hidden>
              {brand.initial}
            </span>
            <span className="ryn-wordmark">{brand.name}</span>
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
