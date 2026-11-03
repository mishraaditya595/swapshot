# SWAPSHOT game design

SWAPSHOT is being built for GitHub Game Off 2026, themed **SHIFT**. Its design tagline is "Don't take cover. Change the battlefield." The [original interactive brief](../.agents/skills/swapshot-review/references/source-design-brief.html) contains the wider concept. This document defines the planned gameplay; consult [MILESTONES.md](MILESTONES.md) to see what has actually been built.

## Premise and core loop

Vex infiltrates the Helix research facility to retrieve an experimental core. The player moves and aims in third person, shoots with the VX-7 rifle, and plants a holographic anchor on reachable ground. SHIFT teleports Vex to the anchor for a flank, leaving a brief echo that distracts nearby guards.

Gunplay should stand on its own. SHIFT adds opportunities to flank and redirect enemies during a firefight.

## Prototype tuning targets

| System | Intended target |
| --- | --- |
| Anchor placement range | 18 m |
| Anchor lifetime | 8 s |
| SHIFT cooldown | 4 s after successful activation |
| Active anchors | 1 |
| Echo | 1.5 s |
| Arrival protection | 0.15 s |
| Rifle | Automatic hitscan, 24 rounds, about 1.5 s reload |
| Player | 100 HP; healing later as tuned |

Anchors must be placed on valid surfaces within line of sight. Check player capsule clearance both when placing an anchor **and when activating SHIFT**. Reject teleports through walls, cover, or occupied space without consuming the cooldown. Expired anchors and echoes must be removed safely. These values are targets to tune through playtests.

## Planned controls

WASD move · Mouse look/aim · Left click fire · Right click ADS · Q deploy anchor · Left Shift SHIFT · R reload · E interact · Tab objective · Esc pause. Implement via Godot InputMap actions.

## Release scope

**P0 prototype:** one greybox arena with third-person movement and camera, rifle damage, one guard with readable attacks, safe SHIFT and echo behavior, a basic HUD, death/restart, and a win condition.

**P1, after P0 works:** an 8–12-minute mission across three zones:
1. Loading Dock (2–3 min): fundamentals and first flank behind cargo.
2. Security Core (3–4 min): elevated catwalk combat and terminal shutdown.
3. Extraction (3–5 min): retrieve core, final resistance and escape.

**P2:** optional turret, scoring, animation polish, and controller support.

**Excluded:** open world, multiplayer, crafting, gear economy, elaborate squad AI or bespoke AAA asset production.

## Visual and distribution direction

Use low-poly industrial sci-fi environments with graphite and steel surfaces, cyan SHIFT effects, and amber enemy indicators. Reuse geometry and limit expensive effects to keep the game readable and browser performance steady. The intended release is an HTML5 build on itch.io using Godot's Compatibility renderer; a desktop build is optional. Test the hosted browser build before submitting, ahead of the December 1, 2026 Game Off deadline.

## Delivery sequencing

Use [MILESTONES.md](MILESTONES.md) for the implementation order, quality checks, target dates, and PR links. This design defines the scope. The tracker records delivery status; planned work must not be described as implemented.

## Change control

Playtesting may change the tuning targets. Changes to the core loop or milestone scope require an approved design note. Keep proposed behavior, implemented behavior, automated test results, and manual playtest findings separate.
