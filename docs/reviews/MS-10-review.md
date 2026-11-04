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

| Check | Status | Evidence |
| --- | --- | --- |
| Static project audit | NOT RUN | No complete local repository checkout |
| Python audit and validator tests | NOT RUN | No complete local repository checkout |
| Godot 4.7.2 import/startup | NOT RUN | No local Godot executable |
| MS-01 through MS-09 engine regressions | NOT RUN | Require the new GitHub Actions run |
| MS-10 dedicated scene/physics smoke | NOT RUN | Added to CI; require actual engine logs |
| Hosted Web build / actual playthrough | NOT RUN | Owner/browser test needed |
| Source-level review | PERFORMED | The director, scene and integration paths were inspected; above runtime risks remain |

**Decision:** INSUFFICIENT EVIDENCE pending Godot CI and the hosted browser pass. Keep the MS-10 pull request in draft. Do not check the milestone as complete or merge automatically.
