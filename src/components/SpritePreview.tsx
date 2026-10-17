import React, { useEffect, useRef } from 'react';
import { assetLoader } from '../engine/assetLoader';

export interface CropRegion {
  x: number;
  y: number;
  w: number;
  h: number;
}

interface SpritePreviewProps {
  sheetSrc: string;
  frameW: number;
  frameH: number;
  row?: number;
  startCol?: number;
  frameCount?: number;
  regions?: CropRegion[];
  fps?: number;
  scale?: number;
  className?: string;
}

export const SpritePreview: React.FC<SpritePreviewProps> = ({
  sheetSrc,
  frameW,
  frameH,
  row = 0,
  startCol = 0,
  frameCount = 1,
  regions,
  fps = 8,
  scale = 2,
  className = '',
}) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    let animId: number;
    const startTime = performance.now();

    const render = (currentTime: number) => {
      const canvas = canvasRef.current;
      if (!canvas) return;
      const ctx = canvas.getContext('2d');
      if (!ctx) return;

      const img = assetLoader.getCached(sheetSrc);
      if (!img) {
        assetLoader.loadAsset(sheetSrc);
      } else {
        ctx.imageSmoothingEnabled = false;
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        const elapsed = (currentTime - startTime) / 1000;

        if (regions && regions.length > 0) {
          const region = regions[Math.floor(elapsed * fps) % regions.length];
          const fitScale = Math.min(
            (canvas.width - 4) / region.w,
            (canvas.height - 4) / region.h
          );
          const drawW = Math.round(region.w * fitScale);
          const drawH = Math.round(region.h * fitScale);
          const drawX = Math.round((canvas.width - drawW) / 2);
          const drawY = Math.round((canvas.height - drawH) / 2);

          ctx.drawImage(
            img,
            region.x,
            region.y,
            region.w,
            region.h,
            drawX,
            drawY,
            drawW,
            drawH
          );
        } else {
          const currentFrame = Math.floor(elapsed * fps) % frameCount;
          const col = startCol + currentFrame;
          const srcX = col * frameW;
          const srcY = row * frameH;

          ctx.drawImage(
            img,
            srcX,
            srcY,
            frameW,
            frameH,
            0,
            0,
            Math.round(frameW * scale),
            Math.round(frameH * scale)
          );
        }
      }

      animId = requestAnimationFrame(render);
    };

    animId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animId);
  }, [sheetSrc, frameW, frameH, row, startCol, frameCount, regions, fps, scale]);

  return (
    <canvas
      ref={canvasRef}
      width={Math.round(frameW * scale)}
      height={Math.round(frameH * scale)}
      className={`block pixelated ${className}`}
    />
  );
};
