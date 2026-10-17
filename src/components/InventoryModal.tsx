import React from 'react';
import { Equipment, Item, PlayerStats } from '../types/game';
import { Language, TRANSLATIONS } from '../i18n/translations';
import { Sword, Shield, Award, X } from 'lucide-react';
import { soundManager } from '../audio/soundManager';

interface InventoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  equipment: Equipment;
  inventory: Item[];
  stats: PlayerStats;
  onEquipItem: (item: Item) => void;
  onUnequipItem: (slot: keyof Equipment) => void;
  onUseConsumable: (item: Item) => void;
  language: Language;
}

export const InventoryModal: React.FC<InventoryModalProps> = ({
  isOpen,
  onClose,
  equipment,
  inventory,
  stats,
  onEquipItem,
  onUnequipItem,
  onUseConsumable,
  language
}) => {
  if (!isOpen) return null;
  const t = TRANSLATIONS[language];

  const getRarityBadge = (rarity: Item['rarity']) => {
    switch (rarity) {
      case 'legendary':
        return 'border-amber-400/80 bg-amber-950/60 text-amber-300';
      case 'epic':
        return 'border-purple-400/80 bg-purple-950/60 text-purple-300';
      case 'rare':
        return 'border-blue-400/80 bg-blue-950/60 text-blue-300';
      default:
        return 'border-slate-600 bg-slate-900/60 text-slate-300';
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-slate-700 rounded-xl w-full max-w-3xl overflow-hidden shadow-2xl flex flex-col max-h-[90vh]">
        {/* Modal Header */}
        <div className="bg-slate-950 px-6 py-4 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Shield className="w-5 h-5 text-amber-400" />
            <h2 className="font-fantasy text-xl font-bold text-slate-100">{t.arsenal}</h2>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded hover:bg-slate-800 text-slate-400 hover:text-white transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6 overflow-y-auto">
          {/* Column 1: Equipment Slots & Stats */}
          <div className="space-y-4">
            <h3 className="text-xs font-pixel text-amber-400 uppercase tracking-wider">{t.equippedRelics}</h3>
            
            {/* Weapon Slot */}
            <div className="bg-slate-950 p-3 rounded-lg border border-slate-800 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded bg-slate-900 border border-slate-700 flex items-center justify-center text-amber-400">
                  <Sword className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-[10px] text-slate-400 uppercase">{t.weapon}</div>
                  <div className="font-medium text-sm text-slate-200">
                    {equipment.weapon ? equipment.weapon.name : t.none}
                  </div>
                </div>
              </div>
              {equipment.weapon && (
                <button
                  onClick={() => onUnequipItem('weapon')}
                  className="text-xs text-rose-400 hover:text-rose-300 px-2 py-1 bg-slate-900 rounded border border-rose-900/50"
                >
                  {t.unequip}
                </button>
              )}
            </div>

            {/* Armor Slot */}
            <div className="bg-slate-950 p-3 rounded-lg border border-slate-800 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded bg-slate-900 border border-slate-700 flex items-center justify-center text-sky-400">
                  <Shield className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-[10px] text-slate-400 uppercase">{t.armor}</div>
                  <div className="font-medium text-sm text-slate-200">
                    {equipment.armor ? equipment.armor.name : t.none}
                  </div>
                </div>
              </div>
              {equipment.armor && (
                <button
                  onClick={() => onUnequipItem('armor')}
                  className="text-xs text-rose-400 hover:text-rose-300 px-2 py-1 bg-slate-900 rounded border border-rose-900/50"
                >
                  {t.unequip}
                </button>
              )}
            </div>

            {/* Accessory Slot */}
            <div className="bg-slate-950 p-3 rounded-lg border border-slate-800 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded bg-slate-900 border border-slate-700 flex items-center justify-center text-purple-400">
                  <Award className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-[10px] text-slate-400 uppercase">{t.accessory}</div>
                  <div className="font-medium text-sm text-slate-200">
                    {equipment.accessory ? equipment.accessory.name : t.none}
                  </div>
                </div>
              </div>
              {equipment.accessory && (
                <button
                  onClick={() => onUnequipItem('accessory')}
                  className="text-xs text-rose-400 hover:text-rose-300 px-2 py-1 bg-slate-900 rounded border border-rose-900/50"
                >
                  {t.unequip}
                </button>
              )}
            </div>

            {/* Attributes summary */}
            <div className="bg-slate-950 p-4 rounded-lg border border-slate-800 space-y-2 text-xs">
              <h4 className="font-pixel text-[10px] text-slate-400 mb-2">{t.combatAttributes}</h4>
              <div className="flex justify-between text-slate-300">
                <span>{t.totalAttack}:</span>
                <span className="font-pixel text-amber-400 font-bold">{stats.attack}</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>{t.totalDefense}:</span>
                <span className="font-pixel text-sky-400 font-bold">{stats.defense}</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>{t.criticalChance}:</span>
                <span className="font-pixel text-rose-400 font-bold">{(stats.critRate * 100).toFixed(0)}%</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>{t.maxHp}:</span>
                <span className="font-pixel text-emerald-400 font-bold">{stats.maxHp}</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>{t.sprintSpeed}:</span>
                <span className="font-pixel text-indigo-400 font-bold">{stats.speed}</span>
              </div>
            </div>
          </div>

          {/* Column 2 & 3: Backpack Inventory */}
          <div className="md:col-span-2 space-y-3">
            <h3 className="text-xs font-pixel text-slate-400 uppercase tracking-wider">
              {t.haversack} ({inventory.length})
            </h3>

            {inventory.length === 0 ? (
              <div className="bg-slate-950/60 border border-dashed border-slate-800 rounded-lg p-8 text-center text-slate-500 text-sm">
                {t.emptyInventory}
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {inventory.map((item, idx) => (
                  <div
                    key={`${item.id}-${idx}`}
                    className={`p-3 rounded-lg border bg-slate-950 flex flex-col justify-between ${getRarityBadge(
                      item.rarity
                    )}`}
                  >
                    <div>
                      <div className="flex items-center justify-between mb-1">
                        <span className="font-bold text-sm text-slate-100">{item.name}</span>
                        <span className="text-[9px] uppercase px-1.5 py-0.5 rounded border border-current font-pixel">
                          {item.rarity}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 line-clamp-2 mb-2">{item.description}</p>
                      {item.stats && (
                        <div className="text-[11px] space-x-2 text-slate-300 mb-2">
                          {item.stats.attack && <span className="text-amber-400">+{item.stats.attack} ATK</span>}
                          {item.stats.defense && <span className="text-sky-400">+{item.stats.defense} DEF</span>}
                          {item.stats.critRate && (
                            <span className="text-rose-400">+{(item.stats.critRate * 100).toFixed(0)}% CRIT</span>
                          )}
                          {item.stats.maxHp && <span className="text-emerald-400">+{item.stats.maxHp} HP</span>}
                        </div>
                      )}
                    </div>

                    <div className="pt-2 border-t border-slate-800/80 flex items-center justify-between">
                      <span className="text-[10px] text-slate-400">{t.value}: {item.value}G</span>
                      {item.type === 'consumable' ? (
                        <button
                          onClick={() => {
                            onUseConsumable(item);
                            soundManager.playPotion();
                          }}
                          className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded text-xs font-bold transition"
                        >
                          {t.drink}
                        </button>
                      ) : (
                        <button
                          onClick={() => {
                            onEquipItem(item);
                            soundManager.playParry();
                          }}
                          className="px-3 py-1 bg-blue-600 hover:bg-blue-500 text-white rounded text-xs font-bold transition"
                        >
                          {t.equip}
                        </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
