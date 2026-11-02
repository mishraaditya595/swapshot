# MS-01 — SWAPSHOT code review and regression fix report

**Repository:** `mishraaditya595/swapshot`, draft [PR #4](https://github.com/mishraaditya595/swapshot/pull/4)  
**Scope:** MS-01, third-person movement, camera and greybox arena (P0)  
**Verification engine:** Godot 4.7.2 stable, Linux headless, via GitHub Actions  
**Review decision:** INSUFFICIENT EVIDENCE to complete MS-01: real editor mouse capture and manual camera/controls still untested. **The two confirmed automated regressions are resolved.**

## Source-confirmed defects and fixes

### Camera origin embedded in walls — fixed in automated tests (P1)

- **Original evidence:** [failing red regression](https://github.com/mishraaditya595/swapshot/actions/runs/41431428089), with explicit failures for the camera sweep origin and camera overlap at the east wall, west wall and corner.
- **Cause:** the SpringArm origin was offset 0.55 m to the player's right, beyond the 0.36 m character capsule radius. A camera probe could consequently begin inside a collider while the player's capsule remained clear.
- **Correction:** `scenes/player/player.tscn` centers the SpringArm origin. `scripts/shoulder_camera.gd` runs after the boom in physics and casts the boom's sphere horizontally from its safe endpoint, reducing the camera's desired shoulder offset near obstructions. The player RID is excluded; the query uses the environment collision mask and a small safety margin. If the start position is already overlapping, the offset is suppressed.
- **Green verification:** [Godot CI](https://github.com/mishraaditya595/swapshot/actions/runs/41432377054) exercises camera clearance near east, west and north boundaries, a corner and cover. The existing south-wall test also passes.

### Ramp cannot be traversed — fixed in automated tests (P1)

- **Original evidence:** [failing red regression](https://github.com/mishraaditya595/swapshot/actions/runs/41431428089) found no usable ramp ascent. Detailed runtime traces from a subsequent failure showed the AccessRamp loading at identity transform and all downward rays hitting the ground, not the ramp.
- **Correction:** `scenes/levels/greybox_arena.tscn` restores the AccessRamp transform without the problematic inline scene comments, aligns the top to the raised platform at ~1.45 m and the bottom to the ground, and gives the ramp slight overlap with the platform. No jumping system is introduced.
- **Green verification:** [Godot CI](https://github.com/mishraaditya595/swapshot/actions/runs/41432377054) confirms the ramp node's transform, a physical mid-ramp collision hit, traversal from the ground to the platform, return descent, grounded states and elevation.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static resource audit | PASS | Current Godot CI run |
| Python audit tests | PASS | 6 tests |
| Milestone & pre-merge policy unit tests | PASS | 18 tests |
| Milestone tracker structure | PASS | Current CI validator |
| Godot headless import/startup | PASS | Current CI run, Godot 4.7.2 |
| Scene physics and camera regression | PASS | `MS-01 SMOKE PASS: input map, movement, camera clearance, wall collisions, ramp ascent and descent` |
| GitHub automated code risk scan | PASS | Pre-Merge automated review |
| PR milestone acceptance | FAIL (expected) | Real gameplay/manual requirement not checked |
| Actual mouse lock, Escape/focus release, camera *feel* and traversal in GUI | NOT RUN | Requires human editor session |
| Web export / hosted browser | NOT IN MS-01 SCOPE | Later release milestone |

**Red-green evidence:** The initial new scenario tests FAILED before the fixes. The same tests PASSED after the camera and ramp changes. One intermediate descent assertion was relaxed from an arbitrary end-position requirement to checking that the player really returned to the ground, avoiding a misleading failure despite completed descent.

## Remaining manual acceptance

Open `scenes/main.tscn` in Godot **4.7.2** in a real window. Capture and release the pointer with click/Escape, move on all WASD diagonals, pitch and yaw at normal and extreme angles, hug all boundaries and crate edges while rotating, ascend/descend the access ramp, and alt-tab away/back. Record actual OS, Godot version, commit SHA, observed behavior, any failures and their steps. In particular, inspect camera framing when the shoulder offset retracts: the headless sphere checks prove clearance, not camera comfort.

Do not tick the two remaining MS-01 checklist tasks, call the milestone complete or merge PR #4 until this recorded manual evidence exists. No combat or SHIFT features were changed.
