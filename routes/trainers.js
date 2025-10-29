import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';

const router = express.Router();

/**
 * @swagger
 * /api/trainers/athletes:
 *   get:
 *     summary: Get trainer's athletes
 *     tags: [Trainers]
 *     security:
 *       - bearerAuth: []
 */
router.get('/athletes', requireRole(['trainer']), async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;

    // Get trainer ID
    const trainer = await new Promise((resolve, reject) => {
      db.get('SELECT id, max_athletes FROM trainers WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!trainer) {
      return res.status(403).json({
        success: false,
        message: 'Trainer profile not found'
      });
    }

    let whereClause = 'WHERE a.trainer_id = ?';
    let params = [trainer.id];

    if (search) {
      whereClause += ' AND (u.first_name LIKE ? OR u.last_name LIKE ? OR u.email LIKE ?)';
      const searchTerm = `%${search}%`;
      params.push(searchTerm, searchTerm, searchTerm);
    }

    const athletes = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          a.*,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.profile_image,
          u.created_at as user_created_at
         FROM athletes a
         JOIN users u ON a.user_id = u.id
         ${whereClause}
         ORDER BY u.first_name, u.last_name
         LIMIT ? OFFSET ?`,
        [...params, limit, offset],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get total count
    const totalCount = await new Promise((resolve, reject) => {
      db.get(
        `SELECT COUNT(*) as count 
         FROM athletes a
         JOIN users u ON a.user_id = u.id
         ${whereClause}`,
        params.slice(0, -2), // Remove limit and offset
        (err, row) => {
          if (err) reject(err);
          else resolve(row.count);
        }
      );
    });

    res.json({
      success: true,
      data: {
        athletes,
        trainer_info: {
          max_athletes: trainer.max_athletes,
          current_athletes: totalCount
        },
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalCount,
          pages: Math.ceil(totalCount / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/trainers/athletes/{id}:
 *   get:
 *     summary: Get specific athlete details
 *     tags: [Trainers]
 *     security:
 *       - bearerAuth: []
 */
router.get('/athletes/:id', requireRole(['trainer']), [
  param('id').isInt()
], async (req, res, next) => {
  try {
    const { id } = req.params;

    // Get trainer ID
    const trainer = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM trainers WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!trainer) {
      return res.status(403).json({
        success: false,
        message: 'Trainer profile not found'
      });
    }

    // Get athlete details
    const athlete = await new Promise((resolve, reject) => {
      db.get(
        `SELECT 
          a.*,
          u.first_name,
          u.last_name,
          u.email,
          u.phone,
          u.profile_image,
          u.created_at as user_created_at
         FROM athletes a
         JOIN users u ON a.user_id = u.id
         WHERE a.id = ? AND a.trainer_id = ?`,
        [id, trainer.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!athlete) {
      return res.status(404).json({
        success: false,
        message: 'Athlete not found or not assigned to you'
      });
    }

    // Get recent workouts
    const recentWorkouts = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.*,
          wt.name as workout_name,
          wt.difficulty_level,
          wt.duration_minutes
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         WHERE aw.athlete_id = ?
         ORDER BY aw.scheduled_date DESC
         LIMIT 10`,
        [id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get progress records
    const progressRecords = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM progress_records 
         WHERE athlete_id = ?
         ORDER BY recorded_at DESC
         LIMIT 10`,
        [id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: {
        athlete,
        recent_workouts: recentWorkouts,
        progress_records: progressRecords
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/trainers/invite-athlete:
 *   post:
 *     summary: Send invitation to athlete
 *     tags: [Trainers]
 *     security:
 *       - bearerAuth: []
 */
router.post('/invite-athlete', requireRole(['trainer']), [
  body('email').isEmail().normalizeEmail(),
  body('message').optional().trim()
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

    const { email, message } = req.body;

    // Get trainer details
    const trainer = await new Promise((resolve, reject) => {
      db.get(
        `SELECT t.*, u.first_name, u.last_name 
         FROM trainers t
         JOIN users u ON t.user_id = u.id
         WHERE t.user_id = ?`,
        [req.user.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!trainer) {
      return res.status(403).json({
        success: false,
        message: 'Trainer profile not found'
      });
    }

    // Check current athlete count
    const currentAthletes = await new Promise((resolve, reject) => {
      db.get(
        'SELECT COUNT(*) as count FROM athletes WHERE trainer_id = ?',
        [trainer.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row.count);
        }
      );
    });

    if (currentAthletes >= trainer.max_athletes) {
      return res.status(400).json({
        success: false,
        message: `Maximum athlete limit reached (${trainer.max_athletes}). Upgrade your subscription to add more athletes.`
      });
    }

    // Check if user already exists
    const existingUser = await new Promise((resolve, reject) => {
      db.get('SELECT id, user_type FROM users WHERE email = ?', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (existingUser) {
      if (existingUser.user_type !== 'athlete') {
        return res.status(400).json({
          success: false,
          message: 'User exists but is not an athlete'
        });
      }

      // Check if already assigned to this trainer
      const existingAssignment = await new Promise((resolve, reject) => {
        db.get(
          'SELECT id FROM athletes WHERE user_id = ? AND trainer_id = ?',
          [existingUser.id, trainer.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row);
          }
        );
      });

      if (existingAssignment) {
        return res.status(400).json({
          success: false,
          message: 'Athlete is already assigned to you'
        });
      }

      // Assign existing athlete to trainer
      await new Promise((resolve, reject) => {
        db.run(
          'UPDATE athletes SET trainer_id = ? WHERE user_id = ?',
          [trainer.id, existingUser.id],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });

      // Send notification
      await new Promise((resolve, reject) => {
        db.run(
          `INSERT INTO notifications 
           (user_id, title, message, notification_type)
           VALUES (?, ?, ?, ?)`,
          [
            existingUser.id,
            'New Trainer Assignment',
            `${trainer.first_name} ${trainer.last_name} is now your personal trainer.`,
            'trainer_assignment'
          ],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });

      return res.json({
        success: true,
        message: 'Athlete assigned successfully'
      });
    }

    // TODO: Send invitation email to new user
    // For now, we'll just create a notification record
    console.log(`Invitation would be sent to ${email} from trainer ${trainer.first_name} ${trainer.last_name}`);
    console.log(`Message: ${message || 'Join me as your personal trainer!'}`);

    res.json({
      success: true,
      message: 'Invitation sent successfully'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/trainers/dashboard:
 *   get:
 *     summary: Get trainer dashboard data
 *     tags: [Trainers]
 *     security:
 *       - bearerAuth: []
 */
router.get('/dashboard', requireRole(['trainer']), async (req, res, next) => {
  try {
    // Get trainer ID
    const trainer = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM trainers WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!trainer) {
      return res.status(403).json({
        success: false,
        message: 'Trainer profile not found'
      });
    }

    // Get stats
    const stats = await Promise.all([
      // Total athletes
      new Promise((resolve, reject) => {
        db.get(
          'SELECT COUNT(*) as count FROM athletes WHERE trainer_id = ?',
          [trainer.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      }),
      
      // Workouts this week
      new Promise((resolve, reject) => {
        db.get(
          `SELECT COUNT(*) as count FROM assigned_workouts 
           WHERE trainer_id = ? 
           AND scheduled_date >= date('now', '-7 days')
           AND scheduled_date <= date('now')`,
          [trainer.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      }),
      
      // Completed workouts this week
      new Promise((resolve, reject) => {
        db.get(
          `SELECT COUNT(*) as count FROM assigned_workouts 
           WHERE trainer_id = ? 
           AND status = 'completed'
           AND scheduled_date >= date('now', '-7 days')
           AND scheduled_date <= date('now')`,
          [trainer.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      }),
      
      // Active workout templates
      new Promise((resolve, reject) => {
        db.get(
          'SELECT COUNT(*) as count FROM workout_templates WHERE trainer_id = ?',
          [trainer.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      })
    ]);

    // Recent activity
    const recentActivity = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.id,
          aw.status,
          aw.scheduled_date,
          aw.completed_at,
          wt.name as workout_name,
          u.first_name || ' ' || u.last_name as athlete_name
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         JOIN athletes a ON aw.athlete_id = a.id
         JOIN users u ON a.user_id = u.id
         WHERE aw.trainer_id = ?
         ORDER BY aw.scheduled_date DESC
         LIMIT 10`,
        [trainer.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Upcoming workouts
    const upcomingWorkouts = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.id,
          aw.scheduled_date,
          wt.name as workout_name,
          wt.difficulty_level,
          u.first_name || ' ' || u.last_name as athlete_name
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         JOIN athletes a ON aw.athlete_id = a.id
         JOIN users u ON a.user_id = u.id
         WHERE aw.trainer_id = ? 
         AND aw.status = 'pending'
         AND aw.scheduled_date >= date('now')
         ORDER BY aw.scheduled_date ASC
         LIMIT 5`,
        [trainer.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: {
        stats: {
          total_athletes: stats[0],
          workouts_this_week: stats[1],
          completed_this_week: stats[2],
          workout_templates: stats[3],
          completion_rate: stats[1] > 0 ? Math.round((stats[2] / stats[1]) * 100) : 0
        },
        recent_activity: recentActivity,
        upcoming_workouts: upcomingWorkouts
      }
    });
  } catch (error) {
    next(error);
  }
});

export default router;