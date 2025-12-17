/// Minimal payment gateway adapter interface + stubs for Phase 3

abstract class PaymentGateway {
  /// Initialize gateway with credentials/config
  Future<void> init(Map<String, String> config);

  /// Create a payment intent / checkout session for the given amount (in smallest currency unit)
  Future<String> createPayment(
      int amount, String currency, Map<String, dynamic> metadata);

  /// Verify webhook payload signature (server-side)
  bool verifyWebhook(String signature, String payload);
}

// Example stub for M-Pesa / Stripe adapter implementations to be added.
class StripeAdapter implements PaymentGateway {
  @override
  Future<void> init(Map<String, String> config) async {
    // TODO: set API keys
  }

  @override
  Future<String> createPayment(
      int amount, String currency, Map<String, dynamic> metadata) async {
    // TODO: call Stripe API and return session id
    return 'stripe_session_stub';
  }

  @override
  bool verifyWebhook(String signature, String payload) {
    // TODO: verify using Stripe signing secret
    return true;
  }
}
