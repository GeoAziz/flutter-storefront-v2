# App Size Optimization - Phase 7 Sprint

**Date**: December 18, 2025  
**Baseline APK (arm64-v8a)**: 30.6 MB  
**Baseline AAB (arm64-v8a)**: 30.2 MB  
**Target**: 20–22 MB per platform (30–35% reduction)

---

## 📊 Baseline Breakdown (from `flutter build apk --analyze-size`)

### Total Size: 30.6 MB (ARM binary)

| Component | Size | % | Status |
|-----------|------|---|--------|
| **armeabi-v7a (32-bit)** | 15 MB | 49% | ❌ Removable (not needed) |
| **Dart AOT Symbols** | 7 MB | 23% | ⚠️ Flutter=3MB, App=276KB, Others=3.7MB |
| **flutter_assets** | 8 MB | 26% | ⚠️ Images/fonts (PNG→WebP + audit) |
| **classes.dex** | 2 MB | 7% | ⚠️ Java bytecode (minify will help) |
| **resources.arsc** | 444 KB | 1.5% | ⚠️ Android resources (shrinkResources) |
| **Other (lib/*, manifests, proto)** | ~2 MB | ~6% | 📌 Native libraries, config |

---

## 🎯 Implemented Changes (Already Applied)

### ✅ 1. Disable 32-bit ABI (armeabi-v7a) + Enable Minification

**File**: `android/app/build.gradle`

**Changes**:
- ✅ `minifyEnabled = true` (enable ProGuard/R8 code shrinking)
- ✅ `shrinkResources = true` (remove unused Android resources)
- ✅ ABI splits enabled; `universalApk = false` (build per-ABI APKs)
- ✅ Include only: `arm64-v8a`, `x86_64` (remove `armeabi-v7a`)
- ✅ ProGuard rules file created: `android/app/proguard-rules.pro`

**Expected Savings**:
- Removing 32-bit ABI: **-15 MB** (50% instant reduction)
- Code minification (R8): **-2 to -3 MB** (10%)
- Resource shrinking: **-0.5 MB** (1%)
- **Subtotal: -17.5 MB** → **~13 MB per platform**

### ✅ 2. ProGuard Rules Added

**File**: `android/app/proguard-rules.pro`

**Purpose**: Safely minify code while preserving Flutter, Firebase, and native functionality.

---

## 📋 Remaining Tasks (High to Medium Priority)

### **Task 1: Audit & Remove Unused Dependencies** (Est. -2 to -4 MB)

**Current Dependencies with Size Impact**:

| Package | Size | Purpose | Recommendation |
|---------|------|---------|-----------------|
| `firebase_analytics` | ~400 KB | Analytics | ❓ Remove if not used |
| `sentry_flutter` | ~600 KB | Error reporting | ❓ Remove if not critical |
| `intl` | ~500 KB | i18n/localization | ❓ Remove if app is English-only |
| `flutter_widget_from_html_core` | ~300 KB | HTML rendering | ✅ Keep (used in UI) |
| `vector_graphics_compiler` | ~180 KB | SVG compilation | ✅ Keep (flutter_svg dependency) |

**Consolidation Opportunity**:
- **`http` vs `dio`**: App imports both. Remove `http`, use only `dio` for consistency. **Est. save: 100 KB**

**Action**:
1. Search codebase for `firebase_analytics` usage. If unused, comment out in `pubspec.yaml`.
2. Search for `sentry_flutter` usage. If only in dev, move to dev_dependencies.
3. Evaluate `intl` usage; if not needed, remove.
4. Replace all `http` imports with `dio` equivalents and remove `http` from pubspec.

---

### **Task 2: Asset Optimization** (Est. -1 to -2 MB)

**Current**:
- `flutter_assets`: 8 MB
- Mostly PNG images in `assets/images/`, `assets/Illustration/`, `assets/screens/`

**Actions**:
1. **Audit unused images**:
   ```bash
   find assets/ -type f -name '*.png' | wc -l  # Count PNGs
   grep -r "assets/" lib/ | grep -o "assets/[^'\"]*" | sort -u  # Used images
   ```
   Remove any images not referenced in code.

2. **Convert PNG → WebP** (25–35% better compression):
   ```bash
   # Example (Linux/macOS):
   for f in assets/images/*.png; do cwebp "$f" -o "${f%.png}.webp"; done
   rm assets/images/*.png  # Keep only WebP
   ```
   Update `pubspec.yaml` to reference `.webp` instead of `.png`.

3. **Compress remaining images** using tools like `pngquant` or `imagemin`.

**Expected savings**: -1 to -2 MB (PNG→WebP + unused removal)

---

### **Task 3: Enable Obfuscation + Split Debug Info** (Est. -2 to -3 MB)

**Action**: Run release builds with flags:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info \
  --target-platform=android-arm64 --analyze-size
```

**Effect**:
- Minifies all Dart symbol names → reduces code size
- Moves debug info to separate file (not in APK)
- **Expected savings: -2 to -3 MB**

**Note**: After obfuscation, you **must** keep debug-info files to symbolicate crash reports (e.g., in Firebase Crashlytics).

---

### **Task 4: Verify Image Assets Are Necessary** (Quick Audit)

**File**: `pubspec.yaml` - `assets` section

Current:
```yaml
assets:
  - assets/images/
  - assets/icons/
  - assets/Illustration/
  - assets/flags/
  - assets/logo/
  - assets/screens/
```

**Questions to answer**:
- Are all `assets/screens/` images used? (These often contain documentation images not rendered in app)
- Are all `assets/Illustration/` necessary?
- Can icons be replaced with Material/Cupertino built-ins?

**Quick fix**: Move documentation/non-app images out of `assets/` so they don't ship with APK.

---

## 📈 Expected Final Sizes (After All Optimizations)

| Optimization | Savings | Cumulative |
|--------------|---------|------------|
| **Baseline (arm64-v8a)** | — | 30.6 MB |
| 1. Remove armeabi-v7a + minify + shrink | -17.5 MB | **13.1 MB** |
| 2. Remove unused dependencies | -2 to -4 MB | **9–11 MB** |
| 3. Asset conversion + audit | -1 to -2 MB | **7–10 MB** |
| 4. Obfuscation + split debug info | -2 to -3 MB | **5–7 MB** |
| **Target Final Size** | **-60%** | **~12–15 MB** |

---

## 🚀 Implementation Roadmap

### **Phase 7.1 (Completed)** ✅
- [x] Add minification + shrinkResources to Gradle
- [x] Enable ABI splits (remove 32-bit)
- [x] Create ProGuard rules
- [x] Document baseline & targets

### **Phase 7.2 (Next)** 📌
- [ ] Run dependency audit script (see below)
- [ ] Remove unused deps (firebase_analytics, sentry_flutter, intl, http)
- [ ] Re-build and measure: **Expected ~13 MB**

### **Phase 7.3** 📌
- [ ] Audit assets; identify documentation-only images
- [ ] Convert PNG → WebP
- [ ] Re-build and measure: **Expected ~11 MB**

### **Phase 7.4** 📌
- [ ] Build with obfuscation + split debug info
- [ ] Test crash reporting with debug symbols
- [ ] Final measurement: **Expected ~10 MB**

---

## 🔧 Dependency Audit Script

Save as `scripts/audit_deps.sh`:

```bash
#!/bin/bash
# Audit unused dependencies

echo "=== Checking firebase_analytics usage ==="
grep -r "firebase_analytics\|FirebaseAnalytics" lib/ || echo "NOT USED in lib/"

echo ""
echo "=== Checking sentry_flutter usage ==="
grep -r "sentry\|Sentry" lib/ || echo "NOT USED in lib/"

echo ""
echo "=== Checking intl usage ==="
grep -r "intl\|Intl" lib/ || echo "NOT USED in lib/"

echo ""
echo "=== Checking http package usage ==="
grep -r "package:http" lib/ || echo "NOT USED in lib/"

echo ""
echo "=== Checking dio usage ==="
grep -r "package:dio" lib/ && echo "DIO USED" || echo "DIO NOT USED"

echo ""
echo "=== Asset inventory ==="
find assets/ -type f | wc -l
find assets/images/ -name "*.png" 2>/dev/null | wc -l
find assets/ -name "*.png" 2>/dev/null | xargs ls -lh | awk '{print $9, $5}'
```

**Run**:
```bash
chmod +x scripts/audit_deps.sh
./scripts/audit_deps.sh
```

---

## 📚 References

- [Flutter App Size Optimization Guide](https://flutter.dev/docs/cookbook/development/reducing-app-size)
- [Android R8/ProGuard Documentation](https://developer.android.com/studio/build/shrink-code)
- [WebP Image Format](https://developers.google.com/speed/webp)

---

## 📝 Notes

- **ABI Splits**: Play Store automatically delivers arm64 APK to 64-bit devices and x86_64 to emulators. Users on older 32-bit devices will not download this app, which is acceptable in 2025.
- **Minification Risks**: Proguard rules are conservative to avoid breaking Firebase/Firestore. If crashes occur, expand keep rules in `proguard-rules.pro`.
- **Obfuscation**: Always retain debug-info files for production crash analysis. Store separately from APK.

