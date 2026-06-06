# Technical Design Document — 《余烬深渊》 MVP

*Created: 2026-06-07 · Status: Draft (pending §12 gate)*
*Engine: Godot 4.6 · Language: GDScript (static typing enforced) · Target: portrait mobile 9:16 (1080×1920 logical), Web secondary*

> Core principle (from source §7): **logic ⟂ presentation, data-driven, save-isolated.** Systems are plain testable GDScript that never reach into UI nodes; they communicate via a signal bus. All tuning lives in `src/data/`. All randomness flows through one seeded service.

---

## 1. Project Layout

`project.godot` at **repo root** (Godot ignores the `.claude/`, `design/`, `docs/`, `production/` folders — they are not imported resources). Source under `src/`, art/audio under `assets/`, config data under `src/data/`, tests under `tests/`.

```
res://
  project.godot
  src/
    main.gd                      # entry; boots autoloads, loads MainMenu
    scenes/
      boot.tscn / boot.gd
      main_menu.tscn / main_menu.gd
      battle.tscn / battle.gd            # the only "live" gameplay scene
    systems/                     # PURE LOGIC (no node tree deps where possible)
      combat_system.gd
      skill_system.gd
      enemy_spawn_system.gd
      loot_system.gd
      equipment_system.gd
      talent_system.gd
      progression_system.gd
    entities/                    # node glue (thin) over logic
      hero.gd / hero.tscn
      enemy.gd / enemy.tscn
      projectile.gd / projectile.tscn
      damage_text.gd / damage_text.tscn
    ui/                          # Control panels, CanvasLayer overlays
      battle_hud.gd / battle_hud.tscn
      skill_bar.gd / skill_bar.tscn
      inventory_panel.gd / inventory_panel.tscn
      equip_compare_panel.gd / equip_compare_panel.tscn
      talent_tree_panel.gd / talent_tree_panel.tscn
      result_panel.gd / result_panel.tscn
    data/                        # .tres resources (config) — see §5
      skills/  enemies/  affixes/  stages/  talents/
    types/                       # class_name typed data containers
      skill_data.gd  enemy_data.gd  item.gd  affix_data.gd  stage_data.gd  talent_node.gd  hero_stats.gd  save_data.gd
    autoload/
      event_bus.gd  game_data.gd  save_system.gd  rng.gd
    util/
      math_util.gd  formulas.gd
  assets/  (art/ audio/ vfx/)
  tests/   (unit/ integration/ gdunit4_runner.gd)
```

**File-size discipline (source §11):** split any file > 400 lines. Natural split points noted per system below.

---

## 2. Scene Architecture

- **One live gameplay scene: `battle.tscn`.** Inventory / Talent / Result are **CanvasLayer overlays** (Control panels) shown/hidden over Battle, not separate scenes — avoids scene-reload state loss and matches mobile "panels slide over the fight" UX.
- `boot.tscn` → init autoloads + warm config → `main_menu.tscn` → `battle.tscn`.
- **Portrait stretch**: `project.godot` → `display/window/stretch/mode = canvas_items`, `aspect = expand`, base size `1080×1920`, `handheld/orientation = portrait`. Renderer = **GL Compatibility** (mobile + web reach). Respect safe-area via a margin container in the HUD root.

Scene tree of `battle.tscn` (sketch):
```
Battle (Node2D)
├─ World (Node2D)            # hero, enemies, projectiles, damage text (pooled)
│   ├─ Hero
│   └─ Spawners/Pools
├─ HUDLayer (CanvasLayer)    # BattleHUD: hp, power, layer, skill bar, wave info
└─ PanelLayer (CanvasLayer)  # Inventory / Talent / Result overlays (hidden by default)
```

---

## 3. Autoload Singletons (kept to four)

| Autoload | Responsibility | Why a singleton |
| ---- | ---- | ---- |
| `EventBus` | Typed signal hub: `damage_dealt`, `enemy_died`, `wave_cleared`, `loot_dropped`, `item_equipped`, `stats_recomputed`, `layer_won/lost`, `level_up`. | Decouples systems↔UI; keeps logic free of node lookups. |
| `GameData` | Loads & caches all `src/data` config resources at boot; read-only lookups by id. | One place owns config; systems get pure data. |
| `SaveSystem` | Serialize/deserialize game state to `user://save.json`; autosave hooks. | Save isolation (source principle). |
| `Rng` | Single seeded `RandomNumberGenerator`; named streams (`loot`, `combat`) derived from master seed. | Determinism / reproducibility (coding standard). |

Systems themselves (CombatSystem etc.) are **not** autoloads — they're instantiated by `battle.gd` and dependency-injected (so tests can construct them in isolation).

---

## 4. Systems (responsibilities, public API, signals)

All are `RefCounted`/`Node`-free logic classes where feasible; node interaction happens in thin entity scripts that forward to systems.

| System | Responsibility | Key public API | Emits | Consumes |
| ---- | ---- | ---- | ---- | ---- |
| `CombatSystem` | Resolve attacks, crit, armor, status ticks; win/lose. | `resolve_hit(attacker, defender, skill) -> HitResult`, `tick(delta)` | `damage_dealt`, `enemy_died`, `layer_won/lost` | target list |
| `SkillSystem` | Cooldown tracking, auto-cast priority, manual cast. | `update(delta)`, `try_cast(skill_id)`, `ready_skills()` | `skill_cast` | hero stats, targets |
| `EnemySpawnSystem` | Drive wave list, apply growth formula, pool enemies. | `start_layer(stage_data)`, `update(delta)` | `wave_spawned`, `wave_cleared` | stage_data, Rng |
| `LootSystem` | Roll drop chance, quality (weights), itemLevel, build item (seeded). | `roll_drop(enemy, layer) -> Item?` | `loot_dropped` | affix pool, Rng(loot) |
| `EquipmentSystem` | Equip/unequip, inventory, `recompute_stats()` source of truth, compare deltas. | `equip(item)`, `compare(item) -> StatDelta`, `final_stats() -> HeroStats` | `item_equipped`, `stats_recomputed` | equipped+talents+base |
| `TalentSystem` | Spend/clear nodes, prereq checks, stat mods, reset. | `can_spend(node)`, `spend(node)`, `reset()`, `stat_mods()` | `talents_changed` | talent data |
| `ProgressionSystem` | XP/gold accrual, level-up, talent-point grant. | `add_kill_rewards(enemy)`, `add_xp(n)` | `level_up`, `currency_changed` | curve config |

`HeroStats.recompute()` = `base + equipment.main+affixes + talents.mods`; called on any equip/talent change and at load. This is the single chokepoint feeding combat — unit-tested directly.

`util/formulas.gd` holds the **pure functions** for every formula in the GDD (damage, power, enemy growth, itemPower). Static, no state → trivially unit-testable; systems call these so the math has exactly one home.

---

## 5. Data Schema Strategy — Godot **Resources (.tres)** (see ADR-001)

Custom `Resource` subclasses with `class_name` + `@export` typed fields, edited as `.tres`. Chosen over raw JSON for type safety, editor authoring, and `GameData` loading via `ResourceLoader`. (Designer-bulk tables may be authored in CSV/JSON and imported to `.tres` by a small tool later if needed.)

Config sets (`src/data/`): `skills/*.tres`, `enemies/*.tres`, `affixes/*.tres`, `stages/*.tres`, `talents/*.tres`. Field-level schemas are owned by the GDD (§2–§7); `types/*.gd` are the typed containers.

**Item instances** are runtime data (not config): built by `LootSystem` from a stored `seed` so an item re-serializes/re-rolls identically (determinism).

---

## 6. Data Flow (signal sequences)

**Combat tick:** `battle.gd._process` → `SkillSystem.update` (auto-cast ready skills) + `CombatSystem.tick` → `resolve_hit` uses `formulas` + `Rng(combat)` for crit → emit `damage_dealt` (HUD floats a `DamageText` from pool) → if lethal emit `enemy_died` → `ProgressionSystem.add_kill_rewards` + `LootSystem.roll_drop`.

**Loot drop:** `enemy_died` → `LootSystem.roll_drop` (drop-chance, quality weights by layer, itemLevel, affixes — all via `Rng(loot)`) → `loot_dropped(item)` → inventory model adds it; HUD plays fly-to-bag (M5).

**Equip swap:** UI selects item → `EquipmentSystem.compare(item)` → panel shows per-stat + power delta → on confirm `equip(item)` → `recompute_stats()` → `stats_recomputed` → next combat tick uses new stats (satisfies AC-EQ2 / M2 PASS).

---

## 7. Save System

`user://save.json` (JSON via `JSON.stringify`/`parse`). On Web export, `user://` maps to browser persistent storage (IndexedDB) → survives refresh (satisfies M4 PASS). Saved fields = GDD §8 list **plus** `rng_master_seed` and a `save_version` int for forward migration. Autosave on: layer end, equip, talent change, level-up. Load at boot → hydrate systems → `recompute_stats()`.

---

## 8. Determinism

One `Rng` autoload seeded from `rng_master_seed` (persisted). Named sub-streams (`loot`, `combat`, `affix`) seeded deterministically from the master so categories don't interfere. Items store their own `seed`. Tests assert: same seed + same inputs → identical loot/affix/crit sequences (coding-standard requirement; no `randomize()` in gameplay paths).

---

## 9. Performance (mobile + web budgets: 60fps / 16.6ms / ≤100 draw calls / ≤512MB)

- **Object pooling** for `Enemy`, `Projectile`, `DamageText` (never instantiate/free mid-fight).
- Texture **atlases** + shared `CanvasItemMaterial` to keep 2D draw calls low; one CanvasLayer per panel.
- Cap concurrent enemies per wave (config) to bound work on low-end devices.
- Status/DoT ticks on a fixed accumulator, not per-frame allocation.
- Profile on a mid-tier Android + Web export before M5.

---

## 10. Test Approach (GDUnit4)

CI: `godot --headless --script tests/gdunit4_runner.gd` (matches coding-standards).
- **Unit (blocking)**: `formulas.gd` (damage/power/growth/itemPower), `LootSystem` rolls (seeded), `EquipmentSystem.recompute_stats`, `TalentSystem` spend/reset, `SaveSystem` round-trip, enemy growth.
- **Integration**: enter-layer auto-combat, equip-changes-next-fight, boss-win flow, save→reload.
- **Advisory (evidence)**: HUD/compare panel walkthroughs, VFX/feel (M5).

---

## 11. Key Decisions → ADRs
- **ADR-001** — Config as Godot Resources (.tres) over JSON.
- **ADR-002** — Logic/presentation separation via EventBus + dependency-injected systems (testability).
- **ADR-003** — Single seeded RNG service with named streams (determinism).
(See `docs/architecture/adr/`.)

---

## 12. Godot 4.6 API Notes / Uncertainties (cross-checked vs `docs/engine-reference/godot/`)
- Godot **4.6 is beyond the model's ~4.3 training cutoff (HIGH risk)** — implementers must verify against the pinned reference, especially: renderer naming (GL Compatibility), `@export` typed Resource arrays, and any web-export storage specifics. **Flagged for verification during M1**, not assumed.
- Physics: Area2D overlap only (no rigid bodies) — confirm Area2D signal names in 4.6 before coding `enemy.gd`.
- Web persistence of `user://`: verify current 4.6 HTML5 export behavior (IndexedDB sync timing) during M4.

---

## 13. Open Technical Questions for the Gate
1. Confirm `.tres` Resources over JSON for designer-authored tables (ADR-001) — acceptable, or prefer JSON for faster bulk editing?
2. Battle as single scene with overlay panels (vs separate scenes) — confirm.
3. Web export: is HTML5 a true MVP target now, or PC/Android first then web? (affects how early we test `user://` persistence).
