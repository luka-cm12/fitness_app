import axios from 'axios';
import FormData from 'form-data';
import sharp from 'sharp';

class FoodAnalysisService {
  constructor() {
    // Usando API gratuita do Spoonacular para análise de alimentos
    // Em produção, considere usar APIs mais robustas como Google Vision ou Clarifai
    this.apiKey = process.env.SPOONACULAR_API_KEY || 'demo_key';
    this.baseUrl = 'https://api.spoonacular.com';
  }

  /**
   * Analisa uma imagem de comida e retorna informações nutricionais
   * @param {Buffer} imageBuffer - Buffer da imagem
   * @returns {Promise<Object>} Informações nutricionais
   */
  async analyzeFood(imageBuffer) {
    try {
      // Redimensiona a imagem para economizar banda e melhorar performance
      const resizedImage = await sharp(imageBuffer)
        .resize(800, 600, { fit: 'inside' })
        .jpeg({ quality: 80 })
        .toBuffer();

      // Para simulação, vou usar análise baseada em padrões comuns
      // Em produção, você integraria com APIs de ML como Google Vision
      const analysis = await this.simulateImageAnalysis(resizedImage);
      
      return {
        success: true,
        data: analysis
      };
    } catch (error) {
      console.error('Erro na análise da imagem:', error);
      return {
        success: false,
        message: 'Erro ao analisar a imagem',
        error: error.message
      };
    }
  }

  /**
   * Simula análise de imagem - substitua por API real de ML
   * @param {Buffer} imageBuffer 
   * @returns {Object} Dados simulados de análise
   */
  async simulateImageAnalysis(imageBuffer) {
    // Simula diferentes tipos de pratos baseado no tamanho da imagem
    const imageSize = imageBuffer.length;
    const random = Math.random();
    
    const plateOptions = [
      {
        food_name: 'Prato Executivo com Arroz, Feijão e Carne',
        confidence: 0.85,
        calories: 650,
        protein: 35,
        carbohydrates: 75,
        fat: 18,
        fiber: 8,
        serving_size: '1 prato (300g)',
        ingredients: [
          { name: 'Arroz branco', calories: 150, protein: 3, carbs: 30, fat: 0.5 },
          { name: 'Feijão preto', calories: 120, protein: 8, carbs: 20, fat: 1 },
          { name: 'Carne bovina grelhada', calories: 250, protein: 20, carbs: 0, fat: 15 },
          { name: 'Salada verde', calories: 30, protein: 2, carbs: 5, fat: 0.2 },
          { name: 'Batata frita', calories: 100, protein: 2, carbs: 20, fat: 3 }
        ]
      },
      {
        food_name: 'Salada Caesar com Frango',
        confidence: 0.78,
        calories: 420,
        protein: 28,
        carbohydrates: 15,
        fat: 30,
        fiber: 4,
        serving_size: '1 porção (250g)',
        ingredients: [
          { name: 'Alface romana', calories: 20, protein: 2, carbs: 4, fat: 0.1 },
          { name: 'Peito de frango grelhado', calories: 200, protein: 22, carbs: 0, fat: 8 },
          { name: 'Molho Caesar', calories: 150, protein: 2, carbs: 5, fat: 18 },
          { name: 'Croutons', calories: 50, protein: 2, carbs: 6, fat: 4 }
        ]
      },
      {
        food_name: 'Hambúrguer com Batata Frita',
        confidence: 0.92,
        calories: 850,
        protein: 32,
        carbohydrates: 68,
        fat: 48,
        fiber: 6,
        serving_size: '1 combo (400g)',
        ingredients: [
          { name: 'Pão de hambúrguer', calories: 180, protein: 6, carbs: 30, fat: 4 },
          { name: 'Hambúrguer de carne', calories: 280, protein: 20, carbs: 2, fat: 22 },
          { name: 'Queijo cheddar', calories: 120, protein: 6, carbs: 1, fat: 10 },
          { name: 'Batata frita', calories: 270, protein: 4, carbs: 35, fat: 12 }
        ]
      },
      {
        food_name: 'Poke Bowl com Salmão',
        confidence: 0.88,
        calories: 520,
        protein: 30,
        carbohydrates: 55,
        fat: 18,
        fiber: 6,
        serving_size: '1 bowl (350g)',
        ingredients: [
          { name: 'Arroz integral', calories: 180, protein: 4, carbs: 35, fat: 2 },
          { name: 'Salmão cru', calories: 200, protein: 22, carbs: 0, fat: 12 },
          { name: 'Abacate', calories: 80, protein: 2, carbs: 4, fat: 7 },
          { name: 'Edamame', calories: 60, protein: 6, carbs: 6, fat: 2.5 }
        ]
      }
    ];

    // Seleciona um prato baseado em fatores aleatórios
    let selectedPlate;
    if (random < 0.25) {
      selectedPlate = plateOptions[0]; // Prato executivo
    } else if (random < 0.5) {
      selectedPlate = plateOptions[1]; // Salada
    } else if (random < 0.75) {
      selectedPlate = plateOptions[2]; // Hambúrguer
    } else {
      selectedPlate = plateOptions[3]; // Poke bowl
    }

    // Adiciona variação baseada no tamanho da imagem (simula porção)
    const sizeVariation = (imageSize % 100000) / 100000; // 0 a 1
    const portionMultiplier = 0.7 + (sizeVariation * 0.6); // 0.7 a 1.3

    return {
      ...selectedPlate,
      calories: Math.round(selectedPlate.calories * portionMultiplier),
      protein: Math.round(selectedPlate.protein * portionMultiplier * 10) / 10,
      carbohydrates: Math.round(selectedPlate.carbohydrates * portionMultiplier * 10) / 10,
      fat: Math.round(selectedPlate.fat * portionMultiplier * 10) / 10,
      fiber: Math.round(selectedPlate.fiber * portionMultiplier * 10) / 10,
      portion_multiplier: Math.round(portionMultiplier * 100) / 100,
      analysis_timestamp: new Date().toISOString(),
      tips: this.getNutritionTips(selectedPlate)
    };
  }

  /**
   * Retorna dicas nutricionais baseadas no prato analisado
   * @param {Object} plate 
   * @returns {Array<string>} Array de dicas
   */
  getNutritionTips(plate) {
    const tips = [];
    
    if (plate.calories > 700) {
      tips.push('Este prato é calórico. Considere reduzir a porção ou aumentar a atividade física.');
    }
    
    if (plate.protein < 20) {
      tips.push('Considere adicionar mais proteína à sua refeição para melhor saciedade.');
    }
    
    if (plate.fiber < 5) {
      tips.push('Adicione mais vegetais ou grãos integrais para aumentar o teor de fibras.');
    }
    
    if (plate.fat > 30) {
      tips.push('Este prato tem bastante gordura. Prefira métodos de cocção mais saudáveis.');
    }
    
    if (plate.carbohydrates > 60) {
      tips.push('Alto teor de carboidratos. Considere equilibrar com mais proteínas e vegetais.');
    }

    if (tips.length === 0) {
      tips.push('Este prato parece bem equilibrado nutricionalmente!');
    }

    return tips;
  }

  /**
   * Busca informações nutricionais de um alimento específico
   * @param {string} foodName 
   * @returns {Promise<Object>}
   */
  async searchFoodNutrition(foodName) {
    try {
      // Em produção, use a API do Spoonacular ou similar
      const response = await axios.get(`${this.baseUrl}/food/ingredients/search`, {
        params: {
          apiKey: this.apiKey,
          query: foodName,
          number: 1
        }
      });

      if (response.data.results && response.data.results.length > 0) {
        const food = response.data.results[0];
        
        // Busca informações nutricionais detalhadas
        const nutritionResponse = await axios.get(
          `${this.baseUrl}/food/ingredients/${food.id}/information`,
          {
            params: {
              apiKey: this.apiKey,
              amount: 100,
              unit: 'grams'
            }
          }
        );

        return {
          success: true,
          data: nutritionResponse.data
        };
      }

      return {
        success: false,
        message: 'Alimento não encontrado'
      };
    } catch (error) {
      console.error('Erro ao buscar informações nutricionais:', error);
      return {
        success: false,
        message: 'Erro ao buscar informações do alimento',
        error: error.message
      };
    }
  }
}

export default new FoodAnalysisService();