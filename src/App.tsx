import React, { useState } from 'react';
import { CharacterColor, Equipment, Item, LevelData, PlayerStats, SaveSlotData } from './types/game';
import { GAME_ITEMS, INITIAL_STATS, LEVELS, writeSaveSlot } from './data/gameData';
import { Language } from './i18n/translations';
import { TitleScreen } from './components/TitleScreen';
import { GameCanvas } from './engine/GameCanvas';
import { HUD } from './components/HUD';
import { PauseMenu } from './components/PauseMenu';
import { InventoryModal } from './components/InventoryModal';
import { SkillTreeModal } from './components/SkillTreeModal';
import { GodotArchitectureModal } from './components/GodotArchitectureModal';
import { VictoryModal } from './components/VictoryModal';
import { GameOverModal } from './components/GameOverModal';
import { soundManager } from './audio/soundManager';

export const App: React.FC = () => {
  // Game lifecycle
  const [gameState, setGameState] = useState<'title' | 'playing' | 'gameover' | 'victory'>('title');
  const [currentLevelIndex, setCurrentLevelIndex] = useState<number>(0);
  const [characterColor, setCharacterColor] = useState<CharacterColor>('blue');
  const [activeSlotId, setActiveSlotId] = useState<number>(1);

  // Language state (defaults to 'zh' with localStorage persistence)
  const [language, setLanguage] = useState<Language>(() => {
    const saved = localStorage.getItem('legend_warrior_lang');
    return (saved === 'en' || saved === 'zh') ? saved : 'zh';
  });

  const toggleLanguage = () => {
    setLanguage((prev) => {
      const next: Language = prev === 'zh' ? 'en' : 'zh';
      localStorage.setItem('legend_warrior_lang', next);
      return next;
    });
  };

  // Audio & Display
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [showScanlines, setShowScanlines] = useState<boolean>(true);

  // Stats, inventory, equipment
  const [stats, setStats] = useState<PlayerStats>({ ...INITIAL_STATS });
  const [equipment, setEquipment] = useState<Equipment>({
    weapon: GAME_ITEMS[0],
    armor: GAME_ITEMS[3],
    accessory: null
  });
  const [inventory, setInventory] = useState<Item[]>([GAME_ITEMS[0], GAME_ITEMS[3], GAME_ITEMS[6]]);

  // Modals
  const [isPaused, setIsPaused] = useState<boolean>(false);
  const [isInventoryOpen, setIsInventoryOpen] = useState<boolean>(false);
  const [isSkillsOpen, setIsSkillsOpen] = useState<boolean>(false);
  const [isArchitectureOpen, setIsArchitectureOpen] = useState<boolean>(false);

  // Checkpoints & Progress tracking
  const [, setLastCheckpointPos] = useState<{ x: number; y: number } | null>(null);
  const [goldEarnedThisLevel, setGoldEarnedThisLevel] = useState<number>(0);

  const currentLevel: LevelData = LEVELS[currentLevelIndex] || LEVELS[0];

  const resolveLevelIndex = (levelId: number | string): number => {
    const strId = typeof levelId === 'number' ? `level_${levelId}` : String(levelId);
    const idx = LEVELS.findIndex((l) => l.id === strId || l.zoneIndex === Number(levelId));
    return idx >= 0 ? idx : 0;
  };

  const handleStartGame = (color: CharacterColor, levelId: number | string, slotId: number) => {
    setCharacterColor(color);
    setActiveSlotId(slotId);
    setCurrentLevelIndex(resolveLevelIndex(levelId));
    setStats({ ...INITIAL_STATS });
    setGoldEarnedThisLevel(0);
    setLastCheckpointPos(null);
    setGameState('playing');
    setIsPaused(false);
  };

  const handleLoadSave = (saveData: SaveSlotData) => {
    setCharacterColor(saveData.characterColor);
    setActiveSlotId(saveData.slotId);
    setCurrentLevelIndex(resolveLevelIndex(saveData.levelId));
    setStats(saveData.stats);
    setEquipment(saveData.equipment);
    setInventory(saveData.inventory);
    setGoldEarnedThisLevel(0);
    setLastCheckpointPos(null);
    setGameState('playing');
    setIsPaused(false);
  };

  const handleSaveGame = () => {
    const slotData: SaveSlotData = {
      slotId: activeSlotId,
      timestamp: Date.now(),
      playtimeSeconds: 120,
      levelId: currentLevel.id,
      characterColor,
      stats,
      equipment,
      inventory,
      openedChests: [],
      activatedAltars: []
    };
    writeSaveSlot(slotData);
  };

  const handleToggleMute = () => {
    const next = !isMuted;
    setIsMuted(next);
    soundManager.setMuted(next);
  };

  const handleOpenChest = (_chestId: string, loot: import('./types/game').Chest['loot']) => {
    const newGold = stats.gold + loot.gold;
    const newGems = stats.gems + (loot.gems || 0);
    const newInventory = [...inventory];
    if (loot.item) {
      newInventory.push(loot.item);
    }
    setInventory(newInventory);
    setGoldEarnedThisLevel((prev) => prev + loot.gold);
    setStats((prev) => ({
      ...prev,
      gold: newGold,
      gems: newGems
    }));
  };

  const handleActivateAltar = (altarId: string) => {
    const altar = currentLevel.altars.find((a) => a.id === altarId);
    if (altar) {
      setLastCheckpointPos({ x: altar.x, y: altar.y });
    }
    handleSaveGame();
  };

  const handleLevelComplete = () => {
    setGameState('victory');
  };

  const handleAdvanceNextLevel = () => {
    if (currentLevelIndex < LEVELS.length - 1) {
      setCurrentLevelIndex((prev) => prev + 1);
      setGoldEarnedThisLevel(0);
      setLastCheckpointPos(null);
      setGameState('playing');
    }
  };

  const handlePlayerDeath = () => {
    setGameState('gameover');
  };

  const handleRespawn = () => {
    setStats((prev) => ({ ...prev, hp: prev.maxHp, stamina: prev.maxStamina }));
    setGameState('playing');
  };

  // Gear Management
  const handleEquipItem = (item: Item) => {
    const newEquip = { ...equipment };
    let newStats = { ...stats };

    const oldItem = equipment[item.type as keyof Equipment];
    if (oldItem && oldItem.stats) {
      if (oldItem.stats.attack) newStats.attack -= oldItem.stats.attack;
      if (oldItem.stats.defense) newStats.defense -= oldItem.stats.defense;
      if (oldItem.stats.critRate) newStats.critRate -= oldItem.stats.critRate;
      if (oldItem.stats.maxHp) newStats.maxHp -= oldItem.stats.maxHp;
      if (oldItem.stats.speed) newStats.speed -= oldItem.stats.speed;
    }

    if (item.stats) {
      if (item.stats.attack) newStats.attack += item.stats.attack;
      if (item.stats.defense) newStats.defense += item.stats.defense;
      if (item.stats.critRate) newStats.critRate += item.stats.critRate;
      if (item.stats.maxHp) newStats.maxHp += item.stats.maxHp;
      if (item.stats.speed) newStats.speed += item.stats.speed;
    }

    if (item.type === 'weapon') newEquip.weapon = item;
    if (item.type === 'armor') newEquip.armor = item;
    if (item.type === 'accessory') newEquip.accessory = item;

    setEquipment(newEquip);
    setStats(newStats);
  };

  const handleUnequipItem = (slot: keyof Equipment) => {
    const oldItem = equipment[slot];
    if (!oldItem) return;

    let newStats = { ...stats };
    if (oldItem.stats) {
      if (oldItem.stats.attack) newStats.attack -= oldItem.stats.attack;
      if (oldItem.stats.defense) newStats.defense -= oldItem.stats.defense;
      if (oldItem.stats.critRate) newStats.critRate -= oldItem.stats.critRate;
      if (oldItem.stats.maxHp) newStats.maxHp -= oldItem.stats.maxHp;
      if (oldItem.stats.speed) newStats.speed -= oldItem.stats.speed;
    }

    setEquipment((prev) => ({ ...prev, [slot]: null }));
    setStats(newStats);
  };

  const handleUseConsumable = (item: Item) => {
    if (item.id === 'consumable_potion') {
      const healed = Math.min(stats.maxHp, stats.hp + 45);
      setStats((prev) => ({ ...prev, hp: healed }));
      setInventory((prev) => {
        const idx = prev.findIndex((i) => i.id === item.id);
        if (idx >= 0) {
          const next = [...prev];
          next.splice(idx, 1);
          return next;
        }
        return prev;
      });
    }
  };

  const handleUnlockSkill = (skillId: string, goldCost: number, gemCost: number) => {
    setStats((prev) => ({
      ...prev,
      gold: prev.gold - goldCost,
      gems: prev.gems - gemCost,
      skillsUnlocked: [...prev.skillsUnlocked, skillId]
    }));
  };

  return (
    <div className="relative w-screen h-screen flex flex-col bg-slate-950 text-slate-100 select-none overflow-hidden">
      {gameState === 'title' ? (
        <TitleScreen
          onStartGame={handleStartGame}
          onLoadSave={handleLoadSave}
          onOpenArchitecture={() => setIsArchitectureOpen(true)}
          levels={LEVELS}
          isMuted={isMuted}
          onToggleMute={handleToggleMute}
          language={language}
          onToggleLanguage={toggleLanguage}
        />
      ) : (
        <div className="relative w-full h-full flex flex-col overflow-hidden">
          {/* Top HUD */}
          <HUD
            stats={stats}
            isMuted={isMuted}
            onToggleMute={handleToggleMute}
            language={language}
            onToggleLanguage={toggleLanguage}
            onOpenInventory={() => setIsInventoryOpen(true)}
            onOpenSkills={() => setIsSkillsOpen(true)}
            onOpenArchitecture={() => setIsArchitectureOpen(true)}
            onTogglePause={() => setIsPaused((prev) => !prev)}
            showScanlines={showScanlines}
            onToggleScanlines={() => setShowScanlines((prev) => !prev)}
          />

          {/* Canvas Engine */}
          <main className="flex-1 relative flex items-center justify-center p-2 overflow-hidden">
            <GameCanvas
              level={currentLevel}
              characterColor={characterColor}
              stats={stats}
              onUpdateStats={setStats}
              onOpenChest={handleOpenChest}
              onActivateAltar={handleActivateAltar}
              onLevelComplete={handleLevelComplete}
              onPlayerDeath={handlePlayerDeath}
              isPaused={isPaused}
              onTogglePause={() => setIsPaused((prev) => !prev)}
              showScanlines={showScanlines}
            />
          </main>
        </div>
      )}

      {/* Modals */}
      <PauseMenu
        isOpen={isPaused}
        onResume={() => setIsPaused(false)}
        onOpenInventory={() => {
          setIsPaused(false);
          setIsInventoryOpen(true);
        }}
        onOpenSkills={() => {
          setIsPaused(false);
          setIsSkillsOpen(true);
        }}
        onOpenArchitecture={() => {
          setIsPaused(false);
          setIsArchitectureOpen(true);
        }}
        onSaveGame={handleSaveGame}
        onReturnTitle={() => {
          setIsPaused(false);
          setGameState('title');
        }}
        isMuted={isMuted}
        onToggleMute={handleToggleMute}
        showScanlines={showScanlines}
        onToggleScanlines={() => setShowScanlines((prev) => !prev)}
        language={language}
        onToggleLanguage={toggleLanguage}
      />

      <InventoryModal
        isOpen={isInventoryOpen}
        onClose={() => setIsInventoryOpen(false)}
        equipment={equipment}
        inventory={inventory}
        stats={stats}
        onEquipItem={handleEquipItem}
        onUnequipItem={handleUnequipItem}
        onUseConsumable={handleUseConsumable}
        language={language}
      />

      <SkillTreeModal
        isOpen={isSkillsOpen}
        onClose={() => setIsSkillsOpen(false)}
        stats={stats}
        onUnlockSkill={handleUnlockSkill}
        language={language}
      />

      <GodotArchitectureModal
        isOpen={isArchitectureOpen}
        onClose={() => setIsArchitectureOpen(false)}
        language={language}
        onToggleLanguage={toggleLanguage}
      />

      <VictoryModal
        isOpen={gameState === 'victory'}
        chapterTitle={currentLevel.chapter}
        levelName={currentLevel.name}
        goldEarned={goldEarnedThisLevel}
        onNextLevel={handleAdvanceNextLevel}
        onReturnTitle={() => setGameState('title')}
        isLastLevel={currentLevelIndex >= LEVELS.length - 1}
        language={language}
      />

      <GameOverModal
        isOpen={gameState === 'gameover'}
        onRespawn={handleRespawn}
        onReturnTitle={() => setGameState('title')}
        language={language}
      />
    </div>
  );
};
