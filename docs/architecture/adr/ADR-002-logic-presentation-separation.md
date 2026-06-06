# ADR-002: Logic/presentation separation via EventBus + dependency-injected systems

*Status: Proposed · Date: 2026-06-07 · Deciders: technical-director*
*Relates to: mvp-tdd.md §3–§4 · Source principle: 逻辑和表现分离 (§7) · Coding standard: DI over singletons, unit-testable public methods*

## Context
Coding standards require public methods to be unit-testable with dependency injection over singletons, and the source mandates logic separated from presentation. Gameplay systems must run and be tested **without** the scene tree / UI.

## Decision
- Gameplay systems (`CombatSystem`, `SkillSystem`, `LootSystem`, `EquipmentSystem`, `TalentSystem`, `ProgressionSystem`, `EnemySpawnSystem`) are **plain GDScript logic classes** instantiated and dependency-injected by `battle.gd` — they do **not** look up UI nodes.
- Cross-cutting communication goes through the **`EventBus`** autoload (typed signals). UI subscribes to EventBus; systems emit to it. UI never calls system internals directly except through their public API.
- All formulas live in `util/formulas.gd` (pure static functions).

## Alternatives Considered
- **Systems as autoload singletons**: simpler wiring, but hard to isolate in tests and encourages hidden global coupling (violates DI standard).
- **Direct node references UI↔logic**: tight coupling, breaks headless testing, brittle to scene changes.

## Consequences
- (+) Systems are unit-testable headlessly (GDUnit4) by construction.
- (+) UI and logic evolve independently; signals are the contract.
- (−) Slightly more wiring/boilerplate in `battle.gd`; signal indirection adds a layer to trace — mitigate with a documented signal catalog in EventBus.
