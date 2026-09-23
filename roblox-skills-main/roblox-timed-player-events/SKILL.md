---
name: roblox-timed-player-events
description: Implement or extend Roblox Luau per-player timed offers and events with server-authoritative timing, persistence, Developer Product receipt safety, UI countdowns, and lifecycle cleanup. Use for introductory sales, session-limited bonuses, or new variants of an existing personal event; do not use for global calendar or cross-server live-ops scheduling.
---

# Roblox Timed Player Events

Build the event around its required time semantics and the project's existing architecture. Keep the server authoritative and preserve paid receipts even when the visible event has ended.

## Discover the existing system

1. Read repository instructions and inspect the real config, player-data schema, service, remotes, receipt router, client controller, UI binder, manifests, and tests before editing.
2. When Studio hierarchy or runtime properties matter, inspect them with a configured Roblox Studio MCP in read-only mode. Do not write to Studio without explicit approval.
3. Query `MarketplaceService:GetProductInfo` when Product IDs are provided and displayed prices must match live Developer Product data. Code cannot change Creator Dashboard prices.
4. Reuse existing services and remotes. Do not introduce Rojo, dependencies, or a parallel purchase pipeline unless the repository already requires them.

## Lock the event contract

Derive these choices from the request and repository; ask only when they materially change behavior:

- timer basis: uninterrupted session time, accumulated playtime, or real-world deadline;
- reconnect behavior: restart, resume, or expire;
- persistent facts: completed, consumed, claimed, or absolute end timestamp;
- eligibility of existing profiles;
- exact boundary behavior at `remaining <= 0`;
- behavior for a purchase prompted before expiry whose receipt arrives later.

Use monotonic `os.clock()` deadlines for session timers. Use persisted Unix timestamps only for events that must continue while the player is offline. If reconnect must restart the full window, persist only final completion/consumption and keep elapsed time in server memory.

## Implement safely

- Put duration, product variants, prices, UI names, and animation bounds in the relevant config. Keep entitlement or reward identity separate from the Product ID so discounted and regular products can grant the same result.
- Add the smallest profile field needed. Let profile reconciliation add backward-compatible defaults. Before bumping a schema version, inspect every migration tied to it; a version bump may trigger unrelated destructive migration logic.
- Create and clear one server session record per eligible player. A delayed expiry callback must verify that it still belongs to the current player session before persisting or publishing state.
- Revalidate eligibility and the deadline inside the server purchase request. The client requests an action, not a Product ID or price.
- Publish enough state for presentation, normally the chosen product/price plus integer remaining seconds. A client may animate the countdown locally, but the server decides expiry and sends the authoritative state change.
- Register every accepted Developer Product ID with the project's receipt router. Validate the reward progression, keep granting idempotent, and honor late receipts after expiry or reconnect. Never grant from `PromptProductPurchaseFinished`.
- Treat a discounted Developer Product ID as discoverable: a modified client may prompt it directly. Since a paid receipt must be resolved, do not leave it pending merely because the UI window ended. Report this platform limitation when strict price enforcement matters.
- Bind the exact UI instances and validate their classes. Store and clean up Heartbeat connections, tweens, signals, and owned tasks during destroy/rebind. Hide event-only labels when the event is inactive while preserving the normal offer UI.

## Verify behavior

Add focused tests for:

- the exact configured products, prices, duration, and UI contract;
- state immediately after join, just before expiry, and exactly at expiry;
- reconnect before expiry and reconnect after persisted completion;
- regular, discounted, late, duplicate, unknown, and skip-tier receipts;
- purchase requests that race the expiry boundary;
- countdown formatting, inactive-state hiding, animation bounds, and cleanup on rebind/destroy;
- existing profiles receiving the intended default without unintended migrations.

After each implementation stage, run the repository's required formatter, linter, and tests. Confirm the synchronized Studio copy contains the new symbols before trusting Studio test results. Separate unrelated flaky failures from failures caused by the change and report both accurately.
