import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/wishlist_repository.dart';
import '../repositories/comparison_repository.dart';
import 'sync_status_provider.dart';
import 'wishlist_provider.dart' show wishlistRepositoryProvider;
import 'comparison_provider.dart' show comparisonRepositoryProvider;

/// SyncManager coordinates best-effort syncs and updates the [syncStatusProvider].
class SyncManager {
  final Ref _ref;
  final WishlistRepository _wishlistRepo;
  final ComparisonRepository _comparisonRepo;

  SyncManager(this._ref, this._wishlistRepo, this._comparisonRepo);

  /// Simple retry helper with exponential backoff (maxAttempts including first try).
  Future<T> _retry<T>(Future<T> Function() fn,
      {int maxAttempts = 3,
      Duration baseDelay = const Duration(milliseconds: 300)}) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        final delay = baseDelay * (1 << (attempt - 1));
        await Future.delayed(delay);
      }
    }
  }

  /// Sync local wishlist to Firestore for [uid]. Updates sync status.
  Future<void> syncWishlist(String uid) async {
    final notifier =
        _ref.read(syncStatusProvider.notifier) as SyncStatusNotifier;
    notifier.setSyncing('wishlist');
    try {
      await _retry(() => _wishlistRepo.syncToFirestore(uid));
      notifier.setSuccess('wishlist');
    } catch (e) {
      notifier.setFailed('wishlist', e.toString());
    }
  }

  /// Sync local comparison list to Firestore for [uid]. Updates sync status.
  Future<void> syncComparison(String uid) async {
    final notifier =
        _ref.read(syncStatusProvider.notifier) as SyncStatusNotifier;
    notifier.setSyncing('comparison');
    try {
      await _retry(() => _comparisonRepo.syncToFirestore(uid));
      notifier.setSuccess('comparison');
    } catch (e) {
      notifier.setFailed('comparison', e.toString());
    }
  }
}

final syncManagerProvider = Provider<SyncManager>((ref) {
  final wishlistRepo = ref.read(wishlistRepositoryProvider);
  final comparisonRepo = ref.read(comparisonRepositoryProvider);
  return SyncManager(ref, wishlistRepo, comparisonRepo);
});
