from __future__ import annotations

import json
import re
import shutil
from collections import defaultdict
from pathlib import Path
from typing import Iterable

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
IMPORTED = ROOT / "art" / "imported"
GENERATED = ROOT / "art" / "generated"
PROCESSED = ROOT / "art" / "processed"
MANIFEST_PATH = ROOT / "data" / "asset_manifest.json"


CHARACTER_ROWS_1 = [
    "idle",
    "attack_combo",
    "run",
    "jump_up",
    "fall_land",
    "hurt",
    "death",
    "death_ground",
    "spell_cast",
    "crouch",
    "shield_defence",
]

CHARACTER_ROWS_2 = [
    "walk",
    "walk_extra",
    "slide",
    "wall_slide",
    "critical_attack",
    "ladder_climb",
    "ladder_climb_extra",
]

MAP_SPLIT_CATEGORIES = {
    "Buildings": ("structures", "buildings"),
    "Chest": ("props", "chest"),
    "Chest2": ("props", "chest"),
    "Forest_2": ("foliage", "forest_2"),
    "Hive": ("props", "hive"),
    "Mine_Stone": ("props", "mine_stone"),
    "Props_Rocks": ("terrain", "rocks"),
}


def safe_name(value: str) -> str:
    value = value.replace("&", "and")
    value = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_").lower()
    return value or "asset"


def res_path(path: Path) -> str:
    return "res://" + path.relative_to(ROOT).as_posix()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    return image.getchannel("A").getbbox()


def save_png(image: Image.Image, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


def record(
    assets: list[dict],
    *,
    asset_id: str,
    category: str,
    family: str,
    output: Path,
    source: Path,
    tags: Iterable[str],
    **extra: object,
) -> None:
    with Image.open(output) as image:
        width, height = image.size
    assets.append(
        {
            "id": asset_id,
            "category": category,
            "family": family,
            "output": res_path(output),
            "source": res_path(source),
            "size": [width, height],
            "tags": sorted(set(tags)),
            **extra,
        }
    )


def crop_grid(
    assets: list[dict],
    *,
    source: Path,
    output_dir: Path,
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
            crop = image.crop(box)
            if alpha_bbox(crop) is None:
                continue

            filename = f"{safe_name(family)}_{safe_name(variant)}_{safe_name(action)}_{frame_index:02d}.png"
            output = output_dir / safe_name(variant) / safe_name(action) / filename
            save_png(crop, output)
            record(
                assets,
                asset_id=f"{category}.{family}.{variant}.{action}.{frame_index:02d}",
                category=category,
                family=family,
                output=output,
                source=source,
                tags=[*tags, action, variant, "frame"],
                frame=[column, row],
                frame_size=[frame_width, frame_height],
                action=action,
                variant=variant,
            )
            frame_index += 1


def process_characters(assets: list[dict]) -> None:
    source_root = IMPORTED / "Generic-Character" / "png"
    for color_dir in sorted(source_root.iterdir()):
        if not color_dir.is_dir():
            continue
        color = safe_name(color_dir.name)
        sheet_1 = color_dir / f"char_{color}_1.png"
        sheet_2 = color_dir / f"char_{color}_2.png"
        if sheet_1.exists():
            crop_grid(
                assets,
                source=sheet_1,
                output_dir=PROCESSED / "characters" / "warrior",
                frame_size=(56, 56),
                columns=8,
                rows=11,
                category="character",
                family="warrior",
                action_labels=CHARACTER_ROWS_1,
                variant=color,
                tags=["player", "humanoid", "sprite_sheet"],
            )
        if sheet_2.exists():
            crop_grid(
                assets,
                source=sheet_2,
                output_dir=PROCESSED / "characters" / "warrior",
                frame_size=(56, 56),
                columns=8,
                rows=7,
                category="character",
                family="warrior",
                action_labels=CHARACTER_ROWS_2,
                variant=color,
                tags=["player", "humanoid", "sprite_sheet"],
            )


def process_bee(assets: list[dict]) -> None:
    bee_root = IMPORTED / "Legacy-Fantasy-High Forest" / "Enemies" / "Small Bee"
    for action, relative in {
        "attack": "Attack/Attack-Sheet.png",
        "fly": "Fly/Fly-Sheet.png",
        "hit": "Hit/Hit-Sheet.png",
    }.items():
        crop_grid(
            assets,
            source=bee_root / relative,
            output_dir=PROCESSED / "enemies" / "bee",
            frame_size=(64, 64),
            columns=4,
            rows=1,
            category="enemy",
            family="bee",
            action_labels=[action],
            variant="small",
            tags=["enemy", "flying", "sprite_sheet"],
        )


def process_snail(assets: list[dict]) -> None:
    snail_root = IMPORTED / "Legacy-Fantasy-High Forest" / "Enemies" / "Snail"
    for action, filename in {
        "walk": "walk-Sheet.png",
        "hide": "Hide-Sheet.png",
        "dead": "Dead-Sheet.png",
    }.items():
        crop_grid(
            assets,
            source=snail_root / filename,
            output_dir=PROCESSED / "enemies" / "snail",
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


def process_boar(assets: list[dict]) -> None:
    boar_root = (
        IMPORTED
        / "Legacy-Fantasy-High Forest"
        / "Enemies"
        / "Small Bee"
        / "MapAssets"
        / "Dark_Tree"
        / "Boar"
    )
    if not boar_root.exists():
        return

    for source in sorted(boar_root.rglob("*.png")):
        action = safe_name(source.parent.name)
        with Image.open(source) as image:
            width, height = image.size
        if height <= 0 or width % height != 0:
            continue
        columns = width // height
        crop_grid(
            assets,
            source=source,
            output_dir=PROCESSED / "enemies" / "boar",
            frame_size=(height, height),
            columns=columns,
            rows=1,
            category="enemy",
            family="boar",
            action_labels=[action],
            variant=boar_variant(source),
            tags=["enemy", "ground", "sprite_sheet", "boar"],
        )


def process_map_tile_atlas(assets: list[dict], source: Path, family: str, tile_size: int = 16) -> None:
    image = Image.open(source).convert("RGBA")
    columns = image.width // tile_size
    rows = image.height // tile_size
    output_root = PROCESSED / "map" / "tiles" / family

    for row in range(rows):
        for column in range(columns):
            box = (
                column * tile_size,
                row * tile_size,
                (column + 1) * tile_size,
                (row + 1) * tile_size,
            )
            crop = image.crop(box)
            if alpha_bbox(crop) is None:
                continue
            output = output_root / f"{family}_{column:02d}_{row:02d}.png"
            save_png(crop, output)
            record(
                assets,
                asset_id=f"map.tiles.{family}.{column:02d}_{row:02d}",
                category="map",
                family=family,
                output=output,
                source=source,
                tags=["forest", "tile", "atlas_crop"],
                frame=[column, row],
                frame_size=[tile_size, tile_size],
            )


def copy_split_map_assets(assets: list[dict]) -> None:
    split_root = (
        IMPORTED
        / "Legacy-Fantasy-High Forest"
        / "Enemies"
        / "Small Bee"
        / "MapAssets"
    )
    for source in sorted(split_root.rglob("*.png")):
        if "Boar" in source.parts:
            continue
        parent = source.parent.name
        category, family = MAP_SPLIT_CATEGORIES.get(parent, ("props", safe_name(parent)))
        output = PROCESSED / "map" / category / family / f"{safe_name(source.stem)}{source.suffix.lower()}"
        output.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, output)
        record(
            assets,
            asset_id=f"map.{category}.{family}.{safe_name(source.stem)}",
            category="map",
            family=family,
            output=output,
            source=source,
            tags=[category, family, "pre_split"],
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

            area = len(xs)
            if area >= min_area:
                components.append((area, (min(xs), min(ys), max(xs) + 1, max(ys) + 1)))

    return sorted(components, key=lambda item: (item[1][1], item[1][0], -item[0]))


def process_tree_atlases(assets: list[dict]) -> None:
    tree_root = IMPORTED / "Legacy-Fantasy-High Forest" / "Map Assets" / "Trees"
    for source in sorted(tree_root.glob("*.png")):
        tree_color = safe_name(source.stem.replace("-Tree", ""))
        image = Image.open(source).convert("RGBA")
        components = connected_components(image.getchannel("A"), min_area=3000)
        for index, (area, box) in enumerate(components):
            crop = image.crop(box)
            output = PROCESSED / "map" / "foliage" / "trees" / tree_color / f"{tree_color}_tree_{index:02d}.png"
            save_png(crop, output)
            record(
                assets,
                asset_id=f"map.foliage.trees.{tree_color}.{index:02d}",
                category="map",
                family="trees",
                output=output,
                source=source,
                tags=["forest", "tree", tree_color, "component_crop"],
                bbox=list(box),
                component_area=area,
                variant=tree_color,
            )


def build_manifest(assets: list[dict]) -> dict:
    by_category: dict[str, int] = defaultdict(int)
    by_family: dict[str, int] = defaultdict(int)
    for asset in assets:
        by_category[str(asset["category"])] += 1
        by_family[str(asset["family"])] += 1

    return {
        "version": 1,
        "source_root": "res://art/imported",
        "output_root": "res://art/processed",
        "summary": {
            "total_assets": len(assets),
            "by_category": dict(sorted(by_category.items())),
            "by_family": dict(sorted(by_family.items())),
        },
        "assets": sorted(assets, key=lambda item: item["id"]),
    }


def main() -> None:
    if PROCESSED.exists():
        resolved = PROCESSED.resolve()
        expected = (ROOT / "art" / "processed").resolve()
        if resolved != expected:
            raise RuntimeError(f"Refusing to clean unexpected path: {resolved}")
        shutil.rmtree(PROCESSED)

    assets: list[dict] = []
    process_characters(assets)
    process_bee(assets)
    process_snail(assets)
    process_boar(assets)
    process_map_tile_atlas(
        assets,
        IMPORTED / "Legacy-Fantasy-High Forest" / "Map Assets" / "Forest-1.png",
        "forest_1",
    )
    process_map_tile_atlas(
        assets,
        IMPORTED / "Legacy-Fantasy-High Forest" / "Map Assets" / "Forest-2.png",
        "forest_2",
    )
    copy_split_map_assets(assets)
    process_tree_atlases(assets)

    manifest = build_manifest(assets)
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print(f"PROCESSED_ASSETS={len(assets)}")
    print(f"MANIFEST={res_path(MANIFEST_PATH)}")
    print(f"OUTPUT={res_path(PROCESSED)}")


if __name__ == "__main__":
    main()
