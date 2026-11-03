# MS-06 review: two-wave P0 encounter

**Repository:** `mishraaditya595/swapshot`, `main` to [draft PR #14](https://github.com/mishraaditya595/swapshot/pull/14).
**Scope:** P0 gameplay loop in Godot 4.7.2 / Compatibility renderer.
**Decision:** PASS WITH ISSUES for MS-06 P0, accepted for merge by the owner on November 3, 2026. Remaining browser edge-case tests and Wave 2 armor tuning are follow-up work.

## Browser evidence and why the encounter changed

The owner's 97.6-second Brave/macOS recording from November 3 shows the original three-guard PR #14 preview. A partly recorded attempt ended in defeat at mission time 01:09 (1/3 eliminations, one SHIFT). The next attempt restarted at 100 HP and won at 00:50 (3/3 eliminations, three SHIFTS, 84/100 HP). The objective, health, shooting, SHIFT feedback and both result screens are visible. The clip does not show replay from victory, unsafe SHIFT tests, FPS or audio. Its source SHA is not visible.

After reviewing this, the owner approved a longer firefight and readability improvements. The follow-up uses two three-guard waves in the existing arena. The first three deaths start a four-second reinforcement warning; three tougher troopers then enter from safe, separated positions. The HUD tracks 0/6 kills and the active wave. Health, ammo, SHIFT, objective and result typography are larger. This revision requires a new hosted build and playtest; the recorded 50-second win is only a baseline.

## Owner acceptance and revised browser evidence (November 3, 2026)

The owner shared a second screen recording titled `Screen Recording 2026-11-03 at 8.47.32 PM.mov` of the revised six-guard hosted PR preview. The recording lasts about 136.75 seconds and begins after the mission timer has started. The first patrol is cleared at 3/6, a reinforcement countdown is shown, Wave 2 activates, and the player wins at mission time **02:25** with **6/6 guards neutralized**, **6 SHIFTS** and **4/100 armor** remaining. The previous recording documented defeat and successful retry on the earlier three-guard build.

Following this review, the owner explicitly approved merging MS-06 and asked to leave armor recovery/balance changes for future versions. The armor concern is tracked separately in [issue #15](https://github.com/mishraaditya595/swapshot/issues/15). No armor mechanic was added in this PR.

The new clip does not show a replay action after victory, invalid SHIFT target attempts, measured FPS or audio. The recorded browser session also does not expose the exact deployed source SHA. Godot 4.7.2 smoke tests do exercise scene reload after victory/death, unsafe SHIFT rejection and the reinforcement spawn checks. These coverage limits remain documented; the owner accepted them for this P0 milestone.

## Findings

### P2 — Two-wave survivability may need later tuning

- **Evidence:** `scripts/ms06_mission.gd` activates three reserve guards after the patrol is defeated. `scenes/levels/ms06_firefight.tscn` gives the response team 120 HP and 9 damage per shot. No new enemy archetype or movement pathfinding was added.
- **Expected:** A focused, enjoyable firefight averaging around 90–135 seconds, with room for more than one useful SHIFT.
- **Observed:** The earlier three-guard victory took 00:50. In the six-guard browser capture, the player wins at 02:25 with 6 SHIFTS and 4 armor remaining.
- **Impact:** The desired longer firefight is demonstrated once, with low remaining armor. One success cannot establish typical difficulty or justify a new health mechanic for P0.
- **Next check:** Future versions may compare several playthroughs and evaluate small armor recovery or a modest response-damage adjustment. Tracked in [issue #15](https://github.com/mishraaditya595/swapshot/issues/15).
- **Confidence:** A successful 02:25 browser run is observed; repeatability and average difficulty remain unmeasured.

### P1 — Browser-only edge cases remain open

- **Evidence:** The expanded `tests/ms06_loop_smoke.gd` passes countdown, paused state, blocked primary spawn, full mission victory, death during the response warning, active echo cleanup, Enter/button retry and scene teardown. The established MS-03/04/05 tests also pass.
- **Expected:** No trooper spawns inside the player, cover or an armed anchor. Victory waits for all six guards; death cannot spawn late enemies; fresh runs reset the entire state.
- **Observed:** The revised browser video shows the response warning, second-wave encounter and victory after 6/6 guards. Browser replay after victory and invalid-target tests remain unrecorded.
- **Next check:** Retain victory replay, focus recovery and blocked SHIFT placement in later browser regression sessions. These pass existing headless tests where covered.
- **Confidence:** Headless checks observed, browser behavior needs verification.

### P2 — HUD scale requires a display check

- **Evidence:** In the old 2940 × 1912 capture, objective, SHIFT, ammo and status labels look small. Scene font sizes and offsets were increased in the follow-up.
- **Expected:** Status remains readable while aiming, at the native laptop display resolution and a smaller browser window.
- **Observed:** The new 2940 × 1912 browser recording shows enlarged objective/status text and the reinforcement banner without obvious panel overlap. Some information remains small at native display resolution.
- **Next check:** Revisit HUD scaling and camera composition in the later presentation/accessibility milestones.
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
| Revised six-guard hosted Web gameplay and duration | PASS (recorded, one run) | Owner video: 02:25, 6/6 guards, six SHIFTS, four HP |
| Post-victory replay, focus changes, FPS and audio | NOT RUN | Not demonstrated for this revision |

## Scope acceptance

| MS-06 requirement | Implementation | Verification limit |
| --- | --- | --- |
| 100 HP, rifle and readable HUD | Implemented | Automated tests pass; revised font scale not yet viewed in browser |
| SHIFT range/anchor/echo/cooldown | Preserved | Earlier regressions pass; browser invalid-target tests outstanding |
| Six-guard objective with second-wave warning | Implemented | Automated transition tests pass; gameplay feel unmeasured |
| Defeat, victory and replay without stale state | Implemented | Automated tests pass; post-victory Web replay outstanding |
| Two-minute firefight acceptance | ACCEPTED (owner) | Recorded 02:25 victory; one revised run, plus prior browser retry and Godot smoke |

## Risks and next action

The response wave keeps the existing trooper AI and caps active opponents at three. It uses capsule clearance and floor support queries to select from eight fixed entry sites. If the available entries are obstructed, it retries rather than spawning into an obstacle. The headless test confirms a safe alternative when the player occupies the primary western entry. One revised hosted session demonstrates the response wave and completed objective. The owner accepted remaining unrecorded edge cases for this P0 merge, with targeted regression checks retained for future versions.

The owner has reviewed the six-guard gameplay and authorized the merge. The acceptance decision covers P0 and does not certify FPS, audio, post-victory browser replay or average encounter difficulty. Preserve those checks for later regression and track any armor changes in issue #15.

**Editorial pass:** This review and the companion QA instructions were edited for concise technical prose following the repository humanizer skill. Claims about automated checks and manual gameplay remain separate.
