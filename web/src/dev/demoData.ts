import type { Character, CreationField, SpawnLocation, UITheme } from '../types'
import { NATIONALITIES } from '../data/nationalities'

export const demoTheme: UITheme = {
  theme: 'royal-blue',
  locale: 'en',
  serverName: 'RYN',
  colors: {
    primary: '#2D7FF9',
    background: '#05080D',
    surface: '#0F1620',
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
  { id: 'crossed_arms', label: 'Crossed Arms' },
  { id: 'lean_wall', label: 'Lean Wall' },
  { id: 'lean_phone', label: 'Lean & Phone' },
  { id: 'smoking', label: 'Smoking' },
  { id: 'bong', label: 'Hitting the Bong' },
  { id: 'coffee', label: 'Coffee' },
  { id: 'beer', label: 'Beer' },
]

export const demoScenePresets = [
  { id: 'apartment', label: 'Apartment' },
  { id: 'studio', label: 'Studio' },
  { id: 'rooftop', label: 'Rooftop' },
  { id: 'void', label: 'Void' },
]

export const demoCharacters: Character[] = [
  {
    cid: 1,
    citizenid: 'RYN001',
    charinfo: { firstname: 'Ryan', lastname: 'Mitchell', gender: 0, birthdate: '1994-03-12', nationality: 'American' },
    job: { label: 'Police Officer', grade: { name: 'Sergeant' } },
    money: { cash: 2450, bank: 48320 },
    last_played: '2026-07-08 21:14:00',
    playtime: 142800,
    scene_data: { poseId: 'smoking' },
  },
  {
    cid: 2,
    citizenid: 'RYN002',
    charinfo: { firstname: 'Alex', lastname: 'Carter', gender: 1, birthdate: '1998-11-02', nationality: 'Canadian' },
    job: { label: 'Mechanic', grade: { name: 'Employee' } },
    money: { cash: 890, bank: 12100 },
    last_played: '2026-07-05 18:42:00',
    playtime: 45600,
    scene_data: { poseId: 'bong' },
  },
]

export const demoSpawnLocations: SpawnLocation[] = [
  {
    id: 'housing:ps-housing:42',
    label: '4 Integrity Way - Apt 12',
    description: 'Spawn at your owned property.',
    icon: 'home',
    coords: { x: -47.52, y: -585.86, z: 37.95, w: 70.0 },
  },
  {
    id: 'housing:qb-houses:legion_1',
    label: 'Legion Square House',
    description: 'Spawn at your owned property.',
    icon: 'home',
    coords: { x: 215.12, y: -810.45, z: 30.73, w: 250.0 },
  },
  {
    id: 'legion',
    label: 'Legion Square',
    description: 'Downtown Los Santos. Busy streets, easy access to the city center.',
    icon: 'map-pin',
    coords: { x: 195.17, y: -933.77, z: 29.7, w: 144.5 },
  },
  {
    id: 'policedp',
    label: 'Police Department',
    description: 'Mission Row PD. Start near the heart of law enforcement.',
    icon: 'shield',
    coords: { x: 428.23, y: -984.28, z: 29.76, w: 3.5 },
  },
  {
    id: 'paleto',
    label: 'Paleto Bay',
    description: 'Quiet northern town. Fresh air and a slower pace.',
    icon: 'map-pin',
    coords: { x: 80.35, y: 6424.12, z: 31.67, w: 45.5 },
  },
]

export const demoSlotLimit = 3
