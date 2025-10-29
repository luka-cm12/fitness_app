import express from 'express';
import { body, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';

const router = express.Router();

/**
 * @swagger
 * /api/subscriptions/plans:
 *   get:
 *     summary: Get available subscription plans
 *     tags: [Subscriptions]
 */
router.get('/plans', async (req, res, next) => {
  try {
    const plans = [
      {
        id: 'trainer_basic',
        name: 'Treinador Básico',
        price: 49.90,
        currency: 'BRL',
        billing_cycle: 'monthly',
        features: [
          'Até 10 alunos',
          'Criação de treinos personalizados',
          'Acompanhamento de progresso',
          'Suporte por email'
        ],
        max_athletes: 10,
        target_user_type: 'trainer'
      },
      {
        id: 'trainer_pro',
        name: 'Treinador Profissional',
        price: 89.90,
        currency: 'BRL',
        billing_cycle: 'monthly',
        features: [
          'Até 25 alunos',
          'Criação de treinos personalizados',
          'Planos nutricionais básicos',
          'Relatórios avançados',
          'Suporte prioritário'
        ],
        max_athletes: 25,
        target_user_type: 'trainer'
      },
      {
        id: 'trainer_enterprise',
        name: 'Treinador Empresarial',
        price: 149.90,
        currency: 'BRL',
        billing_cycle: 'monthly',
        features: [
          'Alunos ilimitados',
          'Criação de treinos personalizados',
          'Planos nutricionais completos',
          'Relatórios avançados',
          'API access',
          'Suporte 24/7'
        ],
        max_athletes: -1, // unlimited
        target_user_type: 'trainer'
      },
      {
        id: 'nutritionist_basic',
        name: 'Nutricionista Básico',
        price: 59.90,
        currency: 'BRL',
        billing_cycle: 'monthly',
        features: [
          'Até 15 clientes',
          'Planos nutricionais personalizados',
          'Banco de alimentos completo',
          'Cálculo automático de macros',
          'Suporte por email'
        ],
        max_clients: 15,
        target_user_type: 'nutritionist'
      },
      {
        id: 'nutritionist_pro',
        name: 'Nutricionista Profissional',
        price: 99.90,
        currency: 'BRL',
        billing_cycle: 'monthly',
        features: [
          'Até 40 clientes',
          'Planos nutricionais personalizados',
          'Banco de alimentos completo',
          'Cálculo automático de macros',
          'Relatórios nutricionais',
          'Integração com treinos',
          'Suporte prioritário'
        ],
        max_clients: 40,
        target_user_type: 'nutritionist'
      }
    ];

    const { user_type } = req.query;
    let filteredPlans = plans;

    if (user_type) {
      filteredPlans = plans.filter(plan => plan.target_user_type === user_type);
    }

    res.json({
      success: true,
      data: { plans: filteredPlans }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/subscriptions/current:
 *   get:
 *     summary: Get current user's subscription
 *     tags: [Subscriptions]
 *     security:
 *       - bearerAuth: []
 */
router.get('/current', requireRole(['trainer', 'nutritionist']), async (req, res, next) => {
  try {
    const subscription = await new Promise((resolve, reject) => {
      db.get(
        `SELECT * FROM subscriptions 
         WHERE user_id = ? 
         ORDER BY created_at DESC 
         LIMIT 1`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'No subscription found'
      });
    }

    // Check if subscription is expired
    const now = new Date();
    const expiresAt = new Date(subscription.expires_at);
    const isExpired = now > expiresAt;

    if (isExpired && subscription.status === 'active') {
      // Update subscription status
      await new Promise((resolve, reject) => {
        db.run(
          'UPDATE subscriptions SET status = ? WHERE id = ?',
          ['expired', subscription.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
      subscription.status = 'expired';
    }

    res.json({
      success: true,
      data: {
        subscription: {
          ...subscription,
          days_until_expiry: Math.max(0, Math.ceil((expiresAt - now) / (1000 * 60 * 60 * 24))),
          is_expired: isExpired
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/subscriptions/subscribe:
 *   post:
 *     summary: Create new subscription
 *     tags: [Subscriptions]
 *     security:
 *       - bearerAuth: []
 */
router.post('/subscribe', requireRole(['trainer', 'nutritionist']), [
  body('plan_id').isIn(['trainer_basic', 'trainer_pro', 'trainer_enterprise', 'nutritionist_basic', 'nutritionist_pro']),
  body('billing_cycle').isIn(['monthly', 'yearly']),
  body('payment_method').optional().trim()
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const { plan_id, billing_cycle, payment_method } = req.body;

    // Get plan details (this would typically come from a database or config)
    const plans = {
      trainer_basic: { name: 'Treinador Básico', price: 49.90, max_athletes: 10 },
      trainer_pro: { name: 'Treinador Profissional', price: 89.90, max_athletes: 25 },
      trainer_enterprise: { name: 'Treinador Empresarial', price: 149.90, max_athletes: -1 },
      nutritionist_basic: { name: 'Nutricionista Básico', price: 59.90, max_clients: 15 },
      nutritionist_pro: { name: 'Nutricionista Profissional', price: 99.90, max_clients: 40 }
    };

    const plan = plans[plan_id];
    if (!plan) {
      return res.status(400).json({
        success: false,
        message: 'Invalid plan ID'
      });
    }

    // Calculate price (yearly gets 20% discount)
    const basePrice = plan.price;
    const finalPrice = billing_cycle === 'yearly' ? basePrice * 12 * 0.8 : basePrice;

    // Calculate expiry date
    const now = new Date();
    const expiresAt = new Date(now);
    if (billing_cycle === 'monthly') {
      expiresAt.setMonth(expiresAt.getMonth() + 1);
    } else {
      expiresAt.setFullYear(expiresAt.getFullYear() + 1);
    }

    // Cancel any existing active subscription
    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE subscriptions 
         SET status = 'cancelled' 
         WHERE user_id = ? AND status IN ('active', 'paused')`,
        [req.user.id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Create new subscription
    const subscriptionId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO subscriptions 
         (user_id, plan_name, plan_price, billing_cycle, expires_at, payment_method)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [req.user.id, plan.name, finalPrice, billing_cycle, expiresAt.toISOString(), payment_method || 'pending'],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Update trainer/nutritionist limits
    if (req.user.user_type === 'trainer') {
      await new Promise((resolve, reject) => {
        db.run(
          `UPDATE trainers 
           SET subscription_plan = ?, max_athletes = ?, subscription_status = 'active', subscription_expires_at = ?
           WHERE user_id = ?`,
          [plan_id, plan.max_athletes, expiresAt.toISOString(), req.user.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } else if (req.user.user_type === 'nutritionist') {
      await new Promise((resolve, reject) => {
        db.run(
          `UPDATE nutritionists 
           SET subscription_plan = ?, max_clients = ?, subscription_status = 'active', subscription_expires_at = ?
           WHERE user_id = ?`,
          [plan_id, plan.max_clients, expiresAt.toISOString(), req.user.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    // TODO: Integrate with actual payment processor (Stripe, PayPal, etc.)
    // For now, we'll simulate successful payment
    
    res.status(201).json({
      success: true,
      message: 'Subscription created successfully',
      data: {
        subscription_id: subscriptionId,
        plan_name: plan.name,
        price: finalPrice,
        billing_cycle,
        expires_at: expiresAt.toISOString(),
        // In real implementation, include payment URL or confirmation
        payment_url: `/payment/confirm/${subscriptionId}`
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/subscriptions/cancel:
 *   put:
 *     summary: Cancel current subscription
 *     tags: [Subscriptions]
 *     security:
 *       - bearerAuth: []
 */
router.put('/cancel', requireRole(['trainer', 'nutritionist']), async (req, res, next) => {
  try {
    // Get current subscription
    const subscription = await new Promise((resolve, reject) => {
      db.get(
        `SELECT * FROM subscriptions 
         WHERE user_id = ? AND status = 'active'
         ORDER BY created_at DESC 
         LIMIT 1`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!subscription) {
      return res.status(404).json({
        success: false,
        message: 'No active subscription found'
      });
    }

    // Update subscription status
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE subscriptions SET status = ?, auto_renew = 0 WHERE id = ?',
        ['cancelled', subscription.id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Update trainer/nutritionist status
    if (req.user.user_type === 'trainer') {
      await new Promise((resolve, reject) => {
        db.run(
          'UPDATE trainers SET subscription_status = ? WHERE user_id = ?',
          ['cancelled', req.user.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } else if (req.user.user_type === 'nutritionist') {
      await new Promise((resolve, reject) => {
        db.run(
          'UPDATE nutritionists SET subscription_status = ? WHERE user_id = ?',
          ['cancelled', req.user.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    // TODO: Cancel with payment processor
    
    res.json({
      success: true,
      message: 'Subscription cancelled successfully. You can continue using the service until the end of your billing period.'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/subscriptions/history:
 *   get:
 *     summary: Get subscription history
 *     tags: [Subscriptions]
 *     security:
 *       - bearerAuth: []
 */
router.get('/history', requireRole(['trainer', 'nutritionist']), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 })
], async (req, res, next) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    const subscriptions = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM subscriptions 
         WHERE user_id = ?
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`,
        [req.user.id, limit, offset],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    const total = await new Promise((resolve, reject) => {
      db.get(
        'SELECT COUNT(*) as count FROM subscriptions WHERE user_id = ?',
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row.count);
        }
      );
    });

    res.json({
      success: true,
      data: {
        subscriptions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;