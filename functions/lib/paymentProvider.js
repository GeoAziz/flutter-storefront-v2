class PaymentResult {
  constructor(success, id, message) {
    this.success = !!success;
    this.id = id || null;
    this.message = message || null;
  }
}

/**
 * MockPaymentProvider implements a minimal interface to simulate charging an
 * order. This is NOT a real payment integration. Use in emulator-only tests.
 */
class MockPaymentProvider {
  constructor() {}

  /**
   * Simulate a charge. Returns a Promise resolving to PaymentResult.
   * The payload may include { amount, currency, simulateFailure: true }
   */
  async charge(payload) {
    const simulateFailure = payload && payload.simulateFailure;
    if (simulateFailure) {
      return new PaymentResult(false, null, 'simulated_failure');
    }
    // Generate a deterministic id for testing
    const id = `mockpay_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    return new PaymentResult(true, id, 'ok');
  }
}

/**
 * StripePaymentProvider is optional and used only when STRIPE_API_KEY is set.
 * It requires the `stripe` package to be installed in `functions/`.
 */
class StripePaymentProvider {
  constructor(apiKey) {
    this.apiKey = apiKey;
    try {
      // require at runtime so functions can work without the package
      const Stripe = require('stripe');
      this.stripe = Stripe(apiKey);
    } catch (e) {
      throw new Error('stripe package not installed. npm install stripe in functions/ to enable StripePaymentProvider');
    }
  }

  /**
   * Create a PaymentIntent (test mode if apiKey is a test key). Returns a
   * PaymentResult-like object.
   */
  async charge(payload) {
    const amount = payload && payload.amount ? payload.amount : 100;
    const currency = payload && payload.currency ? payload.currency : 'usd';
    const simulateFailure = payload && payload.simulateFailure;
    if (simulateFailure) {
      return new PaymentResult(false, null, 'simulated_failure');
    }

    const intent = await this.stripe.paymentIntents.create({
      amount,
      currency,
      metadata: payload && payload.metadata || {},
      payment_method_types: ['card'],
    });
    return new PaymentResult(true, intent.id, 'created');
  }
}

function getProviderFromEnv() {
  const key = process.env.STRIPE_API_KEY || null;
  if (key) {
    return new StripePaymentProvider(key);
  }
  return new MockPaymentProvider();
}

module.exports = { MockPaymentProvider, StripePaymentProvider, PaymentResult, getProviderFromEnv };
