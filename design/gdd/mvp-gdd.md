# MVP Game Design Document — 《余烬深渊》 *Ashsworn: The Cinder Deep*

*Created: 2026-06-07 · Status: Draft (pending §12 gate approval)*
*Engine: Godot 4.6 / GDScript · Target: portrait mobile 9:16 · Authoritative names: `design/gdd/game-concept.md` (Naming Bible)*

> This is a **consolidated** MVP GDD: one doc, one section per system. All numbers below are **starter values that live in config** (`src/data/`), never hardcoded. Economy-designer refines drop/exp/curve numbers in Milestone 2. RNG is seeded — every random result must replay identically from a seed.

---

## 0. Core Loop & Feedback Cadence (recap)

`进入层 → 自动战斗 → 掉落 → 换装/比较 → 加天赋/升级 → 突破更深层`

| Cadence | Player gets |
| ---- | ---- |
| every ~30s | kill, damage numbers, crit, status proc, a drop |
| every ~3min | level-up, gear swap, talent point, visible stat change |
| every ~10min | power spike — break a stuck layer or kill the Lord of Cinders |

**MVP validates ONE thing:** will the player tap "next layer." Everything serves that.

---

## 1. Combat System

### Overview
Fully automated real-time combat on a portrait field. The hero stands/advances; enemies spawn in waves from the top and move toward the hero. The hero auto-targets, auto-attacks, and auto-casts skills. The player optionally taps a skill to fire it early.

### Player Fantasy
"My build does the work." Power expression = watching numbers climb because of decisions made in the inventory/talent screens.

### Detailed Rules
- **Targeting**: hero auto-selects the **nearest living enemy** each time it needs a target (`target = min by distance`). Re-target if current target dies or leaves range.
- **Auto-attack**: fires every `1 / attack_speed` seconds, dealing `ember_swing` (physical). `attack_speed` in attacks/sec.
- **Active skills**: 3 skills each have a `cooldown`. On cooldown-ready, auto-cast in priority order if a valid target/positioning exists. Manual tap fires immediately if off cooldown (then restarts cooldown).
- **Damage** uses the §Formulas pipeline. **Crit** rolls per hit at `crit_rate`.
- **Status effects**: applied by skills/affixes; tick independently:
  - `burn` — fire DoT, `burn_dps` for `burn_duration`, stacks refresh duration.
  - `poison` — physical/nature DoT, stacks add (configurable max stacks).
  - `freeze` — target cannot act for `freeze_duration`; `slow` reduces move/attack speed by `slow_pct`.
- **Waves**: each layer defines an ordered wave list. A wave clears when all its enemies die; next wave spawns after `wave_gap` seconds. Boss is the final "wave" on boss layers.
- **Win**: all waves (incl. boss) cleared → Victory → Results panel.
- **Lose**: hero hp ≤ 0 → Defeat → Results panel; **progression (level/exp/gold/gear/talents) is retained**, the layer is simply not advanced.

### Formulas (authoritative — from concept doc §8)
```
baseDamage     = attack * skillMultiplier
critMultiplier = isCrit ? (1 + critDamage) : 1
armorReduction = enemyArmor / (enemyArmor + 100)
finalDamage    = baseDamage * critMultiplier * (1 - armorReduction)
```
DoT damage uses the same `finalDamage` pipeline with the DoT's own multiplier and the tag's element. Elemental skills add `elementalDamage` as bonus flat damage of that element (pre-armor for elemental portion — see Edge Cases).

### Edge Cases
- No enemies present → hero idles, skills hold at ready (no cooldown waste).
- Multiple enemies equidistant → deterministic tiebreak by spawn index (seed-stable).
- `armorReduction` capped implicitly ≤ ~0.9 by formula shape; document that very high armor still lets some damage through.
- Freeze + ongoing DoT: DoT keeps ticking while frozen.
- Simultaneous hero & last-enemy death in same tick → resolve enemy death first only if it was already lethal; otherwise hero death → Defeat (define order in CombatSystem and unit-test it).

### Dependencies
SkillSystem, EnemySpawnSystem, EquipmentSystem (final hero stats), TalentSystem (stat mods), Rng (crit/loot), EventBus (damage/kill/spawn signals), ProgressionSystem (rewards on kill).

### Tuning Knobs
`attack_speed` base, `wave_gap`, per-status durations/dps, crit tiebreak rule, auto-cast priority order, target re-acquire interval.

### Acceptance Criteria
- AC-CB1: On entering a layer the hero auto-attacks the nearest enemy without input. *(Integration)*
- AC-CB2: Each skill fires automatically on cooldown and respects its cooldown. *(Logic)*
- AC-CB3: `finalDamage` matches the formula for given inputs incl. crit and armor. *(Logic — unit test)*
- AC-CB4: burn/freeze/poison/slow apply, tick, and expire per their config. *(Logic)*
- AC-CB5: Killing the layer-10 boss shows a Victory result; hero death shows Defeat with progression intact. *(Integration)*

---

## 2. Skill System

### Overview
Data-driven skills. MVP ships 1 auto + 3 actives; the system supports 4 element tags so fire/lightning skills are pure data additions later.

### Skill Data Schema (`src/data/skills`)
| Field | Type | Notes |
| ---- | ---- | ---- |
| `id` | StringName | e.g. `cleaving_blow` |
| `display_name` | String | 中文/English |
| `tag` | enum | `physical` / `fire` / `ice` / `lightning` |
| `skill_multiplier` | float | feeds `baseDamage` |
| `cooldown` | float | seconds (0 / auto for ember_swing) |
| `target_mode` | enum | `single` / `aoe_around_hero` / `aoe_at_target` |
| `aoe_radius` | float | px (0 for single) |
| `status` | StringName? | applied status id (nullable) |
| `status_chance` | float | 0–1 |
| `is_auto_attack` | bool | true only for ember_swing |
| `auto_cast_priority` | int | lower = earlier |

### MVP Skill Set (starter values — config)
| Skill | tag | mult | cd | target | status |
| ---- | ---- | ---- | ---- | ---- | ---- |
| 余烬挥斩 Ember Swing `ember_swing` | physical | 1.0 | auto | single | — |
| 裂石斩 Cleaving Blow `cleaving_blow` | physical | 2.4 | 4s | single | — |
| 裂地回旋 Riftwind `riftwind` | physical | 1.3 | 7s | aoe_around_hero (r=180) | — |
| 霜噬冲击 Frostmaw Surge `frostmaw_surge` | ice | 1.6 | 9s | aoe_at_target (r=140) | `freeze` 60% |

### Acceptance Criteria
- AC-SK1: Adding a new skill row (e.g. a `fire` skill) requires no code change. *(Config)*
- AC-SK2: Each MVP skill applies its tag, multiplier, cooldown, AoE, and status as configured. *(Logic)*
- AC-SK3: Frostmaw Surge freezes targets at the configured chance (seeded test). *(Logic)*

---

## 3. Enemy System

### Overview
3 normal archetypes + 1 boss. Stats scale per layer via the growth formulas.

### Enemy Data Schema (`src/data/enemies`)
`id`, `display_name`, `base_hp`, `base_attack`, `base_armor`, `move_speed`, `attack_interval`, `xp_reward`, `gold_reward`, `is_boss`, `sprite_key`.

### Growth (authoritative)
```
enemyHp     = base_hp     * (1 + stageLevel * 0.18)
enemyAttack = base_attack * (1 + stageLevel * 0.12)
enemyArmor  = base_armor  * (1 + stageLevel * 0.08)
```
(`stageLevel` = layer index, 1–10.)

### MVP Enemies (starter base stats — config)
| Enemy | base_hp | base_atk | base_armor | move | profile |
| ---- | ---- | ---- | ---- | ---- | ---- |
| 余烬游魂 Cinder Wisp `cinder_wisp` | 60 | 8 | 0 | fast (140) | fragile swarm |
| 碎甲傀儡 Slagbound Husk `slagbound_husk` | 220 | 12 | 40 | slow (50) | armored tank |
| 噬骨爬虫 Bonegnaw Crawler `bonegnaw_crawler` | 120 | 16 | 12 | med (90) | bruiser |
| 焚誓领主 Lord of Cinders `lord_of_cinders` | 1400 | 30 | 30 | slow (45) | L10 boss, guaranteed epic+ drop |

### Edge Cases
- Boss layers spawn only the boss as the final wave (no trash mixed into boss wave unless configured).
- Enemies that reach the hero deal `enemyAttack` every `attack_interval`.

### Acceptance Criteria
- AC-EN1: Each enemy spawns, moves toward hero, attacks, dies, and grants xp/gold. *(Integration)*
- AC-EN2: Enemy stats equal the growth formula for a given layer. *(Logic — unit test)*

---

## 4. Equipment System

### Overview
6 slots, 5 qualities, one main stat + rolled affixes per item. Equipping recomputes hero final stats. A **compare panel** shows the delta vs the currently-equipped item before the player swaps.

### Slots & Main Stats
| Slot `id` | 中文 | primary main stat |
| ---- | ---- | ---- |
| `weapon` | 武器 | attack |
| `helm` | 头盔 | hp |
| `chest` | 胸甲 | hp / armor |
| `gloves` | 手套 | attack_speed |
| `boots` | 战靴 | armor |
| `amulet` | 项链 | elemental_damage |

### Qualities (→ multiplier, from concept doc)
锈蚀 common 1.0 · 灼印 magic 1.25 · 淬火 rare 1.6 · 焚誓 epic 2.1 · 渊心 legendary 2.8.
Affix count by quality: common 0, magic 1, rare 2, epic 3, legendary 4.

### Item Power (authoritative)
```
itemPower      = itemLevel * qualityMultiplier
mainStatValue  = round(itemPower * slot_main_coeff)
affixValue     = roll within [affix_min, affix_max] * qualityMultiplier   # seeded roll
```

### Affix Pool (`src/data/equipment_affixes`)
`hp`, `attack`, `armor`, `crit_rate`, `crit_damage`, `attack_speed`, `cooldown`, `elemental_damage`. Each affix: `id`, `stat`, `min`, `max`, `is_percent`, `allowed_slots`.

### Equipment Data Schema
Item instance: `slot`, `quality`, `item_level`, `main_stat`, `main_value`, `affixes[]` (stat+value), `seed` (so it re-rolls identically). Stored in inventory list + equipped map (slot→item).

### Detailed Rules
- Hero **final stats** = base + Σ(equipped main stats) + Σ(equipped affixes) + Σ(talent mods), recomputed on any change. Single `recompute_stats()` is the source of truth.
- Compare: selecting an inventory item shows, per stat, `new − equipped` (green/red), plus power delta via the power() formula.
- Swapping moves old item back to inventory; no item is destroyed in MVP.

### Edge Cases
- Empty slot compare = compare against zero.
- Same item re-rolled must reproduce identical affixes from its stored `seed`. *(determinism)*
- Two-stat slot (`chest`) picks main stat deterministically from item seed.

### Acceptance Criteria
- AC-EQ1: Boss drops an item the player can view, compare, and equip. *(Integration)*
- AC-EQ2: After equipping, the next fight's damage/power numbers change to match recomputed stats. *(Integration — source PASS criterion for M2)*
- AC-EQ3: `itemPower`, main stat, and affix values match formulas for a given seed. *(Logic — unit test)*
- AC-EQ4: Compare panel shows correct per-stat and power deltas. *(UI)*

---

## 5. Talent System — Path of Cinders

### Overview
One base tree. Level-ups grant talent points; spending lights nodes (respecting prerequisites); nodes apply to **real hero stats**; full reset refunds all points.

### Talent Node Schema (`src/data/talents`)
`id`, `display_name`, `category` (`attack`/`hp`/`crit`/`cooldown`/`elemental`), `stat`, `value_per_rank`, `is_percent`, `max_rank`, `cost_per_rank`, `requires[]` (node ids), `grid_pos` (x,y for layout).

### Example Tree (~14 nodes, starter)
- Tier 0 (no prereq): `ember_might` (+attack), `ember_vigor` (+hp).
- Tier 1 (req tier 0): `keen_edge` (+crit_rate, req ember_might), `thick_hide` (+armor, req ember_vigor), `swift_hands` (+attack_speed, req ember_might).
- Tier 2: `cruel_strikes` (+crit_damage, req keen_edge), `rapid_oath` (+cooldown reduction, req swift_hands), `searing_brand` (+elemental_damage, req ember_might).
- Tier 3: `bonfire_heart` (+hp%, req thick_hide), `executioner` (+crit_damage%, req cruel_strikes).
- Capstones (Tier 4, high cost): `cinderlord` (+attack% & +elemental%, req searing_brand + executioner), `unbroken` (+hp% & +armor%, req bonfire_heart).
*(Exact values are Tuning Knobs in config.)*

### Detailed Rules
- Points granted: `talent_points_per_level` per level-up (starter = 1).
- A node rank can be raised only if `current_points ≥ cost` and all `requires` nodes are at ≥ rank 1.
- Reset: refund all spent points, clear all node ranks, recompute stats. Free in MVP.

### Acceptance Criteria
- AC-TL1: Spending an attack node measurably raises damage in the next fight; reset restores prior values. *(Logic + Integration — source PASS criterion for M3)*
- AC-TL2: A node cannot be lit unless prerequisites are met and points suffice. *(Logic)*
- AC-TL3: Reset refunds exactly the points spent. *(Logic)*

---

## 6. Stage / Layer System

### Overview
10 layers, increasing difficulty. Each defines its waves, enemy mix, rewards, and drop profile. Failure never costs progression.

### Layer Data Schema (`src/data/stages`)
`layer` (1–10), `waves[]` (each: enemy id list + counts), `wave_gap`, `gold_reward`, `xp_reward`, `drop_level`, `drop_quality_weights`, `is_boss_layer`, `unlocks_next`.

### Rules
- Layers 1–9: 3–5 waves of normal enemies (mix ramps up). Layer 10: short waves + `lord_of_cinders` boss.
- Clearing a layer marks the next unlocked; player may replay earlier layers to farm.
- `drop_level` feeds `itemLevel`; `drop_quality_weights` bias the rarity roll (deeper = better).

### Tuning Knobs
wave composition per layer, `drop_level` curve, quality weight curve, reward curve.

### Acceptance Criteria
- AC-ST1: Layers advance only after full clear; failure keeps progression and lets retry. *(Integration)*
- AC-ST2: Layer 10 spawns the boss as the final wave and gates better loot. *(Integration)*

---

## 7. Progression & Economy (starter — economy-designer refines in M2)

### Leveling
- Hero level 1→20 for MVP. EXP curve (Tuning Knob, starter):
  `xp_to_next(level) = round(50 * level^1.6)`  → L1→2 = 50, L5→6 ≈ 655, L10→11 ≈ 1990, L20 cap.
- On level-up: +base stat growth (config) and +`talent_points_per_level`.

### Currency & Rewards
- `gold` and `xp` granted per kill (`enemy.xp_reward`, `enemy.gold_reward`) + layer-clear bonus.
- Gold's MVP sink = none required (no shop in MVP); kept for save + future. *(Flag: confirm whether gold has any MVP use; default = display + future-proof only.)*

### Drop Rates (starter table — per non-boss kill, config `drop_quality_weights` scaled by layer)
| Quality | L1 weight | L10 weight |
| ---- | ---- | ---- |
| 锈蚀 common | 60 | 20 |
| 灼印 magic | 28 | 30 |
| 淬火 rare | 9 | 30 |
| 焚誓 epic | 2.5 | 16 |
| 渊心 legendary | 0.5 | 4 |
- **Drop chance per kill** (whether anything drops): starter 35% normal kill, 100% boss (guaranteed epic+). Ensures "frequent gear in first 10 minutes."

### Power Rating (player-facing 战力)
```
power = attack*3 + hp*0.3 + armor*2 + critRate*100 + critDamage*50 + attackSpeed*80 + elementalDamage*2
```

### Acceptance Criteria
- AC-PR1: First 10 minutes of play yield multiple gear drops (drop cadence test). *(Logic/sim)*
- AC-PR2: power() recomputes and displays correctly after any stat change. *(Logic)*
- AC-PR3: No runaway inflation — at L10 with rare gear, hero power vs boss is within a tunable win-band (balance sim). *(Logic/sim — economy-designer M2)*

---

## 8. Save System (design-facing; tech in TDD)

Persist: `hero_level`, `xp`, `gold`, `current_layer`/`max_layer_cleared`, `equipped` map, `inventory` list (each item incl. its `seed`), `talents` (node ranks + spent points), `rng_master_seed`. Survives browser/app refresh.

### Acceptance Criteria
- AC-SV1: After a refresh, all of the above is exactly restored. *(Integration — source PASS criterion for M4)*

---

## 9. Cross-System Dependencies (summary)

```
EquipmentSystem ┐
TalentSystem    ├─► recompute_stats() ─► hero final stats ─► CombatSystem/SkillSystem
LayerSystem ─► EnemySpawnSystem ─► (kills) ─► ProgressionSystem(xp/gold) + LootSystem(drops)
LootSystem ─► Inventory ─► EquipmentSystem
All ─► SaveSystem (state) · All randomness ─► Rng(seed)
```

---

## 10. Open Questions for the Review Gate
1. Does **gold** need a sink in MVP (e.g., reroll affix / reset cost), or is it display-only + future-proofing? *(Recommend: display-only in MVP.)*
2. Hero level cap: 20 enough for a 10-layer MVP, or 30? *(Recommend: 20.)*
3. Manual skill taps: ship in MVP or M5 polish? *(Recommend: minimal manual-tap in M1, juice in M5.)*
4. Bilingual UI: ship Chinese-primary with English in data, or English UI? *(Recommend: Chinese-primary UI, both names in data.)*

*Numbers invented beyond source (flagged for reconciliation): all starter base stats, skill multipliers/cooldowns, affix counts per quality, exp curve, drop-rate weights/chances, talent tree composition. The **formulas** are all verbatim from source §8.*
