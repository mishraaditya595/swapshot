# MS-09 review: Security Core Looped Mezzanine

**Repository / base..head:** `mishraaditya595/swapshot`, `main` (`d586a5f`) to `feat/ms-09-security-core` (`806f572` before this documentation commit).
**Scope:** P1, MS-09 Security Core only.
**Reviewed:** `scenes/levels/security_core.tscn`, `scripts/ms09_security_core.gd`, the shared player/SHIFT/trooper/rifle scripts, MS-06 and MS-08 startup assertions, `tests/ms09_security_core_smoke.gd`, CI, milestone tracker and manual QA worksheet.
**Environment:** Godot 4.7.2 stable (official binary in GitHub Actions); no hosted browser session for MS-09.
**Acceptance decision:** **INSUFFICIENT EVIDENCE**. Engine regressions passed. Browser playtesting, pacing and required predecessor acceptance remain open.

## Findings, ordered by impact

### Acceptance blocker: browser quality and gameplay pacing are unmeasured

- **Evidence:** [CI run 41776092450](https://github.com/mishraaditya595/swapshot/actions/runs/41776092450) ran Godot import/startup and MS-01 through MS-09 smoke, including real physics for two ramps, SHIFT and cover. No MS-09 hosted gameplay recording or FPS/audio/pointer-capture report exists yet.
- **Reproduction:** Deploy PR #20 through the manual preview workflow; follow `tests/MS-09-BROWSER-QA.md` without changing the game first.
- **Expected:** A new player sees an understandable two-stage fight, uses tactical elevated SHIFT, disables the terminal and retries reliably. The intended time is 3–4 minutes.
- **Observed:** Automated behavior passed; camera comfort, gunplay feel, terminal discoverability, browser audio and duration were **NOT RUN**.
- **Next check:** Complete a hosted first-person playthrough, record time/SHIFTS/armor and a browser console/FPS check.
- **Confidence:** Verified absence of manual acceptance, not a code defect.

### Policy blocker: earlier milestone acceptance is unfinished

- **Evidence:** [Pre-merge run 41776092465](https://github.com/mishraaditya595/swapshot/actions/runs/41776092465) fails `PR milestone acceptance`. The policy requires checked MS-09 tasks and completed MS-07 and MS-08 prerequisites.
- **Expected:** All milestone acceptance and predecessor requirements have evidence before a merge.
- **Observed:** [Issue #19](https://github.com/mishraaditya595/swapshot/issues/19) explicitly tracks deferred MS-07/MS-08 browser and human acceptance. No work in this PR changes those results.
- **Next action:** Owner resolves #19 and MS-09 manual acceptance under the existing policy or makes a separately reviewed governance decision. Do not alter old checkboxes or weaken policy here.
- **Confidence:** Observed CI failure, not an MS-09 runtime defect.

### P2 / needs manual verification: camera framing and tactical value

- **Evidence:** `scripts/ms09_security_core.gd` builds wide east/west ramps, a north walk, cover and waist-height collision rails. The tests validate walking and ray/capsule safety. Browser gameplay has not established how clearly the player sees targets when the camera retracts near the underside of the upper deck.
- **Reproduction:** Approach both ramps from below, hug the guardrails, SHIFT while moving and fire at guards across each elevation.
- **Expected:** Safe navigation, legible warnings and a useful shooting angle after SHIFT.
- **Observed:** No reproducible code defect in the headless suite; gameplay feel **NOT RUN**.
- **Smallest next step:** Playtest before changing shared camera or guard behavior.
- **Confidence:** Code-inferred risk.

## Implementation review notes

The shared `shift_ability.gd` is unchanged. It still enforces range, slope, visible surface, 4 m height difference, floor support, player capsule clearance and landing revalidation. The new upper approach supports validated ramp-to-deck and lateral SHIFT, plus a downward escape. The MS-09 smoke exercises all three with real collision geometry. A blocked destination does not move the player or spend cooldown.

Two lower troopers activate at start. Two upper troopers remain hidden and non-colliding until both lower guards are defeated. The director chooses safe upper-floor positions atomically after rejecting occupied player/anchor sites and unsuitable physics surfaces. The troopers remain stationary as designed; their existing eye and muzzle rays stop at cover and solid floors. Automated checks confirm that a dead guard does not resume firing.

The terminal's upper-deck proximity, elevation and line-of-sight checks reject early, remote, lower-floor and blocked interaction. Four unique destroyed guards unlock its amber-to-cyan state. A successful E interaction disables the core once. Victory and defeat both freeze combat and reload the whole standalone scene through a single replay request; health, ammo, SHIFTS and encounter state reset in the Godot test.

The MS-08 Loading Dock, original encounter and shared weapon/SHIFT behavior remain directly runnable. `scenes/main.tscn` opens Security Core for a focused Web preview; zone integration belongs to MS-11.

## Verification matrix

| Check | Result | Evidence |
| --- | --- | --- |
| Static audit and repository Python suites | PASS | CI 41776092450, `Static audit and audit tests` |
| Milestone structure validator | PASS | Same CI static job |
| Godot 4.7.2 import and startup | PASS | Same CI engine job |
| MS-01 through MS-08 Godot regressions | PASS | Eight `SMOKE PASS` records in the engine job |
| MS-09: ramps, lateral/down SHIFT, revalidation and expiry | PASS | MS-09 Godot smoke in same run |
| MS-09: phased enemies, floor LOS, terminal and replay | PASS | Same MS-09 Godot smoke |
| Automated code review | PASS | SWAPSHOT Pre-Merge, rule-based scanner |
| PR milestone acceptance | FAIL | Unchecked MS-07, MS-08 and MS-09 requirements; expected until acceptance |
| Hosted Web playthrough and actual duration | NOT RUN | Follow `tests/MS-09-BROWSER-QA.md` |
| Browser FPS, audio, cursor and console | NOT RUN | Manual QA required |
| Local Godot 4.7.2 run | NOT RUN | No trusted local executable in this environment |

## Scope acceptance

| MS-09 requirement | Source implemented | Automated check | Manual acceptance |
| --- | --- | --- | --- |
| Vertical arena, ramps, cover and safe routes | Yes | PASS | NOT RUN |
| Elevated SHIFT opportunities and collision safety | Yes | PASS | NOT RUN |
| Two-phase four-guard encounter and cover integrity | Yes | PASS | NOT RUN |
| Terminal locked/ready/offline sequence with E | Yes | PASS | NOT RUN |
| Fresh death and victory replay | Yes | PASS | NOT RUN |
| 3–4-minute playable section and browser comfort | Target only | Not measurable headless | NOT RUN |

**Decision:** Keep [draft PR #20](https://github.com/mishraaditya595/swapshot/pull/20) open. No P0/P1 runtime defect is confirmed by the current suite; completion and merge readiness have insufficient evidence. Do not interpret the passing tests as an accepted milestone.
