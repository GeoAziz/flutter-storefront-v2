# Performance Profiling Guide for Phase 5 Search

This document provides instructions for profiling the Phase 5 search UI with 500+ products to ensure 60 FPS and <50MB memory usage.

## Quick Start

### 1. Seeded Repository Approach

The `MockSearchRepository.seeded(count)` factory allows you to create a mock repository pre-populated with `count` products. This is useful for local development and profiling.

Example:
```dart
import 'package:shop/repository/search_repository.dart';
import 'package:shop/debug/perf_bootstrap.dart';

// Create a repo with 500 products
final repo = createSeededMockRepo(500);

// Or use the factory directly
final repo = MockSearchRepository.seeded(500);
```

### 2. Manual Device Profiling (Recommended)

To accurately measure FPS and memory usage, run the app in **profile mode** on a real device or emulator:

#### Step 1: Build and Install
```bash
# Clean previous builds
flutter clean

# Build APK in profile mode (Android)
flutter build apk --profile

# Or for iOS:
flutter build ios --profile

# Install on device/emulator
flutter install

# Or launch directly in profile mode:
flutter run --profile
```

#### Step 2: Launch DevTools
While the app is running on the device:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

Then open the DevTools URL in your browser (e.g., `http://localhost:9100`).

#### Step 3: Connect to the Running App
In DevTools:
1. Select your device/emulator from the **Device** dropdown
2. Go to the **Performance** tab
3. Click **Record** to start capturing

#### Step 4: Exercise the Search UI
1. Navigate to the Search screen in the app
2. Trigger a search with default settings (or manually inject the seeded repo via provider override during testing)
3. Scroll the results list smoothly (perform 5-10 fling gestures)
4. Toggle filters and re-search
5. Watch for frame rate and memory metrics

#### Step 5: Collect Traces
1. Click **Stop** in DevTools to finish recording
2. DevTools will show:
   - Frame rate (target: 60 FPS)
   - CPU usage per frame
   - Memory timeline (target: <50MB for 500 products)
   - Jank frames (target: 0)

3. Export the trace (if needed for documentation):
   - Click the **Export** button to download the timeline JSON

### 3. Automated Widget Test (CI-Friendly)

For CI environments without device access, use the widget-level smoke test:

```bash
flutter test test/perf_smoke_test.dart
```

This test verifies:
- Seeded repo generates 500+ products
- Text filtering works correctly
- Price range filtering works correctly
- No exceptions occur during search operations

**Note:** Widget tests cannot measure real FPS or memory (they run headless), but they catch regressions and exceptions.

### 4. Expected Results

After 500 products are loaded and rendered:

| Metric | Target | Notes |
|--------|--------|-------|
| FPS | 60 | Monitor in DevTools Performance tab |
| Memory | <50MB | Check Memory tab or use `adb shell dumpsys meminfo` |
| Jank | 0 frames | Look for yellow/red bars in Performance timeline |
| Scroll smoothness | Smooth | Visual inspection; no stutter during fling |

### 5. Debugging Performance Issues

If you observe frame drops or high memory:

1. **Check ListView build time:** Use DevTools Profiler to find expensive build methods
2. **Profile the cache:** Check `SearchCache.getStats()` for hit/miss rates
3. **Check repository delays:** Mock repository introduces a 300ms delay for UI testing; in production, this will be a real API call
4. **Memory leaks:** Look for growing memory even after scrolling stops—indicates a leak

### 6. Files for Reference

- **Seeded Repository:** `lib/repository/search_repository.dart` (MockSearchRepository.seeded)
- **Bootstrap Helper:** `lib/debug/perf_bootstrap.dart` (createSeededMockRepo)
- **Smoke Tests:** `test/perf_smoke_test.dart`
- **Search Providers:** `lib/providers/search_provider.dart`
- **Search Screen:** `lib/screens/search/views/search_screen.dart`

---

## Profiling with Provider Overrides (Advanced)

If you want to run the full SearchScreen with a seeded repo locally, you can override the provider at app startup:

```dart
// In main.dart or a test app variant
await runApp(
  ProviderScope(
    overrides: [
      searchRepositoryProvider.overrideWithValue(
        MockSearchRepository.seeded(500)
      ),
    ],
    child: MyApp(),
  ),
);
```

Then launch with `flutter run --profile` and use DevTools as described above.

---

## References

- [Flutter DevTools Performance Guide](https://docs.flutter.dev/tools/devtools/performance)
- [Flutter Frame Rate and Jank](https://docs.flutter.dev/testing/best-practices#performance-testing)
- [Riverpod Profiling](https://riverpod.dev/docs/essentials/testing)
- [Phase 5 RFC](./docs/PHASE_5_RFC_SEARCH_FILTERING.md)
