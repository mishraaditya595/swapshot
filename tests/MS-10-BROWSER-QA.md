# MS-10 Extraction browser QA

**Milestone:** MS-10, Double-Deck Lockdown. **Engine:** Godot 4.7.2 Compatibility.
**Status:** NOT RUN. This is a worksheet, not evidence that browser gameplay succeeded.

## Record an actual hosted playthrough

| Field | Recorded value |
| --- | --- |
| Build commit SHA and preview URL | NOT RUN |
| Browser, version, OS | NOT RUN |
| Viewport and display scale | NOT RUN |
| Start and extraction timestamps | NOT RUN |
| Clear time (target: 3 to 5 minutes) | NOT RUN |
| Final health, enemy kills, SHIFT count | NOT RUN |
| Average FPS, frame-time spikes, console errors | NOT RUN |

Use a fresh browser session and a new Extraction run. Record the build revision before collecting evidence.

## Gameplay walkthrough

| Check | Status | Observation / evidence |
| --- | --- | --- |
| South-west entry; upper cyan core and lower amber gate visible and understandable | NOT RUN | |
| West ramp reaches gantry and back without SHIFT; no fall or camera obstruction | NOT RUN | |
| Cross-gantry SHIFT and east overlook support safe landings | NOT RUN | |
| Downward SHIFT reaches lower open pad; rejected unsafe/occluded SHIFT consumes nothing | NOT RUN | |
| Experimental core requires close, same-deck E; duplicate pickup has no effect | NOT RUN | |
| 1.7-second upper warning is readable; both troopers appear in fair guarded positions | NOT RUN | |
| Cover blocks enemy shots and VX-7 fire; echo distracts without wall penetration | NOT RUN | |
| After upper guards fall, the lower warning and response begin with a clear objective | NOT RUN | |
| Exit stays locked while any active guard remains; lower gate opens after response | NOT RUN | |
| Final E works from lower gate only; victory shows time, kills, SHIFTS and waivers | NOT RUN | |
| Fully blocked authored pads retry and waive after eight seconds without spawning inside geometry | NOT RUN | |
| Player death during warning and combat halts waves; retry restores core, guards and resources | NOT RUN | |
| Victory replay resets HP, ammo, SHIFT, warnings, core and gate | NOT RUN | |
| 960 x 540 HUD objective, health, SHIFT and ammo remain readable | NOT RUN | |
| Mouse capture, Escape, browser focus switch, resume and audio startup | NOT RUN | |
| No console errors, unstable frame pacing or serious performance degradation | NOT RUN | |

## Failure reporting

For each failure, record exact steps, scene state, approximate XYZ location, expected outcome, observed outcome, video or console excerpt, browser details and build SHA. Pay special attention to SHIFT rays crossing the upper slab, physical cover around candidates, enemy facing direction, and unfair guard materialization.

Headless Godot smoke and GitHub Actions do not count as hosted gameplay evidence. Complete this worksheet from actual tests, then update milestone acceptance and review findings only if the observations support them.
