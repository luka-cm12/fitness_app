import sqlite3 from 'sqlite3';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const DB_PATH = join(__dirname, '..', 'database', 'fitness_saas.db');

// Ensure database directory exists
const dbDir = join(__dirname, '..', 'database');
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

export const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('Error opening database:', err.message);
  } else {
    console.log('Connected to SQLite database');
  }
});

export const initializeDatabase = () => {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // Enable foreign keys
      db.run("PRAGMA foreign_keys = ON");

      // Users table (base table for all user types)
      db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        user_type TEXT CHECK(user_type IN ('trainer', 'athlete', 'nutritionist')) NOT NULL,
        phone TEXT,
        profile_image TEXT,
        is_active BOOLEAN DEFAULT 1,
        email_verified BOOLEAN DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);

      // Trainers table
      db.run(`CREATE TABLE IF NOT EXISTS trainers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        certification TEXT,
        specialization TEXT,
        years_experience INTEGER,
        bio TEXT,
        subscription_plan TEXT DEFAULT 'basic',
        subscription_status TEXT DEFAULT 'active',
        subscription_expires_at DATETIME,
        max_athletes INTEGER DEFAULT 10,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Athletes table
      db.run(`CREATE TABLE IF NOT EXISTS athletes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        trainer_id INTEGER,
        nutritionist_id INTEGER,
        birth_date DATE,
        gender TEXT CHECK(gender IN ('M', 'F', 'Other')),
        height REAL,
        weight REAL,
        fitness_level TEXT CHECK(fitness_level IN ('beginner', 'intermediate', 'advanced')),
        goals TEXT,
        medical_conditions TEXT,
        emergency_contact_name TEXT,
        emergency_contact_phone TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (trainer_id) REFERENCES trainers (id) ON DELETE SET NULL,
        FOREIGN KEY (nutritionist_id) REFERENCES users (id) ON DELETE SET NULL
      )`);

      // Nutritionists table
      db.run(`CREATE TABLE IF NOT EXISTS nutritionists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        certification TEXT,
        specialization TEXT,
        years_experience INTEGER,
        bio TEXT,
        subscription_plan TEXT DEFAULT 'basic',
        subscription_status TEXT DEFAULT 'active',
        subscription_expires_at DATETIME,
        max_clients INTEGER DEFAULT 15,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Workout templates
      db.run(`CREATE TABLE IF NOT EXISTS workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trainer_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        difficulty_level TEXT CHECK(difficulty_level IN ('beginner', 'intermediate', 'advanced')),
        duration_minutes INTEGER,
        category TEXT,
        is_public BOOLEAN DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (trainer_id) REFERENCES trainers (id) ON DELETE CASCADE
      )`);

      // Exercise library
      db.run(`CREATE TABLE IF NOT EXISTS exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        muscle_groups TEXT,
        equipment TEXT,
        instructions TEXT,
        video_url TEXT,
        image_url TEXT,
        difficulty_level TEXT CHECK(difficulty_level IN ('beginner', 'intermediate', 'advanced')),
        created_by INTEGER,
        is_public BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES trainers (id)
      )`);

      // Workout template exercises (junction table)
      db.run(`CREATE TABLE IF NOT EXISTS workout_template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_template_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sets INTEGER,
        reps TEXT,
        weight TEXT,
        duration_seconds INTEGER,
        rest_seconds INTEGER,
        order_index INTEGER,
        notes TEXT,
        FOREIGN KEY (workout_template_id) REFERENCES workout_templates (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )`);

      // Assigned workouts
      db.run(`CREATE TABLE IF NOT EXISTS assigned_workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        athlete_id INTEGER NOT NULL,
        trainer_id INTEGER NOT NULL,
        workout_template_id INTEGER NOT NULL,
        assigned_date DATE NOT NULL,
        scheduled_date DATE,
        status TEXT CHECK(status IN ('pending', 'in_progress', 'completed', 'skipped')) DEFAULT 'pending',
        completed_at DATETIME,
        notes TEXT,
        trainer_feedback TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (athlete_id) REFERENCES athletes (id) ON DELETE CASCADE,
        FOREIGN KEY (trainer_id) REFERENCES trainers (id) ON DELETE CASCADE,
        FOREIGN KEY (workout_template_id) REFERENCES workout_templates (id) ON DELETE CASCADE
      )`);

      // Workout logs (detailed tracking)
      db.run(`CREATE TABLE IF NOT EXISTS workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assigned_workout_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        sets_completed INTEGER,
        reps_completed TEXT,
        weight_used TEXT,
        duration_seconds INTEGER,
        rest_seconds INTEGER,
        difficulty_rating INTEGER CHECK(difficulty_rating BETWEEN 1 AND 10),
        notes TEXT,
        completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (assigned_workout_id) REFERENCES assigned_workouts (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id)
      )`);

      // Nutrition plans
      db.run(`CREATE TABLE IF NOT EXISTS nutrition_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nutritionist_id INTEGER NOT NULL,
        athlete_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        total_calories INTEGER,
        protein_grams REAL,
        carbs_grams REAL,
        fat_grams REAL,
        fiber_grams REAL,
        start_date DATE,
        end_date DATE,
        status TEXT CHECK(status IN ('active', 'paused', 'completed')) DEFAULT 'active',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (nutritionist_id) REFERENCES nutritionists (id) ON DELETE CASCADE,
        FOREIGN KEY (athlete_id) REFERENCES athletes (id) ON DELETE CASCADE
      )`);

      // Food database
      db.run(`CREATE TABLE IF NOT EXISTS foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        barcode TEXT,
        serving_size TEXT,
        serving_unit TEXT,
        calories_per_serving REAL,
        protein_per_serving REAL,
        carbs_per_serving REAL,
        fat_per_serving REAL,
        fiber_per_serving REAL,
        sugar_per_serving REAL,
        sodium_per_serving REAL,
        category TEXT,
        is_verified BOOLEAN DEFAULT 0,
        created_by INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )`);

      // Meals
      db.run(`CREATE TABLE IF NOT EXISTS meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nutrition_plan_id INTEGER NOT NULL,
        meal_type TEXT CHECK(meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')) NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        target_calories REAL,
        order_index INTEGER,
        FOREIGN KEY (nutrition_plan_id) REFERENCES nutrition_plans (id) ON DELETE CASCADE
      )`);

      // Meal foods (junction table)
      db.run(`CREATE TABLE IF NOT EXISTS meal_foods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_id INTEGER NOT NULL,
        food_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE CASCADE,
        FOREIGN KEY (food_id) REFERENCES foods (id) ON DELETE CASCADE
      )`);

      // Food logs (what athletes actually ate)
      db.run(`CREATE TABLE IF NOT EXISTS food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        athlete_id INTEGER NOT NULL,
        meal_id INTEGER,
        food_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        meal_type TEXT CHECK(meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
        FOREIGN KEY (athlete_id) REFERENCES athletes (id) ON DELETE CASCADE,
        FOREIGN KEY (meal_id) REFERENCES meals (id) ON DELETE SET NULL,
        FOREIGN KEY (food_id) REFERENCES foods (id)
      )`);

      // Progress tracking
      db.run(`CREATE TABLE IF NOT EXISTS progress_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        athlete_id INTEGER NOT NULL,
        record_type TEXT CHECK(record_type IN ('weight', 'body_fat', 'muscle_mass', 'measurements', 'photos')) NOT NULL,
        value REAL,
        unit TEXT,
        body_part TEXT,
        image_url TEXT,
        notes TEXT,
        recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (athlete_id) REFERENCES athletes (id) ON DELETE CASCADE
      )`);

      // Subscriptions and billing
      db.run(`CREATE TABLE IF NOT EXISTS subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        plan_name TEXT NOT NULL,
        plan_price REAL NOT NULL,
        billing_cycle TEXT CHECK(billing_cycle IN ('monthly', 'yearly')) NOT NULL,
        status TEXT CHECK(status IN ('active', 'paused', 'cancelled', 'expired')) DEFAULT 'active',
        started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        auto_renew BOOLEAN DEFAULT 1,
        payment_method TEXT,
        stripe_subscription_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Messages/Communication
      db.run(`CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        recipient_id INTEGER NOT NULL,
        subject TEXT,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT 0,
        message_type TEXT CHECK(message_type IN ('text', 'workout_feedback', 'nutrition_note', 'system')) DEFAULT 'text',
        related_record_id INTEGER,
        related_record_type TEXT,
        sent_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (recipient_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Notifications
      db.run(`CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        notification_type TEXT CHECK(notification_type IN (
          'workout', 'nutrition', 'reminder', 'approval', 'system', 
          'message', 'subscription', 'progress', 'achievement'
        )) NOT NULL,
        priority TEXT CHECK(priority IN ('low', 'medium', 'high', 'urgent')) DEFAULT 'medium',
        is_read BOOLEAN DEFAULT 0,
        is_deleted BOOLEAN DEFAULT 0,
        action_url TEXT,
        action_data TEXT, -- JSON data for actions
        image_url TEXT,
        expires_at DATETIME,
        sender_id INTEGER, -- who sent the notification (if applicable)
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        read_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE SET NULL
      )`);

      // Food analysis history (for AI image analysis)
      db.run(`CREATE TABLE IF NOT EXISTS food_analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        food_name TEXT NOT NULL,
        confidence REAL,
        calories REAL,
        protein REAL,
        carbohydrates REAL,
        fat REAL,
        fiber REAL,
        serving_size TEXT,
        ingredients TEXT,
        tips TEXT,
        image_path TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Password reset tokens
      db.run(`CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT UNIQUE NOT NULL,
        expires_at DATETIME NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        used_at DATETIME,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )`);

      // Create indexes for better performance
      db.run("CREATE INDEX IF NOT EXISTS idx_users_email ON users (email)");
      db.run("CREATE INDEX IF NOT EXISTS idx_users_type ON users (user_type)");
      db.run("CREATE INDEX IF NOT EXISTS idx_athletes_trainer ON athletes (trainer_id)");
      db.run("CREATE INDEX IF NOT EXISTS idx_assigned_workouts_athlete ON assigned_workouts (athlete_id)");
      db.run("CREATE INDEX IF NOT EXISTS idx_assigned_workouts_date ON assigned_workouts (scheduled_date)");
      db.run("CREATE INDEX IF NOT EXISTS idx_nutrition_plans_athlete ON nutrition_plans (athlete_id)");
      db.run("CREATE INDEX IF NOT EXISTS idx_food_logs_athlete_date ON food_logs (athlete_id, logged_at)");
      db.run("CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages (recipient_id, is_read)");
      db.run("CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, is_read)");
      db.run("CREATE INDEX IF NOT EXISTS idx_food_analysis_user_date ON food_analysis_history (user_id, created_at)");
      db.run("CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens (token)");
      db.run("CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_expires ON password_reset_tokens (expires_at)");

      resolve();
    });
  });
};

// Export database as default and named export for compatibility
export const database = db;
export default db;