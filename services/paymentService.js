import Stripe from 'stripe';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Stripe
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || 'sk_test_...', {
  apiVersion: '2023-10-16',
});

class PaymentService {
  // Create a customer
  static async createCustomer(email, name, metadata = {}) {
    try {
      const customer = await stripe.customers.create({
        email,
        name,
        metadata,
      });
      return customer;
    } catch (error) {
      throw new Error(`Failed to create customer: ${error.message}`);
    }
  }

  // Create a subscription
  static async createSubscription(customerId, priceId, trialPeriodDays = 14) {
    try {
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        trial_period_days: trialPeriodDays,
        payment_behavior: 'default_incomplete',
        payment_settings: { save_default_payment_method: 'on_subscription' },
        expand: ['latest_invoice.payment_intent'],
      });
      return subscription;
    } catch (error) {
      throw new Error(`Failed to create subscription: ${error.message}`);
    }
  }

  // Create payment intent for one-time payments
  static async createPaymentIntent(amount, currency = 'brl', customerId) {
    try {
      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount * 100, // Stripe uses cents
        currency,
        customer: customerId,
        automatic_payment_methods: { enabled: true },
      });
      return paymentIntent;
    } catch (error) {
      throw new Error(`Failed to create payment intent: ${error.message}`);
    }
  }

  // Update subscription
  static async updateSubscription(subscriptionId, updates) {
    try {
      const subscription = await stripe.subscriptions.update(
        subscriptionId,
        updates
      );
      return subscription;
    } catch (error) {
      throw new Error(`Failed to update subscription: ${error.message}`);
    }
  }

  // Cancel subscription
  static async cancelSubscription(subscriptionId, cancelAtPeriodEnd = true) {
    try {
      const subscription = await stripe.subscriptions.update(subscriptionId, {
        cancel_at_period_end: cancelAtPeriodEnd,
      });
      return subscription;
    } catch (error) {
      throw new Error(`Failed to cancel subscription: ${error.message}`);
    }
  }

  // Get subscription details
  static async getSubscription(subscriptionId) {
    try {
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      return subscription;
    } catch (error) {
      throw new Error(`Failed to get subscription: ${error.message}`);
    }
  }

  // List customer subscriptions
  static async getCustomerSubscriptions(customerId) {
    try {
      const subscriptions = await stripe.subscriptions.list({
        customer: customerId,
        status: 'all',
      });
      return subscriptions;
    } catch (error) {
      throw new Error(`Failed to get customer subscriptions: ${error.message}`);
    }
  }

  // Create setup intent for saving payment methods
  static async createSetupIntent(customerId) {
    try {
      const setupIntent = await stripe.setupIntents.create({
        customer: customerId,
        payment_method_types: ['card'],
      });
      return setupIntent;
    } catch (error) {
      throw new Error(`Failed to create setup intent: ${error.message}`);
    }
  }

  // Get customer payment methods
  static async getCustomerPaymentMethods(customerId) {
    try {
      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: 'card',
      });
      return paymentMethods;
    } catch (error) {
      throw new Error(`Failed to get payment methods: ${error.message}`);
    }
  }

  // Create prices for different plans
  static async createPrice(productId, amount, currency = 'brl', interval = 'month') {
    try {
      const price = await stripe.prices.create({
        product: productId,
        unit_amount: amount * 100, // Stripe uses cents
        currency,
        recurring: { interval },
      });
      return price;
    } catch (error) {
      throw new Error(`Failed to create price: ${error.message}`);
    }
  }

  // Create products
  static async createProduct(name, description) {
    try {
      const product = await stripe.products.create({
        name,
        description,
      });
      return product;
    } catch (error) {
      throw new Error(`Failed to create product: ${error.message}`);
    }
  }

  // Handle webhook events
  static async handleWebhook(body, signature) {
    try {
      const event = stripe.webhooks.constructEvent(
        body,
        signature,
        process.env.STRIPE_WEBHOOK_SECRET
      );
      return event;
    } catch (error) {
      throw new Error(`Webhook signature verification failed: ${error.message}`);
    }
  }

  // Get usage statistics
  static async getUsageStatistics(subscriptionId) {
    try {
      const subscription = await stripe.subscriptions.retrieve(subscriptionId, {
        expand: ['items.data.price.product'],
      });
      return subscription;
    } catch (error) {
      throw new Error(`Failed to get usage statistics: ${error.message}`);
    }
  }
}

export default PaymentService;