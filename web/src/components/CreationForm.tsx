import { useCallback, useEffect, useMemo, useState } from 'react'
import type { CreationField } from '@/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Field, FieldLabel } from '@/components/ui/field'
import {
  Select,
  SelectItem,
  SelectPopup,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Autocomplete,
  AutocompleteEmpty,
  AutocompleteInput,
  AutocompleteItem,
  AutocompleteList,
  AutocompletePopup,
} from '@/components/ui/autocomplete'
import { ScreenPanel } from './ScreenPanel'
import { PanelHeader } from './PanelHeader'
import { useLocale } from '@/hooks/useLocale'

interface CreationFormProps {
  slotIndex: number
  fields: CreationField[]
  onSubmit: (data: Record<string, string>) => Promise<void>
  onCancel: () => void
}

function validateFields(
  fields: CreationField[],
  formData: Record<string, string>,
): Record<string, string> {
  const errors: Record<string, string> = {}
  for (const field of fields) {
    if (field.required && !formData[field.name]?.trim()) {
      errors[field.name] = 'required'
    }
  }
  return errors
}

function formatOptionLabel(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1)
}

function getInitialFormData(fields: CreationField[]): Record<string, string> {
  const initial: Record<string, string> = {}
  for (const field of fields) {
    if (field.name === 'nationality') {
      const firstOption = field.options?.[0]
      if (firstOption) initial[field.name] = firstOption
    }
  }
  return initial
}

function isFormDirty(fields: CreationField[], formData: Record<string, string>) {
  const initial = getInitialFormData(fields)
  for (const field of fields) {
    const current = (formData[field.name] ?? '').trim()
    const baseline = (initial[field.name] ?? '').trim()
    if (current !== baseline) return true
  }
  return false
}

export function CreationForm({ slotIndex, fields, onSubmit, onCancel }: CreationFormProps) {
  const { t } = useLocale()
  const [formData, setFormData] = useState<Record<string, string>>(() => getInitialFormData(fields))
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [touched, setTouched] = useState<Record<string, boolean>>({})
  const [submitting, setSubmitting] = useState(false)
  const [confirmDiscard, setConfirmDiscard] = useState(false)

  const isValid = useMemo(
    () => Object.keys(validateFields(fields, formData)).length === 0,
    [fields, formData],
  )

  const dirty = useMemo(() => isFormDirty(fields, formData), [fields, formData])
  const slotLabel = String(slotIndex).padStart(2, '0')

  const markTouched = (name: string) => {
    setTouched((prev) => ({ ...prev, [name]: true }))
  }

  const requestCancel = useCallback(() => {
    if (submitting) return
    if (dirty) {
      setConfirmDiscard(true)
      return
    }
    onCancel()
  }, [dirty, onCancel, submitting])

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return
      event.preventDefault()
      if (confirmDiscard) {
        setConfirmDiscard(false)
        return
      }
      requestCancel()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [confirmDiscard, requestCancel])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    const nextErrors = validateFields(fields, formData)
    setErrors(nextErrors)
    setTouched(Object.fromEntries(fields.map((field) => [field.name, true])))
    if (Object.keys(nextErrors).length > 0) return

    setSubmitting(true)
    try {
      await onSubmit(formData)
    } finally {
      setSubmitting(false)
    }
  }

  const updateField = useCallback((name: string, value: string) => {
    setFormData((prev) => {
      const next = { ...prev, [name]: value }
      setErrors(validateFields(fields, next))
      return next
    })
  }, [fields])

  const renderFieldControl = (field: CreationField, showError: boolean) => {
    if (field.type === 'select') {
      return (
        <Select
          value={formData[field.name] ?? ''}
          onValueChange={(value) => {
            updateField(field.name, value ?? '')
            markTouched(field.name)
          }}
        >
          <SelectTrigger aria-invalid={!!showError} className="w-full">
            <SelectValue placeholder={t('selectPlaceholder')} />
          </SelectTrigger>
          <SelectPopup>
            {field.options?.map((opt) => (
              <SelectItem key={opt} value={opt}>
                {formatOptionLabel(opt)}
              </SelectItem>
            ))}
          </SelectPopup>
        </Select>
      )
    }

    if (field.type === 'autocomplete') {
      const options = field.options ?? []
      const value = formData[field.name] ?? null

      return (
        <Autocomplete
          items={options}
          value={value}
          onValueChange={(next) => {
            updateField(field.name, next ?? '')
            markTouched(field.name)
          }}
        >
          <AutocompleteInput
            showTrigger
            placeholder={t('searchNationality')}
            aria-invalid={!!showError}
            onBlur={() => markTouched(field.name)}
          />
          <AutocompletePopup>
            <AutocompleteList>
              {(item: string) => (
                <AutocompleteItem key={item} value={item}>
                  {item}
                </AutocompleteItem>
              )}
            </AutocompleteList>
            <AutocompleteEmpty>{t('noNationalityResults')}</AutocompleteEmpty>
          </AutocompletePopup>
        </Autocomplete>
      )
    }

    return (
      <Input
        type={field.type}
        placeholder={field.label}
        value={formData[field.name] ?? ''}
        aria-invalid={!!showError}
        onBlur={() => markTouched(field.name)}
        onChange={(e) => updateField(field.name, e.target.value)}
      />
    )
  }

  const renderField = (field: CreationField) => {
    const showError = touched[field.name] && errors[field.name]
    return (
      <Field key={field.name} className="ryn-form-field">
        <FieldLabel className="ryn-field-label">
          {field.label}
          {field.required && <span className="text-destructive"> *</span>}
        </FieldLabel>
        {renderFieldControl(field, !!showError)}
        {showError && (
          <p className="mt-1 text-xs text-destructive">
            {t('fieldRequired', { field: field.label })}
          </p>
        )}
      </Field>
    )
  }

  const nameFields = fields.filter((f) => f.name === 'firstname' || f.name === 'lastname')
  const detailFields = fields.filter((f) => f.name !== 'firstname' && f.name !== 'lastname')
  const hasNamePair = nameFields.length === 2

  return (
    <ScreenPanel animationKey="creation" onBackdropClick={requestCancel} labelledBy="ryn-create-title">
      {confirmDiscard ? (
        <div className="ryn-flow-form">
          <PanelHeader
            title={t('discardChanges')}
            subtitle={t('discardChangesDesc')}
            className="mb-5"
          />
          <div className="ryn-screen-footer">
            <Button
              className="flex-1"
              size="lg"
              variant="destructive"
              type="button"
              onClick={onCancel}
            >
              {t('discardConfirm')}
            </Button>
            <Button
              size="lg"
              variant="outline"
              type="button"
              onClick={() => setConfirmDiscard(false)}
            >
              {t('keepEditing')}
            </Button>
          </div>
        </div>
      ) : (
        <form onSubmit={handleSubmit} noValidate className="ryn-flow-form">
          <PanelHeader
            eyebrow={t('createSlotMeta', { slot: slotLabel })}
            title={t('createIdentity')}
            subtitle={t('createSubtitle')}
            className="mb-5"
            titleId="ryn-create-title"
          />

          {hasNamePair ? (
            <>
              <p className="ryn-form-section">{t('createSectionIdentity')}</p>
              <div className="ryn-form-grid mb-4">
                {nameFields.map((field) => renderField(field))}
              </div>
              {detailFields.length > 0 && (
                <>
                  <p className="ryn-form-section">{t('createSectionDetails')}</p>
                  <div className="flex flex-col gap-4">{detailFields.map((field) => renderField(field))}</div>
                </>
              )}
            </>
          ) : (
            <div className="flex flex-col gap-4">{fields.map((field) => renderField(field))}</div>
          )}

          <div className="ryn-screen-footer">
            <Button className="ryn-btn-play flex-1" size="lg" type="submit" disabled={!isValid || submitting}>
              {submitting ? t('creating') : t('create')}
            </Button>
            <Button size="lg" variant="outline" type="button" onClick={requestCancel} disabled={submitting}>
              {t('cancel')}
            </Button>
          </div>
        </form>
      )}
    </ScreenPanel>
  )
}
