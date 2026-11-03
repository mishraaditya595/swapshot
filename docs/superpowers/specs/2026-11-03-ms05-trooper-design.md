# MS-05 security trooper design

**Date:** 2026-11-03
**Context:** The owner requested implementation of the MS-05 firefight against the merged MS-04 baseline. This records the chosen narrow implementation, not a claim of a separate design-approval meeting.

## Intent and constraints

Make SHIFT useful in combat: after teleporting, the holographic echo should absorb a guard's attention long enough for Vex to flank. Combat must be readable, deterministic and safe around cover. Preserve the existing rifle, camera and SHIFT lifecycle, and keep the Web-first, solo-developer scope. One trooper is enough. A full health HUD, death/restart loop, navigation system, advanced cover tactics and new assets are outside MS-05.

## Approaches

- **Stationary guard, four states (chosen):** straightforward physics rays and physics-time timers. Clear telegraph, full echo distraction and easy deterministic tests. The tradeoff is no movement around cover.
- **Simple strafe guard:** a `CharacterBody3D` could move after losing sight, but collision behavior and actor blocking would require another test cycle.
- **Navigation-based pursuit:** multiple positions and pathfinding would add scene navigation and path-state complexity for one encounter.

The chosen approach gives the player a predictable opponent and makes the first SHIFT flank legible. Repositioning can be revisited only after gameplay evidence supports it.

## Rules

A guard has `IDLE`, `ALERT`, `ATTACK` and `DEAD` states. First acquisition requires detection radius, field of view and a ray to the player's collider. Sight and attack rays include world layer 1 and player layer 2, excluding the guard's own RID. From `ALERT`, a short reaction precedes `ATTACK`. A visible weapon glow announces each shot; one cooldown bounds the firing cadence. At discharge, a second muzzle ray must hit the player, or the attack is canceled. Death disables all attack logic and removes the collider from hitscan targeting.

A nearby, unobstructed echo interrupts the attack. The guard turns to its recorded departure position and does not shoot while the echo is live. It clears the echo on `echo_ended`, on invalid/freed instance detection, or on death. Then it attempts normal player acquisition. The echo stays collision-free and never receives damage.

The player receives bounded damage through `apply_damage`; at zero health the SHIFT ability is disabled. MS-06 will add player-facing health feedback, full death handling and restart.

## Verification

The new headless test exercises geometry obstruction, warning/cadence, actual player damage, echo lifetime, rifle damage and death. Existing MS-01 through MS-04 tests remain in CI. Headless results do not establish combat feel, input quality or Web performance; the owner must test the PR preview.
