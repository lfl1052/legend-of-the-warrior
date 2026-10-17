import React from 'react';
import { PlayerStats } from '../types/game';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { Heart, Zap, Sparkles, Coins, Gem, Volume2, VolumeX, Menu, Shield, Code, Globe } from 'lucide-react';

interface HUDProps {
  stats: PlayerStats;
  isMuted: boolean;
  onToggleMute: () => void;
  language: Language;
  onToggleLanguage: () => void;
  onOpenInventory: () => void;
  onOpenSkills: () => void;
  onOpenArchitecture: () => void;
  onTogglePause: () => void;
  showScanlines: boolean;
  onToggleScanlines: () => void;
}

export const HUD: React.FC<HUDProps> = ({
  stats,
  isMuted,
  onToggleMute,
  language,
  onToggleLanguage,
  onOpenInventory,
  onOpenSkills,
  onOpenArchitecture,
  onTogglePause,
  showScanlines,
  onToggleScanlines
}) => {
  const hpPercent = Math.max(0, Math.min(100, (stats.hp / stats.maxHp) * 100));
  const staminaPercent = Math.max(0, Math.min(100, (stats.stamina / stats.maxStamina) * 100));
  const xpPercent = Math.max(0, Math.min(100, (stats.xp / stats.xpToNext) * 100));
  const t = TRANSLATIONS[language];

  return (
    <header className="w-full bg-slate-900/90 border-b border-slate-800 px-4 py-2.5 backdrop-blur-md flex flex-wrap items-center justify-between gap-3 text-slate-100 z-30 shadow-lg">
      {/* Player Vital Bars */}
      <div className="flex items-center space-x-4">
        {/* Level Avatar Badge */}
        <div className="flex flex-col items-center justify-center bg-gradient-to-br from-amber-600 to-amber-800 border-2 border-amber-400 rounded-lg w-11 h-11 shadow">
          <span className="text-[9px] font-pixel text-amber-200">{t.levelLabel}</span>
          <span className="font-pixel text-sm font-bold text-white">{stats.level}</span>
        </div>

        {/* Bars Column */}
        <div className="flex flex-col space-y-1.5 min-w-[180px] sm:min-w-[240px]">
          {/* HP Bar */}
          <div className="flex items-center space-x-1.5">
            <Heart className="w-4 h-4 text-rose-500 fill-rose-500 shrink-0" />
            <div className="relative flex-1 h-3.5 bg-slate-950 rounded-full overflow-hidden border border-rose-900/60 shadow-inner">
              <div
                className="h-full bg-gradient-to-r from-rose-600 to-rose-400 transition-all duration-200"
                style={{ width: `${hpPercent}%` }}
              />
              <span className="absolute inset-0 flex items-center justify-center text-[9px] font-pixel text-white font-bold drop-shadow">
                {Math.ceil(stats.hp)} / {stats.maxHp}
              </span>
            </div>
          </div>

          {/* Stamina Bar */}
          <div className="flex items-center space-x-1.5">
            <Zap className="w-4 h-4 text-sky-400 fill-sky-400 shrink-0" />
            <div className="relative flex-1 h-2.5 bg-slate-950 rounded-full overflow-hidden border border-sky-900/60 shadow-inner">
              <div
                className="h-full bg-gradient-to-r from-sky-500 to-cyan-400 transition-all duration-150"
                style={{ width: `${staminaPercent}%` }}
              />
            </div>
          </div>

          {/* XP Bar */}
          <div className="flex items-center space-x-1.5">
            <Sparkles className="w-3.5 h-3.5 text-purple-400 shrink-0" />
            <div className="relative flex-1 h-1.5 bg-slate-950 rounded-full overflow-hidden border border-purple-900/40">
              <div
                className="h-full bg-gradient-to-r from-purple-500 to-fuchsia-400 transition-all duration-300"
                style={{ width: `${xpPercent}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Currency & Consumables */}
      <div className="flex items-center space-x-4">
        {/* Gold */}
        <div className="flex items-center space-x-1.5 bg-slate-950/80 px-2.5 py-1 rounded border border-amber-500/30">
          <Coins className="w-4 h-4 text-amber-400 fill-amber-400" />
          <span className="font-pixel text-xs text-amber-300">{stats.gold}</span>
        </div>

        {/* Gems */}
        <div className="flex items-center space-x-1.5 bg-slate-950/80 px-2.5 py-1 rounded border border-sky-500/30">
          <Gem className="w-4 h-4 text-cyan-400 fill-cyan-400" />
          <span className="font-pixel text-xs text-cyan-300">{stats.gems}</span>
        </div>

        {/* Potion Slot */}
        <div className="flex items-center space-x-1 bg-slate-950/80 px-2.5 py-1 rounded border border-rose-500/30">
          <span className="text-[9px] font-pixel text-rose-400 mr-1">[I]</span>
          <Heart className="w-3.5 h-3.5 text-rose-400 fill-rose-400" />
          <span className="font-pixel text-xs text-white">x{stats.potions}</span>
        </div>
      </div>

      {/* Navigation & Action Buttons */}
      <div className="flex items-center space-x-2">
        <button
          onClick={onOpenInventory}
          className="px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 text-xs font-fantasy font-semibold rounded border border-slate-700 flex items-center space-x-1 transition"
          title="Open Inventory (I)"
        >
          <Shield className="w-3.5 h-3.5 text-amber-400" />
          <span className="hidden sm:inline">{t.arsenal}</span>
        </button>

        <button
          onClick={onOpenSkills}
          className="px-2.5 py-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 text-xs font-fantasy font-semibold rounded border border-slate-700 flex items-center space-x-1 transition"
          title="Skill Tree"
        >
          <Sparkles className="w-3.5 h-3.5 text-purple-400" />
          <span className="hidden sm:inline">{t.skillMasteries}</span>
        </button>

        <button
          onClick={onOpenArchitecture}
          className="px-2.5 py-1.5 bg-indigo-950/80 hover:bg-indigo-900 text-xs font-pixel text-indigo-300 rounded border border-indigo-700/50 flex items-center space-x-1 transition"
          title="Godot & GdUnit Architecture Hub"
        >
          <Code className="w-3.5 h-3.5 text-indigo-400" />
          <span className="hidden md:inline text-[9px]">GdUnit</span>
        </button>

        {/* Language switch button */}
        <button
          onClick={onToggleLanguage}
          className="px-2 py-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 rounded border border-slate-700 text-xs font-pixel text-amber-300 flex items-center space-x-1 transition"
          title="Toggle Language (中/EN)"
        >
          <Globe className="w-3.5 h-3.5" />
          <span>{language === 'zh' ? '中' : 'EN'}</span>
        </button>

        <button
          onClick={onToggleScanlines}
          className={`p-1.5 rounded border transition text-xs font-pixel ${
            showScanlines ? 'bg-amber-950 text-amber-300 border-amber-600' : 'bg-slate-800 text-slate-400 border-slate-700'
          }`}
          title="Toggle CRT Scanline Effect"
        >
          CRT
        </button>

        <button
          onClick={onToggleMute}
          className="p-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 rounded border border-slate-700 transition"
          title={isMuted ? t.soundMuted : t.soundOn}
        >
          {isMuted ? <VolumeX className="w-4 h-4 text-slate-400" /> : <Volume2 className="w-4 h-4 text-emerald-400" />}
        </button>

        <button
          onClick={onTogglePause}
          className="p-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 rounded border border-slate-700 transition"
          title="Pause Game (ESC)"
        >
          <Menu className="w-4 h-4 text-slate-200" />
        </button>
      </div>
    </header>
  );
};
