# MS-10 Extraction implementation review

**Branch:** `feat/ms-10-extraction`. **Date:** November 4, 2026.
**Scope:** Scene-local Double-Deck Lockdown (MS-10), no global mission framework.

## Initial code inspection

- The Extraction director owns all nine phases and is the only component that changes mission state. Four existing stationary troopers begin non-colliding. An upper pair responds to the core pickup; a lower pair responds to the upper clear.
- Enemy sites use three authored points each, real shape and support queries, and horizontal separation from player, anchor, echo and the other guard. Both positions must validate before either actor activates. Eight seconds of failed retries waive the wave without recording fake kills.
- Core and gate require an alive player, appropriate deck height, proximity and unobstructed ray. Victory and death disable player/enemy combat; replay reloads the scene once.
- Shared SHIFT, rifle and trooper scripts were not changed. Existing Loading Dock and Security Core scenes remain directly loadable; only the main preview and the two preview smoke assertions change.

## Risks requiring runtime evidence

1. **P1, needs verification:** A new north gantry, ramp rails and cover can occlude third-person aim or intended SHIFT rays. Confirm actual west ascent, upper lateral placement and downward landing in the Godot smoke and hosted browser.
2. **P1, needs verification:** Guard floor support and candidate positions must validate in the Godot physics server; otherwise waves will be waived and the encounter will be too short.
3. **P1, needs verification:** Enemy visual-root yaw must face the player approach at activation, while solid cover still blocks eye and muzzle rays.
4. **P1, needs verification:** Scene reload after victory and defeat must restore all combat state. Test the existing main preview and standalone scene entry.
5. **P2, needs verification:** At 960 x 540, long objective or result strings may require further font or offset changes. Check actual display and hosted browser.
6. **Acceptance blocker:** Browser gameplay, difficulty, pacing and frame-rate observations have not been supplied. MS-07/MS-08/MS-09 acceptance is still pending in issues #19 and #21. PR #20's POC deferral does not apply to MS-10.

## Verification matrix

**Automated evidence:** [SWAPSHOT CI run 41791242167](https://github.com/mishraaditya595/swapshot/actions/runs/41791242167), commit `2076fb9d9acf271aeb406d13b1e222c8e0b84805`, Godot 4.7.2 stable.

| Check | Status | Evidence |
| --- | --- | --- |
| Static project audit | PASS | GitHub Actions static job, exit 0 |
| Python audit tests and PR/validator unit tests | PASS | GitHub Actions static job, exit 0 |
| Milestone tracker integrity | PASS | GitHub Actions static job, exit 0; acceptance remains unchecked |
| Godot 4.7.2 import/startup | PASS | Import and startup steps completed without reported engine errors |
| MS-01 through MS-09 engine regressions | PASS | Nine sequential physics smoke steps, all successful |
| MS-10 dedicated scene/physics smoke | PASS | `MS-10 SMOKE PASS: core, decks, SHIFT, two waves, LOS, waiver, extraction, replay` |
| Automated code review (rule-based) | PASS | SWAPSHOT Pre-Merge job on commit `74b14b98594ca8f35dc5819ffd78ea3cdc7a9ef4` |
| PR milestone acceptance | FAIL (expected blocker) | MS-07/08/09 prerequisites and unverified MS-10 manual acceptance remain incomplete |
| Hosted Web build / actual playthrough | NOT RUN | Browser, pacing, comfort, audio and performance remain to be tested |
| Source-level critical review | PERFORMED | Reviewed interaction, wave director, SHIFT boundary, rifle/cover, replay, HUD and scope |

**Decision:** INSUFFICIENT EVIDENCE for final milestone acceptance. Automated physics checks are green, while hosted gameplay and milestone prerequisites remain unresolved. Keep [draft PR #23](https://github.com/mishraaditya595/swapshot/pull/23) unmerged.
