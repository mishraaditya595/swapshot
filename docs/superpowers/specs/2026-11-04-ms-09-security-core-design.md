# MS-09 Security Core design: Looped Mezzanine

**Approved:** November 4, 2026. The owner selected Approach A and authorized implementation.
**Scope:** Standalone, replayable Security Core section for Godot 4.7.2 (GDScript, Compatibility, Web-first).

## Intent and constraints

Build a readable 3–4-minute third-person tactical section in which Vex uses rifle fire, cover, ramps and safe elevated SHIFT positions to shut down the Helix Security Core. Duration is a playtest target, not a timer. Reuse the existing player, VX-7, SHIFT, Helix trooper, HUD and industrial kit. No turret, new weapon, pathfinding framework, jumping system, multi-zone integration or expensive assets.

## Approaches considered

| Approach | Gameplay | Effort and risk | Decision |
| --- | --- | --- | --- |
| A. Looped Mezzanine | Lower encounter, wide ramps, two connected elevated flanks and terminal | Low-medium effort; readable and Web-friendly | **Selected** |
| B. Twin Balconies | Opposing upper firing positions and exposed cross-gap SHIFTS | More aiming, camera and landing risk | Not selected |
| C. Reactor Tower | Several stacked rings around a reactor | Higher collision, camera and performance risk | Deferred |

## Player flow and space

The player starts on clear lower ground in a south-to-north industrial chamber. Two Helix guards guard the lower lanes behind physical cover. East and west ramps climb to an approximately 2.9 m upper level, which connects an east overlook to a north walk and a west terminal deck. No route requires SHIFT. The player can reach a higher position using the ramps, SHIFT across an upper overlook where the destination is visible, and fall back to lower cover. Cyan cues distinguish useful landings; amber signals show active threats.

The 0.36 m player capsule and third-person camera require wide walking lanes (target 3 m), clear overhead routes and guardrails with collision. Reuse crate geometry; heavy cover must occlude both enemy and rifle traces. Keep the geometry cheap and avoid visual obstructions around the terminal.

### Safe SHIFT

Keep the current 18 m range, 4 m elevation difference, 8 s anchor, 4 s cooldown, 1.5 s echo, one-anchor rule, floor slope, line-of-sight, five-point support, capsule clearance and activation-time revalidation. A surface below an overhead slab is **not** a valid upward landing simply because it is close: the placement ray must see the landing floor. Guaranteed upper SHIFT positions are arranged at the ramp approach and between visible upper walkways. Test a downward escape from an overlook. Failed SHIFTS must not move the player or consume cooldown; no relaxation of safety invariants.

## Combat and objective

Four existing stationary Helix troopers form two phases, with two initially active. On both lower guard deaths, announce an upper response and activate the upper pair once their candidate spawn positions pass real player/anchor/echo separation, floor support and collision checks. Try several preselected upper spawn positions. If none are safe, leave them disabled, show an unobtrusive message and retry; never overlap the player or land an enemy on an armed anchor. Upper guards cover the ramp/overlook and console approach. They may turn, attack, search and react to an echo; they do not navigate.

After four unique guard deaths, a security terminal on the upper west deck changes from amber to cyan. Press E near the console, at approximately the same elevation and with unobstructed interaction to disable it. Early, distant, below-floor, blocked and post-completion interactions are rejected without changing state. A successful shutdown happens once, freezes combat and shows a result with guards, elapsed time and SHIFTS.

Death displays a defeat panel. Enter or the replay button initiates one deferred reload of the standalone Security Core scene. The entrance is the local checkpoint; fresh replay restores health, ammo, enemies, reserve state, HUD, anchors, echo, cooldown and terminal. MS-11 owns cross-zone progression. During MS-09, `scenes/main.tscn` may point at Security Core for hosted preview, while Loading Dock stays directly runnable.

## Technical boundaries

- `scenes/levels/security_core.tscn`: player, four guard instances, terminal, light, HUD, outcome.
- `scripts/ms09_security_core.gd`: deterministic low-poly collision greybox, staged combat, safe upper spawn selection, terminal validation and replay.
- `tests/ms09_security_core_smoke.gd`: real Godot scene/physics tests, including SHIFT and sightline checks, terminal state, death and replay.
- `.github/workflows/ci.yml`: MS-09 smoke alongside existing MS-01 through MS-08 checks.

Touch shared gameplay systems only to correct a verified cross-elevation regression. No global mission autoload is needed.

## Acceptance

Use project audit, Python tests, milestone validator, engine import/startup, MS-01 through MS-09 Godot smoke suites, code review and the real GitHub Actions outputs. Manual QA covers two-way ramp travel, camera comfort, safe tactical SHIFT, enemy occlusion and echo, terminal clarity, both result paths, actual duration and hosted browser performance, audio, pointer capture and console. Passing headless checks does not prove browser acceptance.

MS-07 and MS-08 formal acceptance remains deferred under [issue #19](https://github.com/mishraaditya595/swapshot/issues/19). Do not alter their checkboxes or pre-merge policy in MS-09. A policy failure is a blocker, not evidence that those tests ran.
