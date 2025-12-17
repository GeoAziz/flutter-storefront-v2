# Sprint 3: Memory & Image Optimization - Profiling Guide

## Overview

Sprint 3 focused on optimizing memory and image loading performance to meet these targets:
- **Memory Usage**: < 50 MB total app memory
- **Scroll Performance**: 60 FPS during image-heavy view scrolling
- **Image Cache**: Centralized disk cache with eviction policy + in-memory cache limits

## Implementation Summary

### Changes Made

1. **Disk Cache Manager** (`lib/utils/image_cache_manager.dart`)
   - Centralized CacheManager instance for all network images
   - Configured with:
     - Max 200 cached objects (controls disk count)
     - 30-day stale period (automatic cleanup of old images)
     - Used by `CachedNetworkImage` to bound disk usage

2. **Network Image Component** (`lib/components/network_image_with_loader.dart`)
   - Updated to use `appImageCacheManager` for disk caching
   - Already uses `CachedNetworkImage` for lazy loading (placeholder shown until image loads)
   - Maintains skeleton loader during fetch

3. **In-Memory Cache Limits** (`lib/main.dart`)
   - Set `imageCache.maximumSize = 100` (number of cached images)
   - Set `imageCache.maximumSizeBytes = 20 * 1024 * 1024` (~20 MB limit)
   - Applied during app initialization before runApp

4. **Dependency** (`pubspec.yaml`)
   - Added `flutter_cache_manager: ^3.3.0` for disk cache management

---

## How to Profile Locally

### Prerequisites

- **Device/Emulator**: Android Emulator, iOS Simulator, or physical device
- **Flutter DevTools**: Built-in or run via `flutter pub global run devtools`
- **Android Studio / VS Code**: For comfortable DevTools integration

### Step 1: Launch App with Profiling Enabled

```bash
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2

# For Android Emulator
flutter run -d <emulator-id> --profile

# For iOS Simulator
flutter run -d <simulator-id> --profile

# Or let Flutter auto-select your device
flutter run --profile
```

The `--profile` flag compiles an optimized build suitable for profiling without the overhead of debug mode.

### Step 2: Open Flutter DevTools

**Option A: Via Terminal**
```bash
flutter pub global run devtools
# DevTools opens at http://localhost:9100 (or provided URL)
# Select your running app from the Device dropdown
```

**Option B: Via Android Studio**
- Look for the **DevTools** icon in the toolbar or Logcat view
- Click to launch DevTools and auto-connect to your app

**Option C: Via VS Code**
- Extension: "Dart" (already installed likely)
- Run: `Cmd/Ctrl + Shift + P` → **Open DevTools** (or **Dart: Open DevTools**)

---

## Profiling Workflows

### Memory Profiling

#### Recording Memory Timeline

1. **Open DevTools → Memory tab**
2. **Click "Record Memory Timeline"** (red dot icon)
3. **Interact with the app for 30–60 seconds**:
   - Navigate to **Home Screen** (shows product grid)
   - Scroll down continuously through 5–10 products
   - Switch to **On-Sale Screen** (another heavy image list)
   - Scroll aggressively for 10 seconds
   - Navigate back to **Home** and repeat
4. **Stop recording** (red dot becomes black)

#### Interpreting Memory Results

In the Memory timeline graph:
- **Y-axis**: Memory usage in MB
- **Blue line (Dart heap)**: Managed memory in Flutter runtime
- **Red line (External)**: Native allocations (images often here)
- **Yellow line (RSS)**: Total process memory

**Target**: Peak RSS should stay **< 50 MB** during normal usage.

**What to look for**:
- Spikes after fast scrolling? → Images may not be evicting quickly
- Linear growth? → Possible memory leak
- Stable sawtooth pattern? → Healthy GC behavior

**If memory is high**:
1. Note which screen triggered the spike (product list, gallery, etc.)
2. Take a heap snapshot (button in DevTools) to see what's holding memory
3. Common culprits:
   - Decoded image cache too large → reduce `maximumSizeBytes`
   - Disk cache too large → reduce `maxNrOfCacheObjects` in `image_cache_manager.dart`
   - Listener leaks in Riverpod providers → check provider disposal

#### Taking Heap Snapshots

1. In Memory tab, click **"Take Heap Snapshot"**
2. Wait for snapshot to complete (appears in list below)
3. Click the snapshot to expand and inspect object counts/sizes
4. Filter by "Image" or search for asset/cache classes
5. Look for unexpected large counts (e.g., 500+ Image objects when expecting <100)

---

### FPS & Frame Performance Profiling

#### Recording a Performance Timeline

1. **Open DevTools → Performance tab**
2. Click **"Record"** (red circle)
3. Perform the action you want to profile:
   - Scroll product list quickly (5–10 flicks)
   - Swipe between tabs
   - Open a modal or pop a screen
4. Click **"Stop"** to end recording

#### Interpreting Performance Results

The timeline shows two critical sections:

**UI Thread (Green bars)**:
- Height indicates frame build/layout time
- Target: **< 16 ms/frame** (for 60 FPS)
- Tall green bars = dropped frames

**Raster Thread (Orange bars)**:
- Height indicates frame rendering time (paint + composite)
- Target: **< 16 ms/frame**
- Tall orange bars = GPU bottleneck

**Janky frames**: If a frame exceeds 16 ms, it's displayed as a red stripe across the timeline.

#### Identifying Bottlenecks

1. Click on a tall/red bar in the timeline to inspect that frame
2. Look at the **Frame Rendering Duration** at the bottom
3. If UI Thread is slow:
   - Likely: Complex widget builds, large lists without pagination
   - Solution: Use `ListView.builder`, `GridView.builder`, or `PageView` with caching
4. If Raster Thread is slow:
   - Likely: Image decoding, complex paint operations
   - Solution: Pre-decode images, use `RepaintBoundary` to cache expensive paints

#### Smoke Test: Scroll FPS

```bash
# Manual test (observe the FPS meter)
# 1. Run: flutter run --profile
# 2. Tap the performance icon overlay (shows FPS)
# 3. Scroll a product grid continuously
# 4. Watch FPS counter: should stay >= 55 FPS most of the time
```

---

## Expected Performance Before & After Sprint 3

### Before Sprint 3
- **Memory**: May spike to 60–80 MB on image-heavy screens (no centralized cache control)
- **Disk Cache**: Unbounded (could grow to hundreds of MB)
- **In-Memory Cache**: Default Flutter cache (conservative but not tuned)

### After Sprint 3
- **Memory**: Should stay < 50 MB on most interactions
  - First load of product list: ~30–35 MB (images decoded)
  - After scrolling 50+ products: ~40–45 MB (old images evicted)
  - Peak memory: < 50 MB in normal scenarios
- **Disk Cache**: Bounded to ~max 200 images (with 30-day stale period)
- **In-Memory Cache**: Bounded to 20 MB

---

## Validation Checklist

Run through this checklist to confirm Sprint 3 is working:

### Memory Budget ✅

- [ ] Launch app and navigate to **Home Screen** (product grid)
- [ ] Open DevTools Memory tab and record for 60 seconds while scrolling
- [ ] **Expected**: Peak RSS < 50 MB
- [ ] **Acceptable range**: 40–48 MB (allows headroom for other features)

### FPS During Scrolling ✅

- [ ] In Performance tab, record a 10-second continuous scroll of the product list
- [ ] Check timeline for janky frames (red bars)
- [ ] **Expected**: < 5% janky frames, avg 55+ FPS
- [ ] **Acceptable**: Mostly green bars, occasional small orange dips OK

### Image Cache Eviction ✅

- [ ] Take a heap snapshot at app start
- [ ] Scroll past 100+ product cards
- [ ] Take another heap snapshot
- [ ] Compare object counts for ImageCache entries
- [ ] **Expected**: Counts should be similar (old images evicted)
- [ ] **Not expected**: Linear growth with each image viewed

### Disk Cache Growth ✅

- [ ] Connect device via `adb` (Android)
- [ ] Check app cache directory:
  ```bash
  adb shell ls -lh /data/data/com.example.shop/cache/
  # or similar path; grep for flutter_cache_manager or appImageCache
  ```
- [ ] **Expected**: Directory size stable (not growing with each scroll)

### Cold Start Memory ✅

- [ ] Close app completely
- [ ] Open DevTools Memory tab
- [ ] Start app fresh (`flutter run --profile`)
- [ ] Wait 5 seconds for stabilization
- [ ] **Expected**: Initial memory < 30 MB

---

## Troubleshooting

### Memory Still High?

1. **Check image sources**: Are images very large (e.g., 3000x3000px downloaded as full size)?
   - **Solution**: Implement `resizeImage` or request thumbnail from backend

2. **Check provider cleanup**: Are Riverpod providers holding image streams?
   - **Solution**: Use `.family` and `.autoDispose` modifiers; ensure listeners unsubscribe

3. **Check for listener leaks**: Are screens leaving listeners open?
   - **Solution**: Use `useEffect` or `ref.watch` with proper cleanup

### FPS Drops During Scroll?

1. **Check image loading**: Are images being decoded on the main thread?
   - **Solution**: Use `CachedNetworkImage` (already done) or `FadeInImage.memoryNetwork`

2. **Check for expensive builds**: Are you rebuilding large widget trees?
   - **Solution**: Use `const` constructors, `ListView.builder`, extract widgets to reduce redraws

3. **Check for paint operations**: Are custom paints slow?
   - **Solution**: Use `RepaintBoundary` or offscreen caching

### Disk Cache Not Evicting?

1. **Check cache manager config** (`lib/utils/image_cache_manager.dart`):
   - Ensure `maxNrOfCacheObjects` is set (currently 200)
   - Check `stalePeriod` is reasonable (currently 30 days)

2. **Manually clear cache** (for testing):
   ```dart
   import 'package:shop/utils/image_cache_manager.dart';
   
   // In a test or debug button:
   await appImageCacheManager.emptyCache();
   ```

---

## Advanced Profiling: Tracing & CPU Profiler

### CPU Profiling (DevTools Performance tab, advanced)

1. In **Performance tab**, scroll down to **Advanced** section
2. Look for **Flame Chart** or **Call Tree**
3. Expand frames to see which methods consume CPU time
4. **Common culprits**:
   - `Image.load` / `ImageCache._checkImageSize` → image decoding
   - `RenderObject.performLayout` → layout thrashing
   - `Canvas.drawImage` → painting

### Full App Profiling (Advanced)

For a complete trace:
```bash
flutter run --profile --trace-startup
# App starts and profiles for ~30 seconds automatically
# Results saved to timeline.json
# Open in DevTools Timeline tab
```

---

## CI/CD Integration (Future)

Consider adding automated performance regression tests:

```dart
// Example: test/perf_smoke_test.dart (similar structure)
testWidgets('Memory usage under load', (WidgetTester tester) async {
  // Pump app
  // Scroll through heavy list
  // Assert memory < 50 MB
});
```

Run in CI with:
```bash
FIREBASE_EMULATOR=true flutter test --profile test/perf_smoke_test.dart
```

---

## References

- [Flutter Performance Profiling](https://flutter.dev/docs/testing/debugging)
- [DevTools Memory View](https://flutter.dev/docs/development/tools/devtools/memory)
- [DevTools Performance View](https://flutter.dev/docs/development/tools/devtools/performance)
- [CachedNetworkImage Package](https://pub.dev/packages/cached_network_image)
- [Flutter Cache Manager](https://pub.dev/packages/flutter_cache_manager)

---

## Summary

Sprint 3 implementation provides:
1. ✅ Disk cache management (centralized, evicts old images)
2. ✅ In-memory cache limits (20 MB configured)
3. ✅ Lazy loading already in place (CachedNetworkImage)
4. ✅ Ready for profiling and performance validation

**Next steps**: Run local profiling on your device, confirm targets are met, and iterate on cache tuning if needed.
