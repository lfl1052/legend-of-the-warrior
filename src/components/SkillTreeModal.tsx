import React from 'react';
import { PlayerStats } from '../types/game';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { Sparkles, X, Zap, Shield, Flame, CheckCircle2 } from 'lucide-react';
import { soundManager } from '../audio/soundManager';

interface SkillTreeModalProps {
  isOpen: boolean;
  onClose: () => void;
  stats: PlayerStats;
  onUnlockSkill: (skillId: string, goldCost: number, gemCost: number) => void;
  language: Language;
}

interface SkillNode {
  id: string;
  name: string;
  nameZh: string;
  icon: typeof Sparkles;
  description: string;
  descriptionZh: string;
  goldCost: number;
  gemCost: number;
  keybind: string;
}

const SKILL_NODES: SkillNode[] = [
  {
    id: 'whirlwind',
    name: 'Whirlwind Blade',
    nameZh: '旋风利刃斩',
    icon: Flame,
    description: 'Spin 360 degrees, unleashing a devastating storm of slashes damaging all surrounding enemies.',
    descriptionZh: '原地360度大回旋斩击，释放狂暴剑刃风暴打击周遭一切敌兵。',
    goldCost: 0,
    gemCost: 0,
    keybind: '[U]'
  },
  {
    id: 'dash_strike',
    name: 'Phantom Dash Strike',
    nameZh: '幻影突刺破',
    icon: Zap,
    description: 'Infuses warrior dash with razor energy, piercing through enemies and dealing 25 damage along the path.',
    descriptionZh: '为战术冲刺注入锋锐剑芒，穿透敌阵并对路径上的目标造成25点穿刺伤害。',
    goldCost: 80,
    gemCost: 3,
    keybind: '[L]'
  },
  {
    id: 'titan_slam',
    name: "Titan's Ground Slam",
    nameZh: '泰坦撼地重击',
    icon: Sparkles,
    description: 'Leap and smash the blade into the earth, causing erupting stone shockwaves across the floor.',
    descriptionZh: '跃起并将巨剑重砸于地面，激荡起冲破地表的碎石冲击波。',
    goldCost: 150,
    gemCost: 6,
    keybind: '[U] (空中)'
  },
  {
    id: 'aegis_bastion',
    name: 'Divine Aegis Bastion',
    nameZh: '圣佑坚壁要塞',
    icon: Shield,
    description: 'Perfect shield blocks convert incoming kinetic impact into 15% HP restoration.',
    descriptionZh: '精湛的盾牌招架能够将攻击冲击力转化为圣光，每次成功格挡恢复15%生命值。',
    goldCost: 240,
    gemCost: 10,
    keybind: '[B]'
  }
];

export const SkillTreeModal: React.FC<SkillTreeModalProps> = ({
  isOpen,
  onClose,
  stats,
  onUnlockSkill,
  language
}) => {
  if (!isOpen) return null;
  const t = TRANSLATIONS[language];

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-slate-700 rounded-xl w-full max-w-2xl overflow-hidden shadow-2xl flex flex-col">
        {/* Header */}
        <div className="bg-slate-950 px-6 py-4 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Sparkles className="w-5 h-5 text-purple-400" />
            <h2 className="font-fantasy text-xl font-bold text-slate-100">{t.skillMasteries}</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded hover:bg-slate-800 text-slate-400 hover:text-white transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Skill list */}
        <div className="p-6 space-y-4 max-h-[75vh] overflow-y-auto">
          {SKILL_NODES.map((skill) => {
            const isUnlocked = stats.skillsUnlocked.includes(skill.id);
            const canAfford = stats.gold >= skill.goldCost && stats.gems >= skill.gemCost;
            const Icon = skill.icon;
            const displayName = language === 'zh' ? skill.nameZh : skill.name;
            const displayDesc = language === 'zh' ? skill.descriptionZh : skill.description;

            return (
              <div
                key={skill.id}
                className={`p-4 rounded-xl border flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 transition ${
                  isUnlocked
                    ? 'bg-slate-950/70 border-purple-500/50 shadow-[0_0_15px_rgba(168,85,247,0.15)]'
                    : 'bg-slate-950/30 border-slate-800'
                }`}
              >
                <div className="flex items-start space-x-4">
                  <div
                    className={`w-12 h-12 rounded-lg flex items-center justify-center shrink-0 border ${
                      isUnlocked
                        ? 'bg-purple-950/80 border-purple-400 text-purple-300'
                        : 'bg-slate-900 border-slate-700 text-slate-500'
                    }`}
                  >
                    <Icon className="w-6 h-6" />
                  </div>
                  <div>
                    <div className="flex items-center space-x-2">
                      <h4 className="font-bold text-slate-100 text-sm">{displayName}</h4>
                      <span className="font-pixel text-[9px] px-2 py-0.5 rounded bg-slate-800 text-purple-300 border border-purple-500/30">
                        {skill.keybind}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 mt-1">{displayDesc}</p>
                  </div>
                </div>

                <div className="shrink-0 flex items-center space-x-3 self-end sm:self-center">
                  {isUnlocked ? (
                    <div className="flex items-center space-x-1 text-emerald-400 text-xs font-bold font-pixel">
                      <CheckCircle2 className="w-4 h-4" />
                      <span>{t.mastered}</span>
                    </div>
                  ) : (
                    <div className="flex flex-col items-end space-y-1">
                      <div className="text-[10px] text-slate-400 font-pixel">
                        {skill.goldCost > 0 && <span className="text-amber-400 mr-2">{skill.goldCost} {t.goldLabel}</span>}
                        {skill.gemCost > 0 && <span className="text-cyan-400">{skill.gemCost} {t.gemsLabel}</span>}
                      </div>
                      <button
                        disabled={!canAfford}
                        onClick={() => {
                          onUnlockSkill(skill.id, skill.goldCost, skill.gemCost);
                          soundManager.playLevelUp();
                        }}
                        className={`px-3 py-1.5 rounded text-xs font-bold font-pixel transition ${
                          canAfford
                            ? 'bg-purple-600 hover:bg-purple-500 text-white shadow-lg shadow-purple-600/30'
                            : 'bg-slate-800 text-slate-500 cursor-not-allowed'
                        }`}
                      >
                        {t.unlock}
                      </button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
