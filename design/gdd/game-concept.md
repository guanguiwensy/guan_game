# Game Concept: 《余烬深渊》 (working title) — *Ashsworn: The Cinder Deep*

*Created: 2026-06-07*
*Status: Draft — pending GDD/TDD/Milestone bundle approval (source-doc §12 gate)*

> Original IP. Inspired only by the *general genre structure* of loot-driven auto-battle ARPGs.
> No names, art, UI, characters, item names, skill names, numbers, or copy are taken from any existing title.

---

## Elevator Pitch

> It's a **portrait-mobile idle ARPG** where you descend an endless cursed abyss as a lone ember-bound warrior — your hero **auto-fights** wave after wave, and *you* shape the build: swap loot, slot affixes, and spend talent points to break through each layer and topple its Lord of Cinders.

10-second test: *"Tap in, watch your warrior auto-clear monsters, grab better gear, get visibly stronger, push the next floor."* ✔

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Idle / auto-battle Action-RPG (loot + build) |
| **Platform** | Mobile (Android/iOS) portrait 9:16, primary; Web (HTML5) secondary |
| **Target Audience** | 18–40, mid-core loot-ARPG & idle-RPG players |
| **Player Count** | Single-player |
| **Session Length** | 3–10 min bursts (idle-friendly) |
| **Monetization** | None in MVP (premium/none — validate the loop first) |
| **Estimated Scope** | Small — 7-day playable MVP, then iterate |
| **Comparable Titles** | Generic loot-ARPG & idle-RPG genre conventions only (no specific title copied) |

---

## Core Fantasy

**You are the last Ashen Warden, descending the Maw to reclaim the ember of your broken oath.** The fantasy is *the satisfying snowball of power* — you don't grind inputs, you grind **decisions**. Every layer your warrior fights on its own; your power comes from reading the loot, committing to a build, and feeling the next floor melt where the last one was a wall.

---

## Unique Hook

It's a loot-ARPG, **AND ALSO** it's built for the 30-second idle glance: combat resolves itself with juicy feedback, so the entire game *you* play is the **build meta-loop** — compare-and-swap gear, affix synergy, talent pathing — distilled into a one-thumb portrait screen. The hook is **"all build, no busywork."**

---

## Core Loop

- **Moment-to-moment (30s)**: Hero auto-targets nearest enemy, auto-attacks by attack speed, auto-casts the 3 skills on cooldown. Feedback: hit flashes, damage numbers, crits, status procs (burn/freeze/poison), loot pops. *Player watches and lands the occasional manual skill tap.*
- **Short-term (3 min)**: Clear a layer's waves → boss-or-not → results panel → **level up, swap a piece of gear, spend a talent point**, see power change.
- **Session (10 min)**: A visible **power spike** — break a stuck layer or kill a Lord of Cinders, jump 1–2 floors.
- **Long-term**: Push deeper into the Maw (stages), chase higher-quality affixed gear, complete the talent tree.
- **Retention**: *Curiosity* (next floor's enemies/boss), *Investment* (saved build + hoarded gear), *Mastery* (optimizing affix + talent synergy).

---

## Game Pillars

1. **Playable loop above all** — every feature serves "fight → loot → swap → grow → deeper." If it doesn't, it's cut or deferred. *Test: complex UI vs. another working loop step → loop wins.*
2. **The build is the game** — depth lives in gear/affix/talent decisions, not in twitch input. *Test: add manual dodge vs. add an affix synergy → synergy wins.*
3. **Readable power** — the player must always see *why* they got stronger (number, drop, node). *Test: hidden elegant formula vs. visible chunky stat → visible wins.*
4. **Data-driven & reproducible** — all balance in config, all RNG seedable. *Test: hardcode a tuned value vs. add a config row → config wins.*

### Anti-Pillars (what this game is NOT)
- **NOT a twitch action game** — no manual dodging/aiming skill-checks in MVP.
- **NOT content-broad** — MVP is one hero, 10 layers, one boss; depth over breadth.
- **NOT monetized yet** — no shop/gacha/ads until the loop is proven fun.
- **NOT a copy** — zero assets/names/numbers from any reference title.

---

## Original IP Naming Bible  *(SHARED SOURCE OF TRUTH — all GDD/TDD/code/UI use these names)*

> Display names are bilingual (中文 / English). **Code IDs** are the snake_case/PascalCase identifiers used in data files and scripts.

### World & Hero
| Concept | 中文 | English | Code ID |
| ---- | ---- | ---- | ---- |
| Title (working) | 余烬深渊 | Ashsworn: The Cinder Deep | — |
| Setting | 噬渊（无尽深渊） | The Maw | — |
| Stage unit | 下降层 | Descent Layer | `layer` / `stage` |
| Hero | 余烬守望者 | the Ashen Warden | `ashen_warden` |
| Hero archetype | 近战誓战士 | melee oath-warrior | — |

### Skills (1 auto + 3 active)
| Source ref | 中文 | English | Code ID | Tag | Role |
| ---- | ---- | ---- | ---- | ---- | ---- |
| auto attack | 余烬挥斩 | Ember Swing | `ember_swing` | physical | basic auto-attack, scales with attack speed |
| 重斩 | 裂石斩 | Cleaving Blow | `cleaving_blow` | physical | single-target high damage |
| 旋风斩 | 裂地回旋 | Riftwind | `riftwind` | physical | AoE around hero |
| 冰霜冲击 | 霜噬冲击 | Frostmaw Surge | `frostmaw_surge` | ice | AoE + slow/freeze |

*Skill system supports all 4 element tags: `physical` / `fire` / `ice` / `lightning`. MVP ships physical + ice skills; fire/lightning exist as affix/talent damage and future skills.*

### Status Effects
暴击 crit · 燃烧 burn (`burn`) · 冰冻 freeze (`freeze`) · 中毒 poison (`poison`) · 减速 slow (`slow`)

### Enemies (3 normal + 1 boss)
| Role | 中文 | English | Code ID | Profile |
| ---- | ---- | ---- | ---- | ---- |
| normal A | 余烬游魂 | Cinder Wisp | `cinder_wisp` | fast, fragile, swarms |
| normal B | 碎甲傀儡 | Slagbound Husk | `slagbound_husk` | slow, high armor, tanky |
| normal C | 噬骨爬虫 | Bonegnaw Crawler | `bonegnaw_crawler` | balanced melee bruiser |
| boss (L10) | 焚誓领主 | Lord of Cinders | `lord_of_cinders` | layer-10 boss, gated loot |

### Equipment — 6 slots
武器 Weapon `weapon` · 头盔 Helm `helm` · 胸甲 Chestplate `chest` · 手套 Gauntlets `gloves` · 战靴 Greaves `boots` · 项链 Amulet `amulet`

### Equipment — 5 qualities (flavor name → generic tier → multiplier from source §8)
| 中文 | English flavor | Generic tier | Code ID | qualityMultiplier |
| ---- | ---- | ---- | ---- | ---- |
| 锈蚀 | Worn | common | `common` | 1.0 |
| 灼印 | Touched | magic | `magic` | 1.25 |
| 淬火 | Tempered | rare | `rare` | 1.6 |
| 焚誓 | Ashforged | epic | `epic` | 2.1 |
| 渊心 | Cinderborn | legendary | `legendary` | 2.8 |

### Affixes (sub-stats)
生命 HP `hp` · 攻击 Attack `attack` · 护甲 Armor `armor` · 暴击率 Crit Rate `crit_rate` · 暴击伤害 Crit Damage `crit_damage` · 攻速 Attack Speed `attack_speed` · 冷却缩减 Cooldown `cooldown` · 元素伤害 Elemental Damage `elemental_damage`

### Talent Tree
余烬之路 / **Path of Cinders** (`path_of_cinders`) — one base tree; node categories: 攻击 / 生命 / 暴击 / 冷却 / 元素伤害, with prerequisite edges and full reset.

---

## MVP Definition

**Core hypothesis**: *Players will want to push the next layer because "fight → loot → swap → grow → deeper" is satisfying on its own.*

**Required for MVP** (locked from source-doc §4):
1. 1 hero, auto basic attack + 3 active skills (cooldown auto-cast), wave spawning, boss fight
2. 3 normal enemies + 1 boss (hp / attack / armor / move speed, config-driven)
3. Equipment: 6 slots × 5 qualities, main stat + affixes, **compare-on-swap UI**, gear changes next fight's numbers
4. 1 talent tree (attack/hp/crit/cooldown/elemental), point spend, prerequisites, reset
5. 10 layers (wave/reward/drop-level config), progress persists on failure
6. Local save: level, exp, gold, current layer, equipment, inventory, talents (survives browser/app refresh)
7. Portrait HUD + inventory + talent + results screens

**Explicitly NOT in MVP**: offline-earning calc, shop/monetization, multiple heroes/classes, fire/lightning *skills* (tags only), events/dungeons, crafting beyond swap, prestige.

### Scope Tiers
| Tier | Content | Timeline |
| ---- | ---- | ---- |
| **MVP** | core loop, 10 layers, 1 boss, 1 hero | ~7 days |
| **Vertical Slice** | + game-feel polish, full talent tree, juiced VFX | +1 week |
| **Alpha** | + offline earnings, 2nd skill set, more enemies/layers | later |

---

## Key Formulas (carried verbatim from source-doc §8 — authoritative)

```
# Damage
baseDamage     = attack * skillMultiplier
critMultiplier = isCrit ? (1 + critDamage) : 1
armorReduction = enemyArmor / (enemyArmor + 100)
finalDamage    = baseDamage * critMultiplier * (1 - armorReduction)

# Power rating
power = attack*3 + hp*0.3 + armor*2 + critRate*100 + critDamage*50 + attackSpeed*80 + elementalDamage*2

# Enemy growth by layer (stageLevel)
enemyHp     = baseHp     * (1 + stageLevel * 0.18)
enemyAttack = baseAttack * (1 + stageLevel * 0.12)
enemyArmor  = baseArmor  * (1 + stageLevel * 0.08)

# Equipment quality
qualityMultiplier: common 1.0 | magic 1.25 | rare 1.6 | epic 2.1 | legendary 2.8
itemPower = itemLevel * qualityMultiplier
```

---

## Risks & Open Questions
- **Design**: auto-battle may feel passive → mitigate with strong feedback + manual skill taps + frequent meaningful drops (every 30s feedback, 3min growth).
- **Balance**: power inflation across 10 layers → enemy-growth + quality multipliers are fixed; validate with seeded sims.
- **Scope**: 7-day MVP is tight → milestone gating (each ends in a runnable build), files ≤400 lines, defer all polish to Milestone 5.
- **Open**: exact drop-rate table & 1–50 level curve → owned by economy-designer in the GDD.

---

## Next Steps
- [ ] GDD authored (game-designer) → `design/gdd/`
- [ ] TDD / architecture authored (technical-director) → `docs/architecture/`
- [ ] Milestone plan authored (producer) → `production/milestones/`
- [ ] ⏸ Present bundle → user confirmation gate (source-doc §12) before any code
