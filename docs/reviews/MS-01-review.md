# MS-01 — SWAPSHOT code review and regression fix report

**Repository:** `mishraaditya595/swapshot`, [PR #4](https://github.com/mishraaditya595/swapshot/pull/4)  
**Scope:** MS-01, third-person movement, camera and greybox arena (P0)  
**Verification engine:** Godot 4.7.2 stable, Linux headless, via GitHub Actions  
**Review decision:** PASS WITH ISSUES for MS-01's Web-first gameplay foundation. The updated Web build was manually tested on macOS by the project owner (video plus subsequent control/collision confirmations). The original abrupt camera zoom is not apparent in the updated recording. A small dark-surface occlusion is recorded as a nonblocking polish observation. Native editor GUI and release-level Web QA are not claimed; merge remains subject to fresh CI and review.

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

### Recorded near-obstacle zoom and abrupt recovery — automated and browser retests completed (P1)

- **Human evidence:** November 3 user-supplied browser screen recording (approximately 10.8–11.3 seconds near cover/ramp and 17–18.5 seconds near elevated geometry) showed a camera pushing close to the avatar and snapping back to the normal follow distance. This was a real usability defect, not an FOV change.
- **Root cause:** `SpringArm3D` sets its child position to the collision endpoint every physics frame; when the obstruction disappears, its full 3.5 m distance returns in one tick. The existing custom shoulder offset also changed immediately; the camera was allowed inside the visible player mesh on close collisions. Safe geometry tests were not sufficient to detect this.
- **Failing regression:** [red Godot run 41582105118](https://github.com/mishraaditya595/swapshot/actions/runs/41582105118) explicitly reported 4 failures: body fade, visor fade, one-tick distance recovery, and restoration of avatar visibility.
- **Correction:** `scripts/shoulder_camera.gd` constrains distance and shoulder offset to the **safe current frame** collision endpoint immediately, but restores the normal distance at 5 m/s and right offset at 3 m/s after clearance. A cached `PhysicsShapeQueryParameters3D` avoids unnecessary per-tick allocation. Duplicated suit/visor `StandardMaterial3D` alpha materials fade away when the camera is very near and recover after obstruction. Using `GeometryInstance3D.transparency` was ruled out because the Compatibility renderer ignores it.
- **Green verification:** [Godot 4.7.2 CI 41582259952](https://github.com/mishraaditya595/swapshot/actions/runs/41582259952) passed the previously failing cases and all prior camera intersection, player movement, collision and ramp traversal smoke tests. The static audit also passed.
- **Safety limitation:** This does **not** promise a fixed-distance camera in a narrow corridor: immediate inward retraction remains necessary to avoid putting the camera through solid geometry. The change removes instant outward recovery and obstructed player visuals, without trading away collision safety.
- **Updated browser retest:** The [successful manually triggered Web deployment](https://github.com/mishraaditya595/swapshot/actions/runs/41582737996) published PR #4 commit `cc0f6f152c3675ee3df996900f96c67dac9df4b7`. In the ~30-second November 3 macOS browser recording, WASD movement, mouse-look, obstacle interaction and ramp/landing traversal looked usable, and the earlier abrupt camera pop was not visibly reproduced. The owner also confirmed Escape, Command+Tab focus switching and movement away from head-on collisions. These observations are distinct from the automated physics results.

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
| PR milestone acceptance | PENDING fresh run | Update tracker and PR acceptance evidence for owner-confirmed Web-first manual QA, then verify new policy run |
| Updated browser build: movement, mouse-look and camera *feel* | PASS (observed) | User's November 3 ~30-second recording of the revised hosted PR #4 game; earlier snap is not apparent |
| Updated Web build / controls and obstacle collisions | PASS (user-reported) | [Manual deployment 41582737996](https://github.com/mishraaditya595/swapshot/actions/runs/41582737996) plus Escape, Command+Tab and backward/sideways collision recovery confirmation |

**Red-green evidence:** The initial new scenario tests FAILED before the fixes. The same tests PASSED after the camera and ramp changes. One intermediate descent assertion was relaxed from an arbitrary end-position requirement to checking that the player really returned to the ground, avoiding a misleading failure despite completed descent.

## November 3 manual acceptance record

- **Tested revision:** `cc0f6f152c3675ee3df996900f96c67dac9df4b7`, deployed by [GitHub Pages workflow run 41582737996](https://github.com/mishraaditya595/swapshot/actions/runs/41582737996) to the manually maintained `/swapshot/pr-4/` path. Game code is unchanged by subsequent acceptance-document commits, so they do not require a new Web export to test the camera.
- **Environment:** macOS, desktop browser. The user supplied a ~30-second screen recording in this conversation; the original MOV is **not** attached to the repository or PR as a permanent public file. The observations and test answers are preserved here as a written QA record.
- **Observed in recording:** WASD and mouse-look, character navigation beside cover/crates, ramp/elevated geometry, reduced near-obstacle camera snap compared with the initial recording. No clear penetration of visible obstacles.
- **Explicit owner confirmations:** Escape releases the cursor; macOS Command+Tab app switching works; walls and crates block head-on movement; backward and sideways movement continue working after contact. This is successful collision blocking, **not** an immovable-player softlock.
- **Nonblocking observation (P2):** near 9–11 seconds of the new recording, a dark wall/landing surface fills much of the view. This appears to be close-geometry occlusion/shadowing, not the previously reproduced full-distance camera snap. Reassess in a later camera/level-art polish pass if it affects combat readability.
- **Not tested / not asserted:** Godot native editor GUI (owner chose browser-only manual QA), exhaustive diagonal/corner paths, keyboard/controller accessibility, browser performance on multiple devices, or the final itch.io release. Godot 4.7.2 **headless** import/startup and the physics test are already covered by engine CI.

**Acceptance decision:** The P0 MS-01 playability gate has been met for the user's explicitly preferred Web-first workflow. The recorded manual browser test plus engine CI cover launch, controllability, mouse capture/release and focus, obstacle collision, camera behavior, and ramp traversal. The limited P2 visual observation does not block the initial gameplay foundation. Mark MS-01 complete in the tracker only with a fresh policy-and-CI check. The user still controls whether to merge PR #4 and when to manually deploy future builds. No combat or SHIFT features were changed.
