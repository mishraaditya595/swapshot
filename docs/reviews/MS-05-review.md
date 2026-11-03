# MS-05 security trooper review

**Repository:** mishraaditya595/swapshot
**Base:** `ade4ce3b97b381846c932b617aa7ddae4243058e`
**Branch / PR:** `feat/ms-05-security-trooper`, [#13](https://github.com/mishraaditya595/swapshot/pull/13)
**Scope:** P0, MS-05
**CI environment:** GitHub Actions Ubuntu runner, Godot 4.7.2 stable, Python 3.12
**Verified gameplay commit:** `b7e93485692dcc354143873685f932c437dd9cad`
**Decision:** LATEST CHANGES VERIFIED IN CI; FINAL BROWSER REVIEW STILL PENDING

## Source review

Inspected `security_trooper.gd`, its scene, the player damage receiver, combat HUD, the dedicated encounter, SHIFT signals, rifle collision masks and the regression test. The guard uses one cooldown, cancels its warning on obstruction, raycasts at discharge, and disconnects echo handlers on death/teardown. Its collision layer is 1 so the VX-7 hits it unchanged. Perception and shots include player layer 2; echoes use an occlusion-only world ray and never gain physics collision.

Source review identified one P1 input edge case: the initial health guard returned before handling Escape, leaving a risk of captured mouse input after player death. The controller now releases mouse capture on death and preserves Escape handling, and the rifle rejects further shots from dead players. Native pointer lock remains a manual browser check. The first CI run exposed an encounter problem: the guard acquired the player immediately at spawn. The detection radius is now 12.5 meters, requiring the player to approach. The test also checks range, field of view and the incoming-damage cue. The final gameplay CI run 41631866801 passed with the tuned detection, added smoke assertions, and the player-death input fix. Browser pointer lock still needs human verification.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit, audit unit tests, milestone validator and Python tests | PASS | SWAPSHOT CI [41631866801](https://github.com/mishraaditya595/swapshot/actions/runs/41631866801), static job success; 30 repository Python tests |
| Godot 4.7.2 import | PASS | Same run, import completed without engine errors |
| Existing MS-01 through MS-04 physics tests | PASS | Four explicit `SMOKE PASS` lines in Godot job logs |
| MS-05 physics test | PASS | Final run printed `MS-05 SMOKE PASS: states, LOS, cover, cadence, damage, rifle, SHIFT, death and cleanup` |
| Human Web playtest | PARTIAL | Two owner clips on Nov 3, approximately 16.9 and 49 seconds. The second shows cover protection, cyan echo distraction/reacquisition, armor damage and a collapse. Neither clip establishes its deployed SHA. Latest camera/search/UI changes need another browser pass. |
| Hosted browser performance and input | PARTIAL | Second clip shows mouse-controlled movement, combat, cover and SHIFT. Audio, engine FPS/frame pacing, full death/restart attempt and browser console are not verified. |
| PR milestone acceptance | FAIL by design while unfinished | Final preview/playtest required; see [Pre-Merge run 41631866787](https://github.com/mishraaditya595/swapshot/actions/runs/41631866787) |

## Scope acceptance

| Requirement | Implemented? | Verified? |
| --- | --- | --- |
| Modular, damageable trooper | Yes | Headless smoke passed; silhouette still needs visual browser QA |
| Idle, alert, attack, dead | Yes | MS-05 smoke passed in latest CI run |
| Wall-protected, timed shots with real damage | Yes | MS-05 smoke passed in final gameplay CI run |
| SHIFT echo distraction and cleanup | Yes | MS-05 smoke passed in second CI run |
| One firefight preview | Yes | Two browser clips reviewed; cover, SHIFT and enemy defeat observed, but latest camera/search/presentation changes require playback verification |
| MS-06 full health/death/retry | Deferred by scope | NOT RUN |

## Owner Web playtest procedure

Run `deploy-web-manual.yml` with source `pr` and PR `13`. Record the tested commit SHA, browser, operating system and date. In the deployed game, approach the Helix trooper and look for the amber alert lamp. Wait for its muzzle warning and observe the hit cue. Hide behind a crate, confirm no hits cross the crate, then reappear and shoot until the guard falls. Deploy an anchor with Q, SHIFT with Left Shift, and watch the guard turn toward the hologram; confirm it reacquires the player when the echo disappears. Finally, check camera movement, ADS, reload, SHIFT placement, pointer lock, sound and frame pacing. Report actual outcomes under the PR acceptance section.

## Remaining risks

- MS-05 has a simple Enter-to-restart fallback after death; the full game-over screen, victory flow and checkpoints remain MS-06. The fallback has not been exercised in the supplied browser recordings.
- The guard does not move around cover. The player must approach or reposition with SHIFT.
- Browser readability, actual combat feel and performance are unverified. Do not merge until the owner accepts these behaviors.

## Exact automated checks

Executed by SWAPSHOT CI on the gameplay commit (run 41631866801), with successful job exit status:

- `python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .`
- `python3 -m unittest discover -s .agents/skills/swapshot-review/tests -v`
- `python3 scripts/validate_milestones.py docs/MILESTONES.md`
- `python3 -m unittest discover -s tests -v` (30 Python tests in the runner's combined Python output)
- `godot --headless --path . --import`
- `godot --headless --path . --script res://tests/ms01_scene_smoke.gd`
- `godot --headless --path . --script res://tests/ms02_rifle_smoke.gd`
- `godot --headless --path . --script res://tests/ms03_shift_smoke.gd`
- `godot --headless --path . --script res://tests/ms04_shift_lifecycle_smoke.gd`
- `godot --headless --path . --script res://tests/ms05_enemy_smoke.gd`
- `godot --headless --path . --quit-after 2`

These ran in CI using the pinned Godot executable path. The manual PR Web preview workflow and hands-on browser playtest remain NOT RUN.

## Resolved source-review finding

**P1, code-inferred: Escape blocked after player death.** In the first MS-05 health change, `scripts/player_controller.gd::_unhandled_input` returned immediately for a dead player, before handling `release_mouse`. The fix releases captured mouse input on death and checks Escape before the dead-player input guard. `scripts/vx7_rifle.gd::fire_once` also rejects firing by a dead player. The MS-05 smoke test now asserts lethal damage disables SHIFT and rifle fire. Browser pointer-lock handling is still NOT RUN and requires the owner's preview test.


## November 3 recording follow-up — MS-05 polish

The owner uploaded a **16.9-second Brave/macOS gameplay recording** from PR #13. It demonstrates browser startup, movement, a trooper hit for 12 armor damage, SHIFT teleportation, VX-7 shots, and an enemy defeat. This was a review of an **earlier PR build**; there is no proven deployed SHA for the recording. The clip cannot establish cover integrity, echo retargeting/reacquisition, audio quality (no audio track) or actual Godot frame timing.

Changes implemented in response, covered by headless regressions:

- **Combat readability:** stronger amber alert lamp, pulsing weapon warning, generated lock/shot tones and a combat-state HUD line for searching, engagement, imminent shot, cooldown, neutralization and echo distraction.
- **Echo clarity:** higher-opacity cyan hologram with head beacon and floor disc; guard displays a cyan distraction beacon; HUD signals echo release and player reacquisition. SHIFT status changes from "Echo active" as soon as the echo ends, without waiting for cooldown.
- **Death presentation:** trooper stops attacking, disables collision and eases the mesh sideways *and downward* toward the ground instead of floating around its pivot.
- **Arena/character:** improved ambient and fill lights in MS-05; leg/shoulder geometry on the trooper and arms on Vex. Only the MS-05 foreground body/visor scale is reduced; shared camera and rifle aim geometry remains unchanged after CI exposed a regression.
- **Combat HUD and recovery:** larger warning/impact text, damage overlay, persistent armor counter, and an Enter-to-restart fallback on death. Full victory/death/retry presentation remains MS-06.
- **Cover regression:** the MS-05 test now starts another enemy wind-up, introduces a real physics barrier *during* the warning, and verifies the warning cancels and damage is blocked. It also checks echo visual/status cleanup and the settling corpse. MS-04 now checks echo-expiry text.

**Code verification:** [SWAPSHOT CI #41638178355](https://github.com/mishraaditya595/swapshot/actions/runs/41638178355) succeeded on gameplay commit 516e565d5477e7db7ba7d5daacbf7bf59ab7ec58 (static checks, Godot import and all five physics smoke tests). Two intermediate failures were corrected: a global camera-framing change broke MS-02 rifle sightlines, and an MS-05-only wider camera still missed a target in the rifle smoke test. Both geometry changes were removed. Headless tests cannot measure browser feel, sound playback or FPS.

### Required browser replay on this revised build

Deploy PR #13 again and record the **actual deployed SHA**:

1. Approach while exposed; verify amber warning, lock sound, muzzle flash, an actual shot and a readable armor decrement.
2. Once the guard starts a new warning, move behind a crate and stay there for multiple firing cycles; verify no armor is lost until you peek.
3. Place Q on clear floor, SHIFT laterally while leaving the trooper alive, and look back at the cyan echo and guard beacon. Observe "DISTRACTED BY ECHO", no attacks during the 1.5-second echo, and "REACQUIRING PLAYER" followed by attack once visible.
4. Confirm SHIFT status stops reporting an active echo after 1.5 seconds, even during cooldown.
5. Eliminate the guard: its body should settle to the floor and it must never fire again.
6. Allow defeat in a separate attempt: check persistent armor, damage overlay, cursor release and Enter retry. Exercise ADS/reload, camera clipping near crates, audio, FPS and pacing.

**Acceptance remains pending.** Keep PR #13 in draft and MS-05 incomplete until a human tests the revised deployed SHA. Automated cover/echo checks are not a substitute for browser acceptance.

## Second browser clip and follow-up fixes, November 3

The owner supplied a second PR #13 Brave/macOS clip, approximately 49 seconds long. It shows amber shot warnings and armor damage in 12-point steps, several seconds of protection behind cover, two SHIFT echo distractions with reacquisition messages, and the trooper collapsing. The video does not identify the deployed commit SHA or provide usable audio/FPS measurements.

The clip also exposed a partially transparent player model blocking the camera near cover at about 19 seconds, rapid loss of enemy alertness, a dark upper wall and an unchanged mission label after the guard was defeated.

The new PR changes address each issue:

- Camera: scripts/shoulder_camera.gd begins fading at 2.85 m and makes the suit and weapon fully transparent by 2.1 m. The boom, muzzle and crosshair rays remain fixed. The MS-05 smoke test checks near-cover body, arm and rifle opacity and recovery in open space.
- Enemy: scripts/security_trooper.gd gains a SEARCH state after the existing four state IDs. A trooper that loses sight watches its last visible target point for 2.6 seconds without firing or following a hidden player through cover, then returns to idle if no sightline returns. The test moves the player behind a solid barrier and verifies the stored point, attack cancellation and reacquisition.
- Arena: scenes/levels/ms05_firefight.tscn adds ambient/fill lighting and non-colliding wall ribs and light strips. No physics cover or SHIFT landing geometry changes.
- Interface: scripts/combat_hud.gd and scenes/ui/combat_hud.tscn add contrast panels and clearer danger/cyan state colors. scripts/ms05_presentation.gd changes the objective to MISSION COMPLETE when the lone trooper is eliminated. Full victory/retry flow remains MS-06.

**Automated evidence:** [SWAPSHOT CI #41640766303](https://github.com/mishraaditya595/swapshot/actions/runs/41640766303) succeeded on gameplay commit b7e93485692dcc354143873685f932c437dd9cad. Static checks and the Godot 4.7.2 import job passed; all five gameplay smoke suites printed SMOKE PASS. [Automated code review](https://github.com/mishraaditya595/swapshot/actions/runs/41640766327) succeeded. The separate milestone acceptance check remains incomplete pending owner review.

**Latest browser replay:** Deploy PR #13 from the new head and record its SHA. Move beside and behind a crate to check that no partially transparent suit remains in front of the reticle, and that the character returns to view in open space. Let the trooper detect you, break sight behind cover, watch SEARCHING LAST SEEN for several seconds, and peek to provoke reacquisition. Eliminate the guard and check the completed mission banner. Test wall brightness, audio, frame pacing, and, in a separate attempt, death followed by Enter-to-restart. Keep this PR unmerged until the owner accepts the new build.
