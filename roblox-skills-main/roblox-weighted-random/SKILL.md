---
name: roblox-weighted-random
description: Implement or review server-authoritative weighted-random selection in Roblox Luau when pool entries or weights can change at runtime. Use for weighted spawn, loot, reward, or encounter selection; do not use for uniform random choices or broad RemoteEvent security audits.
---

# Roblox Weighted Random

Build the smallest selector that preserves the project's current data source and authority model.

## Establish the contract

- Inspect the real pool type, weight source, mutation points, and call sites before choosing an algorithm.
- Keep the selection core independent from domain effects such as rare alerts, rewards, spawning, or analytics.
- Prefer a pure selector that receives the ordered pool and an injected unit roll. Let the caller own `Random` so tests can choose exact rolls.

## Select from dynamic weights

- When the pool or its weights can change at runtime, recompute the usable total on every selection. Do not keep a static total.
- A cached total is acceptable only for an immutable snapshot or when every mutation updates or invalidates the cache through one enforced path.
- Treat positive weights as enabled. Ignore non-positive weights when that matches the project's configuration contract; validate malformed or untrusted weights at their external boundary.
- If no positive total remains, return `nil` and let the caller skip the outcome safely.
- Clamp a unit roll to `[0, 1]`, multiply it by the current total, then scan the pool in stable order while accumulating positive weights.
- Use half-open intervals: return the first entry where `target < cumulative`. Keep the last positive entry as the fallback so an exact roll of `1` selects the final interval instead of returning `nil`.
- Do not normalize every entry unless another consumer requires normalized probabilities; the cumulative scan works directly with weights.

## Preserve server authority

- Generate the roll and choose the gameplay outcome on the server for spawns, loot, currency, rewards, damage, inventory, or progression.
- Let clients request intent, not provide the chosen entry, roll, weight, or authoritative result.
- Before applying an outcome requested through a remote, validate only the relevant external-boundary facts: payload types and ranges, rate, permission or ownership, and current server state. Add spatial checks when proximity is part of the action.
- Send notifications and visuals after the server commits the outcome; client rendering must not change authoritative state.

## Verify behavior

Use deterministic unit rolls rather than flaky frequency-based assertions. Cover:

- exact interval starts and values immediately below each boundary;
- rolls `0` and `1`;
- one positive entry, zero or negative entries, and a pool with no positive total;
- a weight changed between two selections, proving that the total is recalculated;
- the caller's safe behavior when selection returns `nil`;
- remote rejection tests when client input participates in the surrounding flow.

Keep domain thresholds and presentation rules in their owning modules and test them separately from the generic weighted selector.
