# Performance & Memory Profiling (Sprint 1)

This guide describes quick steps to profile memory and CPU while running the app and validating that lazy-loading and caching keep memory under 50MB.

1. DevTools memory snapshot
   - Run the app in profile mode:
     ```bash
     flutter run --profile
     ```
   - Open DevTools and capture a memory snapshot after loading product lists.
   - Observe active allocations and raster cache sizes.

2. Verify lazy-loading
   - Scroll through product lists and capture memory before and after scrolling.
   - Ensure images not in viewport are not held in memory.
   - Use thumbnails (smaller image sizes) to reduce memory.

3. Automated smoke test
   - Use `tools/profile_automation.dart` to simulate scrolling and collect traces.
   - The script generates a memory and CPU report in `profile_logs.txt` / `profile_report.json`.

4. Target: Keep resident memory < 50MB on typical device
   - Use `cached_network_image` with `maxWidth`/`maxHeight` resizing when available.
   - Prefer thumbnails (120x120) for list/grid views and full-size images for product details.

5. CI Checks (optional)
   - Add a smoke job that launches a headless emulator and runs `profile_automation.dart` to validate memory budgets.

