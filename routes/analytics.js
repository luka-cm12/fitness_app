import express from 'express';
import { query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';
import AnalyticsService from '../services/analyticsService.js';

const router = express.Router();

/**
 * @swagger
 * /api/analytics/dashboard:
 *   get:
 *     summary: Get analytics dashboard data
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 */
router.get('/dashboard', requireRole(['trainer', 'nutritionist']), [
  query('period').optional().isIn(['week', 'month', 'quarter', 'year']),
  query('date_from').optional().isISO8601(),
  query('date_to').optional().isISO8601()
], async (req, res, next) => {
  try {
    const { period = 'month', date_from, date_to } = req.query;
    
    let dateFilter = '';
    let dateParams = [];
    
    if (date_from && date_to) {
      dateFilter = 'AND date(created_at) BETWEEN ? AND ?';
      dateParams = [date_from, date_to];
    } else {
      // Set default date ranges based on period
      const now = new Date();
      let startDate = new Date(now);
      
      switch (period) {
        case 'week':
          startDate.setDate(now.getDate() - 7);
          break;
        case 'month':
          startDate.setMonth(now.getMonth() - 1);
          break;
        case 'quarter':
          startDate.setMonth(now.getMonth() - 3);
          break;
        case 'year':
          startDate.setFullYear(now.getFullYear() - 1);
          break;
      }
      
      dateFilter = 'AND date(created_at) >= ?';
      dateParams = [startDate.toISOString().split('T')[0]];
    }

    let analytics = {};

    if (req.user.user_type === 'trainer') {
      analytics = await getTrainerAnalytics(req.user.id, dateFilter, dateParams);
    } else if (req.user.user_type === 'nutritionist') {
      analytics = await getNutritionistAnalytics(req.user.id, dateFilter, dateParams);
    }

    res.json({
      success: true,
      data: analytics
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/analytics/workouts:
 *   get:
 *     summary: Get workout analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 */
router.get('/workouts', requireRole(['trainer']), [
  query('athlete_id').optional().isInt(),
  query('period').optional().isIn(['week', 'month', 'quarter']),
  query('group_by').optional().isIn(['day', 'week', 'month'])
], async (req, res, next) => {
  try {
    const { athlete_id, period = 'month', group_by = 'week' } = req.query;

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

    let whereClause = 'WHERE aw.trainer_id = ?';
    let params = [trainer.id];

    if (athlete_id) {
      whereClause += ' AND aw.athlete_id = ?';
      params.push(athlete_id);
    }

    // Add date filter
    const now = new Date();
    let startDate = new Date(now);
    
    switch (period) {
      case 'week':
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(now.getMonth() - 1);
        break;
      case 'quarter':
        startDate.setMonth(now.getMonth() - 3);
        break;
    }

    whereClause += ' AND aw.scheduled_date >= ?';
    params.push(startDate.toISOString().split('T')[0]);

    // Group by clause
    let groupByClause = '';
    let selectClause = '';
    
    switch (group_by) {
      case 'day':
        selectClause = "date(aw.scheduled_date) as period";
        groupByClause = "GROUP BY date(aw.scheduled_date)";
        break;
      case 'week':
        selectClause = "strftime('%Y-W%W', aw.scheduled_date) as period";
        groupByClause = "GROUP BY strftime('%Y-W%W', aw.scheduled_date)";
        break;
      case 'month':
        selectClause = "strftime('%Y-%m', aw.scheduled_date) as period";
        groupByClause = "GROUP BY strftime('%Y-%m', aw.scheduled_date)";
        break;
    }

    const workoutStats = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          ${selectClause},
          COUNT(*) as total_workouts,
          COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) as completed_workouts,
          COUNT(CASE WHEN aw.status = 'pending' THEN 1 END) as pending_workouts,
          COUNT(CASE WHEN aw.status = 'skipped' THEN 1 END) as skipped_workouts,
          ROUND(AVG(CASE WHEN aw.status = 'completed' THEN wt.duration_minutes END), 2) as avg_duration
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         ${whereClause}
         ${groupByClause}
         ORDER BY period`,
        params,
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get most popular exercises
    const popularExercises = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          e.name as exercise_name,
          e.category,
          COUNT(*) as usage_count
         FROM assigned_workouts aw
         JOIN workout_template_exercises wte ON aw.workout_template_id = wte.workout_template_id
         JOIN exercises e ON wte.exercise_id = e.id
         ${whereClause}
         GROUP BY e.id, e.name, e.category
         ORDER BY usage_count DESC
         LIMIT 10`,
        params,
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get completion rates by difficulty
    const completionByDifficulty = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          wt.difficulty_level,
          COUNT(*) as total_assigned,
          COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) as completed,
          ROUND(COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) * 100.0 / COUNT(*), 2) as completion_rate
         FROM assigned_workouts aw
         JOIN workout_templates wt ON aw.workout_template_id = wt.id
         ${whereClause}
         GROUP BY wt.difficulty_level
         ORDER BY completion_rate DESC`,
        params,
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: {
        workout_stats: workoutStats,
        popular_exercises: popularExercises,
        completion_by_difficulty: completionByDifficulty,
        period,
        group_by
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/analytics/athletes:
 *   get:
 *     summary: Get athlete analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 */
router.get('/athletes', requireRole(['trainer']), async (req, res, next) => {
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

    // Get athlete engagement stats
    const athleteStats = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          a.id,
          u.first_name || ' ' || u.last_name as athlete_name,
          COUNT(aw.id) as total_workouts_assigned,
          COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) as workouts_completed,
          COUNT(CASE WHEN aw.status = 'pending' THEN 1 END) as workouts_pending,
          COUNT(CASE WHEN aw.status = 'skipped' THEN 1 END) as workouts_skipped,
          ROUND(COUNT(CASE WHEN aw.status = 'completed' THEN 1 END) * 100.0 / 
                NULLIF(COUNT(aw.id), 0), 2) as completion_rate,
          MAX(aw.completed_at) as last_workout_date,
          COUNT(DISTINCT DATE(aw.scheduled_date)) as active_days
         FROM athletes a
         JOIN users u ON a.user_id = u.id
         LEFT JOIN assigned_workouts aw ON a.id = aw.athlete_id 
           AND aw.scheduled_date >= date('now', '-30 days')
         WHERE a.trainer_id = ?
         GROUP BY a.id, u.first_name, u.last_name
         ORDER BY completion_rate DESC, workouts_completed DESC`,
        [trainer.id],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    // Get progress tracking stats
    const progressStats = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          a.id as athlete_id,
          u.first_name || ' ' || u.last_name as athlete_name,
          pr.record_type,
          COUNT(*) as records_count,
          MIN(pr.recorded_at) as first_record,
          MAX(pr.recorded_at) as latest_record
         FROM athletes a
         JOIN users u ON a.user_id = u.id
         LEFT JOIN progress_records pr ON a.id = pr.athlete_id
         WHERE a.trainer_id = ? AND pr.recorded_at >= date('now', '-90 days')
         GROUP BY a.id, u.first_name, u.last_name, pr.record_type
         ORDER BY athlete_name, pr.record_type`,
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
        athlete_stats: athleteStats,
        progress_tracking: progressStats
      }
    });
  } catch (error) {
    next(error);
  }
});

// Helper functions
async function getTrainerAnalytics(userId, dateFilter, dateParams) {
  // Get trainer ID
  const trainer = await new Promise((resolve, reject) => {
    db.get('SELECT id FROM trainers WHERE user_id = ?', [userId], (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });

  if (!trainer) {
    throw new Error('Trainer profile not found');
  }

  // Total athletes
  const totalAthletes = await new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(*) as count FROM athletes WHERE trainer_id = ?',
      [trainer.id],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      }
    );
  });

  // Workouts in period
  const workoutsInPeriod = await new Promise((resolve, reject) => {
    db.get(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending
       FROM assigned_workouts 
       WHERE trainer_id = ? ${dateFilter}`,
      [trainer.id, ...dateParams],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  // Active athletes (those who completed at least one workout in period)
  const activeAthletes = await new Promise((resolve, reject) => {
    db.get(
      `SELECT COUNT(DISTINCT athlete_id) as count 
       FROM assigned_workouts 
       WHERE trainer_id = ? AND status = 'completed' ${dateFilter}`,
      [trainer.id, ...dateParams],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      }
    );
  });

  return {
    summary: {
      total_athletes: totalAthletes,
      active_athletes: activeAthletes,
      workouts_assigned: workoutsInPeriod.total,
      workouts_completed: workoutsInPeriod.completed,
      completion_rate: workoutsInPeriod.total > 0 ? 
        Math.round((workoutsInPeriod.completed / workoutsInPeriod.total) * 100) : 0
    }
  };
}

async function getNutritionistAnalytics(userId, dateFilter, dateParams) {
  // Get nutritionist ID
  const nutritionist = await new Promise((resolve, reject) => {
    db.get('SELECT id FROM nutritionists WHERE user_id = ?', [userId], (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });

  if (!nutritionist) {
    throw new Error('Nutritionist profile not found');
  }

  // Total clients
  const totalClients = await new Promise((resolve, reject) => {
    db.get(
      'SELECT COUNT(DISTINCT athlete_id) as count FROM nutrition_plans WHERE nutritionist_id = ?',
      [nutritionist.id],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      }
    );
  });

  // Nutrition plans in period
  const plansInPeriod = await new Promise((resolve, reject) => {
    db.get(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active
       FROM nutrition_plans 
       WHERE nutritionist_id = ? ${dateFilter}`,
      [nutritionist.id, ...dateParams],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  // Active clients (those with active nutrition plans)
  const activeClients = await new Promise((resolve, reject) => {
    db.get(
      `SELECT COUNT(DISTINCT athlete_id) as count 
       FROM nutrition_plans 
       WHERE nutritionist_id = ? AND status = 'active'`,
      [nutritionist.id],
      (err, row) => {
        if (err) reject(err);
        else resolve(row.count);
      }
    );
  });

  return {
    summary: {
      total_clients: totalClients,
      active_clients: activeClients,
      nutrition_plans: plansInPeriod.total,
      active_plans: plansInPeriod.active
    }
  };
}

/**
 * @swagger
 * /api/analytics/advanced-dashboard:
 *   get:
 *     summary: Get comprehensive analytics dashboard
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Advanced analytics data
 */
router.get('/advanced-dashboard', requireRole(['trainer', 'admin']), async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.userType;

    const metrics = await AnalyticsService.getDashboardMetrics(userId, userType);
    
    res.json({
      success: true,
      data: metrics,
      generated_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Advanced dashboard error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /api/analytics/revenue-metrics:
 *   get:
 *     summary: Get detailed revenue analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Revenue metrics and projections
 */
router.get('/revenue-metrics', requireRole(['trainer', 'admin']), async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.userType;

    const revenueMetrics = await AnalyticsService.getRevenueMetrics(userId, userType);
    const growthMetrics = await AnalyticsService.getGrowthMetrics(userId, userType);
    
    res.json({
      success: true,
      data: {
        revenue: revenueMetrics,
        growth: growthMetrics,
        insights: {
          mrr_trend: revenueMetrics.growth_rate > 0 ? 'growing' : 'declining',
          subscriber_health: revenueMetrics.active_subscribers > 0 ? 'healthy' : 'critical',
          revenue_per_user: revenueMetrics.active_subscribers > 0 ? 
            (revenueMetrics.mrr / revenueMetrics.active_subscribers).toFixed(2) : 0
        }
      }
    });
  } catch (error) {
    console.error('Revenue metrics error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /api/analytics/engagement-metrics:
 *   get:
 *     summary: Get user engagement analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User engagement metrics
 */
router.get('/engagement-metrics', requireRole(['trainer', 'admin']), async (req, res) => {
  try {
    const userId = req.user.id;
    const userType = req.user.userType;

    const engagementMetrics = await AnalyticsService.getEngagementMetrics(userId, userType);
    
    res.json({
      success: true,
      data: engagementMetrics,
      insights: {
        engagement_level: engagementMetrics.active_users.weekly > 50 ? 'high' : 
                         engagementMetrics.active_users.weekly > 20 ? 'medium' : 'low',
        workout_participation: engagementMetrics.workout_engagement.avg_workouts_per_athlete > 3 ? 'excellent' :
                              engagementMetrics.workout_engagement.avg_workouts_per_athlete > 1 ? 'good' : 'poor'
      }
    });
  } catch (error) {
    console.error('Engagement metrics error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /api/analytics/real-time:
 *   get:
 *     summary: Get real-time analytics
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Real-time metrics
 */
router.get('/real-time', requireRole(['trainer', 'admin']), async (req, res) => {
  try {
    const realTimeMetrics = await AnalyticsService.getRealTimeMetrics();
    
    res.json({
      success: true,
      data: realTimeMetrics
    });
  } catch (error) {
    console.error('Real-time metrics error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * @swagger
 * /api/analytics/charts/{chartType}:
 *   get:
 *     summary: Get specific chart data
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: chartType
 *         required: true
 *         schema:
 *           type: string
 *           enum: [userGrowth, workoutCompletion, revenue, workoutTypes]
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [7d, 30d, 90d, 1y]
 *           default: 30d
 *     responses:
 *       200:
 *         description: Chart data
 */
router.get('/charts/:chartType', requireRole(['trainer', 'admin']), async (req, res) => {
  try {
    const { chartType } = req.params;
    const { period = '30d' } = req.query;
    const userId = req.user.id;
    const userType = req.user.userType;

    const validChartTypes = ['userGrowth', 'workoutCompletion', 'revenue', 'workoutTypes'];
    if (!validChartTypes.includes(chartType)) {
      return res.status(400).json({ error: 'Invalid chart type' });
    }

    const chartData = await AnalyticsService.getChartData(userId, userType);
    
    res.json({
      success: true,
      data: chartData[chartType] || [],
      chart_type: chartType,
      period: period
    });
  } catch (error) {
    console.error('Chart data error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;