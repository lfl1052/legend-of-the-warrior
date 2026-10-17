import { PNG } from 'pngjs';
import fs from 'fs';
import path from 'path';

// Helper to set pixel in PNG
function setPixel(png, x, y, r, g, b, a = 255) {
  if (x < 0 || x >= png.width || y < 0 || y >= png.height) return;
  const idx = (png.width * y + x) << 2;
  png.data[idx] = r;
  png.data[idx + 1] = g;
  png.data[idx + 2] = b;
  png.data[idx + 3] = a;
}

function hexToRgb(hex) {
  const num = parseInt(hex.replace('#', ''), 16);
  return [(num >> 16) & 255, (num >> 8) & 255, num & 255];
}

function fillRect(png, x, y, w, h, hex, a = 255) {
  const [r, g, b] = hexToRgb(hex);
  for (let dy = 0; dy < h; dy++) {
    for (let dx = 0; dx < w; dx++) {
      setPixel(png, x + dx, y + dy, r, g, b, a);
    }
  }
}

// 1. GENERATE TILESET (256x256, 16x16 tiles = 16x16 grid)
const tilePng = new PNG({ width: 256, height: 256 });
// Clear transparent
for (let i = 0; i < tilePng.data.length; i += 4) {
  tilePng.data[i + 3] = 0;
}

const TILE_SIZE = 16;

// Function to draw a 16x16 tile at grid (tx, ty)
function drawGrassTile(tx, ty, variant = 0) {
  const px = tx * TILE_SIZE;
  const py = ty * TILE_SIZE;
  // Dirt body
  fillRect(tilePng, px, py + 4, 16, 12, '#3d2314');
  fillRect(tilePng, px, py + 14, 16, 2, '#27170c');
  // Pebbles
  if (variant === 0) {
    fillRect(tilePng, px + 3, py + 8, 2, 2, '#5c3822');
    fillRect(tilePng, px + 11, py + 11, 3, 2, '#5c3822');
  } else {
    fillRect(tilePng, px + 7, py + 7, 2, 2, '#5c3822');
    fillRect(tilePng, px + 2, py + 12, 3, 2, '#5c3822');
  }
  // Grass top band
  fillRect(tilePng, px, py + 2, 16, 3, '#166534');
  fillRect(tilePng, px, py, 16, 2, '#22c55e');
  // Grass tufts / blade tips
  fillRect(tilePng, px + 2, py - 1, 2, 2, '#4ade80');
  fillRect(tilePng, px + 8, py - 1, 2, 2, '#4ade80');
  fillRect(tilePng, px + 13, py - 1, 2, 2, '#4ade80');
  // Roots
  fillRect(tilePng, px + 4, py + 5, 1, 3, '#15803d');
  fillRect(tilePng, px + 10, py + 5, 1, 4, '#15803d');
}

function drawDirtTile(tx, ty) {
  const px = tx * TILE_SIZE;
  const py = ty * TILE_SIZE;
  fillRect(tilePng, px, py, 16, 16, '#3d2314');
  fillRect(tilePng, px, py + 6, 16, 2, '#27170c');
  fillRect(tilePng, px, py + 13, 16, 2, '#27170c');
  fillRect(tilePng, px + 4, py + 3, 3, 2, '#5c3822');
  fillRect(tilePng, px + 10, py + 9, 3, 3, '#5c3822');
}

function drawWoodPlankTile(tx, ty, isEdge = false) {
  const px = tx * TILE_SIZE;
  const py = ty * TILE_SIZE;
  fillRect(tilePng, px, py + 2, 16, 12, '#854d0e');
  fillRect(tilePng, px, py, 16, 2, '#a16207');
  fillRect(tilePng, px, py + 14, 16, 2, '#451a03');
  // Woodgrain
  fillRect(tilePng, px + 5, py + 2, 1, 12, '#713f12');
  fillRect(tilePng, px + 12, py + 2, 1, 12, '#713f12');
  // Moss patch
  fillRect(tilePng, px + 2, py - 1, 4, 2, '#22c55e');
  if (isEdge) {
    // Metal rivet
    fillRect(tilePng, px + 2, py + 4, 2, 2, '#cbd5e1');
  }
}

function drawStoneTile(tx, ty) {
  const px = tx * TILE_SIZE;
  const py = ty * TILE_SIZE;
  fillRect(tilePng, px, py, 16, 16, '#334155');
  fillRect(tilePng, px, py, 16, 2, '#64748b');
  fillRect(tilePng, px, py + 14, 16, 2, '#1e293b');
  fillRect(tilePng, px + 7, py + 2, 2, 12, '#1e293b');
  fillRect(tilePng, px + 2, py + 8, 4, 1, '#475569');
  fillRect(tilePng, px + 10, py + 6, 4, 1, '#475569');
}

function drawSpikeTile(tx, ty) {
  const px = tx * TILE_SIZE;
  const py = ty * TILE_SIZE;
  fillRect(tilePng, px, py + 13, 16, 3, '#334155');
  // Spike 1
  for (let y = 0; y < 13; y++) {
    const halfW = Math.floor((13 - y) / 3);
    fillRect(tilePng, px + 4 - halfW, py + y, halfW * 2 + 1, 1, '#64748b');
  }
  // Spike 2
  for (let y = 0; y < 13; y++) {
    const halfW = Math.floor((13 - y) / 3);
    fillRect(tilePng, px + 12 - halfW, py + y, halfW * 2 + 1, 1, '#64748b');
  }
  // Tips
  fillRect(tilePng, px + 4, py + 1, 1, 3, '#cbd5e1');
  fillRect(tilePng, px + 12, py + 1, 1, 3, '#cbd5e1');
  fillRect(tilePng, px + 3, py + 3, 3, 2, '#b91c1c'); // blood
}

// Draw tiles onto grid:
// Row 0: Grass variants
drawGrassTile(0, 0, 0);
drawGrassTile(1, 0, 1);
drawGrassTile(2, 0, 0);

// Row 1: Dirt
drawDirtTile(0, 1);
drawDirtTile(1, 1);

// Row 2: Wood Planks
drawWoodPlankTile(0, 2, true);
drawWoodPlankTile(1, 2, false);
drawWoodPlankTile(2, 2, true);

// Row 3: Stone Ruins
drawStoneTile(0, 3);
drawStoneTile(1, 3);

// Row 4: Spikes
drawSpikeTile(0, 4);

// Ensure directories exist in art/ and public/art/
const mapAssetsDir = path.resolve('art/imported/Legacy-Fantasy-High Forest/Map Assets');
const publicMapAssetsDir = path.resolve('public/art/imported/Legacy-Fantasy-High Forest/Map Assets');
fs.mkdirSync(mapAssetsDir, { recursive: true });
fs.mkdirSync(publicMapAssetsDir, { recursive: true });

// Save Tileset.png
const tilePath1 = path.join(mapAssetsDir, 'Tileset.png');
const tilePath2 = path.join(publicMapAssetsDir, 'Tileset.png');

const tileBuffer = PNG.sync.write(tilePng);
fs.writeFileSync(tilePath1, tileBuffer);
fs.writeFileSync(tilePath2, tileBuffer);
console.log('Saved Tileset.png to', tilePath1, 'and', tilePath2);

// 2. GENERATE PARALLAX BACKGROUND (640x360)
const bgPng = new PNG({ width: 640, height: 360 });

// Sky gradient
for (let y = 0; y < 360; y++) {
  const t = y / 360;
  const r = Math.round(10 * (1 - t) + 27 * t);
  const g = Math.round(25 * (1 - t) + 67 * t);
  const b = Math.round(47 * (1 - t) + 50 * t);
  for (let x = 0; x < 640; x++) {
    setPixel(bgPng, x, y, r, g, b, 255);
  }
}

// Distant Mountain Silhouettes
for (let x = 0; x < 640; x++) {
  const m1 = Math.sin(x * 0.01) * 35 + Math.sin(x * 0.03) * 15 + 210;
  for (let y = Math.round(m1); y < 360; y++) {
    setPixel(bgPng, x, y, 15, 41, 44, 255);
  }
}

// Pine Forest Midground Silhouettes
for (let x = 0; x < 640; x++) {
  const f1 = Math.abs(Math.sin(x * 0.05)) * 40 + Math.sin(x * 0.01) * 20 + 260;
  for (let y = Math.round(f1); y < 360; y++) {
    setPixel(bgPng, x, y, 17, 53, 42, 255);
  }
}

const bgPath1 = path.join(mapAssetsDir, 'Background.png');
const bgPath2 = path.join(publicMapAssetsDir, 'Background.png');
const bgBuffer = PNG.sync.write(bgPng);
fs.writeFileSync(bgPath1, bgBuffer);
fs.writeFileSync(bgPath2, bgBuffer);
console.log('Saved Background.png to', bgPath1, 'and', bgPath2);
