# MS-01 — third-person movement and training arena

**Milestone:** MS-01 · **Status:** browser-based acceptance recorded on November 3, 2026; merge pending.
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
  Its origin stays on the capsule centerline: a separate camera script sweeps
  sideways at the camera endpoint before applying the over-the-shoulder offset,
  preventing the sweep origin or camera from starting inside nearby cover.
- After the November 3 hosted-browser recording showed abrupt camera close-ups
  beside cover and the upper landing, apply a collision-safe recovery policy:
  **immediate inward retraction** (never allow a blocked camera to clip through
  geometry), but **speed-limited return** to the normal 3.5 m follow distance
  and shoulder offset. Cache the lateral physics-shape query instead of
  allocating it each physics tick. Preserve the existing centered boom probe
  so walls/corners still pass clearance checks.
- Close-up avatar visibility: fade both suit and visor with duplicated
  StandardMaterial3D alpha materials when the camera comes closer than 1.5 m;
  fully suppress the near-field mesh below ~0.75 m, then smoothly restore it.
  Do **not** use GeometryInstance3D.transparency: Compatibility ignores it.
  Keep this limited to the two small prototype meshes for Web performance.
- Regression approach: add a headless close-wall/recovery/mesh-visibility
  scenario before the fix, require a failing run, then prove the same scenario
  passes after the fix alongside the existing wall/cover/ramp cases. Human
  browser recording must still confirm actual camera comfort.
- Click to capture mouse, Escape and window focus loss to release.
- A 32 m square physical arena: four walls, three cover crates, and a **ramp**
  leading to an elevated platform. The ramp starts flush with the floor and
  overlaps the raised platform edge; both ascent and descent are covered by
  automated physics checks without implementing an out-of-scope jump.
- Prototype-only primitive meshes/materials; no external assets or licenses.

## Verification and acceptance

1. Static audit, Python regression suite, tracker structural validator.
2. Godot 4.7.2 headless import/startup plus the MS-01 physics smoke script.
3. **MS-01 owner-selected Web-first acceptance:** rather than requiring a
   local Godot editor session, launch the manually deployed HTML5 build in
   a desktop browser. Record the tested PR SHA, OS, movement, mouse-look,
   Escape release/recapture, application focus loss/return (Command+Tab on
   macOS), head-on wall/crate blocking, backward/sideways escape from contact,
   ramp/landing traversal, and near-obstacle camera behavior. Manual recordings
   and owner-reported outcomes are valid evidence for this Web-first milestone.
   Native Godot GUI startup is **not** claimed; CI still checks Godot 4.7.2
   headless import/startup and physics. The final Web release milestone
   retains its separate hosted-release QA gate.
4. Record the acceptance decision and any nonblocking visuals in the
   implementing PR and review report. Do not equate passing engine physics
   with manually observed camera feel, and do not mark a test that was not
   actually performed.

## Risks and rollback

SpringArm sweep and wall-edge behavior require human evaluation. In extremely
narrow spaces the camera must still retract immediately for collision safety;
this cannot be eliminated entirely without permitting geometry clipping.
The close-up fade and eased recovery were checked in the user's November 3
recording of the manually deployed build. Keep the minor close-platform dark
geometry occlusion as a later polish observation. Restore the starter main scene and
project inputs in the PR if runtime import fails; do not merge a blocking PR.
