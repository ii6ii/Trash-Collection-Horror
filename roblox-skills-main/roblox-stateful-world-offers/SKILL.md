---
name: roblox-stateful-world-offers
description: Implement or extend Roblox Luau offers attached to changing world slots or objects, using server-authoritative stateful reconciliation, injectable randomness, current-offer validation, and durable idempotent Developer Product receipts with rollback. Use for offers on free plots, bases, stands, or similar shared world inventory; do not use for GUI-only work or per-player timed offers.
---

# Roblox Stateful World Offers

Keep offer assignment, purchase authorization, and paid grants server-authoritative while the set of eligible world objects changes. Preserve stable offers where possible instead of rerolling the whole world after every lifecycle event.

## Discover the contracts

Before editing, inspect the real world-object registry, free/occupied lifecycle, offer and reward catalogs, appearance application, player-data schema, receipt router, service manifest, remotes, and focused tests. Confirm event ordering: an assignment observer needs the object after it becomes occupied, while a release observer needs it after it becomes free.

Separate these facts:

- the authoritative in-memory offer assigned to a world object;
- replicated attributes or instances used only for presentation;
- the player's durable entitlement and processed-purchase journal;
- progression facts that affect presentation or eligibility.

## Build a stateful selector

- Keep initial assignment and later repair in a small selection module without world mutations.
- Inject a narrow random source so boundary choices and repair behavior are deterministic in tests.
- Make cardinality rules and required category coverage explicit for zero, one, two, and many eligible objects.
- During repair, retain valid surviving assignments, fill missing entries, then make the smallest change needed to restore global invariants. Do not reroll unaffected offers.
- If a category has no configured item, or applying its preview fails, clear both the authoritative mapping and its replicated marker. Never publish a marker for an offer that was not applied.

## Reconcile world lifecycle

- On assignment, clear the object's offer before owner-specific visuals or state take over, then repair the remaining eligible set.
- On release, wait until the object is actually free, then repair the set and apply its offer preview.
- Use distinct pre-release, removing, and post-release signals when their state guarantees differ; do not infer post-release state from a pre-release callback.
- Order service startup so world and appearance dependencies exist before offer reconciliation, and every product handler is registered before the global receipt router starts.
- On destruction, disconnect owned signals, clear per-player throttles, and remove offer mappings and replicated markers owned by the service.

## Authorize purchase requests

- Let the client send an action and the selected world instance, never a trusted Product ID, reward ID, category, price, or ownership claim.
- Resolve the exact object through the server registry and reject wrong classes, descendants masquerading as roots, occupied objects, stale mappings, mismatched replicated markers, already-owned rewards, and invalid product configuration.
- Resolve the Product ID from the current authoritative offer only after validation. Rate-limit the request and contain prompt failures without granting anything.
- Do not use `PromptProductPurchaseFinished` to grant a Developer Product.

## Process receipts durably

- Register each supported Product ID once. Handle a valid paid receipt independently of whether its original world offer is still visible or assigned.
- Require a non-empty `PurchaseId` and guard concurrent processing of the same purchase in memory.
- In one profile update, grant and equip the entitlement and record the purchase in a feature-owned processed-purchase journal.
- Snapshot every profile field that transaction mutates. If saving fails, restore all of those fields and return a deferred result so Roblox can retry.
- Acknowledge only after the saved snapshot proves that both the journal entry and entitlement are durable. A memory-only mutation is not enough.
- Treat an already persisted receipt as successful without granting twice. Run notifications, appearance refreshes, analytics success, and other effects only after durability, and do not undo a durable grant when a presentation effect fails.

## Integrate shared progression

If client presentation depends on progression, publish the smallest authoritative fact through the project's existing replication contract. Initialize it for newly loaded and already-loaded players, and update it from the owning progression service rather than duplicating progression logic in the offer service.

Keep preview application separate from applying a player's equipped appearance. When an object becomes owned, the normal owner-appearance path must overwrite the temporary offer preview.

## Verify behavior

Add focused tests for:

- deterministic initial selection and minimal repair for zero, one, two, and many eligible objects;
- assignment and release transitions without rerolling valid survivors;
- missing pools and preview failures leaving no stale published offer;
- invalid, occupied, stale, already-owned, and throttled purchase requests;
- successful receipt persistence, save-failure rollback, durability verification failure, malformed purchase IDs, and persisted duplicates;
- post-save effects occurring only after a durable grant;
- service startup ordering, lifecycle cleanup, and authoritative progression replication when used.

Run the repository's required formatter, linter, and relevant tests after each implementation stage. Separate failures caused by the change from pre-existing failures.
