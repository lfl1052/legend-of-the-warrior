import React, { useEffect } from 'react';
import { Skull, RotateCcw, Home } from 'lucide-react';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { soundManager } from '../audio/soundManager';

interface GameOverModalProps {
  isOpen: boolean;
  onRespawn: () => void;
  onReturnTitle: () => void;
  language: Language;
}

export const GameOverModal: React.FC<GameOverModalProps> = ({
  isOpen,
  onRespawn,
  onReturnTitle,
  language
}) => {
  useEffect(() => {
    if (isOpen) {
      soundManager.playHurt();
    }
  }, [isOpen]);

  if (!isOpen) return null;
  const t = TRANSLATIONS[language];

  return (
    <div className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-rose-900/80 rounded-2xl w-full max-w-md p-6 shadow-2xl text-center space-y-5">
        <div className="w-16 h-16 rounded-full bg-rose-950 border-2 border-rose-600 mx-auto flex items-center justify-center text-rose-500">
          <Skull className="w-8 h-8" />
        </div>

        <div className="space-y-1">
          <span className="text-[10px] font-pixel text-rose-500 uppercase tracking-widest">
            {t.gameTitle}
          </span>
          <h2 className="font-fantasy text-3xl font-black text-rose-400">{t.youDied}</h2>
          <p className="text-xs text-slate-400">{t.deathDesc}</p>
        </div>

        <div className="space-y-2 pt-2">
          <button
            onClick={onRespawn}
            className="w-full py-3 bg-rose-600 hover:bg-rose-500 text-white font-pixel text-xs font-bold rounded-xl flex items-center justify-center space-x-2 transition shadow-lg shadow-rose-600/30"
          >
            <RotateCcw className="w-4 h-4" />
            <span>{t.respawnCheckpoint}</span>
          </button>

          <button
            onClick={onReturnTitle}
            className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 font-pixel text-xs rounded-xl flex items-center justify-center space-x-2 transition"
          >
            <Home className="w-4 h-4" />
            <span>{t.returnTitle}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
