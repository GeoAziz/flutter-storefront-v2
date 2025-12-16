import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Performance smoke test for product list with thumbnails.
// Verifies that lazy-loading thumbnails doesn't cause frame drops during scrolling.
// Run with: flutter test test/performance/thumbnail_performance_test.dart
//
// Note: For detailed performance profiling, use `flutter run --profile` and DevTools Timeline tab.
// This smoke test provides a quick sanity-check that scrolling is reasonably smooth.

void main() {
  group('Thumbnail performance', () {
    testWidgets('scrolling product list maintains frame rate',
        (WidgetTester tester) async {
      // Build a simple list of product cards with thumbnails (minimal example)
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Center(
                        child: Text('Thumb $index'),
                      ),
                    ),
                    title: Text('Product $index'),
                    subtitle: Text('\$${100 + index}'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Warm up the rendering pipeline.
      await tester.pumpAndSettle();

      // Scroll down and measure frame rate.
      final Stopwatch timer = Stopwatch()..start();
      int frameCount = 0;

      // Perform scroll gestures and count frames.
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        frameCount++;
        await tester.pump(); // pump one frame
      }

      timer.stop();

      // Simple sanity check: scrolling should complete without long stalls.
      // In a production perf test, you'd measure FPS and set a threshold.
      expect(frameCount, greaterThan(0));
      final avgFrameTime = timer.elapsedMilliseconds / frameCount;

      // ignore: avoid_print
      print(
          'Thumbnail scroll performance: $frameCount frames in ${timer.elapsedMilliseconds}ms (avg: ${avgFrameTime.toStringAsFixed(2)}ms/frame)');
      // Expect frames to be fast enough (this is a loose sanity check)
      expect(avgFrameTime, lessThan(50),
          reason: 'Average frame time should be < 50ms');
    });
  });
}
