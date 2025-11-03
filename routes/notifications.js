import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { database } from '../config/database.js';

const router = express.Router();

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: Get user notifications
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [workout, nutrition, reminder, approval, system, message, subscription, progress, achievement]
 *       - in: query
 *         name: unread_only
 *         schema:
 *           type: boolean
 */
router.get('/', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('type').optional().isIn(['workout', 'nutrition', 'reminder', 'approval', 'system', 'message', 'subscription', 'progress', 'achievement']),
  query('unread_only').optional().isBoolean()
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

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const type = req.query.type;
    const unreadOnly = req.query.unread_only === 'true';

    // Build WHERE clause
    let whereClause = 'WHERE n.user_id = ? AND n.is_deleted = 0';
    let params = [req.user.id];

    if (type) {
      whereClause += ' AND n.notification_type = ?';
      params.push(type);
    }

    if (unreadOnly) {
      whereClause += ' AND n.is_read = 0';
    }

    // Get notifications with sender info
    const notifications = await new Promise((resolve, reject) => {
      database.all(`
        SELECT 
          n.*,
          u.first_name || ' ' || u.last_name as sender_name,
          u.profile_image as sender_image
        FROM notifications n
        LEFT JOIN users u ON n.sender_id = u.id
        ${whereClause}
        ORDER BY n.created_at DESC
        LIMIT ? OFFSET ?
      `, [...params, limit, offset], (err, rows) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    });

    // Get total count
    const totalCount = await new Promise((resolve, reject) => {
      database.get(`
        SELECT COUNT(*) as count
        FROM notifications n
        ${whereClause}
      `, params, (err, row) => {
        if (err) reject(err);
        else resolve(row?.count || 0);
      });
    });

    // Get unread count
    const unreadCount = await new Promise((resolve, reject) => {
      database.get(`
        SELECT COUNT(*) as count
        FROM notifications n
        WHERE n.user_id = ? AND n.is_read = 0 AND n.is_deleted = 0
      `, [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row?.count || 0);
      });
    });

    res.json({
      success: true,
      data: {
        notifications: notifications.map(n => ({
          ...n,
          action_data: n.action_data ? JSON.parse(n.action_data) : null
        })),
        pagination: {
          page,
          limit,
          total: totalCount,
          pages: Math.ceil(totalCount / limit)
        },
        unread_count: unreadCount
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/notifications:
 *   post:
 *     summary: Create a notification
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.post('/', [
  body('user_id').isInt(),
  body('title').trim().isLength({ min: 1, max: 200 }),
  body('message').trim().isLength({ min: 1, max: 1000 }),
  body('notification_type').isIn(['workout', 'nutrition', 'reminder', 'approval', 'system', 'message', 'subscription', 'progress', 'achievement']),
  body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']),
  body('action_url').optional().isURL(),
  body('action_data').optional(),
  body('image_url').optional().isURL(),
  body('expires_at').optional().isISO8601()
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

    const {
      user_id,
      title,
      message,
      notification_type,
      priority = 'medium',
      action_url,
      action_data,
      image_url,
      expires_at
    } = req.body;

    // Verify user exists
    const targetUser = await new Promise((resolve, reject) => {
      database.get('SELECT id FROM users WHERE id = ?', [user_id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'Target user not found'
      });
    }

    // Create notification
    const notificationId = await new Promise((resolve, reject) => {
      database.run(`
        INSERT INTO notifications (
          user_id, title, message, notification_type, priority,
          action_url, action_data, image_url, expires_at, sender_id
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        user_id, title, message, notification_type, priority,
        action_url, action_data ? JSON.stringify(action_data) : null,
        image_url, expires_at, req.user.id
      ], function(err) {
        if (err) reject(err);
        else resolve(this.lastID);
      });
    });

    // Get created notification
    const notification = await new Promise((resolve, reject) => {
      database.get(`
        SELECT 
          n.*,
          u.first_name || ' ' || u.last_name as sender_name,
          u.profile_image as sender_image
        FROM notifications n
        LEFT JOIN users u ON n.sender_id = u.id
        WHERE n.id = ?
      `, [notificationId], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    res.status(201).json({
      success: true,
      message: 'Notification created successfully',
      data: {
        ...notification,
        action_data: notification.action_data ? JSON.parse(notification.action_data) : null
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/notifications/{id}/read:
 *   patch:
 *     summary: Mark notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/:id/read', [
  param('id').isInt()
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

    const notificationId = req.params.id;

    // Check if notification exists and belongs to user
    const notification = await new Promise((resolve, reject) => {
      database.get(`
        SELECT * FROM notifications 
        WHERE id = ? AND user_id = ? AND is_deleted = 0
      `, [notificationId, req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    // Mark as read
    await new Promise((resolve, reject) => {
      database.run(`
        UPDATE notifications 
        SET is_read = 1, read_at = datetime('now')
        WHERE id = ?
      `, [notificationId], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/notifications/read-all:
 *   patch:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/read-all', async (req, res, next) => {
  try {
    await new Promise((resolve, reject) => {
      database.run(`
        UPDATE notifications 
        SET is_read = 1, read_at = datetime('now')
        WHERE user_id = ? AND is_read = 0 AND is_deleted = 0
      `, [req.user.id], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/notifications/{id}:
 *   delete:
 *     summary: Delete notification (soft delete)
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/:id', [
  param('id').isInt()
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

    const notificationId = req.params.id;

    // Check if notification exists and belongs to user
    const notification = await new Promise((resolve, reject) => {
      database.get(`
        SELECT * FROM notifications 
        WHERE id = ? AND user_id = ? AND is_deleted = 0
      `, [notificationId, req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    // Soft delete
    await new Promise((resolve, reject) => {
      database.run(`
        UPDATE notifications 
        SET is_deleted = 1
        WHERE id = ?
      `, [notificationId], (err) => {
        if (err) reject(err);
        else resolve();
      });
    });

    res.json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/notifications/stats:
 *   get:
 *     summary: Get notification statistics
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 */
router.get('/stats', async (req, res, next) => {
  try {
    // Get notification counts by type
    const typeStats = await new Promise((resolve, reject) => {
      database.all(`
        SELECT 
          notification_type,
          COUNT(*) as total,
          SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread
        FROM notifications
        WHERE user_id = ? AND is_deleted = 0
        GROUP BY notification_type
      `, [req.user.id], (err, rows) => {
        if (err) reject(err);
        else resolve(rows || []);
      });
    });

    // Get overall stats
    const overallStats = await new Promise((resolve, reject) => {
      database.get(`
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN is_read = 0 THEN 1 ELSE 0 END) as unread,
          SUM(CASE WHEN priority = 'high' OR priority = 'urgent' THEN 1 ELSE 0 END) as high_priority
        FROM notifications
        WHERE user_id = ? AND is_deleted = 0
      `, [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row || { total: 0, unread: 0, high_priority: 0 });
      });
    });

    res.json({
      success: true,
      data: {
        overall: overallStats,
        by_type: typeStats
      }
    });
  } catch (error) {
    next(error);
  }
});

// Helper function to create notification
export const createNotification = async (notificationData) => {
  const {
    user_id,
    title,
    message,
    notification_type,
    priority = 'medium',
    action_url,
    action_data,
    image_url,
    expires_at,
    sender_id
  } = notificationData;

  return new Promise((resolve, reject) => {
    database.run(`
      INSERT INTO notifications (
        user_id, title, message, notification_type, priority,
        action_url, action_data, image_url, expires_at, sender_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      user_id, title, message, notification_type, priority,
      action_url, action_data ? JSON.stringify(action_data) : null,
      image_url, expires_at, sender_id
    ], function(err) {
      if (err) reject(err);
      else resolve(this.lastID);
    });
  });
};

export default router;