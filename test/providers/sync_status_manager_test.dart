import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/sync_status_provider.dart';

// Minimal fake repos matching the public methods used by SyncManager
// We don't need full fake repos for this unit test. We'll exercise the notifier directly.

void main() {
  test('SyncStatusNotifier transitions on success', () async {
    final container = ProviderContainer(overrides: []);
    addTearDown(container.dispose);

    // create a provider container and manually access the notifier
    final syncStatusNotifier =
        container.read(syncStatusProvider.notifier) as SyncStatusNotifier;

    // Simulate: directly call notifier methods as SyncManager would
    syncStatusNotifier.setSyncing('wishlist');
    expect(container.read(syncStatusProvider)['wishlist']?.status,
        SyncStatus.syncing);

    syncStatusNotifier.setSuccess('wishlist');
    expect(container.read(syncStatusProvider)['wishlist']?.status,
        SyncStatus.success);

    syncStatusNotifier.setSyncing('comparison');
    expect(container.read(syncStatusProvider)['comparison']?.status,
        SyncStatus.syncing);

    syncStatusNotifier.setFailed('comparison', 'error');
    expect(container.read(syncStatusProvider)['comparison']?.status,
        SyncStatus.failed);
  });
}
