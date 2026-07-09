import { createContext, useContext, useMemo, createElement, type ReactNode } from 'react'
import en from '@/locales/en.json'
import es from '@/locales/es.json'

type LocaleKey = keyof typeof en
export type LocaleCode = keyof typeof locales

const locales = { en, es } as const

const LocaleContext = createContext<LocaleCode>('en')

function interpolate(template: string, vars?: Record<string, string | number>) {
  if (!vars) return template
  return template.replace(/\{(\w+)\}/g, (_, key: string) => String(vars[key] ?? `{${key}}`))
}

export function LocaleProvider({
  locale,
  children,
}: {
  locale: LocaleCode
  children: ReactNode
}) {
  return createElement(LocaleContext.Provider, { value: locale }, children)
}

export function useLocale() {
  const locale = useContext(LocaleContext)

  return useMemo(() => {
    const dict = locales[locale] ?? en
    return {
      locale,
      t: (key: LocaleKey, vars?: Record<string, string | number>) =>
        interpolate(dict[key] ?? en[key] ?? key, vars),
    }
  }, [locale])
}
