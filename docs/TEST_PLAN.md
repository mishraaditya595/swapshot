# Test plan

## Bootstrap (CI)

- Python static project audit checks main scene, literal res:// paths, basic source/packaging hygiene.
- Python unittest suite exercises the audit itself.
- Godot 4.7.2 headless project import/startup smoke run (GitHub CI). A successful import does **not** prove game behavior.

## P0 manual journeys (required once playable)

1. Launch and restart without errors; move with WASD, mouse aim, pause/resume, shoot and reload.
2. Confirm camera doesn't clip into cover; bullets don't pass through close obstructions.
3. Deploy valid SHIFT anchor within range, including different elevations; verify HUD timer.
4. Reject wall/ceiling/occluded, beyond-range, too-tight, actor-occupied, unsafe and moving target locations; verify no cooldown spent.
5. Anchor expiry, repeated Q/Shift presses, expiry/teleport race, jumping/falling, pause, death and scene reload.
6. SHIFT to flank a guard, verify echo distraction ends, finish objective, die/retry, win/restart.
7. Browser export must be played in the **hosted** environment: pointer lock, inputs, audio start, performance, loading size and fullscreen/focus changes.

Record Godot version, OS/browser, build SHA, observed vs expected, and failure reproduction steps. Do not claim an unrun journey passed.
