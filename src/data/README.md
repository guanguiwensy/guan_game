# Game Config Data (`src/data/`)

All gameplay numbers live here as Godot **Resources (`.tres`)** — never hardcoded
(ADR-001, source rule §11). `GameData` autoload loads these at boot and serves
read-only lookups by id.

## Layout (authored per system in M1+)

| Folder | Resource type (`src/types/`) | Authored in | Holds |
| ---- | ---- | ---- | ---- |
| `skills/` | `SkillData` | M1 | ember_swing, cleaving_blow, riftwind, frostmaw_surge |
| `enemies/` | `EnemyData` | M1 | cinder_wisp, slagbound_husk, bonegnaw_crawler, lord_of_cinders |
| `stages/` | `StageData` | M1 | layers 1–10 (waves, rewards, drop profile) |
| `affixes/` | `AffixData` | M2 | hp, attack, armor, crit_rate, crit_damage, attack_speed, cooldown, elemental_damage |
| `talents/` | `TalentNode` | M3 | Path of Cinders (~14 nodes) |

Names + ids are fixed by the **Naming Bible** in `design/gdd/game-concept.md`.
Field schemas are defined by the `class_name` types in `src/types/` and the GDD.
