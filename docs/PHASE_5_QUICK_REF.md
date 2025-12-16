# Phase 5 Quick Reference

## What's Done ✅

- ✅ **Search Architecture** — 7 DTOs with JSON serialization
- ✅ **Riverpod State Management** — 25+ providers (debounced, cached, reactive)
- ✅ **Search UI** — 7 components (input, suggestions, filters, sort, panel)
- ✅ **Repository & Caching** — Mock repo + HiveCache with TTL
- ✅ **SearchScreen Integration** — Full UI wired to providers
- ✅ **60 Unit Tests** — All passing (repository, cache, providers, perf smoke tests)
- ✅ **Performance Infrastructure** — Seeded repo (500 products), profiling app, guides

## How to Test Locally

```bash
# Run all search tests (60 tests, ~5 seconds)
flutter test test/search_*.dart test/provider_search_test.dart \
           test/mock_search_repository_test.dart test/perf_smoke_test.dart

# Or individual suites:
flutter test test/perf_smoke_test.dart      # Perf smoke tests (3 tests, <1s)
flutter test test/search_repository_test.dart  # Repository tests (25 tests)
```

## How to Profile on Device

### Lightweight Profiling App (Recommended)
```bash
# Build with seeded 500-product repo (low RAM footprint)
flutter run --profile -t lib/main_perf.dart --android-skip-build-dependency-validation
```

### Manual Device Profiling Workflow

1. **Run app in profile mode** (one terminal)
   ```bash
   flutter run --profile -t lib/main_perf.dart
   ```

2. **Launch DevTools** (second terminal)
   ```bash
   flutter pub global run devtools
   ```

3. **Open browser:** http://localhost:9100

4. **In DevTools:**
   - **Performance tab** → Record
   - **In app:** Scroll results, toggle filters
   - **Stop recording** → Analyze

5. **Expected metrics:**
   - FPS: 60 (green in timeline)
   - Memory: <50MB
   - Jank frames: 0

See `docs/PERF_PROFILING_GUIDE.md` for detailed instructions.

## Key Files

| File | Purpose |
|------|---------|
| `lib/models/search_models.dart` | Search DTOs (Query, Filter, Result, etc.) |
| `lib/repository/search_repository.dart` | SearchRepository abstract + MockSearchRepository.seeded() |
| `lib/repository/search_cache.dart` | Cache wrapper with TTL + statistics |
| `lib/providers/search_provider.dart` | Riverpod providers (25+) |
| `lib/components/search/` | 7 UI components (SearchInputField, FilterPanel, etc.) |
| `lib/screens/search/views/search_screen.dart` | Main search screen |
| `lib/main_perf.dart` | **NEW:** Lightweight profiling app |
| `lib/debug/perf_bootstrap.dart` | **NEW:** Perf helper (createSeededMockRepo) |
| `test/perf_smoke_test.dart` | **NEW:** 3 performance smoke tests |
| `docs/PERF_PROFILING_GUIDE.md` | **NEW:** Manual profiling workflow |
| `docs/PHASE_5_COMPLETION_SUMMARY.md` | **NEW:** Comprehensive completion doc |

## Deployment Checklist

- [ ] Run full test suite: `flutter test` (all 60 tests pass)
- [ ] Profile on real device with DevTools (60 FPS, <50MB targets)
- [ ] Review `docs/PHASE_5_COMPLETION_SUMMARY.md` for architecture overview
- [ ] Merge to `main` when approved
- [ ] Create PR to staging with profiling results

## Useful Commands

```bash
# Run seeded repo tests only
flutter test test/perf_smoke_test.dart -r expanded

# Profile app with hot reload (debug mode)
flutter run -t lib/main_perf.dart

# Profile app with DevTools (profile mode)
flutter run --profile -t lib/main_perf.dart

# See test failures in detail
flutter test test/perf_smoke_test.dart -v

# Clean and rebuild
flutter clean && flutter pub get && flutter test test/perf_smoke_test.dart
```

## Performance Targets (Post-Profiling)

| Metric | Target | Tool |
|--------|--------|------|
| **Frame Rate** | 60 FPS | DevTools Performance tab |
| **Memory** | <50MB | DevTools Memory tab |
| **Jank** | 0 frames | DevTools Performance timeline (green only) |
| **Cache Hit Rate** | >80% | Inspect `SearchCache.getStats()` in tests |

## Current Status

**Branch:** `feat/interim-cursor-network`  
**Last Commits:**
- `f65d301` — Phase 5 complete (profiling app + summary)
- `245c51b` — Phase 5 finalization (seeded repo + tests + guide)

**Test Status:** ✅ 60/60 passing (0 failures)  
**Regressions:** ✅ None (all existing tests still pass)

---

## Next Steps (Optional)

1. **Profile on device** — Use `lib/main_perf.dart` with DevTools
2. **Optimize if needed** — Adjust caching, debounce, or rendering based on traces
3. **Merge to main** — Once profiling confirmed
4. **Phase 6** — Real API integration (replace MockSearchRepository)

---

For detailed information, see:
- `docs/PHASE_5_COMPLETION_SUMMARY.md` — Full architecture & completion doc
- `docs/PERF_PROFILING_GUIDE.md` — Manual device profiling workflow
- `docs/PHASE_5_RFC_SEARCH_FILTERING.md` — Original RFC & design doc
