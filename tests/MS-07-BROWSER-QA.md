# MS-07 browser playtest worksheet

Test a freshly deployed MS-07 PR preview. Use [the manual Web deployment workflow](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml): on `main`, set source to `pr` and enter the MS-07 PR number. Record the deployed commit SHA, browser, OS, window resolution and whether the Web build loads without console errors.

## Complete playtest runs

Play at least three independent attempts, including a death/retry and a full victory/replay. Do not infer typical difficulty from the single MS-06 run ending at 4 HP. For each attempt, record:

| Run | Result | Mission time | Kills / 6 | SHIFT count | Armor remaining | Replay succeeded? | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Pending | | | | | | |
| 2 | Pending | | | | | | |
| 3 | Pending | | | | | | |

For movement and camera, check diagonal running, quick stops, sidestepping along cover, turning while strafing, close-wall camera fade, ramp traversal and pointer release/recovery after Escape and app focus switching. Describe where movement feels sluggish or slippery. For the rifle, check hipfire against ADS, fire cadence, recoil, aim alignment, an empty magazine, reload during movement and whether a close crate blocks fire from the muzzle. Record unexpected behavior and where it happened.

For SHIFT, deploy on an open floor and an elevated surface, then attempt a flank and note whether the resulting angle actually helps. Try deploying on a wall, out of range, into cover or beside an enemy. Place a valid anchor, block the landing with an actor if practical, and confirm rejection leaves the player in place without spending cooldown. Test eight-second expiry, rapid Q/Shift inputs, a SHIFT during fire, and a SHIFT near the response-wave entry period. Enemies should respond to an echo and return to searching or attacking after it vanishes.

For pacing, note the time to finish the first three guards, the four-second Wave 2 warning, whether the response feels fair, and where damage accumulates. Describe whether the six-guard encounter encourages more than one worthwhile SHIFT. Verify that victory requires 6/6 and that Enter and the replay button both restart from full health, 24 rounds, six guards and a ready SHIFT. Test death during the warning and retry, with no late spawns. Check HUD legibility and overlap in a smaller browser window.

## Browser-only evidence and decision

Record measured frame rate where available, audio problems, browser console errors, screenshots or a short video, and the exact revision tested. Mark every item not tested explicitly. Headless Godot and GitHub Actions cannot verify input comfort, shot sounds, actual GPU performance or the fun of the firefight.

The MS-07 Go decision requires explicit human feedback on the current preview, no known P0/P1 gameplay defects, a completed victory/replay and death/retry, useful SHIFT flanking, and acceptable movement/shooting feel. If those conditions are not met, keep MS-07 open and fix the recorded blockers before beginning the three-zone mission. If survival is consistently too low across several runs, use that evidence to evaluate the small damage or recovery changes proposed in [issue #15](https://github.com/mishraaditya595/swapshot/issues/15).
