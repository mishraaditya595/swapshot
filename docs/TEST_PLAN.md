# Test plan

## CI checks

- The Python project audit checks the main scene, literal `res://` resource paths, and basic source and packaging hygiene.
- The Python unittest suite tests the audit script.
- GitHub CI imports and starts the project using Godot 4.7.2 in headless mode. A successful startup cannot prove that gameplay works.

## P0 manual playtests

1. Launch and restart without errors; move with WASD, mouse aim, pause/resume, shoot and reload.
2. Confirm camera doesn't clip into cover; bullets don't pass through close obstructions.
3. Deploy valid SHIFT anchor within range, including different elevations; verify HUD timer.
4. Reject wall/ceiling/occluded, beyond-range, too-tight, actor-occupied, unsafe and moving target locations; verify no cooldown spent.
5. Anchor expiry, repeated Q/Shift presses, expiry/teleport race, jumping/falling, pause, death and scene reload.
6. SHIFT to flank a guard, verify echo distraction ends, finish objective, die/retry, win/restart.
7. Browser export must be played in the **hosted** environment: pointer lock, inputs, audio start, performance, loading size and fullscreen/focus changes.

Once the relevant gameplay is available, run every applicable journey and record the Godot version, OS and browser, build SHA, expected and observed behavior, and steps to reproduce failures. Leave unrun journeys marked as untested.
