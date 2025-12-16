# Phase 4 RFC — Persistent Cache & Telemetry

Last updated: 2025-12-16

## Executive summary

Phase 4 introduces a persistent cache and telemetry platform for the app. The goals are:

- Improve perceived performance (startup, lists, search) by caching frequently used entities and paginated lists.
- Provide observability for production: error tracking, performance telemetry (API latency, pagination time-to-first-item, cache hit/miss), and event logging for key user flows.
- Keep offline-first user experience where reasonable: cached product metadata and search suggestions should survive app restarts.

This RFC proposes an incremental approach: add a stable cache interface and a small memory-backed implementation now; follow with a Hive-backed persistent implementation and Sentry-backed telemetry integration in staging.

## Non-goals

- Provide a full syncing CRDT system.
- Ship a heavy-weight analytics pipeline or backend changes in this phase (we'll integrate with existing telemetry/APIs where possible).

## Key requirements

- Pluggable cache provider with runtime selection (Memory for tests/dev, Hive for production/mobile persistent storage).
- TTL-based entries with optional manual invalidation.
- Small, typed cache entries: product objects, pagination cursors, small UI artifacts.
- Safe, non-blocking initialization and graceful fallback when persistent storage isn't available.
- Telemetry abstraction with minimal surface area so we can plug Sentry and/or a metrics provider later.

## Proposed technologies

- Local persistent cache: Hive (lightweight, fast, well-supported in Flutter). Alternative: sqflite for relational needs — not required for our current data shapes.
- Telemetry: Sentry for error/exception capture + performance spans. Optional analytics: Firebase/Amplitude for high-volume eventing later.

Rationale: Hive is zero-config, works on mobile, and supports typed adapters. Sentry provides both exceptions and performance (traces/spans).

## Data model & caching strategy

- Cache keys will be simple namespaced strings, e.g. `product:12345`, `search:query:shoes:cursor:abc`, `pagination:products:on_sale:cursorHash`
- Values will be JSON-serializable. We'll provide typed helper methods to avoid ad-hoc serialization across the codebase.
- TTL: per-entry TTL optional. Default TTL for product entries: 24 hours. Pagination lists: short TTL, e.g. 5 minutes (configurable).
- Invalidation: manual (explicit delete) and TTL-based automatic eviction. Also provide a `clear()` for user sign-out.

## API contract (CacheProvider)

- init(): initialize storage (async). Must be safe to call multiple times.
- get<T>(String key): returns T? or null.
- set<T>(String key, T value, {Duration? ttl})
- delete(String key)
- clear()
- contains(String key): bool

The provider will be injected at app startup via a service locator/provider pattern (we use Riverpod elsewhere). The pagination and repository layers will consult cache first (read-through) and write-through on successful network responses.

## Telemetry contract (TelemetryService)

- init({environment})
- logEvent(name, properties)
- captureException(error, stackTrace, context)
- startSpan(name) -> span token
- finishSpan(token)

The telemetry service should be a no-op in dev by default (or log to console) and wire to Sentry in staging/production.

## Telemetry events and schema

This project emits a small set of telemetry events around pagination and caching. Keep payloads small and consistent to make downstream analysis simple.

- Event: `pagination_start`
	- Description: Emitted when a pagination request begins.
	- Payload shape:
		- `requestType` (string) - e.g. `PageRequest` or `CursorRequest`
		- `page` (int, optional) - present for PageRequest
		- `pageSize` (int, optional) - present for PageRequest
		- `cursor` (string, optional) - present for CursorRequest

- Event: `pagination_success`
	- Description: Emitted when a pagination request completes successfully.
	- Payload shape:
		- `items` (int) - number of items returned
		- `hasMore` (bool) - whether more pages are available
		- `page` (int, optional) - present for PageRequest
		- `pageSize` (int, optional)

- Event: `pagination_error`
	- Description: Emitted when a pagination request fails.
	- Payload shape:
		- `error` (string) - short error message
		- `requestType` (string) - same as in start event

- Span/Trace: `pagination`
	- Description: A short-lived span/transaction that covers the pagination work (start → network/read → end). Use spans to measure time-to-first-item and total duration.
	- Token: Implementation-defined. For Sentry, we use transactions/spans.

- Event: `cache_hit` / `cache_miss` (optional)
	- Description: Emitted when we read from cache and it's present or missing. These events are optional (emit sparingly to avoid noise).
	- Payload shape:
		- `key` (string) - cache key read
		- `Namespace` (string) - e.g. `product`, `pagination`

Notes:
- Keep event sizes small — avoid embedding entire objects. Use counts, identifiers, and light metadata.
- For sensitive errors or data, ensure PII is never sent. Mask or omit user identifiers unless permitted.
- Sampling: Consider sampling long-running traces in production to reduce volume.


## Migration & rollout plan

1. Add abstract interfaces + in-memory implementation and console telemetry (this commit).
2. Add Hive-backed implementation behind a feature flag; run in staging.
3. Add Sentry integration behind a separate flag; enable in staging and capture errors/perf traces for targeted users.
4. Monitor cache hit ratio and pagination latency for 1–2 weeks in staging. If acceptable, flip prod flags.

## Backwards compatibility

All cache/telemetry code is additive. Repositories may optionally call the cache. Default behavior remains network-first until we switch to read-through caching.

## Timeline & milestones (2-week sprints)

- Sprint 1: finalize RFC, add interfaces and in-memory impl, basic telemetry stub, unit tests, docs.
- Sprint 2: Hive integration, simple product/pagination caching, staging rollout, telemetry Sentry integration.
- Sprint 3: Search integration with cached suggestions, telemetry tuning, final QA and release.

## Risks & mitigations

- Data staleness: mitigate with TTL, explicit refresh triggers (pull-to-refresh).
- Storage migrations: use Hive adapters and a versioning scheme; provide upgrade routines.
- Telemetry volume/cost: keep what we send minimal; sample performance traces if needed.

## Next steps (actionable)

1. Review RFC and confirm Hive + Sentry are acceptable.
2. Add MemoryCache and TelemetryService interfaces (this commit).
3. Add Hive provider and Sentry adapter in Sprint 2 (requires adding dependencies to pubspec).

---
Document author: project lead
