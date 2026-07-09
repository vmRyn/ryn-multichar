import type { Character, CreationField, SpawnLocation, UITheme } from '../types'
import { NATIONALITIES } from '../data/nationalities'

export const demoTheme: UITheme = {
  theme: 'royal-blue',
  locale: 'en',
  colors: {
    primary: '#2D7FF9',
    background: 'rgba(5, 8, 13, 0.92)',
    surface: 'rgba(15, 22, 32, 0.88)',
    border: 'rgba(45, 127, 249, 0.14)',
    text: '#F0F4FA',
    textMuted: '#6B7A94',
    success: '#10B981',
    warning: '#F59E0B',
    danger: '#DC2626',
  },
  logo: '',
  sounds: {
    enabled: true,
    volume: 0.28,
  },
}

export const demoCreationFields: CreationField[] = [
  { name: 'firstname', label: 'First Name', type: 'text', required: true },
  { name: 'lastname', label: 'Last Name', type: 'text', required: true },
  { name: 'birthdate', label: 'Date of Birth', type: 'date', required: true },
  { name: 'gender', label: 'Gender', type: 'select', required: true, options: ['male', 'female'] },
  { name: 'nationality', label: 'Nationality', type: 'autocomplete', required: false, options: [...NATIONALITIES] },
]

export const demoPosePresets = [
  { id: 'standing', label: 'Standing' },
  { id: 'lean_phone', label: 'Lean & Phone' },
  { id: 'sit_chair', label: 'Seated' },
  { id: 'sports_car', label: 'Sports Car' },
  { id: 'muscle_car', label: 'Muscle Car' },
]

export const demoCharacters: Character[] = [
  {
    cid: 1,
    citizenid: 'RYN001',
    charinfo: { firstname: 'Ryan', lastname: 'Mitchell', gender: 0 },
    job: { label: 'Police Officer', grade: { name: 'Sergeant' } },
    money: { cash: 2450, bank: 48320 },
    last_played: '2026-07-08 21:14:00',
    playtime: 142800,
    scene_data: { poseId: 'sports_car' },
  },
  {
    cid: 2,
    citizenid: 'RYN002',
    charinfo: { firstname: 'Alex', lastname: 'Carter', gender: 1 },
    job: { label: 'Mechanic', grade: { name: 'Employee' } },
    money: { cash: 890, bank: 12100 },
    last_played: '2026-07-05 18:42:00',
    playtime: 45600,
    scene_data: { poseId: 'lean_phone' },
  },
]

export const demoSpawnLocations: SpawnLocation[] = [
  {
    id: 'lastLocation',
    label: 'Last Location',
    icon: 'history',
    coords: { x: 195.17, y: -933.77, z: 29.7, w: 144.5 },
  },
  {
    id: 'housing:ps-housing:42',
    label: '4 Integrity Way - Apt 12',
    icon: 'home',
    coords: { x: -47.52, y: -585.86, z: 37.95, w: 70.0 },
  },
  {
    id: 'housing:qb-houses:legion_1',
    label: 'Legion Square House',
    icon: 'home',
    coords: { x: 215.12, y: -810.45, z: 30.73, w: 250.0 },
  },
  {
    id: 'legion',
    label: 'Legion Square',
    icon: 'map-pin',
    coords: { x: 195.17, y: -933.77, z: 29.7, w: 144.5 },
  },
  {
    id: 'policedp',
    label: 'Police Department',
    icon: 'shield',
    coords: { x: 428.23, y: -984.28, z: 29.76, w: 3.5 },
  },
  {
    id: 'paleto',
    label: 'Paleto Bay',
    icon: 'map-pin',
    coords: { x: 80.35, y: 6424.12, z: 31.67, w: 45.5 },
  },
]

export const demoSlotLimit = 3
