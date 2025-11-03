import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/modern_app_bar.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  final List<Goal> _goals = [
    Goal(
      id: 1,
      title: 'Perder 5kg',
      description: 'Meta de perda de peso até o final do mês',
      targetValue: 5.0,
      currentValue: 2.5,
      unit: 'kg',
      category: GoalCategory.weight,
      deadline: DateTime.now().add(const Duration(days: 30)),
      isCompleted: false,
    ),
    Goal(
      id: 2,
      title: 'Correr 50km',
      description: 'Total de corrida durante a semana',
      targetValue: 50.0,
      currentValue: 32.0,
      unit: 'km',
      category: GoalCategory.cardio,
      deadline: DateTime.now().add(const Duration(days: 7)),
      isCompleted: false,
    ),
    Goal(
      id: 3,
      title: '8 horas de sono',
      description: 'Dormir pelo menos 8 horas por noite',
      targetValue: 8.0,
      currentValue: 7.2,
      unit: 'horas',
      category: GoalCategory.lifestyle,
      deadline: DateTime.now(),
      isCompleted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Minhas Metas',
        showUserInfo: true,
      ),
      body: Column(
        children: [
          _buildGoalsSummary(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                return _buildGoalCard(_goals[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGoalsSummary() {
    final completedGoals = _goals.where((goal) => goal.isCompleted).length;
    final totalGoals = _goals.length;
    final progressPercentage =
        totalGoals > 0 ? (completedGoals / totalGoals) * 100 : 0;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumo das Metas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              CircularProgressIndicator(
                value: progressPercentage / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$completedGoals de $totalGoals metas concluídas',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${progressPercentage.toStringAsFixed(0)}% de progresso geral',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final progress =
        goal.targetValue > 0 ? (goal.currentValue / goal.targetValue) : 0.0;
    final isOverdue =
        goal.deadline.isBefore(DateTime.now()) && !goal.isCompleted;
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.shade300 : Colors.transparent,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _getCategoryColor(goal.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(goal.category),
                    color: _getCategoryColor(goal.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: goal.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                      ),
                      Text(
                        goal.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (goal.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)} ${goal.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: progress >= 1.0
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? Colors.green
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deadline info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning : Icons.calendar_today,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Atrasada'
                          : daysLeft == 0
                              ? 'Vence hoje'
                              : '$daysLeft dias restantes',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showUpdateProgressDialog(goal),
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _toggleGoalCompletion(goal),
                      icon: Icon(
                        goal.isCompleted ? Icons.undo : Icons.check,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(GoalCategory category) {
    switch (category) {
      case GoalCategory.weight:
        return Colors.blue;
      case GoalCategory.cardio:
        return Colors.red;
      case GoalCategory.strength:
        return Colors.orange;
      case GoalCategory.lifestyle:
        return Colors.green;
      case GoalCategory.nutrition:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(GoalCategory category) {
    switch (category) {
      case GoalCategory.weight:
        return Icons.scale;
      case GoalCategory.cardio:
        return Icons.directions_run;
      case GoalCategory.strength:
        return Icons.fitness_center;
      case GoalCategory.lifestyle:
        return Icons.spa;
      case GoalCategory.nutrition:
        return Icons.restaurant;
    }
  }

  void _showAddGoalDialog() {
    // Implementar diálogo de adicionar meta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adicionar nova meta em desenvolvimento')),
    );
  }

  void _showUpdateProgressDialog(Goal goal) {
    // Implementar diálogo de atualizar progresso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atualizar progresso em desenvolvimento')),
    );
  }

  void _toggleGoalCompletion(Goal goal) {
    setState(() {
      goal.isCompleted = !goal.isCompleted;
      if (goal.isCompleted) {
        goal.currentValue = goal.targetValue;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          goal.isCompleted ? 'Meta concluída!' : 'Meta marcada como pendente',
        ),
      ),
    );
  }
}

// Models
class Goal {
  final int id;
  final String title;
  final String description;
  final double targetValue;
  double currentValue;
  final String unit;
  final GoalCategory category;
  final DateTime deadline;
  bool isCompleted;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.category,
    required this.deadline,
    required this.isCompleted,
  });
}

enum GoalCategory {
  weight,
  cardio,
  strength,
  lifestyle,
  nutrition,
}
