import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple sync status used by Wishlist/Comparison sync flows.
enum SyncStatus { idle, syncing, success, failed }

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? error;

  const SyncState(this.status, {this.lastSyncedAt, this.error});

  factory SyncState.idle() => const SyncState(SyncStatus.idle);
  factory SyncState.syncing() => SyncState(SyncStatus.syncing);
  factory SyncState.success([DateTime? at]) =>
      SyncState(SyncStatus.success, lastSyncedAt: at);
  factory SyncState.failed(String? error) =>
      SyncState(SyncStatus.failed, error: error);
}

/// Map keys are feature names like 'wishlist' or 'comparison'.
class SyncStatusNotifier extends StateNotifier<Map<String, SyncState>> {
  SyncStatusNotifier() : super({});

  void setIdle(String key) => state = {...state, key: SyncState.idle()};

  void setSyncing(String key) => state = {...state, key: SyncState.syncing()};

  void setSuccess(String key) =>
      state = {...state, key: SyncState.success(DateTime.now())};

  void setFailed(String key, String? error) =>
      state = {...state, key: SyncState.failed(error)};

  SyncState getState(String key) => state[key] ?? SyncState.idle();
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, Map<String, SyncState>>((ref) {
  return SyncStatusNotifier();
});
