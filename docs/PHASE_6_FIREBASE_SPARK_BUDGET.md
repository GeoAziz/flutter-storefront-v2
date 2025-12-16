# Firebase Spark Plan Budget Tracker

**Purpose:** Monitor daily usage to stay within Spark Plan limits  
**Update Frequency:** Daily  
**Warning Threshold:** 80% of monthly limit  
**Critical Threshold:** 95% of monthly limit

---

## Monthly Limits (Spark Plan)

| Resource | Monthly Limit | Daily Average (to stay under) | Daily Peak (safe) |
|----------|---------------|-------------------------------|-------------------|
| **Firestore Reads** | 50,000 | 1,667 reads/day | 2,000 reads/day |
| **Firestore Writes** | 20,000 | 667 writes/day | 800 writes/day |
| **Firestore Deletes** | 20,000 | 667 deletes/day | 800 deletes/day |
| **Cloud Functions Invocations** | 125,000 | 4,167 invocations/day | 5,000 invocations/day |
| **Cloud Functions Execution Time** | 40,000 seconds | 1,333 seconds/day | 1,500 seconds/day |
| **Outbound Bandwidth** | 5 GB | 166.7 MB/day | 200 MB/day |

---

## Usage by Phase 6 Feature

### Feature: Wishlist

**Monthly Projection (500 users):**
```
Operations:
├── Add to wishlist: 500 users × 2 items/month = 1,000 adds
├── Each add: 0 reads (cached) + 1 write (batched)
├── Batch factor: 5 items per write = 200 writes
└── Total: 0 reads + 200 writes ✅
```

**Daily Average:** 6-7 writes  
**Monthly Total:** 200 writes  
**Spark Plan Impact:** <1% ✅

---

### Feature: Product Comparison

**Monthly Projection (500 users):**
```
Operations:
├── Comparisons (local only, no Firestore)
├── 0 reads (all local state)
└── 0 writes (no sync to cloud)
```

**Daily Average:** 0 reads, 0 writes  
**Monthly Total:** 0 reads, 0 writes  
**Spark Plan Impact:** 0% ✅

---

### Feature: Recommendations via Cloud Functions

**Monthly Projection (500 users):**
```
Cloud Function Invocations:
├── Scheduled: 1 per user per day = 500/day
├── Execution time: 200ms average = 100 seconds/day
└── Total: 500 invocations, 100 execution seconds/day

Firestore Writes (from Cloud Function):
├── 20 recommendations per user = 10k writes
└── Per day: ~300 writes

Firestore Reads:
├── User view history query: 1 read per function
├── Product query: 1 read per function × 20 products
├── Total: 500 × 2 = 1,000 reads/day
```

**Daily Average:** 1,000 reads, 300 writes, 500 CF invocations  
**Monthly Total:** 30k reads, 9k writes, 15k CF invocations  
**Spark Plan Impact:** 60% reads, 45% writes, 12% CF invocations ✅

---

### Feature: Analytics Events

**Monthly Projection (500 users):**
```
Event Rate:
├── Product views: 10/user/day = 5,000/day
├── Search queries: 3/user/day = 1,500/day
├── Add to cart: 1/user/day = 500/day
├── Total events: 7,000/day

Firestore Writes (batched):
├── Batch size: 50 events per write
├── Writes per day: 7,000 ÷ 50 = 140 writes/day
├── Monthly: 140 × 30 = 4,200 writes
```

**Daily Average:** 140 writes  
**Monthly Total:** 4,200 writes  
**Spark Plan Impact:** 21% ✅

---

### Feature: Virtual Scrolling + Image Caching

**Monthly Projection (500 users):**
```
Image Caching:
├── Downloaded images: 200 per user per month
├── Image size: 50KB average
├── Total: 200 × 50KB × 500 users = 5 GB bandwidth
└── WARNING: Exceeds 5GB limit!

Optimization:
├── Compress images to 30KB: 3 GB ✅
├── Use CDN caching: 1.5 GB ✅
└── Final: 1.5 GB per month (well under limit!)
```

**Daily Average:** 50 MB bandwidth  
**Monthly Total:** 1.5 GB bandwidth  
**Spark Plan Impact:** 30% ✅

---

## Combined Phase 6 Usage

### Daily Usage Summary (500 concurrent users)

```
Firestore Reads:
├── Product browsing: 2,000 reads (cached → 200 reads actual)
├── Recommendations: 1,000 reads
├── User profile: 500 reads (cached → 50 reads actual)
└── Total: 1,250 reads/day ✅ (under 1,667 limit)

Firestore Writes:
├── Wishlist updates: 50 writes
├── Recommendations: 300 writes (from Cloud Function)
├── Analytics events: 140 writes
└── Total: 490 writes/day ✅ (under 667 limit)

Cloud Functions:
├── Recommendation generation: 500 invocations/day
├── Execution time: 100 seconds/day
└── Total: Well under daily limit ✅

Bandwidth:
├── Images + assets: 50 MB/day
└── Total: 1,500 MB/month ✅ (under 5 GB limit)
```

### Monthly Usage Summary

| Resource | Used | Limit | % Used | Status |
|----------|------|-------|--------|--------|
| **Reads** | ~37,500 | 50,000 | 75% | ⚠️ Monitor |
| **Writes** | ~14,700 | 20,000 | 73.5% | ⚠️ Monitor |
| **Deletes** | ~0 | 20,000 | 0% | ✅ |
| **CF Invocations** | ~15,000 | 125,000 | 12% | ✅ |
| **CF Execution (sec)** | ~3,000 | 40,000 | 7.5% | ✅ |
| **Bandwidth** | ~1,500 MB | 5,000 MB | 30% | ✅ |

**Overall Spark Plan Usage: ~60% of monthly limits** ✅

---

## Scaling to 2000 Users

| Resource | 500 Users | 2000 Users | Limit | Status |
|----------|-----------|------------|-------|--------|
| **Reads/month** | 37.5k | 150k | 50k | ❌ Exceeds |
| **Writes/month** | 14.7k | 58.8k | 20k | ❌ Exceeds |
| **CF Invocations/month** | 15k | 60k | 125k | ✅ |
| **Bandwidth/month** | 1.5 GB | 6 GB | 5 GB | ❌ Exceeds |

**Conclusion:** With current optimization, we can support 500-750 concurrent users on Spark Plan.  
**For 2000+ users:** Migrate to Blaze Plan.

---

## Real-Time Monitoring Dashboard Setup

### Firebase Console Configuration

**Step 1: Enable Monitoring**
```
Firebase Console → Project Settings → Usage & Billing
├── Enable billing alerts
├── Set up daily email reports
└── Configure warning thresholds (80%, 95%)
```

**Step 2: Create Custom Dashboard**
```
Firebase Console → Monitoring
├── Create metric for Firestore reads
├── Create metric for Firestore writes
├── Create metric for Cloud Function execution time
└── Set alerts for each metric
```

### Example Alert Configuration

```
Alert 1: High Firestore Reads
├── Condition: Daily reads > 2,000
├── Notification: Email daily
└── Action: Auto-scale recommendations caching

Alert 2: High Cloud Function Execution Time
├── Condition: Average execution time > 500ms
├── Notification: Email + Slack
└── Action: Optimize function code

Alert 3: Bandwidth High
├── Condition: Daily bandwidth > 200 MB
├── Notification: Email
└── Action: Increase image compression
```

---

## Daily Tracking Template

### Monday, January 13, 2026

```
Metrics (last 24 hours):
├── Firestore Reads: 1,200 (Target: <1,667)
├── Firestore Writes: 480 (Target: <667)
├── Firestore Deletes: 0 (Target: <667)
├── Cloud Functions Invocations: 450 (Target: <4,167)
├── Cloud Functions Execution Time: 90 sec (Target: <1,333)
└── Bandwidth Used: 48 MB (Target: <166.7 MB)

Cumulative (January 1-13):
├── Reads: 15,600 (6 days × 1,200 + 7 days × 1,350)
├── Writes: 6,240 (6 days × 480 + 7 days × 600)
├── CF Invocations: 5,850
└── Bandwidth: 624 MB

Projections to Month End:
├── Reads: ~37,500 (75% of limit) ⚠️
├── Writes: ~14,700 (73.5% of limit) ⚠️
├── CF Invocations: ~15,000 (12% of limit) ✅
└── Bandwidth: ~1,500 MB (30% of limit) ✅

Alerts:
├── None critical ✅
└── Monitor read/write trends

Optimization Opportunities:
├── Consider increasing cache TTL to reduce reads
├── Batch analytics more aggressively
└── Add read cache layer for recommendations
```

---

## Optimization Strategies If Approaching Limits

### If Reads Approaching 80% (40k)

**Increase Caching:**
```
Current: 24-hour cache for recommendations
Action: Increase to 48-hour cache
Impact: Reduces reads by ~50% ✅
```

**Enable Firestore Offline Persistence:**
```
Current: Sync every 5 seconds
Action: Sync every 30 seconds + cache
Impact: Reduces syncs by 80% ✅
```

**Batch Product Queries:**
```
Current: Query products per page
Action: Query 2 pages at once + cache
Impact: Reduces pagination reads by 50% ✅
```

### If Writes Approaching 80% (16k)

**Aggressive Batching:**
```
Current: Batch every 5 seconds or 50 items
Action: Batch every 60 seconds or 100 items
Impact: Reduces writes by 75% ✅
```

**Cloud Function Optimization:**
```
Current: Process 1 user recommendation per function
Action: Batch process 100 users per function
Impact: Reduces function-generated writes by 80% ✅
```

### If Cloud Function Execution Time Approaching Limit

**Function Optimization:**
```
Current: Average 200ms
Action: Profile + optimize to <100ms
Impact: Saves 50% execution time ✅
```

**Reduce Processing:**
```
Current: Analyze 50 views per user
Action: Analyze top 20 views only
Impact: Reduces execution time by 60% ✅
```

---

## Migration to Blaze Plan Criteria

**Consider upgrading when:**
```
✅ All of the following are true:
├── 1000+ concurrent users
├── 100k+ reads/month
├── 50k+ writes/month
├── OR monthly bill would be <$5 anyway
└── OR user growth indicates more scale needed
```

**Blaze Plan Pricing:**
```
Firestore:
├── Reads: $0.06 per 100k
├── Writes: $0.18 per 100k
├── Deletes: $0.02 per 100k

Example: 100k reads + 50k writes/month
├── Reads: 100k ÷ 100k × $0.06 = $0.06
├── Writes: 50k ÷ 100k × $0.18 = $0.09
├── Total: ~$0.15/month (negligible)

Cloud Functions:
├── Invocations: $0.40 per million (after 2M free)
├── Execution time: $0.0025 per GB-second
├── Outbound bandwidth: $0.12 per GB
```

**Recommendation:** Start with Spark Plan for MVP (current plan), upgrade to Blaze once:
- User base exceeds 1000 concurrent
- Monthly bill projected > $5
- Need unlimited invocations

---

## Monthly Review Checklist

**Every month (ideally same day):**

- [ ] Review Firebase Usage Dashboard
- [ ] Compare actual vs. projected usage
- [ ] Check for unexpected spikes
- [ ] Review optimization opportunities
- [ ] Update team on usage trends
- [ ] Adjust caching/batching if needed
- [ ] Plan for next month's expected usage
- [ ] Document any issues/learnings

**Example Review (End of January 2026):**

```
Month: January 2026

Actual Usage:
├── Reads: 37.5k (75% - on target!)
├── Writes: 14.7k (73.5% - on target!)
├── CF Invocations: 15k (12% - comfortable)
└── Bandwidth: 1.5 GB (30% - comfortable)

vs. Projected:
├── ✅ All within estimates

Issues Found:
├── Recommendations cache hit rate: 85% (good!)
├── Analytics batch write timing: Working well
└── No performance issues

Optimizations Applied:
├── Increased product cache TTL 24→36 hours
└── Reduced recommendation processing time

Next Month Projection:
├── Expected 600 users (20% growth)
├── Projected reads: ~45k (still OK)
├── Projected writes: ~18k (still OK)
└── No scaling action needed yet ✅

Recommendation:
└── Continue with Spark Plan through March
```

---

## Emergency Procedures

### If Spark Plan Limit Exceeded Mid-Month

**Immediate Actions (within 1 hour):**
```
1. [ ] Increase cache TTL (24h → 48h)
2. [ ] Disable non-critical analytics
3. [ ] Pause recommendation generation (schedule to off-peak)
4. [ ] Notify team
5. [ ] Monitor reads/writes
```

**Short-term Actions (within 24 hours):**
```
1. [ ] Optimize hot code paths (profiling)
2. [ ] Review analytics batching (increase batch size)
3. [ ] Consider Blaze Plan upgrade
4. [ ] Implement hard read/write limits (graceful degradation)
5. [ ] Update team on situation
```

**Long-term Actions (within 1 week):**
```
1. [ ] Implement comprehensive caching strategy
2. [ ] Audit all Firestore queries
3. [ ] Migrate to Blaze Plan if scaling needed
4. [ ] Update limits and alerts
5. [ ] Document lessons learned
```

---

## Appendix: Detailed Usage Breakdown by User Action

### User Action: Browse Products (Typical Session)

```
1. User opens app
   ├── Fetch user profile: 1 read (cached)
   ├── Fetch recommendations: 1 read (cached)
   └── Fetch featured products: 0 reads (cached)
   Total: 1 read, 0 writes

2. User scrolls through products (virtual scroll, no API calls)
   ├── Images loaded (local cache)
   └── Total: 0 reads, 0 writes

3. User taps product
   ├── Log view event (batched, 0 immediate writes)
   ├── Fetch product details: 0 reads (cached from list)
   └── Total: 0 reads, 0 writes (1 event logged)

Per User per Day: 1-2 reads, <50 writes from analytics

Monthly per 500 users: 750-1500 reads, ~7k analytics writes
```

### User Action: Add to Wishlist

```
1. User clicks "Add to Wishlist"
   ├── Local state update: Instant UI response ✅
   ├── Queue wishlist write: 0 immediate Firestore writes
   └── Batch write (after 5-30 seconds):
       └── 1 write = 1 item (or multiple items if batched)

Per User per Month: 2-5 writes

Monthly per 500 users: 500-1250 writes
```

### User Action: Get Recommendations

```
1. Cloud Function runs (every 1 hour, per user)
   ├── Read user view history: 1 read
   ├── Query product database: 1-3 reads
   ├── Write recommendations: 1 write (batched, ~20 items)
   └── Total: 2-4 reads, 1 write

Per User per Day: 2-4 reads, 1 write

Monthly per 500 users: 30k reads, 500 writes
```

---

**Document Version:** 1.0  
**Created:** December 16, 2025  
**Status:** Ready for Phase 6 Implementation  
**Update Frequency:** Daily (automated via Firebase Console)

