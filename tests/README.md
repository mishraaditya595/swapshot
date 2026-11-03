# Tests

Add Godot gameplay regression tests here as systems are implemented. CI runs the static audit, Python unit tests, Godot headless import, plus MS-01 movement/camera, MS-02 rifle and MS-03 SHIFT safety and MS-04 lifecycle physics smoke tests. Headless checks cannot establish mouse feel or browser rendering.

**Manual test matrix (not automated):** movement, aim, rifle cover/obstruction, SHIFT valid/invalid/expiry/cooldown/echo, enemy reaction, pause/death/retry, Web build mouse capture/performance. See `docs/TEST_PLAN.md`.


The MS-08 loading dock adds `ms08_loading_dock_smoke.gd`. It covers tutorial progression, a blocked SHIFT landing, real echo creation, matched cargo collision, exit gating, section completion and clean victory/death replay. CI runs MS-01 through MS-08. These checks do not measure whether the tutorial is intuitive or whether the hosted browser build maintains smooth mouse input. Use [MS-08 browser QA](MS-08-BROWSER-QA.md) for those checks.
