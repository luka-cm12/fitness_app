import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/models/food_analysis_model.dart';

class FoodAnalysisResultPage extends StatelessWidget {
  final FoodAnalysisModel analysis;
  final File imageFile;

  const FoodAnalysisResultPage({
    super.key,
    required this.analysis,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Análise'),
        actions: [
          IconButton(
            onPressed: () => _shareResult(context),
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem analisada
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          analysis.foodName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _getConfidenceColor(analysis.confidence),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Confiança: ${analysis.confidencePercentage}',
                              style: TextStyle(
                                color: _getConfidenceColor(analysis.confidence),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informações nutricionais principais
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informações Nutricionais',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calorias destacadas
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${analysis.calories}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Text(
                            'Calorias',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            analysis.servingSize,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Macronutrientes
                    Row(
                      children: [
                        Expanded(
                          child: _buildNutrientCard(
                            'Proteína',
                            '${analysis.protein.toStringAsFixed(1)}g',
                            Colors.red,
                            analysis.proteinPercentage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNutrientCard(
                            'Carbs',
                            '${analysis.carbohydrates.toStringAsFixed(1)}g',
                            Colors.orange,
                            analysis.carbsPercentage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildNutrientCard(
                            'Gordura',
                            '${analysis.fat.toStringAsFixed(1)}g',
                            Colors.yellow[700]!,
                            analysis.fatPercentage,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Fibra
                    _buildNutrientRow('Fibra',
                        '${analysis.fiber.toStringAsFixed(1)}g', Icons.grass),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredientes detectados
            if (analysis.ingredients.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.list,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingredientes Detectados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...analysis.ingredients
                          .map((ingredient) => _buildIngredientTile(ingredient))
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Dicas nutricionais
            if (analysis.tips.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dicas Nutricionais',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...analysis.tips
                          .map((tip) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botões de ação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _addToFoodLog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar ao Diário'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _analyzeAnother(context),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Analisar Outra Foto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(
      String label, String value, Color color, double percentage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientTile(FoodIngredient ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${ingredient.calories} cal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _shareResult(BuildContext context) {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Funcionalidade de compartilhamento em desenvolvimento')),
    );
  }

  void _addToFoodLog(BuildContext context) {
    // Implementar adição ao diário alimentar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adicionado ao diário alimentar!')),
    );
    Navigator.of(context).pop();
  }

  void _analyzeAnother(BuildContext context) {
    Navigator.of(context).pop();
  }
}
