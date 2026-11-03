# MS-08 review: Loading Dock opening

**Repository:** `mishraaditya595/swapshot`  
**Branch / PR:** `feat/ms-08-loading-dock`, [#17](https://github.com/mishraaditya595/swapshot/pull/17).  
**Scope:** P1 Loading Dock only, Godot 4.7.2 Compatibility.  
**Decision:** INSUFFICIENT EVIDENCE pending current-branch CI and first-time hosted browser feedback.

## Findings

### Acceptance blocker: first-time comprehension is not yet demonstrated

The scene contains contextual movement, rifle, anchor and SHIFT prompts, a two-guard objective and an E-controlled exit. Static source inspection cannot establish whether a new player notices them or finishes in two to three minutes. Use `tests/MS-08-BROWSER-QA.md` with the hosted PR snapshot and record a first attempt.

### Follow-up: overhead camera visibility

The PR #16 recording prompted a question about visibility near overhead geometry. The new dock avoids low overhead collision beams in its main lanes. The camera code has not been changed. Reproduce in a hosted browser before classifying this as a bug or tuning the boom.

### Follow-up: point-blank guard engagement

The existing trooper checks line of sight from its muzzle and eye and uses the previous alert, windup and firing logic. There is no verified close-range defect in this PR. Test close guard approaches in the browser, then supply coordinates and a recording if behavior fails.

## Automated verification

| Check | Status | Evidence |
| --- | --- | --- |
| Godot import and startup | NOT RUN | CI pending |
| MS-01 through MS-07 regressions | NOT RUN | CI pending |
| MS-08 Loading Dock smoke | NOT RUN | CI pending |
| Static audit and Python tests | NOT RUN | CI pending |
| Milestone tracker validation | NOT RUN | CI pending |
| Hosted first-time playtest | NOT RUN | Requires owner |
| Browser FPS / audio / console | NOT RUN | Requires owner |

## Scope and risk

The new director is scene-local. It reuses the player, rifle, SHIFT, HUD and original trooper scripts without changing the MS-06 reinforcement selector. Its gate ends this section with a results panel rather than loading MS-09. The MS-07 HOLD remains documented and unchecked under the owner's explicit authorization to proceed with MS-08.

Review the CI logs, confirm collision behavior and the gate/retry suite, then obtain the owner's browser feedback before accepting MS-08. Reader-facing prose received the required humanizer edit pass.
