# MS-08 implementation plan: Loading Dock

**Base:** `main` after merged PR #16. **Branch:** `feat/ms-08-loading-dock`. **Implementing PR:** [#17](https://github.com/mishraaditya595/swapshot/pull/17).

The owner explicitly approved starting MS-08 while MS-07 remains unchecked/HOLD. This changes the work order for MS-08, without accepting the pending MS-07 human playtest.

## Implementation

1. Build `loading_dock.tscn` with a broad, level floor, perimeter walls, cargo lanes and visible north gate. Instance a small container/crate kit with matched box collisions. Avoid new overhead collision obstacles.
2. Instance the existing player, rifle, SHIFT and HUD. Add one practice target and a route `Area3D`. Advance tutorial instructions from route entry, target damage, successful anchor placement and successful SHIFT. Remember early actions.
3. Instance two existing Helix troopers on opposite sides of the central crate lane. Track each destroyed guard once. Keep the objective count visible while the tutorial progresses.
4. Keep the gate locked until both troopers die. Change its light and prompt on unlock. Permit E interaction only when the player is alive, both guards are defeated and the player is close to the exit marker.
5. Show a terminal result overlay with time, guard count, SHIFT count and replay. Reload the entire scene on replay. Death follows the same clean scene lifecycle.
6. Set `scenes/main.tscn` to Loading Dock. Preserve the original MS-06 scene and its code; update only its smoke test's startup assertion to reflect the new default scene.
7. Add `tests/ms08_loading_dock_smoke.gd`, then run MS-01 through MS-08, Godot import/startup, the static audit, Python suites and milestone validator. Wire the new smoke to GitHub Actions. A CI pass does not establish that the onboarding is understandable or the camera feels right.
8. Review the changed gameplay using `swapshot-review`. Record findings, manual gaps and the specific browser playtest in the PR. Apply the humanizer checklist to reader-facing prose.
9. Link the real draft PR in `docs/MILESTONES.md`. Only tick sub-tasks that have implementation and verification evidence. Leave the full milestone unchecked pending the hosted first-time playtest.

## Regression expectations

MS-03 SHIFT placement and activation must still reject occupied landings without moving the player or charging cooldown. MS-04 echo and cooldown must still expire safely. MS-05 guards must not fire through cover or after death. MS-06 two-wave activation must keep its original safe player/anchor/echo exclusions. MS-07 blocked reinforcement sites must still defer activation and recover once clear. Replays must never retain old enemies, signals, anchors or echo targets.

For the new scene, test the tutorial transition sequence, early gate rejection, a blocked then valid SHIFT, guard count and gate unlock, proximity validation, section completion without MS-09 and both victory/death replay.

## Manual checks

Follow `tests/MS-08-BROWSER-QA.md` on the hosted PR build. Record a first attempt before showing the controls worksheet. Test the two PR #16 observations (overhead camera and close-range guard behavior) as candidate reproductions, and report what actually happened. Never mark the milestone complete without that new-player feedback.

## November 4 recorded-playtest follow-up

The owner's hosted PR #17 recording showed a successful 58-second clear with three SHIFTS and 76 armor. Two interface bugs require correction before acceptance: rifle onboarding ignored guard hits, and the global SHIFT status overlapped the Loading Dock mission labels. The follow-up accepts damage from either training dummy or living guard, preserves early Q/SHIFT actions, and moves the SHIFT status to a dock-only lower-left panel without modifying the global HUD resource. The target receives a brighter amber frame and range label, and the gate adds a locked/unlocked sign and matching floor cue.

Godot regression checks cover the filmed action order, invalid zero-damage hits, panel bounds at desktop and 960×540, color/label state changes, and all existing MS-01–MS-07 regressions. Treat the prior 58-second clear as one observed run, not a reason to add enemy health or artificial delays yet. The owner must redeploy and retest the revised build before the milestone can close. The P2 close-range camera observation remains open pending reproduction.

## November 4 combat/readability correction

A second owner recording shows a 01:17 Loading Dock clear with two SHIFTS, 100/100 armor, an unlocked gate and victory replay. The earlier tutorial/HUD defects were visibly improved. The review still found low enemy pressure, close-range camera crowding, confusing 18 m anchor placement, and oblique-angle gate lettering.

Keep this a scene-focused correction. Raise only Loading Dock guards' detection radius from 12.5 m to 20 m; retain the shared guard script, cover line-of-sight, 8-point shot damage and 1.7 s firing interval. Supply the shared shoulder camera with an optional external suit-fade cap (default 1.0) that Loading Dock can reduce when a living guard is within 4 m. Leave camera aim and boom geometry untouched. Update the anchor prompt and its existing rejection feedback, and use a fixed two-line sign on a dark panel in front of the gate.

Regression coverage: actual warned enemy damage from an exposed approach past 12.5 m, blocked sight and fire through cover, alpha fade when a guard is near and restoration when distant, explicit out-of-range and missing-floor messages, fixed gate label, existing SHIFT collision tests and replay. CI run [41763440936](https://github.com/mishraaditya595/swapshot/actions/runs/41763440936) passed on the gameplay/test changes. The revised browser build has not been tested; leave MS-08 and MS-07 unchecked and keep PR #17 in draft pending a new hosted session.
