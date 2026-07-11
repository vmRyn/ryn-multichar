import { toastManager } from '@/components/ui/toast'
import { playUiSound } from '@/lib/sounds'

const trackedToastIds = new Set<string>()

function track(id: string) {
  trackedToastIds.add(id)
  return id
}

/** Clear every toast — required before SetNuiFocus(false) (CEF freezes timers). */
export function dismissAllToasts() {
  for (const id of trackedToastIds) {
    toastManager.close(id)
  }
  trackedToastIds.clear()
  // Close any untracked toasts still in the provider.
  toastManager.close()
}

export function notifySuccess(title: string, description?: string) {
  return track(toastManager.add({ type: 'success', title, description, timeout: 4000 }))
}

export function notifyError(title: string, description?: string) {
  playUiSound('error')
  return track(toastManager.add({ type: 'error', title, description, timeout: 5000 }))
}

export function notifyInfo(title: string, description?: string) {
  return track(toastManager.add({ type: 'info', title, description, timeout: 4000 }))
}
