# MS-08 Loading Dock browser playtest

Use a fresh hosted build of [PR #17](https://github.com/mishraaditya595/swapshot/pull/17). The [manual Web deployment workflow](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml) takes source `pr` and PR number `17`; it publishes under `/swapshot/pr-17/`. The preview is not automatically deployed by opening the PR.

Record the build commit, browser/OS, approximate FPS and the number of attempts. The two Nov 4 recordings are from earlier PR #17 snapshots; the later one ends at 01:17 with two SHIFTS and full armor. Manually redeploy PR #17 after this latest patch, since the preview does not update on push. Keep a first-time run unscripted: do not read the control checklist before playing. Note prompts that were missed or misunderstood.

## First-time run

- [ ] Spawn at the entrance, follow the cyan floor marker using WASD, and discover the rifle lesson.
- [ ] Aim with RMB, hit the orange practice target with LMB and try R to reload.
- [ ] Find a clear floor landing, press Q and read the anchor status. Press Left Shift while it is active.
- [ ] Notice the echo and any guard distraction. Try at least one useful cargo flank.
- [ ] Defeat both guards. Check that the counter reaches `2 / 2` and the exit changes to cyan.
- [ ] Walk to the illuminated gate and press E. Confirm the outcome says `SECURITY CORE IS NEXT`, without entering an unfinished zone.
- [ ] Record first clear time, SHIFT count, remaining armor, what felt unclear, and whether outside help was needed.

## Retest the November 4 recording findings

- [ ] After crossing the cyan movement marker, shoot a real guard without touching the dummy. The rifle lesson should advance from step 02.
- [ ] On a separate run, place an anchor and SHIFT before hitting a guard. Shooting the guard should credit the earlier actions, without asking the player to repeat Q or SHIFT.
- [ ] Check the SHIFT status and cooldown at the lower-left of the screen. They must not overlap the top-left objective, tutorial or clock, including at a 960×540 browser viewport.
- [ ] Confirm the orange practice target has a distinct amber frame and range sign.
- [ ] The Security Core gate should read LOCKED in amber initially, then PRESS E in cyan after both guards are defeated.
- [ ] Record the run time and any close-range camera crowding; the earlier run completed in about 58 seconds, shorter than the 2–3-minute target.

## Retest the combat and visibility fixes

- [ ] Walk into an exposed middle lane toward the western guard. It should notice, warn and fire before you get directly beside it. Record whether armor drops in a normal fight.
- [ ] Move behind a cargo container while a guard tracks you. No shot should hit through the solid object; stepping into the open should restore pressure.
- [ ] Approach a live guard closely while turning and shooting. Check that Vex's suit fades enough to reveal the target without changing crosshair alignment, camera stability or weapon behavior.
- [ ] Aim down at clear floor within 18 m during step 03 and press Q. Test an out-of-range attempt and an attempt with no floor under the reticle. The instructions and rejection messages should tell you how to correct each.
- [ ] Read the gate sign from front, side and close range before and after unlocking. The two-line text should remain visible on its fixed dark panel.
- [ ] Record how long a new player takes, remaining armor and any camera/AI problems. No balance claim should be based on one run.

## Safety, controls and replay

- [ ] Try placing on a wall, beyond range and into or behind a container. Rejections should not consume a charge.
- [ ] Place a valid anchor, then stand near an obstructed route; confirm SHIFT does not clip through cargo or into guards.
- [ ] Let an anchor expire; try repeated Q and Shift input during cooldown. No duplicate shift or stuck indicator.
- [ ] Check cover from both sides with the rifle and enemy fire. Shots should not pass through solid crates or containers.
- [ ] Walk against a container and a high wall while panning the camera. Record any obstruction or abrupt jump, especially beneath wall trim or other overhead geometry.
- [ ] Approach a live guard to point-blank range. Record whether it tracks, warns and fires as expected. This was an observation in PR #16, not a confirmed defect.
- [ ] Lose a fight; use Enter or the retry button. Confirm that both guards, full armor, ammunition, the tutorial and the locked gate reset.
- [ ] Win and replay. Confirm all objectives and UI return to their initial state, and test one additional clear.
- [ ] Check Esc pointer release, recapture after returning to the tab, audio, smaller viewport readability, FPS and browser-console errors.

## Feedback record

| Field | Observation |
| --- | --- |
| PR head SHA / preview URL (must reflect updated deploy) | |
| Browser / OS / viewport | |
| First-run time and attempts | |
| SHIFTs / armor at clear | |
| First confusing prompt | |
| Useful flank or missed SHIFT opportunity | |
| Camera near overhead shapes | |
| Guard behavior at point blank | |
| Mouse, audio, FPS, console | |
| Victory replay and death retry | |
| New player understood SHIFT without outside instructions? | |
| Accept MS-08 or request changes? | |

Attach a short recording or reproducible steps for any collision, camera or AI issue. A headless smoke PASS is separate from this browser acceptance.
