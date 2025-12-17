# Phase 6 Sprint Implementation Guide

## Quick Start: 8-Week Roadmap to Production

### Week 1-2: Wishlist & Comparison (Sprint 1)

#### Week 1: Core Implementation

**Monday-Tuesday: Wishlist Foundation**
```
Tasks:
├── Create WishlistItem model (lib/models/wishlist_model.dart)
├── Create WishlistRepository (lib/repository/wishlist_repository.dart)
├── Set up Hive box for wishlist caching
└── Implement batch write logic (5-second debounce)

Time: 4-6 hours
Tests: 5 unit tests
```

**Wednesday-Thursday: Wishlist UI**
```
Tasks:
├── Create WishlistButton component (animated heart icon)
├── Create WishlistScreen (view all wishlisted items)
├── Create Riverpod providers (wishlistProvider, isInWishlistProvider)
├── Add snackbar feedback for add/remove
└── Implement offline support (read from Hive if offline)

Time: 6-8 hours
Tests: 10 integration tests
```

**Friday: Testing & Refinement**
```
Tasks:
├── Test offline functionality
├── Profile memory usage (should be <1MB)
├── Test batch write timing
└── Code review + refactoring

Time: 4-5 hours
Result: Wishlist fully functional ✅
```

**Sprint 1 Monday: Comparison Foundation**
```
Tasks:
├── Create ComparisonList model (lib/models/comparison_model.dart)
├── Create ComparisonRepository (local-only, Hive storage)
├── Design ComparisonTable UI component
└── Limit comparisons to 4 items max (UX + performance)

Time: 4-6 hours
```

#### Week 2: Comparison & Polish

**Tuesday-Wednesday: Comparison UI**
```
Tasks:
├── Build ProductComparisonScreen
├── Create comparison table with dynamic attributes
├── Add "Add to Comparison" button on ProductCard
├── Add comparison management (remove, clear all)
└── Test with 4-item comparison

Time: 6-8 hours
Tests: 8 integration tests
```

**Thursday-Friday: Integration & Testing**
```
Tasks:
├── Integrate Wishlist + Comparison (show in ProductCard)
├── Test memory with both features active
├── Performance profiling
├── Fix any issues found
└── Merge to develop branch

Time: 6-8 hours
Result: Wishlist + Comparison complete ✅
Firestore Reads Used: ~2% of Spark limit
```

---

### Week 3-4: Cloud Functions & Recommendations (Sprint 2)

#### Week 3: Cloud Functions Setup

**Monday-Tuesday: Firebase Setup**
```
Tasks:
├── Create Firebase project console (if not done)
├── Set up Cloud Functions project locally
├── Configure functions/package.json
├── Deploy test function
└── Verify function logs work

Time: 3-4 hours
Tools Needed:
├── Firebase CLI installed
├── Node.js 16+ installed
└── Firebase service account credentials
```

**Wednesday-Thursday: Recommendation Function**
```
Tasks:
├── Implement generateRecommendations Cloud Function
│   ├── Fetch user view history (last 50)
│   ├── Analyze category/price preferences
│   ├── Query matching products
│   └── Batch write results
├── Set up scheduled trigger (every 1 hour)
└── Deploy function

Time: 8-10 hours
Testing:
├── Test with 10 users locally
├── Monitor function logs for errors
└── Verify results in Firestore
```

**Friday: Testing & Monitoring**
```
Tasks:
├── Set up Cloud Function monitoring dashboard
├── Create alerts for execution time >500ms
├── Test function with Firebase emulator
├── Document function behavior
└── Monitor daily invocation cost

Time: 3-4 hours
Result: Cloud Functions deployed ✅
```

#### Week 4: App Integration

**Monday-Tuesday: Event Logging**
```
Tasks:
├── Create RecommendationsRepository
├── Implement logProductView Cloud Function call
├── Integrate with ProductCard (log on tap)
├── Batch event logging (queue + debounce)
└── Add offline queueing

Time: 6-8 hours
Tests: 12 unit tests
```

**Wednesday-Thursday: Recommendations UI**
```
Tasks:
├── Create RecommendationsScreen
├── Integrate with home screen
├── Display "Recommended for You" section
├── Add recommendation caching (24-hour TTL)
├── Handle empty recommendations gracefully

Time: 6-8 hours
Tests: 10 integration tests
```

**Friday: Integration Testing**
```
Tasks:
├── End-to-end test (log view → wait 1hr → recommendations update)
├── Test with Firebase emulator
├── Profile memory + CPU impact
├── Fix issues
└── Merge to develop

Time: 4-5 hours
Result: Recommendations fully working ✅
Firestore Operations:
├── Reads: Cached (1 read per 24 hours per user)
├── Writes: ~1 per hour per user (batch)
└── Cloud Functions: 1 per user per hour
```

---

### Week 5-6: Analytics & Virtual Scrolling (Sprint 3)

#### Week 5: Analytics Service

**Monday-Tuesday: Event Tracking Service**
```
Tasks:
├── Create AnalyticsEvent model
├── Create AnalyticsService with batch writing
│   ├── 50-item batch size OR 30-second interval
│   ├── Automatic retry on failure
│   └── Offline queueing
├── Add event types (view, search, add_cart, purchase)
└── Implement Hive persistence for offline events

Time: 6-8 hours
Tests: 12 unit tests (batch logic, retry, offline)
```

**Wednesday-Thursday: Integration Points**
```
Tasks:
├── Log analytics on ProductCard view
├── Log analytics on search query
├── Log analytics on add-to-cart
├── Log analytics on wishlist actions
├── Test batch write timing

Time: 6-8 hours
Tests: 8 integration tests
Expected Result:
├── 1000 events = 20 Firestore writes (95% reduction!)
└── Memory impact: <2MB
```

**Friday: Monitoring**
```
Tasks:
├── Create simple analytics dashboard (daily summary)
├── Set up daily write alerts
├── Profile total writes/day
└── Document analytics flow

Time: 3-4 hours
```

#### Week 6: Virtual Scrolling

**Monday-Tuesday: Virtualized List Component**
```
Tasks:
├── Study Flutter scroll physics
├── Create ScrollViewBuilder component
├── Implement visible range calculation
├── Create item recycling logic
├── Test with 1000 items

Time: 8-10 hours
Performance Target: <30MB memory for 10k items (vs 500MB without)
```

**Wednesday-Thursday: Integration & Testing**
```
Tasks:
├── Integrate VirtualizedProductList into SearchScreen
├── Test scrolling performance (60 FPS target)
├── Profile memory with 10k items
├── Test with different device sizes
├── Add pull-to-refresh

Time: 8-10 hours
Tests: 15 performance tests
```

**Friday: Optimization**
```
Tasks:
├── Profile and optimize hot paths
├── Add shimmer placeholders for non-visible items
├── Test with real device
├── Fix any jank issues
└── Merge to develop

Time: 4-5 hours
Result: Virtual scrolling complete ✅
Performance: 10k items with <50MB memory ✅
```

---

### Week 7: Internationalization (Sprint 4 Part 1)

**Monday-Tuesday: i18n Setup**
```
Tasks:
├── Add flutter_localizations dependency
├── Create l10n directory structure
├── Generate app_en.arb with all strings
├── Generate app_es.arb (Spanish)
├── Generate app_fr.arb (French)
├── Configure app to use localization

Time: 5-6 hours
Strings to Translate: ~150 across app
```

**Wednesday-Thursday: String Migration**
```
Tasks:
├── Replace all hardcoded strings with l10n references
├── Update widgets to use AppLocalizations
├── Test language switching
├── Add language selector to settings

Time: 8-10 hours
Files to Update: ~30 widget files
```

**Friday: Testing & Polish**
```
Tasks:
├── Test language switching (no restart needed)
├── Verify all strings translated
├── Check text overflow in different languages
├── Add fallback to English if translation missing
└── Merge to develop

Time: 4-5 hours
Result: i18n fully functional ✅
```

---

### Week 8: Final Testing & Deployment (Sprint 4 Part 2)

**Monday-Tuesday: Comprehensive Testing**
```
Tasks:
├── Run 100+ test suite (all phases)
├── Integration testing (all features together)
├── Cross-device testing (phone, tablet)
├── Performance profiling on real device:
│   ├── Memory: <50MB target
│   ├── FPS: 60 FPS maintained
│   └── Startup time: <3 seconds
└── Firebase Spark Plan verification (<80% usage)

Time: 8-10 hours
```

**Wednesday-Thursday: Optimization & Bug Fixes**
```
Tasks:
├── Fix any performance issues found
├── Address memory leaks (if any)
├── Optimize Cloud Functions if slow
├── Final code review
└── Update documentation

Time: 8-10 hours
```

**Friday: Release Preparation**
```
Tasks:
├── Final testing pass
├── Update version in pubspec.yaml
├── Generate release notes
├── Tag release (v2.0.0)
├── Merge to main branch
└── Deploy to staging

Time: 4-5 hours
Result: Phase 6 Complete ✅
Ready for Phase 7 Production Deployment
```

---

## Daily Standup Template

### Example: Monday of Week 3

```
Developer 1 (Cloud Functions):
What I did Friday:
├── Set up Firebase functions directory
├── Wrote recommendation algorithm
└── Deployed test function

What I'm doing today:
├── Optimize function for <300ms execution
├── Add batch processing
└── Set up Cloud Function monitoring

Blockers:
└── (none)

Developer 2 (Mobile App):
What I did Friday:
├── Finished wishlist UI
├── Started analytics service
└── All tests passing

What I'm doing today:
├── Implement analytics batching
├── Add event types
└── Integration test with Cloud Functions

Blockers:
└── Waiting for Cloud Functions deployment

---

Daily Metrics:
├── Firestore reads today: 250 (target: <50k ✅)
├── Lines of code: 2,500
├── Tests: 145 passing
└── Memory usage: 35MB (target: <50MB ✅)
```

---

## Testing Checklist by Week

### Week 1-2: Wishlist & Comparison
- [ ] Add to wishlist works offline and online
- [ ] Remove from wishlist works
- [ ] Wishlist persists after app restart
- [ ] Batch writes occur every 5 seconds
- [ ] Memory stays <2MB for 100-item wishlist
- [ ] Comparison can hold 4 items max
- [ ] Comparison UI renders all attributes
- [ ] Side-by-side table scrolls horizontally
- [ ] All strings in multiple languages (if i18n done)

### Week 3-4: Cloud Functions
- [ ] Cloud Function deploys successfully
- [ ] generateRecommendations runs every 1 hour
- [ ] Event logging calls Cloud Function
- [ ] Recommendations appear in app after 1 hour
- [ ] Cache prevents duplicate reads
- [ ] Offline mode queues events
- [ ] Sync happens on reconnect
- [ ] Memory impact < 3MB
- [ ] Error handling works (graceful degradation)

### Week 5-6: Analytics & Virtual Scrolling
- [ ] Analytics service batches 50 events
- [ ] Firestore receives batches every 30 seconds
- [ ] 1000 events = ~20 writes (95% reduction!)
- [ ] Virtual scroll handles 1k items smoothly
- [ ] Virtual scroll handles 10k items (<50MB)
- [ ] FPS stays at 60 during fast scrolling
- [ ] Pull-to-refresh works
- [ ] Memory doesn't accumulate on scroll

### Week 7: Internationalization
- [ ] Language selection works
- [ ] All strings translated (en, es, fr)
- [ ] No hardcoded strings remaining
- [ ] Language persists on app restart
- [ ] Text overflow handled in all languages
- [ ] Locale changes update UI without restart

### Week 8: Final Verification
- [ ] All 100+ tests passing
- [ ] Memory <50MB on real device
- [ ] 60 FPS maintained during all interactions
- [ ] No jank or dropped frames
- [ ] Startup time <3 seconds
- [ ] Firestore Spark Plan usage <80%
- [ ] Cloud Function execution <300ms avg
- [ ] Offline mode works seamlessly
- [ ] Online sync works on reconnect

---

## Performance Targets by Feature

| Feature | Memory | FPS | Reads/Day | Writes/Day | Status |
|---------|--------|-----|-----------|------------|--------|
| Wishlist | <2MB | 60 | 0 cached | 1k batched | ✅ |
| Comparison | <1MB | 60 | 0 | 0 | ✅ |
| Recommendations | <3MB | 60 | 1k cached | 1k (CF) | ✅ |
| Analytics | <2MB | 60 | 0 | 500 batched | ✅ |
| Virtual Scroll | <5MB | 60 | 0 | 0 | ✅ |
| i18n | <1MB | 60 | 0 | 0 | ✅ |
| **Total** | **<15MB** | **60 FPS** | **<5k** | **<3k** | **✅** |

**Spark Plan Allocation:** Uses only 10-15% of monthly limits!

---

## Common Pitfalls & Solutions

### Pitfall 1: Cloud Function Timeouts

**Problem:** generateRecommendations function takes >5 minutes

**Solution:**
```
├── Limit query to last 100 views (not all)
├── Use caching at function level
├── Batch process max 100 users per function
└── Split into multiple scheduled functions if needed
```

### Pitfall 2: Memory Bloat with Analytics

**Problem:** Offline event queue grows unbounded

**Solution:**
```
├── Limit queue to max 500 events (1MB)
├── Implement priority queue (purchases first)
├── Auto-flush when queue reaches 80%
└── Warn user if offline >1 day
```

### Pitfall 3: Virtual Scroll Jank

**Problem:** FPS drops to 30 when scrolling fast

**Solution:**
```
├── Increase buffer size (render more off-screen items)
├── Reduce re-renders of visible items
├── Profile with DevTools → Performance tab
└── Consider using cached_network_image for fast rendering
```

### Pitfall 4: i18n Maintenance

**Problem:** Strings not synced across translations

**Solution:**
```
├── Use ARB format (JSON-based, enforced structure)
├── Set up translation service (not manual)
├── Validate all keys present in all languages
└── Add pre-commit hook to prevent missing translations
```

---

## Deployment Checklist

### Pre-Deployment (Week 8 Friday)
- [ ] All tests passing (100+ test suite)
- [ ] Performance profiling complete (<50MB verified)
- [ ] Firestore indexes created
- [ ] Cloud Functions deployed + monitored
- [ ] Firebase rules reviewed
- [ ] Error tracking configured (Sentry)
- [ ] Analytics dashboard set up
- [ ] Privacy policy updated
- [ ] Staging environment tested

### Deployment Day
- [ ] Create release branch: `release/v2.0.0`
- [ ] Update version: `pubspec.yaml`
- [ ] Generate release notes
- [ ] Build production APK/IPA
- [ ] Submit to Google Play / App Store
- [ ] Set up post-deployment monitoring

### Post-Deployment
- [ ] Monitor Firestore usage daily
- [ ] Monitor Cloud Function performance
- [ ] Monitor error rates (Sentry)
- [ ] Collect user feedback
- [ ] Prepare for Phase 7 launch

---

## Success Metrics (Week 8 - Go/No-Go)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Test Pass Rate | 100% | ? | ? |
| Memory Usage | <50MB | ? | ? |
| FPS | 60 | ? | ? |
| Cloud Function Avg Time | <300ms | ? | ? |
| Firestore Spark Usage | <80% | ? | ? |
| Bugs Found | 0 critical | ? | ? |
| Code Coverage | >80% | ? | ? |

---

## Next Phase: Phase 7 Production Deployment

Once Phase 6 is complete, we move to Phase 7:
- [ ] Final security audit
- [ ] Production database setup
- [ ] CDN configuration
- [ ] App store submission
- [ ] User onboarding flow
- [ ] Launch marketing
- [ ] Post-launch monitoring

**Estimated Timeline:** 2-3 weeks

---

**Document Version:** 1.0  
**Created:** December 16, 2025  
**Status:** Ready for Implementation  
**Phase 6 Kick-off:** Monday, January 13, 2026

