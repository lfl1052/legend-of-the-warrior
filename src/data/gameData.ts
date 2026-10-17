import { Item, LevelData, PlayerStats, SaveSlotData } from '../types/game';

export const INITIAL_STATS: PlayerStats = {
  level: 1,
  xp: 0,
  xpToNext: 100,
  hp: 100,
  maxHp: 100,
  stamina: 100,
  maxStamina: 100,
  attack: 18,
  defense: 6,
  critRate: 0.15,
  speed: 210,
  gold: 0,
  gems: 0,
  potions: 3,
  skillsUnlocked: ['whirlwind']
};

export const GAME_ITEMS: Item[] = [
  {
    id: 'weapon_rusty_blade',
    name: 'Rusty Shortsword',
    type: 'weapon',
    rarity: 'common',
    description: 'An old iron sword, nicked but reliable in close combat.',
    icon: 'Sword',
    value: 20,
    stats: { attack: 5 }
  },
  {
    id: 'weapon_steel_claymore',
    name: 'Steel Claymore',
    type: 'weapon',
    rarity: 'rare',
    description: 'Tempered high-carbon blade forged in the northern citadel.',
    icon: 'Sword',
    value: 120,
    stats: { attack: 16, critRate: 0.08 }
  },
  {
    id: 'weapon_radiant_edge',
    name: 'Sunfire Blade',
    type: 'weapon',
    rarity: 'legendary',
    description: 'Infused with ancient solar runes that scorch encroaching beasts.',
    icon: 'Sparkles',
    value: 450,
    stats: { attack: 32, critRate: 0.2, speed: 20 }
  },
  {
    id: 'armor_leather_vest',
    name: 'Scout Leather Tunic',
    type: 'armor',
    rarity: 'common',
    description: 'Supple boiled leather allowing swift evasion and light protection.',
    icon: 'Shield',
    value: 25,
    stats: { defense: 4, maxHp: 15 }
  },
  {
    id: 'armor_knight_plate',
    name: "Knight's Iron Hauberk",
    type: 'armor',
    rarity: 'rare',
    description: 'Interlocking steel rings capable of withstanding heavy boar charges.',
    icon: 'Shield',
    value: 160,
    stats: { defense: 14, maxHp: 45 }
  },
  {
    id: 'accessory_warrior_pendant',
    name: 'Amulet of Valor',
    type: 'accessory',
    rarity: 'rare',
    description: 'Ancient medal awarded to heroic vanguards. Boosts attack & vigor.',
    icon: 'Award',
    value: 150,
    stats: { attack: 8, maxHp: 25, critRate: 0.05 }
  },
  {
    id: 'consumable_potion',
    name: 'Elixir of Mending',
    type: 'consumable',
    rarity: 'common',
    description: 'Restores 45 Hit Points and quenches battle fatigue.',
    icon: 'Heart',
    value: 15
  }
];

export const LEVELS: LevelData[] = [
  // =========================================================================
  // ZONE I: Emerald Hollow & Waterfall Gorge (level_demo + asset_showcase)
  // =========================================================================
  {
    id: 'level_1',
    zoneIndex: 1,
    name: 'Emerald Hollow & Waterfall Gorge',
    nameZh: '翠林巨树与瀑布溪谷',
    chapter: 'Zone I • Western High Forest',
    chapterZh: '第一区 • 翠林西境（无缝连通地图 1/3）',
    description: 'Ancient hollow trees with mushroom shelves, cascading waterfalls, lotus river bridges, and stone ruins.',
    descriptionZh: '汇聚千年空心巨树、红伞树舌平台、三叠动态瀑布、睡莲溪流木桥与古石遗迹的翠林西境。',
    width: 2400,
    height: 720,
    theme: 'forest',
    spawnPoint: { x: 64, y: 512 },
    goalPoint: { x: 2260, y: 512 },
    platforms: [
      // Section 1: Hollow Tree Grove & Stepped Highland (x: 0..544)
      { x: 0, y: 576, w: 544, h: 144, type: 'solid', style: 'grass' },
      { x: 176, y: 528, w: 160, h: 48, type: 'solid', style: 'grass' },
      // Red Polypore Shelf Mushroom Platforms on the Giant Hollow Tree (Forest-2.png)
      { x: 352, y: 464, w: 128, h: 16, type: 'one-way', style: 'mushroom_shelf' },
      { x: 384, y: 384, w: 128, h: 16, type: 'one-way', style: 'mushroom_shelf' },

      // River Gap 1 (x: 544..640) crossed by FLUSH WoodenBridge at y = 576!
      { x: 528, y: 576, w: 128, h: 12, type: 'one-way', style: 'bridge' },

      // Section 2: Waterfall Terrace & Twin-Tier Ridge (x: 640..1344)
      { x: 640, y: 576, w: 704, h: 144, type: 'solid', style: 'grass' },
      { x: 784, y: 528, w: 368, h: 48, type: 'solid', style: 'grass' },
      { x: 912, y: 480, w: 160, h: 48, type: 'solid', style: 'grass' },
      // Floating grassy cliff island above waterfall
      { x: 1136, y: 384, w: 160, h: 48, type: 'solid', style: 'grass' },

      // River Gap 2 (x: 1344..1440) crossed by FLUSH WoodenBridge at y = 576!
      { x: 1328, y: 576, w: 128, h: 12, type: 'one-way', style: 'bridge' },

      // Section 3: Ancient Stone Ruins & Outpost Border (x: 1440..2400)
      { x: 1440, y: 576, w: 960, h: 144, type: 'solid', style: 'grass' },
      { x: 1584, y: 512, w: 192, h: 64, type: 'solid', style: 'grass' },
      // Ancient Carved Stone Ledges above the ruins
      { x: 1632, y: 416, w: 144, h: 16, type: 'one-way', style: 'stone_ledge' },
      { x: 1824, y: 368, w: 160, h: 48, type: 'solid', style: 'grass' },
      { x: 2032, y: 528, w: 144, h: 48, type: 'solid', style: 'grass' },

      // Bramble Thorn Hazards
      { x: 688, y: 560, w: 64, h: 16, type: 'hazard' },
      { x: 1488, y: 560, w: 64, h: 16, type: 'hazard' }
    ],
    ladders: [
      { id: 'ladder_1_hollow_tree', x: 360, y: 384, w: 28, h: 192 },
      { id: 'ladder_1_ruins', x: 1600, y: 416, w: 28, h: 96 }
    ],
    breakableRocks: [
      { id: 'rock_1_1', x: 296, y: 500, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'mossy', lootGold: 25, lootGems: 1 },
      { id: 'rock_1_2', x: 1032, y: 452, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'mossy', lootGold: 35, lootGems: 2 },
      { id: 'rock_1_3', x: 1736, y: 484, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'crag', lootGold: 40, lootGems: 2 }
    ],
    collectibles: [
      { id: 'col_1_1', x: 432, y: 352, type: 'red_potion', collected: false, labelZh: '生命灵药 +35 HP', labelEn: 'Life Vial +35 HP' },
      { id: 'col_1_2', x: 584, y: 536, type: 'upgrade_token', collected: false, labelZh: '翠林升级代币 +2 宝石', labelEn: 'Upgrade Token +2 Gems' },
      { id: 'col_1_3', x: 1200, y: 348, type: 'gold_key', collected: false, labelZh: '古老黄金钥匙 +50G', labelEn: 'Ancient Gold Key +50G' }
    ],
    structures: [
      { type: 'hollow_tree', x: 368, y: 576 },
      { type: 'waterfall', x: 568, y: 576 },
      { type: 'stone_ruins', x: 944, y: 480 },
      { type: 'waterfall', x: 1368, y: 576 },
      { type: 'hollow_tree', x: 1848, y: 576 },
      { type: 'timber_cabin', x: 2210, y: 576 }
    ],
    chests: [
      {
        id: 'chest_1_1',
        x: 440,
        y: 352,
        opened: false,
        loot: { gold: 55, gems: 3, item: GAME_ITEMS[0] }
      },
      {
        id: 'chest_1_2',
        x: 1888,
        y: 336,
        opened: false,
        loot: { gold: 95, gems: 5, item: GAME_ITEMS[3] }
      }
    ],
    altars: [
      { id: 'altar_1_mid', x: 976, y: 440, activated: false }
    ],
    enemies: [
      {
        id: 'snail_1',
        type: 'snail',
        x: 220,
        y: 500,
        vx: 0,
        vy: 0,
        w: 38,
        h: 28,
        facing: -1,
        hp: 45,
        maxHp: 45,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 65,
        originX: 240,
        originY: 500,
        damage: 10,
        score: 60,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'bee_1',
        type: 'bee',
        x: 480,
        y: 340,
        vx: 0,
        vy: 0,
        w: 36,
        h: 36,
        facing: -1,
        hp: 35,
        maxHp: 35,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 130,
        originX: 480,
        originY: 340,
        damage: 12,
        score: 50,
        hitFlash: 0
      },
      {
        id: 'boar_1',
        type: 'boar',
        x: 690,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 65,
        maxHp: 65,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 140,
        originX: 690,
        originY: 544,
        damage: 16,
        score: 90,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'bee_2',
        type: 'bee',
        x: 1180,
        y: 330,
        vx: 0,
        vy: 0,
        w: 36,
        h: 36,
        facing: -1,
        hp: 40,
        maxHp: 40,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 140,
        originX: 1180,
        originY: 330,
        damage: 14,
        score: 60,
        hitFlash: 0
      },
      {
        id: 'snail_2',
        type: 'snail',
        x: 1650,
        y: 484,
        vx: 0,
        vy: 0,
        w: 38,
        h: 28,
        facing: -1,
        hp: 55,
        maxHp: 55,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 65,
        originX: 1660,
        originY: 484,
        damage: 14,
        score: 70,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'boar_2',
        type: 'boar',
        x: 1900,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 70,
        maxHp: 70,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 110,
        originX: 1900,
        originY: 544,
        damage: 18,
        score: 100,
        hitFlash: 0,
        isGrounded: true
      }
    ]
  },

  // =========================================================================
  // ZONE II: Golden Timber Outpost & Mine Approach (level_2 West-Mid)
  // =========================================================================
  {
    id: 'level_2',
    zoneIndex: 2,
    name: 'Golden Timber Outpost & Mine Approach',
    nameZh: '金秋木寨与古矿前哨',
    chapter: 'Zone II • Central Timberlands & Mine',
    chapterZh: '第二区 • 金秋木寨与矿道前哨（无缝连通地图 2/3）',
    description: 'Multi-tier timber watchtowers, village cabins, rocky crag outcrops, and the grand Mine Stone tunnel.',
    descriptionZh: '金秋林海中的木制哨塔、村落木屋、脚手架栈道与通往地底圣殿的巨型矿洞入口。',
    width: 2600,
    height: 720,
    theme: 'ruins',
    spawnPoint: { x: 80, y: 512 },
    prevPortalPoint: { x: 24, y: 512 },
    goalPoint: { x: 2440, y: 512 },
    platforms: [
      // Section 1: Timber Outpost Village & Watchtower (x: 0..688)
      { x: 0, y: 576, w: 688, h: 144, type: 'solid', style: 'grass' },
      // Timber Scaffolding Platforms on the Outpost Cabin & Watchtower (Buildings.png)
      { x: 160, y: 464, w: 128, h: 16, type: 'one-way', style: 'timber_scaffold' },
      { x: 400, y: 480, w: 128, h: 16, type: 'one-way', style: 'timber_scaffold' },
      { x: 400, y: 384, w: 128, h: 16, type: 'one-way', style: 'timber_scaffold' },

      // River Gorge 1 (x: 688..784) with FLUSH WoodenBridge at y = 576!
      { x: 672, y: 576, w: 128, h: 12, type: 'one-way', style: 'bridge' },

      // Section 2: Stone Ruins & Rocky Crag Terraces (x: 784..1600)
      { x: 784, y: 576, w: 816, h: 144, type: 'solid', style: 'grass' },
      // Stepped Rocky Crag (uses Forest-1.png rows 5..9 Rock Cliff tiles!)
      { x: 928, y: 512, w: 256, h: 64, type: 'solid', style: 'rock' },
      { x: 992, y: 448, w: 128, h: 64, type: 'solid', style: 'rock' },
      // Ancient Carved Stone Ledges
      { x: 1216, y: 400, w: 160, h: 16, type: 'one-way', style: 'stone_ledge' },
      { x: 1408, y: 496, w: 144, h: 80, type: 'solid', style: 'rock' },

      // River Gorge 2 (x: 1600..1696) with FLUSH WoodenBridge at y = 576!
      { x: 1584, y: 576, w: 128, h: 12, type: 'one-way', style: 'bridge' },

      // Section 3: Mine Supply Camp & Grand Mine Stone Tunnel (x: 1696..2600)
      { x: 1696, y: 576, w: 904, h: 144, type: 'solid', style: 'rock' },
      { x: 1840, y: 512, w: 224, h: 64, type: 'solid', style: 'rock' },
      { x: 1872, y: 416, w: 160, h: 16, type: 'one-way', style: 'timber_scaffold' },
      { x: 2112, y: 384, w: 160, h: 48, type: 'solid', style: 'rock' },

      // Hazards
      { x: 1248, y: 560, w: 96, h: 16, type: 'hazard' }
    ],
    ladders: [
      { id: 'ladder_2_watchtower', x: 448, y: 384, w: 28, h: 192 },
      { id: 'ladder_2_mine_scaffold', x: 1888, y: 416, w: 28, h: 96 }
    ],
    breakableRocks: [
      { id: 'rock_2_1', x: 560, y: 548, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'ore', lootGold: 45, lootGems: 2 },
      { id: 'rock_2_2', x: 1040, y: 420, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'crag', lootGold: 50, lootGems: 3 },
      { id: 'rock_2_3', x: 2016, y: 484, w: 32, h: 28, hp: 3, maxHp: 3, hitFlash: 0, variant: 'ore', lootGold: 65, lootGems: 4 }
    ],
    collectibles: [
      { id: 'col_2_1', x: 208, y: 432, type: 'blue_potion', collected: false, labelZh: '以太体力灵药 +40 MP', labelEn: 'Ether Vial +40 Stamina' },
      { id: 'col_2_2', x: 1280, y: 368, type: 'upgrade_token', collected: false, labelZh: '矿道地图代币 +3 宝石', labelEn: 'Map Token +3 Gems' },
      { id: 'col_2_3', x: 1936, y: 384, type: 'gold_key', collected: false, labelZh: '矿工秘钥 +75G', labelEn: "Miner's Key +75G" }
    ],
    structures: [
      { type: 'timber_cabin', x: 160, y: 576 },
      { type: 'watchtower', x: 416, y: 576 },
      { type: 'stone_ruins', x: 1008, y: 448 },
      { type: 'waterfall', x: 1616, y: 576 },
      { type: 'supply_camp', x: 1760, y: 576 },
      { type: 'watchtower', x: 1900, y: 512 },
      { type: 'mine_entrance', x: 2410, y: 576 }
    ],
    chests: [
      {
        id: 'chest_2_1',
        x: 448,
        y: 352,
        opened: false,
        loot: { gold: 110, gems: 6, item: GAME_ITEMS[1] }
      },
      {
        id: 'chest_2_2',
        x: 2176,
        y: 352,
        opened: false,
        loot: { gold: 160, gems: 10, item: GAME_ITEMS[5] }
      }
    ],
    altars: [
      { id: 'altar_2_mid', x: 1456, y: 456, activated: false }
    ],
    enemies: [
      {
        id: 'boar_2_1',
        type: 'boar',
        x: 340,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 80,
        maxHp: 80,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 130,
        originX: 340,
        originY: 544,
        damage: 20,
        score: 120,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'bee_2_1',
        type: 'bee',
        x: 730,
        y: 360,
        vx: 0,
        vy: 0,
        w: 36,
        h: 36,
        facing: -1,
        hp: 45,
        maxHp: 45,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 140,
        originX: 730,
        originY: 360,
        damage: 16,
        score: 75,
        hitFlash: 0
      },
      {
        id: 'snail_2_1',
        type: 'snail',
        x: 980,
        y: 484,
        vx: 0,
        vy: 0,
        w: 38,
        h: 28,
        facing: -1,
        hp: 75,
        maxHp: 75,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 60,
        originX: 980,
        originY: 484,
        damage: 18,
        score: 90,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'boar_2_2',
        type: 'boar',
        x: 1520,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 95,
        maxHp: 95,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 150,
        originX: 1520,
        originY: 544,
        damage: 22,
        score: 140,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'boar_2_3',
        type: 'boar',
        x: 2220,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 105,
        maxHp: 105,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 120,
        originX: 2220,
        originY: 544,
        damage: 24,
        score: 160,
        hitFlash: 0,
        isGrounded: true
      }
    ]
  },

  // =========================================================================
  // ZONE III: Crimson Fortress & Guardian's Sanctum (level_2 Boss Coliseum)
  // =========================================================================
  {
    id: 'level_3',
    zoneIndex: 3,
    name: "Crimson Fortress & Guardian's Sanctum",
    nameZh: '赤林古堡与守卫圣殿',
    chapter: 'Zone III • The Trial of Steel',
    chapterZh: '第三区 • 赤林古堡与试炼圣殿（无缝连通地图 3/3）',
    description: 'Blue-roof stone fortress, craggy dark cliffs, purple bramble vines, and the Forest Guardian Boss Arena.',
    descriptionZh: '穿越矿洞抵达的赤林深处：蓝瓦石木要塞、暗岩高台、紫荆棘藤蔓与森林守卫 Boss 决战圣殿。',
    width: 1800,
    height: 720,
    theme: 'sanctum',
    spawnPoint: { x: 96, y: 512 },
    prevPortalPoint: { x: 24, y: 512 },
    goalPoint: { x: 1660, y: 512 },
    platforms: [
      // Craggy Rocky Cliff Arena Floor (Forest-1.png rows 5..9 Rock tiles!)
      { x: 0, y: 576, w: 1800, h: 144, type: 'solid', style: 'rock' },
      // Fortress Courtyard Stepped Bastion
      { x: 208, y: 512, w: 192, h: 64, type: 'solid', style: 'rock' },
      // Coliseum Tactical Ledges (Stone Ledges & Timber Battlements)
      { x: 464, y: 448, w: 160, h: 16, type: 'one-way', style: 'stone_ledge' },
      { x: 752, y: 384, w: 240, h: 16, type: 'one-way', style: 'stone_ledge' },
      { x: 1120, y: 448, w: 160, h: 16, type: 'one-way', style: 'stone_ledge' },
      { x: 1376, y: 512, w: 176, h: 64, type: 'solid', style: 'rock' }
    ],
    ladders: [
      { id: 'ladder_3_fortress_left', x: 480, y: 448, w: 28, h: 128 },
      { id: 'ladder_3_fortress_right', x: 1236, y: 448, w: 28, h: 128 }
    ],
    breakableRocks: [
      { id: 'rock_3_1', x: 336, y: 484, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'ore', lootGold: 60, lootGems: 3 },
      { id: 'rock_3_2', x: 1424, y: 484, w: 32, h: 28, hp: 2, maxHp: 2, hitFlash: 0, variant: 'ore', lootGold: 80, lootGems: 5 }
    ],
    collectibles: [
      { id: 'col_3_1', x: 528, y: 416, type: 'red_potion', collected: false, labelZh: '圣殿秘药 +45 HP', labelEn: 'Sanctum Elixir +45 HP' },
      { id: 'col_3_2', x: 864, y: 348, type: 'upgrade_token', collected: false, labelZh: '圣殿王冠代币 +5 宝石', labelEn: 'Crown Token +5 Gems' }
    ],
    structures: [
      { type: 'mine_entrance', x: 32, y: 576 },
      { type: 'stone_fortress', x: 224, y: 512 },
      { type: 'stone_ruins', x: 824, y: 576 },
      { type: 'stone_fortress', x: 1380, y: 512 },
      { type: 'mine_entrance', x: 1632, y: 576 }
    ],
    chests: [
      {
        id: 'chest_3_1',
        x: 856,
        y: 352,
        opened: false,
        loot: { gold: 180, gems: 10, item: GAME_ITEMS[4] }
      },
      {
        id: 'chest_3_boss',
        x: 1560,
        y: 544,
        opened: false,
        loot: { gold: 500, gems: 25, item: GAME_ITEMS[2] }
      }
    ],
    altars: [
      { id: 'altar_3_entrance', x: 160, y: 536, activated: false }
    ],
    enemies: [
      {
        id: 'boar_3_guard',
        type: 'boar',
        x: 520,
        y: 544,
        vx: 0,
        vy: 0,
        w: 48,
        h: 32,
        facing: -1,
        hp: 110,
        maxHp: 110,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 0,
        patrolRange: 110,
        originX: 520,
        originY: 544,
        damage: 22,
        score: 150,
        hitFlash: 0,
        isGrounded: true
      },
      {
        id: 'boss_guardian',
        type: 'boss',
        x: 980,
        y: 486,
        vx: 0,
        vy: 0,
        w: 68,
        h: 90,
        facing: -1,
        hp: 450,
        maxHp: 450,
        state: 'patrol',
        stateTimer: 0,
        attackCooldown: 1.5,
        patrolRange: 220,
        originX: 980,
        originY: 486,
        damage: 32,
        score: 1000,
        hitFlash: 0,
        isGrounded: true
      }
    ]
  }
];

// --- LocalStorage Save & Load Manager (Replicating Godot ISaveable Protocol) ---

const SAVE_PREFIX = 'legend_warrior_save_';

export function loadSaveSlot(slotId: number): SaveSlotData | null {
  try {
    const raw = localStorage.getItem(`${SAVE_PREFIX}${slotId}`);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (err) {
    console.error('Failed to load save slot:', err);
    return null;
  }
}

export function writeSaveSlot(slotData: SaveSlotData): boolean {
  try {
    localStorage.setItem(`${SAVE_PREFIX}${slotData.slotId}`, JSON.stringify(slotData));
    return true;
  } catch (err) {
    console.error('Failed to save game slot:', err);
    return false;
  }
}

export function getAllSaveSlots(): (SaveSlotData | null)[] {
  return [loadSaveSlot(1), loadSaveSlot(2), loadSaveSlot(3)];
}

export function createNewSaveSlot(slotId: number, color: import('../types/game').CharacterColor): SaveSlotData {
  return {
    slotId,
    timestamp: Date.now(),
    playtimeSeconds: 0,
    levelId: 'level_1',
    characterColor: color,
    stats: { ...INITIAL_STATS },
    equipment: {
      weapon: GAME_ITEMS[0],
      armor: GAME_ITEMS[3],
      accessory: null
    },
    inventory: [GAME_ITEMS[0], GAME_ITEMS[3]],
    openedChests: [],
    activatedAltars: []
  };
}
