import React, { useEffect } from 'react';
import confetti from 'canvas-confetti';
import { Trophy, ArrowRight, Home } from 'lucide-react';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { soundManager } from '../audio/soundManager';

interface VictoryModalProps {
  isOpen: boolean;
  chapterTitle: string;
  levelName: string;
  goldEarned: number;
  onNextLevel: () => void;
  onReturnTitle: () => void;
  isLastLevel: boolean;
  language: Language;
}

export const VictoryModal: React.FC<VictoryModalProps> = ({
  isOpen,
  chapterTitle,
  levelName,
  goldEarned,
  onNextLevel,
  onReturnTitle,
  isLastLevel,
  language
}) => {
  useEffect(() => {
    if (isOpen) {
      soundManager.playLevelUp();
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 }
      });
    }
  }, [isOpen]);

  if (!isOpen) return null;
  const t = TRANSLATIONS[language];

  return (
    <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-amber-500/80 rounded-2xl w-full max-w-md p-6 shadow-2xl text-center space-y-5">
        <div className="w-16 h-16 rounded-full bg-amber-500/20 border-2 border-amber-400 mx-auto flex items-center justify-center text-amber-400">
          <Trophy className="w-8 h-8" />
        </div>

        <div className="space-y-1">
          <span className="text-[10px] font-pixel text-amber-400 uppercase tracking-widest">
            {chapterTitle}
          </span>
          <h2 className="font-fantasy text-2xl font-bold text-white">
            {isLastLevel ? t.sanctumConquered : t.victoryTitle}
          </h2>
          <p className="text-xs text-slate-300">{levelName} {t.levelCleared}</p>
        </div>

        <div className="bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-2 text-xs">
          <div className="flex justify-between text-slate-400">
            <span>{t.spoilsOfWar}:</span>
            <span className="font-pixel text-amber-400 font-bold">+{goldEarned} {t.goldLabel}</span>
          </div>
          <div className="flex justify-between text-slate-400">
            <span>{t.warriorAcclaim}:</span>
            <span className="font-pixel text-purple-400 font-bold">+250</span>
          </div>
        </div>

        <div className="space-y-2 pt-2">
          {!isLastLevel && (
            <button
              onClick={onNextLevel}
              className="w-full py-3 bg-gradient-to-r from-amber-600 to-amber-700 hover:from-amber-500 hover:to-amber-600 text-slate-950 font-pixel text-xs font-bold rounded-xl flex items-center justify-center space-x-2 transition shadow-lg shadow-amber-600/30"
            >
              <span>{t.advanceChapter}</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          )}

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
