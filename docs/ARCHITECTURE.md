# Technical architecture

The planned architecture uses Godot **4.7.2**, GDScript, and the GL Compatibility renderer. Components should remain small enough to test independently. The table describes intended responsibilities, not the current implementation state:

| System | Intended role | Likely Godot primitive |
| --- | --- | --- |
| Player | camera-relative movement, health, input | CharacterBody3D |
| Camera rig | over-shoulder camera and aiming | SpringArm3D, Camera3D |
| Weapon | auto hitscan, damage, reload and feedback | RayCast3D / physics direct-space queries |
| SHIFT | anchor validation, safe teleport, echo, cooldown | Raycast/shape clearance, signals, timer/state |
| Enemy | detect/attack/reposition/distract/die | CharacterBody3D, explicit state machine |
| Mission | objectives, encounter gates, checkpoints | scene nodes / signals |
| UI | ammo, health, cooldown, objective, pause | Control nodes |

## Source layout

- `scenes/player/`, `scenes/abilities/`, `scenes/weapons/`, `scenes/enemies/`, `scenes/levels/`, `scenes/ui/`: scenes and their scene-specific behavior
- `scripts/`: shared logic (only introduce global autoloads when justified)
- `assets/`: licensed models/materials/audio, with later attribution manifest
- `tests/`: mechanic regressions and manual-playtest procedure
- `docs/`: design, approved specs/plans, notes and decisions

## SHIFT state machine

The intended sequence is `IDLE` → `ANCHOR_ACTIVE` (until expiry) → revalidate on activation → `TELEPORT` → `ECHO_ACTIVE` and `COOLDOWN` → `IDLE`. If validation fails, the player stays in place and the ability is not consumed. On a successful teleport, preserve the intended camera direction and prevent velocity exploits. Test the timing edge cases around anchor expiry, death, cooldown, and scene transitions.

## Dependency policy

Use built-in Godot nodes, GDScript, and Python's standard library for repository tools by default. New addons, C# dependencies, binary art packs, or remote runners require a specific benefit, a license and security review, and developer approval.
