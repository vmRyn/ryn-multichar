import { Separator } from '@/components/ui/separator'

interface InfoRowProps {
  label: string
  value: string
  showSeparator?: boolean
}

export function InfoRow({ label, value, showSeparator = true }: InfoRowProps) {
  return (
    <>
      <div className="ryn-stat-row">
        <span className="ryn-stat-label">{label}</span>
        <span className="ryn-stat-value">{value}</span>
      </div>
      {showSeparator && <Separator className="opacity-40" />}
    </>
  )
}
