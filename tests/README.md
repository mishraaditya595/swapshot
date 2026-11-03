# Tests

Add Godot gameplay regression tests here as systems are implemented. CI runs the static audit, Python unit tests, Godot headless import, plus MS-01 movement/camera, MS-02 rifle and MS-03 SHIFT safety physics smoke tests. Headless checks cannot establish mouse feel or browser rendering.

**Manual test matrix (not automated):** movement, aim, rifle cover/obstruction, SHIFT valid/invalid/expiry/cooldown/echo, enemy reaction, pause/death/retry, Web build mouse capture/performance. See `docs/TEST_PLAN.md`.
