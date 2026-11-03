# MS-06 review: two-wave P0 encounter

**Repository:** `mishraaditya595/swapshot`, `main` to [draft PR #14](https://github.com/mishraaditya595/swapshot/pull/14).
**Scope:** P0 gameplay loop in Godot 4.7.2 / Compatibility renderer.
**Decision:** PASS WITH ISSUES for automated mechanics; INSUFFICIENT EVIDENCE for revised browser acceptance.

## Browser evidence and why the encounter changed

The owner's 97.6-second Brave/macOS recording from November 3 shows the original three-guard PR #14 preview. A partly recorded attempt ended in defeat at mission time 01:09 (1/3 eliminations, one SHIFT). The next attempt restarted at 100 HP and won at 00:50 (3/3 eliminations, three SHIFTS, 84/100 HP). The objective, health, shooting, SHIFT feedback and both result screens are visible. The clip does not show replay from victory, unsafe SHIFT tests, FPS or audio. Its source SHA is not visible.

After reviewing this, the owner approved a longer firefight and readability improvements. The follow-up uses two three-guard waves in the existing arena. The first three deaths start a four-second reinforcement warning; three tougher troopers then enter from safe, separated positions. The HUD tracks 0/6 kills and the active wave. Health, ammo, SHIFT, objective and result typography are larger. This revision requires a new hosted build and playtest; the recorded 50-second win is only a baseline.

## Findings

### P1 — Revised duration and pacing still need observation

- **Evidence:** `scripts/ms06_mission.gd` activates three reserve guards after the patrol is defeated. `scenes/levels/ms06_firefight.tscn` gives the response team 120 HP and 9 damage per shot. No new enemy archetype or movement pathfinding was added.
- **Expected:** A focused, enjoyable firefight averaging around 90–135 seconds, with room for more than one useful SHIFT.
- **Observed:** The previous three-guard win was 50 seconds. The revised six-guard session has not been recorded.
- **Impact:** The feature may still be too short, or the extra guards may make a first attempt unfair. Static AI still limits pressure on a player who stays behind solid cover.
- **Next check:** Record a complete six-guard winning run, its health/time/SHIFT stats, and any unfair spawn or sightline. Tune within this milestone before approval.
- **Confidence:** Code-inferred risk; actual pacing needs verification.

### P1 — Browser-only edge cases remain open

- **Evidence:** The expanded `tests/ms06_loop_smoke.gd` passes countdown, paused state, blocked primary spawn, full mission victory, death during the response warning, active echo cleanup, Enter/button retry and scene teardown. The established MS-03/04/05 tests also pass.
- **Expected:** No trooper spawns inside the player, cover or an armed anchor. Victory waits for all six guards; death cannot spawn late enemies; fresh runs reset the entire state.
- **Observed:** Godot headless simulation covers these states. A browser session has not exercised the new response team or replay after victory.
- **Next check:** Try a SHIFT anchor near the response entry, die during the countdown, and click replay from the victory screen in the hosted build.
- **Confidence:** Headless checks observed, browser behavior needs verification.

### P2 — HUD scale requires a display check

- **Evidence:** In the old 2940 × 1912 capture, objective, SHIFT, ammo and status labels look small. Scene font sizes and offsets were increased in the follow-up.
- **Expected:** Status remains readable while aiming, at the native laptop display resolution and a smaller browser window.
- **Observed:** Larger text is present in resource scenes and asserted in the MS-06 smoke test. No screenshot of the revised layout exists yet.
- **Next check:** Inspect top-of-screen label overlap, SHIFT countdown, incoming warning, and replay button on the next hosted build.
- **Confidence:** Source changes verified; real readability needs feedback.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Source audit, Python tests, tracker validator | PASS | [CI run 41656292272](https://github.com/mishraaditya595/swapshot/actions/runs/41656292272), static job |
| Godot 4.7.2 import and startup | PASS | Same CI run, Godot job |
| MS-01–MS-05 regression suites | PASS | Same CI run; all five `SMOKE PASS` |
| MS-06 two-wave, spawn safety, pause, death and replay | PASS | Same CI run; `MS-06 SMOKE PASS` |
| Rule-based automated code review | PASS | [Pre-merge run 41656292716](https://github.com/mishraaditya595/swapshot/actions/runs/41656292716); static risk scan only |
| Milestone acceptance policy | FAIL (expected) | Owner approval and manual tasks remain unchecked |
| Original three-guard hosted browser gameplay | PASS (recorded) | Owner's 01:09 defeat and 00:50 victory |
| Revised six-guard hosted Web gameplay and duration | NOT RUN | Requires a fresh owner-triggered Web deployment |
| Post-victory replay, focus changes, FPS and audio | NOT RUN | Not demonstrated for this revision |

## Scope acceptance

| MS-06 requirement | Implementation | Verification limit |
| --- | --- | --- |
| 100 HP, rifle and readable HUD | Implemented | Automated tests pass; revised font scale not yet viewed in browser |
| SHIFT range/anchor/echo/cooldown | Preserved | Earlier regressions pass; browser invalid-target tests outstanding |
| Six-guard objective with second-wave warning | Implemented | Automated transition tests pass; gameplay feel unmeasured |
| Defeat, victory and replay without stale state | Implemented | Automated tests pass; post-victory Web replay outstanding |
| Reproducible two-minute firefight | Pending | Original victory was 50 seconds; revised duration unknown |

## Risks and next action

The response wave keeps the existing trooper AI and caps active opponents at three. It uses capsule clearance and floor support queries to select from eight fixed entry sites. If the available entries are obstructed, it retries rather than spawning into an obstacle. The headless test confirms a safe alternative when the player occupies the primary western entry. A human session is still needed for practical spawn visibility, balance and feel.

Run the manual workflow for PR #14 and follow `tests/MS-06-BROWSER-QA.md`. Record the exact deployed SHA and confirm the two-wave completion and victory replay before checking the milestone. Keep PR #14 open and unmerged until the owner accepts it.

**Editorial pass:** This review and the companion QA instructions were edited for concise technical prose following the repository humanizer skill. Claims about automated checks and manual gameplay remain separate.
