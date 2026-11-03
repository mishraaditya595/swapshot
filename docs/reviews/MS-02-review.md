# SWAPSHOT MS-02 review — VX-7 rifle and visual aim alignment

**Repository / scope:** `mishraaditya595/swapshot`, `main..feat/ms-02-vx7-rifle`; one implementing [PR #8](https://github.com/mishraaditya595/swapshot/pull/8), milestone MS-02.

**Decision:** **MS-02 acceptance evidence sufficient** for the stated greybox rifle milestone. Browser control/visual feedback is supported by owner-recorded gameplay, and target damage/cover safety and edge cases are supported by engine-level regressions. This is not a claim of a finished/polished shooter. Merge requires fresh CI and pre-merge policy checks.

## Owner Web playtests (November 3, 2026)

1. **Pre-correction:** Owner supplied a ~42-second PR #8 browser recording, confirmed that firing, reloading and right-mouse aiming worked, and reported an obvious yaw mismatch: character visor/weapon remained facing forward when the camera turned. Source revealed a movement-direction-only `VisualRoot` turn and a camera-parented VX-7.
2. **Post-correction:** Owner supplied `Screen Recording 2026-11-03 at 13.58.00.mov` (~46 seconds) showing PR #8 running in a macOS Brave browser, then stated that the rotation logic and firing mechanics look fine and weapon placement is better. Independent frame review observed the character and shoulder-mounted rifle moving together during look rotation, visible muzzle/tracer feedback, the ammo counter decreasing across sustained firing, and traversal of the ramp and nearby crates. No obvious repeat of the old facing mismatch was seen.
3. **Limits:** The second recording does **not** independently prove target damage values, every fire-rate edge case, close-cover no-penetration, reload timing, performance/FPS or all pointer-lock transitions. Those physics/state cases are separately covered by engine tests where applicable. A native graphical Godot editor test was not run. The recordings were user-provided in this conversation; they are not checked into the repository or publicly linked.

## Brainstorming and correction

[Follow-up design](../plans/MS-02-aim-alignment.md) compared body-only rotation, rifle-only reparenting, and a combined visual-body yaw plus character-relative shoulder weapon. The selected combined approach parents VX-7 under `VisualRoot/WeaponPivot`, aligns player visuals to `CameraPivot` yaw during captured mouse-look, matches rifle pitch to `CameraBoom` and leaves the physics body and collision-safe camera independent. Shots still use the camera aim ray, the camera-to-muzzle check and the muzzle-to-target ray.

## Verification matrix

| Requirement / check | Result | Evidence |
| --- | --- | --- |
| Shooting, reload and ADS controls in Web | OWNER PASS | Pre-correction PR #8 browser recording and owner's explicit observations |
| Stationary turning and character/rifle pose in Web | OWNER PASS | New ~46-second PR #8 recording and owner's positive follow-up; no obvious previous mismatch |
| Ammo/tracer/muzzle feedback in Web | OBSERVED | New recording shows counter decrement, tracer/muzzle visual during firing |
| Rifle cadence, 24-round ammo, partial/empty reload and HUD | ENGINE PASS | [CI run 41597083512](https://github.com/mishraaditya595/swapshot/actions/runs/41597083512) |
| Camera yaw, 180-degree rotation, rifle pitch and muzzle forward alignment | ENGINE PASS | Same run, MS-02 smoke |
| Training target health and hitmarker; target death/collider disable | ENGINE PASS | Same run, MS-02 smoke |
| Camera-to-muzzle and muzzle-to-target cover obstruction | ENGINE PASS | Same run, MS-02 close-cover physics regression |
| MS-01 movement, camera clearance and ramp traversal | ENGINE PASS | Same run, existing MS-01 regression |
| Godot 4.7.2 import/startup, Python/static audit and milestone validator | ENGINE PASS (prior to acceptance-doc update) | Same run |
| Manual local editor GUI / exhaustive pointer-lock or FPS check | NOT RUN | Not part of the verified browser-first MS-02 acceptance scope |
| SHIFT, guard AI and complete mission loop | OUT OF SCOPE | Later milestones |

## Findings and follow-up

**Resolved P1 — Rifle and character facing desynchronization.** The original browser evidence and source diagnosed the mismatch. The follow-up code, engine tests and new browser review provide corroborating evidence that the character-relative weapon alignment is acceptable.

**Nonblocking P2 — Visual readability and polish.** The weapon is still a small placeholder mesh and the character can become dark against the arena's low-lit surfaces near the ramp/cover. These do not block the MS-02 mechanical acceptance; richer weapon shape, lighting and animation can be scheduled for later art/polish milestones. There are no rifle audio assets yet; `shot_fired` and `dry_fired` remain hooks.

**Remaining operational gate:** After checking the milestone task list and linking PR #8 in the completion line, verify the latest **SWAPSHOT CI** and **SWAPSHOT Pre-Merge** runs before marking the PR ready or merging. Only the owner should authorize merge; no automatic deployment should occur.
