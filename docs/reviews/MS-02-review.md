# SWAPSHOT MS-02 review — VX-7 rifle

**Repository / base..head:** `mishraaditya595/swapshot`, main..feat/ms-02-vx7-rifle, implementing [PR #8](https://github.com/mishraaditya595/swapshot/pull/8).
**Scope/milestone:** P0 / MS-02 only.
**Reviewed:** VX7 scene and script; FX, target, HUD, InputMap, arena/player instancing, new smoke test, workflow and tracker.
**Test environment:** GitHub Actions Linux Godot 4.7.2 stable; this conversation runtime has no Godot editor or hosted PR browser run.
**Decision:** INSUFFICIENT EVIDENCE for full gameplay acceptance; automated evidence PASS.

## Findings

### P1 — Hosted/browser gameplay still unverified
- **Evidence:** No manual Web deployment or owner gameplay video for PR #8. Existing `deploy-web-manual.yml` deliberately only runs when triggered.
- **Reproduction:** Actions → SWAPSHOT Deploy Web to GitHub Pages (Manual) → Run workflow → source `pr`, PR `8`. Play with WASD/LMB/RMB/R/Escape near crates and on the ramp.
- **Expected:** No click-to-capture ghost shots; ADS and recoil feel responsive; muzzle/camera ray disagreement does not let shots through close cover.
- **Observed:** NOT RUN. Headless tests cannot witness render, sounds, pointer capture, frame pacing or recoil feel.
- **Smallest next test:** Owner records one hosted Web run covering the MS-02 acceptance gate and updates this report.

### P2 — Prototype visuals, no audio asset
- **Evidence:** `scenes/weapons/vx7.tscn` uses a low-poly placeholder mesh; `scripts/rifle_fx.gd` creates procedural tracers and impact spheres. `shot_fired` and `dry_fired` signals are audio hooks, not audible clips.
- **Expected:** Readable minimal feedback for MS-02; sound polish can be scheduled for MS-12.
- **Observed:** Visual effects are implemented, **not visually playtested**.
- **Smallest next test:** Confirm muzzle, tracer, impact and target destruction are visible and inexpensive in a hosted browser build.
- **Confidence:** code-inferred; no observed playtest.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static audit, Python tests, milestone tracker validator | PASS | [CI run 41586482031](https://github.com/mishraaditya595/swapshot/actions/runs/41586482031) |
| Godot 4.7.2 headless import + startup | PASS | same run, Godot import job |
| MS-01 movement/camera smoke | PASS | same run; existing regression retained |
| MS-02 cadence, hit damage, partial/empty reload, muzzle obstruction, HUD smoke | PASS | same run, `MS-02 SMOKE PASS: ammo, cadence, damage, reload, cover, HUD` |
| Automated conservative code review | PASS | [Pre-Merge run 41586422543](https://github.com/mishraaditya595/swapshot/actions/runs/41586422543) |
| PR milestone acceptance | EXPECTED FAIL | Milestone intentionally unchecked pending manual gameplay |
| Manual rifle/ADS/pointer lock/camera feel | NOT RUN | Owner Web test required |
| Hosted HTML5 browser export and playtest | NOT RUN | Manual deployment required |
| SHIFT / guard / echo and mission loop | OUT OF SCOPE | MS-03 through MS-06 |

## MS-02 acceptance matrix

| Requirement | Implemented? | Verified? | Notes |
| --- | --- | --- | --- |
| VX-7 automatic hitscan / single cadence owner | Yes | Headless PASS | Camera target ray + muzzle checks |
| ADS, recoil, 24-round ammo, 1.5 s reload | Yes | Ammo/reload PASS; visual ADS NOT RUN | Need browser feel check |
| Damageable targets and VFX/HUD | Yes | Damage/HUD PASS; rendered VFX NOT RUN | Test scene has two targets |
| Prevent shots through nearby cover | Yes | Headless PASS | Narrow blocker leaves camera aim path unobstructed |
| Preserve MS-01 camera/movement | Yes | MS-01 smoke PASS; manual regression NOT RUN | No changes to MS-01 controller scripts |

## Risks and next action

No confirmed P0/P1 regression from executed checks. Browser feedback and pointer-lock handling remain unverified, so keep PR in draft and the milestone partially checked. Owner should manually deploy PR #8 and verify controls and close-cover behavior; then update acceptance evidence and only then mark the milestone complete.
