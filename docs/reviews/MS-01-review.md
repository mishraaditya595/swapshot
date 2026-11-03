# MS-01 — SWAPSHOT code review and regression fix report

**Repository:** `mishraaditya595/swapshot`, draft [PR #4](https://github.com/mishraaditya595/swapshot/pull/4)  
**Scope:** MS-01, third-person movement, camera and greybox arena (P0)  
**Verification engine:** Godot 4.7.2 stable, Linux headless, via GitHub Actions  
**Review decision:** INSUFFICIENT EVIDENCE to complete MS-01: user browser recording exposed a new P1 camera-framing issue. Automated recovery/fade regressions are now green; a fresh browser QA pass on the updated build remains required. **Do not merge until manual acceptance is recorded.**

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

### Recorded near-obstacle zoom and abrupt recovery — automatic fix verified, browser feel pending (P1)

- **Human evidence:** November 3 user-supplied browser screen recording (approximately 10.8–11.3 seconds near cover/ramp and 17–18.5 seconds near elevated geometry) showed a camera pushing close to the avatar and snapping back to the normal follow distance. This was a real usability defect, not an FOV change.
- **Root cause:** `SpringArm3D` sets its child position to the collision endpoint every physics frame; when the obstruction disappears, its full 3.5 m distance returns in one tick. The existing custom shoulder offset also changed immediately; the camera was allowed inside the visible player mesh on close collisions. Safe geometry tests were not sufficient to detect this.
- **Failing regression:** [red Godot run 41582105118](https://github.com/mishraaditya595/swapshot/actions/runs/41582105118) explicitly reported 4 failures: body fade, visor fade, one-tick distance recovery, and restoration of avatar visibility.
- **Correction:** `scripts/shoulder_camera.gd` constrains distance and shoulder offset to the **safe current frame** collision endpoint immediately, but restores the normal distance at 5 m/s and right offset at 3 m/s after clearance. A cached `PhysicsShapeQueryParameters3D` avoids unnecessary per-tick allocation. Duplicated suit/visor `StandardMaterial3D` alpha materials fade away when the camera is very near and recover after obstruction. Using `GeometryInstance3D.transparency` was ruled out because the Compatibility renderer ignores it.
- **Green verification:** [Godot 4.7.2 CI 41582259952](https://github.com/mishraaditya595/swapshot/actions/runs/41582259952) passed the previously failing cases and all prior camera intersection, player movement, collision and ramp traversal smoke tests. The static audit also passed.
- **Safety limitation:** This does **not** promise a fixed-distance camera in a narrow corridor: immediate inward retraction remains necessary to avoid putting the camera through solid geometry. The change removes instant outward recovery and obstructed player visuals, without trading away collision safety.
- **Manual retest pending:** The user should trigger the Web deployment manually for the updated PR #4 commit, replay the troublesome paths near cover/ramp/landing and walls, test extreme pitch/orbit and pointer lock/focus. A Godot headless PASS does not prove the browser camera feels good.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static resource audit | PASS | Current Godot CI run |
| Python audit tests | PASS | 6 tests |
| Milestone & pre-merge policy unit tests | PASS | 18 tests |
| Milestone tracker structure | PASS | Current CI validator |
| Godot headless import/startup | PASS | Current CI run, Godot 4.7.2 |
| Scene physics, camera clearance, recovery and avatar fade regression | PASS | [Godot CI 41582259952](https://github.com/mishraaditya595/swapshot/actions/runs/41582259952): `MS-01 SMOKE PASS` after red test |
| GitHub automated code risk scan | PASS | Pre-Merge automated review |
| PR milestone acceptance | FAIL (expected) | Real gameplay/manual requirement not checked |
| Updated browser build: mouse lock, Escape/focus release and camera *feel* | NOT RUN after fix | November 3 recording confirms defect in old build; a new manual deployment and playtest is required |
| Manually deployed Web build | Old build recorded; new build NOT RUN | Later release milestone also retains final Web acceptance gate |

**Red-green evidence:** The initial new scenario tests FAILED before the fixes. The same tests PASSED after the camera and ramp changes. One intermediate descent assertion was relaxed from an arbitrary end-position requirement to checking that the player really returned to the ground, avoiding a misleading failure despite completed descent.

## Remaining manual acceptance

Open `scenes/main.tscn` in Godot **4.7.2** in a real window. Capture and release the pointer with click/Escape, move on all WASD diagonals, pitch and yaw at normal and extreme angles, hug all boundaries and crate edges while rotating, ascend/descend the access ramp, and alt-tab away/back. Record actual OS, Godot version, commit SHA, observed behavior, any failures and their steps. In particular, inspect camera framing when the shoulder offset retracts: the headless sphere checks prove clearance, not camera comfort.

Do not tick the two remaining MS-01 checklist tasks, call the milestone complete or merge PR #4 until this recorded manual evidence exists. No combat or SHIFT features were changed.
