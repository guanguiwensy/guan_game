# ADR-003: Single seeded RNG service with named streams

*Status: Proposed · Date: 2026-06-07 · Deciders: technical-director*
*Relates to: mvp-tdd.md §8 · Source rule §11: "所有随机结果应能通过 seed 复现" · Coding standard: deterministic tests*

## Context
Every random outcome (crit rolls, drop chance, quality weighting, affix rolls) must be reproducible from a seed, both for deterministic tests and for re-rolling saved item instances identically.

## Decision
One `Rng` autoload wrapping a master `RandomNumberGenerator` seeded from a persisted `rng_master_seed`. Derive **named sub-streams** (`combat`, `loot`, `affix`) deterministically from the master so categories don't perturb each other. Each generated item stores its own `seed` so its affixes reproduce on load. **No `randomize()` in gameplay code paths.**

## Alternatives Considered
- **Ad-hoc `randf()`/`randi()` calls**: non-reproducible, untestable, forbidden by source §11.
- **Per-system independent RNGs with separate seeds**: works, but harder to coordinate save/restore and cross-stream reproducibility from a single master seed.

## Consequences
- (+) Deterministic tests (same seed → same sequence); reproducible loot for bug repro.
- (+) Save/restore of RNG state is centralized.
- (−) Must discipline all gameplay randomness to go through `Rng` — enforce via code review + a forbidden-pattern note in technical-preferences.
