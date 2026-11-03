# MS-03 SHIFT safety design

## Intent

SHIFT should let Vex escape a bad angle with a deliberate, visible landing choice. A rejected destination must never move or damage the player. This milestone covers Q placement and Left Shift activation, with a single anchor and basic visual feedback. Expiry, cooldown, echo and advanced state handling remain MS-04.

## Approaches considered

1. **Teleport to the first camera hit:** simple, but a hit on a wall or a narrow ledge can strand the player. Rejected.
2. **Teleport to predefined safe pads:** easy to validate but removes tactical placement, particularly the elevated arena platform. Rejected.
3. **Camera ray followed by independent safety queries:** selected as a working implementation choice. It supports free aim within 18 m and checks geometry again immediately before teleport. Costs a few physics queries while previewing, acceptable for one local player.

## Placement and activation contract

- Camera-center ray selects a candidate floor, and the player-to-target distance must be at most 18 m. The shoulder camera can see around corners, so a separate ray from the player's head rejects those occluded landings.
- The candidate must have an upward normal within 40 degrees of vertical and stay within 4 m of the player's current height. Five downward probes (center and four offsets) reject ledges, uneven landings, and missing floor.
- The full player capsule, expanded slightly for clearance, must not intersect solid world or actors at the proposed arrival origin. The anchor disc uses cyan for clear space and orange for rejected surfaces.
- Q places the anchor when every check passes; an existing anchor remains in place until it is used. Left Shift repeats the range, head-height line-of-sight, floor-support and capsule checks at the moment of activation.
- A failed activation retains the anchor and leaves position and velocity unchanged. Success moves the player to a grounded capsule center and zeroes velocity. Camera pivot yaw and boom pitch are not changed.

## Scope and acceptance

The greybox arena, VX-7 and camera remain unchanged apart from the SHIFT component and control hints. Two Godot InputMap actions are introduced. Headless physics smoke tests cover range, slopes, missing support, collision near the capsule edge, dynamic obstruction, repeated use, camera preservation and velocity reset.

The manual owner Web test must additionally confirm the preview is readable, Q and Left Shift work after pointer capture, elevation feels consistent, and rejected SHIFT causes no visual camera pop or movement lock. The MS-03 milestone stays unchecked until that evidence is captured.

## Implementation sequence

See `docs/plans/MS-03-shift-implementation.md`. No external dependencies, authored art, Web workflow changes or extra combat systems are required.
