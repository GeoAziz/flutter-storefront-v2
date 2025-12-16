/// Feature flags read from --dart-define at runtime.
const bool kEnablePersistentCache = bool.fromEnvironment('ENABLE_PERSISTENT_CACHE', defaultValue: false);
const bool kEnableSentry = bool.fromEnvironment('ENABLE_SENTRY', defaultValue: false);
