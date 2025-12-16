import '../constants.dart';
import 'cache/cache_provider.dart';
import 'cache/memory_cache.dart';
import 'cache/hive_cache.dart';
import 'telemetry/telemetry_service.dart';
import 'telemetry/dev_telemetry.dart';
import 'telemetry/sentry_telemetry.dart';
 
CacheProvider? _cacheProvider;
TelemetryService? _telemetryService;

/// Initialize core services (cache + telemetry). Safe to call multiple times.
Future<void> initServices({String? hiveCustomPath, Map<String, dynamic>? telemetryOptions}) async {
  // Initialize cache provider (Hive or Memory). HiveCache will call Hive.initFlutter
  // internally when no custom path is provided.
  _cacheProvider = await createCacheProvider(hiveCustomPath: hiveCustomPath);

  // Create telemetry service and initialize it.
  _telemetryService = createTelemetryService(options: telemetryOptions);
  await _telemetryService!.init(options: telemetryOptions);
}

CacheProvider get cacheProvider {
  if (_cacheProvider != null) return _cacheProvider!;
  // Return a default memory cache if services weren't initialized.
  final mem = MemoryCache();
  mem.init();
  return mem;
}

TelemetryService get telemetryService {
  return _telemetryService ?? DevTelemetry();
}

// Test helpers: allow overriding services in tests.
void setTelemetryServiceForTest(TelemetryService svc) {
  _telemetryService = svc;
}

void setCacheProviderForTest(CacheProvider cache) {
  _cacheProvider = cache;
}

/// Factory to create a cache provider based on feature flags.
/// - If `enablePersistentCache` is true, returns a HiveCache (and initializes it).
/// - Otherwise returns an in-memory MemoryCache.
Future<CacheProvider> createCacheProvider({String? hiveCustomPath}) async {
  if (enablePersistentCache) {
    final hive = HiveCache(customPath: hiveCustomPath);
    await hive.init();
    return hive;
  }
  final mem = MemoryCache();
  await mem.init();
  return mem;
}

/// Factory to create a telemetry service based on feature flags.
/// Accepts optional options passed to SentryTelemetry when enabled.
TelemetryService createTelemetryService({Map<String, dynamic>? options}) {
  if (enableTelemetry) {
    final dsn = options != null && options.containsKey('dsn') ? options['dsn'] as String : '';
    final enableTracing = options != null && options['enableTracing'] == true;
    return SentryTelemetry(dsn: dsn, enableTracing: enableTracing);
  }
  return DevTelemetry();
}
