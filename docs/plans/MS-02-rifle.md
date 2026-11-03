# MS-02 — VX-7 rifle design and implementation

**Status:** Feature branch in development; do not treat this document as acceptance evidence.

## Objective
Add one reliable, satisfying third-person weapon to the completed MS-01 player/camera. Scope is the documented 24-round automatic hitscan VX-7, ADS, reload, damageable training targets, recoil, tracers, impact flashes, hit-marker and ammo HUD. No enemy AI, SHIFT or new assets/dependencies.

## Brainstormed alternatives
- **Camera-only ray:** crosshair feels correct, but barrel can shoot through nearby cover. Rejected.
- **Barrel-only ray:** accounts for cover but misses the crosshair when camera is offset. Rejected.
- **Camera target plus muzzle obstruction (selected):** camera center sets the desired impact; camera-to-muzzle probe and muzzle-to-target ray prevent hitting through walls. Small extra physics cost acceptable for one player rifle.

This design follows the already established MS-02 specification; other tuning is internal and remains playtest-adjustable.

## Vertical implementation
1. Install InputMap fire/aim/reload without changing MS-01 movement inputs.
2. Mount VX-7 as Camera3D child; keep ammunition and cadence entirely in one rifle script.
3. Animate ADS field of view and cosmetic recoil without changing shoulder camera collision.
4. Provide damageable static targets, two-stage hit detection and short-lived procedural FX.
5. Bind an uncomplicated crosshair, ammo count, reload text and hit marker via weapon signals.
6. Add headless regressions for cadence, magazine depletion, partial/empty reload and close-wall shots in CI.

## Manual Web acceptance (owner required)
Click to capture and release without surprise fire; hold LMB for sustained fire; ADS with RMB while moving; empty 24-shot magazine, reload with R; verify reticle, recoil, muzzle flash/tracer/impact/hit marker and destruction. Shoot around cover and up the ramp, then repeat after Escape/focus change. Record video and verify hosted PR preview independently of engine CI.

## Constraints and deferred work
Godot 4.7.2/Compatibility; no external assets or costly shaders. No attempt to certify feel or pointer-lock/browser behavior using headless tests. MS-03/04 SHIFT and MS-05 enemy AI remain separate PRs.
