# 《余烬深渊》 · Ashsworn: The Cinder Deep

A vertical, mobile-first **idle / auto-battle ARPG** (original IP). You play the lone
**Ashen Warden** descending an endless cursed abyss — your hero auto-fights wave after wave,
and *you* shape the build: loot gear, slot affixes, spend talent points, and break through
each layer to topple its **Lord of Cinders**.

> **Status: playable MVP complete.** Core loop end-to-end: menu → auto-battle → loot →
> compare/equip → level-up → talents → deeper layers → progress autosaved.

---

## Core loop

`进入层 → 自动战斗 → 掉落装备 → 背包对比换装(战力实时变化)→ 升级得天赋点 → 天赋加点 → 突破更深层 → 自动存档`

- **Combat** — hero auto-targets the nearest enemy, auto-attacks by attack speed, auto-casts
  3 active skills on cooldown (or tap to fire manually; toggle auto-cast off). Crit, burn,
  freeze, poison, slow. Waves + a layer-10 boss.
- **Loot** — 6 slots × 5 qualities (锈蚀/灼印/淬火/焚誓/渊心), main stat + rolled affixes,
  seeded & reproducible. Compare-on-swap shows the per-stat and power delta before you equip.
- **Talents** — *Path of Cinders*, a 14-node tree with prerequisites, ranks, and full reset.
- **Save** — progress (level/xp/gold/layer/equipment/inventory/talents) persists to
  `user://save.json`; on Web that is IndexedDB-backed, so a refresh keeps your run.

All gameplay numbers are **data-driven** (`src/data/*.tres`) and all randomness flows
through one **seeded** RNG service, so results reproduce.

---

## Run it

Requires **Godot 4.6** (GDScript). No external addons.

```bash
# Open in the editor
godot --path . -e

# Or run the game directly
godot --path . res://src/scenes/main_menu.tscn
```

Click **进入深渊 (Descend)**. Debug: the HUD's `→ L10` button jumps straight to the boss.

## Build the data / run tests

```bash
# (Re)generate config resources after editing values in tools/generate_data.gd
godot --headless --path . --script tools/generate_data.gd

# Headless test suite (46 tests; exit 0 = pass) — also runs in CI on every push
godot --headless --path . --script tests/run_tests.gd
```

---

## Tech

| | |
|---|---|
| Engine | Godot 4.6 |
| Language | GDScript (static typing enforced) |
| Renderer | GL Compatibility (mobile + web reach) |
| Target | Portrait 9:16 (1080×1920), Android/iOS + Web |
| Architecture | Logic ⟂ presentation: systems are dependency-injected, signal-based, and headless-testable; UI never drives logic |
| Tests | Zero-dependency headless runner + GitHub Actions CI |

## Project structure

```
src/
  combat/      battle_engine, combat_system, skill_system, combat_actor, status_effect
  loot/        loot_system
  equipment/   equipment_system
  talents/     talent_system
  entities/    hero_view, enemy_view, damage_text
  ui/          battle_hud, inventory_panel, talent_tree_panel, result_panel
  scenes/      main_menu, battle
  autoload/    EventBus, GameData, SaveSystem, Rng, Player
  types/       typed config + runtime data containers
  data/        skills, enemies, stages, affixes, talents (.tres config)
tools/         generate_data.gd
tests/         unit/ + integration/  (run_tests.gd)
design/ docs/ production/   design docs, ADRs, milestone plan
```

Design docs: `design/gdd/` (concept + naming bible + GDD), `docs/architecture/` (TDD + ADRs),
`production/milestones/`.

## Milestones

| Milestone | Status |
|---|---|
| M0 — Project scaffold | ✅ |
| M1 — Combat sandbox | ✅ |
| M2 — Loot & equipment | ✅ |
| M3 — Talents | ✅ |
| M4 — Save | ✅ |
| M5 — Game feel | ✅ |

Next (optional): cooldown-affix CDR, real art/audio, balance tuning, more layers/skills.

## Original IP

100% original world, characters, names, art direction, and numbers. Inspired only by the
general *genre structure* of loot-driven auto-battle ARPGs — nothing is copied from any
existing title.

## Credits

Scaffolded and built with the multi-agent **[Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)** workflow (MIT). The original template README is preserved at `docs/CCGS-TEMPLATE-README.md`.
