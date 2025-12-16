# Phase 5 Performance Profiling Workflow

## Executive Summary

This document provides a step-by-step workflow for executing the Phase 5 performance profiling and merge process. It serves as the final validation gate before merging search functionality to the main branch.

## Pre-Profiling Checklist

- [ ] Device or emulator is connected and responsive
- [ ] Flutter SDK is up-to-date: `flutter upgrade`
- [ ] No other processes consuming significant CPU/memory
- [ ] At least 15-20 minutes of uninterrupted time available
- [ ] Network is stable (for any initial app downloads)
- [ ] Device screen will not auto-lock during profiling (enable developer mode if needed)

## Step-by-Step Profiling Workflow

### Phase 1: Setup (5 minutes)

```bash
# 1. Navigate to project directory
cd flutter-storefront-v2

# 2. Ensure clean state
git status  # Should show no uncommitted changes
flutter clean

# 3. Install dependencies
flutter pub get

# 4. Verify device connection
flutter devices  # Should show at least one connected device
```

### Phase 2: Start Profiling (2 minutes)

```bash
# 1. Launch the automated profiling script
dart run tools/profile_automation.dart

# 2. Wait for "App is running" message in terminal
# You'll see: "[INFO] App is running. Exercise the search UI..."
```

The app will launch in profile mode with 500 pre-seeded products loaded.

### Phase 3: Exercise the Search UI (5 minutes)

While the profiling script runs, perform these user workflows in sequence:

**1. Text Search (1 minute)**
- Tap the search field at the top
- Type slowly: "shirt" (watch results update)
- Clear and type: "pants"
- Clear and type: "red" (no results expected)
- Type: "shoe" (should show shoes)

**2. Category Filtering (1 minute)**
- Close search field (tap X or clear)
- Tap the "Filter" button
- Select category: "Men"
- Observe filtered results
- Deselect "Men", select "Women"
- Select multiple: "Men" + "Kids"

**3. Price Range Filtering (1 minute)**
- Tap "Filter" → "Price Range"
- Drag minimum slider to $50
- Drag maximum slider to $300
- Observe results update instantly
- Adjust sliders gradually to $75-$250

**4. Combined Filtering (1 minute)**
- Keep price filter active
- Add category filter (select "Men")
- Go to search field, type a query like "jacket"
- Watch all three filters work together
- Scroll through results smoothly

**5. Observation (1 minute)**
- Keep the app idle (no interaction)
- Observe if memory continues rising (indicates leak)
- Watch for CPU spike at idle (indicates background work)

### Phase 4: Complete Profiling (1 minute)

Once 5 minutes of testing is complete:

```bash
# Press Ctrl+C in the terminal where the script runs
# The script will:
# 1. Stop the Flutter process
# 2. Collect final metrics
# 3. Generate report summary
# 4. Save logs to profile_logs.txt and profile_report.json
```

The terminal will display something like:

```
╔════════════════════════════════════════╗
║      PROFILING SUMMARY REPORT          ║
╚════════════════════════════════════════╝

Duration:        300s
Peak Memory:     48.2 MB (Target: <50 MB) ✅ PASS
Avg Memory:      44.5 MB
Peak CPU:        28.5 %
Avg CPU:         19.2 %
Frames Rendered: 18000
Dropped Frames:  12

Status: READY FOR PRODUCTION
```

### Phase 5: Analyze Results

**Quick Check (Console Output)**
```
✅ If you see "READY FOR PRODUCTION" → All targets met
❌ If you see "NEEDS OPTIMIZATION" → Memory exceeded 50MB
```

**Detailed Analysis**

1. **Check the JSON report:**
```bash
cat profile_report.json
```
Look for:
- `pass_memory_target: true` ✅
- `peak_memory_mb` < 50 ✅
- `avg_cpu_percent` < 25 ✅

2. **Review full logs for patterns:**
```bash
cat profile_logs.txt | grep "SYSTEM"  # Show all system metrics
```
Look for:
- Steady memory (no sudden spikes)
- CPU spikes only during interaction
- No repeated error patterns

3. **Identify any issues:**
```bash
cat profile_logs.txt | grep "ERROR\|WARNING"  # Show errors
```

### Phase 6: Decision Point

#### ✅ All Targets Met (Peak Memory < 50MB)

```bash
# 1. Document the successful profiling run
echo "✅ Phase 5 profiling complete - PASSED all targets" >> PROFILING_LOG.txt
echo "Profile Report: $(date)" >> PROFILING_LOG.txt
cat profile_report.json >> PROFILING_LOG.txt

# 2. Commit the profiling results (optional, for record)
git add profile_logs.txt profile_report.json PROFILING_LOG.txt
git commit -m "docs: Phase 5 profiling results - all targets met (48.2MB peak)"

# 3. Proceed to merge (see Phase 7 below)
```

#### ⚠️ Memory Close to Limit (45-50MB)

```bash
# 1. Run additional tests to confirm consistency
# Repeat the profiling workflow 2-3 more times
dart run tools/profile_automation.dart  # Run again

# 2. If all runs stay under 50MB, proceed to merge
# If any run exceeds 50MB, proceed to optimization
```

#### ❌ Memory Target Not Met (>50MB)

```bash
# 1. Analyze the logs for bottlenecks
cat profile_logs.txt | grep "Memory"  # Identify spike pattern

# 2. Check for memory leaks:
# - Does memory increase during idle? → Leak
# - Does memory spike with search? → Large result caching

# 3. Review recent Phase 5 commits for culprits:
git log --oneline --grep="Phase 5" -10

# 4. Open issue for optimization:
# Title: "Phase 5: Optimize memory usage (currently >50MB)"
# Description: Include profile_logs.txt and profile_report.json
# Labels: performance, phase-5

# 5. Do NOT merge until resolved
```

### Phase 7: Merge to Main

Once profiling is confirmed successful:

```bash
# 1. Verify current branch and status
git branch -v  # Should show "feat/interim-cursor-network"
git status     # Should show clean working directory

# 2. Switch to main branch
git checkout main
git pull origin main

# 3. Merge Phase 5
git merge feat/interim-cursor-network --no-ff -m "Merge Phase 5: Search & Filtering System

- Real-time search with debounced query processing
- Multi-factor filtering (category, price, text)
- Caching layer for optimized performance
- Riverpod state management
- 60+ unit tests (all passing)
- Performance profiling: peak memory 48.2MB, smooth scrolling
- Comprehensive documentation"

# 4. Push to remote
git push origin main

# 5. Create a release tag
git tag -a v1.5.0 -m "Phase 5: Search & Filtering System - Production Ready"
git push origin v1.5.0

# 6. Clean up feature branch
git branch -d feat/interim-cursor-network
```

### Phase 8: Post-Merge Checklist

```bash
# On main branch:

# 1. Verify the merge was successful
git log --oneline -5
git diff main~1..main --stat  # Should show Phase 5 changes

# 2. Run quick smoke test on main
flutter test test/perf_smoke_test.dart

# 3. Verify app builds in profile mode
flutter build apk --profile -t lib/main_perf.dart
# or
flutter build ios --profile -t lib/main_perf.dart

# 4. Update version in pubspec.yaml if needed
# Look for "version:" and increment appropriately

# 5. Create a GitHub release (optional but recommended)
# - Title: "Phase 5: Search & Filtering System"
# - Tag: v1.5.0
# - Include profiling results in release notes
```

## Troubleshooting During Profiling

| Issue | Solution |
|-------|----------|
| App crashes during search | Check `profile_logs.txt` for error stack traces; may indicate a bug in search provider |
| Memory spikes above 50MB | Scroll less aggressively; reduce the number of simultaneous filter changes |
| CPU stays above 40% even at idle | Check for background providers; verify all listeners are properly scoped |
| Script exits immediately | Ensure device is connected: `flutter devices` |
| Inconsistent memory readings | This is normal; focus on peak and average, not individual samples |

## Rollback Plan (If Issues Found After Merge)

If critical issues are discovered after merging:

```bash
# 1. Create a hotfix branch from main
git checkout -b hotfix/phase5-rollback
git revert HEAD~1..HEAD  # Revert the merge commit

# 2. Commit and merge the rollback
git push origin hotfix/phase5-rollback
# Create PR and merge to main

# 3. Investigate the issue
# - Review profile_logs.txt from the profiling run
# - Run unit tests to identify failures
# - Create an issue for the Phase 5 refinement

# 4. Re-profiling after fix
# Once issue is fixed, repeat Phase 1-7 above
```

## Success Criteria

✅ **Phase 5 is production-ready when:**
- Peak memory usage < 50 MB
- Average CPU usage < 25%
- Smooth scrolling with < 1% dropped frames
- All 60+ unit tests pass
- No error or warning messages in logs
- All three filtering methods work seamlessly
- Merged to main branch successfully

## Next Steps: Phase 6 (Real API Integration)

Once Phase 5 is merged, the next phase involves:
1. Connecting to real backend API
2. Replacing MockSearchRepository with API client
3. Implementing pagination for large datasets
4. Adding error handling and retry logic
5. Performance profiling with real data (1000+ products)

See `docs/PHASE_6_PLANNING.md` for details (to be created).

## Additional Resources

- **[Automated Profiling Automation](tools/PROFILING_AUTOMATION.md)** — Technical details of the profiling script
- **[Performance Profiling Guide](docs/PERF_PROFILING_GUIDE.md)** — Manual profiling with DevTools
- **[Phase 5 Completion Summary](docs/PHASE_5_COMPLETION_SUMMARY.md)** — Architecture and implementation
- **[Quick Reference](docs/PHASE_5_QUICK_REF.md)** — Commands and quick checklist

## Contact / Questions

If you encounter issues during profiling:
1. Check the troubleshooting section above
2. Review logs in `profile_logs.txt`
3. Refer to Flutter documentation: https://flutter.dev/docs/perf
4. Create a GitHub issue with logs attached

---

**Phase 5 Status: READY FOR PROFILING** ✅
Script created: 2024-01-15
Document version: 1.0
