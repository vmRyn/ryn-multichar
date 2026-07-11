/** Curated urban / night city photos for browser NUI preview (Unsplash). */
export const CITY_BACKGROUNDS = [
  'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1519501025264-65ba15a82390?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1467269578790-b014bcb3f5a8?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=1920&q=80',
  'https://images.unsplash.com/photo-1444723121867-7a241cacace9?auto=format&fit=crop&w=1920&q=80',
] as const

export function pickRandomCityBackground(): string {
  const index = Math.floor(Math.random() * CITY_BACKGROUNDS.length)
  return CITY_BACKGROUNDS[index]!
}
