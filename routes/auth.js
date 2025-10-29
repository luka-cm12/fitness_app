import express from 'express';
import { body, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { generateToken, hashPassword, comparePassword } from '../middleware/auth.js';
import EmailService from '../services/emailService.js';

const router = express.Router();

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *               - first_name
 *               - last_name
 *               - user_type
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 minLength: 8
 *               first_name:
 *                 type: string
 *               last_name:
 *                 type: string
 *               user_type:
 *                 type: string
 *                 enum: [trainer, athlete, nutritionist]
 *               phone:
 *                 type: string
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error
 *       409:
 *         description: Email already exists
 */
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }),
  body('first_name').trim().isLength({ min: 1 }),
  body('last_name').trim().isLength({ min: 1 }),
  body('user_type').isIn(['trainer', 'athlete', 'nutritionist']),
  body('phone').optional().isMobilePhone()
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

    const { email, password, first_name, last_name, user_type, phone } = req.body;

    // Check if user already exists
    const existingUser = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM users WHERE email = ?', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered'
      });
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Insert user
    const userId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO users (email, password_hash, first_name, last_name, user_type, phone) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [email, passwordHash, first_name, last_name, user_type, phone],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Create role-specific record
    if (user_type === 'trainer') {
      await new Promise((resolve, reject) => {
        db.run(
          'INSERT INTO trainers (user_id) VALUES (?)',
          [userId],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } else if (user_type === 'nutritionist') {
      await new Promise((resolve, reject) => {
        db.run(
          'INSERT INTO nutritionists (user_id) VALUES (?)',
          [userId],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    } else if (user_type === 'athlete') {
      await new Promise((resolve, reject) => {
        db.run(
          'INSERT INTO athletes (user_id) VALUES (?)',
          [userId],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    // Get the created user
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id, email, first_name, last_name, user_type, phone, created_at FROM users WHERE id = ?',
        [userId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    // Generate token
    const token = generateToken(user);

    // Send welcome email
    try {
      await EmailService.sendWelcomeEmail(
        user.email,
        `${user.first_name} ${user.last_name}`,
        user.user_type
      );
    } catch (emailError) {
      console.error('Failed to send welcome email:', emailError);
      // Don't fail the registration if email fails
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          user_type: user.user_type,
          phone: user.phone,
          created_at: user.created_at
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Login successful
 *       401:
 *         description: Invalid credentials
 */
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty()
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

    const { email, password } = req.body;

    // Get user
    const user = await new Promise((resolve, reject) => {
      db.get(
        'SELECT * FROM users WHERE email = ? AND is_active = 1',
        [email],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check password
    const isValidPassword = await comparePassword(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate token
    const token = generateToken(user);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          user_type: user.user_type,
          phone: user.phone,
          profile_image: user.profile_image,
          created_at: user.created_at
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Request password reset
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: Password reset email sent
 */
router.post('/forgot-password', [
  body('email').isEmail().normalizeEmail()
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Valid email is required'
      });
    }

    const { email } = req.body;

    // Check if user exists
    const user = await new Promise((resolve, reject) => {
      db.get('SELECT id, email, first_name FROM users WHERE email = ?', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    // Always return success to prevent email enumeration
    res.json({
      success: true,
      message: 'If the email exists in our system, you will receive password reset instructions.'
    });

    // TODO: Implement actual email sending logic here
    if (user) {
      console.log(`Password reset requested for user ${user.id}: ${user.email}`);
      // Generate reset token, save to database, send email
    }
  } catch (error) {
    next(error);
  }
});

export default router;