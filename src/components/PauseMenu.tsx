import React from 'react';
import { Play, Shield, Sparkles, Save, Code, Home, Volume2, VolumeX, Globe } from 'lucide-react';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { soundManager } from '../audio/soundManager';

interface PauseMenuProps {
  isOpen: boolean;
  onResume: () => void;
  onOpenInventory: () => void;
  onOpenSkills: () => void;
  onOpenArchitecture: () => void;
  onSaveGame: () => void;
  onReturnTitle: () => void;
  isMuted: boolean;
  onToggleMute: () => void;
  showScanlines: boolean;
  onToggleScanlines: () => void;
  language: Language;
  onToggleLanguage: () => void;
}

export const PauseMenu: React.FC<PauseMenuProps> = ({
  isOpen,
  onResume,
  onOpenInventory,
  onOpenSkills,
  onOpenArchitecture,
  onSaveGame,
  onReturnTitle,
  isMuted,
  onToggleMute,
  showScanlines,
  onToggleScanlines,
  language,
  onToggleLanguage
}) => {
  if (!isOpen) return null;
  const t = TRANSLATIONS[language];

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-slate-700 rounded-2xl w-full max-w-md p-6 shadow-2xl flex flex-col items-center space-y-4">
        {/* Title */}
        <div className="text-center">
          <span className="text-[10px] font-pixel text-amber-400 uppercase tracking-widest">
            {t.gameTitle}
          </span>
          <h2 className="font-fantasy text-2xl font-bold text-slate-100 mt-1">PAUSE</h2>
        </div>

        {/* Buttons list */}
        <div className="w-full space-y-2.5 pt-2">
          <button
            onClick={() => {
              soundManager.playParry();
              onResume();
            }}
            className="w-full py-3 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 transition shadow-lg shadow-blue-600/30"
          >
            <Play className="w-4 h-4 fill-current" />
            <span>{t.resume}</span>
          </button>

          <button
            onClick={() => {
              soundManager.playParry();
              onOpenInventory();
            }}
            className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 text-slate-200 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-slate-700 transition"
          >
            <Shield className="w-4 h-4 text-amber-400" />
            <span>{t.arsenal}</span>
          </button>

          <button
            onClick={() => {
              soundManager.playParry();
              onOpenSkills();
            }}
            className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-900 text-slate-200 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-slate-700 transition"
          >
            <Sparkles className="w-4 h-4 text-purple-400" />
            <span>{t.skillMasteries}</span>
          </button>

          <button
            onClick={() => {
              soundManager.playLevelUp();
              onSaveGame();
            }}
            className="w-full py-2.5 bg-emerald-950 hover:bg-emerald-900 text-emerald-300 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-emerald-700/50 transition"
          >
            <Save className="w-4 h-4 text-emerald-400" />
            <span>{t.saveGame}</span>
          </button>

          <button
            onClick={() => {
              soundManager.playParry();
              onOpenArchitecture();
            }}
            className="w-full py-2.5 bg-indigo-950 hover:bg-indigo-900 text-indigo-300 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 border border-indigo-700/50 transition"
          >
            <Code className="w-4 h-4 text-indigo-400" />
            <span>{t.gdunitInspector}</span>
          </button>

          {/* Quick toggles */}
          <div className="grid grid-cols-3 gap-2 pt-1">
            <button
              onClick={onToggleLanguage}
              className="py-2 bg-slate-950 hover:bg-slate-800 text-amber-300 text-xs font-pixel rounded-lg border border-slate-800 flex items-center justify-center space-x-1 transition"
            >
              <Globe className="w-3.5 h-3.5" />
              <span>{language === 'zh' ? '中文' : 'EN'}</span>
            </button>

            <button
              onClick={onToggleMute}
              className="py-2 bg-slate-950 hover:bg-slate-800 text-slate-300 text-xs font-pixel rounded-lg border border-slate-800 flex items-center justify-center space-x-1 transition"
            >
              {isMuted ? <VolumeX className="w-3.5 h-3.5 text-rose-400" /> : <Volume2 className="w-3.5 h-3.5 text-emerald-400" />}
              <span>{isMuted ? 'Mute' : 'Audio'}</span>
            </button>

            <button
              onClick={onToggleScanlines}
              className={`py-2 text-xs font-pixel rounded-lg border flex items-center justify-center space-x-1 transition ${
                showScanlines
                  ? 'bg-amber-950/80 text-amber-300 border-amber-600/60'
                  : 'bg-slate-950 text-slate-400 border-slate-800'
              }`}
            >
              <span>CRT {showScanlines ? 'ON' : 'OFF'}</span>
            </button>
          </div>

          <button
            onClick={() => {
              soundManager.playParry();
              onReturnTitle();
            }}
            className="w-full py-2 bg-slate-950 hover:bg-rose-950 text-rose-400 hover:text-rose-300 font-pixel text-[10px] rounded-xl flex items-center justify-center space-x-1.5 border border-rose-950 transition mt-2"
          >
            <Home className="w-3.5 h-3.5" />
            <span>{t.returnTitle}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
