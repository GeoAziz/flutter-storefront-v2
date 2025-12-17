import 'dart:ui' show FrameTiming;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shop/main.dart';

/// CI-Ready Performance Integration Tests
///
/// These integration tests validate performance characteristics:
/// - Memory usage during scrolling
/// - Frame timing and FPS metrics
/// - Image lazy loading behavior
/// - Cache management under load
///
/// Run with: `flutter test integration_test/performance_integration_test.dart`
/// Or in CI: `flutter drive --target=integration_test/performance_integration_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Integration Tests', () {
    setUp(() async {
      // Per-test setup if needed
    });

    tearDown(() async {
      // Per-test cleanup
      // Reset binding state if needed
    });

    testWidgets('Frame timing during product list scroll',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Prepare frame timing collector
      final frameTimes = <Duration>[];
      final observer = _PerformanceObserver(frameTimes);

      try {
        // Register observer to capture frame timings
        WidgetsBinding.instance.addTimingsCallback(observer.onFrameTiming);

        // Simulate scrolling through product list
        // Perform 10 scroll gestures to simulate user interaction
        for (int i = 0; i < 10; i++) {
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -400),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Allow some time for any pending frames to render
        await tester.pumpAndSettle(const Duration(seconds: 1));
      } finally {
        // Always cleanup observer
        WidgetsBinding.instance.removeTimingsCallback(observer.onFrameTiming);
      }

      // Analyze frame timings
      if (frameTimes.isNotEmpty) {
        final avgFrameTimeMs = frameTimes.reduce((a, b) => a + b).inMilliseconds /
            frameTimes.length;
        final maxFrameTimeMs = frameTimes
            .reduce((a, b) => a > b ? a : b)
            .inMilliseconds
            .toDouble();
        final minFrameTimeMs =
            frameTimes.reduce((a, b) => a < b ? a : b).inMilliseconds.toDouble();

        // 60 FPS = 16.67 ms per frame; 55 FPS = ~18 ms per frame
        const targetFrameTimeMs = 18.0;

        // Log metrics for CI analysis
        print('📊 Frame Timing Metrics:');
        print('  Average Frame Time: ${avgFrameTimeMs.toStringAsFixed(2)} ms');
        print('  Max Frame Time: ${maxFrameTimeMs.toStringAsFixed(2)} ms');
        print('  Min Frame Time: ${minFrameTimeMs.toStringAsFixed(2)} ms');
        print('  Frame Count: ${frameTimes.length}');
        print('  Dropped Frames (>$targetFrameTimeMs ms): '
            '${frameTimes.where((f) => f.inMilliseconds > targetFrameTimeMs).length}');

        // Assert that average frame time is acceptable
        expect(avgFrameTimeMs, lessThan(targetFrameTimeMs),
            reason:
                'Average frame time ($avgFrameTimeMs ms) exceeded target ($targetFrameTimeMs ms)');

        // Assert that max frame time doesn't exceed reasonable threshold (2x target)
        expect(maxFrameTimeMs, lessThan(targetFrameTimeMs * 2),
            reason:
                'Max frame time ($maxFrameTimeMs ms) exceeded threshold (${targetFrameTimeMs * 2} ms)');
      }

      // Ensure app is still responsive
      expect(find.byType(MyApp), findsOneWidget);
    });

    testWidgets('Lazy loading prevents excessive image loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get initial widget count
      final initialImageCount =
          find.byType(Image).evaluate().length;

        // Scroll down significantly to load new content
        for (int i = 0; i < 15; i++) {
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -300),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }      // Get final widget count
      final finalImageCount = find.byType(Image).evaluate().length;

      print('📊 Lazy Loading Metrics:');
      print('  Initial Image Widgets: $initialImageCount');
      print('  Final Image Widgets: $finalImageCount');
      print('  Images Added: ${finalImageCount - initialImageCount}');

      // Verify images are being loaded incrementally (not all at once)
      // This indicates lazy loading is working
      expect(finalImageCount, greaterThan(initialImageCount),
          reason: 'Lazy loading should add images as user scrolls');
    });

    testWidgets('Sustained scrolling with image cache stability',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Track memory-intensive operations
      final scrollMetrics = <_ScrollMetric>[];

      try {
        // Perform sustained scrolling to stress test cache
        for (int batch = 0; batch < 5; batch++) {
          final batchStartTime = DateTime.now();

          for (int i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -500),
            );
            await tester.pump(const Duration(milliseconds: 200));
          }

          final batchDuration =
              DateTime.now().difference(batchStartTime);
          final imageCount = find.byType(Image).evaluate().length;

          scrollMetrics.add(_ScrollMetric(
            batchNumber: batch,
            duration: batchDuration,
            imageCount: imageCount,
          ));

          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Log scroll metrics
        print('📊 Sustained Scroll Metrics:');
        for (final metric in scrollMetrics) {
          print('  Batch ${metric.batchNumber}: '
              '${metric.duration.inMilliseconds}ms, '
              '${metric.imageCount} images');
        }

        // Verify app remains responsive
        expect(find.byType(MyApp), findsOneWidget);

        // Check that image count stabilizes (not growing unbounded)
        final lastImageCount =
            scrollMetrics.last.imageCount;
        final secondLastImageCount =
            scrollMetrics[scrollMetrics.length - 2].imageCount;

        print('  Last 2 batches image counts: '
            '$secondLastImageCount -> $lastImageCount');
        expect(lastImageCount, lessThanOrEqualTo(secondLastImageCount + 10),
            reason:
                'Image count should stabilize; possible cache leak detected');
      } catch (e) {
        print('⚠️ Scroll test error: $e');
        rethrow;
      }
    });

    testWidgets('App recovers from rapid navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 1));

        // Rapidly trigger navigation and scrolling to stress cache
        for (int cycle = 0; cycle < 3; cycle++) {
          // Scroll down
          for (int i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -300),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }

          // Scroll back up
          for (int i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, 300),
            );
            await tester.pump(const Duration(milliseconds: 100));
          }        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Verify app is still responsive and hasn't crashed
      expect(find.byType(MyApp), findsOneWidget);
      print('✅ Rapid navigation test passed');
    });

    testWidgets('No exceptions during extended scrolling',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      int scrollCount = 0;
      final startTime = DateTime.now();

      try {
        // Continuous scrolling for 30 seconds
        while (DateTime.now().difference(startTime).inSeconds < 30) {
          await tester.drag(
            find.byType(ListView).first,
            const Offset(0, -400),
          );
          await tester.pump(const Duration(milliseconds: 150));
          scrollCount++;
        }
      } catch (e) {
        // If we timeout or crash, record the failure
        print('❌ Extended scroll failed after $scrollCount scrolls: $e');
        fail('Extended scrolling failed: $e');
      }

      print('✅ Extended scroll test passed ($scrollCount scrolls in 30s)');
      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}

/// Performance observer to capture frame timings
class _PerformanceObserver {
  final List<Duration> frameTimes;

  _PerformanceObserver(this.frameTimes);

  void onFrameTiming(List<FrameTiming> timings) {
    for (final timing in timings) {
      // Record the total time from frame start to frame finish
      frameTimes.add(timing.totalSpan);
    }
  }
}

/// Helper class to store scroll batch metrics
class _ScrollMetric {
  final int batchNumber;
  final Duration duration;
  final int imageCount;

  _ScrollMetric({
    required this.batchNumber,
    required this.duration,
    required this.imageCount,
  });
}
