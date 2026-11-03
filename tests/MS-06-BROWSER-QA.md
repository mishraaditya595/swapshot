# MS-06 browser acceptance check

Test the latest code in [draft PR #14](https://github.com/mishraaditya595/swapshot/pull/14). Run [the manual Web deployment workflow](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml) on branch `main`, choose source `pr`, and enter PR number `14`. Once deployment succeeds, open `https://mishraaditya595.github.io/swapshot/pr-14/`. Record the deployed commit SHA, OS and browser version.

## Full encounter

1. Start at 100 HP with a 24-round rifle. Move, aim, fire, reload, use cover and SHIFT. Confirm that close cover still blocks bullets.
2. Defeat the first patrol of three. The counter should read `3 / 6` and reinforcements should be announced for four seconds. No victory screen should appear yet.
3. Watch the next three troopers activate. They must never appear inside the player or cover, and there must be at most three active enemies at a time. The last trooper should require another attack angle. Defeat all six to win.
4. On the victory screen, click **Replay Encounter**. On a later victory, press Enter instead. Both should begin a fresh run with six live guards, `0 / 6` objective, 100 HP, full ammo, and no stale anchor or echo.
5. On another attempt, let the player die while the reinforcement warning is active or while a SHIFT echo exists. The defeat screen must remain stable and no delayed troopers should activate after death. Try both the button and Enter to retry.
6. Try deploying onto a wall, a blocked floor, an occupied landing and beyond the anchor's range. A rejected SHIFT must neither spend cooldown nor strand the player.
7. Check HP, ammo, objective, SHIFT timer, reinforcement warning and result panel at native display resolution and in a smaller browser window. Look for clipping or overlapping elements. Verify Escape release and focus recovery.

## Evidence to record

For each run, note the mission time, number of kills, successful SHIFTS, remaining HP and whether replay was successful. The target is a satisfying 90–135-second winning run, not a mandatory timer. If a run is significantly faster or slower, describe where the pacing changes.

Record audio behavior, browser console errors and measured FPS if available. Include whether the new wave felt fair and whether the HUD remained readable while fighting. The earlier 50-second recording documents the three-guard version and cannot serve as acceptance of the updated one.
