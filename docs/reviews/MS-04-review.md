# MS-04 review: SHIFT expiry, cooldown and echo

**Repository / base..head:** mishraaditya595/swapshot, main...feat/ms-04-shift-lifecycle, PR #12. Gameplay checks cover feature-code commit 2f989e28fcc7ff935a6ac7558df5e56cbbbe1f42.
**Scope/milestone:** P0, MS-04.
**Reviewed files:** scripts/shift_ability.gd, scenes/abilities/shift_ability.tscn, scenes/abilities/shift_echo.tscn, tests/ms03_shift_smoke.gd, tests/ms04_shift_lifecycle_smoke.gd, .github/workflows/ci.yml, README and the implementation plan.
**Test environment:** GitHub Actions, Godot 4.7.2 stable headless on Ubuntu; Python/static checks. Local Godot editor and browser QA were unavailable.
**Decision:** PASS WITH ISSUES for automated MS-04 logic. Full milestone acceptance is pending owner Web playtesting of visibility, audio and controls.

## Findings

### P1 fixed: teardown accessed a detached echo transform

- **Evidence:** The first CI attempt, run 41621064234, logged an engine error from shift_ability.gd in _remove_echo during _exit_tree.
- **Reproduction:** SHIFT and exit the MS-03 smoke scene while an echo is active.
- **Expected:** Remove the echo without looking up an invalid world transform.
- **Observed:** Reading global_position after the echo left the scene tree produced a Godot ERROR and failed the CI job.
- **Fix:** Use the top-level echo's position for the end notification during teardown. The MS-03 test also waits for its queued arena cleanup, and MS-04 explicitly unloads a scene with a live echo.
- **Verification:** The updated MS-03 and MS-04 smoke tests passed on feature-code commit 2f989e2 in CI run 41622056909. No corresponding Godot ERROR is present in that run. An additional warning about five leaked ObjectDB instances at process exit was traced to rapid cue playback at the end of the MS-03 test. WAV cues are now cached, playback stops on teardown, and the test gives the audio mixer time to release the final cue. CI run 41622056909 has no ObjectDB leak warning.

### Manual feedback remains unverified

- **Evidence:** Engine smoke tests verify state, timing, signals, geometry and cleanup. They do not render a browser playthrough or establish audible cue volume.
- **Reproduction:** Deploy PR #12 through the manual Web preview workflow, capture the mouse, place an anchor, wait for expiry, SHIFT, then repeat after cooldown.
- **Expected:** Clear timer and active echo, audible but unobtrusive cues, no camera pop or input lock, and an expired anchor that can be replaced.
- **Observed:** NOT RUN in this session.
- **Impact:** The mechanism can satisfy deterministic tests while its HUD or presentation feels unclear.
- **Next test:** Owner Web playthrough with browser, device, commit SHA, observed results and a recording or notes.
- **Confidence:** Needs verification.

### Deferred integration, not a defect in MS-04

MS-05 will connect the echo_spawned and echo_ended signals to guards. MS-06 will connect set_owner_alive and reset_lifecycle to player health and restart. The current Esc behavior releases pointer lock; a full pause UI is not part of this milestone. The state tests separately verify that SceneTree pause stops ability timers.

## Verification matrix

| Check | Status | Evidence |
| --- | --- | --- |
| Static audit, audit tests and repository Python tests | PASS | SWAPSHOT CI run 41622056909, Static audit and audit tests |
| Godot 4.7.2 import and startup | PASS | Same CI run, Godot headless job |
| MS-01 and MS-02 regressions | PASS | Same CI run, engine smoke |
| MS-03 teleport and landing safety | PASS | Same CI run, engine smoke |
| MS-04 expiry, cooldown, rejection, spam, pause, death and reload | PASS | Same CI run, MS-04 SMOKE PASS |
| Echo spawn, 1.5-second expiry, signal and cleanup | PASS | Same CI run, MS-04 SMOKE PASS |
| Automated code review | PASS | Pre-Merge automated rule scan on feature-code commit; not a gameplay review |
| PR milestone acceptance | PENDING | The PR stays draft until the manual feedback task and acceptance record are complete |
| Godot editor and hosted browser inputs, sound and presentation | NOT RUN | No accessible manual session or owner report for MS-04 |
| Guard response to echo | OUT OF SCOPE | MS-05 |

## Scope acceptance

| Requirement | Implemented? | Verified? | Notes |
| --- | --- | --- | --- |
| Existing movement and rifle | Unchanged | CI smoke PASS | MS-01 and MS-02 |
| Safe SHIFT landing | Retained | CI smoke PASS | MS-03 regression |
| Eight-second expiry and four-second cooldown | Yes | CI smoke PASS | Physics-delta clock freezes on pause |
| Single active anchor and rejected landing | Yes | CI smoke PASS | Failed activation does not consume cooldown |
| 1.5-second world-space hologram | Yes | CI lifetime/cleanup PASS | Visual readability needs browser review |
| State/HUD/audio cues | Yes | Godot scene/import and signals PASS; browser NOT RUN | Keep related milestone task pending |
| Death, reset and reload safety | Hook and cleanup present | CI smoke PASS | Health/retry producer is planned for MS-06 |
| Enemy distraction | Deferred | NOT RUN | MS-05 |
| Hosted Web game acceptance | Pending | NOT RUN | Manual deployment only |

## Risks and next action

No currently observed P0/P1 engine regression remains in the automated scope. The owner needs to publish and exercise PR #12's Web build before accepting the audio/visual task and checking MS-04 complete. The manual PR acceptance policy remains intentionally red while that evidence is missing. The project review, verification, brainstorming, find-skills and humanizer skills were consulted; no third-party skill or package was installed. Reader-facing prose received an editorial pass without changing facts, controls or commands.
