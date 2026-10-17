import { CharacterColor } from '../types/game';

export const ASSET_PATHS = {
  forest1: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png',
  forest2: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-2.png',
  innerCorners: '/art/runtime/derived/terrain/forest_ground_inner_corners.png',
  treeGreen: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Green-Tree.png',
  treeDark: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Dark-Tree.png',
  treeGolden: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Golden-Tree.png',
  treeYellow: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Yellow-Tree.png',
  treeRed: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Trees/Red-Tree.png',
  chest: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Chest.png',
  chest2: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Chest2.png',
  propsRocks: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Props-Rocks.png',
  mineStone: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Mine Stone.png',
  buildings: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Buildings.png',
  hive: '/art/imported/Legacy-Fantasy-High Forest/Map Assets/Hive.png',
  baseUi: '/art/imported/Legacy-Fantasy-High Forest/HUD/Base-UI.png',
  gameButtons: '/art/imported/Legacy-Fantasy-High Forest/HUD/GameButtons.png',
  signCharacters: '/art/imported/Legacy-Fantasy-High Forest/HUD/SignCharacters.png',
  beeFly: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Fly/Fly-Sheet.png',
  beeAttack: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Attack/Attack-Sheet.png',
  beeHit: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Hit/Hit-Sheet.png',
  boarIdle: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Idle/Idle-Sheet.png',
  boarIdleWhite: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Idle/Idle-Sheet-White.png',
  boarWalk: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Walk/Walk-Base-Sheet.png',
  boarWalkBlack: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Walk/Walk-Base-SheetBlack.png',
  boarWalkWhite: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Walk/Walk-Base-Sheet-White.png',
  boarRun: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Run/Run-Sheet.png',
  boarRunBlack: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Run/Run-Sheet-Black.png',
  boarRunWhite: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Run/Run-Sheet-White.png',
  boarHit: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Hit-Vanish/Hit-Sheet.png',
  boarHitBlack: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Hit-Vanish/Hit-Sheet-Black.png',
  boarHitWhite: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Hit-Vanish/Hit-Sheet-White.png',
  snailWalk: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/walk-Sheet.png',
  snailHide: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/Hide-Sheet.png',
  snailDead: '/art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/Dead-Sheet.png',
  // Custom generated 16-bit pixel art landmarks, boulders & parallax vistas
  genHollowTree: '/art/generated/prop_ancient_hollow_tree.png',
  genMineEntrance: '/art/generated/prop_dwarven_mine_entrance.png',
  genWatchtower: '/art/generated/prop_forest_watchtower.png',
  genBoulders: '/art/generated/prop_mossy_boulders.png',
  genBgEmerald: '/art/generated/bg_emerald_forest.png',
  genBgGolden: '/art/generated/bg_golden_groves.png',
  genBgTwilight: '/art/generated/bg_twilight_sanctuary.png',
};

class AssetLoader {
  private cache: Map<string, HTMLImageElement> = new Map();
  private loadingPromises: Map<string, Promise<HTMLImageElement>> = new Map();
  public currentColor: CharacterColor = 'blue';

  public loadAsset(src: string): Promise<HTMLImageElement> {
    const cached = this.cache.get(src);
    if (cached && cached.complete && cached.naturalWidth > 0) {
      return Promise.resolve(cached);
    }

    if (this.loadingPromises.has(src)) {
      return this.loadingPromises.get(src)!;
    }

    const promise = new Promise<HTMLImageElement>((resolve) => {
      const img = new Image();
      img.src = src;
      img.onload = () => {
        this.cache.set(src, img);
        this.loadingPromises.delete(src);
        resolve(img);
      };
      img.onerror = () => {
        console.warn(`[AssetLoader] Could not load ${src}`);
        this.loadingPromises.delete(src);
        resolve(img);
      };
    });

    this.loadingPromises.set(src, promise);
    return promise;
  }

  public async preloadAll(color: CharacterColor = 'blue'): Promise<void> {
    this.currentColor = color;
    const allPaths = [
      `/art/imported/Generic-Character/png/${color}/char_${color}_1.png`,
      `/art/imported/Generic-Character/png/${color}/char_${color}_2.png`,
      `/art/imported/Generic-Character/png/purple/char_purple_1.png`,
      `/art/imported/Generic-Character/png/red/char_red_1.png`,
      ...Object.values(ASSET_PATHS),
    ];
    await Promise.all(allPaths.map((p) => this.loadAsset(p)));
  }

  public getCached(src: string): HTMLImageElement | null {
    const img = this.cache.get(src);
    if (img && img.complete && img.naturalWidth > 0) {
      return img;
    }
    this.loadAsset(src);
    return null;
  }
}

export const assetLoader = new AssetLoader();
