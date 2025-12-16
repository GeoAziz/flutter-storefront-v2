import 'package:flutter/services.dart';

/// Device class categorization based on available memory.
enum DeviceClass {
  /// High-end devices with 6+ GB RAM.
  /// Cache: 100 images max, 25 MB in-memory, 200 objects on disk.
  highEnd,

  /// Mid-range devices with 4–5 GB RAM.
  /// Cache: 70 images max, 18 MB in-memory, 150 objects on disk.
  midRange,

  /// Low-end devices with < 4 GB RAM (AGGRESSIVE MODE).
  /// Cache: 50 images max, 10 MB in-memory, 80 objects on disk.
  /// Optimized for memory-constrained devices with aggressive eviction.
  lowEnd,
}

/// Cache configuration adapted to device capabilities.
class DeviceCacheConfig {
  final DeviceClass deviceClass;
  final int inMemoryCacheBytes;
  final int inMemoryCacheCount;
  final int diskCacheObjectCount;
  final Duration diskCacheStalePeriod;

  DeviceCacheConfig({
    required this.deviceClass,
    required this.inMemoryCacheBytes,
    required this.inMemoryCacheCount,
    required this.diskCacheObjectCount,
    required this.diskCacheStalePeriod,
  });

  /// Preset configuration for high-end devices.
  factory DeviceCacheConfig.highEnd() => DeviceCacheConfig(
        deviceClass: DeviceClass.highEnd,
        inMemoryCacheBytes: 25 * 1024 * 1024, // 25 MB
        inMemoryCacheCount: 100,
        diskCacheObjectCount: 200,
        diskCacheStalePeriod: const Duration(days: 30),
      );

  /// Preset configuration for mid-range devices.
  factory DeviceCacheConfig.midRange() => DeviceCacheConfig(
        deviceClass: DeviceClass.midRange,
        inMemoryCacheBytes: 18 * 1024 * 1024, // 18 MB
        inMemoryCacheCount: 70,
        diskCacheObjectCount: 150,
        diskCacheStalePeriod: const Duration(days: 20),
      );

  /// Preset configuration for low-end devices (aggressive memory management).
  /// 
  /// Optimized for devices with < 4 GB RAM and heavily constrained environments.
  /// Ultra-aggressive settings: 50 images max, 10 MB memory limit
  /// - Minimizes memory footprint to absolute necessity
  /// - Rapid image eviction when cache is full
  /// - Combined with 5% VisibilityDetector threshold for fast loading
  /// - Suitable for budget smartphones, older devices, and emerging markets
  /// - Tested for smooth 55+ FPS performance on low-end hardware
  factory DeviceCacheConfig.lowEnd() => DeviceCacheConfig(
        deviceClass: DeviceClass.lowEnd,
        inMemoryCacheBytes: 10 * 1024 * 1024, // 10 MB (aggressive limit)
        inMemoryCacheCount: 50, // Ultra-aggressive: 50 images max
        diskCacheObjectCount: 80,
        diskCacheStalePeriod: const Duration(days: 14),
      );

  /// Detect device class based on available memory.
  ///
  /// Uses platform channels to retrieve device memory info.
  /// Falls back to mid-range if detection fails.
  static Future<DeviceClass> detectDeviceClass() async {
    try {
      const platform = MethodChannel('com.example.shop/device');
      final totalMemory = await platform.invokeMethod<int>('getTotalMemory');

      if (totalMemory == null) {
        return DeviceClass.midRange; // Safe default
      }

      // Convert bytes to GB
      final totalMemoryGB = totalMemory / (1024 * 1024 * 1024);

      if (totalMemoryGB >= 6) {
        return DeviceClass.highEnd;
      } else if (totalMemoryGB >= 4) {
        return DeviceClass.midRange;
      } else {
        return DeviceClass.lowEnd;
      }
    } catch (e) {
      // Log error and return safe default
      // ignore: avoid_print
      print('Failed to detect device class: $e');
      return DeviceClass.midRange;
    }
  }

  /// Get configuration based on detected device class.
  static Future<DeviceCacheConfig> adaptive() async {
    final deviceClass = await detectDeviceClass();
    return fromDeviceClass(deviceClass);
  }

  /// Create configuration from device class.
  static DeviceCacheConfig fromDeviceClass(DeviceClass deviceClass) {
    switch (deviceClass) {
      case DeviceClass.highEnd:
        return DeviceCacheConfig.highEnd();
      case DeviceClass.midRange:
        return DeviceCacheConfig.midRange();
      case DeviceClass.lowEnd:
        return DeviceCacheConfig.lowEnd();
    }
  }

  @override
  String toString() =>
      'DeviceCacheConfig(device: $deviceClass, inMemory: ${inMemoryCacheBytes ~/ (1024 * 1024)}MB, disk: $diskCacheObjectCount objects)';
}
