# Phase 5 Automated Profiling Automation Guide

## Overview

The `tools/profile_automation.dart` script automates the profiling process for Phase 5 search and filtering performance testing. It launches the Flutter app in profile mode, captures system metrics in real-time, and generates detailed reports for easy analysis.

## Quick Start

### Prerequisites
- Flutter SDK installed and in PATH
- Device or emulator connected
- At least 5-10 minutes of available time for profiling run

### Running the Script

```bash
# Make sure you're in the project root
cd flutter-storefront-v2

# Run the profiling script
dart run tools/profile_automation.dart
```

The script will:
1. Launch `flutter run --profile -t lib/main_perf.dart`
2. Display real-time metrics in the terminal
3. Capture system stats (memory, CPU) every 2 seconds
4. Save detailed logs to `profile_logs.txt`
5. Generate a structured report to `profile_report.json`
6. Print a summary to console when complete

## What Gets Captured

### Flutter Metrics
- **Frames Rendered**: Total number of frames successfully rendered
- **Dropped Frames**: Number of frames that missed the 60fps target
- **App Output**: All stdout/stderr from the Flutter process
- **Warnings/Errors**: Any performance warnings or exceptions

### System Metrics (Captured Every 2 Seconds)
- **Memory (MB)**: Estimated RSS memory usage of Flutter process
- **CPU (%)**: CPU utilization percentage
- **Timestamp**: ISO 8601 timestamp for correlation

### Duration
- Profiles for up to 5 minutes by default
- Can be interrupted earlier with Ctrl+C

## Output Files

### `profile_logs.txt`
Complete log file with:
- Session timestamp
- Command executed
- All Flutter output lines (prefixed with `[FLUTTER]`)
- System metrics samples (prefixed with `[SYSTEM]`)
- Error messages (prefixed with `[FLUTTER_ERR]` or `[SYSTEM_ERROR]`)
- Final summary report

**Example excerpt:**
```
Profile Session: 2024-01-15T14:32:00.000Z
Command: flutter run --profile -t lib/main_perf.dart
══════════════════════════════════════════════════════════════════
[FLUTTER] I/Choreographer(12345): Skipped 2 frames!  The application may be doing too much work on its main thread.
[SYSTEM] Memory: 45.2MB | CPU: 18.5% | 2024-01-15T14:32:02.123Z
[SYSTEM] Memory: 46.8MB | CPU: 22.3% | 2024-01-15T14:32:04.234Z
[SYSTEM] Memory: 44.1MB | CPU: 15.7% | 2024-01-15T14:32:06.345Z

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

### `profile_report.json`
Structured metrics in JSON format for programmatic analysis:

```json
{
  "timestamp": "2024-01-15T14:37:45.123Z",
  "duration_seconds": 300,
  "peak_memory_mb": "48.20",
  "avg_memory_mb": "44.50",
  "peak_cpu_percent": "28.50",
  "avg_cpu_percent": "19.20",
  "frames_rendered": 18000,
  "dropped_frames": 12,
  "pass_memory_target": true,
  "system_samples_count": 150
}
```

## How to Interpret Results

### Memory Analysis
- **✅ PASS**: Peak memory < 50 MB (Phase 5 target)
- **⚠️ WARNING**: Peak memory 40-50 MB (acceptable but monitor)
- **❌ FAIL**: Peak memory > 50 MB (needs optimization)

**Tips:**
- Lower average memory indicates efficient caching
- Spike patterns reveal potential memory leaks
- Compare multiple runs to identify variance

### CPU Analysis
- **Optimal**: Avg CPU < 25%, Peak < 40%
- **Acceptable**: Avg CPU 25-35%, Peak 40-60%
- **Concerning**: Avg CPU > 35%, Peak > 60%

**Tips:**
- High CPU during search operations is expected (indexing, filtering)
- Sustained high CPU between operations indicates background work
- Look for patterns: spikes during scrolling suggest layout recalculation

### Frame Drops
- **✅ SMOOTH**: <1% dropped frames (0-180 over 5 min @ 60fps)
- **⚠️ NOTICEABLE**: 1-3% dropped frames
- **❌ CHOPPY**: >3% dropped frames

**Tips:**
- Dropped frames appear in logs as "Skipped X frames"
- Correlate with memory spikes to diagnose garbage collection stalls

## Testing Scenarios

During the 5-minute profiling run, exercise these workflows:

### Scenario 1: Text Search (1 minute)
1. Tap search field
2. Type product names slowly: "shirt", "pants", "shoes"
3. Delete and retry with different queries
4. Observe FPS in Flutter DevTools (if available)

### Scenario 2: Category Filter (1 minute)
1. Close search field (clear query)
2. Tap category filter
3. Select different categories: Men, Women, Kids, Accessories
4. Toggle multiple categories on/off
5. Observe filter speed and memory changes

### Scenario 3: Price Filter (1 minute)
1. Open price range slider
2. Adjust min price: $0 → $100 → $50
3. Adjust max price: $500 → $100 → $300
4. Observe slider response and result updates

### Scenario 4: Combined Filtering (1 minute)
1. Keep category filter active (e.g., "Men")
2. Apply price filter ($50-$300)
3. Type search query in search field
4. Scroll through results
5. This is the heaviest workload; observe metrics peak

### Scenario 5: Idle/Observation (1 minute)
1. Keep app idle (no interaction)
2. Watch for memory leaks (memory increasing without action)
3. Observe baseline CPU when idle

## Troubleshooting

### "Command not found: flutter"
**Solution:** Ensure Flutter is in your PATH:
```bash
# Check Flutter installation
flutter doctor

# Add to PATH (if needed)
export PATH="$PATH:$HOME/flutter/bin"
```

### "Device not found" or "No running emulator"
**Solution:** Connect a device or start an emulator:
```bash
# List connected devices
flutter devices

# Start emulator (if installed)
emulator -list-avds  # List available emulators
emulator -avd <emulator_name> &  # Start emulator
```

### Script exits immediately with no output
**Solution:** Check for build errors:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run --profile -t lib/main_perf.dart  # Manual run to see errors
```

### Memory stays at 0 MB or reports unrealistic values
**Solution:** The script uses `ps aux` which may not be available on all systems:
- On Linux/Mac: Install GNU coreutils
- On Windows: Consider using WSL2
- Alternative: Manually monitor with `adb shell dumpsys meminfo com.example.app`

### System monitor stops after 5 minutes
**Solution:** This is intentional (prevents infinite runs). To extend, edit the script:
```dart
final maxMonitoringDurationSeconds = 600; // 10 minutes instead of 5
```

## Advanced Usage

### Capture Multiple Profiling Runs

```bash
# Create a profiling session directory
mkdir profiling_session_$(date +%Y%m%d_%H%M%S)
cd profiling_session_*/

# Run multiple times for comparison
for i in {1..3}; do
  echo "Run $i of 3"
  dart run ../tools/profile_automation.dart
  mv profile_logs.txt "profile_logs_run_$i.txt"
  mv profile_report.json "profile_report_run_$i.json"
  sleep 5
done

# Analyze results
cat profile_report_run_*.json
```

### Parse Results in Python

```python
import json

# Load profiling report
with open('profile_report.json') as f:
    metrics = json.load(f)

# Check if target met
memory_passed = metrics['pass_memory_target']
peak_memory = float(metrics['peak_memory_mb'])

print(f"Memory Target ({peak_memory}MB < 50MB): {'✓ PASS' if memory_passed else '✗ FAIL'}")
print(f"Average CPU: {metrics['avg_cpu_percent']}%")
```

### Integrate with CI/CD

Add to your `.github/workflows/profiling.yml` or similar:

```yaml
- name: Run Profiling
  run: |
    dart run tools/profile_automation.dart
    
- name: Check Results
  run: |
    # Fail if memory target not met
    python3 - << 'EOF'
    import json
    with open('profile_report.json') as f:
        if not json.load(f)['pass_memory_target']:
            exit(1)
    EOF
    
- name: Upload Reports
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: profiling-reports
    path: |
      profile_logs.txt
      profile_report.json
```

## Performance Targets

| Metric | Target | Target Type |
|--------|--------|-------------|
| Peak Memory | < 50 MB | Hard (Phase 5 requirement) |
| Avg Memory | < 45 MB | Soft (optimization goal) |
| Peak CPU | < 40% | Soft (smooth operation) |
| Avg CPU | < 25% | Soft (power efficiency) |
| Dropped Frames | < 1% | Soft (smooth scrolling) |

## Next Steps

1. **Run the script** on your target device/emulator
2. **Review results** in `profile_logs.txt` and `profile_report.json`
3. **Compare with previous runs** if available (track regression)
4. **If targets met**: Proceed to merge Phase 5 to main
5. **If targets missed**: Review logs for bottlenecks and optimize

## Related Documents

- **[Phase 5 Completion Summary](../docs/PHASE_5_COMPLETION_SUMMARY.md)** — Architecture and implementation details
- **[Performance Profiling Guide](../docs/PERF_PROFILING_GUIDE.md)** — Manual profiling with DevTools
- **[Quick Reference](../docs/PHASE_5_QUICK_REF.md)** — Commands and checklist

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter logs with `flutter logs`
3. Run DevTools manually for deeper analysis: `flutter run --profile -t lib/main_perf.dart` then connect DevTools
4. Check `profile_logs.txt` for detailed error messages
