import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';

const router = express.Router();

/**
 * @swagger
 * /api/workouts/templates:
 *   post:
 *     summary: Create workout template (Trainers only)
 *     tags: [Workouts]
 *     security:
 *       - bearerAuth: []
 */
router.post('/templates', requireRole(['trainer']), [
  body('name').trim().isLength({ min: 1 }),
  body('description').optional().trim(),
  body('difficulty_level').isIn(['beginner', 'intermediate', 'advanced']),
  body('duration_minutes').isInt({ min: 1, max: 480 }),
  body('category').optional().trim(),
  body('exercises').isArray({ min: 1 }),
  body('exercises.*.exercise_id').isInt(),
  body('exercises.*.sets').optional().isInt({ min: 1 }),
  body('exercises.*.reps').optional().trim(),
  body('exercises.*.weight').optional().trim(),
  body('exercises.*.duration_seconds').optional().isInt({ min: 1 }),
  body('exercises.*.rest_seconds').optional().isInt({ min: 0 }),
  body('exercises.*.notes').optional().trim()
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

    const { name, description, difficulty_level, duration_minutes, category, exercises, is_public = false } = req.body;

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

    // Create workout template
    const templateId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO workout_templates 
         (trainer_id, name, description, difficulty_level, duration_minutes, category, is_public) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [trainer.id, name, description, difficulty_level, duration_minutes, category, is_public ? 1 : 0],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Add exercises to template
    for (let i = 0; i < exercises.length; i++) {
      const exercise = exercises[i];
      await new Promise((resolve, reject) => {
        db.run(
          `INSERT INTO workout_template_exercises 
           (workout_template_id, exercise_id, sets, reps, weight, duration_seconds, rest_seconds, order_index, notes)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            templateId, 
            exercise.exercise_id, 
            exercise.sets, 
            exercise.reps, 
            exercise.weight,
            exercise.duration_seconds,
            exercise.rest_seconds,
            i + 1,
            exercise.notes
          ],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    // Get the created template with exercises
    const template = await getWorkoutTemplateById(templateId);

    res.status(201).json({
      success: true,
      message: 'Workout template created successfully',
      data: template
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/workouts/templates:
 *   get:
 *     summary: Get workout templates
 *     tags: [Workouts]
 *     security:
 *       - bearerAuth: []
 */
router.get('/templates', async (req, res, next) => {
  try {
    const { page = 1, limit = 20, category, difficulty_level, my_templates } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE (wt.is_public = 1';
    let params = [];

    // Allow trainers to see their own templates
    if (req.user.user_type === 'trainer') {
      const trainer = await new Promise((resolve, reject) => {
        db.get('SELECT id FROM trainers WHERE user_id = ?', [req.user.id], (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });

      if (trainer) {
        if (my_templates === 'true') {
          whereClause = 'WHERE wt.trainer_id = ?';
          params.push(trainer.id);
        } else {
          whereClause += ' OR wt.trainer_id = ?';
          params.push(trainer.id);
        }
      }
    }

    whereClause += ')';

    if (category) {
      whereClause += ' AND wt.category = ?';
      params.push(category);
    }

    if (difficulty_level) {
      whereClause += ' AND wt.difficulty_level = ?';
      params.push(difficulty_level);
    }

    const templates = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          wt.*,
          u.first_name || ' ' || u.last_name as trainer_name,
          COUNT(wte.id) as exercise_count
         FROM workout_templates wt
         JOIN trainers t ON wt.trainer_id = t.id
         JOIN users u ON t.user_id = u.id
         LEFT JOIN workout_template_exercises wte ON wt.id = wte.workout_template_id
         ${whereClause}
         GROUP BY wt.id
         ORDER BY wt.created_at DESC
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
        templates,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: templates.length
        }
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/workouts/assign:
 *   post:
 *     summary: Assign workout to athlete (Trainers only)
 *     tags: [Workouts]
 *     security:
 *       - bearerAuth: []
 */
router.post('/assign', requireRole(['trainer']), [
  body('athlete_id').isInt(),
  body('workout_template_id').isInt(),
  body('scheduled_date').isISO8601(),
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

    const { athlete_id, workout_template_id, scheduled_date, notes } = req.body;

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

    // Verify athlete belongs to this trainer
    const athlete = await new Promise((resolve, reject) => {
      db.get(
        'SELECT id FROM athletes WHERE id = ? AND trainer_id = ?',
        [athlete_id, trainer.id],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    if (!athlete) {
      return res.status(403).json({
        success: false,
        message: 'Athlete not found or not assigned to you'
      });
    }

    // Create assignment
    const assignmentId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO assigned_workouts 
         (athlete_id, trainer_id, workout_template_id, assigned_date, scheduled_date, notes)
         VALUES (?, ?, ?, datetime('now'), ?, ?)`,
        [athlete_id, trainer.id, workout_template_id, scheduled_date, notes],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    res.status(201).json({
      success: true,
      message: 'Workout assigned successfully',
      data: { assignment_id: assignmentId }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/workouts/assigned:
 *   get:
 *     summary: Get assigned workouts (for current user)
 *     tags: [Workouts]
 *     security:
 *       - bearerAuth: []
 */
router.get('/assigned', async (req, res, next) => {
  try {
    const { status, date_from, date_to, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    if (req.user.user_type === 'athlete') {
      // Get athlete's workouts
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

      whereClause = 'WHERE aw.athlete_id = ?';
      params.push(athlete.id);
    } else if (req.user.user_type === 'trainer') {
      // Get trainer's assigned workouts
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

      whereClause = 'WHERE aw.trainer_id = ?';
      params.push(trainer.id);
    }

    if (status) {
      whereClause += ' AND aw.status = ?';
      params.push(status);
    }

    if (date_from) {
      whereClause += ' AND aw.scheduled_date >= ?';
      params.push(date_from);
    }

    if (date_to) {
      whereClause += ' AND aw.scheduled_date <= ?';
      params.push(date_to);
    }

    const workouts = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          aw.*,
          wt.name as workout_name,
          wt.description as workout_description,
          wt.difficulty_level,
          wt.duration_minutes,
          wt.category,
          u_athlete.first_name || ' ' || u_athlete.last_name as athlete_name,
          u_trainer.first_name || ' ' || u_trainer.last_name as trainer_name
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         JOIN athletes a ON aw.athlete_id = a.id
         JOIN users u_athlete ON a.user_id = u_athlete.id
         JOIN trainers t ON aw.trainer_id = t.id
         JOIN users u_trainer ON t.user_id = u_trainer.id
         ${whereClause}
         ORDER BY aw.scheduled_date DESC
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
        workouts,
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

// Helper function to get workout template with exercises
async function getWorkoutTemplateById(templateId) {
  const template = await new Promise((resolve, reject) => {
    db.get(
      `SELECT wt.*, u.first_name || ' ' || u.last_name as trainer_name
       FROM workout_templates wt
       JOIN trainers t ON wt.trainer_id = t.id
       JOIN users u ON t.user_id = u.id
       WHERE wt.id = ?`,
      [templateId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (template) {
    const exercises = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          wte.*,
          e.name as exercise_name,
          e.category as exercise_category,
          e.muscle_groups,
          e.equipment,
          e.instructions
         FROM workout_template_exercises wte
         JOIN exercises e ON wte.exercise_id = e.id
         WHERE wte.workout_template_id = ?
         ORDER BY wte.order_index`,
        [templateId],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    template.exercises = exercises;
  }

  return template;
}

export default router;