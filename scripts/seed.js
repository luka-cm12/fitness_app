import { db } from '../config/database.js';

// Sample exercises data
const exercises = [
  {
    name: 'Push-ups',
    category: 'Chest',
    muscle_groups: 'Chest, Triceps, Shoulders',
    equipment: 'None',
    instructions: '1. Start in plank position\n2. Lower body until chest nearly touches floor\n3. Push back up to starting position',
    difficulty_level: 'beginner',
    is_public: 1
  },
  {
    name: 'Squats',
    category: 'Legs',
    muscle_groups: 'Quadriceps, Glutes, Hamstrings',
    equipment: 'None',
    instructions: '1. Stand with feet shoulder-width apart\n2. Lower hips back and down\n3. Return to standing position',
    difficulty_level: 'beginner',
    is_public: 1
  },
  {
    name: 'Deadlifts',
    category: 'Back',
    muscle_groups: 'Hamstrings, Glutes, Lower Back, Traps',
    equipment: 'Barbell',
    instructions: '1. Stand with barbell over mid-foot\n2. Grip bar with hands shoulder-width apart\n3. Lift by extending hips and knees',
    difficulty_level: 'intermediate',
    is_public: 1
  },
  {
    name: 'Bench Press',
    category: 'Chest',
    muscle_groups: 'Chest, Triceps, Shoulders',
    equipment: 'Barbell, Bench',
    instructions: '1. Lie on bench with barbell above chest\n2. Lower bar to chest\n3. Press bar back to starting position',
    difficulty_level: 'intermediate',
    is_public: 1
  },
  {
    name: 'Pull-ups',
    category: 'Back',
    muscle_groups: 'Lats, Biceps, Rhomboids',
    equipment: 'Pull-up bar',
    instructions: '1. Hang from bar with overhand grip\n2. Pull body up until chin passes bar\n3. Lower back to starting position',
    difficulty_level: 'intermediate',
    is_public: 1
  },
  {
    name: 'Planks',
    category: 'Core',
    muscle_groups: 'Core, Shoulders',
    equipment: 'None',
    instructions: '1. Start in push-up position\n2. Rest on forearms instead of hands\n3. Hold position keeping body straight',
    difficulty_level: 'beginner',
    is_public: 1
  },
  {
    name: 'Lunges',
    category: 'Legs',
    muscle_groups: 'Quadriceps, Glutes, Hamstrings',
    equipment: 'None',
    instructions: '1. Step forward with one leg\n2. Lower hips until both knees at 90 degrees\n3. Return to starting position',
    difficulty_level: 'beginner',
    is_public: 1
  },
  {
    name: 'Burpees',
    category: 'Cardio',
    muscle_groups: 'Full Body',
    equipment: 'None',
    instructions: '1. Start standing\n2. Drop to squat, jump back to plank\n3. Do push-up, jump feet to squat, jump up',
    difficulty_level: 'advanced',
    is_public: 1
  }
];

// Sample foods data
const foods = [
  {
    name: 'Chicken Breast',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 165,
    protein_per_serving: 31,
    carbs_per_serving: 0,
    fat_per_serving: 3.6,
    fiber_per_serving: 0,
    category: 'Meat',
    is_verified: 1
  },
  {
    name: 'Brown Rice',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 123,
    protein_per_serving: 2.6,
    carbs_per_serving: 23,
    fat_per_serving: 0.9,
    fiber_per_serving: 1.8,
    category: 'Grains',
    is_verified: 1
  },
  {
    name: 'Broccoli',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 34,
    protein_per_serving: 2.8,
    carbs_per_serving: 7,
    fat_per_serving: 0.4,
    fiber_per_serving: 2.6,
    category: 'Vegetables',
    is_verified: 1
  },
  {
    name: 'Salmon',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 208,
    protein_per_serving: 25,
    carbs_per_serving: 0,
    fat_per_serving: 12,
    fiber_per_serving: 0,
    category: 'Fish',
    is_verified: 1
  },
  {
    name: 'Oatmeal',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 389,
    protein_per_serving: 16.9,
    carbs_per_serving: 66,
    fat_per_serving: 6.9,
    fiber_per_serving: 10.6,
    category: 'Grains',
    is_verified: 1
  },
  {
    name: 'Greek Yogurt',
    serving_size: '100',
    serving_unit: 'g',
    calories_per_serving: 59,
    protein_per_serving: 10,
    carbs_per_serving: 3.6,
    fat_per_serving: 0.4,
    fiber_per_serving: 0,
    category: 'Dairy',
    is_verified: 1
  },
  {
    name: 'Banana',
    serving_size: '1',
    serving_unit: 'medium',
    calories_per_serving: 105,
    protein_per_serving: 1.3,
    carbs_per_serving: 27,
    fat_per_serving: 0.4,
    fiber_per_serving: 3.1,
    category: 'Fruits',
    is_verified: 1
  },
  {
    name: 'Almonds',
    serving_size: '28',
    serving_unit: 'g',
    calories_per_serving: 164,
    protein_per_serving: 6,
    carbs_per_serving: 6,
    fat_per_serving: 14,
    fiber_per_serving: 3.5,
    category: 'Nuts',
    is_verified: 1
  }
];

export async function seedDatabase() {
  try {
    console.log('🌱 Seeding database with sample data...');

    // Seed exercises
    console.log('📝 Adding sample exercises...');
    for (const exercise of exercises) {
      await new Promise((resolve, reject) => {
        db.run(
          `INSERT OR IGNORE INTO exercises 
           (name, category, muscle_groups, equipment, instructions, difficulty_level, is_public)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            exercise.name, exercise.category, exercise.muscle_groups,
            exercise.equipment, exercise.instructions, exercise.difficulty_level,
            exercise.is_public
          ],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    // Seed foods
    console.log('🍎 Adding sample foods...');
    for (const food of foods) {
      await new Promise((resolve, reject) => {
        db.run(
          `INSERT OR IGNORE INTO foods 
           (name, serving_size, serving_unit, calories_per_serving, protein_per_serving,
            carbs_per_serving, fat_per_serving, fiber_per_serving, category, is_verified)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [
            food.name, food.serving_size, food.serving_unit, food.calories_per_serving,
            food.protein_per_serving, food.carbs_per_serving, food.fat_per_serving,
            food.fiber_per_serving, food.category, food.is_verified
          ],
          (err) => {
            if (err) reject(err);
            else resolve();
          }
        );
      });
    }

    console.log('✅ Database seeded successfully!');
    console.log(`   - ${exercises.length} exercises added`);
    console.log(`   - ${foods.length} foods added`);

  } catch (error) {
    console.error('❌ Error seeding database:', error);
    throw error;
  }
}

// Run seeding if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  import('../config/database.js').then(async ({ initializeDatabase }) => {
    try {
      await initializeDatabase();
      await seedDatabase();
      process.exit(0);
    } catch (error) {
      console.error('Failed to seed database:', error);
      process.exit(1);
    }
  });
}