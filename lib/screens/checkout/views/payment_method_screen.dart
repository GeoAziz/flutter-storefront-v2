import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/cart_provider.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/repositories/order_repository.dart';
import 'package:shop/models/order.dart';
import 'package:shop/route/route_names.dart';

/// PaymentMethodScreen allows users to select payment method and complete the order.
/// Collects cart items, calculates total, and creates an order in Firestore.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final List<Map<String, String>> _paymentMethods = [
    {'id': 'credit_card', 'label': 'Credit Card', 'icon': '💳'},
    {'id': 'debit_card', 'label': 'Debit Card', 'icon': '🏧'},
    {'id': 'mobile_money', 'label': 'Mobile Money (M-Pesa)', 'icon': '📱'},
    {'id': 'bank_transfer', 'label': 'Bank Transfer', 'icon': '🏦'},
    {'id': 'cash_on_delivery', 'label': 'Cash on Delivery', 'icon': '💵'},
  ];

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final cart = ref.watch(cartProvider);
    final orderRepo = ref.read(orderRepositoryProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Please sign in to proceed with checkout'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      );
    }

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Method')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Your cart is empty'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteNames.home);
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate total (simplified: assume each item costs 100 for demo)
    final totalQuantity = cart.values.fold<int>(0, (p, e) => p + e);
    final totalPrice = totalQuantity * 100.0; // Simplified for demo

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items'),
                          Text('$totalQuantity'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('KES ${totalPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'KES ${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: _isProcessing
                        ? null
                        : () {
                            setState(() {
                              _selectedPaymentMethod = method['id'];
                            });
                          },
                    child: Card(
                      elevation: isSelected ? 4 : 1,
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Text(method['icon']!,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                method['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Colors.blue),
                            if (!isSelected)
                              Icon(
                                Icons.radio_button_unchecked,
                                color: Colors.grey.shade400,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // Complete Order Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedPaymentMethod == null || _isProcessing
                      ? null
                      : () => _completeOrder(
                            context,
                            orderRepo,
                            userId,
                            cart,
                            totalPrice,
                          ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Complete Order'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed:
                      _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Back to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeOrder(
    BuildContext context,
    OrderRepository orderRepo,
    String userId,
    Map<String, int> cart,
    double totalPrice,
  ) async {
    setState(() => _isProcessing = true);

    try {
      // Convert cart items to OrderItems (simplified)
      final orderItems = cart.entries
          .map((e) => OrderItem(
                productId: e.key,
                productName:
                    'Product ${e.key}', // Simplified for demo; ideally fetch from product repo
                quantity: e.value,
                price:
                    100.0, // Simplified for demo; ideally fetch from product repo
              ))
          .toList();

      // Place the order
      final orderId = await orderRepo.placeOrder(
        userId: userId,
        items: orderItems,
        totalPrice: totalPrice,
        paymentMethod: _selectedPaymentMethod,
      );

      // Clear the cart after successful order
      await ref.read(cartProvider.notifier).clear();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order ID: $orderId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to orders screen or home
        Navigator.of(context).pushReplacementNamed(RouteNames.orders);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Order error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
