import React, { useState } from 'react';
import { CharacterColor, LevelData, SaveSlotData } from '../types/game';
import { getAllSaveSlots } from '../data/gameData';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { SpritePreview } from './SpritePreview';
import { Play, Code, Sword, Shield, Volume2, VolumeX, Sparkles, BookOpen, Layers, Globe, Image as ImageIcon } from 'lucide-react';
import { soundManager } from '../audio/soundManager';

interface TitleScreenProps {
  onStartGame: (color: CharacterColor, levelId: number | string, slotId: number) => void;
  onLoadSave: (saveData: SaveSlotData) => void;
  onOpenArchitecture: () => void;
  levels: LevelData[];
  isMuted: boolean;
  onToggleMute: () => void;
  language: Language;
  onToggleLanguage: () => void;
}

export const TitleScreen: React.FC<TitleScreenProps> = ({
  onStartGame,
  onLoadSave,
  onOpenArchitecture,
  levels,
  isMuted,
  onToggleMute,
  language,
  onToggleLanguage
}) => {
  const [selectedColor, setSelectedColor] = useState<CharacterColor>('blue');
  const [selectedLevelId, setSelectedLevelId] = useState<string>(levels[0]?.id ?? 'level_1');
  const [activeView, setActiveView] = useState<'main' | 'new_game' | 'load_game' | 'controls' | 'art_gallery'>('main');
  const [saveSlots, setSaveSlots] = useState<(SaveSlotData | null)[]>(() => getAllSaveSlots());

  const t = TRANSLATIONS[language];

  const colors: { id: CharacterColor; label: string; previewRow: number }[] = [
    { id: 'blue', label: t.azureKnight, previewRow: 0 },
    { id: 'red', label: t.crimsonVanguard, previewRow: 0 },
    { id: 'green', label: t.verdantRanger, previewRow: 0 },
    { id: 'purple', label: t.shadowblade, previewRow: 0 }
  ];

  const refreshSaveSlots = () => {
    setSaveSlots(getAllSaveSlots());
  };

  return (
    <div className="relative w-full min-h-screen bg-slate-950 flex flex-col items-center justify-center p-4 overflow-hidden">
      {/* Background Ambience */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-blue-950/40 via-slate-950 to-slate-950 pointer-events-none" />
      <div className="absolute inset-0 crt-overlay opacity-50 pointer-events-none" />

      {/* Top Controls: Language & Audio */}
      <div className="absolute top-4 right-4 flex items-center space-x-2 z-20">
        {/* Language Toggle */}
        <button
          onClick={onToggleLanguage}
          className="px-3 py-1.5 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-700 text-xs font-pixel text-amber-300 flex items-center space-x-1.5 shadow transition"
          title="Switch Language / 切换语言"
        >
          <Globe className="w-3.5 h-3.5" />
          <span>{language === 'zh' ? '中文' : 'EN'}</span>
        </button>

        {/* Audio Toggle */}
        <button
          onClick={onToggleMute}
          className="p-2 rounded-lg bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 hover:text-white transition"
          title={isMuted ? t.soundMuted : t.soundOn}
        >
          {isMuted ? <VolumeX className="w-4 h-4 text-rose-400" /> : <Volume2 className="w-4 h-4 text-emerald-400" />}
        </button>
      </div>

      {/* Main Content Box */}
      <div className="relative z-10 w-full max-w-2xl text-center space-y-6 py-4">
        {/* Game Title & Header */}
        <div className="space-y-2">
          <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-amber-950/80 border border-amber-600/40 text-[10px] font-pixel text-amber-300">
            <Sparkles className="w-3 h-3" />
            <span>{t.subtitle}</span>
          </div>

          <h1 className="font-fantasy text-4xl sm:text-5xl font-black text-transparent bg-clip-text bg-gradient-to-r from-amber-200 via-amber-400 to-amber-600 tracking-wider drop-shadow-[0_5px_15px_rgba(245,158,11,0.3)]">
            {t.gameTitle}
          </h1>

          <p className="text-xs sm:text-sm text-slate-300 max-w-lg mx-auto">
            {t.tagline}
          </p>
        </div>

        {/* Active View: Main Menu */}
        {activeView === 'main' && (
          <div className="space-y-3 max-w-sm mx-auto">
            {/* Live Hero Display from art/imported */}
            <div className="bg-slate-900/60 border border-slate-800/80 rounded-2xl p-3 flex items-center justify-center space-x-6">
              <div className="flex flex-col items-center">
                <SpritePreview
                  sheetSrc="/art/imported/Generic-Character/png/blue/char_blue_1.png"
                  frameW={56}
                  frameH={56}
                  row={0}
                  frameCount={6}
                  fps={7}
                  scale={1.5}
                />
                <span className="text-[9px] font-pixel text-blue-400 mt-1">Warrior</span>
              </div>

              <div className="flex flex-col items-center">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Fly/Fly-Sheet.png"
                  frameW={64}
                  frameH={64}
                  row={0}
                  frameCount={4}
                  fps={8}
                  scale={1.2}
                />
                <span className="text-[9px] font-pixel text-amber-400 mt-1">Forest Bee</span>
              </div>

              <div className="flex flex-col items-center">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Hit-Vanish/Hit-Sheet-Black.png"
                  frameW={48}
                  frameH={32}
                  row={0}
                  frameCount={4}
                  fps={6}
                  scale={1.5}
                />
                <span className="text-[9px] font-pixel text-stone-400 mt-1">Wild Boar</span>
              </div>
            </div>

            <button
              onClick={() => {
                soundManager.playParry();
                setActiveView('new_game');
              }}
              className="w-full py-3.5 bg-gradient-to-r from-amber-600 to-amber-700 hover:from-amber-500 hover:to-amber-600 text-slate-950 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 font-bold transition shadow-lg shadow-amber-600/20 active:scale-[0.98]"
            >
              <Play className="w-4 h-4 fill-current" />
              <span>{t.startAdventure}</span>
            </button>

            <button
              onClick={() => {
                soundManager.playParry();
                refreshSaveSlots();
                setActiveView('load_game');
              }}
              className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-slate-200 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-slate-800 transition active:scale-[0.98]"
            >
              <Shield className="w-4 h-4 text-sky-400" />
              <span>{t.continueGame}</span>
            </button>

            <button
              onClick={() => {
                soundManager.playParry();
                setActiveView('controls');
              }}
              className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-slate-200 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-slate-800 transition active:scale-[0.98]"
            >
              <BookOpen className="w-4 h-4 text-emerald-400" />
              <span>{t.howToPlay}</span>
            </button>

            <button
              onClick={() => {
                soundManager.playParry();
                setActiveView('art_gallery');
              }}
              className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-slate-200 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-slate-800 transition active:scale-[0.98]"
            >
              <ImageIcon className="w-4 h-4 text-amber-400" />
              <span>{language === 'zh' ? 'ART 原生美术画廊' : 'ART SPRITE GALLERY'}</span>
            </button>

            <button
              onClick={() => {
                soundManager.playParry();
                onOpenArchitecture();
              }}
              className="w-full py-3 bg-indigo-950/70 hover:bg-indigo-900 text-indigo-300 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-indigo-700/50 transition active:scale-[0.98]"
            >
              <Code className="w-4 h-4 text-indigo-400" />
              <span>{t.gdunitInspector}</span>
            </button>
          </div>
        )}

        {/* View: New Game & Character Customization with LIVE SPRITE PREVIEW */}
        {activeView === 'new_game' && (
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 text-left space-y-6 shadow-2xl">
            <h3 className="font-fantasy text-xl font-bold text-slate-100 flex items-center space-x-2">
              <Sword className="w-5 h-5 text-amber-400" />
              <span>{t.chooseChampion}</span>
            </h3>

            {/* Character Palette with REAL SPRITE ANIMATION */}
            <div className="space-y-3">
              <label className="text-xs font-pixel text-slate-400">{t.armorColor}</label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {colors.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => {
                      setSelectedColor(c.id);
                      soundManager.playParry();
                    }}
                    className={`p-3 rounded-xl border flex flex-col items-center space-y-2 transition ${
                      selectedColor === c.id
                        ? 'border-amber-400 bg-slate-800 shadow-md ring-2 ring-amber-500/50'
                        : 'border-slate-800 bg-slate-950/60 hover:border-slate-700'
                    }`}
                  >
                    <div className="h-16 flex items-center justify-center">
                      <SpritePreview
                        sheetSrc={`/art/imported/Generic-Character/png/${c.id}/char_${c.id}_1.png`}
                        frameW={56}
                        frameH={56}
                        row={0}
                        frameCount={6}
                        fps={8}
                        scale={1.3}
                      />
                    </div>
                    <span className="text-[10px] font-pixel text-slate-200 text-center">{c.label}</span>
                  </button>
                ))}
              </div>
            </div>

            {/* Stage Select: 3 Distinct Interconnected Biome Zones */}
            <div className="space-y-2">
              <label className="text-xs font-pixel text-slate-400">{t.chooseChapter}</label>
              <div className="space-y-2">
                {levels.map((lvl) => {
                  const zoneFeatures =
                    lvl.zoneIndex === 1
                      ? 'Forest-2.png 空心巨树 · 蘑菇跳台 · Forest-1.png 飞流瀑布 · 可破坏苔石'
                      : lvl.zoneIndex === 2
                      ? 'Buildings.png 木屋与瞭望塔 · 木梯攀爬 · Golden-Tree.png 金叶林 · 石砌拱门'
                      : 'Buildings.png 绯红石木要塞 · 岩壁地形 · Red-Tree.png 暗夜林 · 森林守护者 Boss';
                  return (
                    <button
                      key={lvl.id}
                      onClick={() => {
                        setSelectedLevelId(lvl.id);
                        soundManager.playParry();
                      }}
                      className={`w-full p-3 rounded-xl border text-left flex items-center justify-between transition ${
                        selectedLevelId === lvl.id
                          ? 'border-amber-500/80 bg-amber-950/30 ring-1 ring-amber-500/40'
                          : 'border-slate-800 bg-slate-950/60 hover:border-slate-700'
                      }`}
                    >
                      <div>
                        <div className="font-bold text-sm text-slate-200">{lvl.name}</div>
                        <div className="text-[11px] text-slate-400">{lvl.chapter}</div>
                        <div className="text-[10px] text-emerald-400/90 mt-0.5">{zoneFeatures}</div>
                      </div>
                      <span className="text-[9px] font-pixel text-amber-400 uppercase">{lvl.theme}</span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="flex space-x-3 pt-2">
              <button
                onClick={() => setActiveView('main')}
                className="w-1/3 py-2.5 bg-slate-800 text-slate-300 text-xs font-pixel rounded-xl hover:bg-slate-700 transition"
              >
                {t.back}
              </button>
              <button
                onClick={() => {
                  soundManager.playLevelUp();
                  onStartGame(selectedColor, selectedLevelId, 1);
                }}
                className="w-2/3 py-2.5 bg-gradient-to-r from-amber-600 to-amber-700 text-slate-950 text-xs font-pixel font-bold rounded-xl hover:from-amber-500 hover:to-amber-600 transition shadow-lg shadow-amber-600/30"
              >
                {t.enterRealm}
              </button>
            </div>
          </div>
        )}

        {/* View: Art Gallery */}
        {activeView === 'art_gallery' && (
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 text-left space-y-4 shadow-2xl">
            <h3 className="font-fantasy text-xl font-bold text-slate-100 flex items-center space-x-2">
              <ImageIcon className="w-5 h-5 text-amber-400" />
              <span>{t.artAssetsTitle}</span>
            </h3>
            <p className="text-xs text-slate-300 leading-relaxed">{t.artNotice}</p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 max-h-[55vh] overflow-y-auto pr-1">
              {/* Warrior Idle */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Generic-Character/png/blue/char_blue_1.png"
                  frameW={56}
                  frameH={56}
                  row={0}
                  frameCount={6}
                  fps={8}
                  scale={1.4}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-blue-300">Warrior: Idle & Run</h4>
                  <p className="text-[10px] text-slate-400">char_blue_1.png (Row 0 & Row 2)</p>
                </div>
              </div>

              {/* Warrior Climb & Dash */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Generic-Character/png/blue/char_blue_2.png"
                  frameW={56}
                  frameH={56}
                  row={6}
                  frameCount={8}
                  fps={8}
                  scale={1.4}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-purple-300">Warrior: Ladder Climb & Dash</h4>
                  <p className="text-[10px] text-slate-400">char_blue_2.png (Row 6 Climb, Row 2 Dash)</p>
                </div>
              </div>

              {/* Map Assets: Forest-1.png Rule Tileset & Waterfall */}
              <div className="bg-slate-950 p-3 rounded-xl border border-emerald-500/40 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png"
                  frameW={16}
                  frameH={32}
                  row={0}
                  frameCount={5}
                  fps={2}
                  scale={1.8}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-emerald-300">Forest-1.png (Grass & Rock Rules)</h4>
                  <p className="text-[10px] text-slate-400">Terrain Set 0 + Waterfall + Stone Ruins + Lotus/Reeds</p>
                </div>
              </div>

              {/* Custom Generated 16-Bit Pixel Art: Ancient Hollow Shrine Tree */}
              <div className="bg-slate-950 p-3 rounded-xl border border-emerald-500/40 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/generated/prop_ancient_hollow_tree.png"
                  frameW={64}
                  frameH={64}
                  regions={[{ x: 0, y: 0, w: 160, h: 192 }]}
                  fps={1}
                  scale={1}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-emerald-300">Ancient Hollow Shrine Tree (Generated)</h4>
                  <p className="text-[10px] text-slate-400">Custom 16-bit Pixel Art Landmark with Shelf Mushrooms & Beehive</p>
                </div>
              </div>

              {/* Custom Generated 16-Bit Pixel Art: Ranger Timber Watchtower */}
              <div className="bg-slate-950 p-3 rounded-xl border border-amber-500/40 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/generated/prop_forest_watchtower.png"
                  frameW={64}
                  frameH={64}
                  regions={[{ x: 0, y: 0, w: 128, h: 160 }]}
                  fps={1}
                  scale={1}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-amber-300">Ranger Timber Watchtower (Generated)</h4>
                  <p className="text-[10px] text-slate-400">Custom 16-bit Stone & Timber Outpost Tower with Shingled Roof</p>
                </div>
              </div>

              {/* Custom Generated 16-Bit Pixel Art: Dwarven Mine Cave Entrance */}
              <div className="bg-slate-950 p-3 rounded-xl border border-emerald-500/40 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/generated/prop_dwarven_mine_entrance.png"
                  frameW={64}
                  frameH={56}
                  regions={[{ x: 0, y: 0, w: 160, h: 128 }]}
                  fps={1}
                  scale={1}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-emerald-300">Dwarven Mine Cave Portal (Generated)</h4>
                  <p className="text-[10px] text-slate-400">Custom 16-bit Crag Cave Archway with Cyan Crystals & Lantern</p>
                </div>
              </div>

              {/* Custom Generated 16-Bit Pixel Art: Mossy Boulders, Crystal Crag & Waystone */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/generated/prop_mossy_boulders.png"
                  frameW={64}
                  frameH={64}
                  row={0}
                  frameCount={4}
                  fps={1.4}
                  scale={1}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-amber-300">Organic Boulders & Waystone (Generated)</h4>
                  <p className="text-[10px] text-slate-400">Mossy Boulder, Crystal Crag, Elven Waystone Shrine & Hollow Log</p>
                </div>
              </div>

              {/* Forest Snail: walk-Sheet.png */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Enemies/Snail/walk-Sheet.png"
                  frameW={48}
                  frameH={32}
                  row={0}
                  frameCount={8}
                  fps={7}
                  scale={1.4}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-teal-300">Forest Snail: Walk & Hide</h4>
                  <p className="text-[10px] text-slate-400">Enemies/Snail/walk-Sheet.png & Hide-Sheet.png (48x32)</p>
                </div>
              </div>

              {/* Small Bee Fly */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/Fly/Fly-Sheet.png"
                  frameW={64}
                  frameH={64}
                  row={0}
                  frameCount={4}
                  fps={8}
                  scale={1.2}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-amber-300">Small Bee: Flight & Attack</h4>
                  <p className="text-[10px] text-slate-400">Fly-Sheet.png & Attack-Sheet.png (4 frames, 64x64)</p>
                </div>
              </div>

              {/* Dark Tree Boar Walk & Run */}
              <div className="bg-slate-950 p-3 rounded-xl border border-slate-800 flex items-center space-x-4">
                <SpritePreview
                  sheetSrc="/art/imported/Legacy-Fantasy-High Forest/Enemies/Small Bee/MapAssets/Dark_Tree/Boar/Run/Run-Sheet.png"
                  frameW={48}
                  frameH={32}
                  row={0}
                  frameCount={6}
                  fps={10}
                  scale={1.5}
                />
                <div>
                  <h4 className="font-pixel text-[11px] text-stone-300">Wild Boar: Walk / Charge / Hit</h4>
                  <p className="text-[10px] text-slate-400">Idle-Sheet, Walk-Base-Sheet, Run-Sheet (48x32)</p>
                </div>
              </div>
            </div>

            <button
              onClick={() => setActiveView('main')}
              className="w-full py-2.5 bg-slate-800 text-slate-300 text-xs font-pixel rounded-xl hover:bg-slate-700 transition"
            >
              {t.back}
            </button>
          </div>
        )}

        {/* View: Load Game (ISaveable Slots) */}
        {activeView === 'load_game' && (
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 text-left space-y-4 shadow-2xl">
            <h3 className="font-fantasy text-xl font-bold text-slate-100 flex items-center space-x-2">
              <Shield className="w-5 h-5 text-sky-400" />
              <span>{t.continueGame}</span>
            </h3>

            <div className="space-y-3">
              {[1, 2, 3].map((slotNum) => {
                const slot = saveSlots[slotNum - 1];
                return (
                  <div
                    key={slotNum}
                    className="p-4 rounded-xl border border-slate-800 bg-slate-950/80 flex items-center justify-between"
                  >
                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="font-pixel text-xs text-amber-400">SLOT {slotNum}</span>
                        {slot && (
                          <span className="text-[10px] text-slate-400">
                            {t.levelLabel} {slot.stats.level} | {slot.stats.gold}G
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-400 mt-1">
                        {slot
                          ? `${t.savedAt}: ${new Date(slot.timestamp).toLocaleDateString()} ${new Date(
                              slot.timestamp
                            ).toLocaleTimeString()}`
                          : t.emptySlot}
                      </p>
                    </div>

                    {slot ? (
                      <button
                        onClick={() => {
                          soundManager.playParry();
                          onLoadSave(slot);
                        }}
                        className="px-4 py-2 bg-sky-600 hover:bg-sky-500 text-white font-pixel text-xs rounded-lg transition"
                      >
                        {t.loadSlot}
                      </button>
                    ) : (
                      <button
                        onClick={() => {
                          soundManager.playLevelUp();
                          onStartGame(selectedColor, 1, slotNum);
                        }}
                        className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 font-pixel text-xs rounded-lg transition"
                      >
                        {t.newSlot}
                      </button>
                    )}
                  </div>
                );
              })}
            </div>

            <button
              onClick={() => setActiveView('main')}
              className="w-full py-2.5 bg-slate-800 text-slate-300 text-xs font-pixel rounded-xl hover:bg-slate-700 transition"
            >
              {t.back}
            </button>
          </div>
        )}

        {/* View: Controls Guide */}
        {activeView === 'controls' && (
          <div className="bg-slate-900/90 border border-slate-800 rounded-2xl p-6 text-left space-y-4 shadow-2xl">
            <h3 className="font-fantasy text-xl font-bold text-slate-100 flex items-center space-x-2">
              <Layers className="w-5 h-5 text-emerald-400" />
              <span>{t.controlsGuideTitle}</span>
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-amber-400">MOVE (移动)</div>
                <div className="text-slate-200 mt-1">{t.moveDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-emerald-400">JUMP (跳跃)</div>
                <div className="text-slate-200 mt-1">{t.jumpDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-rose-400">ATTACK (斩击连招)</div>
                <div className="text-slate-200 mt-1">{t.attackDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-sky-400">DASH (冲刺突进)</div>
                <div className="text-slate-200 mt-1">{t.dashDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-purple-400">SKILL (战意技能)</div>
                <div className="text-slate-200 mt-1">{t.skillDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-cyan-400">BLOCK (盾牌格挡)</div>
                <div className="text-slate-200 mt-1">{t.blockDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-rose-400">POTION (喝药水)</div>
                <div className="text-slate-200 mt-1">{t.potionDesc}</div>
              </div>
              <div className="p-3 bg-slate-950 rounded-lg border border-slate-800">
                <div className="font-pixel text-[10px] text-amber-400">INTERACT (互动)</div>
                <div className="text-slate-200 mt-1">{t.interactDesc}</div>
              </div>
            </div>

            <button
              onClick={() => setActiveView('main')}
              className="w-full py-2.5 bg-slate-800 text-slate-300 text-xs font-pixel rounded-xl hover:bg-slate-700 transition"
            >
              {t.back}
            </button>
          </div>
        )}

        {/* Footer Credit */}
        <div className="text-[11px] text-slate-500 font-mono">
          Legend of the Warrior • Godot 4.7 Architecture • GdUnit4 v6.1.3
        </div>
      </div>
    </div>
  );
};
