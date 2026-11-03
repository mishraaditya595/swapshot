# MS-03 review: SHIFT anchor and landing safety

**Repository / base..head:** `mishraaditya595/swapshot`, `main...feat/ms-03-shift-safety`, PR #11. Review spans gameplay and test changes on this draft branch.
**Scope/milestone:** P0, MS-03 only.
**Reviewed files:** `scripts/shift_ability.gd`, `scenes/abilities/shift_ability.tscn`, `scenes/player/player.tscn`, `project.godot`, `tests/ms03_shift_smoke.gd`, CI workflow, design and plan.
**Test environment:** GitHub Actions Godot 4.7.2 headless; local Godot and hosted Web playtest unavailable.
**Decision:** INSUFFICIENT EVIDENCE for milestone acceptance pending latest CI and owner Web playtest.

## Findings

No code-proven P0/P1 issue found in the initial diff review. The placement path checks player range, vertical limit, slope, player-eye visibility, expanded capsule and floor support; the activation path repeats the checks before moving the player. Rejected actions do not change player position or consume the current anchor.

### P1 risk to test: browser controls and visual feedback

- **Evidence:** `scripts/shift_ability.gd` gates Q and Left Shift on captured pointer state; camera preview and visual discs are procedural.
- **Reproduction:** Manually deploy this PR preview, click to capture the mouse, aim at ground, press Q and Left Shift; repeat after Escape and focus changes.
- **Expected:** Distinct valid/invalid floor indicator, immediate feedback, no surprising SHIFT on focus changes, and stable player/camera movement.
- **Observed:** NOT RUN in a browser; no player observation is claimed.
- **Impact:** The ability could be hard to read or feel awkward despite passing headless collision checks.
- **Smallest recommended test:** Short owner-recorded Web playtest on ground, platform, wall, crate corner and occupied landing.
- **Confidence:** Needs verification.

### P2: lifecycle intentionally deferred

MS-04 will add the 8-second expiry, post-SHIFT cooldown, decoy echo and associated input/lifetime tests. MS-03 consumes a successful anchor but permits immediate redeployment. This is a scoped decision, not a completed lifecycle.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit and Python tests | PASS on initial PR commit | [CI run 41611540960](https://github.com/mishraaditya595/swapshot/actions/runs/41611540960) |
| Godot 4.7.2 import and startup | PASS on initial PR commit | Same CI run |
| MS-01 and MS-02 regressions | PASS on initial PR commit | Same CI run |
| MS-03 headless safety checks | PASS on initial PR commit | Same CI run, explicit `MS-03 SMOKE PASS` log |
| Updated, stricter MS-03 tests | NOT RUN when report drafted | Await fresh PR-head CI |
| PR milestone acceptance | FAIL by design | Draft milestone remains unchecked pending owner acceptance |
| Manual SHIFT/controller/camera | NOT RUN | Owner Web playtest required |
| Actual browser export and hosted Web | NOT RUN | Deployment is manual |
| Echo and cooldown | OUT OF SCOPE | MS-04 |

## Scope acceptance

| Requirement | Implemented? | Verified? | Notes |
| --- | --- | --- | --- |
| Existing movement/aim | Unchanged | Initial CI regression PASS | MS-01 |
| Rifle | Unchanged | Initial CI regression PASS | MS-02 |
| Anchor range, slope and floor | Yes | Initial CI smoke PASS | Visual feedback still needs human testing |
| Capsule clearance at place and activate | Yes | Initial CI smoke PASS; stricter isolation test pending | No player clipping claimed beyond tested cases |
| Camera and velocity stable | Code path present | Initial headless smoke PASS | Human camera feel unverified |
| Echo, expiry and cooldown | No | Out of scope | MS-04 |
| One trooper, goal/restart | No | Out of scope | MS-05/MS-06 |

## Risks and next action

Fresh CI must pass on the final commit, and the owner must record real browser behavior. Keep PR #11 in draft and the MS-03 milestone unchecked until acceptance evidence supports each task. Reviewed doc prose against the local humanizer guidance, preserving paths, commands, claims and status.
