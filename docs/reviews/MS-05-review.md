# MS-05 security trooper review

**Repository:** mishraaditya595/swapshot
**Base:** `ade4ce3b97b381846c932b617aa7ddae4243058e`
**Branch / PR:** `feat/ms-05-security-trooper`, [#13](https://github.com/mishraaditya595/swapshot/pull/13)
**Scope:** P0, MS-05
**Decision:** INSUFFICIENT EVIDENCE for manual acceptance

## Source review

Inspected `security_trooper.gd`, its scene, the player damage receiver, combat HUD, the dedicated encounter, SHIFT signals, rifle collision masks and the regression test. The guard uses one cooldown, cancels its warning on obstruction, raycasts at discharge, and disconnects echo handlers on death/teardown. Its collision layer is 1 so the VX-7 hits it unchanged. Perception and shots include player layer 2; echoes use an occlusion-only world ray and never gain physics collision.

No P0/P1 defect was confirmed in the inspected code. The first CI run exposed an encounter problem: the guard acquired the player immediately at spawn. The detection radius is now 12.5 meters, requiring the player to approach. The test also checks range, field of view and the incoming-damage cue. The second CI run passed before this final tuning; fresh CI is required after the change.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit, audit unit tests, milestone validator and Python tests | PASS (second PR CI run) | SWAPSHOT CI run 41631148088, static job success; 30 repository Python tests |
| Godot 4.7.2 import | PASS (second PR CI run) | Same run, import completed without engine errors |
| Existing MS-01 through MS-04 physics tests | PASS (first PR CI run) | Four explicit `SMOKE PASS` lines in Godot job logs |
| MS-05 physics test | FAIL initially, then corrected assertion; rerun pending | First run: `MS-05 FAIL: Guard starts IDLE`; later assertions completed without further reported failures |
| Human Web playtest | NOT RUN | No owner browser report yet |
| Hosted browser performance and input | NOT RUN | Requires owner-triggered PR preview |
| PR milestone acceptance | FAIL by design while unfinished | Nested tasks/manual acceptance remain open; see Pre-Merge run 41631148034 |

## Scope acceptance

| Requirement | Implemented? | Verified? |
| --- | --- | --- |
| Modular, damageable trooper | Yes | Headless smoke passed; visual browser QA pending |
| Idle, alert, attack, dead | Yes | MS-05 smoke passed in second CI run |
| Wall-protected, timed shots with real damage | Yes | MS-05 smoke passed in second CI run |
| SHIFT echo distraction and cleanup | Yes | MS-05 smoke passed in second CI run |
| One firefight preview | Yes | Human feel/visibility NOT RUN |
| MS-06 full health/death/retry | Deferred by scope | NOT RUN |

## Owner Web playtest procedure

Run `deploy-web-manual.yml` with source `pr` and PR `13`. Record the tested commit SHA, browser, operating system and date. In the deployed game, approach the Helix trooper and look for the amber alert lamp. Wait for its muzzle warning and observe the hit cue. Hide behind a crate, confirm no hits cross the crate, then reappear and shoot until the guard falls. Deploy an anchor with Q, SHIFT with Left Shift, and watch the guard turn toward the hologram; confirm it reacquires the player when the echo disappears. Finally, check camera movement, ADS, reload, SHIFT placement, pointer lock, sound and frame pacing. Report actual outcomes under the PR acceptance section.

## Remaining risks

- MS-05 has no player restart/game-over implementation. Dying requires restarting the current scene outside the gameplay UI; MS-06 owns that loop.
- The guard does not move around cover. The player must approach or reposition with SHIFT.
- Browser readability, actual combat feel and performance are unverified. Do not merge until the owner accepts these behaviors.
