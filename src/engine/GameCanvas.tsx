import React, { useEffect, useRef, useState } from 'react';
import {
  BreakableRock,
  CharacterColor,
  Chest,
  CheckpointAltar,
  Collectible,
  DamageNumber,
  Enemy,
  Ladder,
  LevelData,
  Particle,
  PlayerActionState,
  PlayerStats,
} from '../types/game';
import { soundManager } from '../audio/soundManager';
import { ASSET_PATHS, assetLoader } from './assetLoader';
import {
  BUILDINGS_CROPS,
  CompiledTilemap,
  FOREST1_CROPS,
  GENERATED_BOULDER_CROPS,
  HIVE_CROPS,
  ROCKS_CROPS,
  compileLevelTilemap,
  renderForegroundAccents,
  renderGeometryTiles,
  renderParallaxForest,
  renderWaterTiles,
  renderWorldBackgroundProps,
} from './forestTilemapEngine';

interface GameCanvasProps {
  level: LevelData;
  characterColor: CharacterColor;
  stats: PlayerStats;
  onUpdateStats: (newStats: PlayerStats) => void;
  onOpenChest: (chestId: string, loot: Chest['loot']) => void;
  onActivateAltar: (altarId: string) => void;
  onLevelComplete: () => void;
  onPlayerDeath: () => void;
  isPaused: boolean;
  onTogglePause: () => void;
  showScanlines: boolean;
}

export const GameCanvas: React.FC<GameCanvasProps> = ({
  level,
  characterColor,
  stats,
  onUpdateStats,
  onOpenChest,
  onActivateAltar,
  onLevelComplete,
  onPlayerDeath,
  isPaused,
  onTogglePause,
  showScanlines,
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // Logical viewport matching Godot baseline (640x360)
  const VIEW_W = 640;
  const VIEW_H = 360;

  // Precompiled rule tilemap for Terrain Set 0 (Forest-1.png + inner corners)
  const compiledTilemapRef = useRef<CompiledTilemap>(compileLevelTilemap(level));

  // Active game entities stored in mutable refs for smooth 60fps loop
  const playerRef = useRef({
    x: level.spawnPoint.x,
    y: level.spawnPoint.y,
    vx: 0,
    vy: 0,
    w: 32,
    h: 46,
    facing: 1 as 1 | -1,
    state: 'idle' as PlayerActionState,
    stateTime: 0,
    isGrounded: false,
    isClimbing: false,
    jumpCount: 0,
    isDashing: false,
    dashTimer: 0,
    dashCooldown: 0,
    attackStep: 0,
    attackTimer: 0,
    skillTimer: 0,
    isBlocking: false,
    invulnerableTimer: 0,
    hitFlash: 0,
    interactTarget: null as 'chest' | 'altar' | 'ladder' | null,
    interactId: null as string | null,
  });

  const enemiesRef = useRef<Enemy[]>([]);
  const chestsRef = useRef<Chest[]>([]);
  const altarsRef = useRef<CheckpointAltar[]>([]);
  const laddersRef = useRef<Ladder[]>([]);
  const breakableRocksRef = useRef<BreakableRock[]>([]);
  const collectiblesRef = useRef<Collectible[]>([]);
  const particlesRef = useRef<Particle[]>([]);
  const damageNumbersRef = useRef<DamageNumber[]>([]);
  const cameraRef = useRef({ x: 0, y: 280, targetX: 0, targetY: 280, shake: 0 });

  // Key tracking
  const keysRef = useRef<{ [key: string]: boolean }>({});
  const [, setTouchControlsActive] = useState(false);

  // Initialize level entities
  useEffect(() => {
    compiledTilemapRef.current = compileLevelTilemap(level);

    playerRef.current.x = level.spawnPoint.x;
    playerRef.current.y = level.spawnPoint.y;
    playerRef.current.vx = 0;
    playerRef.current.vy = 0;
    playerRef.current.isClimbing = false;
    playerRef.current.state = 'idle';

    const maxCamY = Math.max(0, compiledTilemapRef.current.mainGroundY + 64 - VIEW_H);
    const initCamX = Math.max(0, Math.min(level.width - VIEW_W, level.spawnPoint.x - VIEW_W / 2));
    const initCamY = Math.max(0, Math.min(maxCamY, level.spawnPoint.y + 46 - 280));
    cameraRef.current.x = initCamX;
    cameraRef.current.targetX = initCamX;
    cameraRef.current.y = initCamY;
    cameraRef.current.targetY = initCamY;

    enemiesRef.current = JSON.parse(JSON.stringify(level.enemies));
    chestsRef.current = JSON.parse(JSON.stringify(level.chests));
    altarsRef.current = JSON.parse(JSON.stringify(level.altars));
    laddersRef.current = JSON.parse(JSON.stringify(level.ladders || []));
    breakableRocksRef.current = JSON.parse(JSON.stringify(level.breakableRocks || []));
    collectiblesRef.current = JSON.parse(JSON.stringify(level.collectibles || []));
    particlesRef.current = [];
    damageNumbersRef.current = [];

    // Preload all native art sheets
    assetLoader.preloadAll(characterColor);
    soundManager.startBGM(level.theme);

    return () => {
      soundManager.stopBGM();
    };
  }, [level, characterColor]);

  // Keyboard events
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) {
        e.preventDefault();
      }
      keysRef.current[e.code] = true;

      if (e.code === 'Escape') {
        onTogglePause();
      }
    };

    const handleKeyUp = (e: KeyboardEvent) => {
      keysRef.current[e.code] = false;
    };

    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, [onTogglePause]);

  // Main Game Loop
  useEffect(() => {
    let animationFrameId: number;
    let lastTime = performance.now();

    const loop = (currentTime: number) => {
      const dt = Math.min((currentTime - lastTime) / 1000, 0.05);
      lastTime = currentTime;

      if (!isPaused) {
        updateGame(dt);
      }
      renderGame();

      animationFrameId = requestAnimationFrame(loop);
    };

    animationFrameId = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animationFrameId);
  }, [isPaused, stats, level]);

  // Update Game Physics & State Machines
  const updateGame = (dt: number) => {
    const p = playerRef.current;
    const keys = keysRef.current;

    // Camera shake decay
    if (cameraRef.current.shake > 0) {
      cameraRef.current.shake = Math.max(0, cameraRef.current.shake - dt * 15);
    }

    // Invulnerability timer
    if (p.invulnerableTimer > 0) {
      p.invulnerableTimer -= dt;
      p.hitFlash = Math.sin(p.invulnerableTimer * 25) > 0 ? 1 : 0;
    } else {
      p.hitFlash = 0;
    }

    // Breakable rocks hitFlash decay
    for (const rock of breakableRocksRef.current) {
      if (rock.hitFlash > 0) {
        rock.hitFlash = Math.max(0, rock.hitFlash - dt);
      }
    }

    // Cooldowns
    if (p.dashCooldown > 0) p.dashCooldown -= dt;

    // Stamina regen
    if (stats.stamina < stats.maxStamina && !p.isBlocking && !p.isDashing) {
      const newStamina = Math.min(stats.maxStamina, stats.stamina + dt * 25);
      if (Math.abs(newStamina - stats.stamina) > 0.5) {
        onUpdateStats({ ...stats, stamina: newStamina });
      }
    }

    // Actions & Inputs
    const keyLeft = keys['ArrowLeft'] || keys['KeyA'];
    const keyRight = keys['ArrowRight'] || keys['KeyD'];
    const keyUp = keys['ArrowUp'] || keys['KeyW'];
    const keyDown = keys['ArrowDown'] || keys['KeyS'];
    const keyJump = keys['KeyK'] || keys['Space'];
    const keyAttack = keys['KeyJ'] || keys['KeyZ'];
    const keySkill = keys['KeyU'] || keys['KeyC'];
    const keyDash = keys['KeyL'] || keys['ShiftLeft'] || keys['KeyX'];
    const keyBlock = keys['KeyB'];
    const keyPotion = keys['KeyI'] || keys['KeyQ'];
    const keyInteract = keys['KeyE'];

    // Check if player is overlapping a climbable Ladder (scenes/props/ladder.tscn)
    const overlappingLadder = laddersRef.current.find((lad) =>
      checkOverlap(p.x + 4, p.y, p.w - 8, p.h, lad.x - 4, lad.y, lad.w + 8, lad.h)
    );

    if (!overlappingLadder) {
      p.isClimbing = false;
    } else if ((keyUp || keyDown) && p.attackTimer <= 0 && !p.isDashing) {
      p.isClimbing = true;
      p.isGrounded = false;
      p.jumpCount = 0;
    }

    // Potion check
    if (keyPotion && stats.potions > 0 && stats.hp < stats.maxHp) {
      keys['KeyI'] = false;
      keys['KeyQ'] = false;
      const healedHp = Math.min(stats.maxHp, stats.hp + 45);
      onUpdateStats({ ...stats, hp: healedHp, potions: stats.potions - 1 });
      soundManager.playPotion();
      spawnDamageNumber(p.x, p.y - 20, '+45 HP', false, true, true);
      spawnParticles(p.x + p.w / 2, p.y + p.h / 2, '#22c55e', 12, 'magic');
    }

    // Dash
    if (keyDash && p.dashCooldown <= 0 && stats.stamina >= 20 && !p.isDashing) {
      p.isClimbing = false;
      p.isDashing = true;
      p.dashTimer = 0.22;
      p.dashCooldown = 0.75;
      p.invulnerableTimer = 0.25;
      p.state = 'dash';
      p.vx = p.facing * 520;
      p.vy = 0;
      onUpdateStats({ ...stats, stamina: Math.max(0, stats.stamina - 20) });
      soundManager.playDash();
      spawnParticles(p.x + p.w / 2, p.y + p.h / 2, '#38bdf8', 8, 'dust');
    }

    // Attack Trigger
    if (keyAttack && p.attackTimer <= 0 && !p.isDashing && !p.isBlocking) {
      p.isClimbing = false;
      p.attackStep = p.attackStep >= 3 ? 1 : p.attackStep + 1;
      p.attackTimer = 0.32;
      p.state = p.attackStep === 1 ? 'attack1' : p.attackStep === 2 ? 'attack2' : 'attack3';
      soundManager.playAttack(p.attackStep);
      keys['KeyJ'] = false;
      keys['KeyZ'] = false;

      executePlayerAttack(p.attackStep);
    }

    // Heavy Skill: Whirlwind / Slam
    if (keySkill && p.skillTimer <= 0 && stats.stamina >= 35 && !p.isDashing) {
      p.isClimbing = false;
      p.skillTimer = 0.55;
      p.state = 'skill';
      onUpdateStats({ ...stats, stamina: Math.max(0, stats.stamina - 35) });
      soundManager.playSkill();
      cameraRef.current.shake = 6;
      keys['KeyU'] = false;
      keys['KeyC'] = false;

      executePlayerSkill();
    }

    // Blocking
    p.isBlocking = !!keyBlock && p.isGrounded && p.attackTimer <= 0 && !p.isDashing && !p.isClimbing;

    // Movement & Timers
    if (p.isDashing) {
      p.dashTimer -= dt;
      p.vx = p.facing * 480;
      p.vy = 0;
      if (Math.random() < 0.4) {
        spawnParticles(p.x + p.w / 2, p.y + p.h / 2, '#60a5fa', 2, 'line');
      }
      if (p.dashTimer <= 0) {
        p.isDashing = false;
      }
    } else if (p.isClimbing && overlappingLadder) {
      p.state = 'climb';
      // Gently center player horizontally on ladder when climbing vertically
      let moveDir = 0;
      if (keyLeft) moveDir -= 1;
      if (keyRight) moveDir += 1;
      p.vx = moveDir * (stats.speed * 0.65);
      if (moveDir !== 0) p.facing = moveDir as 1 | -1;

      if (keyUp) {
        p.vy = -150;
      } else if (keyDown) {
        p.vy = 150;
      } else {
        p.vy = 0;
      }

      if (keyJump) {
        keys['KeyK'] = false;
        keys['Space'] = false;
        p.isClimbing = false;
        p.vy = -420;
        p.jumpCount = 1;
        p.state = 'jump';
        soundManager.playJump();
      }
    } else if (p.attackTimer > 0) {
      p.attackTimer -= dt;
      p.vx *= 0.85;
    } else if (p.skillTimer > 0) {
      p.skillTimer -= dt;
      p.vx *= 0.9;
    } else if (p.isBlocking) {
      p.state = 'block';
      p.vx = 0;
    } else {
      // Normal walk / run
      let moveDir = 0;
      if (keyLeft) moveDir -= 1;
      if (keyRight) moveDir += 1;

      if (moveDir !== 0) {
        p.facing = moveDir as 1 | -1;
        p.vx = moveDir * stats.speed;
        if (p.isGrounded) {
          p.state = 'run';
          if (Math.random() < 0.15) {
            spawnParticles(p.x + (p.facing === 1 ? 4 : p.w - 4), p.y + p.h, '#a8a29e', 1, 'dust');
          }
        }
      } else {
        p.vx = 0;
        if (p.isGrounded) {
          p.state = 'idle';
        }
      }

      // Jump (Space / K, or Up/W when not on a ladder)
      const wantsJump = keyJump || ((keyUp) && !overlappingLadder);
      if (wantsJump) {
        keys['KeyK'] = false;
        keys['Space'] = false;
        if (!overlappingLadder) {
          keys['ArrowUp'] = false;
          keys['KeyW'] = false;
        }

        if (p.isGrounded) {
          p.vy = -450;
          p.isGrounded = false;
          p.jumpCount = 1;
          p.state = 'jump';
          soundManager.playJump();
          spawnParticles(p.x + p.w / 2, p.y + p.h, '#e2e8f0', 5, 'dust');
        } else if (p.jumpCount < 2) {
          p.vy = -400;
          p.jumpCount = 2;
          p.state = 'jump';
          soundManager.playDoubleJump();
          spawnParticles(p.x + p.w / 2, p.y + p.h, '#38bdf8', 8, 'magic');
        }
      }
    }

    // Apply Gravity when not dashing and not climbing
    if (!p.isDashing && !p.isClimbing) {
      p.vy += 980 * dt;
      if (p.vy > 650) p.vy = 650;
      if (!p.isGrounded && p.attackTimer <= 0 && p.skillTimer <= 0) {
        p.state = p.vy < 0 ? 'jump' : 'fall';
      }
    }

    // Move player horizontally and resolve solid wall / BreakableRock collisions
    p.x += p.vx * dt;
    p.x = Math.max(0, Math.min(level.width - p.w, p.x));

    // BreakableRock horizontal collision
    for (const rock of breakableRocksRef.current) {
      if (rock.hp <= 0) continue;
      if (checkOverlap(p.x, p.y + 4, p.w, p.h - 8, rock.x, rock.y, rock.w, rock.h)) {
        if (p.vx > 0) p.x = rock.x - p.w;
        else if (p.vx < 0) p.x = rock.x + rock.w;
      }
    }

    p.y += p.vy * dt;

    // Platform & BreakableRock vertical collisions
    if (!p.isClimbing) {
      p.isGrounded = false;

      // Solid & One-Way Platforms
      for (const plat of level.platforms) {
        if (plat.type === 'hazard') {
          if (checkOverlap(p.x, p.y, p.w, p.h, plat.x, plat.y, plat.w, plat.h)) {
            takePlayerDamage(18, 'hazard');
          }
          continue;
        }

        if (plat.type === 'solid') {
          if (checkOverlap(p.x, p.y, p.w, p.h, plat.x, plat.y, plat.w, plat.h)) {
            if (p.vy > 0 && p.y + p.h - p.vy * dt <= plat.y + 14) {
              p.y = plat.y - p.h;
              p.vy = 0;
              p.isGrounded = true;
              p.jumpCount = 0;
            } else if (p.vy < 0 && p.y >= plat.y + plat.h - 15) {
              p.y = plat.y + plat.h;
              p.vy = 0;
            } else if (p.vx > 0) {
              p.x = plat.x - p.w;
            } else if (p.vx < 0) {
              p.x = plat.x + plat.w;
            }
          }
        } else if (plat.type === 'one-way' || plat.type === 'crumbly') {
          const prevBottom = p.y + p.h - p.vy * dt;
          if (p.vy >= 0 && prevBottom <= plat.y + 10 && p.y + p.h >= plat.y) {
            if (p.x + p.w > plat.x && p.x < plat.x + plat.w) {
              p.y = plat.y - p.h;
              p.vy = 0;
              p.isGrounded = true;
              p.jumpCount = 0;
            }
          }
        }
      }

      // Stand on top of unbroken BreakableRocks
      for (const rock of breakableRocksRef.current) {
        if (rock.hp <= 0) continue;
        const prevBottom = p.y + p.h - p.vy * dt;
        if (p.vy >= 0 && prevBottom <= rock.y + 10 && p.y + p.h >= rock.y) {
          if (p.x + p.w > rock.x + 4 && p.x < rock.x + rock.w - 4) {
            p.y = rock.y - p.h;
            p.vy = 0;
            p.isGrounded = true;
            p.jumpCount = 0;
          }
        }
      }
    }

    // Pit fall check
    if (p.y > level.height) {
      takePlayerDamage(999, 'hazard');
    }

    // Collectible Rewards pickup check (scenes/props/collectible_reward.tscn)
    for (const col of collectiblesRef.current) {
      if (col.collected) continue;
      if (checkOverlap(p.x, p.y, p.w, p.h, col.x - 8, col.y - 8, 28, 28)) {
        col.collected = true;
        soundManager.playCoin();
        const healAmt = col.type === 'red_potion' ? 35 : col.type === 'blue_potion' ? 20 : 0;
        const goldAmt = col.type === 'gold_key' ? 50 : 25;
        const gemAmt = col.type === 'upgrade_token' ? 2 : 0;
        const xpAmt = 30;
        const newHp = Math.min(stats.maxHp, stats.hp + healAmt);
        const newXp = stats.xp + xpAmt;
        onUpdateStats({
          ...stats,
          gold: stats.gold + goldAmt,
          gems: stats.gems + gemAmt,
          xp: newXp,
          hp: newHp,
        });
        spawnDamageNumber(col.x + 8, col.y - 12, col.labelZh, false, true, true);
        spawnParticles(
          col.x + 8,
          col.y + 8,
          col.type === 'blue_potion' ? '#38bdf8' : '#facc15',
          14,
          'spark'
        );
      }
    }

    // Interactive Check (Chests, Altars, Ladders, Goal)
    p.interactTarget = overlappingLadder && !p.isClimbing ? 'ladder' : null;
    p.interactId = overlappingLadder ? overlappingLadder.id : null;

    // Chests
    for (const chest of chestsRef.current) {
      if (
        !chest.opened &&
        Math.abs(p.x + p.w / 2 - (chest.x + 16)) < 45 &&
        Math.abs(p.y + p.h - (chest.y + 32)) < 48
      ) {
        p.interactTarget = 'chest';
        p.interactId = chest.id;
        if (keyInteract) {
          chest.opened = true;
          soundManager.playChestOpen();
          onOpenChest(chest.id, chest.loot);
          spawnDamageNumber(chest.x + 16, chest.y - 20, `+${chest.loot.gold}G`, false, true, true);
          spawnParticles(chest.x + 16, chest.y + 10, '#facc15', 20, 'spark');
          keys['KeyE'] = false;
        }
        break;
      }
    }

    // Altars
    for (const altar of altarsRef.current) {
      if (
        Math.abs(p.x + p.w / 2 - (altar.x + 16)) < 45 &&
        Math.abs(p.y + p.h - (altar.y + 40)) < 50
      ) {
        p.interactTarget = 'altar';
        p.interactId = altar.id;
        if (keyInteract && !altar.activated) {
          altar.activated = true;
          soundManager.playLevelUp();
          onActivateAltar(altar.id);
          onUpdateStats({ ...stats, hp: stats.maxHp });
          spawnDamageNumber(altar.x + 16, altar.y - 25, 'CHECKPOINT & HEAL!', true, true, true);
          spawnParticles(altar.x + 16, altar.y, '#38bdf8', 25, 'magic');
          keys['KeyE'] = false;
        }
        break;
      }
    }

    // Goal Reach
    if (Math.abs(p.x - level.goalPoint.x) < 42 && Math.abs(p.y - level.goalPoint.y) < 64) {
      onLevelComplete();
    }

    // Update Enemies AI State Machine & Flush Bridge/Terrain Physics
    updateEnemies(dt);

    // Update Particles
    particlesRef.current = particlesRef.current.filter((pt) => {
      pt.x += pt.vx * dt;
      pt.y += pt.vy * dt;
      pt.life -= dt;
      return pt.life > 0;
    });

    // Update Damage Numbers
    damageNumbersRef.current = damageNumbersRef.current.filter((dn) => {
      dn.y -= dt * 35;
      dn.life -= dt;
      return dn.life > 0;
    });

    // Smooth Camera Follow with view bounds clamping
    const maxCamY = Math.max(0, compiledTilemapRef.current.mainGroundY + 64 - VIEW_H);
    const targetCamX = p.x + p.w / 2 - VIEW_W / 2;
    const targetCamY = p.y + p.h - 280;

    cameraRef.current.targetX = Math.max(0, Math.min(level.width - VIEW_W, targetCamX));
    cameraRef.current.targetY = Math.max(0, Math.min(maxCamY, targetCamY));

    cameraRef.current.x += (cameraRef.current.targetX - cameraRef.current.x) * (dt * 8);
    cameraRef.current.y += (cameraRef.current.targetY - cameraRef.current.y) * (dt * 8);
  };

  // Player attacks execution (hits Enemies AND BreakableRocks)
  const executePlayerAttack = (comboStep: number) => {
    const p = playerRef.current;
    const reach = comboStep === 3 ? 55 : 42;
    const attackX = p.facing === 1 ? p.x + p.w : p.x - reach;
    const attackY = p.y - 8;
    const attackW = reach;
    const attackH = p.h + 16;

    spawnParticles(
      p.facing === 1 ? p.x + p.w + 10 : p.x - 10,
      p.y + p.h / 2,
      comboStep === 3 ? '#f97316' : '#93c5fd',
      8,
      'slash'
    );

    let baseDmg = stats.attack * (comboStep === 3 ? 1.6 : comboStep === 2 ? 1.2 : 1.0);
    const isCrit = Math.random() < stats.critRate;
    if (isCrit) baseDmg *= 1.8;

    for (const enemy of enemiesRef.current) {
      if (enemy.hp <= 0) continue;
      if (checkOverlap(attackX, attackY, attackW, attackH, enemy.x, enemy.y, enemy.w, enemy.h)) {
        damageEnemy(enemy, Math.round(baseDmg), isCrit, p.facing);
      }
    }

    // Strike BreakableRocks (scenes/props/breakable_rock.tscn)
    for (const rock of breakableRocksRef.current) {
      if (rock.hp <= 0) continue;
      if (checkOverlap(attackX, attackY, attackW, attackH, rock.x, rock.y, rock.w, rock.h)) {
        damageBreakableRock(rock, Math.round(baseDmg));
      }
    }
  };

  const executePlayerSkill = () => {
    const p = playerRef.current;
    const aoeRadius = 90;
    const aoeX = p.x + p.w / 2 - aoeRadius;
    const aoeY = p.y + p.h / 2 - aoeRadius;
    const aoeSize = aoeRadius * 2;

    for (let i = 0; i < 24; i++) {
      const angle = (i / 24) * Math.PI * 2;
      particlesRef.current.push({
        x: p.x + p.w / 2 + Math.cos(angle) * 45,
        y: p.y + p.h / 2 + Math.sin(angle) * 35,
        vx: Math.cos(angle) * 160,
        vy: Math.sin(angle) * 160,
        size: 4,
        color: '#38bdf8',
        life: 0.35,
        maxLife: 0.35,
        shape: 'line',
      });
    }

    const dmg = Math.round(stats.attack * 2.2);
    for (const enemy of enemiesRef.current) {
      if (enemy.hp <= 0) continue;
      if (checkOverlap(aoeX, aoeY, aoeSize, aoeSize, enemy.x, enemy.y, enemy.w, enemy.h)) {
        damageEnemy(enemy, dmg, true, (enemy.x > p.x ? 1 : -1) as 1 | -1);
      }
    }

    for (const rock of breakableRocksRef.current) {
      if (rock.hp <= 0) continue;
      if (checkOverlap(aoeX, aoeY, aoeSize, aoeSize, rock.x, rock.y, rock.w, rock.h)) {
        damageBreakableRock(rock, dmg);
      }
    }
  };

  const damageBreakableRock = (rock: BreakableRock, dmg: number) => {
    rock.hp = Math.max(0, rock.hp - dmg);
    rock.hitFlash = 0.2;
    soundManager.playHit(false);
    cameraRef.current.shake = 4;

    spawnDamageNumber(rock.x + rock.w / 2, rock.y - 10, dmg, false, false);
    spawnParticles(rock.x + rock.w / 2, rock.y + rock.h / 2, '#a8a29e', 10, 'dust');

    if (rock.hp <= 0) {
      soundManager.playCoin();
      onUpdateStats({ ...stats, gold: stats.gold + rock.lootGold });
      spawnDamageNumber(
        rock.x + rock.w / 2,
        rock.y - 24,
        `SHATTERED! +${rock.lootGold}G`,
        true,
        true,
        true
      );
      spawnParticles(rock.x + rock.w / 2, rock.y + rock.h / 2, '#facc15', 18, 'spark');
    }
  };

  /**
   * PhysicsCheck & Surface Resolver for Ground Enemies (scripts/general/physics_check.gd):
   * - Checks if there is a continuous platform or bridge immediately ahead (`hasGroundAhead`)
   *   so enemies walk seamlessly across flush wooden bridges (`plat.style === 'bridge'`)
   *   and turn around at unbridged cliff edges or solid obstacles.
   * - Resolves vertical gravity & snaps enemy feet (`enemy.y + enemy.h`) to the exact top
   *   surface `plat.y` of any ground or bridge platform, eliminating any bridge clipping (`穿模`)!
   */
  const moveGroundEnemyWithBridgePhysics = (enemy: Enemy, dt: number) => {
    const footY = enemy.y + enemy.h;
    const probeX = enemy.facing === 1 ? enemy.x + enemy.w + 4 : enemy.x - 4;

    // 1. Check forward floor raycast (includes solid ground AND one-way wooden bridges/ledges)
    const hasFloorAhead = level.platforms.some(
      (plat) =>
        (plat.type === 'solid' || plat.type === 'one-way') &&
        probeX >= plat.x &&
        probeX <= plat.x + plat.w &&
        Math.abs(plat.y - footY) <= 14
    );

    // 2. Check forward wall or unbroken BreakableRock obstacle
    const hitsWallAhead =
      level.platforms.some(
        (plat) =>
          plat.type === 'solid' &&
          probeX >= plat.x &&
          probeX <= plat.x + plat.w &&
          plat.y < footY - 8 &&
          plat.y + plat.h > enemy.y + 4
      ) ||
      breakableRocksRef.current.some(
        (rock) =>
          rock.hp > 0 &&
          probeX >= rock.x &&
          probeX <= rock.x + rock.w &&
          rock.y < footY - 4 &&
          rock.y + rock.h > enemy.y + 4
      );

    if (!hasFloorAhead || hitsWallAhead) {
      enemy.facing = (enemy.facing === 1 ? -1 : 1) as 1 | -1;
      enemy.vx = -enemy.vx;
    } else {
      enemy.x += enemy.vx * dt;
    }

    // Clamp inside level bounds
    enemy.x = Math.max(8, Math.min(level.width - enemy.w - 8, enemy.x));

    // 3. Apply vertical gravity & snap enemy feet to exact platform / wooden bridge surface `plat.y`
    enemy.vy = (enemy.vy || 0) + 980 * dt;
    if (enemy.vy > 500) enemy.vy = 500;
    const prevBottom = enemy.y + enemy.h;
    enemy.y += enemy.vy * dt;

    for (const plat of level.platforms) {
      if (plat.type !== 'solid' && plat.type !== 'one-way') continue;
      // Horizontal overlap with enemy's core foot base
      if (enemy.x + enemy.w - 6 > plat.x && enemy.x + 6 < plat.x + plat.w) {
        if (
          enemy.vy >= 0 &&
          prevBottom <= plat.y + 12 &&
          enemy.y + enemy.h >= plat.y
        ) {
          enemy.y = plat.y - enemy.h;
          enemy.vy = 0;
          break;
        }
      }
    }
  };

  // Enemy state machine updates
  const updateEnemies = (dt: number) => {
    const p = playerRef.current;

    for (const enemy of enemiesRef.current) {
      if (enemy.hp <= 0) continue;

      if (enemy.hitFlash > 0) enemy.hitFlash -= dt;
      if (enemy.attackCooldown > 0) enemy.attackCooldown -= dt;

      const distToPlayer = Math.hypot(p.x - enemy.x, p.y - enemy.y);

      // --- BEE AI (Sine flight & dive attack) ---
      if (enemy.type === 'bee') {
        enemy.stateTimer += dt;
        if (distToPlayer < 240) {
          enemy.state = 'chase';
          const angle = Math.atan2(p.y - enemy.y, p.x - enemy.x);
          enemy.vx = Math.cos(angle) * 110;
          enemy.vy = Math.sin(angle) * 110;
          enemy.facing = p.x > enemy.x ? 1 : -1;

          if (distToPlayer < 40 && enemy.attackCooldown <= 0) {
            enemy.state = 'attack';
            enemy.attackCooldown = 1.6;
            takePlayerDamage(enemy.damage, 'bee');
            soundManager.playHit(false);
          }
        } else {
          enemy.state = 'patrol';
          enemy.vx = Math.cos(enemy.stateTimer * 1.5) * 60;
          enemy.vy = Math.sin(enemy.stateTimer * 3) * 30;
          enemy.facing = enemy.vx >= 0 ? 1 : -1;
        }

        enemy.x += enemy.vx * dt;
        enemy.y += enemy.vy * dt;
      }

      // --- BOAR AI (Patrol ground/bridges & ferocious charge) ---
      else if (enemy.type === 'boar') {
        enemy.stateTimer += dt;

        if (distToPlayer < 260 && Math.abs(p.y + p.h - (enemy.y + enemy.h)) < 72) {
          enemy.state = 'chase';
          enemy.facing = p.x > enemy.x ? 1 : -1;
          enemy.vx = enemy.facing * 170;

          if (Math.random() < 0.25) {
            spawnParticles(
              enemy.x + (enemy.facing === 1 ? 0 : enemy.w),
              enemy.y + enemy.h,
              '#78716c',
              1,
              'dust'
            );
          }

          if (checkOverlap(enemy.x, enemy.y, enemy.w, enemy.h, p.x, p.y, p.w, p.h)) {
            if (enemy.attackCooldown <= 0) {
              enemy.attackCooldown = 1.2;
              takePlayerDamage(enemy.damage, 'boar');
            }
          }
        } else {
          enemy.state = 'patrol';
          if (Math.abs(enemy.x - enemy.originX) > enemy.patrolRange) {
            enemy.facing = enemy.x > enemy.originX ? -1 : 1;
          }
          enemy.vx = enemy.facing * 52;
        }

        moveGroundEnemyWithBridgePhysics(enemy, dt);
      }

      // --- SNAIL AI (Slow patrol across bridges/ledges & shell hide defense) ---
      else if (enemy.type === 'snail') {
        enemy.stateTimer += dt;

        if (
          enemy.hitFlash > 0 ||
          (distToPlayer < 68 && Math.abs(p.y + p.h - (enemy.y + enemy.h)) < 50)
        ) {
          enemy.state = 'hit';
          enemy.vx = 0;
          if (checkOverlap(enemy.x, enemy.y, enemy.w, enemy.h, p.x, p.y, p.w, p.h)) {
            if (enemy.attackCooldown <= 0) {
              enemy.attackCooldown = 1.3;
              takePlayerDamage(enemy.damage, 'snail');
            }
          }
        } else {
          enemy.state = 'patrol';
          if (Math.abs(enemy.x - enemy.originX) > enemy.patrolRange) {
            enemy.facing = enemy.x > enemy.originX ? -1 : 1;
          }
          enemy.vx = enemy.facing * 28;
        }

        moveGroundEnemyWithBridgePhysics(enemy, dt);
      }

      // --- BOSS GUARDIAN AI (3-Stage State Machine) ---
      else if (enemy.type === 'boss') {
        enemy.stateTimer += dt;
        enemy.facing = p.x > enemy.x ? 1 : -1;

        if (enemy.state === 'patrol') {
          if (distToPlayer > 120) {
            enemy.vx = enemy.facing * 70;
          } else {
            enemy.vx = 0;
            if (enemy.attackCooldown <= 0) {
              enemy.state = 'windup';
              enemy.stateTimer = 0;
            }
          }
        } else if (enemy.state === 'windup') {
          enemy.vx = 0;
          if (enemy.stateTimer > 0.6) {
            enemy.state = 'attack';
            enemy.stateTimer = 0;
            soundManager.playAttack(3);
            cameraRef.current.shake = 8;

            const bossReach = 90;
            const bAtkX = enemy.facing === 1 ? enemy.x + enemy.w : enemy.x - bossReach;
            if (checkOverlap(bAtkX, enemy.y, bossReach, enemy.h + 20, p.x, p.y, p.w, p.h)) {
              takePlayerDamage(enemy.damage, 'boss');
            }

            for (let i = 0; i < 16; i++) {
              particlesRef.current.push({
                x: enemy.facing === 1 ? enemy.x + enemy.w + 20 : enemy.x - 20,
                y: enemy.y + enemy.h - 5,
                vx: (enemy.facing === 1 ? 1 : -1) * (180 + Math.random() * 80),
                vy: -Math.random() * 120,
                size: 5,
                color: '#ef4444',
                life: 0.45,
                maxLife: 0.45,
                shape: 'line',
              });
            }
          }
        } else if (enemy.state === 'attack') {
          enemy.vx = 0;
          if (enemy.stateTimer > 0.4) {
            enemy.state = 'recovery';
            enemy.stateTimer = 0;
          }
        } else if (enemy.state === 'recovery') {
          enemy.vx = 0;
          if (enemy.stateTimer > 0.7) {
            enemy.state = 'patrol';
            enemy.attackCooldown = 1.4;
          }
        }

        moveGroundEnemyWithBridgePhysics(enemy, dt);
      }
    }
  };

  // Damage Enemy
  const damageEnemy = (enemy: Enemy, dmg: number, isCrit: boolean, attackDir: 1 | -1) => {
    const finalDmg =
      enemy.type === 'snail' && enemy.state === 'hit'
        ? Math.max(1, Math.round(dmg * 0.6))
        : dmg;
    enemy.hp = Math.max(0, enemy.hp - finalDmg);
    enemy.hitFlash = 0.22;
    soundManager.playHit(isCrit);

    // Safe horizontal knockback (only if floor exists)
    enemy.x += attackDir * (isCrit ? 18 : 10);

    spawnDamageNumber(enemy.x + enemy.w / 2, enemy.y - 15, finalDmg, isCrit, false);

    spawnParticles(
      enemy.x + enemy.w / 2,
      enemy.y + enemy.h / 2,
      isCrit ? '#fbbf24' : '#ef4444',
      isCrit ? 14 : 7,
      'spark'
    );

    if (enemy.hp <= 0) {
      enemy.state = 'dead';
      soundManager.playCoin();
      const goldDrop = Math.floor(enemy.score / 2);
      const newXp = stats.xp + enemy.score;
      let newLevel = stats.level;
      let newXpToNext = stats.xpToNext;
      let maxHp = stats.maxHp;
      let attack = stats.attack;

      if (newXp >= newXpToNext) {
        newLevel += 1;
        newXpToNext = Math.round(newXpToNext * 1.5);
        maxHp += 15;
        attack += 4;
        soundManager.playLevelUp();
        spawnDamageNumber(
          playerRef.current.x,
          playerRef.current.y - 30,
          'LEVEL UP!',
          true,
          true,
          true
        );
      }

      onUpdateStats({
        ...stats,
        gold: stats.gold + goldDrop,
        xp: newXp,
        level: newLevel,
        xpToNext: newXpToNext,
        maxHp,
        attack,
        hp: Math.min(maxHp, stats.hp + 10),
      });

      spawnParticles(enemy.x + enemy.w / 2, enemy.y + enemy.h / 2, '#fbbf24', 20, 'spark');
    }
  };

  // Player Damage & Hurt Reaction
  const takePlayerDamage = (rawDmg: number, _source: string) => {
    const p = playerRef.current;
    if (p.invulnerableTimer > 0 || stats.hp <= 0) return;

    if (p.isBlocking) {
      soundManager.playParry();
      spawnDamageNumber(p.x, p.y - 20, 'BLOCKED!', false, true);
      spawnParticles(p.x + (p.facing === 1 ? p.w : 0), p.y + p.h / 2, '#38bdf8', 12, 'spark');
      p.invulnerableTimer = 0.35;
      return;
    }

    const actualDmg = Math.max(1, rawDmg - stats.defense);
    const newHp = Math.max(0, stats.hp - actualDmg);
    p.invulnerableTimer = 0.8;
    cameraRef.current.shake = 10;
    soundManager.playHurt();

    spawnDamageNumber(p.x, p.y - 20, `-${actualDmg}`, false, true);
    spawnParticles(p.x + p.w / 2, p.y + p.h / 2, '#ef4444', 10, 'blood');

    onUpdateStats({ ...stats, hp: newHp });

    if (newHp <= 0) {
      p.state = 'dead';
      onPlayerDeath();
    }
  };

  // Helpers
  const checkOverlap = (
    x1: number,
    y1: number,
    w1: number,
    h1: number,
    x2: number,
    y2: number,
    w2: number,
    h2: number
  ) => {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
  };

  const spawnParticles = (
    x: number,
    y: number,
    color: string,
    count: number,
    shape: Particle['shape'] = 'circle'
  ) => {
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 40 + Math.random() * 120;
      particlesRef.current.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 20,
        size: shape === 'line' ? 8 : 2 + Math.random() * 3,
        color,
        life: 0.25 + Math.random() * 0.25,
        maxLife: 0.5,
        shape,
      });
    }
  };

  const spawnDamageNumber = (
    x: number,
    y: number,
    value: number | string,
    isCrit: boolean,
    isPlayer: boolean,
    isHeal: boolean = false
  ) => {
    damageNumbersRef.current.push({
      id: Math.random().toString(),
      x,
      y,
      value,
      isCrit,
      isPlayer,
      isHeal,
      life: 0.9,
      maxLife: 0.9,
    });
  };

  // ===================== AUTHENTIC GODOT TILEMAP & NATIVE ART RENDERING =====================
  const renderGame = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.imageSmoothingEnabled = false;

    const cam = cameraRef.current;
    const shakeOffsetX = cam.shake > 0 ? (Math.random() - 0.5) * cam.shake * 2 : 0;
    const shakeOffsetY = cam.shake > 0 ? (Math.random() - 0.5) * cam.shake * 2 : 0;
    const renderCamX = Math.round(cam.x + shakeOffsetX);
    const renderCamY = Math.round(cam.y + shakeOffsetY);

    ctx.save();
    ctx.clearRect(0, 0, VIEW_W, VIEW_H);

    // 1. Multi-Layer Parallax Forest Background (Trees/*.png & Forest-1.png bushes)
    renderBackground(ctx, renderCamX, renderCamY);

    // Apply Camera Translation for world layers
    ctx.save();
    ctx.translate(-renderCamX, -renderCamY);

    // 2. BackgroundTiles & World Structures Layer (z = -2: Forest-2.png Hollow Trees, Buildings.png Cabins/Watchtowers/Fortresses, Waterfalls, Bridge Railings)
    renderWorldBackgroundProps(ctx, level, compiledTilemapRef.current);

    // 3. WaterTiles Layer (z = -1: animated river surface, body, deep water & aquatic flora from Forest-1.png)
    renderWaterTiles(ctx, compiledTilemapRef.current);

    // 4. GeometryTiles Layer (z = 0: Terrain Set 0 Grass & Rock rules, Forest-2.png mushroom shelves, flush WoodenBridge plank decks)
    renderGeometryTiles(ctx, level, compiledTilemapRef.current);

    // 5. Interactive Objects (z = +1: Ladders, BreakableRocks, Collectibles, SavePoint Rune Monoliths, Chest2 & Chest)
    renderInteractiveObjects(ctx);

    // 6. Native Sprite Enemies (Bee sheets, Boar sheets, Snail sheets, Boss) with exact foot-to-bridge alignment
    renderEnemies(ctx);

    // 7. Native Sprite Player (Generic-Character sheets including Climb animation)
    renderPlayer(ctx);

    // 8. ForegroundTiles Layer (z = +2: single-cell mushroom accents from Forest-1.png)
    renderForegroundAccents(ctx, compiledTilemapRef.current);

    // 9. Particle Effects & Damage Numbers
    renderParticles(ctx);
    renderDamageNumbers(ctx);

    ctx.restore(); // Restore camera translation

    // 10. In-world prompts with GameButtons.png pixel icons
    renderWorldPrompts(ctx, renderCamX, renderCamY);

    ctx.restore();
  };

  const renderBackground = (ctx: CanvasRenderingContext2D, camX: number, camY: number) => {
    const time = performance.now() * 0.001;
    const screenGroundY = Math.round(compiledTilemapRef.current.mainGroundY - camY);

    renderParallaxForest(ctx, camX, VIEW_W, VIEW_H, level.theme, screenGroundY);

    // Sunbeams / God-Rays filtering through forest canopy
    ctx.save();
    ctx.globalAlpha = 0.07 + Math.sin(time * 1.2) * 0.025;
    const rayGrad = ctx.createLinearGradient(0, 0, VIEW_W, VIEW_H);
    rayGrad.addColorStop(
      0,
      level.theme === 'sanctum' ? '#f43f5e' : level.theme === 'ruins' ? '#fbbf24' : '#fef08a'
    );
    rayGrad.addColorStop(1, 'transparent');
    ctx.fillStyle = rayGrad;
    for (let r = 0; r < 5; r++) {
      ctx.beginPath();
      ctx.moveTo(80 + r * 130 - ((camX * 0.3) % 150), 0);
      ctx.lineTo(140 + r * 130 - ((camX * 0.3) % 150), 0);
      ctx.lineTo(240 + r * 130 - ((camX * 0.3) % 150), VIEW_H);
      ctx.lineTo(140 + r * 130 - ((camX * 0.3) % 150), VIEW_H);
      ctx.fill();
    }
    ctx.restore();

    // Floating Forest Spores / Fireflies
    ctx.fillStyle =
      level.theme === 'ruins' ? '#fde047' : level.theme === 'sanctum' ? '#fda4af' : '#a7f3d0';
    for (let s = 0; s < 12; s++) {
      const spX = (s * 60 + time * 22) % VIEW_W;
      const spY = (60 + Math.sin(time * 2 + s) * 40 + s * 18) % (VIEW_H - 60);
      const pulse = 0.3 + Math.sin(time * 3 + s) * 0.5;
      if (pulse > 0) {
        ctx.globalAlpha = pulse * 0.7;
        ctx.fillRect(spX, spY, 2, 2);
      }
    }
    ctx.globalAlpha = 1;
  };

  const renderInteractiveObjects = (ctx: CanvasRenderingContext2D) => {
    const time = performance.now() * 0.001;
    const buildings = assetLoader.getCached(ASSET_PATHS.buildings);
    const propsRocks = assetLoader.getCached(ASSET_PATHS.propsRocks);
    const forest1 = assetLoader.getCached(ASSET_PATHS.forest1);
    const hiveImg = assetLoader.getCached(ASSET_PATHS.hive);
    const signChars = assetLoader.getCached(ASSET_PATHS.signCharacters);
    const chest2Img = assetLoader.getCached(ASSET_PATHS.chest2);
    const chest1Img = assetLoader.getCached(ASSET_PATHS.chest);

    // 1. Climbable Wooden Ladders assembled from verified Buildings.png rail & rung crops
    for (const lad of laddersRef.current) {
      if (buildings) {
        const rail = BUILDINGS_CROPS.SCAFFOLD_POST_A; // (213, 192, 6, 32)
        for (let oy = 0; oy < lad.h; oy += 32) {
          const segH = Math.min(32, lad.h - oy);
          ctx.drawImage(
            buildings,
            rail.x,
            rail.y,
            rail.w,
            segH,
            Math.round(lad.x),
            Math.round(lad.y + oy),
            5,
            segH
          );
          ctx.drawImage(
            buildings,
            rail.x,
            rail.y,
            rail.w,
            segH,
            Math.round(lad.x + lad.w - 5),
            Math.round(lad.y + oy),
            5,
            segH
          );
        }
        for (let ry = 4; ry < lad.h - 2; ry += 10) {
          ctx.drawImage(
            buildings,
            211,
            84,
            26,
            4,
            Math.round(lad.x + 3),
            Math.round(lad.y + ry),
            Math.max(8, lad.w - 6),
            4
          );
        }
      } else {
        ctx.fillStyle = '#92400e';
        ctx.fillRect(lad.x, lad.y, 3, lad.h);
        ctx.fillRect(lad.x + lad.w - 3, lad.y, 3, lad.h);
      }
    }

    const genBoulders = assetLoader.getCached(ASSET_PATHS.genBoulders);

    // 2. Breakable Rocks using custom-generated organic pixel-art boulders & crystal crags
    for (const rock of breakableRocksRef.current) {
      if (rock.hp <= 0) continue;
      ctx.save();
      if (rock.hitFlash > 0) {
        ctx.filter = 'brightness(2.2)';
      }
      if (genBoulders) {
        const crop =
          rock.variant === 'mossy'
            ? GENERATED_BOULDER_CROPS.MOSSY_BOULDER
            : GENERATED_BOULDER_CROPS.CRYSTAL_CRAG;
        ctx.drawImage(
          genBoulders,
          crop.x,
          crop.y,
          crop.w,
          crop.h,
          Math.round(rock.x - 8),
          Math.round(rock.y - 12),
          Math.round(rock.w + 16),
          Math.round(rock.h + 12)
        );
      } else if (propsRocks) {
        const crop = ROCKS_CROPS.BOULDER_MOSSY;
        ctx.drawImage(
          propsRocks,
          crop.x,
          crop.y,
          crop.w,
          crop.h,
          Math.round(rock.x - 4),
          Math.round(rock.y - 4),
          Math.round(rock.w + 8),
          Math.round(rock.h + 4)
        );
      } else {
        ctx.fillStyle = '#57534e';
        ctx.fillRect(rock.x, rock.y, rock.w, rock.h);
      }

      if (rock.hp < rock.maxHp) {
        const pct = rock.hp / rock.maxHp;
        ctx.fillStyle = 'rgba(0,0,0,0.75)';
        ctx.fillRect(rock.x + 4, rock.y - 10, rock.w - 8, 4);
        ctx.fillStyle = '#f59e0b';
        ctx.fillRect(rock.x + 5, rock.y - 9, (rock.w - 10) * pct, 2);
      }
      ctx.restore();
    }

    // 3. Collectible Rewards using exact single-item crops from Forest-1.png & Hive.png
    for (const col of collectiblesRef.current) {
      if (col.collected) continue;
      const bob = Math.sin(time * 4 + col.x * 0.05) * 3;
      const drawY = Math.round(col.y + bob);

      ctx.save();
      const glow = ctx.createRadialGradient(col.x + 8, drawY + 8, 2, col.x + 8, drawY + 8, 16);
      glow.addColorStop(
        0,
        col.type === 'blue_potion'
          ? 'rgba(56, 189, 248, 0.55)'
          : col.type === 'red_potion'
          ? 'rgba(244, 63, 94, 0.5)'
          : 'rgba(250, 204, 21, 0.55)'
      );
      glow.addColorStop(1, 'transparent');
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(col.x + 8, drawY + 8, 16, 0, Math.PI * 2);
      ctx.fill();

      if (forest1 && col.type === 'blue_potion') {
        const p = FOREST1_CROPS.POTION_BLUE;
        ctx.drawImage(forest1, p.x, p.y, p.w, p.h, Math.round(col.x + 2), drawY, 12, 15);
      } else if (forest1 && col.type === 'red_potion') {
        const p = FOREST1_CROPS.POTION_RED;
        ctx.drawImage(forest1, p.x, p.y, p.w, p.h, Math.round(col.x + 2), drawY, 12, 15);
      } else if (col.type === 'upgrade_token') {
        if (hiveImg) {
          const gem = HIVE_CROPS.BLUE_GEM;
          ctx.drawImage(hiveImg, gem.x, gem.y, gem.w, gem.h, Math.round(col.x + 1), drawY, 14, 16);
        } else if (signChars) {
          ctx.drawImage(signChars, 240, 0, 16, 16, Math.round(col.x), drawY, 16, 16);
        }
      } else if (forest1 && col.type === 'gold_key') {
        const k = FOREST1_CROPS.GOLD_KEY;
        ctx.drawImage(forest1, k.x, k.y, k.w, k.h, Math.round(col.x), drawY + 3, 16, 10);
      }
      ctx.restore();
    }

    // 4. Goal Waypoint Beacon (in front of Mine Stone Entrance drawn in renderWorldBackgroundProps)
    const g = level.goalPoint;
    const groundY = compiledTilemapRef.current.mainGroundY;

    ctx.save();
    const portalGlow = ctx.createRadialGradient(
      g.x + 28,
      groundY - 38,
      4,
      g.x + 28,
      groundY - 38,
      42
    );
    portalGlow.addColorStop(0, 'rgba(56, 189, 248, 0.55)');
    portalGlow.addColorStop(0.6, 'rgba(99, 102, 241, 0.25)');
    portalGlow.addColorStop(1, 'transparent');
    ctx.fillStyle = portalGlow;
    ctx.beginPath();
    ctx.arc(g.x + 28, groundY - 38, 42, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();

    ctx.fillStyle = '#38bdf8';
    ctx.font = '8px "Press Start 2P"';
    ctx.textAlign = 'center';
    ctx.fillText(
      level.zoneIndex < 3 ? `ZONE ${level.zoneIndex + 1} >>` : 'SANCTUM CLEAR >>',
      g.x + 28,
      groundY - 108 + Math.sin(time * 3) * 3
    );

    // 5. SavePoint / Checkpoint Altar using custom-generated Ancient Elven Waystone Shrine + SignCharacters.png rune
    for (const altar of altarsRef.current) {
      if (genBoulders) {
        const waystone = GENERATED_BOULDER_CROPS.WAYSTONE_SHRINE;
        ctx.drawImage(
          genBoulders,
          waystone.x,
          waystone.y,
          waystone.w,
          waystone.h,
          Math.round(altar.x - 10),
          Math.round(altar.y - 20),
          52,
          60
        );
      } else if (propsRocks) {
        const mono = ROCKS_CROPS.MONOLITH_SLIM;
        ctx.drawImage(
          propsRocks,
          mono.x,
          mono.y,
          mono.w,
          mono.h,
          Math.round(altar.x - 2),
          Math.round(altar.y - 26),
          36,
          66
        );
      } else {
        ctx.fillStyle = '#334155';
        ctx.fillRect(altar.x, altar.y, 32, 40);
      }

      if (signChars) {
        const runeBob = Math.sin(time * 3.2) * 2;
        const runeSrcX = altar.activated ? 240 : 96;
        if (altar.activated) {
          ctx.save();
          const halo = ctx.createRadialGradient(
            altar.x + 16,
            altar.y + 2,
            2,
            altar.x + 16,
            altar.y + 2,
            24
          );
          halo.addColorStop(0, 'rgba(56, 189, 248, 0.55)');
          halo.addColorStop(1, 'transparent');
          ctx.fillStyle = halo;
          ctx.beginPath();
          ctx.arc(altar.x + 16, altar.y + 2, 24, 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
        }
        ctx.drawImage(
          signChars,
          runeSrcX,
          0,
          16,
          16,
          altar.x + 4,
          Math.round(altar.y - 8 + runeBob),
          24,
          24
        );
      }
    }

    // 6. Native Pixel Chests from Chest2.png & Chest.png (exact regions from scenes/props/chest.tscn)
    chestsRef.current.forEach((chest, idx) => {
      if (chest2Img && idx % 2 === 0) {
        const srcX = chest.opened ? 31 : 0;
        const srcW = chest.opened ? 33 : 34;
        ctx.drawImage(chest2Img, srcX, 0, srcW, 32, chest.x, chest.y, 32, 32);
      } else if (chest1Img) {
        const frameX = chest.opened ? 22 : 0;
        ctx.drawImage(chest1Img, frameX, 0, 22, 22, chest.x, chest.y + 4, 30, 28);
      } else {
        ctx.fillStyle = '#78350f';
        ctx.fillRect(chest.x, chest.y + 8, 32, 24);
      }
    });
  };

  /**
   * Renders enemies with exact bottom-of-feet alignment (`enemy.y + enemy.h`)
   * so that when crossing flush wooden bridges or terrain platforms, their feet
   * stand cleanly ON TOP of the bridge planks with zero clipping (`0 穿模`)!
   */
  const renderEnemies = (ctx: CanvasRenderingContext2D) => {
    for (const enemy of enemiesRef.current) {
      if (enemy.hp <= 0) continue;

      ctx.save();
      if (enemy.hitFlash > 0) {
        ctx.filter = 'brightness(2.2)';
      }

      if (enemy.type === 'bee') {
        const beeFly = assetLoader.getCached(ASSET_PATHS.beeFly);
        const beeAttack = assetLoader.getCached(ASSET_PATHS.beeAttack);
        const beeHit = assetLoader.getCached(ASSET_PATHS.beeHit);

        const currentBeeSheet =
          enemy.hitFlash > 0 ? beeHit : enemy.state === 'attack' ? beeAttack : beeFly;

        if (currentBeeSheet) {
          const frameIdx = Math.floor(
            (performance.now() * (enemy.state === 'attack' ? 0.012 : 0.008)) % 4
          );
          ctx.save();
          ctx.translate(Math.round(enemy.x + enemy.w / 2), Math.round(enemy.y + enemy.h / 2));
          ctx.scale(-enemy.facing, 1);
          ctx.drawImage(currentBeeSheet, frameIdx * 64, 0, 64, 64, -32, -32, 64, 64);
          ctx.restore();
        }
      } else if (enemy.type === 'boar') {
        const boarIdle = assetLoader.getCached(ASSET_PATHS.boarIdle);
        const boarWalk = assetLoader.getCached(ASSET_PATHS.boarWalk);
        const boarRun = assetLoader.getCached(ASSET_PATHS.boarRun);
        const boarHit =
          assetLoader.getCached(ASSET_PATHS.boarHitWhite) ||
          assetLoader.getCached(ASSET_PATHS.boarHit);

        let sheet = boarWalk || boarIdle;
        let frameCount = 6;
        let speed = 0.008;

        if (enemy.hitFlash > 0 && boarHit) {
          sheet = boarHit;
          frameCount = 4;
          speed = 0.012;
        } else if (enemy.state === 'chase' && boarRun) {
          sheet = boarRun;
          frameCount = 6;
          speed = 0.014;
        } else if (Math.abs(enemy.vx) < 5 && boarIdle) {
          sheet = boarIdle;
          frameCount = 4;
          speed = 0.006;
        }

        if (sheet) {
          const frameIdx = Math.floor((performance.now() * speed) % frameCount);
          ctx.save();
          // Anchor directly to bottom of boar collision box (enemy.y + enemy.h)
          ctx.translate(Math.round(enemy.x + enemy.w / 2), Math.round(enemy.y + enemy.h));
          ctx.scale(-enemy.facing, 1);
          ctx.drawImage(sheet, frameIdx * 48, 0, 48, 32, -24, -32, 48, 32);
          ctx.restore();
        }
      } else if (enemy.type === 'snail') {
        const snailWalk = assetLoader.getCached(ASSET_PATHS.snailWalk);
        const snailHide = assetLoader.getCached(ASSET_PATHS.snailHide);

        const isHiding = enemy.state === 'hit' || enemy.hitFlash > 0;
        const sheet = isHiding ? snailHide || snailWalk : snailWalk;

        if (sheet) {
          const frameIdx = isHiding
            ? Math.min(3, Math.floor((performance.now() * 0.01) % 4))
            : Math.floor((performance.now() * 0.006) % 8);
          ctx.save();
          // Anchor directly to bottom of snail collision box (enemy.y + enemy.h)
          ctx.translate(Math.round(enemy.x + enemy.w / 2), Math.round(enemy.y + enemy.h));
          ctx.scale(-enemy.facing, 1);
          ctx.drawImage(sheet, frameIdx * 48, 0, 48, 32, -24, -32, 48, 32);
          ctx.restore();
        }
      } else if (enemy.type === 'boss') {
        const bossSheet =
          assetLoader.getCached('/art/imported/Generic-Character/png/purple/char_purple_1.png') ||
          assetLoader.getCached(
            `/art/imported/Generic-Character/png/${characterColor}/char_${characterColor}_1.png`
          );

        if (bossSheet) {
          let row = 0;
          let frameCount = 6;
          let speed = 0.008;
          if (enemy.state === 'patrol' && Math.abs(enemy.vx) > 5) {
            row = 2;
            frameCount = 8;
            speed = 0.01;
          } else if (enemy.state === 'windup') {
            row = 8;
            frameCount = 8;
            speed = 0.014;
          } else if (enemy.state === 'attack') {
            row = 1;
            frameCount = 8;
            speed = 0.018;
          }
          const frameIdx = Math.floor((performance.now() * speed) % frameCount);
          ctx.save();
          ctx.translate(Math.round(enemy.x + enemy.w / 2), Math.round(enemy.y + enemy.h - 46));
          ctx.scale(enemy.facing * 1.65, 1.65);
          ctx.drawImage(bossSheet, frameIdx * 56, row * 56, 56, 56, -28, -28, 56, 56);
          ctx.restore();
        }

        // Boss Health Bar above head
        const barW = 100;
        const barX = enemy.x + enemy.w / 2 - barW / 2;
        ctx.fillStyle = 'rgba(0,0,0,0.75)';
        ctx.fillRect(barX, enemy.y - 18, barW, 8);
        const hpPct = Math.max(0, enemy.hp / enemy.maxHp);
        ctx.fillStyle = '#ef4444';
        ctx.fillRect(barX + 1, enemy.y - 17, (barW - 2) * hpPct, 6);
      }

      ctx.restore();
    }
  };

  const renderPlayer = (ctx: CanvasRenderingContext2D) => {
    const p = playerRef.current;
    if (p.hitFlash > 0 && Math.floor(performance.now() / 60) % 2 === 0) {
      return;
    }

    const sheet1 = assetLoader.getCached(
      `/art/imported/Generic-Character/png/${characterColor}/char_${characterColor}_1.png`
    );
    const sheet2 = assetLoader.getCached(
      `/art/imported/Generic-Character/png/${characterColor}/char_${characterColor}_2.png`
    );

    if (sheet1) {
      let targetImg = sheet1;
      let row = 0;
      let startCol = 0;
      let frameCount = 6;
      let animSpeed = 0.008;

      if (p.state === 'idle') {
        row = 0;
        startCol = 0;
        frameCount = 6;
        animSpeed = 0.008;
      } else if (p.state === 'climb') {
        // Animation Guide 2 - Row 6: Ladder Climbing animation from char_2
        if (sheet2) {
          targetImg = sheet2;
          row = 6;
          startCol = 0;
          frameCount = 8;
          animSpeed = Math.abs(p.vy) > 5 ? 0.012 : 0;
        } else {
          row = 2;
          startCol = 0;
          frameCount = 4;
          animSpeed = 0.008;
        }
      } else if (p.state === 'attack1' || p.state === 'attack2') {
        row = 1;
        startCol = p.state === 'attack2' ? 2 : 0;
        frameCount = 4;
        animSpeed = 0.015;
      } else if (p.state === 'attack3') {
        row = 1;
        startCol = 0;
        frameCount = 8;
        animSpeed = 0.016;
      } else if (p.state === 'run') {
        row = 2;
        startCol = 0;
        frameCount = 8;
        animSpeed = 0.012;
      } else if (p.state === 'jump') {
        row = 3;
        startCol = 2;
        frameCount = 3;
        animSpeed = 0.01;
      } else if (p.state === 'fall') {
        row = 4;
        startCol = 1;
        frameCount = 3;
        animSpeed = 0.01;
      } else if (p.state === 'dash') {
        if (sheet2) {
          targetImg = sheet2;
          row = 2;
          startCol = 0;
          frameCount = 6;
          animSpeed = 0.018;
        } else {
          row = 2;
          startCol = 0;
          frameCount = 8;
        }
      } else if (p.state === 'skill') {
        row = 8;
        startCol = 0;
        frameCount = 8;
        animSpeed = 0.018;
      } else if (p.state === 'block') {
        row = 10;
        startCol = 0;
        frameCount = 3;
        animSpeed = 0.006;
      } else if (p.state === 'hurt') {
        row = 5;
        startCol = 0;
        frameCount = 4;
        animSpeed = 0.012;
      } else if (p.state === 'dead') {
        row = 6;
        startCol = 0;
        frameCount = 8;
        animSpeed = 0.008;
      }

      const frameIdx =
        animSpeed > 0 ? Math.floor((performance.now() * animSpeed) % frameCount) : 0;
      const col = startCol + frameIdx;
      const srcX = (col % 8) * 56;
      const srcY = row * 56;

      ctx.save();
      ctx.translate(Math.round(p.x + p.w / 2), Math.round(p.y + p.h - 28));
      ctx.scale(p.facing, 1);
      ctx.drawImage(targetImg, srcX, srcY, 56, 56, -28, -28, 56, 56);
      ctx.restore();
    } else {
      ctx.fillStyle =
        characterColor === 'blue' ? '#3b82f6' : characterColor === 'red' ? '#ef4444' : '#10b981';
      ctx.fillRect(p.x, p.y, p.w, p.h);
      ctx.fillStyle = '#f8fafc';
      ctx.fillRect(p.facing === 1 ? p.x + p.w - 8 : p.x, p.y + 8, 8, 6);
    }
  };

  const renderParticles = (ctx: CanvasRenderingContext2D) => {
    for (const pt of particlesRef.current) {
      const alpha = pt.life / pt.maxLife;
      ctx.fillStyle = pt.color;
      ctx.globalAlpha = alpha;

      if (pt.shape === 'line') {
        ctx.fillRect(pt.x, pt.y, pt.size, 2);
      } else {
        ctx.fillRect(pt.x - pt.size / 2, pt.y - pt.size / 2, pt.size, pt.size);
      }
    }
    ctx.globalAlpha = 1;
  };

  const renderDamageNumbers = (ctx: CanvasRenderingContext2D) => {
    ctx.font = '8px "Press Start 2P"';
    ctx.textAlign = 'center';

    for (const dn of damageNumbersRef.current) {
      const alpha = Math.max(0, dn.life / dn.maxLife);
      ctx.globalAlpha = alpha;

      if (dn.isHeal) {
        ctx.fillStyle = '#22c55e';
      } else if (dn.isPlayer) {
        ctx.fillStyle = '#f87171';
      } else if (dn.isCrit) {
        ctx.fillStyle = '#facc15';
      } else {
        ctx.fillStyle = '#ffffff';
      }

      ctx.fillText(String(dn.value), dn.x, dn.y);
    }
    ctx.globalAlpha = 1;
  };

  const renderWorldPrompts = (ctx: CanvasRenderingContext2D, camX: number, camY: number) => {
    const p = playerRef.current;
    const gameButtons = assetLoader.getCached(ASSET_PATHS.gameButtons);

    if (p.interactTarget) {
      const screenX = Math.round(p.x + p.w / 2 - camX);
      const screenY = Math.round(p.y - 18 - camY);
      const promptText =
        p.interactTarget === 'ladder'
          ? 'W/↑ CLIMB'
          : p.interactTarget === 'altar'
          ? 'PRAY'
          : 'OPEN';

      ctx.fillStyle = 'rgba(15, 23, 42, 0.88)';
      ctx.fillRect(screenX - 42, screenY - 15, 84, 18);
      ctx.strokeStyle = '#38bdf8';
      ctx.strokeRect(screenX - 42, screenY - 15, 84, 18);

      // Draw animated cropped [E] keycap from GameButtons.png (x = 160 + frame*16, y = 96, w = 16, h = 16)
      if (gameButtons) {
        const keyFrame = Math.floor((performance.now() * 0.005) % 4);
        ctx.drawImage(
          gameButtons,
          160 + keyFrame * 16,
          96,
          16,
          16,
          screenX - 38,
          screenY - 14,
          14,
          14
        );
      }

      ctx.fillStyle = '#ffffff';
      ctx.font = '7px "Press Start 2P"';
      ctx.textAlign = 'center';
      ctx.fillText(promptText, screenX + 8, screenY - 3);
    }
  };

  // Virtual touch button triggers
  const triggerTouch = (code: string, isDown: boolean) => {
    setTouchControlsActive(true);
    keysRef.current[code] = isDown;
  };

  return (
    <div className="relative w-full h-full flex flex-col items-center justify-between bg-slate-950 overflow-hidden select-none">
      {/* Dynamic Scaled Canvas Container */}
      <div className="relative flex-1 w-full flex items-center justify-center p-1 sm:p-2 min-h-0">
        <div className="relative w-full h-full max-w-[calc((100vh-130px)*16/9)] max-h-[calc(100vh-130px)] aspect-[16/9] shadow-2xl rounded-lg overflow-hidden border border-slate-800/80 bg-slate-950">
          <canvas
            ref={canvasRef}
            width={VIEW_W}
            height={VIEW_H}
            className="w-full h-full object-contain block pixelated"
          />

          {/* Scanlines CRT overlay */}
          {showScanlines && <div className="absolute inset-0 crt-overlay pointer-events-none" />}

          {/* Connected World Zone Progression Banner */}
          <div className="absolute top-2.5 left-3 flex flex-wrap items-center gap-2 pointer-events-none">
            <span className="text-[9px] font-pixel text-amber-400 bg-slate-950/85 px-2 py-0.5 rounded border border-amber-500/30">
              {level.chapter}
            </span>
            <span className="text-xs font-fantasy font-bold text-slate-100 drop-shadow">
              {level.name}
            </span>
            <div className="hidden sm:flex items-center space-x-1 bg-slate-950/80 px-2 py-0.5 rounded border border-slate-800 text-[9px] font-pixel">
              <span className={level.zoneIndex === 1 ? 'text-emerald-400' : 'text-slate-500'}>
                I.翠谷瀑布
              </span>
              <span className="text-slate-600">→</span>
              <span className={level.zoneIndex === 2 ? 'text-amber-400' : 'text-slate-500'}>
                II.金叶哨站
              </span>
              <span className="text-slate-600">→</span>
              <span className={level.zoneIndex === 3 ? 'text-rose-400' : 'text-slate-500'}>
                III.绯红要塞
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Responsive Virtual Gamepad / Touch Buttons */}
      <div className="w-full max-w-4xl px-4 py-1.5 shrink-0 flex items-center justify-between text-slate-300 bg-slate-950/90 border-t border-slate-900">
        {/* D-Pad Buttons (including Up/Down for Ladders!) */}
        <div className="flex items-center space-x-1.5">
          <button
            onTouchStart={() => triggerTouch('ArrowLeft', true)}
            onTouchEnd={() => triggerTouch('ArrowLeft', false)}
            onMouseDown={() => triggerTouch('ArrowLeft', true)}
            onMouseUp={() => triggerTouch('ArrowLeft', false)}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-blue-600 border border-slate-700/80 flex items-center justify-center font-bold text-base select-none shadow"
            title="Move Left (A / ←)"
          >
            ←
          </button>
          <button
            onTouchStart={() => triggerTouch('ArrowUp', true)}
            onTouchEnd={() => triggerTouch('ArrowUp', false)}
            onMouseDown={() => triggerTouch('ArrowUp', true)}
            onMouseUp={() => triggerTouch('ArrowUp', false)}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-blue-600 border border-slate-700/80 flex items-center justify-center font-bold text-base select-none shadow"
            title="Climb Up / Jump (W / ↑)"
          >
            ↑
          </button>
          <button
            onTouchStart={() => triggerTouch('ArrowDown', true)}
            onTouchEnd={() => triggerTouch('ArrowDown', false)}
            onMouseDown={() => triggerTouch('ArrowDown', true)}
            onMouseUp={() => triggerTouch('ArrowDown', false)}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-blue-600 border border-slate-700/80 flex items-center justify-center font-bold text-base select-none shadow"
            title="Climb Down (S / ↓)"
          >
            ↓
          </button>
          <button
            onTouchStart={() => triggerTouch('ArrowRight', true)}
            onTouchEnd={() => triggerTouch('ArrowRight', false)}
            onMouseDown={() => triggerTouch('ArrowRight', true)}
            onMouseUp={() => triggerTouch('ArrowRight', false)}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-blue-600 border border-slate-700/80 flex items-center justify-center font-bold text-base select-none shadow"
            title="Move Right (D / →)"
          >
            →
          </button>
          <button
            onTouchStart={() => triggerTouch('KeyB', true)}
            onTouchEnd={() => triggerTouch('KeyB', false)}
            onMouseDown={() => triggerTouch('KeyB', true)}
            onMouseUp={() => triggerTouch('KeyB', false)}
            className="w-11 h-10 rounded-lg bg-slate-900 active:bg-cyan-600 border border-slate-700/80 flex flex-col items-center justify-center font-bold text-[8px] font-pixel text-cyan-300 select-none shadow"
            title="Block (B)"
          >
            BLOCK
            <span className="text-[7px] text-slate-500">[B]</span>
          </button>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center space-x-1.5 sm:space-x-2">
          <button
            onClick={() => {
              triggerTouch('KeyE', true);
              setTimeout(() => triggerTouch('KeyE', false), 150);
            }}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-emerald-600 border border-slate-700/80 flex flex-col items-center justify-center text-[9px] font-pixel text-emerald-400 select-none"
            title="Interact (E)"
          >
            [E]
            <span className="text-[7px] text-slate-400">USE</span>
          </button>

          <button
            onClick={() => {
              triggerTouch('KeyI', true);
              setTimeout(() => triggerTouch('KeyI', false), 150);
            }}
            className="w-10 h-10 rounded-lg bg-slate-900 active:bg-rose-600 border border-slate-700/80 flex flex-col items-center justify-center text-[9px] font-pixel text-rose-400 select-none"
            title="Potion (I)"
          >
            [I]
            <span className="text-[7px] text-slate-400">HP</span>
          </button>

          <button
            onClick={() => {
              triggerTouch('KeyL', true);
              setTimeout(() => triggerTouch('KeyL', false), 150);
            }}
            className="w-11 h-11 rounded-lg bg-sky-950/80 active:bg-sky-600 border border-sky-500/40 flex flex-col items-center justify-center text-[9px] font-pixel text-sky-300 select-none"
            title="Dash (L)"
          >
            DASH
            <span className="text-[7px] text-sky-400">[L]</span>
          </button>

          <button
            onClick={() => {
              triggerTouch('KeyU', true);
              setTimeout(() => triggerTouch('KeyU', false), 150);
            }}
            className="w-11 h-11 rounded-lg bg-purple-950/80 active:bg-purple-600 border border-purple-500/40 flex flex-col items-center justify-center text-[9px] font-pixel text-purple-300 select-none"
            title="Skill (U)"
          >
            SKILL
            <span className="text-[7px] text-purple-400">[U]</span>
          </button>

          <button
            onClick={() => {
              triggerTouch('KeyJ', true);
              setTimeout(() => triggerTouch('KeyJ', false), 150);
            }}
            className="w-12 h-12 rounded-full bg-red-950/90 active:bg-red-600 border-2 border-red-500/60 flex flex-col items-center justify-center font-pixel text-[11px] text-red-200 select-none shadow-lg"
            title="Attack (J)"
          >
            ATK
            <span className="text-[7px] text-red-400">[J]</span>
          </button>

          <button
            onClick={() => {
              triggerTouch('KeyK', true);
              setTimeout(() => triggerTouch('KeyK', false), 150);
            }}
            className="w-12 h-12 rounded-full bg-emerald-950/90 active:bg-emerald-600 border-2 border-emerald-500/60 flex flex-col items-center justify-center font-pixel text-[11px] text-emerald-200 select-none shadow-lg"
            title="Jump (K)"
          >
            JUMP
            <span className="text-[7px] text-emerald-400">[K]</span>
          </button>
        </div>
      </div>
    </div>
  );
};
