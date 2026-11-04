# MS-08 review: Loading Dock opening

**Repository / range:** `mishraaditya595/swapshot`, `main` to `feat/ms-08-loading-dock`, [PR #17](https://github.com/mishraaditya595/swapshot/pull/17).  
**Scope:** P1 Loading Dock only, Godot 4.7.2 Compatibility.  
**Review mode:** Source, headless CI and the owner's November 4 hosted gameplay recording. The corrected build has not been browser-tested.  
**Decision:** CHANGES IMPLEMENTED; BROWSER RETEST REQUIRED. MS-08 and MS-07 stay unchecked.

## November 4 video findings and corrective changes

The owner recorded a hosted PR #17 run ending around 00:58 with three SHIFTS, both guards eliminated and 76/100 armor. This demonstrates a completable browser section, but one run does not establish typical pacing or onboarding clarity.

Two defects were visible in the recording. The tutorial remained on rifle step 02 even after the player had shot guards and used SHIFT, because only the orange practice target's `damaged` event advanced the rifle lesson. The top-left mission instructions also covered the SHIFT status and cooldown text.

The MS-08 follow-up connects both guards' `damaged` signals to the same onboarding handler as the practice target. Valid guard damage now counts as a rifle hit, and earlier anchor/SHIFT events remain recorded. The existing movement-area trigger still starts the tutorial. A new regression replays the video's order: SHIFT first, shoot a guard, enter the training area, and reach combat step 05 without repeatedly performing completed actions.

The director now moves its SHIFT status and timer into a bottom-left, dock-specific panel. The global SHIFT HUD scene stays unchanged for earlier missions. Godot tests check non-overlap with the tutorial, timer, objective and ammo at the default resolution and at 960×540. The practice target gains an amber frame and range sign; the exit sign, floor guide and light change from amber locked to cyan interactable when both guards fall.

[Godot CI 41752720895](https://github.com/mishraaditya595/swapshot/actions/runs/41752720895) passed import/startup, MS-01–MS-08 smoke, static audit and Python tests with those changes. The owner has not yet recorded the revised hosted build, so visual clarity and the original overlap symptom still need a real browser retest.

The 58-second clear is faster than the planned 2–3-minute opening. No timers or additional guards were introduced based on one experienced run. Measure a first-time attempt before tuning fight length. The point-blank camera crowding visible around 34–37 seconds remains a P2 follow-up, while the earlier overhead-geometry and AI concerns are not confirmed defects.

## Findings

### Acceptance blocker: first-time comprehension and duration have not been measured

- **Evidence:** `scripts/ms08_loading_dock.gd` advances prompts through real route, target, anchor and SHIFT events; the new Godot smoke passes those transitions and the final gate. A headless scene cannot establish that players notice the prompts, use SHIFT tactically or finish in the intended two to three minutes.
- **Expected:** An unfamiliar player reaches the Security Core exit without outside guidance and understands SHIFT.
- **Next check:** Deploy PR #17, record the first run and complete `tests/MS-08-BROWSER-QA.md` before checking the milestone.

### P2 follow-up: overhead camera visibility is unconfirmed

- **Evidence:** PR #16's video raised an overhead-geometry question. The Loading Dock uses open main lanes, four-metre perimeter walls and no low overhead physical beams. `scripts/shoulder_camera.gd` is unchanged.
- **Reproduction needed:** Approach walls and cargo at close range while rotating the camera, particularly near any upper trim. Record a browser clip if visibility fails.
- **Decision:** No speculative camera change in MS-08.

### P2 follow-up: point-blank guard engagement is unconfirmed

- **Evidence:** `scripts/security_trooper.gd` still checks eye and muzzle line of sight when acquiring and firing. Existing AI tests passed; no new browser evidence establishes a close-range defect.
- **Reproduction needed:** Stand near the front and sides of a live guard, wait for its warning, and record whether it engages. Include the distance and angle in any report.
- **Decision:** Preserve the established AI until a fault is reproduced.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static SWAPSHOT audit | PASS | [CI 41752720895](https://github.com/mishraaditya595/swapshot/actions/runs/41752720895) |
| Audit Python tests | PASS | Same run, 6 tests |
| Repository Python tests | PASS | Same run, 30 tests |
| Milestone tracker validator | PASS | Same run, MS-00 through MS-16 valid |
| Godot 4.7.2 import | PASS | Same run, official 4.7.2 stable executable |
| Godot startup | PASS | Same run, two headless frames, no reported engine errors |
| MS-01 to MS-07 Godot smoke | PASS | Same run, seven distinct `SMOKE PASS` reports |
| MS-08 Godot smoke | PASS | Same run, dummy and guard hits, early SHIFT catch-up, two viewport HUD layouts, gate cues, blocked SHIFT, win/death replay |
| Rule-based automated code review | PASS | [SWAPSHOT Pre-Merge](https://github.com/mishraaditya595/swapshot/actions/workflows/premerge.yml), limited to static risk checks |
| PR milestone acceptance policy | FAIL, expected | MS-07 prerequisite is unchecked and MS-08 still requires human acceptance; the existing policy has no override for an authorized work-order exception |
| Hosted browser playtest | ORIGINAL RUN OBSERVED | Nov 4 owner video, 00:58 clear, 3 SHIFTS, 76 armor; revised build NOT RUN |
| Revised build browser camera, point-blank AI, FPS, audio and mouse capture | NOT RUN | Requires a new hosted PR snapshot and human player |

The Godot/Python follow-up CI result above is for commit `e9e093392082f732ce1de9f69bd57daffc16c2af`. A final scene text-format and documentation edit follows; confirm its own CI run on the final PR head before merging.

## Source review and scope acceptance

The new `loading_dock.tscn` instances the existing player, practice target, HUD and two troopers. Reusable cargo has physical box collisions. The new director counts eliminated guards once, keeps its gate locked until both die, rejects remote E interaction and freezes input on victory/death. It does not modify `shift_ability.gd`, `security_trooper.gd`, `vx7_rifle.gd` or `ms06_mission.gd`. The original MS-06 and MS-07 tests passed on the same new scene entry build.

The integration change to `tests/ms06_loop_smoke.gd` updates its startup assertion from MS-06 to Loading Dock while retaining the complete MS-06 encounter regression. No new reinforcement spawns exist in this dock section, and the MS-07 echo-safe entry protection remains unchanged.

| MS-08 requirement | Implemented | Automated verification | Human verification |
| --- | --- | --- | --- |
| Containers, crates, cover and flanking lanes | Yes | Scene load and cover ray pass | Route quality pending |
| Contextual movement, rifle, anchor and SHIFT prompts | Yes | Signal/physics transitions pass | Instruction clarity pending |
| Opening two-guard fight, 2–3 minute pacing | Yes, timing is a target | Kills, feedback and counts pass | Actual duration pending |
| Exit gate and next-zone message | Yes | Locked state, proximity, win and replay pass | Readability pending |
| Safe SHIFT and unaffected P0 gameplay | Existing implementation reused | MS-01 to MS-08 pass | Hosted browser safety pending |

## Decision and next action

Keep [PR #17](https://github.com/mishraaditya595/swapshot/pull/17) open and draft. MS-08 completion remains unchecked, as does MS-07. The owner authorized starting MS-08 out of order; that did not accept the prerequisites or waive the review gates. The pre-merge policy check will continue to block merge until its prerequisite requirement is satisfied or an explicitly reviewed policy change is made.

Redeploy PR #17 at the revised commit. Confirm that a guard hit advances rifle training, old Q/SHIFT actions are credited, the HUD panels never overlap and the gate sign changes on unlock. Then complete `tests/MS-08-BROWSER-QA.md` with a first-time run and record pacing, camera and guard observations. This document and the PR text received a humanizer editorial pass; test results and outstanding requirements were kept explicit.
