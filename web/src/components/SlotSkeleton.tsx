import { Skeleton } from '@/components/ui/skeleton'

export function SlotSkeleton() {
  return (
    <div className="ryn-slot-skeleton flex flex-col justify-center gap-2 p-4" aria-hidden="true">
      <Skeleton className="h-2 w-10" />
      <Skeleton className="h-2.5 w-24" />
      <Skeleton className="h-2 w-16" />
    </div>
  )
}
