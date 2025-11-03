import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import multer from 'multer';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = join(__dirname, '..', 'uploads', 'avatars');
    
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const ext = file.originalname.split('.').pop();
    const filename = `${req.user.id}_${Date.now()}.${ext}`;
    cb(null, filename);
  }
});

const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  }
});

const router = express.Router();

/**
 * @swagger
 * /api/users/profile:
 *   get:
 *     summary: Get current user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/profile', async (req, res, next) => {
  try {
    const user = await new Promise((resolve, reject) => {
      db.get(
        `SELECT 
          u.id, u.email, u.first_name, u.last_name, u.user_type, 
          u.phone, u.profile_image, u.created_at
         FROM users u 
         WHERE u.id = ? AND u.is_active = 1`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get role-specific data
    let roleData = {};
    
    if (user.user_type === 'trainer') {
      roleData = await new Promise((resolve, reject) => {
        db.get(
          'SELECT * FROM trainers WHERE user_id = ?',
          [user.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row || {});
          }
        );
      });
    } else if (user.user_type === 'athlete') {
      roleData = await new Promise((resolve, reject) => {
        db.get(
          `SELECT 
            a.*,
            u_trainer.first_name || ' ' || u_trainer.last_name as trainer_name,
            u_nutritionist.first_name || ' ' || u_nutritionist.last_name as nutritionist_name
           FROM athletes a
           LEFT JOIN trainers t ON a.trainer_id = t.id
           LEFT JOIN users u_trainer ON t.user_id = u_trainer.id
           LEFT JOIN users u_nutritionist ON a.nutritionist_id = u_nutritionist.id
           WHERE a.user_id = ?`,
          [user.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row || {});
          }
        );
      });
    } else if (user.user_type === 'nutritionist') {
      roleData = await new Promise((resolve, reject) => {
        db.get(
          'SELECT * FROM nutritionists WHERE user_id = ?',
          [user.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row || {});
          }
        );
      });
    }

    res.json({
      success: true,
      data: {
        ...user,
        ...roleData
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/users/profile:
 *   put:
 *     summary: Update user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.put('/profile', [
  body('first_name').optional().trim().isLength({ min: 1 }),
  body('last_name').optional().trim().isLength({ min: 1 }),
  body('phone').optional().isMobilePhone(),
  body('profile_image').optional().isURL()
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

    const allowedFields = ['first_name', 'last_name', 'phone', 'profile_image'];
    const updates = {};
    
    Object.keys(req.body).forEach(key => {
      if (allowedFields.includes(key) && req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    });

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields to update'
      });
    }

    // Add updated_at timestamp
    updates.updated_at = new Date().toISOString();

    const setClause = Object.keys(updates).map(key => `${key} = ?`).join(', ');
    const values = [...Object.values(updates), req.user.id];

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE users SET ${setClause} WHERE id = ?`,
        values,
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Get updated user
    const updatedUser = await new Promise((resolve, reject) => {
      db.get(
        `SELECT id, email, first_name, last_name, user_type, phone, profile_image, updated_at 
         FROM users WHERE id = ?`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/users/upload-avatar:
 *   post:
 *     summary: Upload user avatar
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.post('/upload-avatar', upload.single('avatar'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Generate URL for the uploaded file
    const imageUrl = `/uploads/avatars/${req.file.filename}`;

    // Update user profile with new image URL
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE users SET profile_image = ?, updated_at = ? WHERE id = ?',
        [imageUrl, new Date().toISOString(), req.user.id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Get updated user
    const updatedUser = await new Promise((resolve, reject) => {
      db.get(
        `SELECT id, email, first_name, last_name, user_type, phone, profile_image, updated_at 
         FROM users WHERE id = ?`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    res.json({
      success: true,
      message: 'Avatar uploaded successfully',
      data: {
        profile_image: imageUrl,
        user: updatedUser
      }
    });
  } catch (error) {
    // Remove uploaded file if database update fails
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    next(error);
  }
});

/**
 * @swagger
 * /api/users/change-password:
 *   put:
 *     summary: Change user password
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.put('/change-password', [
  body('current_password').notEmpty(),
  body('new_password').isLength({ min: 8 }),
  body('confirm_password').custom((value, { req }) => {
    if (value !== req.body.new_password) {
      throw new Error('Password confirmation does not match');
    }
    return true;
  })
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

    const { current_password, new_password } = req.body;

    // Get current password hash
    const user = await new Promise((resolve, reject) => {
      db.get('SELECT password_hash FROM users WHERE id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify current password
    const { comparePassword, hashPassword } = await import('../middleware/auth.js');
    const isValidPassword = await comparePassword(current_password, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const newPasswordHash = await hashPassword(new_password);

    // Update password
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?',
        [newPasswordHash, new Date().toISOString(), req.user.id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/users/notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/notifications', [
  query('is_read').optional().isBoolean(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], async (req, res, next) => {
  try {
    const { is_read, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE user_id = ?';
    let params = [req.user.id];

    if (is_read !== undefined) {
      whereClause += ' AND is_read = ?';
      params.push(is_read === 'true' ? 1 : 0);
    }

    const notifications = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM notifications 
         ${whereClause}
         ORDER BY created_at DESC
         LIMIT ? OFFSET ?`,
        [...params, limit, offset],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    const unreadCount = await new Promise((resolve, reject) => {
      db.get(
        'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = 0',
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
        notifications,
        unread_count: unreadCount,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/users/notifications/{id}/read:
 *   put:
 *     summary: Mark notification as read
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.put('/notifications/:id/read', [
  param('id').isInt()
], async (req, res, next) => {
  try {
    const { id } = req.params;

    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
        [id, req.user.id],
        function(err) {
          if (err) reject(err);
          else if (this.changes === 0) {
            reject(new Error('Notification not found'));
          } else {
            resolve();
          }
        }
      );
    });

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    if (error.message === 'Notification not found') {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }
    next(error);
  }
});

export default router;