import { toastManager } from '@/components/ui/toast'
import { playUiSound } from '@/lib/sounds'

export function notifySuccess(title: string, description?: string) {
  toastManager.add({ type: 'success', title, description, timeout: 4000 })
}

export function notifyError(title: string, description?: string) {
  playUiSound('error')
  toastManager.add({ type: 'error', title, description, timeout: 5000 })
}

export function notifyInfo(title: string, description?: string) {
  toastManager.add({ type: 'info', title, description, timeout: 4000 })
}
