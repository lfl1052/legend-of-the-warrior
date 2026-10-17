import { LevelData, Platform } from '../types/game';
import { ASSET_PATHS, assetLoader } from './assetLoader';

export const TILE_SIZE = 16;

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

// ============================================================================
// 1. VERIFIED CROPPED REGIONS FROM data/editor_asset_catalog.json & scenes/
// ============================================================================

// Trees/*.png (1344x1200) — ONLY complete standalone trees with full trunks!
// Never use trunkless foliage crowns (01, 11, 17, 23) or bare poles (06, 07).
export const TREE_CROPS: Record<string, Rect> = {
  GIANT_A: { x: 0, y: 0, w: 107, h: 368 }, // map.components.trees.*.00
  GIANT_B: { x: 224, y: 0, w: 107, h: 368 }, // map.components.trees.*.02
  TALL_A: { x: 2, y: 391, w: 108, h: 313 }, // map.components.trees.*.10
  TALL_B: { x: 226, y: 391, w: 108, h: 313 }, // map.components.trees.*.12
  MEDIUM_A: { x: 4, y: 720, w: 88, h: 208 }, // map.components.trees.*.16 (level_2.tscn)
  MEDIUM_B: { x: 196, y: 720, w: 88, h: 208 }, // map.components.trees.*.18
  SMALL_A: { x: 6, y: 944, w: 88, h: 144 }, // map.components.trees.*.22 (asset_showcase_level.tscn)
  SMALL_B: { x: 198, y: 944, w: 88, h: 144 }, // map.components.trees.*.24
  SAPLING_A: { x: 5, y: 1092, w: 70, h: 108 }, // map.components.trees.*.28
};

const PARALLAX_FAR_TREES: Rect[] = [
  TREE_CROPS.MEDIUM_A,
  TREE_CROPS.SMALL_A,
  TREE_CROPS.MEDIUM_B,
  TREE_CROPS.SMALL_B,
];

const PARALLAX_MID_TREES: Rect[] = [
  TREE_CROPS.TALL_A,
  TREE_CROPS.MEDIUM_A,
  TREE_CROPS.TALL_B,
  TREE_CROPS.MEDIUM_B,
];

const WORLD_LANDMARK_TREES: Rect[] = [
  TREE_CROPS.TALL_A,
  TREE_CROPS.MEDIUM_A,
  TREE_CROPS.GIANT_A,
  TREE_CROPS.SMALL_A,
  TREE_CROPS.TALL_B,
  TREE_CROPS.MEDIUM_B,
];

// Forest-1.png (528x336) — Flat-bottomed ground bushes (exact bounding boxes)
export const FOREST1_BUSH_CROPS: Rect[] = [
  { x: 274, y: 5, w: 124, h: 43 }, // Bright green flat-base bush
  { x: 274, y: 53, w: 124, h: 43 }, // Golden-olive flat-base bush
  { x: 274, y: 101, w: 124, h: 43 }, // Dark moss flat-base bush
  { x: 274, y: 149, w: 124, h: 43 }, // Deep forest flat-base bush
  { x: 274, y: 197, w: 124, h: 43 }, // Shadow green flat-base bush
];

// Forest-1.png — Standalone cropped props & wooden_bridge.tscn regions
export const FOREST1_CROPS = {
  BRIDGE_LEFT_END: { x: 176, y: 116, w: 24, h: 44 }, // scenes/props/wooden_bridge.tscn
  BRIDGE_MIDDLE: { x: 177, y: 94, w: 46, h: 12 }, // scenes/props/wooden_bridge.tscn
  BRIDGE_RIGHT_END: { x: 232, y: 116, w: 24, h: 44 }, // scenes/props/wooden_bridge.tscn
  STONE_FLOATING_LEDGE: { x: 194, y: 238, w: 45, h: 17 }, // 3-block carved stone floating platform
  WATERFALL_CHUTE: { x: 48, y: 208, w: 48, h: 64 }, // cols 3..5, rows 13..16 (build_editor_asset_catalog.py)
  MUSHROOM_WIDE_RED: { x: 177, y: 279, w: 30, h: 25 }, // Standalone wide red-spotted mushroom
  MUSHROOM_TALL_ORANGE: { x: 210, y: 272, w: 28, h: 32 }, // Standalone tall orange-spotted mushroom
  MUSHROOM_MED_RED: { x: 241, y: 283, w: 14, h: 21 }, // Standalone medium red mushroom
  MUSHROOM_SMALL_RED: { x: 162, y: 273, w: 11, h: 14 }, // Standalone small red mushroom
  FERN_BROAD: { x: 112, y: 279, w: 32, h: 25 }, // Broad green fern
  CATTAIL_REEDS: { x: 145, y: 278, w: 15, h: 26 }, // Cattail reeds
  LOTUS_GREEN: { x: 18, y: 299, w: 28, h: 37 }, // Green lotus pad
  LOTUS_FLOWER: { x: 50, y: 294, w: 28, h: 42 }, // White-flower lotus pad
  POTION_RED: { x: 418, y: 289, w: 12, h: 15 }, // Single red potion bottle
  POTION_BLUE: { x: 466, y: 289, w: 12, h: 15 }, // Single blue potion bottle
  GOLD_KEY: { x: 82, y: 291, w: 12, h: 7 }, // Single gold key
  GOLD_COIN: { x: 101, y: 291, w: 6, h: 9 }, // Single gold coin
};

// Forest-2.png (256x256) — ONLY standalone verified crops (no uncropped tileset blocks!)
export const FOREST2_CROPS = {
  SHELF_MUSHROOM_TRUNK: { x: 129, y: 0, w: 62, h: 32 }, // Trunk segment with 4 red shelf-mushrooms
  MUSHROOM_PROP_MED: { x: 146, y: 33, w: 11, h: 14 }, // Standalone red mushroom
  MUSHROOM_PROP_SMALL: { x: 132, y: 35, w: 8, h: 10 }, // Tiny red mushroom
  MUSHROOM_PROP_TALL: { x: 162, y: 42, w: 11, h: 20 }, // Tall-stem red mushroom
  BEEHIVE_ON_BRANCH: { x: 160, y: 70, w: 32, h: 25 }, // Leafy branch with hanging golden beehive
  MOSSY_BRANCH_LEDGE: { x: 164, y: 187, w: 75, h: 16 }, // Horizontal mossy branch platform
};

// Buildings.png (432x240) — SCENE_PAINT_COMPONENTS["buildings"] = {1,2,4,5,6,7,8,9,10,11,12}
export const BUILDINGS_CROPS = {
  SHINGLE_ROOF: { x: 349, y: 0, w: 54, h: 48 }, // buildings.default.01
  STONE_TIMBER_PILLAR: { x: 416, y: 16, w: 16, h: 64 }, // buildings.default.02
  WOODEN_BENCH: { x: 209, y: 84, w: 30, h: 12 }, // buildings.default.04
  SCAFFOLD_DECK: { x: 0, y: 93, w: 48, h: 14 }, // buildings.default.05 (33_scaffold_deck)
  SUPPLY_SHELF: { x: 144, y: 97, w: 64, h: 79 }, // buildings.default.06
  CABIN_DOOR: { x: 373, y: 154, w: 38, h: 54 }, // buildings.default.07
  SUPPLY_LOGS: { x: 16, y: 160, w: 46, h: 16 }, // buildings.default.08 (34_supply_logs)
  STONE_FOUNDATION: { x: 96, y: 192, w: 64, h: 32 }, // buildings.default.09
  SUPPLY_RACK_FENCE: { x: 163, y: 192, w: 42, h: 32 }, // buildings.default.10 (35_supply_rack)
  SCAFFOLD_POST_A: { x: 213, y: 192, w: 6, h: 32 }, // buildings.default.11 (36_scaffold_post_a)
  SCAFFOLD_POST_B: { x: 227, y: 192, w: 10, h: 32 }, // buildings.default.12 (37_scaffold_post_b)
  WOODEN_BARREL: { x: 224, y: 45, w: 16, h: 18 }, // Standalone wooden barrel
  FORTRESS_GATE: { x: 272, y: 160, w: 64, h: 65 }, // Standalone double wooden gate
};

// Mine Stone.png (224x160) — SCENE_PAINT_COMPONENTS["mine_stone"] = {0,1,2,3}
export const MINE_STONE_CROPS = {
  ROCK_PILE_A: { x: 0, y: 0, w: 80, h: 32 }, // mine_stone.default.00 (25_mine_a)
  MINE_ENTRANCE: { x: 96, y: 0, w: 128, h: 160 }, // mine_stone.default.01 (26_mine_b)
  ROCK_PILE_B: { x: 0, y: 48, w: 80, h: 32 }, // mine_stone.default.02 (27_mine_c)
  ROCK_PILE_C: { x: 0, y: 96, w: 80, h: 32 }, // mine_stone.default.03 (32_mine_d)
};

// Props-Rocks.png (288x256) — SCENE_PAINT_COMPONENTS["rocks"] verified standalone rocks
export const ROCKS_CROPS = {
  SMALL_FRAGMENT: { x: 146, y: 0, w: 13, h: 15 }, // rocks.default.00 (breakable_rock.tscn)
  MED_BROWN: { x: 67, y: 1, w: 28, h: 31 }, // rocks.default.01
  SPIRE_BROWN: { x: 6, y: 2, w: 55, h: 78 }, // rocks.default.03
  BOULDER_BROWN: { x: 224, y: 6, w: 48, h: 42 }, // rocks.default.05
  WIDE_BROWN: { x: 212, y: 52, w: 59, h: 28 }, // rocks.default.13
  MED_MOSSY: { x: 67, y: 81, w: 28, h: 31 }, // rocks.default.14
  SPIRE_MOSSY: { x: 6, y: 82, w: 55, h: 78 }, // rocks.default.15
  BOULDER_MOSSY: { x: 224, y: 85, w: 48, h: 43 }, // rocks.default.17
  APPROACH_MOSSY: { x: 128, y: 89, w: 16, h: 23 }, // rocks.default.18 (23_rock_d)
  CONE_MOSSY: { x: 132, y: 114, w: 44, h: 46 }, // rocks.default.23
  WIDE_MOSSY: { x: 212, y: 132, w: 59, h: 28 }, // rocks.default.25 (24_rock_e)
  MONOLITH_TALL: { x: 9, y: 166, w: 50, h: 90 }, // rocks.default.27
  CHISELED_BLOCK: { x: 163, y: 166, w: 43, h: 42 }, // rocks.default.28
  MONOLITH_SLIM: { x: 71, y: 177, w: 37, h: 79 }, // rocks.default.31
  LARGE_SLAB: { x: 166, y: 213, w: 52, h: 43 }, // rocks.default.35 (31_rock_large)
};

// Hive.png (128x256) — Standalone cropped hazards & gems
export const HIVE_CROPS = {
  SPIKE_STRIP: { x: 0, y: 121, w: 48, h: 24 }, // 6 black spikes on thorny base
  BLUE_GEM: { x: 113, y: 64, w: 14, h: 16 }, // hive.default.02
};

// ============================================================================
// 2. FOREST-1.PNG TERRAIN AUTOTILE DEFINITIONS (scripts/tools/build_forest_tileset.gd)
// ============================================================================

const GRASS_TOP_LEFT = { x: 0, y: 0, w: 16, h: 32 };
const GRASS_TOP_MIDS = [
  { x: 1, y: 0, w: 16, h: 32 },
  { x: 2, y: 0, w: 16, h: 32 },
  { x: 3, y: 0, w: 16, h: 32 },
];
const GRASS_TOP_RIGHT = { x: 4, y: 0, w: 16, h: 32 };

const GRASS_LEFT_WALLS = [
  { x: 0, y: 2, w: 16, h: 16 },
  { x: 0, y: 3, w: 16, h: 16 },
];
const GRASS_RIGHT_WALLS = [
  { x: 4, y: 2, w: 16, h: 16 },
  { x: 4, y: 3, w: 16, h: 16 },
];
const GRASS_CENTERS = [
  { x: 1, y: 2, w: 16, h: 16 },
  { x: 2, y: 2, w: 16, h: 16 },
  { x: 3, y: 2, w: 16, h: 16 },
  { x: 1, y: 3, w: 16, h: 16 },
  { x: 2, y: 3, w: 16, h: 16 },
  { x: 3, y: 3, w: 16, h: 16 },
];

const GRASS_BOTTOM_LEFT = { x: 0, y: 4, w: 16, h: 16 };
const GRASS_BOTTOM_MIDS = [
  { x: 1, y: 4, w: 16, h: 16 },
  { x: 2, y: 4, w: 16, h: 16 },
  { x: 3, y: 4, w: 16, h: 16 },
];
const GRASS_BOTTOM_RIGHT = { x: 4, y: 4, w: 16, h: 16 };

// Rocky / Crag Cliff Terrain Block in Forest-1.png (cols 0..4, rows 6..9)
const ROCK_TOP_LEFT = { x: 0, y: 6, w: 16, h: 16 };
const ROCK_TOP_MIDS = [
  { x: 1, y: 6, w: 16, h: 16 },
  { x: 2, y: 6, w: 16, h: 16 },
  { x: 3, y: 6, w: 16, h: 16 },
];
const ROCK_TOP_RIGHT = { x: 4, y: 6, w: 16, h: 16 };
const ROCK_LEFT_WALLS = [
  { x: 0, y: 7, w: 16, h: 16 },
  { x: 0, y: 8, w: 16, h: 16 },
];
const ROCK_RIGHT_WALLS = [
  { x: 4, y: 7, w: 16, h: 16 },
  { x: 4, y: 8, w: 16, h: 16 },
];
const ROCK_CENTERS = [
  { x: 1, y: 7, w: 16, h: 16 },
  { x: 2, y: 7, w: 16, h: 16 },
  { x: 3, y: 7, w: 16, h: 16 },
  { x: 1, y: 8, w: 16, h: 16 },
  { x: 2, y: 8, w: 16, h: 16 },
  { x: 3, y: 8, w: 16, h: 16 },
];
const ROCK_BOTTOM_LEFT = { x: 0, y: 9, w: 16, h: 16 };
const ROCK_BOTTOM_MIDS = [
  { x: 1, y: 9, w: 16, h: 16 },
  { x: 2, y: 9, w: 16, h: 16 },
  { x: 3, y: 9, w: 16, h: 16 },
];
const ROCK_BOTTOM_RIGHT = { x: 4, y: 9, w: 16, h: 16 };

// Derived inner corners (art/runtime/derived/terrain/forest_ground_inner_corners.png)
const INNER_MISSING_TOP_LEFT = { x: 0, y: 0, w: 16, h: 32 };
const INNER_MISSING_TOP_RIGHT = { x: 1, y: 0, w: 16, h: 32 };

// Animated River Water cells in Forest-1.png (exact coords from asset_showcase_level.gd)
// RIVER_SURFACE = (6..9, 14), RIVER_BODY = (6..9, 15), RIVER_DEEP = (6..9, 16)
const RIVER_SURFACE_COLS = [6, 7, 8, 9];
const RIVER_BANK_LEFT_CELLS = [
  { x: 0, y: 13 },
  { x: 0, y: 14 },
  { x: 0, y: 15 },
  { x: 0, y: 16 },
];
const RIVER_BANK_RIGHT_CELLS = [
  { x: 2, y: 13 },
  { x: 2, y: 14 },
  { x: 2, y: 15 },
  { x: 2, y: 16 },
];

// Safe single-cell foreground mushroom accents in Forest-1.png (build_forest_tileset.gd line 30)
const MUSHROOM_ACCENTS = [
  { x: 10, y: 17 },
  { x: 15, y: 17 },
  { x: 10, y: 18 },
  { x: 15, y: 18 },
];

export interface RiverGap {
  id: string;
  startCol: number;
  endCol: number;
  surfaceRow: number;
  bottomRow: number;
}

export interface CompiledTilemap {
  cols: number;
  rows: number;
  grid: Uint8Array; // 0 = empty, 1 = grass terrain, 2 = rock terrain
  riverGaps: RiverGap[];
  accents: { col: number; row: number; variant: number }[];
  mainGroundY: number;
}

function hash2D(x: number, y: number): number {
  let h = (x * 374761393 + y * 668265263) ^ 0x5bf03635;
  h = (h ^ (h >> 13)) * 1274126177;
  return Math.abs(h ^ (h >> 16));
}

function drawCropped(
  ctx: CanvasRenderingContext2D,
  img: HTMLImageElement,
  rect: Rect,
  dx: number,
  dy: number,
  dw: number = rect.w,
  dh: number = rect.h
) {
  ctx.drawImage(
    img,
    rect.x,
    rect.y,
    rect.w,
    rect.h,
    Math.round(dx),
    Math.round(dy),
    Math.round(dw),
    Math.round(dh)
  );
}

export function compileLevelTilemap(level: LevelData): CompiledTilemap {
  const cols = Math.ceil(level.width / TILE_SIZE);
  const rows = Math.ceil((level.height + 160) / TILE_SIZE);
  const grid = new Uint8Array(cols * rows);

  const solidPlats = level.platforms.filter((p) => p.type === 'solid');
  const groundPlats = solidPlats
    .filter((p) => p.h >= 64)
    .sort((a, b) => a.x - b.x);

  const mainGroundY = groundPlats.length > 0 ? groundPlats[0].y : 576;
  const bottomRow = Math.min(rows - 1, Math.floor((mainGroundY + 144) / TILE_SIZE));

  for (const plat of solidPlats) {
    const startCol = Math.max(0, Math.floor(plat.x / TILE_SIZE));
    const endCol = Math.min(cols - 1, Math.floor((plat.x + plat.w - 1) / TILE_SIZE));
    const startRow = Math.max(0, Math.floor(plat.y / TILE_SIZE));
    const isGroundOrHill = plat.h >= 64 || plat.y + plat.h >= mainGroundY;
    const endRow = isGroundOrHill
      ? bottomRow
      : Math.min(rows - 1, Math.floor((plat.y + plat.h - 1) / TILE_SIZE));

    const cellType = plat.style === 'rock' ? 2 : 1;

    for (let r = startRow; r <= endRow; r++) {
      for (let c = startCol; c <= endCol; c++) {
        if (grid[r * cols + c] === 0 || r === startRow) {
          grid[r * cols + c] = cellType;
        }
      }
    }
  }

  const riverGaps: RiverGap[] = [];
  for (let i = 0; i < groundPlats.length - 1; i++) {
    const leftPlat = groundPlats[i];
    const rightPlat = groundPlats[i + 1];
    const gapStartPx = leftPlat.x + leftPlat.w;
    const gapEndPx = rightPlat.x;

    if (gapEndPx - gapStartPx >= 32) {
      const startCol = Math.floor(gapStartPx / TILE_SIZE);
      const endCol = Math.floor((gapEndPx - 1) / TILE_SIZE);
      const baseSurfaceY = Math.max(leftPlat.y, rightPlat.y);
      const surfaceRow = Math.floor(baseSurfaceY / TILE_SIZE) + 1;
      const riverbedTopRow = surfaceRow + 3;

      riverGaps.push({
        id: `river_${i}`,
        startCol,
        endCol,
        surfaceRow,
        bottomRow: riverbedTopRow,
      });

      for (let r = riverbedTopRow; r <= bottomRow; r++) {
        for (let c = Math.max(0, startCol - 1); c <= Math.min(cols - 1, endCol + 1); c++) {
          if (grid[r * cols + c] === 0) {
            grid[r * cols + c] = leftPlat.style === 'rock' ? 2 : 1;
          }
        }
      }
    }
  }

  const accents: { col: number; row: number; variant: number }[] = [];
  for (let r = 1; r < rows - 1; r++) {
    for (let c = 2; c < cols - 2; c++) {
      if (grid[r * cols + c] === 1 && grid[(r - 1) * cols + c] === 0) {
        const hasLeft = grid[r * cols + (c - 1)] > 0;
        const hasRight = grid[r * cols + (c + 1)] > 0;
        if (hasLeft && hasRight && hash2D(c, r) % 7 === 0) {
          accents.push({
            col: c,
            row: r - 1,
            variant: hash2D(c * 3, r * 5) % MUSHROOM_ACCENTS.length,
          });
        }
      }
    }
  }

  return { cols, rows, grid, riverGaps, accents, mainGroundY };
}

export const GENERATED_BOULDER_CROPS = {
  MOSSY_BOULDER: { x: 0, y: 0, w: 64, h: 64 },
  CRYSTAL_CRAG: { x: 64, y: 0, w: 64, h: 64 },
  WAYSTONE_SHRINE: { x: 128, y: 0, w: 64, h: 64 },
  FALLEN_MOSSY_LOG: { x: 192, y: 0, w: 64, h: 64 },
};

export function renderParallaxForest(
  ctx: CanvasRenderingContext2D,
  camX: number,
  viewW: number,
  viewH: number,
  theme: LevelData['theme'],
  screenGroundY: number
) {
  const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
  const darkTree = assetLoader.getCached(ASSET_PATHS.treeDark);
  const greenTree = assetLoader.getCached(ASSET_PATHS.treeGreen);
  const goldenTree = assetLoader.getCached(ASSET_PATHS.treeGolden);
  const redTree = assetLoader.getCached(ASSET_PATHS.treeRed);
  const yellowTree = assetLoader.getCached(ASSET_PATHS.treeYellow);

  const bgVista = assetLoader.getCached(
    theme === 'forest'
      ? ASSET_PATHS.genBgEmerald
      : theme === 'ruins'
      ? ASSET_PATHS.genBgGolden
      : ASSET_PATHS.genBgTwilight
  );

  const horizonY = Math.min(viewH, Math.max(240, screenGroundY + 12));

  // 1. Render custom-generated 16-bit pixel art parallax vista background (640x360)
  if (bgVista) {
    const bgW = 640;
    const scrollX = Math.floor(camX * 0.08) % bgW;
    const firstX = scrollX > 0 ? -scrollX : 0;
    for (let drawX = firstX; drawX < viewW; drawX += bgW) {
      ctx.drawImage(bgVista, 0, 0, bgVista.width, bgVista.height, drawX, 0, bgW, viewH);
    }
  } else {
    const skyGrad = ctx.createLinearGradient(0, 0, 0, viewH);
    if (theme === 'forest') {
      skyGrad.addColorStop(0, '#07191e');
      skyGrad.addColorStop(0.5, '#113338');
      skyGrad.addColorStop(1, '#1c4738');
    } else if (theme === 'ruins') {
      skyGrad.addColorStop(0, '#1c1226');
      skyGrad.addColorStop(0.5, '#3b202c');
      skyGrad.addColorStop(1, '#593424');
    } else {
      skyGrad.addColorStop(0, '#0f071e');
      skyGrad.addColorStop(0.5, '#29102e');
      skyGrad.addColorStop(1, '#42122b');
    }
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, viewW, viewH);
  }

  // 2. Far parallax trees — using verified complete tree crops anchored at horizonY
  const farSheet = theme === 'sanctum' ? redTree || darkTree : darkTree;
  if (farSheet) {
    ctx.save();
    ctx.globalAlpha = 0.52;
    const span = 156;
    const offset = Math.floor(camX * 0.18);
    const startIdx = Math.floor(offset / span) - 1;
    const endIdx = startIdx + Math.ceil(viewW / span) + 3;

    for (let i = startIdx; i <= endIdx; i++) {
      const drawX = Math.round(i * span - offset);
      const crop = PARALLAX_FAR_TREES[Math.abs(i) % PARALLAX_FAR_TREES.length];
      const scale = 0.85;
      const dw = Math.round(crop.w * scale);
      const dh = Math.round(crop.h * scale);
      drawCropped(ctx, farSheet, crop, drawX, horizonY - dh + 8, dw, dh);
    }
    ctx.restore();
  }

  // 3. Mid parallax trees — using verified complete tree crops anchored at horizonY
  const midSheet =
    theme === 'forest'
      ? greenTree
      : theme === 'ruins'
      ? goldenTree || yellowTree
      : redTree || darkTree;
  const midSheetAlt =
    theme === 'forest'
      ? yellowTree
      : theme === 'ruins'
      ? yellowTree || greenTree
      : darkTree;

  if (midSheet) {
    ctx.save();
    ctx.globalAlpha = 0.82;
    const span = 190;
    const offset = Math.floor(camX * 0.36);
    const startIdx = Math.floor(offset / span) - 1;
    const endIdx = startIdx + Math.ceil(viewW / span) + 3;

    for (let i = startIdx; i <= endIdx; i++) {
      const sheet = i % 3 === 0 && midSheetAlt ? midSheetAlt : midSheet;
      const drawX = Math.round(i * span - offset);
      const crop = PARALLAX_MID_TREES[Math.abs(i * 3 + 1) % PARALLAX_MID_TREES.length];
      const scale = 0.92;
      const dw = Math.round(crop.w * scale);
      const dh = Math.round(crop.h * scale);
      drawCropped(ctx, sheet, crop, drawX, horizonY - dh + 10, dw, dh);
    }
    ctx.restore();
  }

  // 4. Near parallax flat-bottomed bushes from Forest-1.png (exact 124x43 crops)
  if (forest1) {
    ctx.save();
    ctx.globalAlpha = 0.9;
    const span = 172;
    const offset = Math.floor(camX * 0.55);
    const startIdx = Math.floor(offset / span) - 1;
    const endIdx = startIdx + Math.ceil(viewW / span) + 3;

    for (let i = startIdx; i <= endIdx; i++) {
      const drawX = Math.round(i * span - offset);
      const bushCrop = FOREST1_BUSH_CROPS[Math.abs(i) % FOREST1_BUSH_CROPS.length];
      drawCropped(ctx, forest1, bushCrop, drawX, horizonY - bushCrop.h + 6);
    }
    ctx.restore();
  }
}

export function renderWorldBackgroundProps(
  ctx: CanvasRenderingContext2D,
  level: LevelData,
  tilemap: CompiledTilemap
) {
  const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
  const forest2 = assetLoader.getCached(ASSET_PATHS.forest2);
  const buildings = assetLoader.getCached(ASSET_PATHS.buildings);
  const greenTree = assetLoader.getCached(ASSET_PATHS.treeGreen);
  const goldenTree = assetLoader.getCached(ASSET_PATHS.treeGolden);
  const redTree = assetLoader.getCached(ASSET_PATHS.treeRed);
  const yellowTree = assetLoader.getCached(ASSET_PATHS.treeYellow);
  const darkTree = assetLoader.getCached(ASSET_PATHS.treeDark);
  const signChars = assetLoader.getCached(ASSET_PATHS.signCharacters);

  // Custom generated standalone 16-bit pixel art landmarks & boulders (no flat tileset seams!)
  const genHollowTree = assetLoader.getCached(ASSET_PATHS.genHollowTree);
  const genMineEntrance = assetLoader.getCached(ASSET_PATHS.genMineEntrance);
  const genWatchtower = assetLoader.getCached(ASSET_PATHS.genWatchtower);
  const genBoulders = assetLoader.getCached(ASSET_PATHS.genBoulders);

  const groundY = tilemap.mainGroundY;
  const time = performance.now() * 0.001;

  // 1. Render World Landmark Trees along solid ground segments using verified complete tree crops
  const primaryTree =
    level.theme === 'forest'
      ? greenTree
      : level.theme === 'ruins'
      ? goldenTree
      : redTree;
  const secondaryTree =
    level.theme === 'forest'
      ? yellowTree
      : level.theme === 'ruins'
      ? yellowTree
      : darkTree;

  if (primaryTree) {
    for (let x = 150; x < level.width - 260; x += 340) {
      const col = Math.floor((x + 44) / TILE_SIZE);
      const groundRow = Math.floor(groundY / TILE_SIZE);
      if (tilemap.grid[groundRow * tilemap.cols + col] === 0) continue;

      const idx = Math.floor(x / 340);
      const sheet = idx % 2 === 0 ? primaryTree : secondaryTree || primaryTree;
      const crop = WORLD_LANDMARK_TREES[idx % WORLD_LANDMARK_TREES.length];
      drawCropped(ctx, sheet, crop, x, groundY - crop.h + 4);

      if (forest2 && idx % 2 === 1) {
        drawCropped(
          ctx,
          forest2,
          FOREST2_CROPS.BEEHIVE_ON_BRANCH,
          x + Math.round(crop.w * 0.58),
          groundY - Math.round(crop.h * 0.55)
        );
      }
    }
  }

  // 2. Render Zone-Specific WorldStructures using our custom-generated standalone 16-bit pixel art landmarks!
  if (level.structures) {
    for (const s of level.structures) {
      ctx.save();

      if (s.type === 'hollow_tree') {
        if (genHollowTree) {
          ctx.drawImage(
            genHollowTree,
            Math.round(s.x - 24),
            Math.round(s.y - genHollowTree.height + 8)
          );
        }
        if (forest1) {
          drawCropped(ctx, forest1, FOREST1_CROPS.MUSHROOM_WIDE_RED, s.x - 28, s.y - 24);
          drawCropped(ctx, forest1, FOREST1_CROPS.MUSHROOM_TALL_ORANGE, s.x + 112, s.y - 31);
        }
      } else if (s.type === 'waterfall' && forest1) {
        // Framed by custom-generated organic mossy boulders & crystal crags
        if (genBoulders) {
          drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.CRYSTAL_CRAG, s.x - 36, s.y - 58);
          drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.MOSSY_BOULDER, s.x + 36, s.y - 58);
        }
        const fallShift = Math.floor(time * 10) % 16;
        drawCropped(ctx, forest1, FOREST1_CROPS.WATERFALL_CHUTE, s.x + 4, s.y - 64, 48, 64);
        drawCropped(ctx, forest1, FOREST1_CROPS.WATERFALL_CHUTE, s.x + 4, s.y, 48, 64);
        ctx.globalAlpha = 0.65;
        ctx.drawImage(
          forest1,
          48,
          208 + fallShift,
          48,
          48,
          Math.round(s.x + 4),
          Math.round(s.y - 48),
          48,
          96
        );
        ctx.globalAlpha = 1;
        drawCropped(ctx, forest1, FOREST1_CROPS.MUSHROOM_TALL_ORANGE, s.x + 84, s.y - 31);
        drawCropped(ctx, forest1, FOREST1_CROPS.CATTAIL_REEDS, s.x - 36, s.y - 25);
      } else if (
        s.type === 'timber_cabin' ||
        s.type === 'watchtower' ||
        s.type === 'stone_fortress'
      ) {
        if (genWatchtower) {
          ctx.drawImage(
            genWatchtower,
            Math.round(s.x),
            Math.round(s.y - genWatchtower.height + 6)
          );
        }
        if (buildings) {
          drawCropped(ctx, buildings, BUILDINGS_CROPS.WOODEN_BARREL, s.x - 16, s.y - 18);
          drawCropped(ctx, buildings, BUILDINGS_CROPS.SUPPLY_LOGS, s.x + 116, s.y - 16);
        }
      } else if (s.type === 'stone_ruins' && genBoulders) {
        drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.WAYSTONE_SHRINE, s.x, s.y - 59);
        drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.CRYSTAL_CRAG, s.x + 56, s.y - 59);
        drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.FALLEN_MOSSY_LOG, s.x - 52, s.y - 59);
      } else if (s.type === 'supply_camp' && buildings) {
        drawCropped(ctx, buildings, BUILDINGS_CROPS.SUPPLY_LOGS, s.x - 48, s.y - 16);
        drawCropped(ctx, buildings, BUILDINGS_CROPS.SCAFFOLD_POST_A, s.x + 6, s.y - 32);
        drawCropped(ctx, buildings, BUILDINGS_CROPS.SCAFFOLD_POST_B, s.x + 42, s.y - 32);
        drawCropped(ctx, buildings, BUILDINGS_CROPS.SCAFFOLD_DECK, s.x + 4, s.y - 44);
        drawCropped(ctx, buildings, BUILDINGS_CROPS.SUPPLY_RACK_FENCE, s.x + 62, s.y - 32);
        drawCropped(ctx, buildings, BUILDINGS_CROPS.WOODEN_BARREL, s.x + 108, s.y - 18);
      } else if (s.type === 'mine_entrance' && genMineEntrance) {
        ctx.drawImage(
          genMineEntrance,
          Math.round(s.x - 16),
          Math.round(s.y - genMineEntrance.height + 6)
        );
      }

      ctx.restore();
    }
  }

  // 3. Render Wooden Bridge BACKGROUND parts (exact LeftEnd & RightEnd posts from scenes/props/wooden_bridge.tscn)
  if (forest1) {
    for (const plat of level.platforms) {
      if (plat.style === 'bridge') {
        drawCropped(ctx, forest1, FOREST1_CROPS.BRIDGE_LEFT_END, plat.x - 4, plat.y - 26);
        drawCropped(
          ctx,
          forest1,
          FOREST1_CROPS.BRIDGE_RIGHT_END,
          plat.x + plat.w - 20,
          plat.y - 26
        );
      }
    }
  }

  // 4. Render custom-generated standalone Mossy Boulders, Crystal Crags & Logs along the forest floor
  if (genBoulders) {
    const floorBoulders: Rect[] = [
      GENERATED_BOULDER_CROPS.MOSSY_BOULDER,
      GENERATED_BOULDER_CROPS.FALLEN_MOSSY_LOG,
      GENERATED_BOULDER_CROPS.CRYSTAL_CRAG,
      GENERATED_BOULDER_CROPS.WAYSTONE_SHRINE,
    ];
    for (let x = 220; x < level.width - 260; x += 380) {
      const col = Math.floor((x + 24) / TILE_SIZE);
      const groundRow = Math.floor(groundY / TILE_SIZE);
      if (tilemap.grid[groundRow * tilemap.cols + col] === 0) continue;

      const boulderCrop = floorBoulders[Math.floor(x / 380) % floorBoulders.length];
      drawCropped(ctx, genBoulders, boulderCrop, x, groundY - boulderCrop.h + 5);
    }
  }

  // 5. Render Entry & Exit Dwarven Mine Portals using custom-generated standalone prop_dwarven_mine_entrance.png
  if (genMineEntrance) {
    if (level.zoneIndex === 2 || level.zoneIndex === 3) {
      ctx.drawImage(genMineEntrance, 0, Math.round(groundY - genMineEntrance.height + 6));
    }

    const gx = level.goalPoint.x;
    ctx.drawImage(
      genMineEntrance,
      Math.round(gx - 48),
      Math.round(groundY - genMineEntrance.height + 6)
    );
    if (genBoulders) {
      drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.MOSSY_BOULDER, gx - 96, groundY - 58);
      drawCropped(ctx, genBoulders, GENERATED_BOULDER_CROPS.CRYSTAL_CRAG, gx + 88, groundY - 58);
    }
    if (signChars) {
      ctx.drawImage(
        signChars,
        240,
        0,
        16,
        16,
        Math.round(gx + 24),
        Math.round(groundY - 82),
        16,
        16
      );
    }
  }
}

export function renderWaterTiles(
  ctx: CanvasRenderingContext2D,
  tilemap: CompiledTilemap
) {
  const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
  if (!forest1) return;

  // Exact river coordinates from scripts/tools/asset_showcase_level.gd:
  // RIVER_SURFACE = (6..9, 14), RIVER_BODY = (6..9, 15), RIVER_DEEP = (6..9, 16)
  const animShift = Math.floor(performance.now() / 280);

  for (const gap of tilemap.riverGaps) {
    for (let c = gap.startCol; c <= gap.endCol; c++) {
      const dx = c * TILE_SIZE;
      const frameCol = RIVER_SURFACE_COLS[(c + animShift) % RIVER_SURFACE_COLS.length];

      // Surface wave row (row 14)
      ctx.drawImage(
        forest1,
        frameCol * 16,
        14 * 16,
        16,
        16,
        dx,
        gap.surfaceRow * TILE_SIZE,
        16,
        16
      );

      // River body row (row 15)
      ctx.drawImage(
        forest1,
        frameCol * 16,
        15 * 16,
        16,
        16,
        dx,
        (gap.surfaceRow + 1) * TILE_SIZE,
        16,
        16
      );

      // Deep water rows (row 16)
      for (let depthOffset = 2; depthOffset <= 3; depthOffset++) {
        ctx.drawImage(
          forest1,
          frameCol * 16,
          16 * 16,
          16,
          16,
          dx,
          (gap.surfaceRow + depthOffset) * TILE_SIZE,
          16,
          16
        );
      }
    }

    // River banks (RIVER_BANK_LEFT at gap.startCol, RIVER_BANK_RIGHT at gap.endCol)
    for (let i = 0; i < RIVER_BANK_LEFT_CELLS.length; i++) {
      const leftCell = RIVER_BANK_LEFT_CELLS[i];
      const rightCell = RIVER_BANK_RIGHT_CELLS[i];
      const dy = (gap.surfaceRow - 1 + i) * TILE_SIZE;
      ctx.drawImage(
        forest1,
        leftCell.x * 16,
        leftCell.y * 16,
        16,
        16,
        gap.startCol * TILE_SIZE,
        dy,
        16,
        16
      );
      ctx.drawImage(
        forest1,
        rightCell.x * 16,
        rightCell.y * 16,
        16,
        16,
        gap.endCol * TILE_SIZE,
        dy,
        16,
        16
      );
    }

    // Standalone cropped lotus pads & cattails on river surface
    const riverLeftX = gap.startCol * TILE_SIZE;
    const riverRightX = (gap.endCol + 1) * TILE_SIZE;
    const surfaceY = gap.surfaceRow * TILE_SIZE;
    drawCropped(ctx, forest1, FOREST1_CROPS.LOTUS_GREEN, riverLeftX + 6, surfaceY - 8);
    if (riverRightX - riverLeftX >= 80) {
      drawCropped(ctx, forest1, FOREST1_CROPS.LOTUS_FLOWER, riverRightX - 34, surfaceY - 12);
    }
  }
}

export function renderGeometryTiles(
  ctx: CanvasRenderingContext2D,
  level: LevelData,
  tilemap: CompiledTilemap
) {
  const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
  const forest2 = assetLoader.getCached(ASSET_PATHS.forest2);
  const buildings = assetLoader.getCached(ASSET_PATHS.buildings);
  const hiveImg = assetLoader.getCached(ASSET_PATHS.hive);
  const innerCorners = assetLoader.getCached(ASSET_PATHS.innerCorners);
  if (!forest1) return;

  const { cols, rows, grid } = tilemap;
  const hasCell = (c: number, r: number): boolean => {
    if (c < 0 || c >= cols) return true;
    if (r < 0) return false;
    if (r >= rows) return true;
    return grid[r * cols + c] > 0;
  };

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const cellType = grid[r * cols + c];
      if (cellType === 0) continue;

      const isRock = cellType === 2;
      const nTop = hasCell(c, r - 1);
      const nBottom = hasCell(c, r + 1);
      const nLeft = hasCell(c - 1, r);
      const nRight = hasCell(c + 1, r);

      const dx = c * TILE_SIZE;
      const dy = r * TILE_SIZE;
      const h = hash2D(c, r);

      if (nTop) {
        let tile = isRock
          ? ROCK_CENTERS[h % ROCK_CENTERS.length]
          : GRASS_CENTERS[h % GRASS_CENTERS.length];

        if (!nBottom) {
          if (!nLeft) tile = isRock ? ROCK_BOTTOM_LEFT : GRASS_BOTTOM_LEFT;
          else if (!nRight) tile = isRock ? ROCK_BOTTOM_RIGHT : GRASS_BOTTOM_RIGHT;
          else
            tile = isRock
              ? ROCK_BOTTOM_MIDS[h % ROCK_BOTTOM_MIDS.length]
              : GRASS_BOTTOM_MIDS[h % GRASS_BOTTOM_MIDS.length];
        } else if (!nLeft) {
          tile = isRock
            ? ROCK_LEFT_WALLS[r % ROCK_LEFT_WALLS.length]
            : GRASS_LEFT_WALLS[r % GRASS_LEFT_WALLS.length];
        } else if (!nRight) {
          tile = isRock
            ? ROCK_RIGHT_WALLS[r % ROCK_RIGHT_WALLS.length]
            : GRASS_RIGHT_WALLS[r % GRASS_RIGHT_WALLS.length];
        }

        ctx.drawImage(
          forest1,
          tile.x * 16,
          tile.y * 16,
          16,
          16,
          dx,
          dy,
          16,
          16
        );
      } else if (isRock) {
        let rTile = ROCK_TOP_MIDS[c % ROCK_TOP_MIDS.length];
        if (!nLeft) rTile = ROCK_TOP_LEFT;
        else if (!nRight) rTile = ROCK_TOP_RIGHT;
        ctx.drawImage(
          forest1,
          rTile.x * 16,
          rTile.y * 16,
          16,
          16,
          dx,
          dy,
          16,
          16
        );
      }
    }
  }

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const cellType = grid[r * cols + c];
      if (cellType === 0) continue;

      const nTop = hasCell(c, r - 1);
      const nLeft = hasCell(c - 1, r);
      const nRight = hasCell(c + 1, r);
      const nTopLeft = hasCell(c - 1, r - 1);
      const nTopRight = hasCell(c + 1, r - 1);

      const dx = c * TILE_SIZE;
      const dy = r * TILE_SIZE;

      if (!nTop && cellType === 1) {
        let topTile = GRASS_TOP_MIDS[c % GRASS_TOP_MIDS.length];
        if (!nLeft) topTile = GRASS_TOP_LEFT;
        else if (!nRight) topTile = GRASS_TOP_RIGHT;

        ctx.drawImage(
          forest1,
          topTile.x * 16,
          topTile.y * 16,
          topTile.w,
          topTile.h,
          dx,
          dy - 8,
          topTile.w,
          topTile.h
        );
      } else if (nTop && innerCorners) {
        if (nLeft && !nTopLeft) {
          ctx.drawImage(
            innerCorners,
            INNER_MISSING_TOP_LEFT.x * 16,
            INNER_MISSING_TOP_LEFT.y * 16,
            16,
            32,
            dx,
            dy - 24,
            16,
            32
          );
        }
        if (nRight && !nTopRight) {
          ctx.drawImage(
            innerCorners,
            INNER_MISSING_TOP_RIGHT.x * 16,
            INNER_MISSING_TOP_RIGHT.y * 16,
            16,
            32,
            dx,
            dy - 24,
            16,
            32
          );
        }
      }
    }
  }

  for (const plat of level.platforms) {
    if (plat.type === 'one-way' || plat.type === 'crumbly') {
      if (plat.style === 'mushroom_shelf' && forest2) {
        renderMushroomPlatform(ctx, forest2, plat);
      } else if (plat.style === 'stone_ledge') {
        renderStoneRuinPlatform(ctx, forest1, plat);
      } else if (plat.style === 'timber_scaffold' && buildings) {
        renderTimberScaffoldPlatform(ctx, buildings, plat);
      } else {
        renderFlushWoodenBridge(ctx, forest1, plat);
      }
    } else if (plat.type === 'hazard') {
      // Render cropped spike strip from Hive.png (0, 121, 48, 24) or thorn_hazard.tscn polygon
      if (hiveImg) {
        for (let ox = 0; ox < plat.w; ox += 48) {
          const segW = Math.min(48, plat.w - ox);
          ctx.drawImage(
            hiveImg,
            HIVE_CROPS.SPIKE_STRIP.x,
            HIVE_CROPS.SPIKE_STRIP.y,
            segW,
            HIVE_CROPS.SPIKE_STRIP.h,
            Math.round(plat.x + ox),
            Math.round(plat.y - 6),
            segW,
            20
          );
        }
      } else {
        const colsCount = Math.max(1, Math.floor(plat.w / 16));
        ctx.fillStyle = '#94ad38';
        for (let i = 0; i < colsCount; i++) {
          const hx = plat.x + i * 16;
          ctx.beginPath();
          ctx.moveTo(hx + 2, plat.y + 12);
          ctx.lineTo(hx + 8, plat.y - 2);
          ctx.lineTo(hx + 14, plat.y + 12);
          ctx.fill();
        }
      }
    }
  }
}

function renderMushroomPlatform(
  ctx: CanvasRenderingContext2D,
  forest2: HTMLImageElement,
  plat: Platform
) {
  // Exact standalone mossy branch ledge from Forest-2.png (164, 187, 75, 16)
  const branch = FOREST2_CROPS.MOSSY_BRANCH_LEDGE;
  for (let ox = 0; ox < plat.w; ox += 70) {
    const segW = Math.min(branch.w, plat.w - ox);
    ctx.drawImage(
      forest2,
      branch.x,
      branch.y,
      segW,
      branch.h,
      Math.round(plat.x + ox),
      Math.round(plat.y - 1),
      segW,
      branch.h
    );
  }
}

function renderStoneRuinPlatform(
  ctx: CanvasRenderingContext2D,
  forest1: HTMLImageElement,
  plat: Platform
) {
  // Exact standalone 3-block carved stone floating platform from Forest-1.png (194, 238, 45, 17)
  const ledge = FOREST1_CROPS.STONE_FLOATING_LEDGE;
  for (let ox = 0; ox < plat.w; ox += 44) {
    const segW = Math.min(ledge.w, plat.w - ox);
    ctx.drawImage(
      forest1,
      ledge.x,
      ledge.y,
      segW,
      ledge.h,
      Math.round(plat.x + ox),
      Math.round(plat.y - 1),
      segW,
      ledge.h
    );
  }
}

function renderTimberScaffoldPlatform(
  ctx: CanvasRenderingContext2D,
  buildings: HTMLImageElement,
  plat: Platform
) {
  // Exact standalone scaffold deck from Buildings.png (0, 93, 48, 14) + support posts (213, 192, 6, 32)
  const postA = BUILDINGS_CROPS.SCAFFOLD_POST_A;
  const postB = BUILDINGS_CROPS.SCAFFOLD_POST_B;
  const deck = BUILDINGS_CROPS.SCAFFOLD_DECK;
  drawCropped(ctx, buildings, postA, plat.x + 6, plat.y + 10);
  drawCropped(ctx, buildings, postB, plat.x + plat.w - 16, plat.y + 10);
  for (let ox = 0; ox < plat.w; ox += 46) {
    const segW = Math.min(deck.w, plat.w - ox);
    ctx.drawImage(
      buildings,
      deck.x,
      deck.y,
      segW,
      deck.h,
      Math.round(plat.x + ox),
      Math.round(plat.y - 1),
      segW,
      deck.h
    );
  }
}

function renderFlushWoodenBridge(
  ctx: CanvasRenderingContext2D,
  forest1: HTMLImageElement,
  plat: Platform
) {
  // Exact Middle plank deck from scenes/props/wooden_bridge.tscn: Forest-1.png Rect2(177, 94, 46, 12)
  // Top walking surface is flush with plat.y so enemies & player never clip!
  const mid = FOREST1_CROPS.BRIDGE_MIDDLE;
  for (let ox = 0; ox < plat.w; ox += 44) {
    const segW = Math.min(mid.w, plat.w - ox);
    ctx.drawImage(
      forest1,
      mid.x,
      mid.y,
      segW,
      mid.h,
      Math.round(plat.x + ox),
      Math.round(plat.y),
      segW,
      mid.h
    );
  }
}

export function renderForegroundAccents(
  ctx: CanvasRenderingContext2D,
  tilemap: CompiledTilemap
) {
  const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
  if (!forest1) return;

  for (const acc of tilemap.accents) {
    const src = MUSHROOM_ACCENTS[acc.variant % MUSHROOM_ACCENTS.length];
    ctx.drawImage(
      forest1,
      src.x * 16,
      src.y * 16,
      16,
      16,
      acc.col * TILE_SIZE,
      acc.row * TILE_SIZE,
      16,
      16
    );
  }
}
