import express from 'express';
import PaymentService from '../services/paymentService.js';
import EmailService from '../services/emailService.js';
import { authenticateToken } from '../middleware/auth.js';
import { body, validationResult } from 'express-validator';
import { db } from '../config/database.js';

const router = express.Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     PaymentIntent:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         amount:
 *           type: number
 *         currency:
 *           type: string
 *         status:
 *           type: string
 *         client_secret:
 *           type: string
 */

/**
 * @swagger
 * /api/payments/create-customer:
 *   post:
 *     summary: Create a Stripe customer
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *               name:
 *                 type: string
 *     responses:
 *       201:
 *         description: Customer created successfully
 *       400:
 *         description: Invalid request data
 */
router.post('/create-customer', 
  authenticateToken,
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('name').notEmpty().withMessage('Name is required'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, name } = req.body;
      const userId = req.user.id;

      // Check if customer already exists
      const existingCustomer = await db.get(
        'SELECT stripe_customer_id FROM users WHERE id = ?',
        [userId]
      );

      if (existingCustomer && existingCustomer.stripe_customer_id) {
        return res.status(400).json({ 
          error: 'Customer already exists',
          customer_id: existingCustomer.stripe_customer_id
        });
      }

      // Create Stripe customer
      const customer = await PaymentService.createCustomer(email, name, {
        user_id: userId.toString()
      });

      // Save customer ID to database
      await db.run(
        'UPDATE users SET stripe_customer_id = ? WHERE id = ?',
        [customer.id, userId]
      );

      res.status(201).json({
        message: 'Customer created successfully',
        customer_id: customer.id
      });
    } catch (error) {
      console.error('Create customer error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * @swagger
 * /api/payments/create-subscription:
 *   post:
 *     summary: Create a subscription
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               price_id:
 *                 type: string
 *               trial_days:
 *                 type: number
 *     responses:
 *       201:
 *         description: Subscription created successfully
 */
router.post('/create-subscription',
  authenticateToken,
  [
    body('price_id').notEmpty().withMessage('Price ID is required'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { price_id, trial_days = 14 } = req.body;
      const userId = req.user.id;

      // Get user's Stripe customer ID
      const user = await db.get(
        'SELECT stripe_customer_id, email, name FROM users WHERE id = ?',
        [userId]
      );

      if (!user.stripe_customer_id) {
        return res.status(400).json({ 
          error: 'Customer not found. Please create a customer first.' 
        });
      }

      // Create subscription
      const subscription = await PaymentService.createSubscription(
        user.stripe_customer_id,
        price_id,
        trial_days
      );

      // Save subscription to database
      await db.run(`
        INSERT INTO subscriptions (
          user_id, stripe_subscription_id, stripe_customer_id, 
          price_id, status, amount, trial_end, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
      `, [
        userId,
        subscription.id,
        user.stripe_customer_id,
        price_id,
        subscription.status,
        subscription.items.data[0].price.unit_amount / 100, // Convert from cents
        subscription.trial_end ? new Date(subscription.trial_end * 1000).toISOString() : null
      ]);

      // Send subscription confirmation email
      await EmailService.sendSubscriptionNotification(
        user.email,
        user.name,
        subscription.status,
        'Plano Trainer - R$ 49,90/mês'
      );

      res.status(201).json({
        message: 'Subscription created successfully',
        subscription_id: subscription.id,
        client_secret: subscription.latest_invoice.payment_intent.client_secret,
        status: subscription.status
      });
    } catch (error) {
      console.error('Create subscription error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * @swagger
 * /api/payments/create-payment-intent:
 *   post:
 *     summary: Create a payment intent for one-time payments
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               amount:
 *                 type: number
 *               currency:
 *                 type: string
 *                 default: brl
 *     responses:
 *       201:
 *         description: Payment intent created successfully
 */
router.post('/create-payment-intent',
  authenticateToken,
  [
    body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
    body('currency').optional().isIn(['brl', 'usd']).withMessage('Invalid currency'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { amount, currency = 'brl' } = req.body;
      const userId = req.user.id;

      // Get user's Stripe customer ID
      const user = await db.get(
        'SELECT stripe_customer_id FROM users WHERE id = ?',
        [userId]
      );

      if (!user.stripe_customer_id) {
        return res.status(400).json({ 
          error: 'Customer not found. Please create a customer first.' 
        });
      }

      const paymentIntent = await PaymentService.createPaymentIntent(
        amount,
        currency,
        user.stripe_customer_id
      );

      res.status(201).json({
        message: 'Payment intent created successfully',
        client_secret: paymentIntent.client_secret,
        payment_intent_id: paymentIntent.id
      });
    } catch (error) {
      console.error('Create payment intent error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * @swagger
 * /api/payments/subscriptions:
 *   get:
 *     summary: Get user subscriptions
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of user subscriptions
 */
router.get('/subscriptions', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const subscriptions = await db.all(`
      SELECT 
        s.*,
        u.email,
        u.name
      FROM subscriptions s
      JOIN users u ON s.user_id = u.id
      WHERE s.user_id = ?
      ORDER BY s.created_at DESC
    `, [userId]);

    // Get detailed info from Stripe for active subscriptions
    const detailedSubscriptions = await Promise.all(
      subscriptions.map(async (sub) => {
        if (sub.status === 'active' || sub.status === 'trialing') {
          try {
            const stripeSubscription = await PaymentService.getSubscription(sub.stripe_subscription_id);
            return {
              ...sub,
              stripe_details: {
                current_period_start: new Date(stripeSubscription.current_period_start * 1000),
                current_period_end: new Date(stripeSubscription.current_period_end * 1000),
                cancel_at_period_end: stripeSubscription.cancel_at_period_end,
              }
            };
          } catch (error) {
            console.error('Error fetching Stripe subscription:', error);
            return sub;
          }
        }
        return sub;
      })
    );

    res.json({
      subscriptions: detailedSubscriptions,
      total: subscriptions.length
    });
  } catch (error) {
    console.error('Get subscriptions error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /api/payments/cancel-subscription:
 *   post:
 *     summary: Cancel a subscription
 *     tags: [Payments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               subscription_id:
 *                 type: string
 *               cancel_immediately:
 *                 type: boolean
 *                 default: false
 *     responses:
 *       200:
 *         description: Subscription canceled successfully
 */
router.post('/cancel-subscription',
  authenticateToken,
  [
    body('subscription_id').notEmpty().withMessage('Subscription ID is required'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { subscription_id, cancel_immediately = false } = req.body;
      const userId = req.user.id;

      // Verify subscription belongs to user
      const subscription = await db.get(
        'SELECT * FROM subscriptions WHERE stripe_subscription_id = ? AND user_id = ?',
        [subscription_id, userId]
      );

      if (!subscription) {
        return res.status(404).json({ error: 'Subscription not found' });
      }

      // Cancel in Stripe
      const canceledSubscription = await PaymentService.cancelSubscription(
        subscription_id,
        !cancel_immediately
      );

      // Update database
      await db.run(
        'UPDATE subscriptions SET status = ?, updated_at = datetime("now") WHERE stripe_subscription_id = ?',
        [canceledSubscription.status, subscription_id]
      );

      // Send cancellation email
      const user = await db.get('SELECT email, name FROM users WHERE id = ?', [userId]);
      await EmailService.sendSubscriptionNotification(
        user.email,
        user.name,
        'canceled',
        'Plano Trainer - R$ 49,90/mês'
      );

      res.json({
        message: 'Subscription canceled successfully',
        status: canceledSubscription.status,
        cancel_at_period_end: canceledSubscription.cancel_at_period_end
      });
    } catch (error) {
      console.error('Cancel subscription error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

/**
 * @swagger
 * /api/payments/webhook:
 *   post:
 *     summary: Handle Stripe webhooks
 *     tags: [Payments]
 *     responses:
 *       200:
 *         description: Webhook processed successfully
 */
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];

  try {
    const event = await PaymentService.handleWebhook(req.body, sig);

    // Handle different event types
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionChange(event.data.object);
        break;
      
      case 'customer.subscription.deleted':
        await handleSubscriptionCanceled(event.data.object);
        break;
      
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object);
        break;
      
      case 'invoice.payment_failed':
        await handlePaymentFailed(event.data.object);
        break;
      
      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(400).json({ error: error.message });
  }
});

// Webhook helper functions
async function handleSubscriptionChange(subscription) {
  await db.run(`
    UPDATE subscriptions 
    SET status = ?, updated_at = datetime('now')
    WHERE stripe_subscription_id = ?
  `, [subscription.status, subscription.id]);
}

async function handleSubscriptionCanceled(subscription) {
  await db.run(`
    UPDATE subscriptions 
    SET status = 'canceled', updated_at = datetime('now')
    WHERE stripe_subscription_id = ?
  `, [subscription.id]);
}

async function handlePaymentSucceeded(invoice) {
  const subscription = await db.get(
    'SELECT * FROM subscriptions WHERE stripe_subscription_id = ?',
    [invoice.subscription]
  );

  if (subscription) {
    // Record payment
    await db.run(`
      INSERT INTO payments (
        user_id, subscription_id, stripe_invoice_id, 
        amount, status, created_at
      ) VALUES (?, ?, ?, ?, 'succeeded', datetime('now'))
    `, [
      subscription.user_id,
      subscription.id,
      invoice.id,
      invoice.amount_paid / 100
    ]);

    // Update subscription status
    await db.run(`
      UPDATE subscriptions 
      SET status = 'active', updated_at = datetime('now')
      WHERE id = ?
    `, [subscription.id]);
  }
}

async function handlePaymentFailed(invoice) {
  const subscription = await db.get(`
    SELECT s.*, u.email, u.name FROM subscriptions s
    JOIN users u ON s.user_id = u.id
    WHERE s.stripe_subscription_id = ?
  `, [invoice.subscription]);

  if (subscription) {
    // Record failed payment
    await db.run(`
      INSERT INTO payments (
        user_id, subscription_id, stripe_invoice_id, 
        amount, status, created_at
      ) VALUES (?, ?, ?, ?, 'failed', datetime('now'))
    `, [
      subscription.user_id,
      subscription.id,
      invoice.id,
      invoice.amount_due / 100
    ]);

    // Send payment failed notification
    await EmailService.sendSubscriptionNotification(
      subscription.email,
      subscription.name,
      'payment_failed',
      'Plano Trainer - R$ 49,90/mês'
    );
  }
}

export default router;