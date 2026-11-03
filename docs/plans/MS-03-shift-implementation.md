# MS-03 implementation plan

1. Add InputMap actions for Q deploy and Left Shift teleport.
2. Mount one ShiftAbility scene on the existing player, using the actual CharacterBody3D collider for arrival clearance. Display a cyan or orange floor disc and a compact status label.
3. Query the current camera target; validate 18 m player range, slope, vertical gap, player-eye line of sight, five floor probes and an expanded capsule overlap before placement.
4. Re-run those queries on activation. Reject without changing the player or anchor. On success, teleport the player root, zero velocity, retain camera yaw/pitch, consume the anchor.
5. Add deterministic headless smoke cases and execute them in Godot CI alongside MS-01/MS-02 regression suites. Update README and the milestone tracker only for verified items.

**Manual acceptance:** Deploy on arena ground and elevated platform, SHIFT repeatedly, try wall/crate/ledge/far targets, add an obstacle after placement, check camera while sprinting and aiming, repeat after mouse release/refocus. Record browser footage and observed results before completing the milestone.

**Rollback:** Delete the ShiftAbility child/resource, remove the two new InputMap actions and CI smoke step; MS-01/MS-02 behavior remains isolated.
