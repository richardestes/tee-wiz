# tee-wiz — Build TODO

Each line is one concrete thing to build (a node, scene, script, resource, system, or asset).
Grouped by system, not ordered by priority. `[x]` = done, `[~]` = partial.

Legend for mana colors (reference, not a task): fire=red, water=blue, poison=green, lightning=yellow, dark=purple.

## Core / flow
- [x] Single scene (main.tscn)
- [x] First-person camera
- [ ] Encounter trigger
- [ ] Clear-encounter check
- [ ] Death → run-over state
- [ ] Hole counter
- [ ] Next-hole load
- [ ] Course-complete check
- [ ] Boss hole

## Player / hands
- [x] FPS controller
- [x] Sprite arms
- [x] Right hand: club mode (charge shot)
- [ ] Right hand: cursor mode
- [ ] Mode swap (club ↔ cursor)
- [ ] Left hand: projectile
- [ ] Nearest-enemy aim
- [ ] Left-hand lock (upgrade)

## Golf
- [x] Ball physics
- [x] Shared trajectory fn
- [x] Arc-preview line
- [x] Hole lock-on
- [x] Lock-on radius gate
- [ ] Ball-in-cup detect
- [ ] Sink → clear + kill all

## Cart
- [x] Cart driving
- [x] Enter/exit swap
- [ ] Cart 3D model
- [ ] Item display rack
- [ ] Chest drive-up pickup

## Mana & loops
- [ ] Mana store (5 types)
- [ ] Per-type cap (3)
- [ ] Mana HUD
- [ ] Loop scene
- [ ] Loop color = type
- [ ] Ball-through detect
- [ ] Add mana on pass
- [ ] Loop-recolor upgrade

## Club-staffs
- [ ] Staff resource
- [ ] Starting fire staff
- [ ] Type-gating
- [ ] Multi-color staff
- [ ] Staff switching

## Spells / cards
- [ ] Spell resource (card)
- [ ] Mana-cost check (typed + generic)
- [ ] Spend mana on play
- [ ] Auto-cast loop (L→R)
- [ ] Switch cooldown
- [ ] Free starter spell
- [ ] Limited-use spells
- [ ] Toolbar UI
- [ ] Drag-reorder
- [ ] Upgrade slots (3/spell)
- [ ] Upgrade effects (dmg / rate / cd / AoE / cost)

## Enemies
- [ ] Enemy scene (billboard)
- [ ] Advance-at-player AI
- [ ] Contact damage + die
- [ ] Spawner
- [ ] XP drop
- [ ] Item drops (health / ammo / coins)
- [ ] Pickup magnet

## Progression
- [ ] XP + level curve
- [ ] Level-up screen
- [ ] Reward options
- [ ] Apply reward

## Combo & grading
- [ ] Combo meter
- [ ] Hit resets combo
- [ ] Combo → enemy buffs
- [ ] Hole grade (D–S)
- [ ] Grade → chest tier

## Chests / rewards
- [ ] Chest scene
- [ ] Sky-drop spawn
- [ ] Open → reward

## Courses & tooling
- [ ] Color-code script (Python/Pillow)
- [ ] Zone masks (rough/fairway/green/hazard)
- [ ] Heightmap import (Blender/Terrain3D)
- [ ] Hand-authored 9 holes
- [ ] Course props (asset pack)
- [ ] (stretch) Prefab-hole assembly

## Crowds (later)
- [ ] Crowd sprite
- [ ] Grid spawn points
- [ ] Cheer on combo
- [ ] Flee from ball
- [ ] State sprite swap
- [ ] Combo-scaled growth
