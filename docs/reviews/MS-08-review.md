# MS-08 review: Loading Dock opening

**Repository / range:** `mishraaditya595/swapshot`, `main` to `feat/ms-08-loading-dock`, [PR #17](https://github.com/mishraaditya595/swapshot/pull/17).  
**Scope:** P1 Loading Dock only, Godot 4.7.2 Compatibility.  
**Review mode:** Source, headless CI and three owner-submitted November 4 hosted gameplay recordings.  
**Decision:** GAMEPLAY VIDEO PASS for the observed victory route; milestone acceptance and merge remain on HOLD pending [issue #18](https://github.com/mishraaditya595/swapshot/issues/18) and MS-07.

## November 4 video findings and corrective changes

The owner recorded a hosted PR #17 run ending around 00:58 with three SHIFTS, both guards eliminated and 76/100 armor. This demonstrates a completable browser section, but one run does not establish typical pacing or onboarding clarity.

Two defects were visible in the recording. The tutorial remained on rifle step 02 even after the player had shot guards and used SHIFT, because only the orange practice target's `damaged` event advanced the rifle lesson. The top-left mission instructions also covered the SHIFT status and cooldown text.

The MS-08 follow-up connects both guards' `damaged` signals to the same onboarding handler as the practice target. Valid guard damage now counts as a rifle hit, and earlier anchor/SHIFT events remain recorded. The existing movement-area trigger still starts the tutorial. A new regression replays the video's order: SHIFT first, shoot a guard, enter the training area, and reach combat step 05 without repeatedly performing completed actions.

The director now moves its SHIFT status and timer into a bottom-left, dock-specific panel. The global SHIFT HUD scene stays unchanged for earlier missions. Godot tests check non-overlap with the tutorial, timer, objective and ammo at the default resolution and at 960×540. The practice target gains an amber frame and range sign; the exit sign, floor guide and light change from amber locked to cyan interactable when both guards fall.

The owner then recorded an 01:17 in-game clear in another hosted build of PR #17 (about 88 seconds of video), with two SHIFTS, full 100/100 armor, an unlocked cyan gate and successful victory replay. The new bottom-left HUD and tutorial progression are visible without the earlier overlap. The orange target frame and gate light are clearer. This run still showed a long search for a valid anchor, close-range camera crowding and a gate label that became hard to read at oblique angles.

The two runs, 00:58 and 01:17, remain short of the planned 2–3-minute target. Neither establishes first-time-player pacing. More guards and artificial delays would add scope before the existing encounter is tuned. The full-armor clear calls for a visibility and line-of-sight check, rather than an immediate damage increase.

### November 4 combat and readability follow-up

The Loading Dock scene now sets `detection_range = 20.0` on its two guards (the shared default is 12.5 m). Attack range, damage (8) and firing interval (1.7 seconds) are unchanged. A new Godot physics regression puts the player in an exposed lane beyond the old detection distance, advances the actual guard state machine through warning/fire and observes armor loss. It then inserts physical cover and verifies that the guard cannot see or damage the player through it. This proves a controlled case, not the difficulty of an unassisted hosted run.

For close-range encounters, the dock director fades Vex's existing Compatibility-renderer suit materials when a live guard comes near. The shared shoulder camera's extra-opacity input defaults to 1.0, leaving earlier levels unchanged. Camera position, collision handling, muzzle and aiming rays are untouched. Godot checks that nearby proximity reduces material alpha and moving away restores the default opacity.

Instruction 03 now says to aim down at clear floor within 18 m. The director gives actionable feedback for out-of-range and missing-floor placements, while the SHIFT safety implementation remains unchanged. The exit sign now faces down the lane on a fixed dark backdrop, avoiding a billboard turning into the gate. New tests verify the tutorial copy, rejected-anchor state, fixed sign geometry and close-proximity fade.

[Godot CI 41763686737](https://github.com/mishraaditya595/swapshot/actions/runs/41763686737) passed import/startup, MS-01–MS-08 smoke, static audit, six audit tests, 30 repository Python tests and milestone validation on the latest gameplay changes.

### Third hosted session and merge assessment

The owner reviewed a third Loading Dock run from the latest reported PR #17 build. The result screen shows **01:23, five SHIFTS, both guards defeated and 84/100 armor**. Guard warnings and armor loss are visible, along with close-range player fading, a working anchor/echo tutorial and the fixed Security Core sign. The owner reported that the session felt fine. The gameplay review found no new blocking issue on the recorded success path.

Across three recorded clears, the in-game times were **00:58, 01:17 and 01:23**. The footage supports a working two-guard encounter and confirms that the last combat/readability improvements are usable in a real browser. It does not measure the experience of a new player or establish the intended two-to-three-minute first run. The uploaded footage has no audio track; browser FPS, console output, pointer recapture, death/retry and invalid SHIFT landing behavior have not been independently established from this session.

The remaining checks are assigned to [issue #18](https://github.com/mishraaditya595/swapshot/issues/18), with their evidence requirements listed in [the browser worksheet](../../tests/MS-08-BROWSER-QA.md). [PR #16](https://github.com/mishraaditya595/swapshot/pull/16) has been merged, but **MS-07 remains unchecked** in the tracker and its review still records HOLD. The PR #17 milestone policy therefore still fails on both the unfinished MS-08 acceptance and the earlier milestone. Do not clear either gate based solely on this video.

## Findings

### Acceptance blocker: first-time comprehension and duration have not been measured

- **Evidence:** `scripts/ms08_loading_dock.gd` advances prompts through real route, target, anchor and SHIFT events; the new Godot smoke passes those transitions and the final gate. A headless scene cannot establish that players notice the prompts, use SHIFT tactically or finish in the intended two to three minutes.
- **Expected:** An unfamiliar player reaches the Security Core exit without outside guidance and understands SHIFT.
- **Next check:** Complete the first-time-player and failure-path checks in [issue #18](https://github.com/mishraaditya595/swapshot/issues/18) before checking the milestone.

### P2 follow-up: overhead camera visibility is unconfirmed

- **Evidence:** PR #16's video raised an overhead-geometry question. The Loading Dock uses open main lanes, four-metre perimeter walls and no low overhead physical beams. The only shared camera change is an optional player-material fade input used by Loading Dock; physical boom/collision and camera aim are unchanged.
- **Reproduction needed:** Approach walls and cargo at close range while rotating the camera, particularly near any upper trim. Record a browser clip if visibility fails.
- **Decision:** The dock-only fade addresses player-model obstruction near guards. Overhead geometry still requires manual reproduction; no boom collision tuning was made.

### P2 follow-up: point-blank guard engagement is unconfirmed

- **Evidence:** `scripts/security_trooper.gd` still checks eye and muzzle line of sight when acquiring and firing. Existing AI tests passed; no new browser evidence establishes a close-range defect.
- **Reproduction needed:** Stand near the front and sides of a live guard, wait for its warning, and record whether it engages. Include the distance and angle in any report.
- **Decision:** Preserve the established AI until a fault is reproduced.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static SWAPSHOT audit | PASS | [CI 41763686737](https://github.com/mishraaditya595/swapshot/actions/runs/41763686737) |
| Audit Python tests | PASS | Same run, 6 tests |
| Repository Python tests | PASS | Same run, 30 tests |
| Milestone tracker validator | PASS | Same run, MS-00 through MS-16 valid |
| Godot 4.7.2 import | PASS | Same run, official 4.7.2 stable executable |
| Godot startup | PASS | Same run, two headless frames, no reported engine errors |
| MS-01 to MS-07 Godot smoke | PASS | Same run, seven distinct `SMOKE PASS` reports |
| MS-08 Godot smoke | PASS | Same run: guard hits and early SHIFT, HUD at two sizes, new guard sightline and blocked-fire test, proximity fade, 18 m anchor feedback, fixed gate sign, win/death replay |
| Rule-based automated code review | PASS | [SWAPSHOT Pre-Merge](https://github.com/mishraaditya595/swapshot/actions/workflows/premerge.yml), limited to static risk checks |
| PR milestone acceptance policy | FAIL, expected | MS-07 prerequisite is unchecked and MS-08 still requires human acceptance; the existing policy has no override for an authorized work-order exception |
| Hosted browser playtest | THREE RUNS OBSERVED | Nov 4: 00:58/3 SHIFTS/76 armor; 01:17/2 SHIFTS/100 armor and victory replay; 01:23/5 SHIFTS/84 armor on latest reported build. Happy-path video review PASS |
| First-time onboarding, death/retry, SHIFT negative paths, FPS, audio and mouse capture | NOT FULLY TESTED | Follow [issue #18](https://github.com/mishraaditya595/swapshot/issues/18) with targeted manual evidence |

The successful gameplay CI above is for commit `256baf18a54938d7894b78da69cb69500c3cea1a`. Documentation corrections follow this commit; confirm the final PR head checks before any merge decision.

## Source review and scope acceptance

The new `loading_dock.tscn` instances the existing player, practice target, HUD and two troopers. Reusable cargo has physical box collisions. The new director counts eliminated guards once, keeps its gate locked until both die, rejects remote E interaction and freezes input on victory/death. It does not modify `shift_ability.gd`, `security_trooper.gd`, `vx7_rifle.gd` or `ms06_mission.gd`. The original MS-06 and MS-07 tests passed on the same new scene entry build.

The integration change to `tests/ms06_loop_smoke.gd` updates its startup assertion from MS-06 to Loading Dock while retaining the complete MS-06 encounter regression. No new reinforcement spawns exist in this dock section, and the MS-07 echo-safe entry protection remains unchanged.

| MS-08 requirement | Implemented | Automated verification | Human verification |
| --- | --- | --- | --- |
| Containers, crates, cover and flanking lanes | Yes | Scene load and cover ray pass | Route quality pending |
| Contextual movement, rifle, anchor and SHIFT prompts | Yes | Signal/physics transitions pass | Instruction clarity pending |
| Opening two-guard fight, 2–3 minute pacing | Two guards with widened dock-only detection | Visible-lane damage and blocked-cover regressions pass | Three owner clears, latest 01:23 with 5 SHIFTS; first-time pacing pending |
| Exit gate and next-zone message | Yes | Locked state, proximity, win and replay pass | Readability pending |
| Safe SHIFT and unaffected P0 gameplay | Existing implementation reused | MS-01 to MS-08 pass | Hosted browser safety pending |

## Decision and next action

Keep [PR #17](https://github.com/mishraaditya595/swapshot/pull/17) open and draft while its required milestone policy check fails. The recorded victory path is ready for human acceptance review; the unverified checks and the separate MS-07 prerequisite are tracked in [issue #18](https://github.com/mishraaditya595/swapshot/issues/18). Record first-time comprehension and death/retry before ticking MS-08. The policy remains active and must not be bypassed. This review and the PR description received a humanizer editorial pass; all unrun checks remain explicit.
