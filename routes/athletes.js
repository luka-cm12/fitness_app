import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';

const router = express.Router();

/**
 * @swagger
 * /api/athletes/dashboard:
 *   get:
 *     summary: Get athlete dashboard data
 *     tags: [Athletes]
 *     security:
 *       - bearerAuth: []
 */
router.get('/dashboard', requireRole(['athlete']), async (req, res, next) => {
  try {
    // Get athlete ID
    const athlete = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM athletes WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!athlete) {
      return res.status(403).json({
        success: false,
        message: 'Athlete profile not found'
      });
    }

    // Get today's workouts
    const todaysWorkouts = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.*,
          wt.name as workout_name,
          wt.description,
          wt.difficulty_level,
          wt.duration_minutes,
          wt.category
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         WHERE aw.athlete_id = ? 
         AND date(aw.scheduled_date) = date('now')
         ORDER BY aw.scheduled_date`,
        [athlete.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get this week's stats
    const weekStats = await Promise.all([
      // Workouts scheduled this week
      new Promise((resolve, reject) => {
        db.get(
          `SELECT COUNT(*) as count FROM assigned_workouts 
           WHERE athlete_id = ? 
           AND scheduled_date >= date('now', 'weekday 0', '-6 days')
           AND scheduled_date <= date('now', 'weekday 0')`,
          [athlete.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      }),
      
      // Workouts completed this week
      new Promise((resolve, reject) => {
        db.get(
          `SELECT COUNT(*) as count FROM assigned_workouts 
           WHERE athlete_id = ? 
           AND status = 'completed'
           AND scheduled_date >= date('now', 'weekday 0', '-6 days')
           AND scheduled_date <= date('now', 'weekday 0')`,
          [athlete.id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row.count);
          }
        );
      }),
      
      // Streak (consecutive days with workouts)
      new Promise((resolve, reject) => {
        db.all(
          `SELECT date(scheduled_date) as workout_date
           FROM assigned_workouts
           WHERE athlete_id = ? AND status = 'completed'
           ORDER BY scheduled_date DESC`,
          [athlete.id],
          (err, rows) => {
            if (err) reject(err);
            else {
              let streak = 0;
              const today = new Date();
              today.setHours(0, 0, 0, 0);
              
              for (let i = 0; i < rows.length; i++) {
                const workoutDate = new Date(rows[i].workout_date);
                const daysDiff = Math.floor((today - workoutDate) / (1000 * 60 * 60 * 24));
                
                if (daysDiff === streak) {
                  streak++;
                } else {
                  break;
                }
              }
              resolve(streak);
            }
          }
        );
      })
    ]);

    // Upcoming workouts (next 7 days)
    const upcomingWorkouts = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.*,
          wt.name as workout_name,
          wt.difficulty_level,
          wt.duration_minutes,
          wt.category
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         WHERE aw.athlete_id = ? 
         AND aw.status = 'pending'
         AND aw.scheduled_date > date('now')
         AND aw.scheduled_date <= date('now', '+7 days')
         ORDER BY aw.scheduled_date`,
        [athlete.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Recent progress
    const recentProgress = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM progress_records 
         WHERE athlete_id = ?
         ORDER BY recorded_at DESC
         LIMIT 5`,
        [athlete.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: {
        today: {
          workouts: todaysWorkouts,
          completed_count: todaysWorkouts.filter(w => w.status === 'completed').length,
          total_count: todaysWorkouts.length
        },
        week_stats: {
          scheduled: weekStats[0],
          completed: weekStats[1],
          completion_rate: weekStats[0] > 0 ? Math.round((weekStats[1] / weekStats[0]) * 100) : 0,
          streak: weekStats[2]
        },
        upcoming_workouts: upcomingWorkouts,
        recent_progress: recentProgress
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/athletes/workouts/{id}/complete:
 *   put:
 *     summary: Mark workout as completed
 *     tags: [Athletes]
 *     security:
 *       - bearerAuth: []
 */
router.put('/workouts/:id/complete', requireRole(['athlete']), [
  param('id').isInt(),
  body('exercises').optional().isArray(),
  body('notes').optional().trim(),
  body('difficulty_rating').optional().isInt({ min: 1, max: 10 })
], async (req, res, next) => {
  try {
    const { id } = req.params;
    const { exercises, notes, difficulty_rating } = req.body;

    // Get athlete ID
    const athlete = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM athletes WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!athlete) {
      return res.status(403).json({
        success: false,
        message: 'Athlete profile not found'
      });
    }

    // Verify workout belongs to athlete
    const workout = await new Promise((resolve, reject) => {
      db.get(
        'SELECT * FROM assigned_workouts WHERE id = ? AND athlete_id = ?',
        [id, athlete.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!workout) {
      return res.status(404).json({
        success: false,
        message: 'Workout not found'
      });
    }

    if (workout.status === 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Workout already completed'
      });
    }

    // Mark workout as completed
    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE assigned_workouts 
         SET status = 'completed', completed_at = ?, notes = ?
         WHERE id = ?`,
        [new Date().toISOString(), notes || null, id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    // Log individual exercises if provided
    if (exercises && exercises.length > 0) {
      for (const exercise of exercises) {
        await new Promise((resolve, reject) => {
          db.run(
            `INSERT INTO workout_logs 
             (assigned_workout_id, exercise_id, sets_completed, reps_completed, 
              weight_used, duration_seconds, rest_seconds, difficulty_rating, notes)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              id, exercise.exercise_id, exercise.sets_completed || null,
              exercise.reps_completed || null, exercise.weight_used || null,
              exercise.duration_seconds || null, exercise.rest_seconds || null,
              difficulty_rating || null, exercise.notes || null
            ],
            (err) => {
              if (err) reject(err);
              else resolve();
            }
          );
        });
      }
    }

    // Create notification for trainer
    if (workout.trainer_id) {
      const trainerUser = await new Promise((resolve, reject) => {
        db.get(
          'SELECT user_id FROM trainers WHERE id = ?',
          [workout.trainer_id],
          (err, row) => {
            if (err) reject(err);
            else resolve(row);
          }
        );
      });

      if (trainerUser) {
        await new Promise((resolve, reject) => {
          db.run(
            `INSERT INTO notifications 
             (user_id, title, message, notification_type, related_record_id, related_record_type)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [
              trainerUser.user_id,
              'Workout Completed',
              `${req.user.first_name} ${req.user.last_name} completed their workout`,
              'workout_completion',
              id,
              'assigned_workout'
            ],
            (err) => {
              if (err) reject(err);
              else resolve();
            }
          );
        });
      }
    }

    res.json({
      success: true,
      message: 'Workout marked as completed'
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/athletes/progress:
 *   post:
 *     summary: Log progress record
 *     tags: [Athletes]
 *     security:
 *       - bearerAuth: []
 */
router.post('/progress', requireRole(['athlete']), [
  body('record_type').isIn(['weight', 'body_fat', 'muscle_mass', 'measurements', 'photos']),
  body('value').optional().isFloat(),
  body('unit').optional().trim(),
  body('body_part').optional().trim(),
  body('image_url').optional().isURL(),
  body('notes').optional().trim()
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

    const { record_type, value, unit, body_part, image_url, notes } = req.body;

    // Get athlete ID
    const athlete = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM athletes WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!athlete) {
      return res.status(403).json({
        success: false,
        message: 'Athlete profile not found'
      });
    }

    const recordId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO progress_records 
         (athlete_id, record_type, value, unit, body_part, image_url, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [athlete.id, record_type, value || null, unit || null, body_part || null, image_url || null, notes || null],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    const record = await new Promise((resolve, reject) => {
      db.get('SELECT * FROM progress_records WHERE id = ?', [recordId], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    res.status(201).json({
      success: true,
      message: 'Progress recorded successfully',
      data: { record }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/athletes/progress:
 *   get:
 *     summary: Get athlete's progress records
 *     tags: [Athletes]
 *     security:
 *       - bearerAuth: []
 */
router.get('/progress', requireRole(['athlete']), [
  query('record_type').optional().isIn(['weight', 'body_fat', 'muscle_mass', 'measurements', 'photos']),
  query('from_date').optional().isISO8601(),
  query('to_date').optional().isISO8601(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], async (req, res, next) => {
  try {
    const { record_type, from_date, to_date, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;

    // Get athlete ID
    const athlete = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM athletes WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!athlete) {
      return res.status(403).json({
        success: false,
        message: 'Athlete profile not found'
      });
    }

    let whereClause = 'WHERE athlete_id = ?';
    let params = [athlete.id];

    if (record_type) {
      whereClause += ' AND record_type = ?';
      params.push(record_type);
    }

    if (from_date) {
      whereClause += ' AND recorded_at >= ?';
      params.push(from_date);
    }

    if (to_date) {
      whereClause += ' AND recorded_at <= ?';
      params.push(to_date);
    }

    const records = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM progress_records 
         ${whereClause}
         ORDER BY recorded_at DESC
         LIMIT ? OFFSET ?`,
        [...params, limit, offset],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: {
        records,
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

export default router;