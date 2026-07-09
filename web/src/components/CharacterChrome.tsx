import { useLocale } from '@/hooks/useLocale'

interface CharacterChromeProps {
  characterCount: number
  slotLimit: number
  logo?: string
}

export function CharacterChrome({ characterCount, slotLimit, logo }: CharacterChromeProps) {
  const { t } = useLocale()

  return (
    <div className="ryn-chrome" data-animate="chrome">
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
