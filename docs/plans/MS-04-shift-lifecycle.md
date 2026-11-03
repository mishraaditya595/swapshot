# MS-04 SHIFT lifecycle implementation plan

MS-03 owns floor targeting, capsule clearance and teleport safety. MS-04 adds the timing and feedback specified in the milestone without weakening those checks.

## Design choice

Three models were considered: dedicated Timer nodes, wall-clock deadlines and one physics-delta clock. A physics-delta clock was selected because anchor expiry and cooldown both stop during pause, and exact time boundaries can be tested without real-time sleeps. The echo has an independent lifetime while cooldown continues.

## Implementation

1. Keep the ShiftAbility scene and its placement/activation checks. Add READY, ANCHOR_ACTIVE, COOLDOWN and DISABLED states, plus configurable 8-second anchor, 4-second cooldown and 1.5-second echo targets.
2. Start anchor time on Q. Expiry clears the anchor, notifies observers and leaves the device ready. Failed activation preserves the anchor and cooldown. Successful SHIFT consumes the anchor and starts cooldown.
3. Spawn a collision-free hologram at the player's previous world transform, fade and remove it on time, and signal its creation/end for MS-05 enemy AI. Add a small timer label and generated audio pulses without new assets.
4. Reject repeated Q/Shift. Pause freezes timers. set_owner_alive(false) clears owned effects and disables input; set_owner_alive(true) and reset_lifecycle() reset the ability. MS-06 will integrate these hooks with health and retry.
5. Run deterministic Godot checks for timing, blocked landing, cooldown spam, pause, echo disposal, signals, death and scene reload. Adapt the MS-03 repeated-use test to the new cooldown.

## Acceptance and rollback

Fresh Godot CI evidence and a human hosted Web playtest are required for acceptance, including Q, Left Shift, HUD, pause, audio/visual feedback and repeated SHIFTs. Code inspection alone cannot establish gameplay feel or browser performance. Roll back the lifecycle additions, echo scene and MS-04 smoke step if needed; keep MS-03 collision validation intact.
