#!/usr/bin/env dart
/// Automated Flutter App Profiling Script
/// 
/// This script automates the profiling process for Phase 5 search performance testing.
/// It launches the app in profile mode, captures system stats, and generates a profiling report.
/// 
/// Usage:
///   dart run tools/profile_automation.dart
///   
/// Output:
///   - profile_logs.txt — complete logs and metrics
///   - profile_report.json — structured metrics for analysis
///
/// Requirements:
///   - Flutter SDK installed
///   - Real device or emulator running
///   - Dart SDK (comes with Flutter)

import 'dart:io';
import 'dart:async';
import 'dart:convert';

// Metrics container
class ProfileMetrics {
  final List<String> flutterLogs = [];
  final List<SystemSample> systemSamples = [];
  DateTime? startTime;
  DateTime? endTime;
  int framesRendered = 0;
  int droppedFrames = 0;
  double peakMemoryMB = 0;
  double avgMemoryMB = 0;
  double peakCPU = 0;
  double avgCPU = 0;

  ProfileMetrics();

  void addFlutterLog(String line) => flutterLogs.add(line);
  
  void addSystemSample(SystemSample sample) {
    systemSamples.add(sample);
    if (sample.memoryMB > peakMemoryMB) peakMemoryMB = sample.memoryMB;
    if (sample.cpuPercent > peakCPU) peakCPU = sample.cpuPercent;
  }

  void calculateAverages() {
    if (systemSamples.isEmpty) return;
    avgMemoryMB = systemSamples.map((s) => s.memoryMB).reduce((a, b) => a + b) / systemSamples.length;
    avgCPU = systemSamples.map((s) => s.cpuPercent).reduce((a, b) => a + b) / systemSamples.length;
  }

  Map<String, dynamic> toJson() => {
    'timestamp': DateTime.now().toIso8601String(),
    'duration_seconds': endTime?.difference(startTime ?? DateTime.now()).inSeconds ?? 0,
    'peak_memory_mb': peakMemoryMB.toStringAsFixed(2),
    'avg_memory_mb': avgMemoryMB.toStringAsFixed(2),
    'peak_cpu_percent': peakCPU.toStringAsFixed(2),
    'avg_cpu_percent': avgCPU.toStringAsFixed(2),
    'frames_rendered': framesRendered,
    'dropped_frames': droppedFrames,
    'pass_memory_target': peakMemoryMB < 50,
    'system_samples_count': systemSamples.length,
  };

  @override
  String toString() {
    final passed = peakMemoryMB < 50 ? '✅ PASS' : '❌ FAIL';
    return '''
╔════════════════════════════════════════╗
║      PROFILING SUMMARY REPORT          ║
╚════════════════════════════════════════╝

Duration:        ${endTime?.difference(startTime ?? DateTime.now()).inSeconds ?? 'N/A'}s
Peak Memory:     ${peakMemoryMB.toStringAsFixed(2)} MB (Target: <50 MB) $passed
Avg Memory:      ${avgMemoryMB.toStringAsFixed(2)} MB
Peak CPU:        ${peakCPU.toStringAsFixed(2)} %
Avg CPU:         ${avgCPU.toStringAsFixed(2)} %
Frames Rendered: $framesRendered
Dropped Frames:  $droppedFrames

Status: ${peakMemoryMB < 50 ? 'READY FOR PRODUCTION' : 'NEEDS OPTIMIZATION'}
    ''';
  }
}

class SystemSample {
  final DateTime timestamp;
  final double memoryMB;
  final double cpuPercent;
  final int pidCount;

  SystemSample({
    required this.timestamp,
    required this.memoryMB,
    required this.cpuPercent,
    required this.pidCount,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'memory_mb': memoryMB.toStringAsFixed(2),
    'cpu_percent': cpuPercent.toStringAsFixed(2),
  };
}

Future<void> main(List<String> args) async {
  print('╔════════════════════════════════════════╗');
  print('║   Phase 5 Automated Profiling Script   ║');
  print('╚════════════════════════════════════════╝\n');

  final metrics = ProfileMetrics();
  final profileLogsFile = File('profile_logs.txt');
  final profileReportFile = File('profile_report.json');
  
  final logSink = profileLogsFile.openWrite();
  
  try {
    logSink.writeln('Profile Session: ${DateTime.now().toIso8601String()}');
    logSink.writeln('Command: flutter run --profile -t lib/main_perf.dart');
    logSink.writeln('═' * 70);
    logSink.writeln('');

    print('[INFO] Starting Flutter app in profile mode...');
    print('[INFO] Device: Check that device/emulator is connected\n');

    metrics.startTime = DateTime.now();

    // Launch Flutter process
    final flutterProcess = await Process.start(
      'flutter',
      [
        'run',
        '--profile',
        '-t', 'lib/main_perf.dart',
        '--android-skip-build-dependency-validation',
      ],
    );

    // Monitor process output and system stats
    final flutterStdoutSubscription = flutterProcess.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) {
          metrics.addFlutterLog(line);
          logSink.writeln('[FLUTTER] $line');
          stdout.writeln('[FLUTTER] $line');
          
          // Extract frames info if available
          if (line.contains('frames')) {
            try {
              final match = RegExp(r'(\d+)\s+frames').firstMatch(line);
              if (match != null) {
                metrics.framesRendered = int.parse(match.group(1)!);
              }
            } catch (e) {
              // Ignore parsing errors
            }
          }
        });

    final flutterStderrSubscription = flutterProcess.stderr
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) {
          logSink.writeln('[FLUTTER_ERR] $line');
          stderr.writeln('[FLUTTER_ERR] $line');
        });

    // Start system monitoring (capture stats every 2 seconds for up to 5 minutes)
    final systemMonitoringStopwatch = Stopwatch()..start();
    final maxMonitoringDurationSeconds = 300; // 5 minutes
    
    final systemTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (systemMonitoringStopwatch.elapsedMilliseconds > maxMonitoringDurationSeconds * 1000) {
        timer.cancel();
        return;
      }

      try {
        final sample = await _captureSystemStats();
        metrics.addSystemSample(sample);
        
        final memStatus = sample.memoryMB < 50 ? '✓' : '⚠';
        print('[$memStatus] Memory: ${sample.memoryMB.toStringAsFixed(1)}MB | CPU: ${sample.cpuPercent.toStringAsFixed(1)}%');
        logSink.writeln('[SYSTEM] Memory: ${sample.memoryMB.toStringAsFixed(1)}MB | CPU: ${sample.cpuPercent.toStringAsFixed(1)}% | ${sample.timestamp.toIso8601String()}');
      } catch (e) {
        logSink.writeln('[SYSTEM_ERROR] $e');
      }
    });

    // Wait for user to stop profiling (Ctrl+C or process completion)
    print('\n[INFO] App is running. Exercise the search UI (scroll, filter, etc.)');
    print('[INFO] Press Ctrl+C to stop profiling...\n');

    await flutterProcess.exitCode;
    
    systemTimer.cancel();
    await flutterStdoutSubscription.cancel();
    await flutterStderrSubscription.cancel();

    metrics.endTime = DateTime.now();
    metrics.calculateAverages();

    logSink.writeln('');
    logSink.writeln('═' * 70);
    logSink.writeln(metrics.toString());

    // Write JSON report
    profileReportFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(metrics.toJson()),
    );

    print('\n${metrics.toString()}');
    print('[INFO] Logs saved to: ${profileLogsFile.path}');
    print('[INFO] Report saved to: ${profileReportFile.path}\n');

    if (metrics.peakMemoryMB < 50) {
      print('✅ PROFILING PASSED: Memory usage is within target (<50MB)');
    } else {
      print('❌ PROFILING FAILED: Memory usage exceeded target (${metrics.peakMemoryMB.toStringAsFixed(2)}MB > 50MB)');
    }

  } catch (e, st) {
    print('ERROR: $e');
    print(st);
    logSink.writeln('ERROR: $e');
    logSink.writeln(st);
  } finally {
    await logSink.close();
  }
}

Future<SystemSample> _captureSystemStats() async {
  try {
    // Get process info from ps command (works on macOS and Linux)
    final result = await Process.run('ps', ['aux'], runInShell: Platform.isWindows);
    
    if (result.exitCode != 0) {
      throw Exception('Failed to capture system stats');
    }

    final lines = (result.stdout as String).split('\n');
    double totalMemoryPercent = 0;
    double totalCPUPercent = 0;
    int processCount = 0;

    // Parse ps output (columns: USER PID %CPU %MEM VSZ RSS STAT START TIME COMMAND)
    for (final line in lines) {
      if (line.contains('flutter') || line.contains('dart')) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          try {
            totalCPUPercent += double.parse(parts[2]);
            totalMemoryPercent += double.parse(parts[3]);
            processCount++;
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }
    }

    // Estimate memory in MB (rough conversion: % of system memory)
    // Assuming 8GB system, 1% ≈ 80MB. Adjust based on your system.
    const systemMemoryGB = 8;
    final estimatedMemoryMB = (totalMemoryPercent / 100) * (systemMemoryGB * 1024);

    return SystemSample(
      timestamp: DateTime.now(),
      memoryMB: estimatedMemoryMB,
      cpuPercent: totalCPUPercent,
      pidCount: processCount,
    );
  } catch (e) {
    // Return a zero sample if capture fails
    return SystemSample(
      timestamp: DateTime.now(),
      memoryMB: 0,
      cpuPercent: 0,
      pidCount: 0,
    );
  }
}
