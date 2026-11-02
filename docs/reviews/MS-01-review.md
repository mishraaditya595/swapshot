# MS-01 — SWAPSHOT code review

**Repository / base..head:** mishraaditya595/swapshot, main 9b52abbb..feature 9796e58f
**Scope:** P0 / MS-01 gameplay foundation only
**Reviewed:** project.godot; player_controller.gd; player.tscn; greybox_arena.tscn;
main.tscn; ms01_scene_smoke.gd; CI change, README, milestone and implementation plan.
**Engine used by CI:** Godot 4.7.2 stable, Linux headless.
**Decision:** INSUFFICIENT EVIDENCE for milestone completion (human editor test pending).
**Automated diff/risk review:** passed on the latest completed PR run.

## Findings (highest priority first)

- **Acceptance blocker — real pointer lock/editor playtest not recorded.**
  **Evidence:** \`scripts/player_controller.gd:_unhandled_input\` handles left-click
  capture, Escape release and mouse events; headless display server cannot
  exercise native pointer capture. The first expanded smoke run explicitly
  failed to acquire a pointer in headless mode; the revised test isolates
  camera rotation math and prints this limitation.
  **Expected:** capture on click, stable look, Escape/focus-loss release,
  click-to-recapture, no cursor trap in an actual Godot window.
  **Impact:** milestone gate cannot be completed until tested.
  **Action:** complete manual checklist in \`docs/plans/MS-01-foundation.md\`
  and provide Godot/OS/commit, observed results and repro steps for failures.
  **Confidence:** observed headless limitation; physical UI result unknown.
- **Needs verification — camera comfort near cover edges/corners and ramp
  navigation.** **Evidence:** Godot physics smoke checks sphere-probe boom
  retraction against the south wall and collision with the upper platform,
  but does not witness an actual player steering around cover or walking up
  the ramp. **Expected:** camera stays outside walls and traversal remains
  intuitive throughout the training space. **Action:** editor playtest.
  **Confidence:** unverified manual behavior; not a code-confirmed defect.

No source-confirmed P0/P1 gameplay defect identified in MS-01 after the
camera/input testability fix. No rifle/SHIFT/AI behavior was expected in this PR.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Source static consistency | PASS | 63 pre-commit path/action/scene assertions |
| SWAPSHOT static audit | PASS | GitHub Actions SWAPSHOT CI job |
| Python audit unit tests | PASS | 6/6 |
| Python milestone/pre-merge tests | PASS | 18/18 |
| Tracker structure | PASS | GitHub CI validator |
| Godot 4.7.2 import/startup | PASS | GitHub Actions SWAPSHOT CI |
| MS-01 headless physics & look math | PASS | "MS-01 SMOKE PASS" in Actions logs |
| Automated code review | PASS | Pre-Merge Automated code review job |
| PR milestone acceptance | FAIL (expected) | Unchecked manual tasks and milestone |
| Actual editor pointer capture / camera feel / ramp play | NOT RUN | Needs human results |
| SHIFT, rifle, hosted Web export | NOT IN SCOPE | Later milestones |

**Successful CI run:** https://github.com/mishraaditya595/swapshot/actions/runs/41428102801

## MS-01 acceptance matrix

| Criterion | Implemented | Verified |
| --- | --- | --- |
| Reusable CharacterBody3D player | Yes | Godot import and loaded scene |
| Camera-relative WASD, acceleration/turning, wall collisions | Yes | Headless movement, turning, ground/wall checks |
| Mouse-look, pitch limit, shoulder camera, camera-wall sweep | Yes | Headless look math and wall-probe check; UI still needs hands-on |
| Greybox walls, cover, walkable ramp, raised landing | Yes | Colliders/load verified; manual ramp use pending |
| InputMap and click/Escape/focus flow | Yes | InputMap verified; OS capture/release NOT RUN |
| Human startup/controllability/camera playtest | No evidence | NOT RUN |

## Next action

In Godot 4.7.2 on a real desktop, run the manual checklist, save
version/build/OS and observed results, and attach the record to PR #4.
Only then check the two remaining nested tasks as verified and mark MS-01
complete in the same PR. Do not merge while PR milestone acceptance fails.
