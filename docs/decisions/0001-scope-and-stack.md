# ADR 0001: Scope and stack

Date: 2026-11-02
Status: Accepted for bootstrap (subject to approved feature designs)

## Decision

Use Godot 4.7.2 stable, GDScript, and the GL Compatibility renderer for a single-player third-person action prototype targeting browser play. Keep the initial scope to one rifle, one trooper, one arena, and safe SHIFT repositioning before expanding the mission.

## Rationale

A small playable combat sequence gives the solo developer time to test shooting and SHIFT repositioning within the Game Off 2026 schedule. Expanding the mission before those mechanics work would put the jam submission at risk.

## Consequences

Prioritize browser export, headless CI checks, and hands-on playtesting. Defer multiplayer, large AI systems, and complex asset pipelines. Treat balance values as prototype targets that can change after testing.
