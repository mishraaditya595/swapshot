# MS-10 Extraction design: Double-Deck Lockdown

**Status:** Approved by owner on November 4, 2026 for implementation.  
**Date:** November 4, 2026  
**Target:** SWAPSHOT, Godot 4.7.2 stable, GDScript, Compatibility renderer, browser-first.  
**Milestone:** MS-10, standalone Extraction section. MS-11 owns the connected three-zone mission.

## Intent

Vex reaches the Helix extraction bay after disabling Security Core. The experimental core sits on a raised gantry above the escape bay. Retrieving it triggers an upper-level security lockdown, followed by a lower-floor interception at the extraction shuttle. The player must change elevation and firing angles, then interact with the exit to finish.

The section should feel like the final encounter in a compact action game. Its planned duration is **3 to 5 minutes**, to be measured in a hosted browser playtest. There is no imposed countdown, scripted camera sequence or requirement to use SHIFT a particular number of times. Walking must always provide a route to the core and back to the exit. SHIFT should make the fighting and escape faster and more tactical.

### Goals and success criteria

- A clear entry, conspicuous core, triggered final fight, extraction objective and replayable victory.
- A distinct upper-to-lower encounter sequence. MS-09 already teaches climbing ramps to shut down an upper terminal; this section reverses the combat flow after the core pickup.
- Four standard Helix troopers in **two bounded groups of two**. Only one group is active at a time. No patrol navigation, dynamic pursuit or unlimited reinforcements.
- Interactions and spawns validated by real physics, with safe recovery when spawn sites are obstructed.
- Reliable death/retry and victory replay. All transient player, SHIFT, enemy, pickup, mission and HUD states reset.
- A playable browser-friendly greybox that reuses industrial assets and existing gameplay scripts.

A successful build does not automatically establish the duration target, enjoyable difficulty or Web acceptance. Those need separate testing.

## Approaches considered

| Approach | Action and SHIFT | Engineering tradeoff | Decision |
| --- | --- | --- | --- |
| Crossfire Bay | Central core on the ground, flanking cover and raised optional positions | Easiest to read; less distinct from previous lateral firefights | Considered, not selected |
| Escape Gauntlet | Retrace a corridor while security activates ahead | Strong forward drive; narrow camera and spawn lanes; fewer interesting SHIFT destinations | Considered, not selected |
| **Double-Deck Lockdown** | Retrieve the core on an upper gantry, clear upper defenders, then fight down toward a lower extraction gate | More vertical camera and collision QA, but better final-act structure | **Selected by owner on November 4, 2026** |

Selection of the approach authorizes preparing this design specification. Gameplay implementation requires a separate approval of the written specification.

## Arena and route

### Spatial model

Use one compact industrial chamber, roughly **34 m wide (X) by 40 m long (Z)**. The south side is the entrance and shuttle floor. A raised north gantry holds the core. The lower floor is at world Y = 0; the upper walking surface is approximately Y = 2.9 m. These values match the established MS-09 elevation scale and stay within SHIFT's 4 m vertical limit when the line of sight is clear.

The proposed coordinate plan is an initial greybox guide, not a license to adjust SHIFT tolerances to suit the art:

| Feature | Proposed location | Purpose |
| --- | --- | --- |
| Player entrance | Lower southwest, near `(-11, 1.03, +16)` | Clear arrival, room to move, core visible ahead |
| Extraction gate | Lower southeast, near `(+11, 1.03, +16)` | Visible locked destination from the beginning |
| West access ramp | West side, rising northward from near `(-11, 0, +10)` | Complete non-SHIFT route to the upper level |
| North gantry | Upper north side, roughly Z = -9 to -16 | Continuous walking route around the core |
| Core pedestal | Upper center, near `(0, 2.9, -12)` | Focus point and pickup interaction |
| East overlook | Upper east, around X = +10 | Long flank, clear downward shooting windows |
| Open lower bay | Center and south, without an overhead slab | Cover, downward SHIFT landings and extraction fight |

The player's center is approximately 1.03 m above the lower floor or 3.93 m above the upper floor. Collision geometry and interaction markers must be positioned using the actual instantiated capsules and meshes; the coordinates above are layout targets.

```text
                          NORTH (Z-)
  +------------------------------------------------+
  |      UPPER NORTH GANTRY / CROSSWALK            |
  |    [upper guard]   [CORE]   [upper guard]       |
  |            ^                  ^                 |
  |   WEST     |      OPEN VIEW   |    EAST         |
  |   RAMP ----+      TO BAY      +-- OVERLOOK     |
  |    /                                           |
  |   /     lower cover       lower cover          |
  |  /                    [lower guard lanes]      |
  |                                                |
  |  ENTRANCE                            EXIT      |
  +------------------------------------------------+
                          SOUTH (Z+)
```

The diagram is schematic, not a collision or navigation map. In the actual scene, a continuous west ramp and connected upper walkway must reach both sides of the core without any teleport. The upper overlook must offer a visible, supportable landing surface with enough room for the player capsule.

### Construction and readability

Build floors, ramp, rails and walls with simple static box geometry and matching colliders, using the deterministic MS-09 builder pattern as a reference. Instance existing `scenes/levels/props/dock_crate.tscn` and `dock_container.tscn` for substantial cover rather than introducing another asset pack. Avoid refactoring MS-09's working geometry just to share a small helper.

Provide at least three distinct cover positions below the gantry and two on or beside the upper walk. Keep the main foot routes approximately 3 m wide and avoid low ceilings where the third-person camera retracts. Use physical rail segments near fall edges, with deliberate openings where a downward SHIFT is meant to be possible. A rail or overhead slab must never be made non-colliding simply to make an invalid teleport work.

Keep the visual language established by Loading Dock and Security Core: dark steel and graphite, cyan core and SHIFT indicators, amber security warning lights. The core remains the most prominent object in the initial sightline. The exit's sign starts amber with **EXTRACTION LOCKED**, and turns cyan with **EXTRACTION READY / E** after combat. Thin floor indicators should have no collider and must not interfere with the SHIFT floor ray.

### Safe SHIFT opportunities

Design and physically test these intended routes:

1. **Ramp to gantry:** From a visible upper ramp approach, place an anchor on a clear upper gantry pad and SHIFT across a corner of the walk.
2. **Upper cross-flank:** Move from west gantry to a visible clear section of the east overlook using a supported upper-floor anchor, within 18 m and without passing through rails or cover.
3. **Overlook to lower cover:** SHIFT downward from a rail opening to an exposed supported floor pad, then engage guards protecting extraction.
4. **Lower reposition:** SHIFT across clear lower cover lanes for the final two guards.

The player may not be able to reach every upper pad from the lower entrance with SHIFT; that is intentional. Test invalid attempts at the underside of the gantry, occluded upper pads, edges, blocked capsules and excessive range. The complete west ramp is the fallback route. Do not require a blind anchor placement to progress.

Preserve `scripts/shift_ability.gd` unchanged unless testing proves a separate regression: 18 m range, 4 m height difference, 40-degree slope tolerance, supported floor probes, sightline, capsule clearance at placement and activation, one anchor, 8-second expiry, 4-second cooldown and 1.5-second echo. Rejected attempts leave position and resources intact.

## Gameplay sequence and state model

| State | Player action and feedback | Exit condition |
| --- | --- | --- |
| `RETRIEVE` | Quiet entrance. HUD says **REACH UPPER GANTRY / RETRIEVE THE CORE**. Core glows cyan and shows **E TAKE CORE** within reach. Exit is amber and locked. | One valid core pickup |
| `UPPER_WARNING` | Core vanishes or goes dark. Brief amber lockdown warning; two upper troopers remain non-colliding and inactive until safe placement. | Valid placement after a short warning, or blocked-entry fail-safe |
| `UPPER_FIGHT` | Defeat upper defenders. Cover, cross-flank and echo distraction can break their sightlines. | Every activated upper trooper is dead |
| `LOWER_WARNING` | Announce lower response with a short warning. Keep extraction locked. | Valid lower activation, or blocked-entry fail-safe |
| `LOWER_FIGHT` | Descend by ramp or safe SHIFT and defeat the guards covering the shuttle approach. | Every activated lower trooper is dead |
| `EXTRACT_READY` | Gate beacon turns cyan. HUD points to the lower southeast extraction marker and **E EXTRACT**. | One valid extraction interaction |
| `VICTORY` | Stop combat. Show **CORE EXTRACTED / OPERATION COMPLETE**, result stats and replay control. | Replay request reloads standalone scene |
| `DEFEAT` | On player death in any active state, disable combat, show **OPERATIVE DOWN** and retry. | Retry request reloads standalone scene |
| `RESTARTING` | One deferred scene reload is scheduled; extra inputs do nothing. | Fresh scene loads in `RETRIEVE` |

There is no mid-scene checkpoint. The standalone section starts at full health and ammunition. Cross-zone inventory, health carry-over, transitions and checkpoints belong to MS-11.

### Core pickup contract

Reuse the validated interaction style from `ms09_security_core.gd`. The core is an in-scene pedestal with a static collider and a visible interaction marker. A call such as `try_collect_core()` must:

- Reject interaction unless the mission is in `RETRIEVE` and the player is alive.
- Require the player to be within approximately **3.0 m** of the interaction marker and on the upper deck; check a vertical difference of about **1.3 m** so the player cannot collect through the gantry floor.
- Raycast from the player toward the marker, excluding the player. Empty sightline or a first hit on the core's own collider may be valid; any wall, crate, floor or intervening collider blocks collection.
- Set `core_collected` before emitting a single pickup signal. Later E inputs never trigger another wave or pickup.
- Hide or dim the core mesh, change the objective and play a short existing-style light/audio pulse. No physical carried item, inventory system or movement penalty.

The player can press E near a locked exit at any time, but doing so displays the current requirement without advancing the mission. The E prompt should appear when near the relevant interaction, while the persistent objective continues to show where to go.

### Two-stage final response

Four existing `scenes/enemies/security_trooper.tscn` instances begin dormant and non-colliding. The upper pair activates only after a valid core pickup. The lower pair activates after the upper stage is fully resolved. Keep each pair's count fixed and separate from other levels. The proposed per-scene starting balance is the MS-09 values (`detection_range = 20.0`, `shot_damage = 8.0`, `fire_interval_seconds = 1.7`), subject to playtest tuning.

- **Upper stage:** One trooper covers the west gantry approach and another the east overlook. Spawn candidates should lie well outside the core interaction radius. These defenders are stationary but can turn, alert, search, shoot through clear lines and react to echoes. Upper cover must stop their shots.
- **Lower stage:** One trooper guards the central lower lane and another covers the southeast extraction approach. They must be positioned so the lower floor and descent lane offer useful angles; a solid upper slab must block any shot through it.

Place candidate pads behind or beside substantial cover so guards appear from identifiable security positions, rather than suddenly in the open center. Aim each stationary trooper's initial facing direction toward the expected approach on its own deck; otherwise the existing field-of-view check can leave it idle during the assault. Verify these angles in an engine test and a hosted playthrough.

Wait roughly **1.5 to 2 seconds** after each phase transition before attempting activation. Signal warning lights and text before enemies become active. Never spawn an attacker within the player's occupied space or directly on the active anchor, echo or a live guard.

### Safe placement and a bounded softlock recovery

Adapt MS-09's `_safe_upper_spawn()` and atomic `_activate_upper()` ideas for both levels, rather than adding pathfinding:

1. Give each guard at least **three authored candidate pads** on the correct floor. The positions are reviewed against the real scene geometry in the engine. Do not use randomized free-space spawning.
2. For each candidate, reject a point within roughly **5 m horizontal distance** of the player (including a player on the other deck), within **2.5 m horizontal distance** of a live SHIFT anchor or echo, or within **2 m** of another selected guard. These are proposed encounter-clearance values, not edits to SHIFT rules.
3. Test the trooper's actual capsule against physics geometry and other colliders. Confirm support below and a sufficiently upward floor normal. Match the intended lower or upper floor height within a small tolerance. Do not spawn in a wall, floor, player, or unsupported air.
4. Select both positions before activating either trooper. If the two-person set is unavailable, keep the pair disabled and retry every approximately **0.25 seconds** while the player can move. Display **HELIX ENTRY BLOCKED / CLEAR THE LANDING AREA** only while relevant.
5. If no safe pair can be found after **8 seconds of activation retries**, terminate that wave as **deployment blocked**, leave both unspawned actors disabled, and advance to the next phase. This is an explicit, bounded last-resort safety rule: it can reduce the challenge but cannot place a guard illegally or trap mission progression. Record the waived wave as a separate state, never as defeated enemies. Manual QA must try to block all candidate pads and confirm that the escape objective eventually advances. Normal intended play should never reach this fallback.

To avoid a race, the phase director alone owns transitions: a guard death handler ignores unknown or already-counted actors; reserve actors cannot take damage while disabled; a death during warning cancels pending activations. No countdown or spawn is allowed after `VICTORY`, `DEFEAT` or `RESTARTING`.

Only guards that actually activated count toward **ENEMIES DEFEATED**. The extraction condition is: core collected, both security stages resolved (cleared or explicitly waived), no activated live guards, and the player still alive. A blocked-entry waiver must be visible in the outcome details so the player does not see a misleading perfect-clear result.

### Extraction interaction and payoff

The extraction gate is visible on the lower southeast side throughout. It becomes active only after the stage conditions above are met. A call such as `try_extract()` checks:

- State is `EXTRACT_READY`; core was collected; both stages are resolved and no activated hostile remains.
- The player is alive, on the lower floor, within approximately **3.0 m** of the gate's interaction marker, and has a clear physical ray to the gate. The gate body itself is an allowed first collider.
- This extraction has never completed before. Set the terminal state before emitting `extraction_completed` and opening the result overlay.

A successful interaction disables the player's combat and SHIFT lifecycle, disables surviving enemies if any, releases the mouse and shows a full-screen result panel with a one-line payoff: **HELIX CORE EXTRACTED. VEX IS CLEAR.** Show elapsed `MM:SS`, enemies actually defeated, successful SHIFT count and whether a deployment was blocked. Avoid a cutscene, camera rail, loading another zone or expensive effects.

## Death, replay, input and HUD

Use `player.managed_restart = true`, the player's `died` signal, and `combat_hud.set_mission_managed(true)` as in MS-08/MS-09. Only the mission controller changes state. On win or death, call `player.set_combat_enabled(false)` and disable all surviving guards. The player controller already clears anchor and echo when combat is disabled.

Enter or the outcome replay button calls one guarded `request_replay()` that changes the phase to `RESTARTING` and schedules `get_tree().call_deferred("reload_current_scene")`. Subsequent E/Enter/button presses have no effect. A fresh instance must restore 100 HP, 24 rounds, correct weapon cooldown/reload state, neutral camera/mouse state, zero SHIFTS, no anchor/echo/cooldown, uncollected core, disabled reserve troopers, locked extraction, cleared warnings and a hidden result overlay. Tests should cover both victory replay and death retry, including death during a wave warning.

Use a mission-specific CanvasLayer for the objective, phase hint, clock and short feedback text. Keep the existing CombatHUD for HP, rifle and threat, and the existing ShiftHUD for anchor/cooldown. Adapt MS-09's bottom-left SHIFT backdrop so labels do not overlap at **960 x 540**. Keep prompts short enough to fit the viewport without horizontal clipping. Colors communicate state, but the on-screen text must still explain LOCKED, TAKE CORE, SECURITY RESPONSE and EXTRACT. Rejected core/exit interactions show a reason for about 2 to 3 seconds. Combat state changes and incoming-fire warnings reuse existing `set_encounter_threat`.

## Proposed implementation boundaries

MS-10 should remain self-contained and use the existing signals/API names discovered in `main`:

| File | Responsibility |
| --- | --- |
| `scenes/levels/extraction.tscn` | Player, four troopers, core pedestal, gate, lights, HUD, result overlay and cover instances |
| `scripts/ms10_extraction.gd` | Scene-local geometry, state machine, validated E interactions, safe staged activation, waiver, results and retry |
| `tests/ms10_extraction_smoke.gd` | Real Godot physics and state smoke tests, bounded by an explicit watchdog |
| `tests/MS-10-BROWSER-QA.md` | Hosted gameplay worksheet with actual timestamps, observed difficulty and Web checks |
| `.github/workflows/ci.yml` | Run MS-10 smoke in the existing Godot 4.7.2 job, with timeout and error detection |
| `scenes/main.tscn` | May point temporarily to Extraction for focused preview; preserve direct play of MS-08/MS-09 and adjust existing preview assertions |
| `docs/MILESTONES.md` | Keep MS-10 unchecked until verified; link the actual MS-10 PR once opened |
| `docs/reviews/MS-10-review.md` | Critical review with evidence and remaining risks after implementation |

Do not add a global mission manager, new weapon, enemy archetype, inventory system, physics carry object, moving elevator or cross-zone transition. Prefer the existing trooper `destroyed`, `windup_started`, `state_changed`, `echo_distracted` and `echo_released` signals; the SHIFT `shifted`, `placement_rejected` and `shift_rejected` signals; and the existing `apply_damage()`, `set_combat_enabled()` and `reset_lifecycle()` methods. Avoid changing shared scripts unless a failing regression demonstrates a specific need.

## Verification and failure cases

### Real Godot smoke

The dedicated MS-10 smoke must exercise these cases, with an internal watchdog and a CI process timeout:

1. Extraction resource loads; player has a physically supported start, full health, full magazine and no pre-armed anchor.
2. Initial mission objective, core, amber locked gate and hidden result are correct.
3. Core E is rejected remotely, from below the deck and through inserted solid cover.
4. The core can be collected once from a near, unobstructed upper position. Duplicate calls emit no extra pickup or wave.
5. Upper stage is requested only after pickup, with exactly two configured guards and a finite warning.
6. Activated guards have supported, non-overlapping floor/capsule positions, face an intended player approach and exclude player, anchor, echo and each other.
7. All-blocked candidate positions trigger retries and eventually the documented waiver, not a hang or collision overlap.
8. Existing SHIFT checks accept the authored ramp, upper cross-flank and lower drop when genuinely visible, and reject occluded, unsafe, distant and occupied landings without consuming the device.
9. Camera-to-muzzle shots and guard eye/muzzle rays stop at real gantry floor, rail and cover colliders.
10. Dead guards stop attacking and duplicate destroyed callbacks cannot increment defeat totals twice.
11. Upper stage resolution starts lower response; exit stays locked through all warnings and active combat.
12. Lower response resolves after genuine defeats or an explicit waiver; a live activated guard always blocks extraction.
13. Early, distant, behind-cover, upper-floor and repeated extraction interactions are rejected; one valid lower-floor E completes exactly once.
14. Victory stops combat and displays accurate time, actual kills, SHIFT count and any waiver.
15. Player death, including death during a warning, produces defeat with no subsequent spawn.
16. Victory replay and death retry restore all mission, player, rifle, SHIFT, guard, core, gate and HUD state; duplicate restart inputs cause only one reload.
17. At 960 x 540, important mission, SHIFT and ammunition labels do not collide.
18. `scenes/main.tscn` preview points to the intended section without breaking standalone Loading Dock and Security Core loading.

Run existing MS-01 through MS-09 Godot smoke tests as regressions, alongside project audit, Python test suites, milestone validation, Godot resource import and startup. Engine smoke establishes state and physical safety, not shooting feel or browser performance.

### Hosted browser QA

Use a deployed Extraction build in a real browser. Record build SHA, browser/OS, viewport, elapsed clear time, remaining HP, SHIFT count and observed FPS. Test both west-ramp traversal and upper camera movement; readable core and exit signs; safe SHIFT on both levels; a blocked SHIFT attempt; core pickup; warnings and spawn fairness; upper/lower fight difficulty; cover and echo distraction; extraction; death/retry; victory replay; pointer capture and focus recovery; audio; console errors and frame pacing. Repeat the encounter enough to look for difficulty spikes and permanently blocked entry sites. Mark unavailable checks `NOT RUN`, never `PASS` by inference.

### Risks and mitigations

| Risk | Mitigation or test |
| --- | --- |
| Looks like another Security Core catwalk | Put the core on the upper level, reverse combat direction toward the lower exit, show the extraction destination from the start |
| Camera occlusion beneath gantry or near rail | Keep open center, broad lanes and clear camera retreat; test in the hosted build before adding detail |
| Upper floor blocks intended SHIFT | Author visible upper landing pads along ramp/gantry; use real physics tests; keep a walking route |
| Unfair enemy materialization | Delayed warning, candidate selection, horizontal separation and real shape/support checks |
| Spawn sites all blocked, mission softlocks | Retry at fixed cadence, then explicit deployment-blocked waiver after 8 seconds; never place an unsafe trooper |
| Fight ends too quickly or becomes frustrating | Two groups with only two active at once, existing tuning as starting point, adjust from timed browser playtests |
| Ambiguous exit or core interaction | Prominent color plus text, interaction marker, height/range/ray validation and rejection feedback |
| HUD clipped at 960 x 540 | Dedicated layout assertions and manual low-resolution check |
| MS-10 acceptance blocked by predecessors | Preserve unchecked MS-07 through MS-09 tasks and open issues; seek separate governance approval if needed |

## Milestone and governance boundary

After this written design receives explicit approval, create the implementation plan at `docs/plans/2026-11-04-ms10-extraction.md`, then work on `feat/ms-10-extraction` with focused commits and a draft PR. The PR title must identify MS-10, its body must include `**Milestone:** MS-10`, `## Acceptance evidence`, `## Verification evidence` and `## Review findings`, and its tracker update must use the real PR number.

The November 4, 2026 POC deferral permits only the named MS-09 PR (#20); it does not authorize checking unfinished MS-07/MS-09 acceptance or bypassing MS-10 pre-merge policy. If predecessors block the PR's acceptance check, leave the MS-10 PR in draft and request an explicit, separately reviewed governance decision. Do not change the checker to obtain a passing result. Do not merge automatically.

## Deferred from MS-10

MS-11 will integrate Loading Dock, Security Core and Extraction, including cross-zone transitions and checkpoints. MS-12 can refine art, animation, music and combat effects. MS-13/14 handle broader UX and hosted Web release requirements. Turrets, mobile controls, new enemies, elaborate scripted chase sequences, moving lift platforms, cinematic cutscenes, additional weapons, carried-object physics and a style scoring system are outside the approved milestone objectives.

**Design approval:** Owner approved the written specification and authorized implementation on November 4, 2026.