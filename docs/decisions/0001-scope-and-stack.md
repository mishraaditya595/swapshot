# ADR 0001 — Scope and stack

Date: 2026-11-02
Status: Accepted for bootstrap (subject to approved feature designs)

**Decision:** Use Godot 4.7.2 stable + GDScript with GL Compatibility to build a solo, single-player, browser-first third-person action prototype for Game Off 2026. Lock initial scope to one rifle, one trooper, one arena and safe SHIFT before expanding the mission.

**Why:** A short stable vertical slice is more feasible and measurable for the jam than a broad AAA-like scope; it tests whether shooting + teleport repositioning is compelling.

**Consequences:** Prioritize accessible web export, editorless CI checks and real playtesting; postpone multiplayer, large AI systems and complex asset pipelines. Balance values are prototype targets rather than strict invariants.
