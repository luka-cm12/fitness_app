import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/athlete_model.dart';
import '../../../workouts/providers/trainer_provider.dart';

class TrainerReportsPage extends ConsumerWidget {
  const TrainerReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(trainerDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios e Analytics'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: dashboardAsync.when(
        data: (dashboard) => _buildReportsContent(context, dashboard),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar relatórios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(trainerDashboardProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsContent(
      BuildContext context, TrainerDashboard dashboard) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Overview
          _buildStatsOverview(dashboard.stats),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivitySection(dashboard.recentActivity),
          const SizedBox(height: 24),

          // Upcoming Workouts
          _buildUpcomingWorkoutsSection(dashboard.upcomingWorkouts),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(TrainerStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visão Geral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total de Atletas',
              '${stats.totalAthletes}',
              Icons.group,
              Colors.blue,
            ),
            _buildStatCard(
              'Treinos esta Semana',
              '${stats.workoutsThisWeek}',
              Icons.fitness_center,
              Colors.green,
            ),
            _buildStatCard(
              'Completados',
              '${stats.completedThisWeek}',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatCard(
              'Taxa de Conclusão',
              '${stats.completionRate}%',
              Icons.trending_up,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(List<RecentActivity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Recente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (activities.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Nenhuma atividade recente',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...activities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    Color statusColor;
    IconData statusIcon;

    switch (activity.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.play_circle;
        break;
      case 'skipped':
        statusColor = Colors.red;
        statusIcon = Icons.skip_next;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(activity.workoutName),
        subtitle: Text(activity.athleteName),
        trailing: Text(
          _formatDate(activity.scheduledDate),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingWorkoutsSection(List<UpcomingWorkout> workouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximos Treinos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum treino agendado',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...workouts.map((workout) => _buildUpcomingWorkoutItem(workout)),
      ],
    );
  }

  Widget _buildUpcomingWorkoutItem(UpcomingWorkout workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
          child: const Icon(Icons.fitness_center, color: Color(0xFF6C63FF)),
        ),
        title: Text(workout.workoutName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workout.athleteName),
            Text(
              _getDifficultyLabel(workout.difficultyLevel),
              style: TextStyle(
                color: _getDifficultyColor(workout.difficultyLevel),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          _formatDate(workout.scheduledDate),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDate = DateTime(date.year, date.month, date.day);

    if (workoutDate == today) {
      return 'Hoje';
    } else if (workoutDate == today.add(const Duration(days: 1))) {
      return 'Amanhã';
    } else if (workoutDate == today.subtract(const Duration(days: 1))) {
      return 'Ontem';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 'Iniciante';
      case 'intermediate':
        return 'Intermediário';
      case 'advanced':
        return 'Avançado';
      default:
        return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
