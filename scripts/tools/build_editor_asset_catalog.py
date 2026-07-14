from __future__ import annotations

import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "data" / "asset_manifest.json"
CATALOG_PATH = ROOT / "data" / "editor_asset_catalog.json"

GEOMETRY_COORDS = {
    (0, 0), (1, 0), (2, 0), (3, 0), (4, 0),
    (0, 2), (1, 2), (2, 2), (3, 2), (4, 2),
    (0, 3), (1, 3), (2, 3), (3, 3), (4, 3),
    (0, 4), (1, 4), (2, 4), (3, 4), (4, 4),
}
FOREGROUND_COORDS = {(10, 17), (15, 17), (10, 18), (15, 18)}

ANIMATION_FPS = {
    "idle": 6.0,
    "walk": 9.0,
    "walk_extra": 9.0,
    "run": 12.0,
    "fly": 10.0,
    "attack": 12.0,
    "attack_combo": 12.0,
    "critical_attack": 10.0,
    "spell_cast": 10.0,
    "hurt": 10.0,
    "hit": 10.0,
    "hit_vanish": 10.0,
    "hide": 8.0,
    "slide": 12.0,
    "wall_slide": 6.0,
    "jump_up": 10.0,
    "fall_land": 10.0,
    "crouch": 6.0,
    "shield_defence": 6.0,
    "ladder_climb": 8.0,
    "ladder_climb_extra": 8.0,
    "death": 8.0,
    "death_ground": 8.0,
    "dead": 6.0,
}
NON_LOOPING_ACTIONS = {
    "attack",
    "attack_combo",
    "critical_attack",
    "spell_cast",
    "hurt",
    "hit",
    "hit_vanish",
    "death",
    "death_ground",
    "dead",
    "fall_land",
}


def classify_tile(asset: dict[str, Any]) -> dict[str, Any]:
    family = str(asset["family"])
    frame = asset.get("frame", [-1, -1])
    coords = (int(frame[0]), int(frame[1]))

    if family == "forest_1" and coords in GEOMETRY_COORDS:
        return editor_info("geometry_tile", "geometry", "world", "tilemap", "forest_geometry")
    if family == "forest_1" and coords in FOREGROUND_COORDS:
        return editor_info("foreground_tile", "foreground", "none", "tilemap", "forest_foreground")
    if family == "forest_1" and 0 <= coords[0] <= 9 and 13 <= coords[1] <= 15:
        return editor_info("water_tile", "water", "none", "tilemap", "forest_water")
    if family == "forest_1" and coords[0] >= 17 and coords[1] <= 16:
        return editor_info("background_tile", "background", "none", "tilemap", "forest_background")
    return editor_info("library_tile", "library", "none", "tilemap", "forest_library")


def editor_info(
    role: str,
    layer: str,
    collision: str,
    paint_mode: str,
    palette: str,
    *,
    editor_ready: bool = True,
    visual_only: bool = False,
) -> dict[str, Any]:
    return {
        "role": role,
        "layer": layer,
        "collision": collision,
        "paint_mode": paint_mode,
        "palette": palette,
        "editor_ready": editor_ready,
        "visual_only": visual_only,
    }


def classify(asset: dict[str, Any]) -> dict[str, Any]:
    category = str(asset["category"])
    tags = set(map(str, asset.get("tags", [])))
    asset_id = str(asset["id"])
    family = str(asset["family"])

    if "derived" in tags:
        return editor_info(
            "internal_derived",
            "geometry",
            "world",
            "none",
            "forest_geometry",
            editor_ready=False,
        )
    if category in {"character", "enemy"}:
        return editor_info(
            "actor_animation_frame",
            "actors",
            "actor_scene",
            "animated_scene",
            "actor_animation_previews",
            editor_ready=False,
        )
    if asset_id.startswith("map.tiles."):
        return classify_tile(asset)
    if "tree" in tags or "component_crop" in tags:
        return editor_info("background_scene", "background", "none", "scene", "forest_background_scenes")
    if "structures" in tags or family == "buildings":
        return editor_info("structure_scene", "background", "none", "scene", "forest_structure_scenes")
    if "terrain" in tags or family == "rocks":
        return editor_info("terrain_prop_scene", "foreground", "none", "scene", "forest_prop_scenes", visual_only=True)
    if "foliage" in tags or family == "forest_2":
        return editor_info("foliage_scene", "background", "none", "scene", "forest_background_scenes")
    if "props" in tags:
        return editor_info("prop_scene", "foreground", "none", "scene", "forest_prop_scenes", visual_only=True)
    return editor_info("unclassified", "library", "none", "none", "unclassified", editor_ready=False)


def editor_texture_reference(asset: dict[str, Any]) -> dict[str, Any]:
    reference: dict[str, Any] = {"texture": asset["source"], "region": None}
    if "frame" in asset and "frame_size" in asset:
        frame_x, frame_y = map(int, asset["frame"])
        frame_width, frame_height = map(int, asset["frame_size"])
        reference["region"] = [
            frame_x * frame_width,
            frame_y * frame_height,
            frame_width,
            frame_height,
        ]
    elif "bbox" in asset:
        left, top, right, bottom = map(int, asset["bbox"])
        reference["region"] = [left, top, right - left, bottom - top]
    return reference


def build_animations(assets: list[dict[str, Any]]) -> list[dict[str, Any]]:
    groups: dict[tuple[str, str, str], dict[str, list[dict[str, Any]]]] = defaultdict(lambda: defaultdict(list))
    for asset in assets:
        if asset["category"] not in {"character", "enemy"}:
            continue
        action = str(asset.get("action", "default"))
        variant = str(asset.get("variant", "default"))
        key = (str(asset["category"]), str(asset["family"]), variant)
        groups[key][action].append(asset)

    animations: list[dict[str, Any]] = []
    for (category, family, variant), action_groups in sorted(groups.items()):
        actions: list[dict[str, Any]] = []
        for action, frames in sorted(action_groups.items()):
            ordered = sorted(frames, key=lambda item: (item.get("frame", [0, 0])[1], item.get("frame", [0, 0])[0]))
            actions.append(
                {
                    "name": action,
                    "fps": ANIMATION_FPS.get(action, 8.0),
                    "loop": action not in NON_LOOPING_ACTIONS,
                    "frames": [editor_texture_reference(item) for item in ordered],
                }
            )
        animations.append(
            {
                "id": f"{category}.{family}.{variant}",
                "category": category,
                "family": family,
                "variant": variant,
                "paint_mode": "animated_scene",
                "actions": actions,
            }
        )
    return animations


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assets: list[dict[str, Any]] = []
    role_counts: Counter[str] = Counter()
    palette_counts: Counter[str] = Counter()

    for source_asset in manifest["assets"]:
        asset = dict(source_asset)
        asset["editor"] = classify(asset)
        asset["editor"].update(editor_texture_reference(asset))
        asset["editor"]["processed_output"] = asset["output"]
        role_counts[asset["editor"]["role"]] += 1
        palette_counts[asset["editor"]["palette"]] += 1
        assets.append(asset)

    catalog = {
        "version": 1,
        "source_manifest": "res://data/asset_manifest.json",
        "rules": {
            "logical_tile_size": [16, 16],
            "scene_anchor": "base_center",
            "texture_filter": "nearest",
            "geometry_collision": "world",
            "decoration_collision": "none",
            "dynamic_tiles": [
                {
                    "id": "forest_water_surface",
                    "source": "res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png",
                    "base": [6, 14],
                    "columns": 4,
                    "fps": 3.0,
                    "loop": True,
                },
                {
                    "id": "forest_water_body_light",
                    "source": "res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png",
                    "base": [3, 13],
                    "columns": 3,
                    "fps": 2.0,
                    "loop": True,
                },
                {
                    "id": "forest_water_body_mid",
                    "source": "res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png",
                    "base": [3, 14],
                    "columns": 3,
                    "fps": 2.0,
                    "loop": True,
                },
                {
                    "id": "forest_water_body_deep",
                    "source": "res://art/imported/Legacy-Fantasy-High Forest/Map Assets/Forest-1.png",
                    "base": [3, 15],
                    "columns": 3,
                    "fps": 2.0,
                    "loop": True,
                },
            ],
        },
        "summary": {
            "total_assets": len(assets),
            "by_role": dict(sorted(role_counts.items())),
            "by_palette": dict(sorted(palette_counts.items())),
        },
        "animations": build_animations(assets),
        "assets": sorted(assets, key=lambda item: item["id"]),
    }
    CATALOG_PATH.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"EDITOR_ASSETS={len(assets)}")
    print(f"ANIMATION_SETS={len(catalog['animations'])}")
    print(f"CATALOG=res://{CATALOG_PATH.relative_to(ROOT).as_posix()}")


if __name__ == "__main__":
    main()
