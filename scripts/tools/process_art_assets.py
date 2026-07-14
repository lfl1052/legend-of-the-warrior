from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
IMPORTED = ROOT / "art" / "imported"
DERIVED = ROOT / "art" / "runtime" / "derived"
MANIFEST_PATH = ROOT / "data" / "asset_manifest.json"

CHARACTER_ROWS_1 = [
    "idle", "attack_combo", "run", "jump_up", "fall_land", "hurt", "death",
    "death_ground", "spell_cast", "crouch", "shield_defence",
]
CHARACTER_ROWS_2 = [
    "walk", "walk_extra", "slide", "wall_slide", "critical_attack",
    "ladder_climb", "ladder_climb_extra",
]


def safe_name(value: str) -> str:
    value = value.replace("&", "and")
    value = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_").lower()
    return value or "asset"


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.convert("RGBA").getchannel("A").getbbox()


def record(
    assets: list[dict[str, Any]],
    *,
    asset_id: str,
    category: str,
    family: str,
    source: Path,
    size: tuple[int, int],
    tags: Iterable[str],
    **extra: Any,
) -> None:
    assets.append(
        {
            "id": asset_id,
            "category": category,
            "family": family,
            "source": res_path(source),
            # 兼容旧消费者；图集优先管线中 output 不再指向裁剪文件。
            "output": res_path(source),
            "size": list(size),
            "tags": sorted(set(tags)),
            **extra,
        }
    )


def index_grid_frames(
    assets: list[dict[str, Any]],
    *,
    source: Path,
    frame_size: tuple[int, int],
    columns: int,
    rows: int,
    category: str,
    family: str,
    action_labels: list[str],
    variant: str,
    tags: Iterable[str],
) -> None:
    image = Image.open(source).convert("RGBA")
    frame_width, frame_height = frame_size
    for row in range(rows):
        action = action_labels[row] if row < len(action_labels) else f"row_{row:02d}"
        frame_index = 0
        for column in range(columns):
            box = (
                column * frame_width,
                row * frame_height,
                (column + 1) * frame_width,
                (row + 1) * frame_height,
            )
            if alpha_bbox(image.crop(box)) is None:
                continue
            record(
                assets,
                asset_id=f"{category}.{family}.{variant}.{action}.{frame_index:02d}",
                category=category,
                family=family,
                source=source,
                size=frame_size,
                tags=[*tags, action, variant, "frame", "atlas_region"],
                frame=[column, row],
                frame_size=list(frame_size),
                region=[box[0], box[1], frame_width, frame_height],
                action=action,
                variant=variant,
            )
            frame_index += 1


def process_characters(assets: list[dict[str, Any]]) -> None:
    source_root = IMPORTED / "Generic-Character" / "png"
    for color_dir in sorted(source_root.iterdir()):
        if not color_dir.is_dir():
            continue
        color = safe_name(color_dir.name)
        for sheet_name, rows, labels in [
            (f"char_{color}_1.png", 11, CHARACTER_ROWS_1),
            (f"char_{color}_2.png", 7, CHARACTER_ROWS_2),
        ]:
            source = color_dir / sheet_name
            if source.exists():
                index_grid_frames(
                    assets,
                    source=source,
                    frame_size=(56, 56),
                    columns=8,
                    rows=rows,
                    category="character",
                    family="warrior",
                    action_labels=labels,
                    variant=color,
                    tags=["player", "humanoid", "sprite_sheet"],
                )


def process_bee(assets: list[dict[str, Any]]) -> None:
    root = IMPORTED / "Legacy-Fantasy-High Forest" / "Enemies" / "Small Bee"
    for action, relative in {
        "attack": "Attack/Attack-Sheet.png",
        "fly": "Fly/Fly-Sheet.png",
        "hit": "Hit/Hit-Sheet.png",
    }.items():
        index_grid_frames(
            assets,
            source=root / relative,
            frame_size=(64, 64),
            columns=4,
            rows=1,
            category="enemy",
            family="bee",
            action_labels=[action],
            variant="small",
            tags=["enemy", "flying", "sprite_sheet"],
        )


def process_snail(assets: list[dict[str, Any]]) -> None:
    root = IMPORTED / "Legacy-Fantasy-High Forest" / "Enemies" / "Snail"
    for action, filename in {
        "walk": "walk-Sheet.png",
        "hide": "Hide-Sheet.png",
        "dead": "Dead-Sheet.png",
    }.items():
        index_grid_frames(
            assets,
            source=root / filename,
            frame_size=(96, 32),
            columns=4,
            rows=1,
            category="enemy",
            family="snail",
            action_labels=[action],
            variant="forest",
            tags=["enemy", "ground", "sprite_sheet"],
        )


def boar_variant(path: Path) -> str:
    name = path.stem.lower()
    if "white" in name:
        return "white"
    if "black" in name:
        return "black"
    if "back" in name:
        return "back"
    return "base"


def process_boar(assets: list[dict[str, Any]]) -> None:
    root = (
        IMPORTED / "Legacy-Fantasy-High Forest" / "Enemies" / "Small Bee"
        / "MapAssets" / "Dark_Tree" / "Boar"
    )
    for source in sorted(root.rglob("*.png")):
        action = safe_name(source.parent.name)
        with Image.open(source) as image:
            width, height = image.size
        if height <= 0 or width % height != 0:
            continue
        index_grid_frames(
            assets,
            source=source,
            frame_size=(height, height),
            columns=width // height,
            rows=1,
            category="enemy",
            family="boar",
            action_labels=[action],
            variant=boar_variant(source),
            tags=["enemy", "ground", "sprite_sheet", "boar"],
        )


def process_map_tile_atlas(assets: list[dict[str, Any]], source: Path, family: str) -> None:
    image = Image.open(source).convert("RGBA")
    tile_size = 16
    for row in range(image.height // tile_size):
        for column in range(image.width // tile_size):
            box = (
                column * tile_size,
                row * tile_size,
                (column + 1) * tile_size,
                (row + 1) * tile_size,
            )
            if alpha_bbox(image.crop(box)) is None:
                continue
            record(
                assets,
                asset_id=f"map.tiles.{family}.{column:02d}_{row:02d}",
                category="map",
                family=family,
                source=source,
                size=(tile_size, tile_size),
                tags=["forest", "tile", "atlas_region"],
                frame=[column, row],
                frame_size=[tile_size, tile_size],
                region=[box[0], box[1], tile_size, tile_size],
            )


def connected_components(alpha: Image.Image, min_area: int) -> list[tuple[int, tuple[int, int, int, int]]]:
    pixels = alpha.load()
    width, height = alpha.size
    seen: set[tuple[int, int]] = set()
    components: list[tuple[int, tuple[int, int, int, int]]] = []
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in seen:
                continue
            stack = [(x, y)]
            seen.add((x, y))
            xs: list[int] = []
            ys: list[int] = []
            while stack:
                cx, cy = stack.pop()
                xs.append(cx)
                ys.append(cy)
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    if (nx, ny) in seen or pixels[nx, ny] == 0:
                        continue
                    seen.add((nx, ny))
                    stack.append((nx, ny))
            if len(xs) >= min_area:
                components.append((len(xs), (min(xs), min(ys), max(xs) + 1, max(ys) + 1)))
    return sorted(components, key=lambda item: (item[1][1], item[1][0], -item[0]))


def process_component_atlas(
    assets: list[dict[str, Any]],
    *,
    source: Path,
    family: str,
    tags: Iterable[str],
    min_area: int,
    variant: str = "default",
) -> None:
    image = Image.open(source).convert("RGBA")
    for index, (area, box) in enumerate(connected_components(image.getchannel("A"), min_area)):
        left, top, right, bottom = box
        record(
            assets,
            asset_id=f"map.components.{family}.{variant}.{index:02d}",
            category="map",
            family=family,
            source=source,
            size=(right - left, bottom - top),
            tags=[*tags, "component_region", variant],
            bbox=list(box),
            region=[left, top, right - left, bottom - top],
            component_area=area,
            variant=variant,
        )


def process_map_components(assets: list[dict[str, Any]]) -> None:
    root = IMPORTED / "Legacy-Fantasy-High Forest" / "Map Assets"
    specs = [
        ("Buildings.png", "buildings", ["structures", "buildings"], 20),
        ("Hive.png", "hive", ["props", "hive"], 20),
        ("Mine Stone.png", "mine_stone", ["props", "mine_stone"], 20),
        ("Props-Rocks.png", "rocks", ["terrain", "rocks"], 20),
        ("Forest-2.png", "forest_2", ["foliage", "forest_2"], 20),
    ]
    for filename, family, tags, min_area in specs:
        process_component_atlas(
            assets, source=root / filename, family=family, tags=tags, min_area=min_area
        )
    for source in sorted((root / "Trees").glob("*.png")):
        variant = safe_name(source.stem.replace("-Tree", ""))
        process_component_atlas(
            assets,
            source=source,
            family="trees",
            tags=["forest", "tree", variant],
            min_area=3000,
            variant=variant,
        )

    # Chest2 是两个相邻状态，透明像素组件会被拆碎，因此显式记录帧区域。
    chest2 = root / "Chest2.png"
    for name, region in [("closed", (0, 0, 34, 32)), ("open", (31, 0, 33, 32))]:
        record(
            assets,
            asset_id=f"map.components.chest.chest2_{name}",
            category="map",
            family="chest",
            source=chest2,
            size=(region[2], region[3]),
            tags=["props", "chest", "component_region", name],
            bbox=[region[0], region[1], region[0] + region[2], region[1] + region[3]],
            region=list(region),
            variant=name,
        )


def process_derived_assets(assets: list[dict[str, Any]]) -> None:
    corner = DERIVED / "terrain" / "forest_ground_inner_corners.png"
    if corner.exists():
        record(
            assets,
            asset_id="map.derived.forest_ground_inner_corners",
            category="map",
            family="forest_1",
            source=corner,
            size=(32, 32),
            tags=["derived", "terrain", "geometry", "inner_corner"],
            region=[0, 0, 32, 32],
        )


def main() -> None:
    assets: list[dict[str, Any]] = []
    process_characters(assets)
    process_bee(assets)
    process_snail(assets)
    process_boar(assets)
    map_root = IMPORTED / "Legacy-Fantasy-High Forest" / "Map Assets"
    process_map_tile_atlas(assets, map_root / "Forest-1.png", "forest_1")
    process_map_tile_atlas(assets, map_root / "Forest-2.png", "forest_2")
    process_map_components(assets)
    process_derived_assets(assets)

    category_counts = Counter(str(asset["category"]) for asset in assets)
    family_counts = Counter(str(asset["family"]) for asset in assets)
    manifest = {
        "version": 2,
        "pipeline": "atlas_first",
        "source_root": "res://art/imported",
        "derived_root": "res://art/runtime/derived",
        "summary": {
            "total_assets": len(assets),
            "by_category": dict(sorted(category_counts.items())),
            "by_family": dict(sorted(family_counts.items())),
        },
        "assets": sorted(assets, key=lambda item: item["id"]),
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"ATLAS_REGIONS={len(assets)}")
    print(f"MANIFEST={res_path(MANIFEST_PATH)}")


if __name__ == "__main__":
    main()
