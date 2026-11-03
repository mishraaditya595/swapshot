# MS-04 review: SHIFT expiry, cooldown and echo

**Repository / base..head:** mishraaditya595/swapshot, main...feat/ms-04-shift-lifecycle, PR #12. Gameplay checks cover feature-code commit 2f989e28fcc7ff935a6ac7558df5e56cbbbe1f42.
**Scope/milestone:** P0, MS-04.
**Reviewed files:** scripts/shift_ability.gd, scenes/abilities/shift_ability.tscn, scenes/abilities/shift_echo.tscn, tests/ms03_shift_smoke.gd, tests/ms04_shift_lifecycle_smoke.gd, .github/workflows/ci.yml, README and the implementation plan.
**Test environment:** GitHub Actions, Godot 4.7.2 stable headless on Ubuntu; Python/static checks. No local editor or assistant-observed browser session. Owner gameplay feedback received on Nov 3, 2026.
**Decision:** PASS WITH ISSUES — MS-04 accepted for milestone tracking on Nov 3, 2026, following the owner's positive gameplay report and the passing automated checks. No open P0/P1 defect was observed in tested scope; detailed browser-specific presentation checks remain unrecorded.

## Findings

### P1 fixed: teardown accessed a detached echo transform

- **Evidence:** The first CI attempt, run 41621064234, logged an engine error from shift_ability.gd in _remove_echo during _exit_tree.
- **Reproduction:** SHIFT and exit the MS-03 smoke scene while an echo is active.
- **Expected:** Remove the echo without looking up an invalid world transform.
- **Observed:** Reading global_position after the echo left the scene tree produced a Godot ERROR and failed the CI job.
- **Fix:** Use the top-level echo's position for the end notification during teardown. The MS-03 test also waits for its queued arena cleanup, and MS-04 explicitly unloads a scene with a live echo.
- **Verification:** The updated MS-03 and MS-04 smoke tests passed on feature-code commit 2f989e2 in CI run 41622056909. No corresponding Godot ERROR is present in that run. An additional warning about five leaked ObjectDB instances at process exit was traced to rapid cue playback at the end of the MS-03 test. WAV cues are now cached, playback stops on teardown, and the test gives the audio mixer time to release the final cue. CI run 41622056909 has no ObjectDB leak warning.

### Owner gameplay acceptance and remaining evidence limits

- **Owner report, Nov 3, 2026:** After discussing the implemented SHIFT audio cues, the owner said, "It is working fine," and requested that the MS-04 bookkeeping be completed.
- **Interpretation:** This is affirmative overall gameplay feedback sufficient to accept the milestone together with the existing deterministic engine test evidence. It does **not** establish that the owner explicitly exercised every negative landing, 8-second timer boundary, scene reload or hardware/browser combination.
- **Automated coverage:** [SWAPSHOT CI run 41622208294](https://github.com/mishraaditya595/swapshot/actions/runs/41622208294) passed Godot 4.7.2 import/startup, MS-01–MS-04 engine tests and static audit. MS-04 smoke checks expiry, cooldown, rejection, repeated input, pause, reset, echo signals/lifetime and reload cleanup.
- **Still unrecorded:** Exact browser/device, tested preview commit, recording, independent sound-volume assessment, and a detailed visual acceptance checklist. The assistant has not run a browser or local Godot GUI playtest.
- **Disposition:** No further SHIFT polish is required to close MS-04. Audio/visual refinements remain in MS-12; future feedback can be tracked without blocking this scope. New PR CI must pass before merge.

### Deferred integration, not a defect in MS-04

MS-05 will connect the echo_spawned and echo_ended signals to guards. MS-06 will connect set_owner_alive and reset_lifecycle to player health and restart. The current Esc behavior releases pointer lock; a full pause UI is not part of this milestone. The state tests separately verify that SceneTree pause stops ability timers.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit, audit tests and repository Python tests | PASS | SWAPSHOT CI run 41622208294, Static audit and audit tests |
| Godot 4.7.2 import and startup | PASS | Same CI run, Godot headless job |
| MS-01 and MS-02 regressions | PASS | Same CI run, engine smoke |
| MS-03 teleport and landing safety | PASS | Same CI run, engine smoke |
| MS-04 expiry, cooldown, rejection, spam, pause, death and reload | PASS | Same CI run, MS-04 SMOKE PASS |
| Echo spawn, 1.5-second expiry, signal and cleanup | PASS | Same CI run, MS-04 SMOKE PASS |
| Automated code review | PASS | Pre-Merge automated rule scan on feature-code commit; not a gameplay review |
| PR milestone acceptance | PENDING RECHECK | Milestone and review updated with owner's Nov 3 feedback; requires fresh CI on documentation commits |
| Godot editor and hosted browser inputs, sound and presentation | OWNER REPORT ONLY | Owner says gameplay is working fine; no independent editor/browser session, recording, test build ID or per-feature audio evidence |
| Guard response to echo | OUT OF SCOPE | MS-05 |

## Scope acceptance

| Requirement | Implemented? | Verified? | Notes |
| --- | --- | --- | --- |
| Existing movement and rifle | Unchanged | CI smoke PASS | MS-01 and MS-02 |
| Safe SHIFT landing | Retained | CI smoke PASS | MS-03 regression |
| Eight-second expiry and four-second cooldown | Yes | CI smoke PASS | Physics-delta clock freezes on pause |
| Single active anchor and rejected landing | Yes | CI smoke PASS | Failed activation does not consume cooldown |
| 1.5-second world-space hologram | Yes | CI lifetime/cleanup PASS; general owner approval | Specific visual readability evidence not recorded |
| State/HUD/audio cues | Yes | Godot scene/import and signals PASS; owner general playtest acceptance | No separate audio-volume/visual recording; polish deferred to MS-12 |
| Death, reset and reload safety | Hook and cleanup present | CI smoke PASS | Health/retry producer is planned for MS-06 |
| Enemy distraction | Deferred | NOT RUN | MS-05 |
| Hosted Web game acceptance | General owner acceptance | Owner reported game working; browser/build specifics not provided |

## Risks and next action

No currently observed P0/P1 engine regression remains in the automated scope. The owner has accepted current gameplay in general terms; the MS-04 checklist is complete with the evidence boundaries above. Fresh CI, including the PR milestone acceptance policy, must pass on the final documentation commit before PR #12 is considered merge-ready. No merge is being performed by this bookkeeping update. The project review, verification, brainstorming, find-skills and humanizer skills were consulted; no third-party skill or package was installed. Reader-facing prose received an editorial pass without changing facts, controls or commands.
