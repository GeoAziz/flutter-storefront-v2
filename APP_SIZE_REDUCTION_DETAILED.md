# App Size Reduction - Detailed Analysis & Action Plan

## Current Status Analysis (Dec 17, 2025)

### Project Metrics
- **Total Project Size**: 2.2GB (includes source, build artifacts, git history)
- **Assets Total**: ~6.2MB (192 files)
- **Dependencies**: 41 direct dependencies
- **Flutter Version**: 3.16.0+ (from ci.yml)

---

## 1. ASSET OPTIMIZATION (QUICK WINS)

### 1.1 Image Assets Breakdown
- **Total Images**: ~192 files
- **Current Size**: ~6.2MB
- **Format Analysis**: Mostly PNG files
- **Illustrations**: 40+ illustration assets (theme variants: light/dark)
- **Screens**: Screenshot assets for documentation
- **Other**: Icons, backgrounds

### 1.2 Optimization Opportunities
| Issue | Count | Impact | Action |
|-------|-------|--------|--------|
| Duplicate theme variants (light/dark) | ~40+ | High | Convert to SVG or single asset with theme overlay |
| Large PNG illustrations | 5+ | High | Convert to WebP (save 30-40%) |
| Screenshot assets | Multiple | Medium | Remove from production (doc only) |
| Unused small icons | Various | Low | Consolidate with Flutter's built-in icons |

### 1.3 Implementation Steps

**Step 1: Identify removable assets**
```bash
# Check which assets are actually referenced in code
grep -r "assets/" lib/ --include="*.dart" | awk -F: '{print $2}' | sort | uniq
```

**Step 2: Convert PNG → WebP**
```bash
# Install ImageMagick
sudo apt-get install imagemagick

# Convert all PNG to WebP (30-40% size reduction)
find assets -name "*.png" -exec cwebp {} -o {}.webp \;
```

**Step 3: Consolidate theme assets**
- Replace individual light/dark variants with single PNG + shader/overlay

**Step 4: Update pubspec.yaml**
```yaml
assets:
  - assets/Illustration/
  - assets/icons/
  # Remove doc-only screenshots
```

---

## 2. DEPENDENCY AUDIT

### 2.1 Current Dependencies Analysis

**Firebase Suite** (High Impact)
```
- firebase_core: 2.24.0       ← Core (required)
- firebase_auth: 4.14.0       ← Auth (required)
- cloud_firestore: 4.13.0     ← Database (required)
- firebase_storage: 11.5.0    ← Storage (used for uploads)
- firebase_messaging: 14.7.0  ← Push notifications (required)
- firebase_analytics: 10.7.0  ← Analytics (optional, ~500KB)
```
**Recommendation**: Keep all (core functionality). Consider removing firebase_analytics if metrics not critical.

**UI & Styling**
```
- flutter_svg: 2.0.10         ← SVG rendering (80KB) - KEEP
- cached_network_image: 3.2.0 ← Image caching (120KB) - KEEP
- flutter_cache_manager: 3.3.0 ← Cache mgmt (dependency of above) - KEEP
- flutter_rating_bar: 4.0.1   ← Ratings UI (30KB) - KEEP
- animations: 2.0.11          ← Animation helpers (70KB) - KEEP
- visibility_detector: 0.4.0  ← Visibility detection (20KB) - KEEP
- flutter_widget_from_html_core: 0.15.1 ← HTML rendering (200KB) - REVIEW
```
**Recommendation**: Review flutter_widget_from_html_core - consider regex-based simple HTML parser if not heavily used.

**State Management**
```
- flutter_riverpod: 2.0.0     ← State mgmt (500KB) - KEEP (no replacement smaller)
```

**Storage/Caching**
```
- shared_preferences: 2.0.15  ← Simple KV store (50KB) - KEEP
- sqflite: 2.3.0              ← SQL DB (150KB) - KEEP if used
- hive: 2.2.3 + hive_flutter  ← NoSQL (200KB) - CONSIDER: Using Hive + Sqflite = 2x storage libs
```
**Recommendation**: Use **ONLY** one storage backend:
- If using Hive: Remove sqflite, shared_preferences (consolidate into Hive)
- If using SQLite: Remove hive (more complex but mature)

**Networking**
```
- http: 1.1.0                 ← HTTP client (60KB) - KEEP
- dio: 5.3.0                  ← HTTP with interceptors (200KB) - REVIEW
```
**Recommendation**: Use `http` OR `dio`, not both. `http` is smaller. If using Dio, remove http.

**Utilities**
```
- intl: 0.19.0                ← i18n (1.2MB) - HIGH IMPACT
- uuid: 4.0.0                 ← UUID generation (20KB) - KEEP
- package_info_plus: 5.0.0    ← App info (50KB) - KEEP
- connectivity_plus: 5.0.0    ← Network check (80KB) - KEEP
- path_provider: 2.1.0        ← File paths (40KB) - KEEP
```
**Recommendation**: **Remove `intl` if not using i18n**, save 1.2MB!

**Error Handling**
```
- sentry_flutter: 7.14.0      ← Error tracking (500KB) - OPTIONAL
```
**Recommendation**: Optional for production. Remove if metrics not needed.

### 2.2 Dependency Recommendations

**REMOVE (Quick wins - ~2MB savings)**
```
- firebase_analytics: ^10.7.0  (-500KB) if metrics not critical
- sentry_flutter: ^7.14.0      (-500KB) if not in error budget
- intl: ^0.19.0                (-1.2MB) if not using i18n features
```

**CONSOLIDATE (Choose one - ~200KB savings)**
```
Replace BOTH sqflite + hive with ONE:
- Option A: Keep hive (simpler API, smaller for KV storage)
- Option B: Keep sqflite (if complex queries needed)
```

**REPLACE/OPTIMIZE (Choose lighter alternative - ~200KB savings)**
```
- dio vs http: Use http only (-150KB)
```

**Total Possible Savings from Dependencies**: ~2.2MB (5-10% of typical APK)

---

## 3. BUILD CONFIGURATION OPTIMIZATION

### 3.1 Android Configuration

**File**: `android/app/build.gradle`

**Changes Needed**:
```gradle
android {
  // ... existing config

  buildTypes {
    release {
      // Enable code minimization
      minifyEnabled true
      shrinkResources true
      
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                    'proguard-rules.pro'
    }
  }

  // Create architecture-specific APKs (2x smaller each)
  splits {
    abi {
      enable true
      reset()
      include 'armeabi-v7a', 'arm64-v8a'
      universalApk true
    }
  }

  packagingOptions {
    // Remove unnecessary native libraries
    exclude 'lib/x86/libc++_shared.so'
    exclude 'lib/x86_64/libc++_shared.so'
  }
}
```

**Expected Impact**: 30-40% APK size reduction

### 3.2 iOS Configuration

**File**: `ios/Podfile`

**Changes Needed**:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_settings(target)
    
    target.build_configurations.each do |config|
      # Enable optimization
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '-Os'
      
      # Strip debug symbols
      config.build_settings['STRIP_STYLE'] = 'non-global'
      config.build_settings['COPY_PHASE_STRIP'] = 'YES'
      config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'YES'
    end
  end
end
```

**Expected Impact**: 20-30% IPA size reduction

---

## 4. FLUTTER BUILD OPTIMIZATIONS

### 4.1 Build Commands

**Android**:
```bash
# Build universal APK with all optimizations
flutter build apk --release \
  --obfuscate \
  --split-debug-info=./build/app/debug_info

# Build split APKs (arm64 only for ~50MB)
flutter build apk --target-platform android-arm64 --release \
  --obfuscate \
  --split-debug-info=./build/app/debug_info
```

**iOS**:
```bash
# Build with all optimizations
flutter build ios --release \
  --obfuscate \
  --split-debug-info=./build/app/debug_info
```

### 4.2 Code-Level Optimizations

**Remove Debug Code** (in `lib/main.dart` and app init):
```dart
void main() {
  // Remove in production
  // debugPrintBeginFrameBanner = true;
  // debugPrintEndFrameBanner = true;

  runApp(
    const ProviderScope(
      child: MyApp(
        // Remove:
        // debugShowCheckedModeBanner: true,
      ),
    ),
  );
}
```

**Reduce Dart Build Size**:
```bash
# Remove dart:mirrors (large reflection library)
# Already optimized in Flutter AOT builds

# Check build size breakdown
flutter build apk --analyze-size --release
```

---

## 5. IMPLEMENTATION CHECKLIST

### Phase 1: Dependency Cleanup (TODAY)
- [ ] Run `flutter pub deps --compact`
- [ ] Remove firebase_analytics (save 500KB)
- [ ] Choose storage backend: Remove hive OR sqflite
- [ ] Choose HTTP client: Keep http, remove dio (save 150KB)
- [ ] Remove intl if not using i18n (save 1.2MB)
- [ ] Verify app still builds and tests pass
- [ ] Measure new APK size

### Phase 2: Asset Optimization (TOMORROW)
- [ ] Audit asset usage: grep references in code
- [ ] Remove screenshot assets (if doc-only)
- [ ] Convert PNG → WebP: 6.2MB → ~3.7MB (40% savings)
- [ ] Test app loads all images correctly

### Phase 3: Build Configuration (DAY 3)
- [ ] Update android/app/build.gradle (minify + splits)
- [ ] Update ios/Podfile (optimize + strip)
- [ ] Test both platforms build without errors

### Phase 4: Build & Measure (DAY 4)
- [ ] Build release APK with obfuscation
- [ ] Build release IPA
- [ ] Measure: `ls -lh build/app/outputs/apk/release/`
- [ ] Analyze size breakdown: `flutter build apk --analyze-size`
- [ ] Document before/after metrics

---

## 6. SIZE REDUCTION TARGETS

### Baseline (Current)
- **APK**: TBD (to measure)
- **IPA**: TBD (to measure)

### After Dependency Cleanup
- **Target**: -2.2MB reduction

### After Asset Optimization
- **Target**: -2.5MB reduction (WebP conversion)

### After Build Config
- **Target**: -30% additional (minification + splits)

### Final Target
- **arm64-v8a APK**: < 50MB
- **IPA**: < 80MB uncompressed
- **Total Reduction**: 40-50% from baseline

---

## 7. MEASUREMENT COMMANDS

```bash
# Check current APK size
flutter build apk --release
ls -lh build/app/outputs/apk/release/app-release.apk

# Check split APK (arm64)
flutter build apk --target-platform android-arm64 --release
ls -lh build/app/outputs/apk/release/app-arm64-v8a-release.apk

# Analyze what's in the APK
unzip -l build/app/outputs/apk/release/app-release.apk | tail -50

# Check for duplicate resources
unzip -l build/app/outputs/apk/release/app-release.apk | grep "res/drawable"

# Measure Dart code size
flutter build apk --analyze-size --release

# iOS size check
flutter build ios --release
du -sh build/ios/Release-iphoneos/shop.app/
```

---

## Next Steps

1. **Immediate (Next 1 hour)**: Review dependencies and mark for removal
2. **Short-term (Today)**: Execute Phase 1 (dependency cleanup)
3. **Medium-term (This week)**: Execute Phases 2-4
4. **Ongoing**: Monitor APK size in CI/CD builds

---

## References
- [Flutter App Size Documentation](https://flutter.dev/docs/testing/testing-with-devtools)
- [Android Build Size Optimization](https://developer.android.com/topic/performance/reduce-apk-size)
- [iOS App Thinning](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html)
