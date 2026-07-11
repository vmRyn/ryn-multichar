import type { Character } from '@/types'
import { getFullName } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { Button } from '@/components/ui/button'
import { Field, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Trash2Icon, XIcon } from 'lucide-react'

interface DeleteCharacterModalProps {
  character: Character
  confirmName: string
  onConfirmNameChange: (value: string) => void
  onConfirm: () => void
  onClose: () => void
}

function initials(character: Character) {
  const first = character.charinfo.firstname?.[0] ?? ''
  const last = character.charinfo.lastname?.[0] ?? ''
  return `${first}${last}`.toUpperCase() || '?'
}

export function DeleteCharacterModal({
  character,
  confirmName,
  onConfirmNameChange,
  onConfirm,
  onClose,
}: DeleteCharacterModalProps) {
  const { t } = useLocale()
  const fullName = getFullName(character.charinfo)
  const canDelete = confirmName.trim() === fullName

  return (
    <div className="ryn-modal-body">
      <div className="ryn-side-panel__heading">
        <span className="ryn-side-panel__icon ryn-side-panel__icon--danger" aria-hidden>
          <Trash2Icon className="size-3.5" strokeWidth={2.25} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="ryn-side-panel__title">{t('confirmDeletion')}</p>
          <p className="ryn-side-panel__hint">{t('deleteModalHint')}</p>
        </div>
        <button type="button" className="ryn-modal-close" onClick={onClose} aria-label={t('close')}>
          <XIcon className="size-4" />
        </button>
      </div>

      <div className="ryn-modal-identity ryn-modal-identity--danger">
        <span className="ryn-avatar ryn-avatar--lg ryn-avatar--danger" aria-hidden>
          {initials(character)}
        </span>
        <div className="min-w-0">
          <h2 className="ryn-info-identity__name">{fullName}</h2>
          <p className="ryn-info-identity__meta">{character.citizenid}</p>
        </div>
      </div>

      <p className="ryn-modal-warning">
        {t('deleteDescription', { name: fullName })}
      </p>

      <Field>
        <FieldLabel className="ryn-field-label">{t('characterName')}</FieldLabel>
        <Input
          value={confirmName}
          onChange={(e) => onConfirmNameChange(e.target.value)}
          placeholder={fullName}
          autoComplete="off"
        />
      </Field>

      <div className="ryn-modal-actions">
        <Button size="lg" variant="destructive" disabled={!canDelete} onClick={onConfirm}>
          <Trash2Icon className="size-4" />
          {t('deleteForever')}
        </Button>
        <Button size="lg" variant="outline" onClick={onClose}>
          {t('cancel')}
        </Button>
      </div>
    </div>
  )
}
