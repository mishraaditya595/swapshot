# MS-10 Extraction browser QA

**Milestone:** MS-10, Double-Deck Lockdown. **Engine:** Godot 4.7.2 Compatibility.
**Status:** Partial browser playthrough reviewed on November 4, 2026. The subsequent signage and combat-polish changes require another hosted build and playtest.

## Record an actual hosted playthrough

| Field | Recorded value |
| --- | --- |
| Build commit SHA and preview URL | PR #23 GitHub Pages browser preview shown; the exact build SHA is not visible in the recording |
| Browser, version, OS | Brave on macOS; browser version not documented |
| Viewport and display scale | 480p source recording; actual game viewport scaling not measured |
| Start and extraction timestamps | A full extraction sequence is visible, but exact real-time session timestamps are not documented |
| Clear time (target: 3 to 5 minutes) | Approximately 02:15 on the in-game clock; one run is shorter than the target |
| Final health, enemy kills, SHIFT count | Approximately 76/100 armor, 4/4 kills and four SHIFTS on the ending screen |
| Average FPS, frame-time spikes, console errors | Not measured; the recording does not establish FPS or browser console state |

Recording reviewed: the owner's 480p copy of `Screen Recording 2026-11-04 at 15.30.05.mov`, showing the original PR #23 implementation. A new run is needed after the core-label, gate-sign and combat-readability fixes. Record the exact build SHA and browser version on that run.

## Gameplay walkthrough

| Check | Status | Observation / evidence |
| --- | --- | --- |
| South-west entry; upper cyan core and lower amber gate visible and understandable | NOT RUN | |
| West ramp reaches gantry and back without SHIFT; no fall or camera obstruction | NOT RUN | |
| Cross-gantry SHIFT and east overlook support safe landings | NOT RUN | |
| Downward SHIFT reaches lower open pad; rejected unsafe/occluded SHIFT consumes nothing | NOT RUN | |
| Experimental core requires close, same-deck E; duplicate pickup has no effect | PARTIAL | Successful pickup is visible; invalid and duplicate attempts were not shown |
| 1.7-second upper warning is readable; both troopers appear in fair guarded positions | NOT RUN | |
| Cover blocks enemy shots and VX-7 fire; echo distracts without wall penetration | NOT RUN | |
| After upper guards fall, the lower warning and response begin with a clear objective | PASS | Footage shows upper security defeated and the lower response phase |
| Exit stays locked while any active guard remains; lower gate opens after response | PARTIAL | Gate becomes ready after the second wave; no premature exit attempt was recorded |
| Final E works from lower gate only; victory shows time, kills, SHIFTS and waivers | PARTIAL | Successful E and victory shown with 4/4 kills, four SHIFTS and about 02:15 elapsed; wrong-deck rejection was not shown |
| Fully blocked authored pads retry and waive after eight seconds without spawning inside geometry | NOT RUN | |
| Player death during warning and combat halts waves; retry restores core, guards and resources | NOT RUN | |
| Victory replay resets HP, ammo, SHIFT, warnings, core and gate | NOT RUN | |
| 960 x 540 HUD objective, health, SHIFT and ammo remain readable | NOT RUN | |
| Mouse capture, Escape, browser focus switch, resume and audio startup | NOT RUN | |
| No console errors, unstable frame pacing or serious performance degradation | NOT RUN | |

## Recording findings and follow-up

The original browser recording exposed an enlarged `CORE SECURED` Label3D obscuring the upper firefight (about 0:42), plus gate text extending beyond its sign panel (about 1:57). The encounter also used similar-looking cover and offered little reaction to nonlethal hits. PR #23 now hides the core sign on pickup, shortens both in-world prompts, colors the cover by role and adds a small per-trooper impact flash and armor recoil. These corrections have source and headless test coverage, but **remain unverified in a new browser recording**.

Retest at least: core pickup during a moving camera shot, approach to the exit gate at short range, repeated VX-7 hits on both upper and lower guards, visibility of the cover accents, and playability at 960×540. The uploaded clip has no audio track, and it does not establish death retry, victory replay, blocked spawns, or browser focus recovery.

## Failure reporting

For each failure, record exact steps, scene state, approximate XYZ location, expected outcome, observed outcome, video or console excerpt, browser details and build SHA. Pay special attention to SHIFT rays crossing the upper slab, physical cover around candidates, enemy facing direction, and unfair guard materialization.

Headless Godot smoke and GitHub Actions do not count as hosted gameplay evidence. Complete this worksheet from actual tests, then update milestone acceptance and review findings only if the observations support them.
