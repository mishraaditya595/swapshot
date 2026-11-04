# MS-09 implementation plan: Security Core

**Base:** merged PR #17 on `main` at `d586a5f67b771b6a1376880c3b2343f83422314f`.
**Branch:** `feat/ms-09-security-core`.
**Design:** [approved Security Core spec](../superpowers/specs/2026-11-04-ms-09-security-core-design.md).
**Milestone:** MS-09 only.

Implement and verify these increments, in order. The MS-07/MS-08 issue #19 acceptance backlog is unchanged.

| Increment | Files | Work | Acceptance and regressions |
| --- | --- | --- | --- |
| 1. Greybox and traversal | `scenes/levels/security_core.tscn`, `scripts/ms09_security_core.gd` | Lower chamber, both walkable ramps, catwalk, west console platform, physical crates/rails and cyan landing markers | Real physics collision, clear player spawn, reachable upper deck without SHIFT; camera under upper walk, no cliff softlock |
| 2. Safe vertical SHIFT | Scene geometry, `tests/ms09_security_core_smoke.gd` | Tune landing pads to current 18 m range, 4 m height cap and support/LOS rules; keep shared ability intact | Real upward/lateral/downward tests plus blocked side, edge, occupied destination, expiry and cooldown; no wall teleport |
| 3. Enemy combat | MS-09 scene/director and smoke | Two lower guards; two dormant upper guards activated at safe candidate positions after lower clear; combat warnings and echo feedback | Collision-safe spawning, no fire through floor/cover, no shooting after death, no activation atop player/anchor/echo; reuse MS-06 logic patterns |
| 4. Terminal and feedback | MS-09 scene/director and smoke | Amber locked console, cyan unlocked, E interaction, close/height/LOS and death guards | All four defeated before unlock; remote, early, lower-floor and blocked requests rejected; successful shutdown once |
| 5. Failure and replay | Director and smoke | Freeze on death or shutdown, Enter/button restart by scene reload | Fresh health/ammo, reset timer/anchor/echo/guard/terminal; duplicate retry input does not reload twice |
| 6. UI and preview | HUD in scene, `scenes/main.tscn`, `tests/ms08_loading_dock_smoke.gd` | Make Security Core the preview entry; preserve Loading Dock standalone; 960×540 HUD legibility | No SHIFT/HUD overlaps, correct preview startup and MS-08 regression expectations |
| 7. Verification and review | `tests/MS-09-BROWSER-QA.md`, CI, milestone tracker, PR | Add MS-09 Godot smoke to CI; run audit/Python/engine suites; critical review; manual hosted QA when available | Record precise PASS/FAIL/NOT RUN and known limitations. Do not infer human acceptance. |

## Test commands

```bash
python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .
python3 -m unittest discover -s .agents/skills/swapshot-review/tests -v
python3 -m unittest discover -s tests -v
python3 scripts/validate_milestones.py docs/MILESTONES.md
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . --script res://tests/ms09_security_core_smoke.gd
```

Also run and inspect existing MS-01 through MS-08 Godot scripts and CI. Use a trusted Godot 4.7.2 executable; unavailable local tools are NOT RUN. Human browser testing and owner approval remain separate. Keep any MS-09 implementation PR draft and do not merge automatically.
