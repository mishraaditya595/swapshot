# MS-08 review: Loading Dock opening

**Repository / range:** `mishraaditya595/swapshot`, `main` to `feat/ms-08-loading-dock`, [PR #17](https://github.com/mishraaditya595/swapshot/pull/17).  
**Scope:** P1 Loading Dock only, Godot 4.7.2 Compatibility.  
**Review mode:** Source and current-PR automated checks. No hosted gameplay session.  
**Decision:** INSUFFICIENT EVIDENCE for milestone acceptance. The automated suite passes, but first-time browser feedback is required.

## Findings

### Acceptance blocker: first-time comprehension and duration have not been measured

- **Evidence:** `scripts/ms08_loading_dock.gd` advances prompts through real route, target, anchor and SHIFT events; the new Godot smoke passes those transitions and the final gate. A headless scene cannot establish that players notice the prompts, use SHIFT tactically or finish in the intended two to three minutes.
- **Expected:** An unfamiliar player reaches the Security Core exit without outside guidance and understands SHIFT.
- **Next check:** Deploy PR #17, record the first run and complete `tests/MS-08-BROWSER-QA.md` before checking the milestone.

### P2 follow-up: overhead camera visibility is unconfirmed

- **Evidence:** PR #16's video raised an overhead-geometry question. The Loading Dock uses open main lanes, four-metre perimeter walls and no low overhead physical beams. `scripts/shoulder_camera.gd` is unchanged.
- **Reproduction needed:** Approach walls and cargo at close range while rotating the camera, particularly near any upper trim. Record a browser clip if visibility fails.
- **Decision:** No speculative camera change in MS-08.

### P2 follow-up: point-blank guard engagement is unconfirmed

- **Evidence:** `scripts/security_trooper.gd` still checks eye and muzzle line of sight when acquiring and firing. Existing AI tests passed; no new browser evidence establishes a close-range defect.
- **Reproduction needed:** Stand near the front and sides of a live guard, wait for its warning, and record whether it engages. Include the distance and angle in any report.
- **Decision:** Preserve the established AI until a fault is reproduced.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static SWAPSHOT audit | PASS | [CI 41690893409](https://github.com/mishraaditya595/swapshot/actions/runs/41690893409) |
| Audit Python tests | PASS | Same run, 6 tests |
| Repository Python tests | PASS | Same run, 30 tests |
| Milestone tracker validator | PASS | Same run, MS-00 through MS-16 valid |
| Godot 4.7.2 import | PASS | Same run, official 4.7.2 stable executable |
| Godot startup | PASS | Same run, two headless frames, no reported engine errors |
| MS-01 to MS-07 Godot smoke | PASS | Same run, seven distinct `SMOKE PASS` reports |
| MS-08 Godot smoke | PASS | Same run, physical route trigger, target, anchor, blocked SHIFT, cover ray, gate, win/death replay |
| Rule-based automated code review | PASS | [SWAPSHOT Pre-Merge](https://github.com/mishraaditya595/swapshot/actions/workflows/premerge.yml), limited to static risk checks |
| PR milestone acceptance policy | FAIL, expected | MS-07 prerequisite is unchecked and MS-08 still requires human acceptance; the existing policy has no override for an authorized work-order exception |
| Hosted browser playtest | NOT RUN | Owner must manually deploy the PR |
| Browser camera, point-blank AI, FPS, audio and mouse capture | NOT RUN | Requires the hosted PR build and a human player |

The Godot/Python CI result is for commit `9c8c913a5e33cf983e50233b35b4b4fc3167fb2d`. If a documentation or scene-only cleanup follows, rerun CI and replace this evidence with the latest successful head.

## Source review and scope acceptance

The new `loading_dock.tscn` instances the existing player, practice target, HUD and two troopers. Reusable cargo has physical box collisions. The new director counts eliminated guards once, keeps its gate locked until both die, rejects remote E interaction and freezes input on victory/death. It does not modify `shift_ability.gd`, `security_trooper.gd`, `vx7_rifle.gd` or `ms06_mission.gd`. The original MS-06 and MS-07 tests passed on the same new scene entry build.

The integration change to `tests/ms06_loop_smoke.gd` updates its startup assertion from MS-06 to Loading Dock while retaining the complete MS-06 encounter regression. No new reinforcement spawns exist in this dock section, and the MS-07 echo-safe entry protection remains unchanged.

| MS-08 requirement | Implemented | Automated verification | Human verification |
| --- | --- | --- | --- |
| Containers, crates, cover and flanking lanes | Yes | Scene load and cover ray pass | Route quality pending |
| Contextual movement, rifle, anchor and SHIFT prompts | Yes | Signal/physics transitions pass | Instruction clarity pending |
| Opening two-guard fight, 2–3 minute pacing | Yes, timing is a target | Kills, feedback and counts pass | Actual duration pending |
| Exit gate and next-zone message | Yes | Locked state, proximity, win and replay pass | Readability pending |
| Safe SHIFT and unaffected P0 gameplay | Existing implementation reused | MS-01 to MS-08 pass | Hosted browser safety pending |

## Decision and next action

Keep [PR #17](https://github.com/mishraaditya595/swapshot/pull/17) open and draft. MS-08 completion remains unchecked, as does MS-07. The owner authorized starting MS-08 out of order; that did not accept the prerequisites or waive the review gates. The pre-merge policy check will continue to block merge until its prerequisite requirement is satisfied or an explicitly reviewed policy change is made.

Complete `tests/MS-08-BROWSER-QA.md`, attach a first-time run and record the pacing, SHIFT usage, camera and guard observations. This document and the PR text received a humanizer editorial pass; test results and outstanding requirements were kept explicit.
