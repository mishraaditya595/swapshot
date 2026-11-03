# SWAPSHOT — delivery milestones and PR tracker

**Single source of truth:** This checklist tracks all SWAPSHOT development from the first gameplay GDScript to the published GitHub Game Off 2026 entry. The foundation in **MS-00** is already merged in [PR #1](https://github.com/mishraaditya595/swapshot/pull/1). This document and its tracking rules are introduced by a separate planning PR; that PR does not count as a gameplay milestone.

**PR policy:** **one milestone = one implementing pull request**. Do not combine milestone IDs in a gameplay PR, do not silently skip a milestone, and do not mark something complete merely because a branch, PR or CI run exists. Dates are planning targets, not verified delivery dates; downstream timing may change when playtests reveal problems.

## How coding agents must update this document

1. Read AGENTS.md, CLAUDE.md (for Claude Code), GAME_DESIGN.md, and this file **before writing gameplay code**. Choose the earliest unfinished milestone unless the owner explicitly changes order.
2. Start a new branch and PR for exactly one milestone. In the PR body name the ID (MS-01 etc.) and include all its acceptance criteria and evidence. Keep unrelated changes out.
3. Tick each **nested task** only when that task is implemented **and verified**. If a check requires human/editor/browser testing, leave the task unchecked until that evidence is actually available; record gaps in the PR.
4. When every nested task and the acceptance gate are satisfied, update this same document **in the implementing PR**: change the milestone line to [x], mark its tasks [x], and replace the PR placeholder with a real link such as [#17](https://github.com/mishraaditya595/swapshot/pull/17). Agents should create the PR first, then push a follow-up tracker update after the number is known.
5. The implementing PR must include the tracker update, verification evidence, and review findings. The owner merges only after checks/review. If the PR is rejected, closed unmerged or blocked, undo its completed mark in the next corrective PR; a completed milestone on main must correspond to delivered work.
6. If scope changes, change the milestone and explain why **in a reviewed PR**, preserving completed IDs and their historical PR links. Optional/deferred items must be explicitly labelled; do not claim them completed.
7. The CI tracker validator enforces stable IDs, task checkboxes, and a real PR link for completed milestones; it cannot prove the gameplay or external submission works. Manual checks still apply.

**Completion semantics:** An unchecked task is unfinished or lacks evidence. A checked nested task means implemented + verified. A checked milestone means every nested task is checked, its acceptance gate is met, and an implementing PR is linked. Do not mark release milestones done based only on a successful build.

## Roadmap

### MS-00 — Repository bootstrap (already delivered)

- [x] **MS-00 complete** — **Implementing PR:** [#1](https://github.com/mishraaditya595/swapshot/pull/1)
  - [x] Initialize the Godot project, folder structure, repository docs and CI.
  - [x] Install agent instructions and the four project skills.
  - [x] Confirm Godot headless import and audit tests pass.

**Acceptance evidence:** [Merged bootstrap PR #1](https://github.com/mishraaditya595/swapshot/pull/1) and its successful CI run. **No gameplay was implemented by MS-00.**

### MS-01 — Gameplay foundation: movement, camera and greybox arena

**Target:** Nov 2–3, 2026 · **Priority:** P0 · **Depends on:** MS-00 (unless explicitly reordered)

- [x] **MS-01 complete** — **Implementing PR:** [#4](https://github.com/mishraaditya595/swapshot/pull/4)
  - [x] Create the first gameplay scripts and reusable player scene using CharacterBody3D.
  - [x] Add camera-relative WASD movement, jump or traversal only if scope allows, collision, and basic acceleration/turning.
  - [x] Implement mouse-look, over-the-shoulder camera rig, clamped pitch and basic camera-wall collision.
  - [x] Create the small greybox training arena with walls, cover, and an elevated landing area.
  - [x] Define InputMap actions and a clear mouse-capture / release flow.
  - [x] Verify **hosted Web gameplay startup**, controllability, collision and camera behavior with a recorded manual test (owner-approved Web-first acceptance instead of native editor GUI).

**MS-01 verification:** [Godot 4.7.2 physics/import CI](https://github.com/mishraaditya595/swapshot/actions/runs/41582463772) passed movement, camera clearance/recovery, wall/crate collisions, ramp ascent/descent and avatar close-camera fade. The [manual Web deployment](https://github.com/mishraaditya595/swapshot/actions/runs/41582737996) published PR #4 revision `cc0f6f152c3675ee3df996900f96c67dac9df4b7`. On November 3 the owner supplied a macOS browser screen recording showing WASD, mouse-look and near-obstacle traversal; subsequent confirmations verified Escape mouse release, Command+Tab app focus switching and backward/sideways movement after head-on wall/crate contact. See the [recorded MS-01 QA and review findings](reviews/MS-01-review.md). Native Godot editor GUI was **not** manually tested; this scope adjustment reflects the owner's browser-only QA requirement. A minor close-platform dark-surface occlusion is deferred as nonblocking polish. Later milestones still require separate final Web/release testing.

**Acceptance gate:** A human can run a scene, move and look around without falling through the floor or camera clipping into walls. All checks and unrun manual tests documented.

### MS-02 — Rifle: shooting, aiming, damage and reload

**Target:** Nov 4, 2026 · **Priority:** P0 · **Depends on:** MS-01 (unless explicitly reordered)

- [x] **MS-02 complete** — **Implementing PR:** [#8](https://github.com/mishraaditya595/swapshot/pull/8)
  - [x] Add VX-7 rifle scene and reusable hitscan weapon logic with a single source of fire-rate state.
  - [x] Implement aim / ADS, 24-round magazine, reload, recoil and ammo handling.
  - [x] Add damageable target(s), hit effects, crosshair feedback and minimal muzzle feedback.
  - [x] Block camera-origin shots obstructed at the muzzle by nearby cover.
  - [x] Add source-level or in-engine tests for fire-rate, reload, empty-magazine and obstruction edge cases.

**Manual Web acceptance (Nov 3, owner-recorded, PR #8):** The first browser recording confirmed shooting, reloading and ADS inputs, but identified a mismatch between camera turns and character/weapon facing. After the follow-up [aim-alignment correction](plans/MS-02-aim-alignment.md), the owner supplied a new ~46-second recording (`Screen Recording 2026-11-03 at 13.58.00.mov`) of the PR #8 browser preview and confirmed the rotation/firing mechanics feel correct and the shoulder-mounted placement is an improvement. Review of the footage shows the character and rifle staying together across camera turning, movement and ramp/cover traversal, plus visible firing feedback and ammo consumption. This is a browser playtest, **not** a native Godot editor GUI test. Some dark surfaces near the ramp and the small placeholder gun remain nonblocking visual polish.

**Godot/CI verification (Nov 3):** [SWAPSHOT CI run 41597083512](https://github.com/mishraaditya595/swapshot/actions/runs/41597083512) passed Godot 4.7.2 headless import/startup, MS-01 movement/camera regression, MS-02 smoke (`aim alignment, ammo, cadence, damage, reload, cover, HUD`), static audit, Python tests and milestone tracker validation. Close-wall no-penetration, target damage, reload edge cases and fire cadence are verified programmatically; the owner footage does not independently prove every edge case. See [MS-02 review](reviews/MS-02-review.md) for evidence boundaries.

**Acceptance gate:** The player can aim, shoot, reload and damage a target; close-wall shots cannot penetrate cover. **Met** through the owner's two-stage Web playtest plus Godot physics regression. The implementing PR must still pass fresh pre-merge checks and be merged to deliver MS-02 to `main`.

### MS-03 — SHIFT core: placement and safe teleport

**Target:** Nov 5, 2026 · **Priority:** P0 · **Depends on:** MS-02 (unless explicitly reordered)

- [x] **MS-03 complete** — **Implementing PR:** [#11](https://github.com/mishraaditya595/swapshot/pull/11)
  - [x] Implement an 18 m target-range holographic anchor preview and placement raycast.
  - [x] Reject invalid surface slope, obstruction, height, unsafe floor and out-of-range destinations.
  - [x] Validate full player-capsule clearance when placing and again immediately before activation.
  - [x] Teleport without camera snapping, movement softlock, or collision penetration; handle velocity safely.
  - [x] Ensure failed teleports do not consume an anchor, cooldown or player health; add edge-case tests.

**Acceptance gate:** A reachable landing can be used repeatedly; occupied/blocked/unsafe landings are rejected at placement AND activation with no resource cost. **Met** through the owner's November 3, 2026 deployed-game playtest confirmation that SHIFT mechanics look fine, together with [Godot 4.7.2 regression and CI evidence](https://github.com/mishraaditya595/swapshot/actions/runs/41617064284). The engine smoke tests exercise range, slope, unsupported floor, capsule clearance, changed obstacles, retries, preserved camera orientation, reset velocity and the fixed-world anchor marker. The owner gave an overall positive playtest result without enumerating each edge case, so edge-case coverage is attributed to the automated tests. Post-SHIFT cooldown, anchor expiry, echo, and related state handling remain MS-04. The revised preview hub has not been visually accepted separately.

### MS-04 — SHIFT lifecycle: cooldown, decoy echo and feedback

**Target:** Nov 6, 2026 · **Priority:** P0 · **Depends on:** MS-03 (unless explicitly reordered)

- [x] **MS-04 complete** — **Implementing PR:** [#12](https://github.com/mishraaditya595/swapshot/pull/12)
  - [x] Implement a single active anchor, eight-second expiry and a four-second post-SHIFT cooldown (tunable).
  - [x] Spawn a 1.5-second holographic echo after successful teleport; dispose it reliably.
  - [x] Emit clear state signals for the HUD and future enemy AI; add simple SHIFT visuals / audio cues.
  - [x] Handle Q/Shift spam, death, pause, scene reload and expiry/activation race conditions.
  - [x] Add tests for expiry, cooldown, repeat inputs, resource consumption and echo lifetime.

**Acceptance gate:** SHIFT state stays deterministic across success, rejection, expiry and reload; the echo ends on time and never leaks. **Met for MS-04 on Nov 3, 2026:** The owner reported that the current gameplay "is working fine" after discussing SHIFT audio, and asked to complete milestone bookkeeping. This is an overall gameplay acceptance report, not a separate recording or item-by-item manual verification of every expiry, collision and echo edge case. [Godot 4.7.2 CI run 41622208294](https://github.com/mishraaditya595/swapshot/actions/runs/41622208294) passed the MS-01–MS-04 smoke tests, headless startup and static checks, covering expiry/cooldown, rejection, repeated input, signals, pause, reload and echo lifetime/cleanup. The preview HUD, visual echo and generated anchor/SHIFT cues are implemented; no specific browser device/build identifier or sound-level measurements were supplied. Enemy reaction to the echo remains MS-05, health/death integration MS-06, and full sound/visual polish MS-12. Fresh PR checks remain required before merge; the acceptance of this milestone does not itself merge PR #12.

### MS-05 — One hostile: trooper AI and firefight

**Target:** Nov 7, 2026 · **Priority:** P0 · **Depends on:** MS-04 (unless explicitly reordered)

- [x] **MS-05 complete** — **Implementing PR:** [#13](https://github.com/mishraaditya595/swapshot/pull/13)
  - [x] Create a modular security trooper scene, damage / death responses and readable silhouettes.
  - [x] Implement explicit idle, alert, attack and dead states with line-of-sight checks.
  - [x] Give the enemy telegraphed fire, rate-limited damage and simple cover-aware repositioning if feasible.
  - [x] React to nearby SHIFT echoes without targeting expired echoes or attacking after death.
  - [x] Stage a short encounter with one or two guards and verify no shots through walls.

**Acceptance gate:** An enemy detects, engages, reacts to SHIFT/echo and can be defeated; enemy attacks cease immediately on death. **Met on Nov 3, 2026:** The owner approved the 71-second Brave/macOS PR #13 gameplay recording after reviewing the final camera fade, cover/search behavior, encounter HUD and defeat banner. The earlier 49-second recording showed SHIFT echo distraction and reacquisition twice. Headless physics smoke tests check walls, timed attacks, echo cleanup and post-death attack cancellation. Full death/restart UX, sound-level measurements and FPS profiling remain separate MS-06/MS-14 work; they were not claimed as tested in the recordings. See [MS-05 review](reviews/MS-05-review.md) and [the passing pre-acceptance CI](https://github.com/mishraaditya595/swapshot/actions/runs/41641206280).

### MS-06 — Complete P0 gameplay loop: health, HUD, victory and restart

**Target:** Nov 8–9, 2026 · **Priority:** P0 · **Depends on:** MS-05 (unless explicitly reordered)

- [x] **MS-06 complete** — **Implementing PR:** [#14](https://github.com/mishraaditya595/swapshot/pull/14)
  - [x] Implement 100-HP player damage, death and safe respawn/restart behavior.
  - [x] Add health, magazine, anchor timer, SHIFT cooldown and objective HUD.
  - [x] Implement an explicit encounter objective, win state and restart / retry affordance.
  - [x] Wire enemy death and player death into mission state without stale signals or softlocks.
  - [x] Play an end-to-end greybox encounter: move → shoot → anchor → SHIFT → eliminate → win/retry.
  - [x] Fix any P0 blockers and record measured playtest results in the PR.

**MS-06 verification (Nov 3, 2026):** Initial [GitHub Actions run 41645861386](https://github.com/mishraaditya595/swapshot/actions/runs/41645861386) passed Godot 4.7.2 import/startup and MS-01–MS-06 headless smoke, including full scene replay after victory and defeat. Static audit, Python unit tests and tracker validation passed. See [MS-06 review](reviews/MS-06-review.md) for the evidence boundary. On Nov 3 the owner supplied a 97.6-second Brave/macOS recording of the hosted PR #14 preview. The clip begins during an attempt that ends in defeat at mission time 01:09 (1/3 guards, 1 SHIFT), followed by a fresh retry. The second attempt ends in victory at 00:50 (3/3 guards, 3 SHIFTS, 84/100 HP). The clip demonstrates an actual browser launch, combat, SHIFT use, objective progress, death/retry and victory. It does not show replay after victory, invalid SHIFT landing, measured FPS, or audio. The winning run is shorter than the two-minute pacing target, and owner acceptance was not explicitly given. MS-06 remains unchecked; the PR milestone gate should remain red until outstanding checks and acceptance are documented.

**Follow-up tuning (Nov 3, 2026):** The owner approved extending the short recorded win. PR #14 now has two waves of three guards, a four-second reinforcement warning, checked entry clearance, and enlarged health, ammo, objective, SHIFT and result text. [Godot 4.7.2 CI run 41656292272](https://github.com/mishraaditya595/swapshot/actions/runs/41656292272) passed import/startup, MS-01–MS-06 smoke (including safe spawn, pause, death during wave countdown and replay), static audit, Python tests and milestone tracker validation. A subsequent 136.75-second Brave/macOS screen recording demonstrates the revised two-wave browser build: first patrol 3/6, reinforcement warning, Wave 2, and victory at mission time 02:25 with 6/6 guards defeated, six SHIFTS and 4/100 armor remaining. The earlier recording shows death/retry in the browser, and Godot smoke covers both replay paths and SHIFT/spawn safety. On November 3 the owner explicitly accepted merging MS-06. Victory-to-replay and browser FPS/audio were not shown, but no observed P0 progression blocker remains. Armor recovery and Wave 2 difficulty are deferred to [issue #15](https://github.com/mishraaditya595/swapshot/issues/15).

**Acceptance gate (owner accepted Nov 3, 2026):** A hosted six-guard firefight reached victory at 02:25 with six SHIFTS. The owner accepted the P0 milestone after reviewing gameplay recordings. The earlier browser death/retry and CI-backed victory/death replay tests supplement the new win. Unrecorded edge cases remain documented in the review; armor changes are explicitly deferred.

### MS-07 — P0 vertical slice: responsiveness and go/no-go gate

**Target:** Nov 10, 2026 · **Priority:** P0 · **Depends on:** MS-06 (unless explicitly reordered)

- [ ] **MS-07 complete** — **Implementing PR:** [#16](https://github.com/mishraaditya595/swapshot/pull/16)
  - [ ] Playtest camera feel, aiming, fire cadence, movement friction and SHIFT responsiveness.
  - [ ] Tune key values from observed play rather than assumed timings; capture changes in docs.
  - [ ] Reproduce and resolve remaining P0/P1 combat/SHIFT regressions from MS-01 through MS-06.
  - [ ] Add restart and boundary/corner-case regression coverage for the complete encounter.
  - [ ] Document go/no-go decision for expanding into 3 zones; cut scope if the firefight is not fun.

**Acceptance gate:** A complete P0 slice has no known progression blockers, reliably passes validation, and has explicit human feedback before expanding the mission.

**MS-07 evidence status (Nov 3):** [Draft PR #16](https://github.com/mishraaditya595/swapshot/pull/16) adds a SHIFT-echo spawn exclusion, targeted Godot regressions, [playtest worksheet](../tests/MS-07-BROWSER-QA.md) and [review/Go-No-Go report](reviews/MS-07-review.md). Automated checks and the current Web playtest must be recorded before any tasks or the milestone are checked. **Decision: HOLD** on expanding into three zones until human gameplay feedback and the P0 safety gate are satisfied. The prior MS-06 4-HP win is a tuning lead, not new MS-07 evidence; follow [issue #15](https://github.com/mishraaditya595/swapshot/issues/15) for repeat-run difficulty analysis.

### MS-08 — Loading Dock: onboarding and first mission section

**Target:** Nov 11–13, 2026 · **Priority:** P1 · **Depends on:** MS-07 (unless explicitly reordered)

- [ ] **MS-08 complete** — **Implementing PR:** [#17](https://github.com/mishraaditya595/swapshot/pull/17)
  - [ ] Greybox the Loading Dock with reusable containers, cover and tactical flanking lanes.
  - [ ] Teach movement, aim, anchor deployment and SHIFT through concise contextual prompts.
  - [ ] Stage a 2–3-minute opening encounter with distinct SHIFT opportunities.
  - [ ] Add a readable completion gate and transition to the next zone.
  - [ ] Playtest new-player clarity, encounter pacing, spawn safety and cover integrity.

**Acceptance gate:** A new player can understand SHIFT and clear the opening section without external instruction.

**MS-08 work-order exception (Nov 3):** The owner explicitly authorized implementation of MS-08 while MS-07 remains unchecked with a HOLD decision. [Draft PR #17](https://github.com/mishraaditya595/swapshot/pull/17) contains the implementation for review. The exception does not complete MS-07 or waive MS-08's hosted new-player browser acceptance. Tasks remain unchecked until their respective verification evidence is recorded; see [MS-08 review](reviews/MS-08-review.md) and [browser worksheet](../tests/MS-08-BROWSER-QA.md).

### MS-09 — Security Core: vertical combat and terminal objective

**Target:** Nov 14–17, 2026 · **Priority:** P1 · **Depends on:** MS-08 (unless explicitly reordered)

- [ ] **MS-09 complete** — **Implementing PR:** —
  - [ ] Build a readable vertical zone with catwalks, cover, safe landing surfaces and limited active enemies.
  - [ ] Introduce tactical elevation where SHIFT provides better sightlines but not unfair teleport shortcuts.
  - [ ] Implement the terminal disable / interaction objective with clear progress and feedback.
  - [ ] Ensure enemy AI, collision checks and re-entry/checkpoint behavior work across vertical geometry.
  - [ ] Playtest the 3–4-minute section; defer the optional turret unless time remains.

**Acceptance gate:** The terminal can be reached and disabled through a stable encounter that rewards SHIFT flanks and respects collision safety.

### MS-10 — Extraction: final assault, core pickup and escape

**Target:** Nov 18–20, 2026 · **Priority:** P1 · **Depends on:** MS-09 (unless explicitly reordered)

- [ ] **MS-10 complete** — **Implementing PR:** —
  - [ ] Build the extraction arena using reusable industrial geometry.
  - [ ] Implement experimental core pickup, final triggered fight and extraction objective.
  - [ ] Add bounded enemy waves or a fixed encounter that cannot softlock the mission.
  - [ ] Provide clear victory messaging and a short payoff without a large cinematic pipeline.
  - [ ] Playtest final section for difficulty spikes, spawn logic and pacing.

**Acceptance gate:** The last mission segment has a clear start, challenge, end and replayable success state.

### MS-11 — Mission integration: checkpoints, flow and replay

**Target:** Nov 21–22, 2026 · **Priority:** P1 · **Depends on:** MS-10 (unless explicitly reordered)

- [ ] **MS-11 complete** — **Implementing PR:** —
  - [ ] Connect Loading Dock, Security Core and Extraction into a coherent 8–12-minute run.
  - [ ] Implement checkpoint transitions and recoverable respawns without duplicating enemies/objectives.
  - [ ] Add short intro, mission indicators and concise ending.
  - [ ] Introduce lightweight style scoring only if it is low risk and valuable.
  - [ ] Test a full mission pass, failure at each checkpoint and restart from the beginning.
  - [ ] Freeze mission content and document remaining out-of-scope ideas.

**Acceptance gate:** A full run completes without progression blockers; each checkpoint recovers cleanly and content is frozen for polish.

### MS-12 — Art, animation, audio and combat/SHIFT feel

**Target:** Nov 23–25, 2026 · **Priority:** P1 · **Depends on:** MS-11 (unless explicitly reordered)

- [ ] **MS-12 complete** — **Implementing PR:** —
  - [ ] Unify low-poly industrial kit, graphite/steel palette, cyan SHIFT and amber danger language.
  - [ ] Replace distracting placeholders with license-verified modular assets and record attribution.
  - [ ] Improve hit reactions, basic locomotion/aim animations and visual readability.
  - [ ] Polish gunfire, impacts, SHIFT/echo effects and sound levels without overwhelming browser FPS.
  - [ ] Profile representative scenes and remove costly or unreadable effects.

**Acceptance gate:** The entire mission has coherent visuals and clear combat cues, with a maintained asset credit/license list.

### MS-13 — Player experience: menus, onboarding and accessibility

**Target:** Nov 26–27, 2026 · **Priority:** P1 · **Depends on:** MS-12 (unless explicitly reordered)

- [ ] **MS-13 complete** — **Implementing PR:** —
  - [ ] Build title, pause, restart and victory/death screens with reliable focus and input capture.
  - [ ] Provide readable controls, objectives, SHIFT status and minimal audio/video options.
  - [ ] Improve contrast, HUD scale or legibility, feedback timing and concise instructions.
  - [ ] Test pause/resume, window focus, restart and mouse capture on target devices.
  - [ ] Document keyboard/mouse support and explicitly defer controller support unless proven feasible.

**Acceptance gate:** A new player can launch, understand controls, complete the mission and restart without getting stuck in UI.

### MS-14 — Web build: export, hosted compatibility and performance

**Target:** Nov 28, 2026 · **Priority:** Release · **Depends on:** MS-13 (unless explicitly reordered)

- [ ] **MS-14 complete** — **Implementing PR:** —
  - [ ] Configure a working Godot Web export preset with Compatibility-friendly settings.
  - [ ] Produce an HTML5 ZIP with index.html at its root and test loading on itch.io draft/unlisted page.
  - [ ] Test mouse pointer lock, keyboard input, audio startup, focus changes and fullscreen.
  - [ ] Measure loading footprint, FPS/frame pacing on an ordinary laptop browser and fix regressions.
  - [ ] Run the release static audit and document tested Godot/build/browser versions.

**Acceptance gate:** The exact uploaded HTML5 artifact is playable end-to-end in at least one real target browser; a successful editor build alone is insufficient.

### MS-15 — Release candidate: critical fixes, verification and media

**Target:** Nov 29, 2026 · **Priority:** Release · **Depends on:** MS-14 (unless explicitly reordered)

- [ ] **MS-15 complete** — **Implementing PR:** —
  - [ ] Run the complete manual regression matrix for movement, combat, SHIFT and objectives.
  - [ ] Fix all P0 and feasible P1 defects; record explicitly deferred nonblocking issues.
  - [ ] Run static checks, audit unit tests, Godot import and full Web export against the release candidate.
  - [ ] Capture screenshots, a short gameplay clip and a clear itch.io description.
  - [ ] Record approved license/asset/AI-use attributions and tag a tested candidate commit.

**Acceptance gate:** A release candidate has fresh verification evidence, no known game-breaking defects and distribution materials ready.

### MS-16 — Publish, submit and verify GitHub Game Off entry

**Target:** Nov 30–Dec 1, 2026 · **Priority:** Release · **Depends on:** MS-15 (unless explicitly reordered)

- [ ] **MS-16 complete** — **Implementing PR:** —
  - [ ] Build the final artifact from the reviewed commit and upload it to the itch.io project.
  - [ ] Personally verify the publicly accessible hosted game from start to completion.
  - [ ] Publish release notes, source link, controls, screenshots, licenses and AI-use disclosure as applicable.
  - [ ] Submit the project to GitHub Game Off 2026 before the event deadline (verify event time zone).
  - [ ] Record final itch.io URL, GitHub release/source commit and submission confirmation in the PR.
  - [ ] Do not mark release complete until the hosted playtest and actual jam submission are verified.

**Acceptance gate:** The final public itch.io page launches the game, the GitHub repository is linked and the jam submission is confirmed with URLs/evidence.

## Scope protection and contingency

- **P0 gate (MS-07):** if the shooting + SHIFT loop is not fun and stable by the first playtest, prioritize iteration over adding more levels. Do not check off MS-07 without a documented go/no-go decision.
- **Time-box:** keep milestone PRs small and reviewable (typically one to three focused days). The target windows are ambitious for one developer; reduce optional content before sacrificing collision safety, reliable retries, or hosted Web verification.
- **Optional work:** turret, advanced enemy tactics, controller support, style scoring, extra animations and desktop exports are not separate required milestones. Add them only if the jam schedule permits and their inclusion is approved.
- **Final submission:** the last milestone needs external access to itch.io and the jam submission interface. A coding agent without permission must leave those tasks unchecked and request human evidence instead of claiming success.

## Release record (fill only after verified publication)

- **Final game URL:** pending
- **GitHub source/release URL or commit:** pending
- **Confirmed jam submission URL:** pending
- **Hosted playthrough evidence / tested browser:** pending
- **Version and release date:** pending
