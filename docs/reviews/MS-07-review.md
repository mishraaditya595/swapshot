# MS-07 review: P0 playtest and expansion decision

**Repository / base:** `mishraaditya595/swapshot`, merged MS-06 on `main` at `9a27005ce280efae14da562c6bb440d1477b2b70`.
**Scope:** One-arena P0 action loop, Godot 4.7.2, Compatibility renderer.
**Decision:** **INSUFFICIENT EVIDENCE / HOLD** on expansion to three zones. The current MS-07 preview still needs hands-on playtesting. This status does not revoke the owner's MS-06 acceptance.

## Prior evidence

The owner accepted the MS-06 six-guard firefight after a recorded 02:25 victory, six successful SHIFTS and 4/100 armor remaining. Earlier recordings covered camera and rifle alignment, a death and a retry. The existing MS-01 through MS-06 headless suites previously passed in their respective CI runs. Those are historical observations, not tests of the MS-07 branch.

## Findings

### P1 risk: reinforcement can overlap the active echo

- **Evidence:** Prior to MS-07, `scripts/ms06_mission.gd::_find_spawn` rejected player, armed-anchor and static geometry overlap, but a SHIFT echo has no collision shape. An entry could therefore coincide with the visible hologram during the four-second warning.
- **Reproduction:** While an echo is live, query a valid entry at the echo position. The old guard selector has no condition excluding it.
- **Expected:** Newly activated enemies enter away from the decoy so SHIFT distraction and enemy silhouettes remain readable.
- **Action:** MS-07 adds an explicit distance test for `echo_instance` and a focused headless regression. Automated execution is pending.
- **Confidence:** Code-inferred risk and concrete missing condition. A visible collision has not been recorded in a browser.

### P1 risk: all reinforcement entries blocked

- **Evidence:** The MS-06 director keeps the wave pending when no three safe entries exist. It retries later; this avoids a collision but can delay progress until space clears.
- **Expected:** No overlapping spawn while blocked; spawn once positions are free.
- **Action:** The new regression creates physical blockers at all eight sites, checks that no unsafe spawn occurs, removes them, and checks recovery. This is a temporary-blocker case, not proof against a permanently obstructed level.
- **Confidence:** Source review. Engine execution pending.

### P2 balance question: low surviving armor

- **Evidence:** The accepted MS-06 browser win ended with 4 HP in 02:25. Issue [#15](https://github.com/mishraaditya595/swapshot/issues/15) requests multiple recorded runs before changing armor or Wave 2 damage.
- **Decision:** Keep the current 100 HP, rifle and two-wave values for this build. No numerical tuning can be justified from a single close win.
- **Next check:** Collect at least three attempts and note damage, kill times and useful SHIFT opportunities.

## Verification matrix

| Check | Result | Evidence / remaining work |
| --- | --- | --- |
| Code review of player, camera, rifle, SHIFT, trooper and mission | REVIEWED | Traced state, safe landing and replay paths; independent gameplay observation still needed |
| Static audit and Python regressions | NOT RUN | Await current branch CI |
| Godot 4.7.2 import/startup | NOT RUN | Await current branch CI |
| MS-01 through MS-06 Godot regressions | NOT RUN | Await current branch CI |
| MS-07 blocked-landing, echo, wave and replay regression | NOT RUN | New test in `tests/ms07_p0_review_smoke.gd`; await CI |
| Browser movement, camera, aim and gunplay | NOT RUN | Owner to complete `tests/MS-07-BROWSER-QA.md` |
| Browser SHIFT rejection, echo, wave, restart and finish | NOT RUN | Owner to complete `tests/MS-07-BROWSER-QA.md` |
| Browser FPS, audio, console and smaller viewport | NOT RUN | Requires hosted MS-07 preview |

## Go/No-Go decision

**HOLD: do not begin MS-08 three-zone work yet.** The code and regression pass can reduce known safety and state risks, but MS-07 explicitly requires playtest observations and human feedback on movement, gunplay, SHIFT usefulness and pacing. Keep the milestone and its human acceptance tasks unchecked until the reviewer records that evidence. If new P0/P1 issues appear, keep the decision at HOLD until addressed.

**Editorial check:** Reader-facing review prose and the playtest worksheet received the repository humanizer pass; source identifiers, observed results and unknowns were preserved.
