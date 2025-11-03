import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_navigation.dart';
import 'food_analysis_page.dart';
import 'food_analysis_history_page.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/models/user_model.dart';

class NutritionPage extends ConsumerWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrição'),
        actions: [
          // Indicador do tipo de usuário para debug
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  user.userType == UserType.athlete
                      ? 'Atleta'
                      : user.userType == UserType.trainer
                          ? 'Treinador'
                          : 'Nutricionista',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: user.userType == UserType.athlete
                    ? Colors.green.shade100
                    : user.userType == UserType.trainer
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
              ),
            ),
          IconButton(
            onPressed: () => _navigateToHistory(context),
            icon: const Icon(Icons.history),
            tooltip: 'Histórico',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(context, user),
      bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    switch (user.userType) {
      case UserType.athlete:
        return _buildAthleteInterface(context);
      case UserType.trainer:
        return _buildTrainerInterface(context);
      case UserType.nutritionist:
        return _buildNutritionistInterface(context);
    }
  }

  Widget _buildAthleteInterface(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mensagem informativa para atletas
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Como atleta, você pode fotografar seus pratos para análise nutricional automática com IA. Apenas nutricionistas podem criar planos alimentares.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Header específico para atleta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Análise de Alimentos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fotografe seus pratos e acompanhe sua alimentação!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Análise de foto - funcionalidade principal para atletas
          Card(
            child: InkWell(
              onTap: () => _navigateToFoodAnalysis(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fotografar Refeição',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tire uma foto da sua comida e receba análise nutricional completa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToFoodAnalysis(context),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Fotografar Agora'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Funcionalidades limitadas para atletas
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Meu Histórico',
                  'Minhas análises',
                  Icons.history,
                  Colors.green,
                  () => _navigateToHistory(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Meu Plano',
                  'Plano nutricional',
                  Icons.assignment,
                  Colors.orange,
                  () => _showAthleteOnlyFeature(context, 'Plano Nutricional'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionistInterface(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header para nutricionistas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gestão Nutricional',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gerencie planos nutricionais e acompanhe seus pacientes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Funcionalidades completas para nutricionistas
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Criar Dieta',
                  'Novos planos nutricionais',
                  Icons.add_circle,
                  Colors.blue,
                  () => _showComingSoon(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Pacientes',
                  'Gerenciar pacientes',
                  Icons.people,
                  Colors.green,
                  () => _showComingSoon(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Análise',
                  'Análise de alimentos',
                  Icons.camera_alt,
                  Colors.purple,
                  () => _navigateToFoodAnalysis(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Receitas',
                  'Biblioteca de receitas',
                  Icons.menu_book,
                  Colors.orange,
                  () => _showComingSoon(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerInterface(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header para treinadores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nutrição - Visão Treinador',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe a alimentação dos seus atletas',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Funcionalidades limitadas para treinadores
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Ver Relatórios',
                  'Relatórios nutricionais',
                  Icons.bar_chart,
                  Colors.blue,
                  () => _showComingSoon(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  context,
                  'Atletas',
                  'Progresso nutricional',
                  Icons.people,
                  Colors.green,
                  () => _showComingSoon(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Como treinador, você pode acompanhar o progresso nutricional dos atletas, mas apenas nutricionistas podem criar planos alimentares.',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAthleteOnlyFeature(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$featureName: Consulte seu nutricionista para mais informações'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToFoodAnalysis(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FoodAnalysisPage(),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FoodAnalysisHistoryPage(),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta funcionalidade estará disponível em breve!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
