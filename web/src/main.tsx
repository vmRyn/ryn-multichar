import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { ToastProvider } from '@/components/ui/toast'
import { TooltipProvider } from '@/components/ui/tooltip'
import { demoTheme } from '@/dev/demoData'
import { applyThemeToDocument } from '@/lib/applyTheme'
import { isDevMode } from '@/hooks/useNui'
import './index.css'

document.documentElement.classList.add('dark')

if (isDevMode() && demoTheme) {
  applyThemeToDocument(demoTheme)
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <TooltipProvider>
      <ToastProvider position="top-center">
        <App />
      </ToastProvider>
    </TooltipProvider>
  </React.StrictMode>,
)
