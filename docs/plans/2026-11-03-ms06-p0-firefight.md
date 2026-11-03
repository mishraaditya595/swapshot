# MS-06 implementation note: complete P0 firefight

Date: November 3, 2026. Implementing PR: [#14](https://github.com/mishraaditya595/swapshot/pull/14).

## Scope and decision

The milestone request sets the design: one browser-first arena, 100 HP, a readable combat HUD, a clear goal, failure/victory screens and replay. The existing rifle, SHIFT safety checks, camera and trooper AI stay in place.

Two ways to connect this were considered. One was to turn the MS-05 presentation script into a global mission manager. That would complicate the earlier smoke test and couple the only guard to the entire game. The chosen approach instantiates the existing MS-05 arena as a child of a new MS-06 scene, adds two more guards of the same type, and gives the encounter one director for objective and terminal state. The extra scene costs a small amount of setup but keeps the previous vertical slice testable.

## Behavior

- The objective reads `CLEAR HELIX SECURITY` with a 0/6 kill counter and a wave counter. The last living guard is the victory gate. Duplicate death notifications do not increment the counter twice.
- Player health starts at 100, clamps at zero and updates a numeric and bar HUD. Damage feedback uses the existing screen flash.
- The existing weapon owns ammunition and reload; the SHIFT ability owns anchor, echo and cooldown. The encounter only reads their signals. No global autoload or duplicate timer is introduced.
- After death or victory, movement and combat stop, the pointer is released, and a result screen reports eliminations, elapsed time and number of SHIFTS. Enter and the visible replay button use the same guarded scene-reload path.
- Reload creates fresh player, weapon, enemies and signal subscriptions, so the next run begins with full health, a full magazine and a ready SHIFT device.
- Three guards form the opening patrol. Three reserve guards use the same trooper AI in a second wave with 120 HP, 9 damage per shot and a 1.60-second firing interval. The four-second warning allows repositioning. Reserve guards have no collision, damage reception or AI before activation. The mission selects an unoccupied floor-supported entry point, away from the player and any armed SHIFT anchor. At most three guards fight at once.

## Limits and acceptance

There is no hard two-minute timer or artificial SHIFT quota. The first owner recording showed a 50-second victory against three guards. On November 3 the owner authorized extending the firefight and improving HUD readability. A second wave and larger combat labels were chosen over new AI types or a larger arena. The working target is a typical 90–135-second victory, to be measured on the revised browser preview. Respawn means restarting the encounter from the start, not introducing checkpoints; checkpoints belong to later milestones. No additional enemy type, arena, campaign zone or scoring system is included.

Headless checks exercise state integration and regressions, but player feel, HUD scale, audio balance, real end-to-end duration and browser pointer lock require manual observation. Leave the milestone unchecked until the owner plays the hosted preview and accepts it.
