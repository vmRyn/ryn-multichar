import en from '@/locales/en.json'

export type LocaleKey = keyof typeof en

const SERVER_ERROR_MAP: Record<string, LocaleKey> = {
  no_framework: 'toastErrorNoFramework',
  create_failed: 'toastErrorCreate',
  slot_limit_reached: 'toastSlotLimit',
  slot_taken: 'toastSlotTaken',
  name_mismatch: 'toastDeleteNameMismatch',
  not_found: 'toastErrorNotFound',
  delete_failed: 'toastErrorDelete',
  no_license: 'toastErrorNoLicense',
  invalid_pose: 'toastError',
  disabled: 'toastError',
}

export function getErrorMessage(code: string | undefined, t: (key: LocaleKey) => string): string {
  if (!code) return t('toastErrorDesc')
  const key = SERVER_ERROR_MAP[code]
  return key ? t(key) : t('toastErrorDesc')
}

export function getErrorTitle(code: string | undefined, t: (key: LocaleKey) => string): string {
  if (code === 'slot_limit_reached') return t('toastSlotLimitTitle')
  if (code === 'name_mismatch') return t('toastDeleteNameMismatch')
  return t('toastError')
}
