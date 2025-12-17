# Performance Targets Quick Reference Card

**Last Updated**: December 16, 2025  
**Status**: Sprint 3 Complete  
**Target Device**: Android 8+ & iOS 11+

---

## 🎯 Performance Targets

| Metric | Target | Minimum Acceptable | How to Measure |
|--------|--------|-------------------|-----------------|
| **Memory Usage** | < 50 MB | < 55 MB | DevTools Memory tab |
| **Scroll FPS** | 60 FPS | ≥ 55 FPS | DevTools Performance tab |
| **App Start Time** | < 3s | < 5s | DevTools Timeline |
| **Image Load Time** | < 500ms | < 1000ms | Network tab or logs |
| **Disk Cache** | 200 objects max | 250 objects | File system check |
| **In-Memory Cache** | 20 MB | 25 MB | Memory tab heap |

---

## 🚀 Quick Start: Run Profiling Locally

### Prerequisites
- ✅ Android Emulator or iOS Simulator running
- ✅ Flutter SDK installed (`flutter --version`)
- ✅ DevTools available (`flutter pub global run devtools`)

### Step 1: Build Release Build
```bash
cd /home/devmahnx/Dev/E-commerce-Complete-Flutter-UI/flutter-storefront-v2
flutter run --profile -d <device-id>
```

### Step 2: Open DevTools
```bash
# Option A: Terminal
flutter pub global run devtools

# Option B: VS Code / Android Studio (built-in)
# Press Cmd+Shift+P (or Ctrl+Shift+P) → "DevTools"
```

### Step 3: Connect to Running App
- DevTools opens at `http://localhost:9100`
- Select your app from the **Device** dropdown
- Choose the running process

---

## 📊 Memory Profiling Checklist

Use this checklist when profiling memory usage:

- [ ] **Cold Start**: 
  - Launch app fresh
  - Memory should be < 30 MB after 5 seconds
  - Check: DevTools → Memory tab → Take Snapshot

- [ ] **Home Screen Scroll**:
  - Navigate to Home (product grid)
  - Scroll continuously for 30 seconds
  - Memory should peak at < 45 MB
  - Check: DevTools → Memory tab → Record Memory Timeline

- [ ] **Wishlist/Comparison Screens**:
  - Navigate to Wishlist (heavy images)
  - Scroll through 50+ items
  - Memory should stay < 48 MB
  - Check: Frame 60+ images loaded, memory stable

- [ ] **Image Cache Eviction**:
  - Take heap snapshot before heavy scroll
  - Scroll past 100+ product cards
  - Take heap snapshot after scroll
  - Image objects should not grow linearly
  - Check: Heap snapshots → Search "Image" → Compare counts

- [ ] **Memory Leak Detection**:
  - Record memory for 60 seconds
  - Alternate: scroll ↔ navigate screens ↔ scroll
  - Memory should fluctuate but not continuously climb
  - Check: Timeline should show sawtooth pattern (GC events)

---

## 🎬 FPS Profiling Checklist

Use this checklist when profiling frame performance:

- [ ] **Baseline (Idle)**:
  - Launch app, let settle for 5 seconds
  - No interaction
  - FPS counter should show 60 (or device max)
  - Check: DevTools → Performance → FPS meter overlay

- [ ] **Scroll Performance**:
  - Open product grid (Home screen)
  - Scroll continuously for 10 seconds
  - Watch FPS counter: should stay ≥ 55
  - Check: DevTools → Performance tab → Record timeline

- [ ] **Fast Fling (Stress Test)**:
  - Fling (fast swipe) through product list
  - Release and let momentum scroll
  - FPS may dip to 50–55 briefly, should recover
  - Check: DevTools → Timeline → look for red bars (janky frames)

- [ ] **Modal/Navigation Performance**:
  - Open product detail modal (from product card)
  - Observe transition FPS
  - Should stay ≥ 55 during open/close animation
  - Check: DevTools → Performance → inspect animation frames

- [ ] **Image-Heavy View Performance**:
  - Gallery screen with 10+ large images
  - Scroll and swipe between images
  - FPS should stay ≥ 50 (images are larger, so slight dip OK)
  - Check: DevTools → Performance → focus on raster thread

---

## 🛠️ DevTools Quick Guide

### Memory Tab
1. **Record Memory Timeline**
   - Click red circle to start recording
   - Interact with app (scroll, navigate)
   - Click to stop
   - **Y-axis**: Memory in MB
   - **Blue line**: Dart heap (managed)
   - **Red line**: External (native allocations, images)
   - **Yellow line**: RSS (total process memory)

2. **Take Heap Snapshot**
   - Pause app or after heavy interaction
   - Click "Take Heap Snapshot"
   - Wait for analysis
   - Search for keywords: "Image", "Cache", "Product"
   - Look for unexpected large counts

### Performance Tab
1. **Record Timeline**
   - Click red circle to record
   - Perform action (scroll, tap, navigate)
   - Click to stop
   - **Green bars**: UI thread (layout, build)
   - **Orange bars**: Raster thread (paint, composite)
   - **Red stripe**: Janky frame (>16 ms)

2. **Interpret Results**
   - Click a frame to inspect details
   - **Frame Rendering Duration**: total time for frame
   - **Expected**: < 16.67 ms per frame (60 FPS)
   - **Acceptable**: < 18 ms for 55 FPS

### Network Tab
- Monitor image requests
- Look for duplicate requests (caching issue)
- Check image load times (<500 ms each)

---

## 🐛 Troubleshooting Guide

### Problem: Memory usage > 50 MB

**Symptom**: App crashes on low-end devices or memory jumps to 60–80 MB

**Root Causes**:
1. ❌ Images being decoded at full resolution
2. ❌ Disk cache too large (>200 objects)
3. ❌ In-memory cache not respecting limits
4. ❌ Listener leaks in Riverpod providers

**Solutions**:
```dart
// 1. Check in-memory cache config (lib/main.dart)
PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
PaintingBinding.instance.imageCache.maximumSize = 100;

// 2. Check disk cache config (lib/utils/image_cache_manager.dart)
Config(
  'appImageCache',
  maxNrOfCacheObjects: 200, // ← Adjust if needed
  stalePeriod: const Duration(days: 30),
)

// 3. Use LazyImageWidget to defer loading
// ❌ DON'T: NetworkImageWithLoader for off-screen images
// ✅ DO: LazyImageWidget for product lists

// 4. Profile with DevTools to find hotspot
// Take heap snapshot → search "Image" → check count
```

### Problem: FPS drops to 45–50 during scroll

**Symptom**: Scrolling feels janky, visible frame drops

**Root Causes**:
1. ❌ Images still loading/decoding on main thread
2. ❌ Complex widget rebuilds during scroll
3. ❌ Heavy Riverpod provider rebuilds
4. ❌ Custom paint operations too expensive

**Solutions**:
```dart
// 1. Use CachedNetworkImage + LazyImageWidget
// Images load off-main-thread, cached

// 2. Use const constructors (reduce rebuilds)
const Widget() ← prevents unnecessary rebuilds

// 3. Use ListView.builder (lazy rendering)
ListView.builder(itemBuilder: ...)

// 4. Profile with DevTools Performance tab
// Check if UI thread (green) or Raster thread (orange) is slow
```

### Problem: Disk cache keeps growing

**Symptom**: App storage usage increases over time, old images not deleted

**Root Causes**:
1. ❌ `maxNrOfCacheObjects` too high
2. ❌ `stalePeriod` too long
3. ❌ Manual cache clears not implemented

**Solutions**:
```dart
// 1. Lower cache limits (check lib/utils/device_cache_config.dart)
lowEnd: 80 objects
midRange: 150 objects
highEnd: 200 objects

// 2. Reduce stale period
stalePeriod: const Duration(days: 14) // was 30

// 3. Manually clear cache when needed
import 'package:shop/utils/image_cache_manager.dart';
await appImageCacheManager.emptyCache();
```

### Problem: Images not loading (blank screens)

**Symptom**: Product images show as blank/error, fallback to error icon

**Root Causes**:
1. ❌ Network issues (no Internet connection)
2. ❌ Image URL malformed or expired
3. ❌ CORS issues (if applicable)
4. ❌ Cache corrupted

**Solutions**:
```dart
// 1. Check network connectivity
// Verify device is connected to WiFi/mobile data

// 2. Verify image URLs in Firestore
// Check that URLs are accessible (paste in browser)

// 3. Clear cache and retry
await appImageCacheManager.emptyCache();

// 4. Check logs in DevTools Console
// Look for network errors or URL issues
```

---

## 💡 Best Practices

### ✅ DO

- ✅ Use `LazyImageWidget` for product lists and grids
- ✅ Use `const` constructors to prevent unnecessary rebuilds
- ✅ Use `ListView.builder` / `GridView.builder` for large lists
- ✅ Profile regularly (weekly for active features)
- ✅ Monitor memory on low-end devices (4GB RAM emulator)
- ✅ Test scroll performance with 50+ items
- ✅ Use DevTools for memory/FPS validation

### ❌ DON'T

- ❌ Load full-resolution images without resizing
- ❌ Create new objects unnecessarily (especially in build methods)
- ❌ Forget to dispose controllers/listeners
- ❌ Use `Image.network` directly (use `CachedNetworkImage`)
- ❌ Pre-load images off-screen aggressively
- ❌ Keep cache limits too high (>250 objects or >30 MB)
- ❌ Skip profiling before committing code

---

## 📋 Device Profiles

### High-End Device
- **RAM**: 6+ GB
- **In-Memory Cache**: 25 MB
- **Disk Cache**: 200 objects
- **Profile on**: Google Pixel 6, iPhone 13
- **Expected**: Smooth scrolling, fast image loads

### Mid-Range Device
- **RAM**: 4–5 GB
- **In-Memory Cache**: 18 MB
- **Disk Cache**: 150 objects
- **Profile on**: Pixel 4a, iPhone 11
- **Expected**: 55–60 FPS, <48 MB peak memory

### Low-End Device
- **RAM**: < 4 GB
- **In-Memory Cache**: 10 MB
- **Disk Cache**: 80 objects
- **Profile on**: Pixel 2, Moto G7, iPhone SE
- **Expected**: 50–55 FPS, <40 MB peak memory

---

## 🔗 Related Documentation

- **Profiling Guide**: `docs/SPRINT_3_PROFILING_GUIDE.md`
- **Sprint 3 Report**: `docs/SPRINT_3_COMPLETION.md`
- **Cache Manager**: `lib/utils/image_cache_manager.dart`
- **Device Config**: `lib/utils/device_cache_config.dart`
- **Lazy Widget**: `lib/components/lazy_image_widget.dart`

---

## 📞 When to Escalate

Contact the performance team if:
- Memory consistently > 55 MB on mid-range devices
- FPS drops below 50 on any device
- App crashes due to OOM
- Disk cache keeps growing despite limits

---

## 📝 Template: Performance Test Report

Use this template when reporting performance findings:

```
**Date**: [YYYY-MM-DD]
**Device**: [Device name, RAM, OS version]
**Test**: [Cold start / Scroll / Navigate / Other]

**Metrics**:
- Memory Peak: [XX MB]
- Avg FPS: [XX FPS]
- Min FPS: [XX FPS]
- Max Frame Time: [XXX ms]

**Findings**:
- [Observation 1]
- [Observation 2]

**Action Items**:
- [ ] [Action 1]
- [ ] [Action 2]
```

---

**Version**: 1.0  
**Last Reviewed**: December 16, 2025  
**Next Review**: January 13, 2026
