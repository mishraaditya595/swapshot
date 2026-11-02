# SWAPSHOT review contract

The authoritative design target is in `docs/GAME_DESIGN.md`, with the full original interactive brief in `source-design-brief.html`. Treat the brief as **planned**, not implemented.

## Core safety criteria

- SHIFT anchor: 18 m target range, 8 s lifetime, only one anchor at a time, floor/line-of-sight and capsule-clearance checks.
- Activation: **revalidate** safe landing immediately before moving the player. Invalid landing **must not** consume charge/cooldown or cause player clipping/softlock.
- Successful SHIFT: 4 s target cooldown, camera and velocity stability, 1.5 s echo distracts enemy guards, and 0.15 s arrival protection tuning target.
- Safety cases: moving/occupied landing, blocked line of sight, cliff, wall, steep slope, expiry edge, spam, pause, death, checkpoint and scene reload.
- Rifle: planned 24-round automatic hitscan, about 1.5 s reload. Validate rate limit, shots blocked by close cover, camera/muzzle alignment, hit reaction, ammo and death.
- Trooper: detect, attack, optionally reposition, react to echo/damage, don't shoot through cover or keep attacking after death.
- UI: readable health, ammo, SHIFT state, objective and restart feedback.
- Web: Compatibility renderer, browser pointer capture and actual hosted build tests before claiming release ready.

## Scope-sensitive review

**P0:** one arena, one rifle, one trooper, safe SHIFT, health, win/retry. **P1:** three zones (Loading Dock, Security Core, Extraction), optional turret and scoring, if feasible. **P2:** polish extras. Do not flag missing P1/P2 content as a P0 bug.

## Evidence

Static code review is not a playtest; Godot headless import is not a web export; web export in CI is not hosted-browser compatibility. Log PASS/FAIL/NOT RUN separately and require actual reproduction steps before claiming SHIFT safety or acceptable feel.
