# MS-10 Extraction implementation review

**Branch:** `feat/ms-10-extraction`. **Date:** November 4, 2026.
**Scope:** Scene-local Double-Deck Lockdown (MS-10), no global mission framework.

## Initial code inspection

- The Extraction director owns all nine phases and is the only component that changes mission state. Four existing stationary troopers begin non-colliding. An upper pair responds to the core pickup; a lower pair responds to the upper clear.
- Enemy sites use three authored points each, real shape and support queries, and horizontal separation from player, anchor, echo and the other guard. Both positions must validate before either actor activates. Eight seconds of failed retries waive the wave without recording fake kills.
- Core and gate require an alive player, appropriate deck height, proximity and unobstructed ray. Victory and death disable player/enemy combat; replay reloads the scene once.
- Shared SHIFT, rifle and trooper scripts were not changed. Existing Loading Dock and Security Core scenes remain directly loadable. MS-10 provides scene-local impact flashes and brief visual recoil through the existing trooper damage signal.
- The follow-up also adds non-colliding color bands to cover, hides the core's 3D sign at pickup and keeps the exit prompt inside its panel.

## Browser recording and visual fixes

The owner supplied a 480p Mac browser recording of the original PR #23 preview on November 4. It shows the full core pickup, upper and lower fights, and extraction. The ending reports four defeated troopers, four SHIFTS, about 02:15 elapsed and roughly 76/100 armor. This establishes one successful hosted-browser playthrough. It does not establish the exact tested revision, average FPS, audio, invalid SHIFT attempts or replay behavior.

At about 0:42, the `CORE SECURED` 3D label obscured the upper firefight. Around 1:57, the gate's long status text extended beyond the sign and became hard to read. The encounter's cover and live troopers also lacked clear visual differences and hit response. PR #23 now hides the core label after pickup, presents `CORE SECURED` on the normal HUD, shortens and shrinks the gate status, adds cover role colors/trim and provides a short chest flash and visual recoil on nonlethal hits. No trooper movement, AI targeting, health or SHIFT collision logic changed.

The updated sign and combat visuals still need a new hosted browser test. The recording also shows a single 02:15 clear, shorter than the planned 3 to 5 minutes. Rebalance only after further first-time player feedback. The browser QA worksheet records the remaining test cases.

## Risks requiring runtime evidence

1. **P1, needs verification:** A new north gantry, ramp rails and cover can occlude third-person aim or intended SHIFT rays. Confirm actual west ascent, upper lateral placement and downward landing in the Godot smoke and hosted browser.
2. **P1, needs verification:** Guard floor support and candidate positions must validate in the Godot physics server; otherwise waves will be waived and the encounter will be too short.
3. **P1, needs verification:** Enemy visual-root yaw must face the player approach at activation, while solid cover still blocks eye and muzzle rays.
4. **P1, needs verification:** Scene reload after victory and defeat must restore all combat state. Test the existing main preview and standalone scene entry.
5. **P2, needs verification:** At 960 x 540, long objective or result strings may require further font or offset changes. Check actual display and hosted browser.
6. **Acceptance blocker:** The original browser playthrough is documented, but there is no post-fix browser evidence for the updated text and impact effects, or measured frame-rate, audio and difficulty results. MS-07/MS-08/MS-09 acceptance is still pending in issues #19 and #21. PR #20's POC deferral does not apply to MS-10.

## Verification matrix

**Automated evidence:** [SWAPSHOT CI run 41821936986](https://github.com/mishraaditya595/swapshot/actions/runs/41821936986), commit `5c91473ce12e39f704fc34156d71a780db279d51`, Godot 4.7.2 stable. The run passed after the signage, cover and hit-response changes and their tests.

| Check | Status | Evidence |
| --- | --- | --- |
| Static project audit | PASS | GitHub Actions static job, exit 0 |
| Python audit tests and PR/validator unit tests | PASS | GitHub Actions static job, exit 0 |
| Milestone tracker integrity | PASS | GitHub Actions static job, exit 0; acceptance remains unchecked |
| Godot 4.7.2 import/startup | PASS | Import and startup steps completed without reported engine errors |
| MS-01 through MS-09 engine regressions | PASS | Nine sequential physics smoke steps, all successful |
| MS-10 dedicated scene/physics smoke | PASS | The original contract plus core-label visibility, gate text, decorative cover and nonlethal hit flash/recoil assertions passed |
| Automated code review (rule-based) | PASS | SWAPSHOT Pre-Merge job on commit `74b14b98594ca8f35dc5819ffd78ea3cdc7a9ef4` |
| PR milestone acceptance | FAIL (expected blocker) | MS-07/08/09 prerequisites and unverified MS-10 manual acceptance remain incomplete |
| Hosted Web build / actual playthrough | PARTIAL | Original PR #23 browser footage shows extraction success; the updated visuals, audio, performance, focus handling and replay have not been verified |
| Source-level critical review | PERFORMED | Reviewed interaction, wave director, SHIFT boundary, rifle/cover, replay, HUD and scope |

**Decision:** INSUFFICIENT EVIDENCE for final milestone acceptance. Automated Godot tests pass and the original happy-path browser run is recorded. The new visual fixes require a hosted retest, and earlier milestone acceptance issues remain. Keep [draft PR #23](https://github.com/mishraaditya595/swapshot/pull/23) unmerged.
