import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/cart_provider.dart';

void main() {
  test('cart add/remove/persist/restore', () async {
    // Use mock shared preferences in tests.
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);

    await notifier.addItem('p1', 2);
    expect(container.read(cartProvider)['p1'], 2);

    await notifier.addItem('p1', 1);
    expect(container.read(cartProvider)['p1'], 3);

    await notifier.removeItem('p1', 2);
    expect(container.read(cartProvider)['p1'], 1);

    await notifier.clear();
    expect(container.read(cartProvider).isEmpty, true);

    // Persist one item, then create a new container to check restore
    await notifier.addItem('p2', 5);

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);

    // allow async init to complete; poll briefly for restored value
    int attempts = 0;
    int? restored;
    while (attempts < 10) {
      restored = container2.read(cartProvider)['p2'];
      if (restored != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    expect(restored, 5);
  });
}
