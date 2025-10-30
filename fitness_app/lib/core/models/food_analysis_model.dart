class FoodAnalysisModel {
  final String foodName;
  final double confidence;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final String servingSize;
  final List<FoodIngredient> ingredients;
  final List<String> tips;
  final double portionMultiplier;
  final String analysisTimestamp;

  const FoodAnalysisModel({
    required this.foodName,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.servingSize,
    required this.ingredients,
    required this.tips,
    required this.portionMultiplier,
    required this.analysisTimestamp,
  });

  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisModel(
      foodName: json['food_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      calories: (json['calories'] ?? 0).toInt(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
      fiber: (json['fiber'] ?? 0.0).toDouble(),
      servingSize: json['serving_size'] ?? '',
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => FoodIngredient.fromJson(e))
              .toList() ??
          [],
      tips: List<String>.from(json['tips'] ?? []),
      portionMultiplier: (json['portion_multiplier'] ?? 1.0).toDouble(),
      analysisTimestamp: json['analysis_timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'confidence': confidence,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'serving_size': servingSize,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'tips': tips,
      'portion_multiplier': portionMultiplier,
      'analysis_timestamp': analysisTimestamp,
    };
  }

  // Getters para facilitar o acesso
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  double get totalMacros => protein + carbohydrates + fat;

  double get proteinPercentage =>
      totalMacros > 0 ? (protein / totalMacros) * 100 : 0;

  double get carbsPercentage =>
      totalMacros > 0 ? (carbohydrates / totalMacros) * 100 : 0;

  double get fatPercentage => totalMacros > 0 ? (fat / totalMacros) * 100 : 0;
}

class FoodIngredient {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodIngredient({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodIngredient.fromJson(Map<String, dynamic> json) {
    return FoodIngredient(
      name: json['name'] ?? '',
      calories: (json['calories'] ?? 0).toInt(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class FoodAnalysisHistoryModel {
  final int id;
  final String foodName;
  final double confidence;
  final int calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final String createdAt;

  const FoodAnalysisHistoryModel({
    required this.id,
    required this.foodName,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.createdAt,
  });

  factory FoodAnalysisHistoryModel.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisHistoryModel(
      id: json['id'] ?? 0,
      foodName: json['food_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      calories: (json['calories'] ?? 0).toInt(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
      fiber: (json['fiber'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_name': foodName,
      'confidence': confidence,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'created_at': createdAt,
    };
  }
}
