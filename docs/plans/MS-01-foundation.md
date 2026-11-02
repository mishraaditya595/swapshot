# MS-01 — third-person movement and training arena

**Milestone:** MS-01 · **Status:** implementation proposal; manual acceptance pending.
**Basis:** AGENTS.md, docs/GAME_DESIGN.md, docs/ARCHITECTURE.md and docs/MILESTONES.md.

## Intent and boundaries

Create the smallest runnable third-person traversal sandbox for the first combat
prototype. A human must be able to move, aim the camera and navigate around
solid cover without falling out of the arena. Do **not** add rifle, SHIFT,
health, enemies, jump, UI menu systems, third-party assets or plugins here.

## Approaches considered (brainstorming)

- **Chosen: native CharacterBody3D + yaw pivot + pitched SpringArm3D**:
  built-in collisions and no addon risk; controller remains one script.
- **Alternative: custom camera collision ray/shape queries**: more control,
  but extra failure cases and unnecessary work at this milestone.
- **Alternative: import third-party controller**: potentially faster initially
  but adds licensing, versioning and review surface for a solo jam.

## Implementation decisions

- Camera-relative WASD using **physical** key bindings, diagonal normalization,
  acceleration/deceleration and gravity with floor snapping.
- Player physics body keeps a stable orientation; only the visible mesh turns
  toward movement. Yaw and pitch stay on separate camera nodes.
- SpringArm uses a sphere sweep and collision mask excluding the player layer.
- Click to capture mouse, Escape and window focus loss to release.
- A 32 m square physical arena: four walls, three cover crates, and a **ramp**
  leading to an elevated platform. The ramp provides traversal without
  implementing an out-of-scope jump.
- Prototype-only primitive meshes/materials; no external assets or licenses.

## Verification and acceptance

1. Static audit, Python regression suite, tracker structural validator.
2. Godot 4.7.2 headless import/startup plus the MS-01 physics smoke script.
3. Human editor playtest: launch, click to lock, look 360 degrees, pitch stops
   before vertical inversion, test W/A/S/D and diagonals, back into a wall,
   circle cover, ascend/descend ramp, push against corner boundaries, walk
   very close to a wall while rotating camera, Escape and click to recapture,
   alt-tab away and back. Record Godot/OS/commit and observed results.
4. Keep final MS-01 checklist gate **unchecked** until the manual record proves
   camera collision and full controllability. A headless scene check is not
   equivalent to this acceptance gate.

## Risks and rollback

SpringArm sweep and wall-edge behavior require human evaluation; tune arm
offset/margin if camera pushes awkwardly. Restore the starter main scene and
project inputs in the PR if runtime import fails; do not merge a blocking PR.
