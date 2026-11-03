# MS-05 security trooper review

**Repository:** mishraaditya595/swapshot
**Base:** `ade4ce3b97b381846c932b617aa7ddae4243058e`
**Branch / PR:** `feat/ms-05-security-trooper`, [#13](https://github.com/mishraaditya595/swapshot/pull/13)
**Scope:** P0, MS-05
**CI environment:** GitHub Actions Ubuntu runner, Godot 4.7.2 stable, Python 3.12
**Verified gameplay commit:** `b1f17a839cdf1250a6c451ba8abc5e69a566258a`
**Decision:** INSUFFICIENT EVIDENCE for manual acceptance

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
| Human Web playtest | NOT RUN | No owner browser report yet |
| Hosted browser performance and input | NOT RUN | Requires owner-triggered PR preview |
| PR milestone acceptance | FAIL by design while unfinished | Final preview/playtest required; see [Pre-Merge run 41631866787](https://github.com/mishraaditya595/swapshot/actions/runs/41631866787) |

## Scope acceptance

| Requirement | Implemented? | Verified? |
| --- | --- | --- |
| Modular, damageable trooper | Yes | Headless smoke passed; silhouette still needs visual browser QA |
| Idle, alert, attack, dead | Yes | MS-05 smoke passed in latest CI run |
| Wall-protected, timed shots with real damage | Yes | MS-05 smoke passed in final gameplay CI run |
| SHIFT echo distraction and cleanup | Yes | MS-05 smoke passed in second CI run |
| One firefight preview | Yes | Human feel/visibility NOT RUN |
| MS-06 full health/death/retry | Deferred by scope | NOT RUN |

## Owner Web playtest procedure

Run `deploy-web-manual.yml` with source `pr` and PR `13`. Record the tested commit SHA, browser, operating system and date. In the deployed game, approach the Helix trooper and look for the amber alert lamp. Wait for its muzzle warning and observe the hit cue. Hide behind a crate, confirm no hits cross the crate, then reappear and shoot until the guard falls. Deploy an anchor with Q, SHIFT with Left Shift, and watch the guard turn toward the hologram; confirm it reacquires the player when the echo disappears. Finally, check camera movement, ADS, reload, SHIFT placement, pointer lock, sound and frame pacing. Report actual outcomes under the PR acceptance section.

## Remaining risks

- MS-05 has no player restart/game-over implementation. Dying requires restarting the current scene outside the gameplay UI; MS-06 owns that loop.
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
