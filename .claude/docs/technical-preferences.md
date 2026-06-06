# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (static typing enforced — all vars, params, returns typed)
- **Rendering**: Compatibility (GL Compatibility) — broad mobile + web reach, 2D pipeline
- **Physics**: Godot 2D (Area2D + collision detection for hit/range checks; no rigid-body simulation — auto-battle is logic-driven, not physics-driven)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (Android / iOS) primary; Web (HTML5) secondary; Desktop (Windows/Linux) for dev & testing
- **Input Methods**: Touch
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: Portrait 9:16, 1080×1920 logical resolution (`canvas_items` stretch, `expand` aspect). Auto-battle minimizes in-combat input — taps are for optional manual skill cast, gear/talent management, and navigation. Tap targets ≥ 88×88 px, primary actions in thumb-reachable bottom zone, no hover-only interactions. Design for notch/safe-area insets.

## Naming Conventions

<!-- GDScript conventions (Godot idiomatic) -->

- **Classes**: PascalCase (e.g., `CombatSystem`)
- **Variables**: snake_case (e.g., `attack_speed`) — functions also snake_case (e.g., `take_damage()`)
- **Signals/Events**: snake_case past tense (e.g., `enemy_died`, `loot_dropped`)
- **Files**: snake_case matching class (e.g., `combat_system.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `Hero.tscn`, `BattleScene.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_TALENT_POINTS`)
- **Config resources**: snake_case `.tres`/`.json` under `src/data/` (e.g., `skills.tres`, `stages.json`)

## Performance Budgets

<!-- Mobile 2D defaults. Revisit against target device once one is chosen. -->

- **Target Framerate**: 60 FPS (mobile)
- **Frame Budget**: 16.6 ms
- **Draw Calls**: ≤ 100 (2D — batch sprites, use texture atlases, single CanvasLayer per panel)
- **Memory Ceiling**: ≤ 512 MB (mid-tier mobile target)

## Testing

- **Framework**: GDUnit4 (CI runner: `godot --headless --script tests/gdunit4_runner.gd`)
- **Minimum Coverage**: 100% of balance/combat public formulas; ~70% of systems logic overall
- **Required Tests**: Balance formulas (damage, power, enemy growth, quality multipliers), combat resolution, loot & affix rolls (seeded/deterministic), talent application & reset, save/load round-trip

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- Hardcoded gameplay values — all skill/enemy/equipment/affix/stage/talent numbers live in `src/data/` config, never in logic
- Non-reproducible randomness — all RNG must run through a seeded utility so results replay deterministically
- Source files over 400 lines — split before exceeding (per anti-drift rule)
- Logic coupled to presentation — combat/loot/talent systems must not depend on UI nodes; communicate via signals/events

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- GDUnit4 (test framework — dev/CI only)
- [Add others as approved when integration begins]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code (hit flashes, status VFX). Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
