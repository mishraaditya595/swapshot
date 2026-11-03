# MS-08 Loading Dock design

Approved November 3, 2026. The owner authorized MS-08 implementation despite the unresolved MS-07 HOLD. MS-07 stays unchecked, and its acceptance gate is unchanged.

## Goal

The opening section should teach a new player movement, aiming, rifle fire, anchor placement and SHIFT before a short firefight. The player starts at the receiving end of a cargo yard, uses an anchor to flank Helix security, then opens the exit to the Security Core. A first run should take roughly two to three minutes. That duration is a playtest target rather than a forced timer.

The release remains a solo-built Godot 4.7.2 Compatibility project. This milestone adds no weapons, enemy archetypes, navigation framework, multiplayer or next-zone content.

## Approaches

1. A separate Loading Dock scene using the existing player, SHIFT, VX-7 and troopers. This keeps the old arena's hard-coded waves and spawn positions untouched. **Approved approach.**
2. Modify the MS-06 arena and mission controller. This saves a scene but risks the tested wave timing and safe reinforcement entries.
3. Build a reusable multi-zone mission framework now. That adds architecture before this section has been playtested.

The owner approved the proposed standalone scene and authorized the dependency exception in the conversation. The scene owns only its opening tutorial, two guards, exit and replay state.

## Player flow

The starting path uses a cyan floor marker ahead of a cargo wall. Entering the marker reveals the rifle lesson: mouse-look, right mouse to aim, left mouse to hit the orange practice target, and R to reload. The first registered target hit advances to an anchor prompt. A valid `anchor_placed` signal advances to the Left Shift prompt, and a successful `shifted` signal opens the combat instruction. Earlier valid actions are remembered, so players can experiment without repeating them.

Two standard Helix guards cover the northern exit from opposite sides. The player can approach along the central lane or flank using the side corridors. All cover blocks shots and obstructed SHIFT landings. The existing SHIFT validation, echo and cooldown code is reused unchanged.

The objective remains visible throughout. Defeating both guards changes the gate light from amber to cyan and reveals the E interaction hint. The player must get close and interact to complete the section. An overlay names Security Core as the next destination and offers a complete Loading Dock replay. No Security Core scene is loaded, and no checkpoint is promised across the unbuilt zone.

## Failure, safety and acceptance

A rejected anchor or SHIFT displays a short explanation alongside the original device status. A blocked exit stays locked until both guards die. Death immediately ends the encounter, disables combat and exposes retry. A scene reload resets health, ammo, guards, tutorial progress, anchors, echo and result state.

Keep overhead detail non-colliding on the main routes until a browser playtest confirms camera clearance. The point-blank engagement and overhead visibility observations from PR #16 remain unconfirmed; investigate them through recorded reproduction, not speculative global changes.

The new player must understand SHIFT and reach the completion screen without outside instructions. Hosted browser feedback is required before MS-08 can be checked complete.
