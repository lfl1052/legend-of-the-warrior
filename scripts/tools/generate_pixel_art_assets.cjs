const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const OUT_DIR = path.join(__dirname, '../../art/generated');
if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

function hex(str, a = 255) {
  const clean = str.replace('#', '');
  const num = parseInt(clean, 16);
  return [(num >> 16) & 255, (num >> 8) & 255, num & 255, a];
}

function hash2d(x, y, seed = 1) {
  let n = Math.imul(x, 374761393) + Math.imul(y, 668265263) + Math.imul(seed, 1442695041);
  n = (n ^ (n >>> 13)) >>> 0;
  n = Math.imul(n, 1274126177) >>> 0;
  return ((n ^ (n >>> 16)) >>> 0) / 4294967296;
}

const BAYER4 = [
  [0 / 16, 8 / 16, 2 / 16, 10 / 16],
  [12 / 16, 4 / 16, 14 / 16, 6 / 16],
  [3 / 16, 11 / 16, 1 / 16, 9 / 16],
  [15 / 16, 7 / 16, 13 / 16, 5 / 16],
];

function bayerDither(x, y, t) {
  return t > BAYER4[y & 3][x & 3];
}

function setPx(png, x, y, color) {
  const ix = Math.floor(x);
  const iy = Math.floor(y);
  if (ix < 0 || ix >= png.width || iy < 0 || iy >= png.height) return;
  const idx = (iy * png.width + ix) * 4;
  const a = (color[3] ?? 255) / 255;
  if (a >= 0.99) {
    png.data[idx] = color[0];
    png.data[idx + 1] = color[1];
    png.data[idx + 2] = color[2];
    png.data[idx + 3] = 255;
  } else if (a > 0) {
    const dstA = png.data[idx + 3] / 255;
    const outA = a + dstA * (1 - a);
    if (outA > 0) {
      png.data[idx] = Math.round((color[0] * a + png.data[idx] * dstA * (1 - a)) / outA);
      png.data[idx + 1] = Math.round((color[1] * a + png.data[idx + 1] * dstA * (1 - a)) / outA);
      png.data[idx + 2] = Math.round((color[2] * a + png.data[idx + 2] * dstA * (1 - a)) / outA);
      png.data[idx + 3] = Math.round(outA * 255);
    }
  }
}

function getAlpha(png, x, y) {
  if (x < 0 || x >= png.width || y < 0 || y >= png.height) return 0;
  return png.data[(y * png.width + x) * 4 + 3];
}

function applyPixelOutline(png, outlineColor = hex('#12161f'), region = null) {
  const x0 = region ? region.x : 0;
  const y0 = region ? region.y : 0;
  const x1 = region ? region.x + region.w : png.width;
  const y1 = region ? region.y + region.h : png.height;

  const toOutline = [];
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      if (getAlpha(png, x, y) === 0) {
        if (
          (x > x0 && getAlpha(png, x - 1, y) > 200) ||
          (x < x1 - 1 && getAlpha(png, x + 1, y) > 200) ||
          (y > y0 && getAlpha(png, x, y - 1) > 200) ||
          (y < y1 - 1 && getAlpha(png, x, y + 1) > 200)
        ) {
          toOutline.push([x, y]);
        }
      }
    }
  }
  for (const [x, y] of toOutline) {
    setPx(png, x, y, outlineColor);
  }
}

function drawLeafCluster(png, cx, cy, rx, ry, ramp, seed = 1) {
  for (let y = Math.floor(cy - ry - 3); y <= Math.ceil(cy + ry + 3); y++) {
    for (let x = Math.floor(cx - rx - 3); x <= Math.ceil(cx + rx + 3); x++) {
      const dx = (x - cx) / rx;
      const dy = (y - cy) / ry;
      const angle = Math.atan2(dy, dx);
      const scallop =
        0.12 * Math.sin(angle * 7 + seed) +
        0.08 * Math.cos(angle * 11 + seed * 2) +
        (hash2d(x >> 1, y >> 1, seed) - 0.5) * 0.14;
      const dist = Math.sqrt(dx * dx + dy * dy) + scallop;
      if (dist <= 1.0) {
        const light =
          (dx * -0.35 + dy * -0.65 + 0.55) +
          (hash2d(x, y, seed + 99) - 0.5) * 0.22;
        let col = ramp[1];
        if (dist > 0.84 || dy > 0.45) {
          col = ramp[0];
        } else if (light > 0.78) {
          col = bayerDither(x, y, (light - 0.78) * 4) ? ramp[4] : ramp[3];
        } else if (light > 0.52) {
          col = bayerDither(x, y, (light - 0.52) * 3.8) ? ramp[3] : ramp[2];
        } else if (light > 0.28) {
          col = bayerDither(x, y, (light - 0.28) * 4) ? ramp[2] : ramp[1];
        } else {
          col = ramp[0];
        }
        if (hash2d(x, y, seed + 7) > 0.88 && light > 0.45 && dist < 0.75) {
          col = ramp[Math.min(4, ramp.indexOf(col) + 1)];
        }
        setPx(png, x, y, col);
      }
    }
  }
}

// ============================================================================
// 1. ANCIENT HOLLOW SHRINE TREE (160x192)
// ============================================================================
function generateAncientHollowTree() {
  const W = 160;
  const H = 192;
  const png = new PNG({ width: W, height: H });

  const BARK = [
    hex('#1e1412'),
    hex('#33211d'),
    hex('#4f342b'),
    hex('#6e4b3c'),
    hex('#8f6550'),
  ];
  const MOSS = [
    hex('#112920'),
    hex('#1b4233'),
    hex('#2a6349'),
    hex('#458f63'),
    hex('#72bf80'),
  ];
  const SHROOM_CAP = [
    hex('#5e1924'),
    hex('#8f2431'),
    hex('#c43b3b'),
    hex('#e8684a'),
    hex('#ffdfb8'),
  ];
  const GOLD = [
    hex('#5c3317'),
    hex('#8f5422'),
    hex('#c7832c'),
    hex('#f2b63d'),
    hex('#fff199'),
  ];

  for (let y = 44; y <= 186; y++) {
    const t = (y - 44) / (186 - 44);
    const rootFlare = t > 0.65 ? Math.pow((t - 0.65) / 0.35, 1.8) * 34 : 0;
    const topFlare = t < 0.25 ? Math.pow((0.25 - t) / 0.25, 1.6) * 20 : 0;
    const curve = Math.sin(t * Math.PI * 1.4) * 4;
    const halfW = 24 + t * 8 + rootFlare + topFlare;
    const centerX = 80 + curve;

    for (let x = Math.floor(centerX - halfW - 4); x <= Math.ceil(centerX + halfW + 4); x++) {
      const dx = x - centerX;
      const normX = dx / halfW;

      if (t > 0.82) {
        const rootWave =
          Math.sin(dx * 0.16) * 6 +
          Math.cos(dx * 0.29 + 1.2) * 4 +
          (hash2d(x, y, 11) - 0.5) * 3;
        const maxRootY = 181 + rootWave - Math.abs(normX) * 6;
        if (y > maxRootY) continue;
      }

      if (Math.abs(normX) <= 1.0) {
        const ridgePhase = dx * 0.38 + Math.sin(y * 0.08 + dx * 0.05) * 1.7;
        const ridge = Math.sin(ridgePhase);
        const barkNoise = (hash2d(x, y >> 1, 21) - 0.5) * 0.35;
        const shade =
          (1 - Math.abs(normX) * 0.65) +
          (normX < 0 ? 0.18 : -0.15) +
          ridge * 0.22 +
          barkNoise;

        let col = BARK[2];
        if (Math.abs(normX) > 0.88 || ridge < -0.68) {
          col = BARK[0];
        } else if (shade > 0.92) {
          col = BARK[4];
        } else if (shade > 0.68) {
          col = BARK[3];
        } else if (shade > 0.42) {
          col = BARK[2];
        } else {
          col = BARK[1];
        }

        const mossChance =
          (t < 0.32 ? (0.32 - t) * 2.8 : 0) +
          (t > 0.72 ? (t - 0.72) * 2.2 : 0) +
          (normX < -0.25 ? 0.25 : 0) +
          Math.sin(x * 0.25 + y * 0.15) * 0.2;
        if (mossChance > 0.48 + hash2d(x, y, 33) * 0.25) {
          col = shade > 0.7 ? MOSS[3] : shade > 0.45 ? MOSS[2] : MOSS[1];
        }

        setPx(png, x, y, col);
      }
    }
  }

  const doorCX = 82;
  const doorTopY = 122;
  const doorBotY = 178;
  for (let y = doorTopY - 6; y <= doorBotY; y++) {
    for (let x = doorCX - 24; x <= doorCX + 24; x++) {
      const dx = x - doorCX;
      const dy = y - (doorTopY + 18);
      const archDist =
        y < doorTopY + 18
          ? Math.sqrt((dx / 16) ** 2 + (dy / 18) ** 2)
          : Math.abs(dx) / (16 + (y - (doorTopY + 18)) * 0.08);

      if (archDist <= 1.0 && y <= doorBotY - 2) {
        const glowDist = Math.sqrt((dx / 10) ** 2 + ((y - 142) / 14) ** 2);
        if (glowDist < 0.35) {
          setPx(png, x, y, GOLD[4]);
        } else if (glowDist < 0.65) {
          setPx(png, x, y, bayerDither(x, y, 0.5) ? GOLD[3] : GOLD[2]);
        } else if (glowDist < 0.95) {
          setPx(png, x, y, bayerDither(x, y, 0.5) ? BARK[2] : BARK[1]);
        } else {
          setPx(png, x, y, hex('#100b0c'));
        }
      } else if (archDist > 1.0 && archDist <= 1.28 && y <= doorBotY) {
        const rimLight = dx < 0 ? BARK[3] : BARK[1];
        setPx(png, x, y, rimLight);
      }
    }
  }

  const shelves = [
    { cx: 52, cy: 108, rx: 14, ry: 6 },
    { cx: 46, cy: 120, rx: 11, ry: 5 },
    { cx: 110, cy: 96, rx: 15, ry: 6 },
    { cx: 114, cy: 110, rx: 10, ry: 5 },
  ];
  for (const sh of shelves) {
    for (let y = sh.cy - sh.ry; y <= sh.cy + sh.ry; y++) {
      for (let x = sh.cx - sh.rx; x <= sh.cx + sh.rx; x++) {
        const dx = (x - sh.cx) / sh.rx;
        const dy = (y - sh.cy) / sh.ry;
        if (dx * dx + dy * dy <= 1.0) {
          if (dy > 0.25) {
            setPx(png, x, y, dx < 0 ? SHROOM_CAP[4] : GOLD[2]);
          } else {
            const isSpot = ((x + y * 3) % 7 === 0) && dy < 0 && Math.abs(dx) < 0.7;
            setPx(
              png,
              x,
              y,
              isSpot ? SHROOM_CAP[4] : dy < -0.3 ? SHROOM_CAP[3] : SHROOM_CAP[2]
            );
          }
        }
      }
    }
  }

  const canopyPuffs = [
    { cx: 42, cy: 58, rx: 28, ry: 22, s: 1 },
    { cx: 118, cy: 60, rx: 28, ry: 22, s: 2 },
    { cx: 28, cy: 44, rx: 22, ry: 18, s: 3 },
    { cx: 132, cy: 46, rx: 22, ry: 18, s: 4 },
    { cx: 58, cy: 36, rx: 32, ry: 24, s: 5 },
    { cx: 102, cy: 38, rx: 32, ry: 24, s: 6 },
    { cx: 80, cy: 26, rx: 36, ry: 22, s: 7 },
    { cx: 80, cy: 52, rx: 38, ry: 22, s: 8 },
  ];
  for (const p of canopyPuffs) {
    drawLeafCluster(png, p.cx, p.cy, p.rx, p.ry, MOSS, p.s);
  }

  for (let y = 66; y <= 92; y++) {
    for (let x = 114; x <= 134; x++) {
      if (x === 124 && y < 72) {
        setPx(png, x, y, BARK[1]);
        continue;
      }
      const dx = (x - 124) / 9;
      const dy = (y - 81) / 10;
      if (dx * dx + dy * dy <= 1.0) {
        const tier = Math.sin((y - 71) * 1.4);
        const col =
          tier < -0.4 ? GOLD[1] : dx < -0.2 ? GOLD[4] : dx < 0.3 ? GOLD[3] : GOLD[2];
        setPx(png, x, y, col);
      }
    }
  }

  applyPixelOutline(png, hex('#12161f'));

  const outPath = path.join(OUT_DIR, 'prop_ancient_hollow_tree.png');
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('Generated:', outPath);
}

// ============================================================================
// 2. DWARVEN MINE CAVE ENTRANCE (160x128) - Organic Moss Clusters & Faceted Rock
// ============================================================================
function generateDwarvenMineEntrance() {
  const W = 160;
  const H = 128;
  const png = new PNG({ width: W, height: H });

  const STONE = [
    hex('#181c26'),
    hex('#2b3244'),
    hex('#46526b'),
    hex('#687896'),
    hex('#96a8c4'),
  ];
  const MOSS = [
    hex('#112920'),
    hex('#1b4233'),
    hex('#2a6349'),
    hex('#458f63'),
    hex('#72bf80'),
  ];
  const WOOD = [
    hex('#241612'),
    hex('#3d261e'),
    hex('#5e3c2e'),
    hex('#825641'),
    hex('#a67458'),
  ];
  const CRYSTAL = [
    hex('#154c61'),
    hex('#20829e'),
    hex('#38b9d6'),
    hex('#73ebff'),
    hex('#dbffff'),
  ];

  // 1. Multi-lobe craggy rock formation (overlapping stone domes)
  const rockLobes = [
    { cx: 44, cy: 84, rx: 34, ry: 36, s: 1 },
    { cx: 116, cy: 86, rx: 34, ry: 34, s: 2 },
    { cx: 80, cy: 68, rx: 48, ry: 48, s: 3 },
    { cx: 26, cy: 98, rx: 20, ry: 22, s: 4 },
    { cx: 134, cy: 100, rx: 20, ry: 20, s: 5 },
  ];

  for (let y = 16; y <= 122; y++) {
    for (let x = 6; x < W - 6; x++) {
      let minDist = 999;
      for (const l of rockLobes) {
        const dx = (x - l.cx) / l.rx;
        const dy = (y - l.cy) / l.ry;
        const d =
          Math.sqrt(dx * dx + dy * dy) +
          0.07 * Math.sin(x * 0.25 + l.s) +
          0.05 * Math.cos(y * 0.3 + l.s);
        if (d < minDist) minDist = d;
      }

      const maxBotY = 119 + Math.sin(x * 0.22) * 2.5 + Math.cos(x * 0.45) * 1.5;
      if (minDist <= 1.0 && y <= maxBotY) {
        // Voronoi-like rock block striations & diagonal strata
        const strata =
          Math.sin((x * 0.12 + y * 0.22) + Math.sin(x * 0.08) * 1.5) * 0.25 +
          Math.cos(x * 0.19 - y * 0.14) * 0.18;
        const isCrack =
          Math.abs(Math.sin(x * 0.11 + y * 0.17) * Math.cos(x * 0.15 - y * 0.12)) < 0.04;
        const light =
          ((80 - x) / 140) * 0.35 +
          ((75 - y) / 110) * 0.45 +
          0.48 +
          strata +
          (hash2d(x, y, 91) - 0.5) * 0.14;

        let col = STONE[2];
        if (isCrack || minDist > 0.92) {
          col = STONE[0];
        } else if (light > 0.78) {
          col = bayerDither(x, y, (light - 0.78) * 4) ? STONE[4] : STONE[3];
        } else if (light > 0.54) {
          col = bayerDither(x, y, (light - 0.54) * 4) ? STONE[3] : STONE[2];
        } else if (light > 0.32) {
          col = STONE[2];
        } else {
          col = STONE[1];
        }
        setPx(png, x, y, col);
      }
    }
  }

  // 2. Organic leafy moss clusters growing on top of the crag (using drawLeafCluster!)
  const mossPuffs = [
    { cx: 38, cy: 50, rx: 22, ry: 12, s: 11 },
    { cx: 64, cy: 30, rx: 24, ry: 14, s: 12 },
    { cx: 94, cy: 32, rx: 24, ry: 14, s: 13 },
    { cx: 122, cy: 52, rx: 22, ry: 12, s: 14 },
  ];
  for (const mp of mossPuffs) {
    drawLeafCluster(png, mp.cx, mp.cy, mp.rx, mp.ry, MOSS, mp.s);
  }

  // Hanging moss vines along upper rock face
  for (const vx of [28, 36, 44, 114, 122, 130]) {
    const vLen = 10 + (vx % 9);
    const startY = vx < 80 ? 54 : 56;
    for (let i = 0; i < vLen; i++) {
      const wx = vx + Math.round(Math.sin(i * 0.5 + vx) * 1.2);
      setPx(png, wx, startY + i, i < vLen - 3 ? MOSS[3] : MOSS[2]);
    }
  }

  // 3. Shadowed cavern archway & mine cart tracks (x: 52..108, y: 54..120)
  for (let y = 54; y <= 120; y++) {
    for (let x = 52; x <= 108; x++) {
      const dx = (x - 80) / 24;
      const dy = (y - 78) / 24;
      const inside = y < 78 ? dx * dx + dy * dy <= 1.0 : Math.abs(dx) <= 1.0;
      if (inside) {
        const depth = Math.sqrt(dx * dx + ((y - 88) / 30) ** 2);
        let col = hex('#0c0e14');
        if (depth > 0.78) col = STONE[0];
        if (y >= 114 && (y % 3 === 0) && Math.abs(dx) < 0.78) {
          col = WOOD[2];
        }
        if (y >= 112 && (Math.abs(x - 68) === 1 || Math.abs(x - 92) === 1)) {
          col = STONE[3]; // steel rails
        }
        setPx(png, x, y, col);
      }
    }
  }

  // 4. Heavy timber mine archway beams
  for (let y = 56; y <= 120; y++) {
    for (const [px0, px1] of [
      [48, 57],
      [103, 112],
    ]) {
      for (let x = px0; x <= px1; x++) {
        const localX = (x - px0) / (px1 - px0);
        const grain = Math.sin(y * 0.25 + x * 1.1) * 0.15;
        const col =
          localX < 0.22
            ? WOOD[3]
            : localX < 0.58 + grain
              ? WOOD[2]
              : localX < 0.85
                ? WOOD[1]
                : WOOD[0];
        setPx(png, x, y, col);
      }
    }
  }
  for (let y = 46; y <= 57; y++) {
    for (let x = 42; x <= 118; x++) {
      const localY = (y - 46) / 11;
      const col =
        localY < 0.25 ? WOOD[4] : localY < 0.6 ? WOOD[3] : localY < 0.85 ? WOOD[2] : WOOD[1];
      setPx(png, x, y, col);
    }
  }
  // Iron bolt plates on timber corners
  for (const bx of [50, 105]) {
    for (let y = 49; y <= 54; y++) {
      for (let x = bx; x <= bx + 5; x++) {
        setPx(png, x, y, x === bx || y === 49 ? STONE[3] : STONE[1]);
      }
    }
  }
  for (let i = 0; i < 14; i++) {
    for (let w = 0; w < 5; w++) {
      setPx(png, 57 + i, 57 + (13 - i) + w, w < 2 ? WOOD[3] : WOOD[1]);
      setPx(png, 103 - i, 57 + (13 - i) + w, w < 2 ? WOOD[3] : WOOD[1]);
    }
  }

  // 5. Glowing cyan mineral crystals embedded on rock sides
  const crystals = [
    { bx: 30, by: 96, dx: -0.4, dy: -1, len: 13 },
    { bx: 35, by: 100, dx: -0.75, dy: -0.65, len: 10 },
    { bx: 126, by: 92, dx: 0.45, dy: -1, len: 14 },
    { bx: 122, by: 98, dx: 0.8, dy: -0.6, len: 10 },
  ];
  for (const c of crystals) {
    for (let t = 0; t <= c.len; t++) {
      const cxp = Math.round(c.bx + c.dx * t);
      const cyp = Math.round(c.by + c.dy * t);
      const r = Math.max(1, Math.round((1 - t / c.len) * 3.5));
      for (let ox = -r; ox <= r; ox++) {
        for (let oy = -r; oy <= r; oy++) {
          if (Math.abs(ox) + Math.abs(oy) <= r) {
            setPx(
              png,
              cxp + ox,
              cyp + oy,
              ox < 0 ? CRYSTAL[4] : ox === 0 ? CRYSTAL[3] : CRYSTAL[2]
            );
          }
        }
      }
    }
  }

  // 6. Hanging lantern with warm halo
  for (let y = 57; y <= 63; y++) setPx(png, 80, y, hex('#1a1c24'));
  for (let y = 64; y <= 73; y++) {
    for (let x = 76; x <= 84; x++) {
      const dx = Math.abs(x - 80);
      const dy = Math.abs(y - 68.5);
      if (y === 64 || y === 73) {
        if (dx <= 3) setPx(png, x, y, STONE[1]);
      } else if (dx <= 3) {
        setPx(
          png,
          x,
          y,
          dx <= 1 && dy <= 2 ? hex('#fff7b8') : dx <= 2 ? hex('#f5b342') : hex('#c76b24')
        );
      }
    }
  }

  applyPixelOutline(png, hex('#12161f'));

  const outPath = path.join(OUT_DIR, 'prop_dwarven_mine_entrance.png');
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('Generated:', outPath);
}

// ============================================================================
// 3. FOREST RANGER TIMBER WATCHTOWER / SHRINE PAVILION (128x160)
// ============================================================================
function generateForestWatchtower() {
  const W = 128;
  const H = 160;
  const png = new PNG({ width: W, height: H });

  const STONE = [
    hex('#1e222e'),
    hex('#32394a'),
    hex('#4d5870'),
    hex('#707f9c'),
    hex('#9cb0cf'),
  ];
  const WOOD = [
    hex('#241612'),
    hex('#3d261e'),
    hex('#5e3c2e'),
    hex('#825641'),
    hex('#a67458'),
  ];
  const ROOF_MOSS = [
    hex('#132b22'),
    hex('#1f4738'),
    hex('#2f6b50'),
    hex('#4a9668'),
    hex('#76c487'),
  ];
  const GOLD = [
    hex('#613718'),
    hex('#995b24'),
    hex('#d48e2f'),
    hex('#f7c244'),
    hex('#fff5a8'),
  ];

  for (let y = 112; y <= 154; y++) {
    const flare = Math.floor(((y - 112) / 42) * 6);
    for (let x = 28 - flare; x <= 100 + flare; x++) {
      const dx = x - 64;
      const dy = y - 134;
      const inArch =
        y >= 134 ? Math.abs(dx) < 15 : dx * dx + dy * dy < 15 * 15;
      if (inArch) {
        setPx(png, x, y, hex('#12151f'));
        continue;
      }
      const row = Math.floor((y - 112) / 6);
      const brickX = (x + (row % 2) * 7) % 14;
      const brickY = (y - 112) % 6;
      const isMortar = brickX === 0 || brickY === 0;
      const col = isMortar
        ? STONE[1]
        : x < 54
          ? brickY < 2
            ? STONE[4]
            : STONE[3]
          : STONE[2];
      setPx(png, x, y, col);
    }
  }

  for (let y = 62; y <= 112; y++) {
    for (let x = 30; x <= 98; x++) {
      const isPost =
        x < 37 || x > 91 || (x >= 61 && x <= 67) || y < 68 || y > 106;
      const isBrace =
        Math.abs(x - 36 - (y - 68) * 0.5) < 2.2 ||
        Math.abs(92 - x - (y - 68) * 0.5) < 2.2;
      if (isPost || isBrace) {
        setPx(png, x, y, x < 64 ? WOOD[3] : WOOD[2]);
      } else {
        setPx(png, x, y, (x + y) % 2 === 0 ? WOOD[1] : WOOD[2]);
      }
    }
  }

  for (let y = 74; y <= 96; y++) {
    for (let x = 54; x <= 74; x++) {
      const dx = x - 64;
      const dy = y - 82;
      if (y < 82 ? dx * dx + dy * dy <= 81 : Math.abs(dx) <= 9) {
        const isMullion = Math.abs(dx) <= 1 || y === 84;
        setPx(
          png,
          x,
          y,
          isMullion ? WOOD[0] : Math.abs(dx) < 5 && y < 88 ? GOLD[4] : GOLD[3]
        );
      }
    }
  }

  for (let x = 22; x <= 106; x++) {
    setPx(png, x, 104, WOOD[4]);
    setPx(png, x, 105, WOOD[3]);
    setPx(png, x, 112, WOOD[2]);
    setPx(png, x, 113, WOOD[1]);
    if (x % 6 <= 1) {
      for (let y = 106; y <= 111; y++) setPx(png, x, y, WOOD[3]);
    }
  }

  for (let y = 12; y <= 66; y++) {
    const t = (y - 12) / 54;
    const halfW = Math.round(4 + Math.pow(t, 0.88) * 48 + (t > 0.8 ? (t - 0.8) * 28 : 0));
    for (let x = 64 - halfW; x <= 64 + halfW; x++) {
      const dx = x - 64;
      const shingleRow = Math.floor((y - 12) / 5);
      const shingleCol = (x + (shingleRow % 2) * 4) % 8;
      const isEdge = Math.abs(dx) >= halfW - 3 || y >= 63;
      if (isEdge) {
        setPx(png, x, y, dx < 0 ? GOLD[3] : GOLD[2]);
      } else {
        const shade =
          (dx < 0 ? 0.65 : 0.35) +
          ((y - 12) % 5 === 0 ? -0.25 : 0.1) +
          (shingleCol === 0 ? -0.15 : 0);
        const col =
          shade > 0.68
            ? ROOF_MOSS[4]
            : shade > 0.48
              ? ROOF_MOSS[3]
              : shade > 0.28
                ? ROOF_MOSS[2]
                : ROOF_MOSS[1];
        setPx(png, x, y, col);
      }
    }
  }

  for (let y = 4; y <= 14; y++) {
    const r = y < 8 ? 1 : 2;
    for (let x = 64 - r; x <= 64 + r; x++) {
      setPx(png, x, y, x <= 64 ? GOLD[4] : GOLD[2]);
    }
  }

  applyPixelOutline(png, hex('#12161f'));

  const outPath = path.join(OUT_DIR, 'prop_forest_watchtower.png');
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('Generated:', outPath);
}

// ============================================================================
// 4. NATURAL MOSSY BOULDERS, CRYSTAL CRAG, WAYSTONE & LOG ATLAS (256x64)
// ============================================================================
function generateMossyBouldersAtlas() {
  const W = 256;
  const H = 64;
  const png = new PNG({ width: W, height: H });

  const STONE = [
    hex('#1c202b'),
    hex('#2d3446'),
    hex('#465168'),
    hex('#677691'),
    hex('#92a3bd'),
  ];
  const MOSS = [
    hex('#143025'),
    hex('#204d3b'),
    hex('#337556'),
    hex('#52a371'),
    hex('#82cf93'),
  ];
  const CRYSTAL = [
    hex('#154c61'),
    hex('#20829e'),
    hex('#38b9d6'),
    hex('#73ebff'),
    hex('#dbffff'),
  ];
  const GOLD = [
    hex('#613718'),
    hex('#995b24'),
    hex('#d48e2f'),
    hex('#f7c244'),
    hex('#fff5a8'),
  ];
  const BARK = [
    hex('#1e1412'),
    hex('#33211d'),
    hex('#4f342b'),
    hex('#6e4b3c'),
    hex('#8f6550'),
  ];

  // Cell 0 (0..63): Natural Mossy Forest Boulder with Toadstools
  for (let y = 18; y <= 59; y++) {
    for (let x = 6; x <= 58; x++) {
      const dx = (x - 32) / 23;
      const dy = (y - 43) / 20;
      const mod = 0.09 * Math.sin(dx * 4.5) + 0.07 * Math.cos(dy * 5);
      const dist = Math.sqrt(dx * dx + dy * dy) + mod;
      if (dist <= 1.0 && y <= 58 + Math.sin(x * 0.4) * 1.5) {
        const facet = Math.sin(x * 0.22 + y * 0.14) * 0.15;
        const light = dx * -0.4 + dy * -0.6 + 0.55 + facet;
        let col =
          light > 0.78
            ? STONE[4]
            : light > 0.52
              ? bayerDither(x, y, (light - 0.52) * 3.5)
                ? STONE[3]
                : STONE[2]
              : light > 0.3
                ? STONE[2]
                : STONE[1];
        setPx(png, x, y, col);
      }
    }
  }
  drawLeafCluster(png, 31, 26, 19, 9, MOSS, 31);
  // Small red mushroom next to boulder at (50, 52)
  for (let y = 48; y <= 58; y++) {
    for (let x = 45; x <= 55; x++) {
      if (y >= 53 && Math.abs(x - 50) <= 1) setPx(png, x, y, hex('#f5e3c6'));
      if (y <= 53 && (x - 50) ** 2 / 20 + (y - 52) ** 2 / 14 <= 1) {
        setPx(png, x, y, (x + y) % 4 === 0 ? hex('#fff2d6') : hex('#d94136'));
      }
    }
  }
  applyPixelOutline(png, hex('#12161f'), { x: 0, y: 0, w: 64, h: 64 });

  // Cell 1 (64..127): Jagged Crystal Crag Spire
  for (let y = 10; y <= 59; y++) {
    const t = (y - 10) / 49;
    const halfW = 4 + t * 20 + Math.sin(y * 0.3) * 2;
    const cx = 96 + Math.sin(t * 3) * 2;
    for (let x = Math.floor(cx - halfW); x <= Math.ceil(cx + halfW); x++) {
      if (y > 57 + Math.cos(x * 0.4) * 2) continue;
      const dx = (x - cx) / halfW;
      const facet = Math.sin(x * 0.25 - y * 0.15) * 0.15;
      const shade = -dx * 0.5 + 0.5 + facet;
      const col =
        shade > 0.75 ? STONE[4] : shade > 0.5 ? STONE[3] : shade > 0.28 ? STONE[2] : STONE[1];
      setPx(png, x, y, col);
      if (Math.abs(x - cx - (y - 34) * 0.35) < 2.4 && y > 18 && y < 52) {
        setPx(png, x, y, dx < 0 ? CRYSTAL[4] : CRYSTAL[2]);
      }
    }
  }
  applyPixelOutline(png, hex('#12161f'), { x: 64, y: 0, w: 64, h: 64 });

  // Cell 2 (128..191): Ancient Elven Waystone Shrine with Golden Runes
  for (let y = 8; y <= 59; y++) {
    const t = (y - 8) / 51;
    const halfW =
      y < 20 ? (y - 8) * 1.1 + 2 : 13 + Math.sin(t * Math.PI) * 3 + (t > 0.8 ? 5 : 0);
    const cx = 160;
    for (let x = Math.floor(cx - halfW); x <= Math.ceil(cx + halfW); x++) {
      if (y > 58 + Math.sin(x * 0.5) * 1.5) continue;
      const dx = x - cx;
      let col = dx < -4 ? STONE[4] : dx < 4 ? STONE[3] : STONE[2];
      const rDist = Math.sqrt(dx * dx + (y - 32) ** 2);
      if (Math.abs(rDist - 6) < 1.3 || (Math.abs(dx) <= 1 && Math.abs(y - 32) <= 4)) {
        col = GOLD[4];
      }
      if (Math.abs(y - (22 + dx * 0.6)) < 2.5 && Math.abs(dx) > 3) {
        col = dyMoss(x, y, MOSS);
      }
      setPx(png, x, y, col);
    }
  }
  drawLeafCluster(png, 155, 16, 10, 6, MOSS, 52);
  applyPixelOutline(png, hex('#12161f'), { x: 128, y: 0, w: 64, h: 64 });

  // Cell 3 (192..255): Fallen Hollow Mossy Log with Shelf Mushrooms
  for (let y = 32; y <= 59; y++) {
    for (let x = 198; x <= 250; x++) {
      const dx = (x - 224) / 25;
      const dy = (y - 46) / 12;
      if (Math.abs(dx) <= 1.0 && Math.abs(dy) <= 1.0 - Math.abs(dx) * 0.15) {
        if (dx > 0.72 && dx * dx + dy * dy < 0.85) {
          setPx(png, x, y, hex('#140d0c'));
        } else {
          const grain = Math.sin(y * 1.2 + x * 0.25) * 0.2;
          let col =
            dy + grain < -0.2 ? BARK[3] : dy + grain < 0.35 ? BARK[2] : BARK[1];
          setPx(png, x, y, col);
        }
      }
    }
  }
  drawLeafCluster(png, 214, 34, 14, 6, MOSS, 61);
  drawLeafCluster(png, 232, 35, 12, 5, MOSS, 62);
  applyPixelOutline(png, hex('#12161f'), { x: 192, y: 0, w: 64, h: 64 });

  const outPath = path.join(OUT_DIR, 'prop_mossy_boulders.png');
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('Generated:', outPath);
}

function dyMoss(x, y, MOSS) {
  return (x + y) % 2 === 0 ? MOSS[3] : MOSS[2];
}

// ============================================================================
// 5. PIXEL ART PARALLAX BACKGROUND VISTAS (640x360) WITH LAYERED PINE & OAK SILHOUETTES
// ============================================================================
function drawSilhouetteTree(png, tx, baseY, height, spread, col, highlightCol, isPine, seed) {
  // Trunk
  const trunkW = Math.max(3, Math.round(spread * 0.16));
  for (let y = baseY - height * 0.75; y <= baseY + 40; y++) {
    for (let x = tx - trunkW; x <= tx + trunkW; x++) {
      setPx(png, x, y, x < tx ? highlightCol : col);
    }
  }

  if (isPine) {
    // 4-tier conical pine silhouette with scalloped boughs
    for (let tier = 0; tier < 4; tier++) {
      const tierTop = baseY - height + tier * (height * 0.19);
      const tierH = height * 0.32;
      const maxHalfW = spread * (0.45 + tier * 0.2);
      for (let y = Math.floor(tierTop); y <= Math.ceil(tierTop + tierH); y++) {
        const t = (y - tierTop) / tierH;
        const hw = maxHalfW * Math.pow(t, 0.85) + Math.sin(y * 0.5 + seed) * 2;
        for (let x = Math.floor(tx - hw); x <= Math.ceil(tx + hw); x++) {
          const scallop = Math.sin((x - tx) * 0.35 + tier) * 2.5;
          if (y <= tierTop + tierH - 2 + scallop) {
            const isLit = x < tx - hw * 0.15 && t < 0.55;
            setPx(
              png,
              x,
              y,
              isLit && bayerDither(x, y, 0.55) ? highlightCol : col
            );
          }
        }
      }
    }
  } else {
    // Broad ancient oak canopy with multiple overlapping leaf puffs
    const puffs = [
      { ox: 0, oy: -height * 0.88, rx: spread * 0.75, ry: height * 0.24 },
      { ox: -spread * 0.48, oy: -height * 0.72, rx: spread * 0.58, ry: height * 0.22 },
      { ox: spread * 0.48, oy: -height * 0.7, rx: spread * 0.58, ry: height * 0.22 },
      { ox: 0, oy: -height * 0.65, rx: spread * 0.82, ry: height * 0.22 },
    ];
    for (const p of puffs) {
      const cx = tx + p.ox;
      const cy = baseY + p.oy;
      for (let y = Math.floor(cy - p.ry - 2); y <= Math.ceil(cy + p.ry + 2); y++) {
        for (let x = Math.floor(cx - p.rx - 2); x <= Math.ceil(cx + p.rx + 2); x++) {
          const dx = (x - cx) / p.rx;
          const dy = (y - cy) / p.ry;
          const ang = Math.atan2(dy, dx);
          const d = Math.sqrt(dx * dx + dy * dy) + 0.1 * Math.sin(ang * 8 + seed);
          if (d <= 1.0) {
            const isRim = dy < -0.35 && dx < 0.25;
            setPx(
              png,
              x,
              y,
              isRim && bayerDither(x, y, (-dy - 0.2) * 1.4) ? highlightCol : col
            );
          }
        }
      }
    }
  }
}

function generateParallaxVista(filename, palette) {
  const W = 640;
  const H = 360;
  const png = new PNG({ width: W, height: H });

  // 1. Dithered sky gradient
  for (let y = 0; y < H; y++) {
    const t = y / H;
    const scaled = t * (palette.sky.length - 1);
    const idx = Math.min(palette.sky.length - 2, Math.floor(scaled));
    const frac = scaled - idx;
    for (let x = 0; x < W; x++) {
      const col = bayerDither(x, y, frac) ? palette.sky[idx + 1] : palette.sky[idx];
      setPx(png, x, y, col);
    }
  }

  // 2. Stars (if twilight/night)
  if (palette.stars) {
    for (let i = 0; i < 110; i++) {
      const sx = Math.floor(hash2d(i, 1, 77) * W);
      const sy = Math.floor(hash2d(i, 2, 77) * 195);
      setPx(png, sx, sy, palette.celestialCore);
      if (i % 6 === 0) {
        setPx(png, sx - 1, sy, palette.celestialGlow);
        setPx(png, sx + 1, sy, palette.celestialGlow);
        setPx(png, sx, sy - 1, palette.celestialGlow);
        setPx(png, sx, sy + 1, palette.celestialGlow);
      }
    }
  }

  // 3. Celestial orb (Sun / Sunset / Moon)
  const sunX = 486;
  const sunY = 78;
  for (let y = sunY - 44; y <= sunY + 44; y++) {
    for (let x = sunX - 44; x <= sunX + 44; x++) {
      const d = Math.sqrt((x - sunX) ** 2 + (y - sunY) ** 2);
      if (d <= 22) {
        setPx(png, x, y, palette.celestialCore);
      } else if (d <= 40 && bayerDither(x, y, 1 - (d - 22) / 18)) {
        setPx(png, x, y, palette.celestialGlow);
      }
    }
  }

  // 4. Three parallax mountain + ancient forest layers
  for (let layer = 0; layer < 3; layer++) {
    const baseH = 190 + layer * 44;
    const col = palette.layers[layer];
    const highlightCol = palette.layerHighlights[layer];

    // Mountain ridge line
    for (let x = 0; x < W; x++) {
      const ridge =
        Math.sin(x * 0.011 + layer * 1.9) * 28 +
        Math.cos(x * 0.027 + layer * 2.5) * 14 +
        Math.sin(x * 0.065 + layer) * 5;
      const topY = Math.floor(baseH + ridge);
      for (let y = Math.max(0, topY); y < H; y++) {
        const isRim = y < topY + 4 && bayerDither(x, y, 1 - (y - topY) / 4);
        setPx(png, x, y, isRim ? highlightCol : col);
      }
    }

    // Forest trees along ridge
    const step = layer === 0 ? 52 : layer === 1 ? 64 : 78;
    for (let tx = 18 + layer * 23; tx < W + 20; tx += step) {
      const ridgeAtX =
        Math.sin(tx * 0.011 + layer * 1.9) * 28 +
        Math.cos(tx * 0.027 + layer * 2.5) * 14;
      const treeBaseY = Math.floor(baseH + ridgeAtX + 12);
      const treeH = (layer === 0 ? 74 : layer === 1 ? 92 : 112) + ((tx * 7) % 24);
      const spread = (layer === 0 ? 22 : layer === 1 ? 28 : 34) + ((tx * 3) % 8);
      const isPine = (tx + layer) % 2 === 0;
      drawSilhouetteTree(
        png,
        tx,
        treeBaseY,
        treeH,
        spread,
        col,
        highlightCol,
        isPine,
        tx + layer * 100
      );
    }
  }

  // 5. Diagonal sunbeams / moonbeams
  for (let b = 0; b < 4; b++) {
    const startX = 70 + b * 150;
    for (let y = 0; y < H; y++) {
      const center = startX + y * 0.42;
      for (let x = Math.floor(center - 16); x <= Math.ceil(center + 16); x++) {
        if ((x + y) % 4 === 0) {
          setPx(png, x, y, [...palette.rayColor.slice(0, 3), 24]);
        }
      }
    }
  }

  const outPath = path.join(OUT_DIR, filename);
  fs.writeFileSync(outPath, PNG.sync.write(png));
  console.log('Generated:', outPath);
}

generateAncientHollowTree();
generateDwarvenMineEntrance();
generateForestWatchtower();
generateMossyBouldersAtlas();

generateParallaxVista('bg_emerald_forest.png', {
  sky: [hex('#0f2429'), hex('#193c40'), hex('#295e58'), hex('#468c72'), hex('#7bc490')],
  celestialCore: hex('#fff7c2'),
  celestialGlow: hex('#a8e6a3'),
  layers: [hex('#1f4a42'), hex('#153630'), hex('#0d2420')],
  layerHighlights: [hex('#387866'), hex('#26574c'), hex('#1a3d35')],
  rayColor: hex('#e8ffbd'),
  stars: false,
});

generateParallaxVista('bg_golden_groves.png', {
  sky: [hex('#241326'), hex('#4a1f33'), hex('#803638'), hex('#bf633b'), hex('#f2a649')],
  celestialCore: hex('#fff3b0'),
  celestialGlow: hex('#f58245'),
  layers: [hex('#592530'), hex('#3d1824'), hex('#260e18')],
  layerHighlights: [hex('#8c413b'), hex('#662b30'), hex('#451b23')],
  rayColor: hex('#ffd27d'),
  stars: false,
});

generateParallaxVista('bg_twilight_sanctuary.png', {
  sky: [hex('#090b17'), hex('#11172e'), hex('#1b264a'), hex('#273b69'), hex('#395c8f')],
  celestialCore: hex('#d9fcff'),
  celestialGlow: hex('#56b4d9'),
  layers: [hex('#182442'), hex('#10182e'), hex('#0a0f1f')],
  layerHighlights: [hex('#2d4978'), hex('#21365c'), hex('#162542')],
  rayColor: hex('#80f2ff'),
  stars: true,
});
