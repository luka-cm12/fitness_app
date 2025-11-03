import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/modern_app_bar.dart';
import '../widgets/bottom_navigation.dart';
import '../../../workouts/presentation/pages/athletes_management_page.dart';
import '../../../workouts/presentation/pages/exercise_library_page.dart';
import '../../../workouts/presentation/pages/trainer_reports_page.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../nutrition/presentation/pages/nutrition_pages.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Olá, ${user.firstName}!',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context, user),
            const SizedBox(height: 20),

            // Stats Cards
            _buildStatsSection(context, user.userType),
            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActionsSection(context, user.userType),
            const SizedBox(height: 20),

            // Recent Activity
            _buildRecentActivitySection(context, user.userType),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getWelcomeMessage(user.userType),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getWelcomeSubtitle(user.userType),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, UserType userType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Treinos',
                '12',
                'Esta semana',
                Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Meta',
                '75%',
                'Atingida',
                Icons.track_changes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Streak',
                '7',
                'Dias seguidos',
                Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Calorias',
                '2.1k',
                'Queimadas',
                Icons.whatshot,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
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
              Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, UserType userType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: _getQuickActions(context, userType),
        ),
      ],
    );
  }

  List<Widget> _getQuickActions(BuildContext context, UserType userType) {
    switch (userType) {
      case UserType.athlete:
        return [
          _buildActionCard(
            'Treino de Hoje',
            Icons.fitness_center,
            () => context.go('/workouts'),
          ),
          _buildActionCard(
            'Dieta',
            Icons.restaurant,
            () => context.go('/nutrition'),
          ),
          _buildActionCard('Progresso', Icons.trending_up, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProgressPage(),
              ),
            );
          }),
          _buildActionCard('Metas', Icons.flag, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalsPage(),
              ),
            );
          }),
        ];
      case UserType.trainer:
        return [
          _buildActionCard('Meus Alunos', Icons.group, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AthletesManagementPage(),
              ),
            );
          }),
          _buildActionCard(
            'Criar Treino',
            Icons.add_circle,
            () => context.go('/workouts'),
          ),
          _buildActionCard('Relatórios', Icons.analytics, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrainerReportsPage(),
              ),
            );
          }),
          _buildActionCard('Biblioteca', Icons.library_books, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExerciseLibraryPage(),
              ),
            );
          }),
        ];
      case UserType.nutritionist:
        return [
          _buildActionCard('Meus Clientes', Icons.group, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NutritionClientsPage(),
              ),
            );
          }),
          _buildActionCard(
            'Planos',
            Icons.restaurant_menu,
            () => context.go('/nutrition'),
          ),
          _buildActionCard('Alimentos', Icons.search, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FoodDatabasePage(),
              ),
            );
          }),
          _buildActionCard('Relatórios', Icons.analytics, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NutritionReportsPage(),
              ),
            );
          }),
        ];
    }
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF6C63FF)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, UserType userType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividade Recente',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: const Center(
            child: Text(
              'Nenhuma atividade recente',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  String _getWelcomeMessage(UserType userType) {
    switch (userType) {
      case UserType.athlete:
        return 'Pronto para treinar?';
      case UserType.trainer:
        return 'Seus atletas te aguardam!';
      case UserType.nutritionist:
        return 'Transforme vidas com nutrição!';
    }
  }

  String _getWelcomeSubtitle(UserType userType) {
    switch (userType) {
      case UserType.athlete:
        return 'Vamos conquistar suas metas hoje!';
      case UserType.trainer:
        return 'Gerencie treinos e acompanhe o progresso';
      case UserType.nutritionist:
        return 'Crie planos nutricionais personalizados';
    }
  }
}
