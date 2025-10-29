import EmailService from '../services/emailService.js';
import { db } from '../config/database.js';

// Middleware to send workout notifications
export const sendWorkoutNotification = async (req, res, next) => {
  try {
    // Check if this is a workout creation or assignment
    if (req.method === 'POST' && req.path.includes('/workouts')) {
      const { athlete_id, name, scheduled_date } = req.body;
      
      if (athlete_id) {
        // Get athlete information
        const athlete = await new Promise((resolve, reject) => {
          db.get(`
            SELECT u.email, u.first_name, u.last_name 
            FROM users u
            JOIN athletes a ON u.id = a.user_id
            WHERE a.id = ?
          `, [athlete_id], (err, row) => {
            if (err) reject(err);
            else resolve(row);
          });
        });

        if (athlete) {
          // Send notification email after response is sent
          res.on('finish', async () => {
            try {
              await EmailService.sendWorkoutNotification(
                athlete.email,
                `${athlete.first_name} ${athlete.last_name}`,
                name,
                scheduled_date || new Date()
              );
            } catch (error) {
              console.error('Failed to send workout notification:', error);
            }
          });
        }
      }
    }
    
    next();
  } catch (error) {
    console.error('Workout notification middleware error:', error);
    next(); // Continue with request even if notification fails
  }
};

// Middleware to send subscription notifications
export const sendSubscriptionNotification = async (req, res, next) => {
  try {
    if (req.method === 'POST' && req.path.includes('/subscriptions')) {
      const userId = req.user.id;
      
      // Get user information
      const user = await new Promise((resolve, reject) => {
        db.get('SELECT email, first_name, last_name FROM users WHERE id = ?', [userId], (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });

      if (user) {
        // Send notification after response is sent
        res.on('finish', async () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            try {
              await EmailService.sendSubscriptionNotification(
                user.email,
                `${user.first_name} ${user.last_name}`,
                'active',
                'Plano Trainer - R$ 49,90/mês'
              );
            } catch (error) {
              console.error('Failed to send subscription notification:', error);
            }
          }
        });
      }
    }
    
    next();
  } catch (error) {
    console.error('Subscription notification middleware error:', error);
    next();
  }
};

// Middleware to track user analytics events
export const trackAnalyticsEvent = (eventType) => {
  return async (req, res, next) => {
    try {
      const userId = req.user?.id;
      
      if (userId) {
        // Record analytics event after response is sent
        res.on('finish', async () => {
          try {
            await new Promise((resolve, reject) => {
              db.run(`
                INSERT INTO analytics_events (
                  user_id, event_type, event_data, ip_address, user_agent, created_at
                ) VALUES (?, ?, ?, ?, ?, datetime('now'))
              `, [
                userId,
                eventType,
                JSON.stringify({
                  method: req.method,
                  path: req.path,
                  status_code: res.statusCode,
                  response_time: Date.now() - req.startTime
                }),
                req.ip,
                req.get('User-Agent')
              ], (err) => {
                if (err) reject(err);
                else resolve();
              });
            });
          } catch (error) {
            console.error('Failed to track analytics event:', error);
          }
        });
      }
      
      // Add start time for response time tracking
      req.startTime = Date.now();
      next();
    } catch (error) {
      console.error('Analytics tracking middleware error:', error);
      next();
    }
  };
};

// Middleware to send password reset emails
export const sendPasswordResetEmail = async (email, resetToken) => {
  try {
    const user = await new Promise((resolve, reject) => {
      db.get('SELECT first_name, last_name FROM users WHERE email = ?', [email], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (user) {
      await EmailService.sendPasswordResetEmail(
        email,
        `${user.first_name} ${user.last_name}`,
        resetToken
      );
    }
  } catch (error) {
    console.error('Failed to send password reset email:', error);
    throw error;
  }
};

// Middleware to send bulk notifications (for newsletters, updates, etc.)
export const sendBulkNotifications = async (userIds, subject, htmlContent) => {
  try {
    // Get user emails
    const users = await new Promise((resolve, reject) => {
      const placeholders = userIds.map(() => '?').join(',');
      db.all(`
        SELECT email FROM users WHERE id IN (${placeholders})
      `, userIds, (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });

    const emails = users.map(user => user.email);
    
    if (emails.length > 0) {
      await EmailService.sendBulkEmail(emails, subject, htmlContent);
      return { success: true, sent_to: emails.length };
    }
    
    return { success: false, error: 'No valid emails found' };
  } catch (error) {
    console.error('Failed to send bulk notifications:', error);
    throw error;
  }
};

// Middleware for real-time analytics updates
export const updateRealTimeMetrics = async (req, res, next) => {
  try {
    // Update real-time metrics after request is processed
    res.on('finish', async () => {
      try {
        const eventType = `${req.method}_${req.path.split('/')[2] || 'unknown'}`;
        
        await new Promise((resolve, reject) => {
          db.run(`
            INSERT OR REPLACE INTO real_time_metrics (
              metric_name, metric_value, updated_at
            ) VALUES (?, COALESCE((SELECT metric_value FROM real_time_metrics WHERE metric_name = ?), 0) + 1, datetime('now'))
          `, [eventType, eventType], (err) => {
            if (err) reject(err);
            else resolve();
          });
        });
      } catch (error) {
        console.error('Failed to update real-time metrics:', error);
      }
    });
    
    next();
  } catch (error) {
    console.error('Real-time metrics middleware error:', error);
    next();
  }
};