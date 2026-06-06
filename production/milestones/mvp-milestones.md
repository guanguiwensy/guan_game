# MVP Milestone Plan — 《余烬深渊》 *Ashsworn: The Cinder Deep*

*Created: 2026-06-07 · Status: Draft (pending §12 gate) · Owner: producer*
*Scope: 7-day lean MVP · Engine: Godot 4.6 / GDScript · Refs: game-concept.md, mvp-gdd.md, mvp-tdd.md*

> Backbone = source §9 (5 milestones). Pass criteria are kept verbatim where the source gives them. **Every milestone ends in a build that runs** (source §11: "每日构建目标:当天结束时游戏仍然能运行"). Polish is forbidden until the playable loop exists (M5 only).

## Definition of Done — per module (source §11, applies to ALL milestones)
1. **Playable loop first** — never prioritize complex UI or content over a working loop step.
2. **Minimal-runnable first** — each system ships its smallest working version before extension.
3. **Data-driven** — all numbers in `src/data/`; zero hardcoded gameplay values.
4. **Seeded RNG** — all randomness reproducible via `Rng` (no `randomize()` in gameplay).
5. **File size ≤ 400 lines** — split before exceeding.
6. **QA writes results per module** — `/qa-plan` → `/smoke-check`; evidence filed.
7. **Bug protocol** — repro steps first, then fix.
8. **Daily build runs** — end each day on a launchable build.

## Timeline (7 days, single dev + CCGS agents)

| Day | Focus |
| ---- | ---- |
| 0 (½) | **M0** Tech setup: `project.godot`, autoloads, `/test-setup` (GDUnit4 + CI), data resource skeletons, `formulas.gd` + its unit tests. |
| 1–2 | **M1** Combat Sandbox |
| 3 | **M2** Loot & Equipment |
| 4 | **M3** Talents |
| 5 | **M4** Save |
| 6 | **M5** Game Feel + buffer/hardening |
| 7 | Buffer: bugfix, balance sim, build verification, playtest |

Sequencing is strictly linear (each milestone depends on the prior); M5 is the only deferrable/compressible block if days slip.

---

## M0 — Tech Setup *(Day 0, ~½ day)*
- **Goal**: an empty-but-correct skeleton that boots and runs tests.
- **Deliverables**: `project.godot` (portrait stretch, GL Compatibility), the 4 autoloads (EventBus/GameData/SaveSystem/Rng) as stubs, `types/*.gd` containers, `util/formulas.gd` with all GDD formulas, `tests/` + GDUnit4 runner + CI workflow (`/test-setup`).
- **Gate**: project launches to an empty MainMenu; `formulas.gd` unit tests pass in headless CI.
- **Drives**: technical-director + gameplay-programmer; `/test-setup`.

## M1 — Combat Sandbox *(Days 1–2)*
- **Goal**: hero, enemies, auto-attack, 3 skills, health bars, damage numbers, waves, win/lose.
- **Scope IN**: CombatSystem, SkillSystem, EnemySpawnSystem, Hero/Enemy entities (pooled), BattleHUD (hp/power/layer/wave), DamageText, the 10 stage configs (placeholder waves OK), all 4 enemies, all 4 skills.
- **Scope OUT**: loot, equipment, talents, save, polish VFX.
- **PASS (source verbatim)**: 第 10 波 Boss 死亡后出现胜利结算 — *killing the layer-10 boss shows a Victory result; hero death shows Defeat with progression intact.*
- **Test evidence**: Logic (blocking) — `formulas`, skill cooldowns, enemy growth, status effects. Integration — auto-combat + boss-win flow. UI (advisory) — HUD walkthrough.
- **Drives**: gameplay-programmer via `/dev-story`; QA via `/qa-plan` + `/smoke-check`.
- **Risk**: targeting/auto-cast feel; Godot 4.6 Area2D signal names need verification (TDD §12).

## M2 — Loot & Equipment *(Day 3)*
- **Goal**: enemies drop gear → inventory → detail/compare → equip-swap → power/damage changes.
- **Scope IN**: LootSystem (seeded drop/quality/affix rolls), EquipmentSystem (`recompute_stats`, compare), 6 slots × 5 qualities, affix pool, InventoryPanel + EquipCmparePanel, ProgressionSystem rewards. **economy-designer** tunes drop table + exp/curve here.
- **Scope OUT**: talents, save, polish.
- **PASS (source verbatim)**: 换装后下一场战斗数值真实变化 — *equipping a different item changes the next fight's numbers for real.*
- **Test evidence**: Logic (blocking) — itemPower/affix rolls (seeded), `recompute_stats`. Integration — drop→equip→next-fight delta. UI (advisory) — compare panel.
- **Drives**: economy-designer + gameplay-programmer + ui-programmer; QA each.
- **Risk**: power inflation across layers → balance sim; compare-panel correctness.

## M3 — Talents *(Day 4)*
- **Goal**: level-up grants points; light nodes; prerequisites; reset.
- **Scope IN**: TalentSystem, Path of Cinders (~14 nodes config), TalentTreePanel, stat-mod integration into `recompute_stats`.
- **PASS (source verbatim)**: 攻击天赋能提高伤害,重置后恢复 — *an attack node raises damage; reset restores.*
- **Test evidence**: Logic (blocking) — spend/prereq/reset, stat application. Integration — talent changes next-fight damage. UI (advisory) — tree panel.
- **Drives**: systems-designer (node values) + gameplay-programmer + ui-programmer.
- **Risk**: prereq graph correctness; reset refund accuracy.

## M4 — Save *(Day 5)*
- **Goal**: persist level/exp/gold/layer/equipment/inventory/talents (+ rng seed).
- **Scope IN**: SaveSystem JSON to `user://`, autosave hooks, load→hydrate→`recompute_stats`, save_version field.
- **PASS (source verbatim)**: 刷新浏览器进度仍然存在 — *refresh (browser/app) keeps progress.*
- **Test evidence**: Logic (blocking) — save/load round-trip. Integration — refresh-persists (verify Web `user://`/IndexedDB behavior in Godot 4.6, TDD §12).
- **Drives**: gameplay-programmer; QA.
- **Risk**: Web persistence timing on HTML5 export.

## M5 — Game Feel *(Day 6)* — only after the loop works
- **Goal**: hit VFX, screen shake, damage-number layering, loot fly-to-bag, auto-cast toggle.
- **Scope IN**: juice only — no new systems.
- **Gate (advisory)**: feel review + lead sign-off; no regressions to M1–M4 PASS criteria (`/regression-suite`).
- **Drives**: technical-artist + gameplay-programmer + sound-designer; `/team-polish`.
- **Risk**: scope creep — strictly time-boxed; cut first if days slip.

---

## Cross-milestone QA & gates
- Each milestone: `/qa-plan` at start → implement via `/dev-story` per story → `/smoke-check` gate before calling it done → `/story-done`.
- Balance: `/balance-check` after M2 and M3.
- Pre-final: `/regression-suite` + a short `/playtest-report` in the Day-7 buffer.

## Schedule risks (biggest first)
1. **M1 over-runs** (combat is the hardest, 2 days) → if it slips, compress M5, never skip M2–M4.
2. **Godot 4.6 knowledge gap** (HIGH risk) → verify flagged APIs early in M0/M1, not late.
3. **Balance inflation** across 10 layers → seeded sims in M2/M3, not eyeballing.
4. **Web persistence** unknown → de-risk by testing `user://` on HTML5 during M4, or ship PC/Android first.

## Open questions for the gate
- Confirm platform priority for testing: PC/Android first then Web, or Web from day one? (affects M4 risk timing)
- Confirm M5 manual-skill-tap juice vs. minimal manual tap in M1.
