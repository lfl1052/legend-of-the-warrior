# Pixel Art And Collision Standard

## Logical Canvas

- Gameplay is authored on a `640x360` logical viewport and displayed in a `1280x720` default window.
- The environment grid is 16 pixels. A normal player body occupies roughly two tiles in visible height.
- Nearest filtering and integer stretch are required. Camera zoom is not a substitute for consistent asset scale.

## Scale Bands

| Role | Visible height relative to player | Purpose |
| --- | ---: | --- |
| Small enemy | 0.55-0.90 | Low silhouette and low threat |
| Normal enemy | 0.80-1.30 | Shares the player's combat plane |
| Elite / boss | 1.25-1.80 | Clearly dominant without hiding nearby terrain |

These bands use non-transparent pixels, not the source frame canvas. Transparent padding must never determine gameplay scale.

## Scene Contract

Ground actors use their scene root as the authored floor anchor:

```text
CharacterBody2D  (root / authored floor anchor)
|-- Visual       (render-only position and scale)
|-- CollisionShape2D
|-- PhysicsCheck
`-- AttackBox    (independent hit box)
```

- The body collider bottom and the visible sprite bottom must resolve to the same local Y within one pixel.
- `Visual` may be offset or mirrored. Body and attack collision nodes must not inherit visual scale.
- Attack range follows the combat role and is not inferred from transparent sprite bounds.
- Ground spawn Y equals the surface Y minus the collider bottom offset. Do not compensate for bad visual alignment in level scenes.
- Flying actors are exempt from the floor anchor rule but still require a body collider centered on their active silhouette.

## Import And Review

0. Prefer the original sheet/atlas and select content through TileSet atlas coordinates,
   `AtlasTexture.region`, or SpriteFrames regions. Do not generate one PNG per tile or animation
   frame. Only manually composed or repaired art belongs in `art/runtime/derived/`.
1. Confirm frame columns and rows against the source image dimensions.
2. Inspect non-transparent bounds for idle, movement, attack, hurt, and death frames.
3. Set visual scale from the scale band, then align the representative idle frame to the body collider.
4. Verify body collision, attack collision, and facing independently.
5. Capture the actor beside the player on representative terrain before accepting the asset.

## Automated Gates

- Actor scenes load with an independent body collider and animation owner.
- Ground actor visible bottoms align with collider bottoms within one logical pixel.
- Active actor height ratios remain inside the role bands above.
- Level smoke tests confirm actors settle on TileMap collision without corrective scene offsets.

## Animation Ownership

- Player `AnimationPlayer` clips own timing and state transitions; `PlayerController` maps the active clip time to sprite sheet frames.
- Enemy `AnimationPlayer` clips own their sprite frame and visibility tracks directly.
- A single property must have one runtime owner. Do not key `Sprite2D.frame` in an animation while also changing it from a per-frame script.
- Attack hit boxes remain gameplay-owned and are enabled only during explicit startup / active / recovery windows.
