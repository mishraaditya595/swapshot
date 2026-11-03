# MS-03 review: SHIFT anchor and landing safety

**Repository / base..head:** `mishraaditya595/swapshot`, `main...feat/ms-03-shift-safety`, PR #11. Review spans gameplay and test changes on this draft branch.
**Scope/milestone:** P0, MS-03 only.
**Reviewed files:** `scripts/shift_ability.gd`, `scenes/abilities/shift_ability.tscn`, `scenes/player/player.tscn`, `project.godot`, `tests/ms03_shift_smoke.gd`, CI workflow, design and plan.
**Test environment:** GitHub Actions Godot 4.7.2 headless; local Godot and hosted Web playtest unavailable.
**Decision:** PASS WITH ISSUES for MS-03 acceptance. Owner confirmed the deployed game's SHIFT mechanics look fine on November 3, 2026; final-head Godot and static CI passed. Human verification of individual safety edge cases, browser frame pacing and the separately requested preview-hub design remains limited.

## Findings

The owner reported a P1 visual-positioning regression in their November 3 browser recording: the deployed anchor marker moved with the player. Source inspection confirmed that `Anchor` and `Preview` inherited the transform of the `Player` through `ShiftAbility`. The marker fix sets both mesh nodes to `top_level` so they stay in world space, and the new headless regression moves and turns the player after deployment. The owner subsequently confirmed a deployed-game playtest and reported the shifting mechanics look fine; this is qualitative owner feedback rather than a detailed edge-case recording. The placement path checks player range, vertical limit, slope, player-eye visibility, expanded capsule and floor support; the activation path repeats the checks before moving the player. Rejected actions do not change player position or consume the current anchor.

### P1 observed: anchor marker inherited player movement

- **Evidence:** Owner-provided November 3 browser recording (`Screen Recording 2026-11-03 at 15.33.41.mov`) and `scenes/abilities/shift_ability.tscn` under the player scene.
- **Reproduction:** Place an anchor with Q, then walk and rotate without teleporting. Previously the disc followed the player even though `anchor_point` stayed in global coordinates.
- **Expected:** The disc stays at the selected floor point and agrees with the teleport destination.
- **Observed:** The marker inherited its parent transform; the landing coordinate was stored separately.
- **Fix:** Set `Anchor` and `Preview` mesh nodes to `top_level`; assert the anchor mesh stays fixed after translating and rotating the player. The owner reports that shifting mechanics look fine in the deployed game after the fix; no new recording or individual test-step log was provided.
- **Confidence:** Observed in video and confirmed from the scene hierarchy.

### P1 risk to test: browser controls and visual feedback

- **Evidence:** `scripts/shift_ability.gd` gates Q and Left Shift on captured pointer state; camera preview and visual discs are procedural.
- **Reproduction:** Manually deploy this PR preview, click to capture the mouse, aim at ground, press Q and Left Shift; repeat after Escape and focus changes.
- **Expected:** Distinct valid/invalid floor indicator, immediate feedback, no surprising SHIFT on focus changes, and stable player/camera movement.
- **Observed:** Owner stated on November 3 that they deployed and tested the game and that SHIFT mechanics look fine. Specific pointer-capture and focus-change transitions were not itemized.
- **Impact:** The ability could be hard to read or feel awkward despite passing headless collision checks.
- **Smallest recommended test:** Short owner-recorded Web playtest on ground, platform, wall, crate corner and occupied landing.
- **Confidence:** Needs verification.

### P2: lifecycle intentionally deferred

MS-04 will add the 8-second expiry, post-SHIFT cooldown, decoy echo and associated input/lifetime tests. MS-03 consumes a successful anchor but permits immediate redeployment. This is a scoped decision, not a completed lifecycle.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit and Python tests | PASS on final reviewed code | [CI run 41617064284](https://github.com/mishraaditya595/swapshot/actions/runs/41617064284) |
| Godot 4.7.2 import and startup | PASS on final reviewed code | Same CI run |
| MS-01 and MS-02 regressions | PASS on final reviewed code | Same CI run |
| MS-03 headless safety checks | PASS on final reviewed code | Same CI run, explicit `MS-03 SMOKE PASS: range, slope, floor, capsule, anchored visual, revalidation, retry, camera, velocity` log |
| Updated, stricter MS-03 tests | PASS on final reviewed code | Same CI run, including moving/rotating player after anchor placement |
| PR milestone acceptance | PENDING on acceptance-doc update | Re-run after milestone tracker and PR body are updated; previous draft CI failed on unchecked MS-03 tasks |
| Manual SHIFT/controller/camera | PASS, qualitative owner report | Owner states deployed gameplay and SHIFT mechanics look fine on Nov 3; browser/version and detailed edge-case log not supplied |
| Actual browser export and hosted Web | Owner-deployed gameplay confirmed | Owner confirms deployed gameplay tested; exact export job, browser and performance data not supplied |
| Echo and cooldown | OUT OF SCOPE | MS-04 |

## Scope acceptance

| Requirement | Implemented? | Verified? | Notes |
| --- | --- | --- | --- |
| Existing movement/aim | Unchanged | Final-head CI regression PASS | MS-01 |
| Rifle | Unchanged | Final-head CI regression PASS | MS-02 |
| Anchor range, slope and floor | Yes | Final-head CI smoke PASS | Owner confirms overall SHIFT experience; no case-by-case manual log |
| Capsule clearance at place and activate | Yes | Final-head CI smoke PASS, including strict overlap and dynamic blocker | No claim of exhaustive player collision testing |
| Camera and velocity stable | Yes | Final-head CI smoke PASS; owner says SHIFT looks fine | No FPS or camera metrics recorded |
| Echo, expiry and cooldown | No | Out of scope | MS-04 |
| One trooper, goal/restart | No | Out of scope | MS-05/MS-06 |

## Risks and next action

Owner's qualitative deployed-game confirmation and the earlier successful final-code CI support accepting MS-03. After updating the checklist, review and PR body, fresh CI and the PR policy gate must pass on that new commit. No automatic merge is authorized. The revised GitHub Pages hub still needs visual review after its generator is delivered to main through a separate owner-triggered deployment. MS-04 cooldown, expiry and echo are out of scope. Reviewed prose against the repository's humanizer guidance while preserving technical paths and evidence boundaries.
