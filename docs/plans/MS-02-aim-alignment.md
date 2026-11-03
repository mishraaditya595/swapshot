# MS-02 — aim alignment after PR #8 gameplay feedback

**Source evidence:** The owner supplied a 42-second PR #8 browser recording on November 3, 2026 and confirmed firing, reload and aiming work. The recording shows camera rotation while the character's cyan visor stays oriented toward its prior forward direction. Source review also found the rifle was a direct child of Camera3D.

## Goal

The third-person character and gun should visibly follow mouse-look when standing, strafing, aiming up/down and turning to look behind, without losing accurate camera-reticle hit detection or muzzle obstruction safety. Stay within Godot 4.7.2 Compatibility and the same MS-02 PR.

## Brainstormed approaches

1. **Rotate the character only.** Fixes the visor, but leaves the rifle floating with the camera rather than attached to Vex. Rejected.
2. **Move the rifle to the character only.** Fixes attachment, but movement-direction-only body yaw leaves stationary shots pointing sideways. Rejected.
3. **Synchronize combat facing and add a shoulder mount (selected).** While the pointer is captured, VisualRoot yaw follows CameraPivot; a WeaponPivot under VisualRoot pitches with CameraBoom, and the existing VX-7 is mounted there. The camera ray still establishes intended target, and camera-to-muzzle plus muzzle-to-target obstruction checks prevent shooting through cover. No new plugins, bone rigs or expensive animation are needed.

## Implementation and verification

Update player/controller, player scene, weapon camera/player references, weapon mesh and muzzle offsets, HUD binding and Godot smoke test paths. Verify left/right/180-degree yaw and pitch alignment during mouse-look, then rerun the original damage, rate, reload, close-cover and MS-01 camera tests. Publish PR #8 manually only when the owner chooses and visually inspect rifle placement, hit feedback, ADS and close-cover shooting before accepting the milestone.

## Deliberate non-goals

No separate head bone, IK rig, locomotion animation framework, new reticle dynamics or changes to SHIFT/AI. The old owner recording supports the original symptom and core controls only, not the corrected behavior.
