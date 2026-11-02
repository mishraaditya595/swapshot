# SWAPSHOT — authoritative working design

**Event:** GitHub Game Off 2026 — theme **SHIFT**. **North star:** "Don't take cover. Change the battlefield." The interactive original design is checked into `../.agents/skills/swapshot-review/references/source-design-brief.html`. This document is the concise implementation contract, not evidence of implemented mechanics.

## Premise / core loop

Vex enters a Helix industrial research facility to extract an experimental core. Move and aim in third person, fire a responsive VX-7 rifle, deploy a holographic anchor on safe reachable ground, SHIFT to flank enemy guards, and leave a short-lived echo to misdirect pursuit.

**Design rule:** gunplay must feel good without SHIFT; SHIFT must make good firefights spectacular.

## Prototype tuning targets (subject to playtests)

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

Critical correctness: place only on valid surfaces in line of sight, verify capsule clearance at placement **and activation**, never teleport through cover/walls or into occupied space, and never burn cooldown on rejected teleport. Remove expired anchors and echoes safely.

## Planned controls

WASD move · Mouse look/aim · Left click fire · Right click ADS · Q deploy anchor · Left Shift SHIFT · R reload · E interact · Tab objective · Esc pause. Implement via Godot InputMap actions.

## Shippable scope

**P0 (prototype):** single greybox arena; third-person controller/camera; rifle firing and damage; one guard with readable shooting; one safe SHIFT ability/echo; basic HUD; death/restart; one win condition.

**P1 (only after P0 works):** 8–12-minute mission in three zones:
1. Loading Dock (2–3 min): fundamentals and first flank behind cargo.
2. Security Core (3–4 min): elevated catwalk combat and terminal shutdown.
3. Extraction (3–5 min): retrieve core, final resistance and escape.

**P2:** optional turret, scoring, extra animation/polish, controller support.

**Excluded:** open world, multiplayer, crafting, gear economy, elaborate squad AI or bespoke AAA asset production.

## Visual and distribution direction

Low-poly industrial sci-fi, graphite/steel architecture, cyan SHIFT highlights and amber threat indicators. Reusable geometry, minimal effects; prioritize frame pacing and readability. HTML5 export through itch.io using Godot Compatibility; desktop optional. The hosted browser build must be separately tested before submission. Target submission before Game Off's December 1, 2026 deadline.

## Change control

Tuning numbers are goals, not immutable truths. Any major change to core loop or milestone scope needs an approved design note. Distinguish design plan, implemented behavior, automated verification and manual playtest observations.
