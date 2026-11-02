# Technical architecture (planned, not yet implemented)

Engine Godot **4.7.2** / GDScript / GL Compatibility. Build modular scenes with minimal coupling:

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

## SHIFT state-machine invariant

IDLE → ANCHOR_ACTIVE (with expiry) → validate again on request → TELEPORT → ECHO_ACTIVE + COOLDOWN → IDLE. Error branches return to a safe state without teleport or resource consumption. Invalid destinations should never be accepted; teleport should preserve orientation/camera intent and avoid velocity exploits. Race conditions at anchor expiry, death, cooldown and scene transitions need explicit tests.

## Dependency policy

Default to built-in Godot nodes, GDScript and Python standard library for repository tooling. Do not add addons, C# dependencies, binary art packs or remote runners without a clear benefit, license/security review and developer approval.
