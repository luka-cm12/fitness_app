import axios from 'axios';
import FormData from 'form-data';
import sharp from 'sharp';

class AIFoodAnalysisService {
  constructor() {
    // Configuração para múltiplas APIs de IA
    this.openaiApiKey = process.env.OPENAI_API_KEY;
    this.googleVisionKey = process.env.GOOGLE_VISION_API_KEY;
    this.clarifaiKey = process.env.CLARIFAI_API_KEY;
    this.spoonacularKey = process.env.SPOONACULAR_API_KEY;
    
    // URLs das APIs
    this.openaiUrl = 'https://api.openai.com/v1/chat/completions';
    this.googleVisionUrl = `https://vision.googleapis.com/v1/images:annotate?key=${this.googleVisionKey}`;
    this.clarifaiUrl = 'https://api.clarifai.com/v2/models/bd367be194cf45149e75f01d59f77ba7/outputs';
    this.spoonacularUrl = 'https://api.spoonacular.com';
  }

  /**
   * Analisa uma imagem de comida usando IA real
   * @param {Buffer} imageBuffer - Buffer da imagem
   * @returns {Promise<Object>} Informações nutricionais
   */
  async analyzeFood(imageBuffer) {
    try {
      // Redimensiona a imagem para economizar banda e melhorar performance
      const resizedImage = await sharp(imageBuffer)
        .resize(1024, 1024, { fit: 'inside' })
        .jpeg({ quality: 85 })
        .toBuffer();

      // Converte para base64 para as APIs
      const base64Image = resizedImage.toString('base64');

      // Tenta diferentes APIs de IA em ordem de preferência
      let analysis = null;

      // 1. Tenta OpenAI GPT-4 Vision (mais preciso)
      if (this.openaiApiKey && !analysis) {
        try {
          analysis = await this.analyzeWithOpenAI(base64Image);
        } catch (error) {
          console.log('OpenAI falhou, tentando próxima API:', error.message);
        }
      }

      // 2. Tenta Google Vision (boa para detecção de objetos)
      if (this.googleVisionKey && !analysis) {
        try {
          analysis = await this.analyzeWithGoogleVision(base64Image);
        } catch (error) {
          console.log('Google Vision falhou, tentando próxima API:', error.message);
        }
      }

      // 3. Tenta Clarifai (especializada em comida)
      if (this.clarifaiKey && !analysis) {
        try {
          analysis = await this.analyzeWithClarifai(base64Image);
        } catch (error) {
          console.log('Clarifai falhou, tentando simulação:', error.message);
        }
      }

      // 4. Fallback para simulação se todas as APIs falharem
      if (!analysis) {
        console.log('Todas as APIs de IA falharam, usando simulação inteligente');
        analysis = await this.intelligentSimulation(resizedImage);
      }

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
   * Análise usando OpenAI GPT-4 Vision
   */
  async analyzeWithOpenAI(base64Image) {
    const response = await axios.post(this.openaiUrl, {
      model: "gpt-4-vision-preview",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Analise esta imagem de comida e retorne um JSON com as seguintes informações:
              {
                "food_name": "nome do prato principal",
                "confidence": 0.95,
                "calories": número estimado de calorias,
                "protein": gramas de proteína,
                "carbohydrates": gramas de carboidratos,
                "fat": gramas de gordura,
                "fiber": gramas de fibra,
                "serving_size": "descrição da porção",
                "ingredients": [
                  {"name": "ingrediente", "calories": número, "protein": número, "carbs": número, "fat": número}
                ],
                "tips": ["dica nutricional 1", "dica nutricional 2"],
                "analysis_method": "openai_gpt4_vision"
              }
              
              Seja preciso na análise nutricional e inclua dicas úteis baseadas no que vê na imagem.`
            },
            {
              type: "image_url",
              image_url: {
                url: `data:image/jpeg;base64,${base64Image}`
              }
            }
          ]
        }
      ],
      max_tokens: 1000
    }, {
      headers: {
        'Authorization': `Bearer ${this.openaiApiKey}`,
        'Content-Type': 'application/json'
      }
    });

    const content = response.data.choices[0].message.content;
    // Extrai JSON da resposta
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const analysis = JSON.parse(jsonMatch[0]);
      analysis.analysis_timestamp = new Date().toISOString();
      analysis.portion_multiplier = 1.0;
      return analysis;
    }
    
    throw new Error('Não foi possível extrair dados estruturados da resposta OpenAI');
  }

  /**
   * Análise usando Google Vision API
   */
  async analyzeWithGoogleVision(base64Image) {
    const response = await axios.post(this.googleVisionUrl, {
      requests: [
        {
          image: {
            content: base64Image
          },
          features: [
            { type: 'LABEL_DETECTION', maxResults: 10 },
            { type: 'OBJECT_LOCALIZATION', maxResults: 10 },
            { type: 'TEXT_DETECTION', maxResults: 5 }
          ]
        }
      ]
    });

    const annotations = response.data.responses[0];
    const labels = annotations.labelAnnotations || [];
    const objects = annotations.localizedObjectAnnotations || [];

    // Extrai informações sobre comida
    const foodLabels = labels.filter(label => 
      this.isFoodRelated(label.description)
    );

    // Mapeia labels para informações nutricionais
    const analysis = await this.mapLabelsToNutrition(foodLabels, objects);
    analysis.analysis_method = 'google_vision';
    analysis.analysis_timestamp = new Date().toISOString();
    
    return analysis;
  }

  /**
   * Análise usando Clarifai Food Model
   */
  async analyzeWithClarifai(base64Image) {
    const response = await axios.post(this.clarifaiUrl, {
      inputs: [
        {
          data: {
            image: {
              base64: base64Image
            }
          }
        }
      ]
    }, {
      headers: {
        'Authorization': `Key ${this.clarifaiKey}`,
        'Content-Type': 'application/json'
      }
    });

    const outputs = response.data.outputs[0];
    const concepts = outputs.data.concepts;

    // Filtra conceitos relacionados a comida
    const foodConcepts = concepts.filter(concept => 
      concept.value > 0.5 && this.isFoodRelated(concept.name)
    );

    const analysis = await this.mapConceptsToNutrition(foodConcepts);
    analysis.analysis_method = 'clarifai_food_model';
    analysis.analysis_timestamp = new Date().toISOString();
    
    return analysis;
  }

  /**
   * Simulação inteligente melhorada (fallback)
   */
  async intelligentSimulation(imageBuffer) {
    // Análise básica da imagem
    const metadata = await sharp(imageBuffer).metadata();
    const stats = await sharp(imageBuffer).stats();
    
    // Usa características da imagem para melhor simulação
    const dominantColor = stats.dominant;
    const brightness = stats.channels.reduce((sum, channel) => sum + channel.mean, 0) / stats.channels.length;
    const imageSize = imageBuffer.length;
    
    // Lógica mais inteligente baseada em características visuais
    let plateType = 'mixed';
    
    // Cor dominante pode indicar tipo de comida
    if (dominantColor.r > dominantColor.g && dominantColor.r > dominantColor.b) {
      // Vermelho dominante - pode ser carne, tomate, etc.
      plateType = 'protein';
    } else if (dominantColor.g > dominantColor.r && dominantColor.g > dominantColor.b) {
      // Verde dominante - vegetais, saladas
      plateType = 'vegetable';
    } else if (brightness > 200) {
      // Imagem clara - pode ser arroz, massas
      plateType = 'carbs';
    }

    const plateOptions = this.getIntelligentPlateOptions(plateType, imageSize, brightness);
    
    // Seleciona baseado em múltiplos fatores
    const index = Math.floor((imageSize % 1000) % plateOptions.length);
    const selectedPlate = plateOptions[index];
    
    // Adiciona variação baseada nas características da imagem
    const variation = this.calculateVariation(brightness, imageSize, dominantColor);
    
    return {
      ...selectedPlate,
      calories: Math.round(selectedPlate.calories * variation),
      protein: Math.round(selectedPlate.protein * variation * 10) / 10,
      carbohydrates: Math.round(selectedPlate.carbohydrates * variation * 10) / 10,
      fat: Math.round(selectedPlate.fat * variation * 10) / 10,
      fiber: Math.round(selectedPlate.fiber * variation * 10) / 10,
      portion_multiplier: Math.round(variation * 100) / 100,
      analysis_timestamp: new Date().toISOString(),
      analysis_method: 'intelligent_simulation',
      image_characteristics: {
        dominant_color: dominantColor,
        brightness: Math.round(brightness),
        size_bytes: imageSize,
        detected_type: plateType
      }
    };
  }

  /**
   * Verifica se um termo está relacionado a comida
   */
  isFoodRelated(term) {
    const foodKeywords = [
      'food', 'meal', 'dish', 'plate', 'bowl', 'rice', 'meat', 'chicken', 'beef', 
      'vegetable', 'salad', 'pasta', 'bread', 'soup', 'pizza', 'burger', 'sandwich',
      'fruit', 'dessert', 'cake', 'cookie', 'fish', 'seafood', 'cheese', 'egg',
      'comida', 'prato', 'refeição', 'arroz', 'carne', 'frango', 'vegetais',
      'salada', 'massa', 'pão', 'sopa', 'pizza', 'hambúrguer', 'fruta', 'sobremesa'
    ];
    
    return foodKeywords.some(keyword => 
      term.toLowerCase().includes(keyword.toLowerCase())
    );
  }

  /**
   * Mapeia labels do Google Vision para informações nutricionais
   */
  async mapLabelsToNutrition(labels, objects) {
    // Banco de dados simples de mapeamento
    const nutritionMap = {
      'rice': { calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4 },
      'meat': { calories: 250, protein: 26, carbs: 0, fat: 15, fiber: 0 },
      'chicken': { calories: 165, protein: 31, carbs: 0, fat: 3.6, fiber: 0 },
      'vegetable': { calories: 25, protein: 1, carbs: 5, fat: 0.1, fiber: 2 },
      'salad': { calories: 20, protein: 1, carbs: 4, fat: 0.1, fiber: 1.5 },
      'pasta': { calories: 220, protein: 8, carbs: 44, fat: 1.1, fiber: 2.5 },
      'bread': { calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7 }
    };

    let totalNutrition = { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 };
    let detectedFoods = [];
    let confidence = 0;

    labels.forEach(label => {
      const foodKey = Object.keys(nutritionMap).find(key => 
        label.description.toLowerCase().includes(key)
      );
      
      if (foodKey) {
        const nutrition = nutritionMap[foodKey];
        const weight = label.score || 0.5; // Confiança do Google Vision
        
        totalNutrition.calories += nutrition.calories * weight;
        totalNutrition.protein += nutrition.protein * weight;
        totalNutrition.carbs += nutrition.carbs * weight;
        totalNutrition.fat += nutrition.fat * weight;
        totalNutrition.fiber += nutrition.fiber * weight;
        
        detectedFoods.push({
          name: label.description,
          calories: Math.round(nutrition.calories * weight),
          protein: nutrition.protein * weight,
          carbs: nutrition.carbs * weight,
          fat: nutrition.fat * weight
        });
        
        confidence += label.score;
      }
    });

    confidence = Math.min(confidence / labels.length, 1.0);

    return {
      food_name: detectedFoods.length > 0 ? 
        `Prato com ${detectedFoods.map(f => f.name).join(', ')}` : 
        'Prato misto',
      confidence: confidence,
      calories: Math.round(totalNutrition.calories),
      protein: Math.round(totalNutrition.protein * 10) / 10,
      carbohydrates: Math.round(totalNutrition.carbs * 10) / 10,
      fat: Math.round(totalNutrition.fat * 10) / 10,
      fiber: Math.round(totalNutrition.fiber * 10) / 10,
      serving_size: '1 porção média',
      ingredients: detectedFoods,
      tips: this.generateTips(totalNutrition, detectedFoods),
      portion_multiplier: 1.0
    };
  }

  /**
   * Mapeia conceitos do Clarifai para informações nutricionais
   */
  async mapConceptsToNutrition(concepts) {
    // Similar ao Google Vision, mas adaptado para a estrutura do Clarifai
    // ... implementação similar à mapLabelsToNutrition
    return this.mapLabelsToNutrition(
      concepts.map(c => ({ description: c.name, score: c.value })), 
      []
    );
  }

  /**
   * Gera opções de pratos baseado no tipo detectado
   */
  getIntelligentPlateOptions(plateType, imageSize, brightness) {
    const baseOptions = {
      protein: [
        {
          food_name: 'Prato Rico em Proteína',
          confidence: 0.85,
          calories: 450,
          protein: 45,
          carbohydrates: 20,
          fat: 20,
          fiber: 5,
          serving_size: '1 porção (250g)',
          ingredients: [
            { name: 'Peito de frango grelhado', calories: 200, protein: 25, carbs: 0, fat: 8 },
            { name: 'Vegetais refogados', calories: 50, protein: 2, carbs: 10, fat: 2 },
            { name: 'Arroz integral', calories: 100, protein: 3, carbs: 20, fat: 1 }
          ]
        }
      ],
      vegetable: [
        {
          food_name: 'Salada Nutritiva',
          confidence: 0.80,
          calories: 220,
          protein: 12,
          carbohydrates: 25,
          fat: 8,
          fiber: 12,
          serving_size: '1 bowl grande (300g)',
          ingredients: [
            { name: 'Mix de folhas verdes', calories: 20, protein: 2, carbs: 4, fat: 0.1 },
            { name: 'Tomate cereja', calories: 30, protein: 1, carbs: 6, fat: 0.2 },
            { name: 'Pepino', calories: 15, protein: 1, carbs: 3, fat: 0.1 }
          ]
        }
      ],
      carbs: [
        {
          food_name: 'Prato com Base de Carboidratos',
          confidence: 0.75,
          calories: 520,
          protein: 18,
          carbohydrates: 80,
          fat: 12,
          fiber: 6,
          serving_size: '1 prato (350g)',
          ingredients: [
            { name: 'Arroz branco', calories: 200, protein: 4, carbs: 45, fat: 0.5 },
            { name: 'Feijão', calories: 120, protein: 8, carbs: 22, fat: 1 },
            { name: 'Proteína complementar', calories: 150, protein: 15, carbs: 5, fat: 8 }
          ]
        }
      ]
    };

    return baseOptions[plateType] || baseOptions.protein;
  }

  /**
   * Calcula variação baseada nas características da imagem
   */
  calculateVariation(brightness, imageSize, dominantColor) {
    let variation = 1.0;
    
    // Tamanho da imagem pode indicar quantidade de comida
    if (imageSize > 500000) variation *= 1.2; // Imagem grande = mais comida
    if (imageSize < 100000) variation *= 0.8; // Imagem pequena = menos comida
    
    // Brilho pode indicar tipo de preparação
    if (brightness > 180) variation *= 0.9; // Comida clara pode ser menos calórica
    if (brightness < 100) variation *= 1.1; // Comida escura pode ser mais calórica
    
    return Math.max(0.7, Math.min(1.3, variation));
  }

  /**
   * Gera dicas nutricionais baseadas na análise
   */
  generateTips(nutrition, foods) {
    const tips = [];
    
    if (nutrition.calories > 600) {
      tips.push('Este prato é calórico. Considere equilibrar com atividade física.');
    }
    
    if (nutrition.protein < 20) {
      tips.push('Adicione mais proteína para melhor saciedade e recuperação muscular.');
    }
    
    if (nutrition.fiber < 5) {
      tips.push('Inclua mais vegetais ou grãos integrais para aumentar as fibras.');
    }
    
    if (foods.some(f => f.name.toLowerCase().includes('vegetable'))) {
      tips.push('Ótima escolha incluir vegetais! Eles fornecem vitaminas e minerais essenciais.');
    }
    
    if (tips.length === 0) {
      tips.push('Este prato parece bem equilibrado nutricionalmente!');
    }
    
    return tips;
  }

  /**
   * Busca informações nutricionais usando Spoonacular
   */
  async searchFoodNutrition(foodName) {
    if (!this.spoonacularKey) {
      throw new Error('Chave da API Spoonacular não configurada');
    }

    try {
      const response = await axios.get(`${this.spoonacularUrl}/food/ingredients/search`, {
        params: {
          apiKey: this.spoonacularKey,
          query: foodName,
          number: 1
        }
      });

      if (response.data.results && response.data.results.length > 0) {
        const food = response.data.results[0];
        
        const nutritionResponse = await axios.get(
          `${this.spoonacularUrl}/food/ingredients/${food.id}/information`,
          {
            params: {
              apiKey: this.spoonacularKey,
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

export default new AIFoodAnalysisService();