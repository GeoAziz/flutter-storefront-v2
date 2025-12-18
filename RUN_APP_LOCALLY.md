# Running the App Locally — Setup Guide

The automated tests pass (all backend systems verified), but the headless build environment has resource constraints. Here's how to run the app on your local machine with full emulator support.

## Why Run Locally?

- ✅ Better resource management (desktop RAM vs headless server)
- ✅ Real Android/iOS emulator with GPU acceleration
- ✅ Better debugging experience (DevTools, hot reload)
- ✅ Faster iteration cycles
- ✅ Can test full flows (auth, cart, orders, etc.)

---

## Prerequisites

### 1. Android Setup (5-10 min)

**Option A: Use Android Studio Emulator (Recommended)**

```bash
# Open Android Studio
android-studio

# Go to: Tools → Device Manager
# Click "Create Device" and select a device (e.g., Pixel 5)
# Select API Level 31+ and start the emulator
```

**Option B: Use Existing Emulator**

```bash
# List available emulators
emulator -list-avds

# Start specific emulator
emulator -avd Pixel_5_API_31 &
```

### 2. iOS Setup (Mac only, 5-10 min)

```bash
# Start iOS simulator
open -a Simulator

# Or from Flutter directly:
flutter emulators --launch ios_simulator
```

### 3. Physical Device (fastest)

```bash
# Enable USB Debugging on phone
# Connect via USB
# Verify device detected:
flutter devices
```

---

## Step 1: Ensure Emulators Are Running

Keep these in separate terminals:

**Terminal 1: Firebase Emulators**
```bash
cd /path/to/flutter-storefront-v2
firebase emulators:start --only functions,firestore
```

Expected output:
```
✔  All emulators ready!
┌───────────┬────────────────┬──────────────────────────┐
│ Functions │ 127.0.0.1:5001 │ http://127.0.0.1:4000... │
│ Firestore │ 127.0.0.1:8080 │ http://127.0.0.1:4000... │
└───────────┴────────────────┴──────────────────────────┘
```

**Terminal 2: Android/iOS Emulator**
```bash
# Android (if not already running from Android Studio)
emulator -avd Pixel_5_API_31 &

# iOS (Mac only)
open -a Simulator
```

---

## Step 2: Run the Flutter App

**Terminal 3: Flutter App**

```bash
cd /path/to/flutter-storefront-v2
flutter run
```

When prompted, select your device:
```
Multiple devices found:
1. emulator-5554 (Android)
2. iPhone 15 Pro (iOS)

Which device do you want to target (or "a" for all)? 
```

Choose your emulator (e.g., type `1` for Android).

**Expected output:**
```
Launching lib/main.dart on emulator-5554 in debug mode...
✓ Connected to local Firebase Emulators
  Firestore: http://127.0.0.1:8080
  View Emulator UI: http://127.0.0.1:4000/

Built build/app/outputs/apk/debug/app-debug.apk.
Installing and launching...
```

App should boot on your emulator! 🎉

---

## Step 3: Manual Testing Checklist

Once the app is running:

- [ ] **Home Screen** — Loads without errors
- [ ] **Products Tab** — Shows product list (Firestore read)
- [ ] **Add to Cart** — Click product, add to cart (Firestore write)
- [ ] **Cart Tab** — View cart items
- [ ] **Auth** — Test sign up / log in (if onboarding present)
- [ ] **Orders Tab** — Verify empty initially (no orders yet)
- [ ] **Favorites** — Add/remove items

---

## Step 4: Monitor in Real Time

While testing, open the Emulator UI in browser:

```
http://127.0.0.1:4000/
```

**Firestore Tab:**
- View collections: `users`, `products`, `cart`, `orders`, `favorites`
- Inspect documents before/after app writes
- Verify data structure matches models

**Functions Tab:**
- View Cloud Functions logs
- Check `rateLimitedWrite` and `batchWrite` invocations

---

## Troubleshooting

### Device Not Detected

```bash
# List devices
flutter devices

# If no devices, start emulator:
emulator -avd Pixel_5_API_31 &

# Wait 30-60s for emulator to boot
```

### App Won't Connect to Firestore Emulator

**Check 1:** Firestore emulator running?
```bash
curl http://127.0.0.1:8080
# Should return 404 or JSON (not "Connection refused")
```

**Check 2:** Check app logs for emulator connection message
```bash
# In Flutter terminal, look for:
✓ Connected to local Firebase Emulators
```

If not present, check `lib/main.dart` has `setupEmulators()` call in debug mode.

### Build Takes Too Long / Crashes

On resource-constrained systems:

```bash
# Skip dependency validation (if AGP/Kotlin warnings cause issues):
flutter run --android-skip-build-dependency-validation

# Or disable ProGuard/R8 (faster debug builds):
flutter run --debug
```

### Hot Reload Not Working

```bash
# Press 'r' in Flutter terminal for hot reload
# Press 'R' for full app restart
# Press 'q' to quit
```

---

## Performance Tips

### 1. Use Fast Device

| Device | Speed | Notes |
|--------|-------|-------|
| Physical phone (USB) | ⚡⚡⚡ | Fastest, real hardware |
| Android Emulator (with GPU) | ⚡⚡ | Good balance |
| iOS Simulator (Mac) | ⚡⚡ | Native, good performance |
| Android Emulator (no GPU) | ⚡ | Slow, only use if needed |

### 2. Close Other Apps

More RAM available = faster builds.

### 3. Use Debug Mode

Debug builds are smaller and faster than release:
```bash
flutter run  # Debug by default
```

---

## Next Steps After Manual Testing

Once manual testing passes:

### 1. Verify Backend Flow ✓
- [ ] App connects to Firestore emulator
- [ ] Auth works (sign up / login)
- [ ] Data reads from Firestore (products, cart, orders)
- [ ] Data writes to Firestore (add to cart, add to favorites)

### 2. Proceed to Week 2 UI Integration
- Wire screens to Riverpod providers
- Implement real-time listeners
- Add error handling and loading states
- Optimize performance

### 3. Use Automation for CI/CD
```bash
# Run automated tests in headless build pipeline:
./scripts/automated_test.sh --no-build
```

---

## Running Automated Tests (Headless)

If you want to verify backend on the build server again:

```bash
# Ensure emulators are running
firebase emulators:start --only functions,firestore &

# Wait 5s for emulator to start
sleep 5

# Run tests (no build, no device required)
./scripts/automated_test.sh --no-build
```

This validates all backend systems without needing a device or building the full app.

---

## Development Loop (Week 2 Recommended)

```bash
# 1. Start emulators (once per session)
firebase emulators:start --only functions,firestore &

# 2. Start emulator/device (once per session)
emulator -avd Pixel_5_API_31 &

# 3. Run app
flutter run

# 4. Make code changes
# 5. Hot reload (press 'r' in Flutter terminal)
# 6. Test in app
# 7. Repeat 4-6 until satisfied

# 8. Before commit:
flutter format lib/ test/
flutter analyze
```

---

## Remote Development (SSH Access)

If you're developing on a remote server:

1. **SSH with X11 forwarding** (slower):
   ```bash
   ssh -X user@server "flutter run"
   ```

2. **Better: Develop locally, push to server for CI/CD**
   - Run `flutter run` locally on your machine
   - Commit changes to git
   - Server runs automated tests: `./scripts/automated_test.sh --no-build`

3. **Alternative: Web version** (if Flutter web is configured):
   ```bash
   flutter run -d web
   # Opens browser at http://localhost:5000/
   ```

---

## Summary

| Task | Command | Time |
|------|---------|------|
| Start emulators | `firebase emulators:start --only functions,firestore` | 10s |
| Start device | `emulator -avd Pixel_5_API_31 &` | 30-60s |
| Run app | `flutter run` | 1-2 min (first run) |
| Hot reload | Press 'r' in Flutter terminal | 1-2s |
| Run automated tests | `./scripts/automated_test.sh --no-build` | 2-3 min |

**Total setup time:** ~5-10 minutes  
**Per iteration time:** ~5-10 seconds (with hot reload)

---

## Questions?

- **Flutter Docs:** https://flutter.dev/docs
- **Emulator Setup:** https://developer.android.com/studio/run/emulator
- **Debugging:** https://flutter.dev/docs/testing/debugging

**Good luck! 🚀**
# Retry emulator tests due to transient Flutter setup failure
