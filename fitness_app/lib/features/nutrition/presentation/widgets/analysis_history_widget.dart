import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/food_analysis_model.dart';
import '../../providers/food_analysis_provider.dart';

class AnalysisHistoryWidget extends ConsumerWidget {
  final int limit;
  final VoidCallback? onSeeMore;

  const AnalysisHistoryWidget({
    super.key,
    this.limit = 5,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyParams = AnalysisHistoryParams(limit: limit);
    final historyAsync = ref.watch(analysisHistoryProvider(historyParams));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Análises Recentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (onSeeMore != null)
                  TextButton(
                    onPressed: onSeeMore,
                    child: const Text('Ver Mais'),
                  ),
              ],
            ),
          ),
          historyAsync.when(
            data: (analyses) {
              if (analyses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Nenhuma análise encontrada.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: analyses.length,
                itemBuilder: (context, index) {
                  final analysis = analyses[index];
                  return AnalysisHistoryTile(analysis: analysis);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Erro ao carregar histórico: $error'),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalysisHistoryTile extends ConsumerWidget {
  final FoodAnalysisModel analysis;

  const AnalysisHistoryTile({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          Icons.restaurant,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        analysis.foodName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${analysis.calories} kcal',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatTimestamp(analysis.analysisTimestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navegar para detalhes da análise
        _showAnalysisDetails(context);
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoje';
      } else if (difference.inDays == 1) {
        return 'Ontem';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} dias atrás';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  void _showAnalysisDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle para arrastar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Text(
                  analysis.foodName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),

                Text(
                  _formatTimestamp(analysis.analysisTimestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Informações nutricionais
                      _buildNutritionInfo(context),
                      const SizedBox(height: 16),

                      // Ingredientes
                      if (analysis.ingredients.isNotEmpty) ...[
                        Text(
                          'Ingredientes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: analysis.ingredients
                              .map((ingredient) => Chip(
                                    label: Text(ingredient.name),
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Dicas
                      if (analysis.tips.isNotEmpty) ...[
                        Text(
                          'Dicas Nutricionais',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...analysis.tips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(tip)),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutritionInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Nutricionais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientCard(
                    context,
                    'Calorias',
                    '${analysis.calories}',
                    'kcal',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientCard(
                    context,
                    'Proteínas',
                    '${analysis.protein.toStringAsFixed(1)}',
                    'g',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientCard(
                    context,
                    'Carboidratos',
                    '${analysis.carbohydrates.toStringAsFixed(1)}',
                    'g',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNutrientCard(
                    context,
                    'Gorduras',
                    '${analysis.fat.toStringAsFixed(1)}',
                    'g',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
