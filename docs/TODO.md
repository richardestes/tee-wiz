# tee-wiz — Feature TODO

## Core structure
- [ ] Single persistent scene (no split combat/map scenes)
- [ ] Fully first-person perspective at all times
- [ ] Game flow: drive to hole → activate encounter → clear/sink or die → reward → next hole
- [ ] Complete a course by finishing all holes (start: 3 holes; target: 9 incl. boss hole)
- [ ] Death = run over (roguelite)

## Player / hands
- [ ] FPS player controller
- [ ] Billboarded sprite arms
- [ ] Right hand: club-staff (golf club + wizard staff), cursor-aimed (mouse/joystick)
- [ ] Left hand: auto-attacks current spell if mana available; aims at closest alive enemy by default
- [ ] Upgrade: left hand locks onto right hand's target (hold button)

## Golf mechanic
- [ ] Real-time shooting (no separate golf scene)
- [ ] 100% accurate arc preview (shared trajectory function with live shot)
- [ ] Hole lock-on button
- [ ] Bool toggle: lock-on only within a radius
- [ ] Sinking a hole ends encounter + kills all enemies

## Cart
- [ ] Driveable golf cart, still FPS perspective
- [ ] 3D customizable cart
- [ ] Displays 3D representations of purchased/found items
- [ ] Drive up to chests to collect

## Mana & loops
- [ ] 5 mana types: fire=red, water=blue, poison=green, lightning=yellow, dark=purple
- [ ] Max 3 mana of each type
- [ ] Shoot ball through floating loops to collect mana (loop color = mana type)
- [ ] Upgrade: recolor all loops to current staff's mana pattern (repeats sequentially for multi-color staffs; reverts per held staff)

## Club-staffs
- [ ] Start with one fire staff
- [ ] Staff mana type gates which spells can be cast
- [ ] Multi-color staffs unlock multi-type spell casting
- [ ] Switch between unlocked staffs

## Spells (card system)
- [ ] Spells = cards in hand, auto-cast left→right in inventory order
- [ ] Mana is SPENT to play cards (cast itself is free)
- [ ] Card castable only if player has the required mana types (MtG-style: typed + generic costs)
- [ ] Cooldown between spell switches (no instant chaining)
- [ ] Each staff has a starting spell: unlimited uses, no mana cost
- [ ] Reward spells: limited uses; removed when uses run out
- [ ] Minecraft-style toolbar inventory at bottom of screen (spell icons)
- [ ] Drag-and-drop to reorder spells
- [ ] Up to 3 upgrades per spell (VS-style)
- [ ] Spell upgrade examples: +damage, +fire rate, -cooldown, +AoE radius, -mana cost

## Enemies
- [ ] Billboarded sprites
- [ ] Move toward player; on reach, damage player then die
- [ ] Drop XP on kill
- [ ] Can drop items: health kit, spell ammo (extra uses), coins
- [ ] Player magnet (radius) pulls items in

## Progression
- [ ] Vampire Survivors-style leveling
- [ ] Level up → instant reward screen
- [ ] Reward types: new spells, spell upgrades, -spell-switch-cooldown, left-hand lock-on, +HP, target weakness to staff mana type

## Combo & grading
- [ ] Combo meter, Devil May Cry style (D → S)
- [ ] Combo rises per kill without getting hit
- [ ] Higher combo = enemies gain HP, damage, speed (needs heavy playtest balancing)
- [ ] Hole completion grade based on combo
- [ ] Higher grade = better-tiered chest rewards

## Rewards / chests
- [ ] Chests on hole completion (clear min enemies OR sink hole)
- [ ] Chests fall from sky, land on green, driven up to collect

## Courses & tooling
- [ ] Use real top-down course reference images
- [ ] Color-code into 4 sections: rough, fairway, green, hazard
- [ ] Tool (Python/Pillow/OpenCV) to auto color-code images into the dataset
- [ ] Import to Blender / Terrain3D, build crude heightmaps from images
- [ ] One playable hand-authored 9-hole course first; easy to add more after
- [ ] Stretch: randomly assemble courses from prefab holes
- [ ] Course props: simple low-poly 3D models (find an asset pack)

## Crowds (later)
- [ ] Billboarded crowd sprites (fallback: Rocket League-style spheres)
- [ ] Stand in grid spawn points along rough/fairway/green edges
- [ ] Cheer (jump) when combo rises; scatter/disappear when ball shot toward them
- [ ] Sprite swaps per state (cheer/flee)
- [ ] Crowd grows with combo; expands outward from middle (math-driven)
