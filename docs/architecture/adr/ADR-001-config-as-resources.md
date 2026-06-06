# ADR-001: Game config as Godot Resources (.tres), not raw JSON

*Status: Proposed · Date: 2026-06-07 · Deciders: technical-director*
*Relates to: mvp-tdd.md §5 · Source principle: data-driven (§7/§11)*

## Context
All gameplay numbers (skills, enemies, equipment affixes, stages, talents) must be data-driven and editable without touching code (source §11). Two viable Godot approaches: custom `Resource` subclasses saved as `.tres`, or plain JSON loaded at runtime.

## Decision
Use **custom `Resource` subclasses** (`class_name` + typed `@export` fields) authored as `.tres` under `src/data/`. `GameData` autoload loads them via `ResourceLoader` at boot and serves read-only lookups by id. Runtime item *instances* remain plain data built from a stored seed (not config resources).

## Alternatives Considered
- **Raw JSON**: faster bulk text editing, but no type safety, no editor authoring, hand-written parsing/validation, easy to drift from the typed `types/*.gd` containers.
- **CSV→imported**: good for big designer tables; deferred — can add a CSV→.tres import tool later if affix/stage tables grow.

## Consequences
- (+) Type-safe, editor-authorable, validated at load, integrates with `types/*.gd`.
- (+) Cheap to unit-test (load resource → assert fields).
- (−) Bulk edits are clickier than a text file → mitigate with a small authoring tool if needed.
- Revisit if designers find `.tres` editing too slow for large tables.
