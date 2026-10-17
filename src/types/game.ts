export type CharacterColor = 'blue' | 'red' | 'green' | 'purple';

export interface PlayerStats {
  level: number;
  xp: number;
  xpToNext: number;
  hp: number;
  maxHp: number;
  stamina: number;
  maxStamina: number;
  attack: number;
  defense: number;
  critRate: number; // 0 to 1
  speed: number;
  gold: number;
  gems: number;
  potions: number;
  skillsUnlocked: string[];
}

export type PlayerActionState =
  | 'idle'
  | 'run'
  | 'jump'
  | 'fall'
  | 'climb'
  | 'dash'
  | 'attack1'
  | 'attack2'
  | 'attack3'
  | 'skill'
  | 'block'
  | 'hurt'
  | 'dead';

export interface Item {
  id: string;
  name: string;
  type: 'weapon' | 'armor' | 'accessory' | 'consumable';
  description: string;
  icon: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  stats?: {
    attack?: number;
    defense?: number;
    critRate?: number;
    maxHp?: number;
    speed?: number;
  };
  value: number;
}

export interface Equipment {
  weapon: Item | null;
  armor: Item | null;
  accessory: Item | null;
}

export interface Platform {
  x: number;
  y: number;
  w: number;
  h: number;
  type: 'solid' | 'one-way' | 'hazard' | 'crumbly';
  style?: 'grass' | 'rock' | 'bridge' | 'stone_ledge' | 'mushroom_shelf' | 'timber_scaffold';
  color?: string;
  crumblyTimer?: number;
}

export interface Ladder {
  id: string;
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface BreakableRock {
  id: string;
  x: number;
  y: number;
  w: number;
  h: number;
  hp: number;
  maxHp: number;
  hitFlash: number;
  variant: 'mossy' | 'crag' | 'ore';
  lootGold: number;
  lootGems?: number;
}

export interface Collectible {
  id: string;
  x: number;
  y: number;
  type: 'red_potion' | 'blue_potion' | 'gold_key' | 'upgrade_token';
  collected: boolean;
  labelZh: string;
  labelEn: string;
}

export interface WorldStructure {
  type:
    | 'hollow_tree'
    | 'waterfall'
    | 'timber_cabin'
    | 'watchtower'
    | 'stone_fortress'
    | 'stone_ruins'
    | 'mine_entrance'
    | 'supply_camp';
  x: number;
  y: number;
  w?: number;
  h?: number;
}

export interface Chest {
  id: string;
  x: number;
  y: number;
  opened: boolean;
  loot: {
    gold: number;
    gems?: number;
    item?: Item;
  };
}

export interface CheckpointAltar {
  id: string;
  x: number;
  y: number;
  activated: boolean;
}

export interface Enemy {
  id: string;
  type: 'bee' | 'boar' | 'snail' | 'boss';
  x: number;
  y: number;
  vx: number;
  vy: number;
  w: number;
  h: number;
  facing: 1 | -1;
  hp: number;
  maxHp: number;
  state: 'patrol' | 'chase' | 'attack' | 'hit' | 'dead' | 'windup' | 'recovery';
  stateTimer: number;
  attackCooldown: number;
  patrolRange: number;
  originX: number;
  originY: number;
  damage: number;
  score: number;
  hitFlash: number;
  isGrounded?: boolean;
}

export interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
  color: string;
  life: number;
  maxLife: number;
  shape?: 'circle' | 'square' | 'line' | 'spark' | 'dust' | 'magic' | 'slash' | 'blood';
}

export interface DamageNumber {
  id: string;
  x: number;
  y: number;
  value: number | string;
  isCrit: boolean;
  isPlayer: boolean;
  isHeal?: boolean;
  life: number;
  maxLife: number;
}

export interface LevelData {
  id: string;
  zoneIndex: number;
  name: string;
  nameZh: string;
  chapter: string;
  chapterZh: string;
  description: string;
  descriptionZh: string;
  width: number;
  height: number;
  spawnPoint: { x: number; y: number };
  goalPoint: { x: number; y: number };
  prevPortalPoint?: { x: number; y: number };
  platforms: Platform[];
  ladders?: Ladder[];
  breakableRocks?: BreakableRock[];
  collectibles?: Collectible[];
  structures?: WorldStructure[];
  chests: Chest[];
  altars: CheckpointAltar[];
  enemies: Enemy[];
  theme: 'forest' | 'ruins' | 'sanctum';
}

export interface SaveSlotData {
  slotId: number;
  timestamp: number;
  playtimeSeconds: number;
  levelId: string;
  characterColor: CharacterColor;
  stats: PlayerStats;
  equipment: Equipment;
  inventory: Item[];
  openedChests: string[];
  activatedAltars: string[];
}
