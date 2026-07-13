import { Kbd, KbdGroup } from '@/components/ui/kbd'
import { useLocale } from '@/hooks/useLocale'

export function KeyboardHints() {
  const { t } = useLocale()

  return (
    <p className="ryn-hint">
      <KbdGroup>
        <Kbd>←</Kbd>
        <Kbd>→</Kbd>
      </KbdGroup>
      <span className="mx-1.5 text-muted-foreground/50">·</span>
      <span>{t('keyboardHints')}</span>
    </p>
  )
}
