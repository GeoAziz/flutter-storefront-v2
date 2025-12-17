# ✅ Immediate Action Checklist

Complete these steps in order. Each step is quick and unblocks the next.

---

## Right Now

### Step 1: Validate Option B Locally ⏱️ ~5 minutes

```bash
# Terminal 1: Navigate to project
cd /path/to/flutter-storefront-v2

# Fetch dependencies
flutter pub get

# Watch for completion (should say "Got dependencies" with no errors)
```

If `flutter pub get` fails with a version error, share the error and I'll fix `pubspec.yaml` immediately.

### Step 2: Run Mocked Tests

```bash
# Terminal 1 (same): Run unit test
flutter test test/unit/auth_controller_mock_test.dart -v

# Expected: ✓ AuthController.signIn signs in existing user
```

```bash
# Terminal 1 (same): Run widget test
flutter test test/widget/login_screen_mock_test.dart -v

# Expected: ✓ LoginScreen signs in and navigates to entryPoint
```

Both should pass in ~1 second total (no device/emulator needed).

### Step 3: Push to Main

```bash
git add -A
git commit -m "Phase 1 validated + Option B ready: firebase auth + mocked tests + CI"
git push origin main
```

**CI will automatically run** and validate:
- Headless harness (Auth + Firestore REST validation)
- Mocked tests (UI flow validation)

Check GitHub Actions tab for workflow run. Should complete in ~3 minutes, all passing.

---

## After Option B is Validated (Immediately — No Wait)

### Step 4: Start Phase 2

**Read these in order:**
1. `PHASE_2_QUICK_START.md` (2 min overview)
2. `PHASE_2_DESIGN.md` (10 min detailed design)

**Then pick a Phase 2.1 task:**

```bash
# Create Product model
touch lib/models/product.dart

# Create ProductRepository
touch lib/repositories/product_repository.dart

# Create seed script
touch scripts/seed_products.dart
```

**Or run the provided template** (if I scaffold it — ask if you want):
- I can create `lib/models/product.dart` + `lib/repositories/product_repository.dart` with full implementations
- You fill in the ProductRepository provider and test it

---

## Checklist

- [ ] Run `flutter pub get` — no errors
- [ ] Run `flutter test test/unit/auth_controller_mock_test.dart` — PASS
- [ ] Run `flutter test test/widget/login_screen_mock_test.dart` — PASS
- [ ] Commit and push to main
- [ ] Check GitHub Actions workflow runs and passes
- [ ] Read `PHASE_2_QUICK_START.md`
- [ ] Read `PHASE_2_DESIGN.md`
- [ ] Create Phase 2.1 files (Product model + repository)
- [ ] Seed 30+ test products to local emulator
- [ ] Connect ProductScreen to ProductRepository
- [ ] Add checkout flow

---

## If Anything Fails

**Post here with:**
- The exact error message
- The command you ran
- Expected vs. actual output

I'll fix it immediately. No step should take more than 5 minutes; if it does, there's likely a simple version or config issue.

---

## Success = You Can

✅ Run tests locally without a device/emulator  
✅ Push to main and see CI validate everything  
✅ Start Phase 2 immediately — products, orders, checkout  
✅ Continue parallel work on all fronts  

**You're ready. Let's go.**
