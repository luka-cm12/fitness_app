import { db } from '../config/database.js';

class AnalyticsService {
  // Get comprehensive dashboard metrics
  static async getDashboardMetrics(userId, userType) {
    try {
      const metrics = {
        overview: await this.getOverviewMetrics(userId, userType),
        charts: await this.getChartData(userId, userType),
        revenue: await this.getRevenueMetrics(userId, userType),
        users: await this.getUserMetrics(userId, userType),
        engagement: await this.getEngagementMetrics(userId, userType),
        growth: await this.getGrowthMetrics(userId, userType),
      };
      
      return metrics;
    } catch (error) {
      throw new Error(`Failed to get dashboard metrics: ${error.message}`);
    }
  }

  // Get overview metrics
  static async getOverviewMetrics(userId, userType) {
    const baseQuery = `
      SELECT 
        COUNT(CASE WHEN up.user_type = 'trainer' THEN 1 END) as total_trainers,
        COUNT(CASE WHEN up.user_type = 'athlete' THEN 1 END) as total_athletes,
        COUNT(CASE WHEN up.user_type = 'nutritionist' THEN 1 END) as total_nutritionists,
        COUNT(CASE WHEN DATE(u.created_at) = DATE('now') THEN 1 END) as new_users_today,
        COUNT(CASE WHEN DATE(u.created_at) >= DATE('now', '-7 days') THEN 1 END) as new_users_week,
        COUNT(CASE WHEN DATE(u.created_at) >= DATE('now', '-30 days') THEN 1 END) as new_users_month
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
    `;

    const workoutQuery = `
      SELECT 
        COUNT(*) as total_workouts,
        COUNT(CASE WHEN DATE(created_at) = DATE('now') THEN 1 END) as workouts_today,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_workouts,
        AVG(CASE WHEN status = 'completed' AND duration > 0 THEN duration END) as avg_workout_duration
      FROM workouts
      ${userType === 'trainer' ? 'WHERE trainer_id = ?' : ''}
    `;

    const subscriptionQuery = `
      SELECT 
        COUNT(*) as active_subscriptions,
        SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END) as monthly_revenue,
        COUNT(CASE WHEN status = 'canceled' THEN 1 END) as canceled_subscriptions,
        AVG(amount) as avg_subscription_value
      FROM subscriptions 
      WHERE status IN ('active', 'trial', 'past_due')
      ${userType === 'trainer' ? 'AND user_id = ?' : ''}
    `;

    const params = userType === 'trainer' ? [userId, userId] : [];
    
    const [overview] = await db.all(baseQuery);
    const [workouts] = await db.all(workoutQuery, userType === 'trainer' ? [userId] : []);
    const [subscriptions] = await db.all(subscriptionQuery, userType === 'trainer' ? [userId] : []);

    return {
      users: {
        total: overview.total_trainers + overview.total_athletes + overview.total_nutritionists,
        trainers: overview.total_trainers,
        athletes: overview.total_athletes,
        nutritionists: overview.total_nutritionists,
        new_today: overview.new_users_today,
        new_week: overview.new_users_week,
        new_month: overview.new_users_month,
      },
      workouts: {
        total: workouts.total_workouts || 0,
        today: workouts.workouts_today || 0,
        completed: workouts.completed_workouts || 0,
        completion_rate: workouts.total_workouts > 0 ? 
          ((workouts.completed_workouts / workouts.total_workouts) * 100).toFixed(1) : 0,
        avg_duration: Math.round(workouts.avg_workout_duration || 0),
      },
      revenue: {
        active_subscriptions: subscriptions.active_subscriptions || 0,
        monthly_revenue: subscriptions.monthly_revenue || 0,
        canceled_subscriptions: subscriptions.canceled_subscriptions || 0,
        avg_subscription_value: subscriptions.avg_subscription_value || 0,
        churn_rate: subscriptions.active_subscriptions > 0 ? 
          ((subscriptions.canceled_subscriptions / subscriptions.active_subscriptions) * 100).toFixed(1) : 0,
      }
    };
  }

  // Get chart data for various metrics
  static async getChartData(userId, userType) {
    // Users growth over time (last 30 days)
    const userGrowthQuery = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as count,
        up.user_type
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE DATE(u.created_at) >= DATE('now', '-30 days')
      GROUP BY DATE(created_at), up.user_type
      ORDER BY date
    `;

    // Workout completion over time
    const workoutCompletionQuery = `
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed
      FROM workouts
      WHERE DATE(created_at) >= DATE('now', '-30 days')
      ${userType === 'trainer' ? 'AND trainer_id = ?' : ''}
      GROUP BY DATE(created_at)
      ORDER BY date
    `;

    // Revenue over time (monthly)
    const revenueQuery = `
      SELECT 
        strftime('%Y-%m', created_at) as month,
        SUM(amount) as revenue,
        COUNT(*) as subscriptions
      FROM subscriptions
      WHERE created_at >= DATE('now', '-12 months')
      ${userType === 'trainer' ? 'AND user_id = ?' : ''}
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month
    `;

    // Popular workout types
    const workoutTypesQuery = `
      SELECT 
        type,
        COUNT(*) as count
      FROM workouts
      WHERE created_at >= DATE('now', '-30 days')
      ${userType === 'trainer' ? 'AND trainer_id = ?' : ''}
      GROUP BY type
      ORDER BY count DESC
      LIMIT 10
    `;

    const params = userType === 'trainer' ? [userId] : [];
    
    const userGrowth = await db.all(userGrowthQuery);
    const workoutCompletion = await db.all(workoutCompletionQuery, params);
    const revenue = await db.all(revenueQuery, params);
    const workoutTypes = await db.all(workoutTypesQuery, params);

    return {
      userGrowth: this.processUserGrowthData(userGrowth),
      workoutCompletion: this.processWorkoutCompletionData(workoutCompletion),
      revenue: this.processRevenueData(revenue),
      workoutTypes: workoutTypes,
    };
  }

  // Get revenue-specific metrics
  static async getRevenueMetrics(userId, userType) {
    const revenueQuery = `
      SELECT 
        SUM(CASE WHEN strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now') THEN amount ELSE 0 END) as current_month,
        SUM(CASE WHEN strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now', '-1 month') THEN amount ELSE 0 END) as last_month,
        SUM(CASE WHEN strftime('%Y', created_at) = strftime('%Y', 'now') THEN amount ELSE 0 END) as current_year,
        SUM(amount) as total_revenue,
        AVG(amount) as avg_transaction,
        COUNT(*) as total_transactions
      FROM subscriptions
      WHERE status = 'active'
      ${userType === 'trainer' ? 'AND user_id = ?' : ''}
    `;

    const mrr_query = `
      SELECT 
        SUM(amount) as mrr,
        COUNT(*) as active_subscribers
      FROM subscriptions 
      WHERE status = 'active'
      ${userType === 'trainer' ? 'AND user_id = ?' : ''}
    `;

    const params = userType === 'trainer' ? [userId] : [];
    
    const [revenue] = await db.all(revenueQuery, params);
    const [mrr] = await db.all(mrr_query, params);

    const growth_rate = revenue.last_month > 0 ? 
      (((revenue.current_month - revenue.last_month) / revenue.last_month) * 100).toFixed(1) : 0;

    return {
      current_month: revenue.current_month || 0,
      last_month: revenue.last_month || 0,
      current_year: revenue.current_year || 0,
      total_revenue: revenue.total_revenue || 0,
      avg_transaction: revenue.avg_transaction || 0,
      total_transactions: revenue.total_transactions || 0,
      growth_rate: parseFloat(growth_rate),
      mrr: mrr.mrr || 0,
      active_subscribers: mrr.active_subscribers || 0,
    };
  }

  // Get user engagement metrics
  static async getEngagementMetrics(userId, userType) {
    const engagementQuery = `
      SELECT 
        COUNT(DISTINCT pt.user_id) as active_users_30d,
        COUNT(CASE WHEN pt.created_at >= DATE('now', '-7 days') THEN pt.user_id END) as active_users_7d,
        COUNT(CASE WHEN pt.created_at >= DATE('now', '-1 day') THEN pt.user_id END) as active_users_1d,
        AVG(pt.sessions_per_user) as avg_sessions_per_user
      FROM (
        SELECT 
          user_id,
          COUNT(*) as sessions_per_user
        FROM progress_tracking
        WHERE created_at >= DATE('now', '-30 days')
        GROUP BY user_id
      ) pt
    `;

    const workoutEngagementQuery = `
      SELECT 
        COUNT(DISTINCT athlete_id) as athletes_with_workouts,
        AVG(workouts_per_athlete) as avg_workouts_per_athlete,
        MAX(workouts_per_athlete) as max_workouts_per_athlete
      FROM (
        SELECT 
          athlete_id,
          COUNT(*) as workouts_per_athlete
        FROM workouts
        WHERE created_at >= DATE('now', '-30 days')
        ${userType === 'trainer' ? 'AND trainer_id = ?' : ''}
        GROUP BY athlete_id
      )
    `;

    const params = userType === 'trainer' ? [userId] : [];
    
    const [engagement] = await db.all(engagementQuery);
    const [workoutEngagement] = await db.all(workoutEngagementQuery, params);

    return {
      active_users: {
        daily: engagement.active_users_1d || 0,
        weekly: engagement.active_users_7d || 0,
        monthly: engagement.active_users_30d || 0,
      },
      avg_sessions_per_user: Math.round(engagement.avg_sessions_per_user || 0),
      workout_engagement: {
        athletes_with_workouts: workoutEngagement.athletes_with_workouts || 0,
        avg_workouts_per_athlete: Math.round(workoutEngagement.avg_workouts_per_athlete || 0),
        max_workouts_per_athlete: workoutEngagement.max_workouts_per_athlete || 0,
      }
    };
  }

  // Get growth metrics and predictions
  static async getGrowthMetrics(userId, userType) {
    const growthQuery = `
      SELECT 
        strftime('%Y-%m', created_at) as month,
        COUNT(*) as new_users,
        COUNT(CASE WHEN up.user_type = 'trainer' THEN 1 END) as new_trainers,
        COUNT(CASE WHEN up.user_type = 'athlete' THEN 1 END) as new_athletes
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE created_at >= DATE('now', '-12 months')
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month
    `;

    const retentionQuery = `
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN last_login >= DATE('now', '-7 days') THEN 1 END) as active_last_week,
        COUNT(CASE WHEN last_login >= DATE('now', '-30 days') THEN 1 END) as active_last_month
      FROM users
      WHERE created_at <= DATE('now', '-30 days')
    `;

    const growth = await db.all(growthQuery);
    const [retention] = await db.all(retentionQuery);

    // Calculate growth rate
    const currentMonth = growth[growth.length - 1];
    const lastMonth = growth[growth.length - 2];
    const growth_rate = lastMonth ? 
      (((currentMonth?.new_users || 0) - (lastMonth?.new_users || 0)) / (lastMonth?.new_users || 1) * 100).toFixed(1) : 0;

    return {
      monthly_growth: growth,
      growth_rate: parseFloat(growth_rate),
      retention: {
        weekly: retention.total_users > 0 ? 
          ((retention.active_last_week / retention.total_users) * 100).toFixed(1) : 0,
        monthly: retention.total_users > 0 ? 
          ((retention.active_last_month / retention.total_users) * 100).toFixed(1) : 0,
      },
      predictions: await this.generatePredictions(growth),
    };
  }

  // Generate simple predictions based on historical data
  static async generatePredictions(historicalData) {
    if (historicalData.length < 3) return null;

    const recent = historicalData.slice(-3);
    const avgGrowth = recent.reduce((sum, month, index, arr) => {
      if (index === 0) return sum;
      const prevMonth = arr[index - 1];
      const growth = ((month.new_users - prevMonth.new_users) / prevMonth.new_users) * 100;
      return sum + growth;
    }, 0) / (recent.length - 1);

    const lastMonth = recent[recent.length - 1];
    const predictedNext = Math.round(lastMonth.new_users * (1 + avgGrowth / 100));

    return {
      next_month_users: predictedNext,
      growth_trend: avgGrowth > 0 ? 'growing' : avgGrowth < 0 ? 'declining' : 'stable',
      confidence: Math.min(Math.abs(avgGrowth) * 10, 100), // Simple confidence score
    };
  }

  // Helper methods to process chart data
  static processUserGrowthData(data) {
    const processed = {};
    data.forEach(item => {
      if (!processed[item.date]) {
        processed[item.date] = { date: item.date, trainers: 0, athletes: 0, nutritionists: 0 };
      }
      processed[item.date][item.user_type + 's'] = item.count;
    });
    return Object.values(processed);
  }

  static processWorkoutCompletionData(data) {
    return data.map(item => ({
      date: item.date,
      total: item.total,
      completed: item.completed,
      completion_rate: item.total > 0 ? ((item.completed / item.total) * 100).toFixed(1) : 0,
    }));
  }

  static processRevenueData(data) {
    return data.map(item => ({
      month: item.month,
      revenue: item.revenue,
      subscriptions: item.subscriptions,
      arpu: item.subscriptions > 0 ? (item.revenue / item.subscriptions).toFixed(2) : 0,
    }));
  }

  // Get real-time analytics for dashboard
  static async getRealTimeMetrics() {
    const realTimeQuery = `
      SELECT 
        COUNT(CASE WHEN DATE(created_at) = DATE('now') THEN 1 END) as signups_today,
        COUNT(CASE WHEN DATE(created_at) = DATE('now') AND status = 'completed' THEN 1 END) as workouts_completed_today,
        COUNT(CASE WHEN DATE(created_at) = DATE('now') THEN 1 END) as subscriptions_today,
        MAX(created_at) as last_activity
      FROM (
        SELECT created_at, 'user' as type, NULL as status FROM users
        UNION ALL
        SELECT created_at, 'workout' as type, status FROM workouts  
        UNION ALL
        SELECT created_at, 'subscription' as type, NULL as status FROM subscriptions
      )
    `;

    const [metrics] = await db.all(realTimeQuery);
    
    return {
      signups_today: metrics.signups_today || 0,
      workouts_completed_today: metrics.workouts_completed_today || 0,
      subscriptions_today: metrics.subscriptions_today || 0,
      last_activity: metrics.last_activity,
      updated_at: new Date().toISOString(),
    };
  }
}

export default AnalyticsService;