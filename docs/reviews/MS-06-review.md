# MS-06 review: P0 encounter loop

**Repository / base..head:** `mishraaditya595/swapshot`, `main` to [draft PR #14](https://github.com/mishraaditya595/swapshot/pull/14). Initial CI-tested code revision: `34dd541bb84138963c66666143d97831cdffca77`.

**Scope:** MS-06, P0. **Engine:** Godot 4.7.2 stable in GitHub Actions, GL Compatibility renderer. **Decision:** INSUFFICIENT EVIDENCE for final milestone acceptance. Automated smoke passed, and the owner's browser recording demonstrates both death/retry and victory, but does not settle pacing or post-victory replay.

## Recorded browser evidence

On Nov 3, 2026 the owner uploaded `Screen Recording 2026-11-03 at 7.53.02 PM.mov`, a 97.6-second, 2940 × 1912 screen recording of the hosted `/swapshot/pr-14/` build in Brave on macOS. The first attempt is already at `00:36` on the mission clock at the start of the clip, and ends in defeat at `01:09` with 1/3 guards neutralized and one SHIFT. A retry returns to 100 HP and resets the objective to 0/3; the second attempt completes at `00:50` with 3/3 kills, three SHIFTS and 84/100 HP. The objective changes in response to enemy death, health and ammunition are displayed, and the victory/defeat result overlays appear.

This is visual evidence of a hosted human playthrough. It does not prove the preview's precise commit SHA, FPS, audio quality, browser version, or that victory replay and invalid SHIFT targets were exercised. The recording's video-only stream has no audio track.

## Findings

### P1 — Winning firefight lasts 50 seconds against a two-minute target

- **Evidence:** In the owner's Nov 3 recording, the centered `SECTOR SECURED` screen reports `TIME 00:50 | SHIFTS 3`, `GUARDS NEUTRALIZED 3 / 3`, and HUD `ARMOR 84 / 100`. The prior defeat screen reports `TIME 01:09 | SHIFTS 1` and `1 / 3`. The clip starts when that first run is already 36 seconds in.
- **Reproduction:** Open the current hosted PR #14 preview and play normally through the three-guard objective.
- **Expected:** The MS-06 gate calls for a reproducible, roughly two-minute firefight where SHIFT changes positioning.
- **Observed:** One completed run took 50 seconds of in-game time. Three SHIFTS are reported, and the video shows position changes and an echo/cooldown HUD. The recording alone does not establish how rewarding the flanks felt.
- **Impact:** The full outcome loop works on the recorded path, but the playable fight is shorter than the requested target. More enemies or a larger arena are not needed to evaluate this: tune existing AI/cover and test again.
- **Next check:** Ask the owner whether a short sub-minute win is acceptable or whether MS-06 needs a longer, better-paced encounter. Re-record after any tuning.
- **Confidence:** Observed in hosted browser footage.

### P1 — Browser replay after victory and edge cases remain unverified

- **Evidence:** The video shows `OPERATIVE DOWN` at approximately recording time 00:37, a fresh restarted attempt from around 00:40, and `SECTOR SECURED` around 01:33. The recording ends on the victory screen without activating its replay control. [CI run 41646473838](https://github.com/mishraaditya595/swapshot/actions/runs/41646473838) passed MS-01–MS-06 smoke, including both replay paths in headless tests.
- **Expected:** Victory/replay and defeat/retry work on the hosted build, and unsafe SHIFT destinations cannot strand the player.
- **Observed:** Defeat/retry, full 100-HP restoration and fresh objectives are visible; victory is visible. The victory replay action, invalid landings, window-focus transitions and measured browser performance are absent from this clip.
- **Impact:** The PR still needs targeted manual acceptance.
- **Next check:** Start another run from the victory screen; try blocked/expired SHIFT anchors and record OS/browser version, FPS and any errors.
- **Confidence:** Recorded for defeat/retry and victory; remaining checks need verification.

### P2 — Small HUD typography at the recorded resolution

- **Evidence:** At 2940 × 1912 capture resolution the objective, SHIFT status, mission clock and ammo counters are small relative to the game view; the centered result panel is clear in isolation, but also uses small text.
- **Reproduction:** Open the preview at the recording's display scale and try reading the objective, SHIFT cooldown and ammunition while moving.
- **Expected:** Combat status can be read at a glance without diverting attention from aiming.
- **Observed:** The text is present and contrast varies by field, but the capture alone cannot measure the player's subjective readability.
- **Impact:** Readability may suffer on high-resolution laptop displays.
- **Next check:** Ask the owner whether HUD scale felt legible. If not, increase sizes and spacing without adding more UI systems.
- **Confidence:** Appearance observed, usability impact needs verification.

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
| Browser movement, rifle hits, damage and SHIFT use | PASS (recorded) | Owner-supplied Brave/macOS gameplay; one defeat and one victory | 
| HUD readability and camera comfort | NOT RUN | Visuals recorded; subjective usability feedback not yet given |
| Hosted HTML5 preview and observed outcomes | PASS (recorded) | `mishraaditya595.github.io/swapshot/pr-14/`; 01:09 defeated and 00:50 victorious |
| Victory replay, invalid SHIFT and FPS | NOT RUN | Not shown in uploaded recording |

## Scope acceptance

| Requirement | Implemented | Evidence |
| --- | --- | --- |
| Third-person movement, camera and rifle | Yes; preserved | Earlier smoke suites pass on PR revision |
| Safe SHIFT, 8-second anchor, 4-second cooldown, echo | Yes; preserved | MS-03/04/05/06 state and physics smoke |
| 100 HP, death and combat lock | Yes | MS-06 smoke |
| Objective, enemy death integration, win and defeat | Yes | MS-06 smoke |
| Clean replay of scene, gun, ability and enemies | Yes | MS-06 smoke |
| Browser defeat/retry and victory | Yes, recorded | Death at 01:09 (1/3, SHIFT 1), retry, win at 00:50 (3/3, SHIFT 3) |
| Two-minute pacing and victory/replay acceptance | Pending | Winner completed in 50 seconds; final replay not shown |

## Reviewer notes

`scripts/ms06_mission.gd` is the only objective authority. It counts living enemy states instead of relying on an increment-only death total. On terminal transition it disables player controls and SHIFT; the player and rifle reject new combat commands. Replay requests switch immediately to `RESTARTING`, so repeated Enter or button presses cannot schedule multiple reloads. The MS-05 scene remains separate and its smoke suite passes.

The recording supports a working death/retry and win path and shows no obvious progression softlock. The 50-second winning run misses the two-minute pacing target, while victory/replay and SHIFT safety edge cases still need a browser check. No audio track is present in the uploaded file, so audio is not assessed. Final acceptance remains with the owner.

**Documentation editorial pass:** Reader-facing tracker, plan, review and PR text were checked against the repository's humanizer instructions. Technical paths, milestone identifiers and evidence links were preserved.
