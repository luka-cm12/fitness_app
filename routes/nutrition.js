import express from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { db } from '../config/database.js';
import { requireRole } from '../middleware/auth.js';
import multer from 'multer';
import foodAnalysisService from '../services/foodAnalysisService.js';
import aiFoodAnalysisService from '../services/aiFoodAnalysisService.js';

const router = express.Router();

// Configuração do multer para upload de imagens
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Apenas arquivos de imagem são permitidos'), false);
    }
  }
});

/**
 * @swagger
 * /api/nutrition/analyze-food-image:
 *   post:
 *     summary: Analyze food image and calculate nutritional information
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               image:
 *                 type: string
 *                 format: binary
 *                 description: Food image to analyze
 *     responses:
 *       200:
 *         description: Food analysis results
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     food_name:
 *                       type: string
 *                     confidence:
 *                       type: number
 *                     calories:
 *                       type: number
 *                     protein:
 *                       type: number
 *                     carbohydrates:
 *                       type: number
 *                     fat:
 *                       type: number
 *                     fiber:
 *                       type: number
 */
// Rota de teste (sem autenticação)
router.post('/analyze-food-image-test', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Imagem é obrigatória'
      });
    }

    // Analisa a imagem usando o serviço de IA
    const analysis = await aiFoodAnalysisService.analyzeFood(req.file.buffer);
    
    if (!analysis.success) {
      return res.status(400).json(analysis);
    }

    res.json({
      success: true,
      message: 'Análise concluída com sucesso',
      data: analysis.data
    });

  } catch (error) {
    console.error('Erro na análise de imagem:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

router.post('/analyze-food-image', upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Imagem é obrigatória'
      });
    }

    // Analisa a imagem usando o serviço de IA
    const analysis = await aiFoodAnalysisService.analyzeFood(req.file.buffer);
    
    if (!analysis.success) {
      return res.status(400).json(analysis);
    }

    // Salva o histórico de análise no banco de dados
    const historyQuery = `
      INSERT INTO food_analysis_history 
      (user_id, food_name, calories, protein, carbohydrates, fat, fiber, confidence, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
    `;

    db.run(historyQuery, [
      req.user.id,
      analysis.data.food_name,
      analysis.data.calories,
      analysis.data.protein,
      analysis.data.carbohydrates,
      analysis.data.fat,
      analysis.data.fiber,
      analysis.data.confidence
    ], function(err) {
      if (err) {
        console.error('Erro ao salvar histórico:', err);
        // Não falha a requisição por erro no histórico
      }
    });

    res.json({
      success: true,
      message: 'Análise concluída com sucesso',
      data: analysis.data
    });

  } catch (error) {
    console.error('Erro na análise de imagem:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/nutrition/food-search:
 *   get:
 *     summary: Search for food nutritional information
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: q
 *         required: true
 *         schema:
 *           type: string
 *         description: Food name to search
 */
router.get('/food-search', async (req, res, next) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Parâmetro de busca é obrigatório'
      });
    }

    const result = await foodAnalysisService.searchFoodNutrition(q.trim());
    res.json(result);

  } catch (error) {
    console.error('Erro na busca de alimento:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/nutrition/analysis-history:
 *   get:
 *     summary: Get user's food analysis history
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Number of records to return
 */
router.get('/analysis-history', async (req, res, next) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    
    const historyQuery = `
      SELECT id, food_name, calories, protein, carbohydrates, fat, fiber, 
             confidence, created_at
      FROM food_analysis_history 
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT ?
    `;

    db.all(historyQuery, [req.user.id, limit], (err, rows) => {
      if (err) {
        console.error('Erro ao buscar histórico:', err);
        return res.status(500).json({
          success: false,
          message: 'Erro ao buscar histórico'
        });
      }

      res.json({
        success: true,
        data: rows || []
      });
    });

  } catch (error) {
    console.error('Erro ao buscar histórico:', error);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: error.message
    });
  }
});

/**
 * @swagger
 * /api/nutrition/plans:
 *   post:
 *     summary: Create nutrition plan (Nutritionists only)
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 */
router.post('/plans', requireRole(['nutritionist']), [
  body('athlete_id').isInt(),
  body('name').trim().isLength({ min: 1 }),
  body('description').optional().trim(),
  body('total_calories').isInt({ min: 800, max: 5000 }),
  body('protein_grams').isFloat({ min: 0 }),
  body('carbs_grams').isFloat({ min: 0 }),
  body('fat_grams').isFloat({ min: 0 }),
  body('fiber_grams').optional().isFloat({ min: 0 }),
  body('start_date').isISO8601(),
  body('end_date').optional().isISO8601(),
  body('meals').isArray({ min: 1 }),
  body('meals.*.meal_type').isIn(['breakfast', 'lunch', 'dinner', 'snack']),
  body('meals.*.name').trim().isLength({ min: 1 }),
  body('meals.*.foods').isArray({ min: 1 })
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
      athlete_id, name, description, total_calories, protein_grams, 
      carbs_grams, fat_grams, fiber_grams, start_date, end_date, meals 
    } = req.body;

    // Get nutritionist ID
    const nutritionist = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM nutritionists WHERE user_id = ?', [req.user.id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!nutritionist) {
      return res.status(403).json({
        success: false,
        message: 'Nutritionist profile not found'
      });
    }

    // Verify athlete exists and can be assigned to this nutritionist
    const athlete = await new Promise((resolve, reject) => {
      db.get('SELECT id FROM athletes WHERE id = ?', [athlete_id], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    if (!athlete) {
      return res.status(404).json({
        success: false,
        message: 'Athlete not found'
      });
    }

    // Create nutrition plan
    const planId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO nutrition_plans 
         (nutritionist_id, athlete_id, name, description, total_calories, 
          protein_grams, carbs_grams, fat_grams, fiber_grams, start_date, end_date)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          nutritionist.id, athlete_id, name, description, total_calories,
          protein_grams, carbs_grams, fat_grams, fiber_grams, start_date, end_date
        ],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Create meals and add foods
    for (let i = 0; i < meals.length; i++) {
      const meal = meals[i];
      
      const mealId = await new Promise((resolve, reject) => {
        db.run(
          `INSERT INTO meals (nutrition_plan_id, meal_type, name, description, target_calories, order_index)
           VALUES (?, ?, ?, ?, ?, ?)`,
          [planId, meal.meal_type, meal.name, meal.description || null, meal.target_calories || null, i + 1],
          function(err) {
            if (err) reject(err);
            else resolve(this.lastID);
          }
        );
      });

      // Add foods to meal
      for (const food of meal.foods) {
        await new Promise((resolve, reject) => {
          db.run(
            'INSERT INTO meal_foods (meal_id, food_id, quantity, unit) VALUES (?, ?, ?, ?)',
            [mealId, food.food_id, food.quantity, food.unit],
            (err) => {
              if (err) reject(err);
              else resolve();
            }
          );
        });
      }
    }

    // Update athlete's nutritionist
    await new Promise((resolve, reject) => {
      db.run(
        'UPDATE athletes SET nutritionist_id = ? WHERE id = ?',
        [req.user.id, athlete_id],
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });

    const createdPlan = await getNutritionPlanById(planId);

    res.status(201).json({
      success: true,
      message: 'Nutrition plan created successfully',
      data: createdPlan
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/nutrition/foods/search:
 *   get:
 *     summary: Search foods in database
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 */
router.get('/foods/search', [
  query('q').trim().isLength({ min: 2 })
], async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Search query must be at least 2 characters'
      });
    }

    const { q, limit = 20 } = req.query;

    const foods = await new Promise((resolve, reject) => {
      db.all(
        `SELECT * FROM foods 
         WHERE name LIKE ? OR brand LIKE ?
         ORDER BY 
           CASE WHEN is_verified = 1 THEN 1 ELSE 2 END,
           name ASC
         LIMIT ?`,
        [`%${q}%`, `%${q}%`, limit],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });

    res.json({
      success: true,
      data: { foods }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/nutrition/foods:
 *   post:
 *     summary: Add new food to database
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 */
router.post('/foods', [
  body('name').trim().isLength({ min: 1 }),
  body('serving_size').trim().isLength({ min: 1 }),
  body('serving_unit').trim().isLength({ min: 1 }),
  body('calories_per_serving').isFloat({ min: 0 }),
  body('protein_per_serving').isFloat({ min: 0 }),
  body('carbs_per_serving').isFloat({ min: 0 }),
  body('fat_per_serving').isFloat({ min: 0 }),
  body('fiber_per_serving').optional().isFloat({ min: 0 }),
  body('sugar_per_serving').optional().isFloat({ min: 0 }),
  body('sodium_per_serving').optional().isFloat({ min: 0 }),
  body('brand').optional().trim(),
  body('category').optional().trim(),
  body('barcode').optional().trim()
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
      name, brand, barcode, serving_size, serving_unit,
      calories_per_serving, protein_per_serving, carbs_per_serving,
      fat_per_serving, fiber_per_serving, sugar_per_serving,
      sodium_per_serving, category
    } = req.body;

    const foodId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO foods 
         (name, brand, barcode, serving_size, serving_unit, calories_per_serving,
          protein_per_serving, carbs_per_serving, fat_per_serving, fiber_per_serving,
          sugar_per_serving, sodium_per_serving, category, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          name, brand, barcode, serving_size, serving_unit, calories_per_serving,
          protein_per_serving, carbs_per_serving, fat_per_serving, fiber_per_serving,
          sugar_per_serving, sodium_per_serving, category, req.user.id
        ],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    const food = await new Promise((resolve, reject) => {
      db.get('SELECT * FROM foods WHERE id = ?', [foodId], (err, row) => {
        if (err) reject(err);
        else resolve(row);
      });
    });

    res.status(201).json({
      success: true,
      message: 'Food added successfully',
      data: { food }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @swagger
 * /api/nutrition/plans:
 *   get:
 *     summary: Get nutrition plans
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 */
router.get('/plans', async (req, res, next) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let whereClause = '';
    let params = [];

    if (req.user.user_type === 'athlete') {
      // Get athlete's nutrition plans
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

      whereClause = 'WHERE np.athlete_id = ?';
      params.push(athlete.id);
    } else if (req.user.user_type === 'nutritionist') {
      // Get nutritionist's created plans
      const nutritionist = await new Promise((resolve, reject) => {
        db.get('SELECT id FROM nutritionists WHERE user_id = ?', [req.user.id], (err, row) => {
          if (err) reject(err);
          else resolve(row);
        });
      });

      if (!nutritionist) {
        return res.status(403).json({
          success: false,
          message: 'Nutritionist profile not found'
        });
      }

      whereClause = 'WHERE np.nutritionist_id = ?';
      params.push(nutritionist.id);
    }

    if (status) {
      whereClause += (whereClause ? ' AND' : 'WHERE') + ' np.status = ?';
      params.push(status);
    }

    const plans = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          np.*,
          u_athlete.first_name || ' ' || u_athlete.last_name as athlete_name,
          u_nutritionist.first_name || ' ' || u_nutritionist.last_name as nutritionist_name
         FROM nutrition_plans np
         JOIN athletes a ON np.athlete_id = a.id
         JOIN users u_athlete ON a.user_id = u_athlete.id
         JOIN nutritionists n ON np.nutritionist_id = n.id
         JOIN users u_nutritionist ON n.user_id = u_nutritionist.id
         ${whereClause}
         ORDER BY np.created_at DESC
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
        plans,
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
 * /api/nutrition/log:
 *   post:
 *     summary: Log food intake (Athletes only)
 *     tags: [Nutrition]
 *     security:
 *       - bearerAuth: []
 */
router.post('/log', requireRole(['athlete']), [
  body('food_id').isInt(),
  body('quantity').isFloat({ min: 0.1 }),
  body('unit').trim().isLength({ min: 1 }),
  body('meal_type').isIn(['breakfast', 'lunch', 'dinner', 'snack']),
  body('meal_id').optional().isInt(),
  body('logged_at').optional().isISO8601()
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

    const { food_id, quantity, unit, meal_type, meal_id, logged_at } = req.body;

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

    const logId = await new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO food_logs 
         (athlete_id, meal_id, food_id, quantity, unit, meal_type, logged_at)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          athlete.id, meal_id || null, food_id, quantity, unit, meal_type, 
          logged_at || new Date().toISOString()
        ],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });

    // Get logged entry with food details
    const logEntry = await new Promise((resolve, reject) => {
      db.get(
        `SELECT 
          fl.*,
          f.name as food_name,
          f.calories_per_serving,
          f.protein_per_serving,
          f.carbs_per_serving,
          f.fat_per_serving
         FROM food_logs fl
         JOIN foods f ON fl.food_id = f.id
         WHERE fl.id = ?`,
        [logId],
        (err, row) => {
          if (err) reject(err);
          else resolve(row);
        }
      );
    });

    res.status(201).json({
      success: true,
      message: 'Food logged successfully',
      data: { log_entry: logEntry }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * Calculate nutrition totals for a meal or nutrition plan
 */
router.get('/calculate/:type/:id', async (req, res, next) => {
  try {
    const { type, id } = req.params;

    let foods = [];
    
    if (type === 'meal') {
      foods = await new Promise((resolve, reject) => {
        db.all(
          `SELECT 
            mf.quantity,
            mf.unit,
            f.serving_size,
            f.serving_unit,
            f.calories_per_serving,
            f.protein_per_serving,
            f.carbs_per_serving,
            f.fat_per_serving,
            f.fiber_per_serving
           FROM meal_foods mf
           JOIN foods f ON mf.food_id = f.id
           WHERE mf.meal_id = ?`,
          [id],
          (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
          }
        );
      });
    } else if (type === 'plan') {
      foods = await new Promise((resolve, reject) => {
        db.all(
          `SELECT 
            mf.quantity,
            mf.unit,
            f.serving_size,
            f.serving_unit,
            f.calories_per_serving,
            f.protein_per_serving,
            f.carbs_per_serving,
            f.fat_per_serving,
            f.fiber_per_serving
           FROM nutrition_plans np
           JOIN meals m ON np.id = m.nutrition_plan_id
           JOIN meal_foods mf ON m.id = mf.meal_id
           JOIN foods f ON mf.food_id = f.id
           WHERE np.id = ?`,
          [id],
          (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
          }
        );
      });
    }

    const totals = calculateNutritionTotals(foods);

    res.json({
      success: true,
      data: { totals }
    });
  } catch (error) {
    next(error);
  }
});

// Helper functions
function calculateNutritionTotals(foods) {
  let totals = {
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0
  };

  for (const food of foods) {
    // Convert quantity to serving size ratio
    // This is simplified - in real app you'd need proper unit conversions
    const servingRatio = food.quantity; // Assuming same units for simplicity
    
    totals.calories += (food.calories_per_serving || 0) * servingRatio;
    totals.protein += (food.protein_per_serving || 0) * servingRatio;
    totals.carbs += (food.carbs_per_serving || 0) * servingRatio;
    totals.fat += (food.fat_per_serving || 0) * servingRatio;
    totals.fiber += (food.fiber_per_serving || 0) * servingRatio;
  }

  // Round to 2 decimal places
  Object.keys(totals).forEach(key => {
    totals[key] = Math.round(totals[key] * 100) / 100;
  });

  return totals;
}

async function getNutritionPlanById(planId) {
  const plan = await new Promise((resolve, reject) => {
    db.get(
      `SELECT 
        np.*,
        u_athlete.first_name || ' ' || u_athlete.last_name as athlete_name,
        u_nutritionist.first_name || ' ' || u_nutritionist.last_name as nutritionist_name
       FROM nutrition_plans np
       JOIN athletes a ON np.athlete_id = a.id
       JOIN users u_athlete ON a.user_id = u_athlete.id
       JOIN nutritionists n ON np.nutritionist_id = n.id
       JOIN users u_nutritionist ON n.user_id = u_nutritionist.id
       WHERE np.id = ?`,
      [planId],
      (err, row) => {
        if (err) reject(err);
        else resolve(row);
      }
    );
  });

  if (plan) {
    const meals = await new Promise((resolve, reject) => {
      db.all(
        `SELECT 
          m.*,
          GROUP_CONCAT(
            json_object(
              'food_id', mf.food_id,
              'quantity', mf.quantity,
              'unit', mf.unit,
              'food_name', f.name,
              'calories_per_serving', f.calories_per_serving
            )
          ) as foods
         FROM meals m
         LEFT JOIN meal_foods mf ON m.id = mf.meal_id
         LEFT JOIN foods f ON mf.food_id = f.id
         WHERE m.nutrition_plan_id = ?
         GROUP BY m.id
         ORDER BY m.order_index`,
        [planId],
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows.map(row => ({
            ...row,
            foods: row.foods ? row.foods.split(',').map(f => JSON.parse(f)) : []
          })));
        }
      );
    });

    plan.meals = meals;
  }

  return plan;
}

export default router;