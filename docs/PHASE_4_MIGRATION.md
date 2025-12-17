# Phase 4 Migration Notes

This document summarizes the migration steps and runtime flags for Phase 4 (persistent cache + telemetry).

1) Dependencies added to `pubspec.yaml`:
   - `hive`
   - `hive_flutter`
   - `sentry_flutter`

2) Runtime feature flags (use `--dart-define` when building/running):
   - `ENABLE_PERSISTENT_CACHE=true` — enables Hive-backed cache (default `false`).
   - `ENABLE_SENTRY=true` — enables Sentry telemetry (default `false`).

3) Data migration strategy:
   - We store cache entries in a Hive box `app_cache` as a map with `value` and `expiry`.
   - If we later move to typed Hive adapters, we'll add a migration path to re-encode existing entries.

4) Testing notes:
   - Tests include a small Hive integration test which initializes Hive in a temporary directory.
   - The MemoryCache remains the default for dev and tests unless the flag is passed explicitly.
