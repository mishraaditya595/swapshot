---
name: swapshot-review
description: Review the SWAPSHOT Godot 4 third-person shooter repository, a pull request, or a milestone against the Game Off 2026 SHIFT design brief. Use for Godot/GDScript code reviews, SHIFT teleport safety, shooting and enemy AI verification, browser export readiness, regression checks, and actionable release go/no-go assessments. Review only; do not modify files unless explicitly asked to fix findings.
---

# SWAPSHOT reviewer

Review SWAPSHOT as a **small, polished, single-player, third-person tactical shooter**, not as a large AAA/open-world game. The 2026 jam theme is **SHIFT**. A good review helps the solo developer ship a fun, stable, browser-playable build in the jam timeframe.

## Milestone completion check

For every gameplay or release milestone review, read `docs/MILESTONES.md`; verify **exactly one** milestone is represented by the implementing PR. Review each checked task against test evidence, the acceptance gate and the actual PR link. Reject false completion, unrelated work and missing manual/hosted test evidence. Run `python3 scripts/validate_milestones.py docs/MILESTONES.md` when available, noting it only checks structure.

## PR quality gate evidence

When reviewing PRs, inspect reports from the `PR milestone acceptance` and `Automated code review` GitHub Actions jobs (see `docs/PRE_MERGE.md`). Use their findings as **signals**, not proof of complete code review: the automated scan cannot establish gameplay, SHIFT capsule safety, scene runtime behavior or browser performance. Report manual reproduction and acceptance evidence independently. Never call a PR ready when its policy or review check fails.

## Source of truth and scope

1. Read `references/design-contract.md` for acceptance criteria and intended scope. The bundled `references/source-design-brief.html` is the original interactive design document; consult relevant sections when precise detail matters. Treat tunable values as targets, not inflexible final product requirements.
2. Inspect `README.md`, `project.godot`, `export_presets.cfg` if present, and the changed files. Prefer project code and current tests for what is **implemented**; the design brief is evidence of what is **planned**, never proof something works.
3. Determine review mode from the request:
   - **PR/diff**: Compare base vs head if available; focus on changed behavior plus interactions and regressions. Review the surrounding code before flagging a defect.
   - **Milestone/feature**: Trace the requested feature end to end from input to feedback and failure handling.
   - **Whole repo / release**: Check project integrity, core loop, gameplay regressions, exports, credits, and jam requirements.
4. If there is no repository, state `NOT REVIEWED — REPOSITORY NOT PROVIDED`. A concept or HTML demonstration alone is not a playable Godot build.
5. If the user only supplies the design brief, perform a **design review**, not a source-code review, and clearly distinguish it.

## Review workflow

### 1. Establish an evidence baseline

- Record repository, branch or PR, commit SHA if available, and what files you examined.
- Inspect the project structure and determine Godot version from project metadata and/or the installed binary. The brief proposes Godot 4.7.2, but use the version actually configured in the project to run checks. Never assume a Godot binary is installed.
- Identify the current milestone: first 48 hours, P0 prototype, three-zone mission, or release candidate. Do not demand P1/P2 features in a P0 prototype.
- If the environment allows, run the **non-mutating** stdlib audit:

```bash
python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .
```

For release reviews, add `--release`. This script checks file layout, local resource paths, main scene, and selected packaging hygiene. **It is not a gameplay test.**

### 2. Inspect the code paths that matter

Follow actual signals/calls and state changes; do not infer functionality from names. Prioritize:

1. **Core controls**: movement relative to the camera, over-the-shoulder aiming, camera collision and stability, input capture/pause, shooting/reloading while moving, death and quick retry.
2. **SHIFT correctness (highest priority)**: anchor max range, placement raycast, navigable floor, landing capsule clearance, blocked surfaces, line of sight, expiry, revalidation at activation, cooldown, single-anchor handling, safe velocity/camera transitions, echo lifetime and enemy distraction. Ensure rejected placement or activation doesn't incorrectly consume cooldown, cause softlocks, or clip through walls.
3. **Combat**: crosshair-camera aim alignment, near-wall muzzle obstruction, hitscan rate limits, damage ownership, ammo/reload transitions, hit feedback, enemy damage/death, health and recovery, small enemy counts.
4. **Enemy behavior**: target acquisition, line of sight, firing telemetry/cadence, cover/reposition, echo priority and expiration, no firing from dead/disabled actors, no runaway navigation or timers.
5. **Mission and UI**: objective clarity, encounter completion, three-zone progression when implemented, checkpoints, extraction, pause/restart, HUD validity, controls tutorial.
6. **Browser/shipping**: Godot web export compatibility, input and mouse capture after focus changes, sensible rendering load, memory/audio/download sizes, exported HTML5 package and browser smoke test. Do not claim a web build works from source inspection alone.

Use `references/design-contract.md` for concrete expected outcomes and intentionally deferred features.

### 3. Validate with the tools actually available

Run relevant checks when possible and **log every check with PASS / FAIL / NOT RUN**, command, and observed result. Suitable checks:

```bash
# Static, no-engine audit (reads files; no changes):
python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .

# If a trusted Godot executable is installed, import/parse resources:
godot --headless --path . --import

# If an actual Web export preset exists and export templates are installed:
mkdir -p /tmp/swapshot-review-export
godot --headless --path . --export-release 'Web' /tmp/swapshot-review-export/index.html
```

- `godot` may be named differently; determine binary and preset name from the environment/project. Run automated Godot tests only if the repository contains a documented runner; report the runner and result.
- Engine load success does not verify frame rate, camera comfort, AI quality, or browser compatibility. Request a **manual playtest** for those.
- Never say tests passed unless they were executed and their output checked. If execution is unavailable, use `NOT RUN` and state what the owner needs to try.
- Do not install dependencies, download assets, change project settings, or create commits as part of a review without permission.

### 4. Perform an explicit playtest, if a build is available

Use a fresh run and test the following user journeys, recording observed behavior:

1. Launch, start, move, look, aim, fire, reload, pause, resume, restart.
2. Place valid SHIFT anchor on ground and elevated surfaces; SHIFT while firing and moving.
3. Try invalid anchor on wall, beyond max distance, across occluding wall, into tight space, under/inside actor, on a changing/blocked destination.
4. Wait for anchor expiration; trigger SHIFT on/near expiration; spam input during cooldown; move/fall while SHIFTing; retry after death.
5. SHIFT to flank a guard; see whether enemy retargets the decoy and eventually returns to player; finish fight and check objective and UI.
6. Complete a full mission if built; replay without progression blockers. Test hosted HTML5 separately from local editor.

If no build can be run, mark **PLAYTEST NOT RUN**, and provide these steps as reproduction/verification instructions without fabricating observations.

### 5. Report only supported findings

Use `references/review-report-template.md`. Order findings by impact and actionable evidence:

- **P0 / Blocker**: prevents launch/progression, corrupts game state, teleports through solid walls, locks player, consistently crashes, broken submission build, significant security/privacy issue.
- **P1 / Major**: reliable gameplay mechanic fails, invalid SHIFT edge case, shots bypass cover, broken enemy AI, severe usability/performance problems, important regression.
- **P2 / Minor**: polish, UX clarity, small maintainability issues, low-risk tuning opportunities.
- **Suggestion**: nonblocking improvement, only after correctness and scope are addressed.

For each finding, provide `file:line` or scene/node and the conditions needed to reproduce, expected vs observed, impact, and smallest fix or test that would validate the fix. Do not overstate guessed defects; label code-inferred risk as **Needs verification**.

End with a separate **acceptance matrix** and a clear decision: `PASS`, `PASS WITH ISSUES`, `CHANGES REQUIRED`, or `INSUFFICIENT EVIDENCE`. Explain whether P0, P1, or release level was evaluated. Missing unimplemented P1 features are not regressions in a P0 review.

## Rules

- Be specific, skeptical, constructive, and concise. No cosmetic nitpicks before functional issues.
- Prefer evidence from the provided code and observed behavior. Cite repository paths, lines, and command output; don't invent files, test results, performance numbers, or Godot compatibility.
- Never silently update design requirements. Call out intentional deviations and explain gameplay consequences; adjustable balance numbers can legitimately change.
- Keep the solo-developer scope: **one rifle, one enemy archetype and one arena for P0**. Do not propose multiplayer, open world, inventory systems, complex squads, or expensive art pipelines as prerequisites.
- Separate implementation verification from judgment about **fun**. Fun, aiming feel, readability, camera comfort and frame pacing require hands-on feedback.
- Review only by default. If specifically asked to fix issues, switch to a separate change-making task and propose minimal, verifiable patches.
