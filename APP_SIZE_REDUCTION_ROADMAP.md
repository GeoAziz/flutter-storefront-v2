# APP SIZE REDUCTION - IMPLEMENTATION ROADMAP
## Phase 7 Sprint Continuation

---

## EXECUTIVE SUMMARY

This document outlines a **structured approach to reduce app size** through:
1. Dependency optimization
2. Asset compression
3. Build configuration
4. Code splitting

**Expected Outcome**: 40-50% reduction in final APK/IPA size

---

## QUICK WINS (Implement Today)

### 1. Remove Unused Dependencies (~2.2MB savings)

**High Priority Removals**:
```yaml
# In pubspec.yaml - REMOVE these lines:
- intl: ^0.19.0                    # (1.2MB) - Only if not using i18n
- sentry_flutter: ^7.14.0          # (500KB) - Optional error tracking
- firebase_analytics: ^10.7.0      # (500KB) - Optional metrics
```

**Consolidation**:
```yaml
# CHOOSE ONE storage backend (currently have both):
# Option A: Keep hive (simpler, smaller for KV store)
# Option B: Keep sqflite (if complex queries needed)

# CHOOSE ONE HTTP client:
# Option A: Keep http (smaller, 60KB)
# Option B: Keep dio (200KB, more features - remove if not using interceptors)
```

### 2. Asset Optimization (~2.5MB savings)

```bash
# Convert PNG → WebP (30-40% smaller)
find assets -name "*.png" | while read f; do
  cwebp "$f" -o "${f%.png}.webp"
done

# Remove duplicate theme variants by using CSS/overlay
# Current: 40+ light/dark variants → Consolidate to single asset
```

### 3. Build Configuration Changes

**Android** (`android/app/build.gradle`):
```gradle
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                  'proguard-rules.pro'
  }
}

splits {
  abi {
    enable true
    reset()
    include 'armeabi-v7a', 'arm64-v8a'
    universalApk true
  }
}
```

**iOS** (`ios/Podfile`):
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '-Os'
      config.build_settings['STRIP_STYLE'] = 'non-global'
    end
  end
end
```

---

## IMPLEMENTATION PHASES

### PHASE 1: DEPENDENCY ANALYSIS & CLEANUP
**Duration**: 2 hours
**Tasks**:
- [ ] Run `flutter pub deps --compact` and analyze output
- [ ] Identify unused dependencies
- [ ] Decide: Keep Hive or SQLite?
- [ ] Decide: Keep http or Dio?
- [ ] Decide: Remove intl if not using i18n?
- [ ] Update pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Verify tests pass

**Expected Savings**: 1.5-2.2MB

### PHASE 2: ASSET COMPRESSION
**Duration**: 1 hour
**Tasks**:
- [ ] Audit assets: `grep -r "assets/" lib/ --include="*.dart" | awk -F: '{print $2}' | sort | uniq`
- [ ] Remove unreferenced assets
- [ ] Convert PNG → WebP: `cwebp input.png -o output.webp`
- [ ] Remove screenshot/demo assets (keep only app assets)
- [ ] Update pubspec.yaml if asset names change
- [ ] Test all images load correctly

**Expected Savings**: 2.0-2.5MB

### PHASE 3: BUILD CONFIGURATION
**Duration**: 2 hours
**Tasks**:
- [ ] Update `android/app/build.gradle` with minification config
- [ ] Update `ios/Podfile` with optimization settings
- [ ] Test builds on both platforms
- [ ] Fix any build errors

**Expected Savings**: 30-40% of base APK size

### PHASE 4: MEASUREMENT & VALIDATION
**Duration**: 3 hours
**Tasks**:
- [ ] Build APK release: `flutter build apk --release`
- [ ] Measure size: `ls -lh build/app/outputs/apk/release/app-release.apk`
- [ ] Analyze breakdown: `flutter build apk --analyze-size --release`
- [ ] Build iOS: `flutter build ios --release`
- [ ] Measure IPA: `du -sh build/ios/Release-iphoneos/shop.app/`
- [ ] Compare against baseline
- [ ] Document results

---

## DEPENDENCY DECISION MATRIX

| Decision | Option A | Option B | Recommendation |
|----------|----------|----------|---|
| **Storage** | Hive (KV store, simpler) | SQLite (relational, complex) | Choose based on data model |
| **HTTP Client** | http (60KB, simple) | Dio (200KB, interceptors) | Keep **http** if not using Dio features |
| **i18n** | Keep intl (1.2MB) | Remove intl | Remove if **English-only** app |
| **Analytics** | Keep firebase_analytics (500KB) | Remove analytics | Remove if **not tracking metrics** |
| **Error Tracking** | Keep sentry_flutter (500KB) | Remove sentry | Remove if **not error tracking** |

---

## ASSET INVENTORY

**Current Assets**: ~192 files, ~6.2MB

**Categories**:
- Illustrations: 40+ files (light/dark variants)
- Icons: 20+ files
- Backgrounds: 10+ files
- Screenshots: 50+ files (documentation)
- Other: 70+ files

**Optimization Opportunity**:
1. Remove 50+ screenshot files (doc purposes)
2. Convert PNG → WebP: 6.2MB → 3.7MB
3. Consolidate light/dark variants

---

## BUILD SIZE TARGETS

### Baseline (To be measured)
- [ ] Current APK size: ___ MB
- [ ] Current IPA size: ___ MB

### After Phase 1 (Dependencies)
- [ ] Target APK: -2.2MB
- [ ] Target IPA: -2.2MB

### After Phase 2 (Assets)
- [ ] Target APK: -2.5MB more
- [ ] Target IPA: -2.5MB more

### After Phase 3 (Build Config)
- [ ] Target APK: -30-40% from base
- [ ] Target IPA: -20-30% from base

### Final Target
- [ ] APK (arm64-v8a): < 50MB
- [ ] APK (universal): < 75MB
- [ ] IPA: < 80MB

---

## VALIDATION CHECKLIST

**Before Committing Changes**:
- [ ] App builds without errors
- [ ] All tests pass: `flutter test`
- [ ] No missing dependencies at runtime
- [ ] CI workflows still pass
- [ ] UI renders correctly
- [ ] Images load from assets
- [ ] Navigation works end-to-end

**Size Validation**:
- [ ] Measure baseline APK size
- [ ] Apply changes
- [ ] Measure new APK size
- [ ] Calculate % reduction
- [ ] Document in git commit

---

## SUCCESS METRICS

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| APK Size (arm64) | TBD | < 50MB | |
| IPA Size | TBD | < 80MB | |
| Dependency Count | 41 | 35-38 | |
| Asset Size | 6.2MB | 3.5MB | |
| Build Time | TBD | No increase | |

---

## NEXT ACTIONS (In Order)

1. **Now**: Review this document
2. **Next 30 min**: Decide on dependency consolidations
3. **Next 1 hour**: Update pubspec.yaml
4. **Next 1 hour**: Compress assets
5. **Next 2 hours**: Update build configs
6. **Next 3 hours**: Build, measure, validate
7. **Finally**: Commit results with size improvements documented

---

## RISKS & MITIGATION

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Removing dependency breaks app | High | Run full test suite before push |
| Asset compression breaks UI | Medium | Test all screens after WebP conversion |
| Build config incompatible | Medium | Test on both Android & iOS devices |
| Can't reach size target | Low | Document learnings for future optimization |

---

## References
- [Flutter App Size](https://flutter.dev/docs/testing/testing-with-devtools)
- [Android Size Optimization](https://developer.android.com/topic/performance/reduce-apk-size)
- [iOS App Thinning](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html)
- [Dart Code Obfuscation](https://dart.dev/guides/language/pubspec#publish_to)

---

**Created**: December 17, 2025
**Status**: Ready for Phase 1 Implementation
**Owner**: Development Team
