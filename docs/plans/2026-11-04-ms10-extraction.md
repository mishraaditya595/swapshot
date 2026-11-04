# MS-10 implementation plan: Double-Deck Lockdown

**Milestone:** MS-10 only. **Date:** November 4, 2026.
**Base:** `main` at `7009b5a7355b4f27a56b8fc5160fdbcdbd23cbd4`.
**Branch:** `feat/ms-10-extraction`.
**Design:** [approved Extraction spec](../superpowers/specs/2026-11-04-ms10-extraction-design.md).
**Planning skill:** A local `writing-plans` skill is unavailable; this plan follows `AGENTS.md` and `docs/AGENT_WORKFLOW.md`.

| Increment | Deliverable | Testable outcome |
| --- | --- | --- |
| 1. Scene scaffold | `scenes/levels/extraction.tscn` with player, four dormant troopers, core, gate, HUD and outcome | Loads in isolation; starts with full HP and ammo; no active guards |
| 2. Geometry | Collision-backed industrial chamber, single west ramp, north gantry, east overlook, cover, rails and non-colliding floor signs | Walking route reaches core without SHIFT; supported spawn and interaction pads |
| 3. SHIFT lanes | Author upper cross-flank and exposed lower drop pads around existing safety constraints | Placement, teleport, blocked floor/occlusion and cooldown checks use original SHIFT script |
| 4. Core pickup | `RETRIEVE` phase, E proximity/height/LOS, single pickup signal, cyan core and objective | Remote, through-floor, blocked, dead or duplicate pickup rejected |
| 5. Warning and upper stage | 1.7s warning, atomic pair selection among three candidates each, upper defender activation | No spawn overlaps player, active anchor, echo, guard or geometry |
| 6. Lower response and waiver | 0.25s retry, 8s waiver, upper-to-lower state change, two lower guards and locked gate | All-blocked waves progress without unsafe spawn; waiver is not a kill |
| 7. Extraction and victory | Validated lower E, core/stage/live-enemy predicate, clear objective and result stats | Early, blocked, distant and duplicate extraction rejected; victory stops combat |
| 8. Death and replay | Managed death, one guarded deferred reload, HUD and SHIFT cleanup | Death in warning cancels spawns; victory/death replay restores all state |
| 9. Automated verification | MS-10 physics smoke, CI timeout, prior preview test update, static checks | Godot MS-01 through MS-10 smoke, import/startup, Python audit/unit/validators |
| 10. Browser and review handoff | Browser QA checklist, read-only critical review, milestone tracker, draft MS-10 PR | Actual evidence marked PASS/FAIL/NOT RUN; do not check manual acceptance or merge |

## Delivery constraints

Preserve the approved two-by-two stationary troopers and eight-second waiver. No cross-zone transition, new weapons, inventory, moving lifts, dynamic navigation or relaxation of SHIFT safety. Keep `MS-07`/`MS-08`/`MS-09` acceptance untouched. Record any Godot/browser tests not run as `NOT RUN`; only check tasks with fresh verification. Use a draft PR if acceptance is blocked.

## Commands

```bash
python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .
python3 -m unittest discover -s .agents/skills/swapshot-review/tests -v
python3 -m unittest discover -s tests -v
python3 scripts/validate_milestones.py docs/MILESTONES.md
godot --headless --path . --import
godot --headless --path . --quit-after 2
godot --headless --path . --script res://tests/ms10_extraction_smoke.gd
```

CI runs the existing Godot MS-01 through MS-09 smoke tests and the new MS-10 smoke; a real hosted browser playtest remains a separate acceptance gate.
