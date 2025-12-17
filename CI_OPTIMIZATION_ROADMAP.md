# CI/Runtime Optimization Roadmap

**Current State:** Phase 7 CI pipeline passes deterministically in **1m43s** (run 20310514915)

## Baseline Metrics (Run 20310514915)
- **Total Duration:** 1m43s
- **Node.js Setup:** ~5-10s
- **Emulator Startup:** ~8-12s (Firestore download on first run)
- **Phase 7 Test:** ~15-20s (webhook idempotency)
- **Phase 6 Test:** ~12-15s (baseline payment flow)
- **Phase 5 Test:** ~5-8s (audit log validation)
- **Post/Cleanup:** ~5s

**Total: 1m43s ✅**

## Optimization Targets

### Phase 1: Emulator & Caching (Quick Wins - Est. -20s)
1. **Java 21 Caching**
   - Currently: Fresh download on each run
   - Optimization: Cache `${{ runner.tool_cache }}/Java_Temurin*`
   - Est. Savings: ~5-8s

2. **Firestore Emulator JAR Caching**
   - Currently: `firebase-emulator-v1.20.2.jar` downloaded fresh
   - Optimization: Cache `~/.cache/firebase/emulators/`
   - Est. Savings: ~8-12s

3. **npm Dependency Caching**
   - Currently: Using `cache: 'npm'` (already enabled)
   - Status: ✅ Implemented in workflow
   - Savings: ~3-5s on cache hits

### Phase 2: Emulator Optimization (Medium Effort - Est. -15s)
1. **Parallel Test Execution**
   - Currently: Phase 5-7 tests run sequentially
   - Optimization: Run Phase 5 (Firestore only) in parallel with Phase 6-7 (both use Firestore+Functions)
   - Challenge: Firestore state isolation
   - Est. Savings: ~8-10s (if Phase 5 runs concurrently)

2. **Emulator Startup Pre-warming**
   - Currently: Emulators start fresh, functions load after
   - Optimization: Use `firebase emulators:exec` (already implemented ✅)
   - Status: Currently used for all tests
   - Savings: Already realized in current pipeline

### Phase 3: Test Harness Optimization (Requires Code Changes - Est. -10s)
1. **Batch Seeding**
   - Currently: Each phase seeds products independently
   - Optimization: Reuse seeded data across phases
   - Challenge: Test isolation requirements
   - Est. Savings: ~3-5s

2. **Reduce Audit Log Queries**
   - Currently: Full Firestore audit validation in each phase
   - Optimization: Lazy validation in Phase 5 only
   - Est. Savings: ~2-3s

### Phase 4: Runner Performance (Code Profiling - Est. -5s)
1. **Identify Hot Paths in Test Code**
   - Profile Phase 6-7 runners for slow operations
   - Measure webhook POST latency
   - Identify unnecessary waits

2. **Reduce Sleep/Wait Times**
   - Current: Conservative 1-2s waits for state consistency
   - Optimization: Use event listeners instead of fixed delays
   - Est. Savings: ~3-5s

---

## Implementation Priority

### **NOW (1-2 hours)**
✅ Phase 1: Emulator & Caching
- Add Java 21 cache to workflow
- Add Firestore emulator JAR cache
- Est. Impact: **-15 to 20s** → **1m23s**

### **NEXT (2-3 hours)**
Phase 2a: Parallel Test Execution (Phase 5 parallel)
- Requires test harness changes for isolation
- Est. Impact: **-8 to 10s** → **1m15s**

### **FUTURE (Post-Optimization)**
Phase 3: Batch Seeding & Audit Optimization
Phase 4: Runner Performance Profiling

---

## Success Criteria
- **Phase 1 Complete:** <1m30s ✅
- **Phase 2 Complete:** <1m15s ✅
- **Phase 3 Complete:** <1m10s (production target)

**Current Status:** 1m43s → **Target: <1m10s** (35% reduction)
