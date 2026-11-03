# MS-06 review: P0 encounter loop

**Repository / base..head:** `mishraaditya595/swapshot`, `main` to [draft PR #14](https://github.com/mishraaditya595/swapshot/pull/14). Initial CI-tested code revision: `34dd541bb84138963c66666143d97831cdffca77`.

**Scope:** MS-06, P0. **Engine:** Godot 4.7.2 stable in GitHub Actions, GL Compatibility renderer. **Decision:** INSUFFICIENT EVIDENCE for final gameplay acceptance; source and engine smoke have passed.

## Findings

### P1 — Encounter duration and browser feel require measurement

- **Evidence:** `scenes/levels/ms06_firefight.tscn` adds three fixed-position troopers. `scripts/ms06_mission.gd` shows elapsed time but intentionally has no time limit.
- **Reproduction:** Manually publish PR #14 using the approved Pages workflow, then play to victory and replay on the target laptop browser.
- **Expected:** A readable, satisfying firefight that typically takes around two minutes and rewards SHIFT flanking.
- **Observed:** No measured human playthrough or browser performance data exists for this revision.
- **Impact:** Pacing and difficulty cannot be accepted from headless tests; the encounter might need tuning.
- **Next check:** Record elapsed time, damage taken, SHIFT usage, browser/OS and any progression issue. Change only tuning values after that evidence.
- **Confidence:** Needs verification.

### P1 — Manual end-to-end acceptance remains open

- **Evidence:** [CI run 41645861386](https://github.com/mishraaditya595/swapshot/actions/runs/41645861386) passed scripted MS-01–MS-06 checks. [Pre-merge run 41645861398](https://github.com/mishraaditya595/swapshot/actions/runs/41645861398) intentionally failed milestone acceptance while the tracker was incomplete.
- **Reproduction:** Try normal keyboard/mouse input, enemy fire and cover, safe/unsafe SHIFT targets, victory after the third kill, death/retry, and victory/replay in the actual deployed Web build.
- **Expected:** No blocked retry button, stuck pointer, stale echo/cooldown, misplaced bullets, or unresponsive player after replay.
- **Observed:** These journeys passed programmatic state checks where covered, but no human browser session has been performed for MS-06.
- **Impact:** The PR is not merge-ready.
- **Next check:** Owner-run manual preview followed by explicit acceptance.
- **Confidence:** Needs verification.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static project audit | PASS | CI static job, initial run 41645861386 |
| Audit unit tests and Python tests | PASS | Same CI static job |
| Milestone tracker structural validator | PASS | Same CI static job; acceptance is a separate gate |
| Godot 4.7.2 import and startup | PASS | CI Godot job, initial run 41645861386 |
| MS-01 through MS-05 regression smoke | PASS | Same CI Godot job, each reported `SMOKE PASS` |
| MS-06 health, HUD, SHIFT, win, death, replay | PASS | Initial CI reported `MS-06 SMOKE PASS`; additional teardown/Enter assertions are on this PR for a follow-up CI run |
| Automated code review | PASS | Rule-based scan from pre-merge run 41645861398; not a gameplay review |
| PR milestone acceptance | FAIL, expected | Manual playtest and full checklist still incomplete |
| Controller feel / aim / HUD contrast | NOT RUN | Human Web session required |
| Hosted HTML5 build and measured run length | NOT RUN | Manual deployment required |

## Scope acceptance

| Requirement | Implemented | Evidence |
| --- | --- | --- |
| Third-person movement, camera and rifle | Yes; preserved | Earlier smoke suites pass on PR revision |
| Safe SHIFT, 8-second anchor, 4-second cooldown, echo | Yes; preserved | MS-03/04/05/06 state and physics smoke |
| 100 HP, death and combat lock | Yes | MS-06 smoke |
| Objective, enemy death integration, win and defeat | Yes | MS-06 smoke |
| Clean replay of scene, gun, ability and enemies | Yes | MS-06 smoke |
| Full two-minute browser playtest | Pending | No owner recording yet |

## Reviewer notes

`scripts/ms06_mission.gd` is the only objective authority. It counts living enemy states instead of relying on an increment-only death total. On terminal transition it disables player controls and SHIFT; the player and rifle reject new combat commands. Replay requests switch immediately to `RESTARTING`, so repeated Enter or button presses cannot schedule multiple reloads. The MS-05 scene remains separate and its smoke suite passes.

This review found no confirmed source-level P0 or P1 defect in the state transitions exercised so far. The missing hosted playtest and duration measurements prevent a final PASS decision. Inspect fresh CI after the follow-up test/documentation commit, then run owner Web QA before changing milestone status.

**Documentation editorial pass:** Reader-facing tracker, plan, review and PR text were checked against the repository's humanizer instructions. Technical paths, milestone identifiers and evidence links were preserved.
