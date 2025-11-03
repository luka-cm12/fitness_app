import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/exercise_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../workouts/providers/exercise_provider.dart';
import '../widgets/bottom_navigation.dart';
import 'exercise_library_page.dart';
import 'create_workout_page.dart';

class WorkoutsPage extends ConsumerStatefulWidget {
  const WorkoutsPage({super.key});

  @override
  ConsumerState<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends ConsumerState<WorkoutsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool showMyTemplatesOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // Verificação de controle de acesso
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ATLETAS - apenas visualização de treinos atribuídos
    if (user.userType == UserType.athlete) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meus Treinos'),
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: const Text('Atleta',
                    style: TextStyle(fontSize: 12, color: Colors.white)),
                backgroundColor: Colors.green.withOpacity(0.3),
              ),
            ),
          ],
        ),
        body: _buildAthleteWorkouts(),
        bottomNavigationBar: const BottomNavigation(),
      );
    }

    // NUTRICIONISTAS - sem acesso a gestão de treinos
    if (user.userType == UserType.nutritionist) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Treinos'),
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Acesso Restrito',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Nutricionistas não têm acesso à gestão de treinos',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavigation(),
      );
    }

    // TREINADORES - acesso completo para criação e gestão
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Treinos'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          if (user.userType == UserType.trainer) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'library':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExerciseLibraryPage(),
                      ),
                    );
                    break;
                  case 'create':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateWorkoutPage(),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'library',
                  child: Row(
                    children: [
                      Icon(Icons.library_books),
                      SizedBox(width: 8),
                      Text('Biblioteca de Exercícios'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'create',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle),
                      SizedBox(width: 8),
                      Text('Criar Treino'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: user.userType == UserType.trainer
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Meus Templates'),
                  Tab(text: 'Biblioteca Pública'),
                ],
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrainerTemplates(true),
          _buildTrainerTemplates(false),
        ],
      ),
      floatingActionButton: user.userType == UserType.trainer
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateWorkoutPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar Treino'),
              backgroundColor: const Color(0xFF6C63FF),
            )
          : null,
      bottomNavigationBar: const BottomNavigation(),
    );
  }

  Widget _buildTrainerTemplates(bool myTemplatesOnly) {
    return Consumer(
      builder: (context, ref, child) {
        final templatesAsync = ref.watch(
          workoutTemplatesProvider(WorkoutTemplateFilters(
            myTemplatesOnly: myTemplatesOnly,
          )),
        );

        return templatesAsync.when(
          data: (templates) => _buildTemplatesList(templates, myTemplatesOnly),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar templates',
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
                  onPressed: () => ref.invalidate(workoutTemplatesProvider),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemplatesList(
      List<WorkoutTemplate> templates, bool myTemplatesOnly) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              myTemplatesOnly
                  ? 'Nenhum template criado'
                  : 'Nenhum template público encontrado',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              myTemplatesOnly
                  ? 'Crie seu primeiro template de treino'
                  : 'Outros treinadores ainda não compartilharam templates',
              style: const TextStyle(color: Colors.grey),
            ),
            if (myTemplatesOnly) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateWorkoutPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar Primeiro Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(template, myTemplatesOnly);
      },
    );
  }

  Widget _buildTemplateCard(WorkoutTemplate template, bool isMyTemplate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTemplateDetails(template),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (template.description?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            template.description!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isMyTemplate)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            // TODO: Navigate to edit page
                            break;
                          case 'assign':
                            _showAssignWorkoutDialog(template);
                            break;
                          case 'duplicate':
                            // TODO: Duplicate template
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'assign',
                          child: Text('Atribuir a Atleta'),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicar'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    template.category ?? 'Geral',
                    Icons.category,
                    Colors.blue,
                  ),
                  _buildInfoChip(
                    _getDifficultyLabel(template.difficultyLevel),
                    Icons.trending_up,
                    _getDifficultyColor(template.difficultyLevel),
                  ),
                  _buildInfoChip(
                    '${template.durationMinutes} min',
                    Icons.access_time,
                    Colors.green,
                  ),
                  if (template.exerciseCount != null)
                    _buildInfoChip(
                      '${template.exerciseCount} exercícios',
                      Icons.fitness_center,
                      Colors.orange,
                    ),
                ],
              ),
              if (!isMyTemplate && template.trainerName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Por: ${template.trainerName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAthleteWorkouts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensagem informativa para atletas
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Como atleta, você pode visualizar e realizar os treinos atribuídos pelo seu treinador. Apenas treinadores podem criar novos treinos.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Treino de Hoje
          _buildAthleteSection(
            'Treino de Hoje',
            Icons.today,
            Colors.green,
            _buildTodayWorkout(),
          ),

          const SizedBox(height: 24),

          // Próximos Treinos
          _buildAthleteSection(
            'Próximos Treinos',
            Icons.schedule,
            Colors.blue,
            _buildUpcomingWorkouts(),
          ),

          const SizedBox(height: 24),

          // Histórico de Treinos
          _buildAthleteSection(
            'Histórico de Treinos',
            Icons.history,
            Colors.orange,
            _buildWorkoutHistory(),
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteSection(
      String title, IconData icon, Color color, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildTodayWorkout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Treino de Peito e Tríceps',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dificuldade: Intermediário • 45 min',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _startWorkout(),
            icon: const Icon(Icons.play_arrow, color: Color(0xFF6C63FF)),
            label: const Text(
              'Iniciar Treino',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingWorkouts() {
    final upcomingWorkouts = [
      {'name': 'Treino de Costas', 'date': 'Amanhã', 'difficulty': 'Avançado'},
      {
        'name': 'Treino de Pernas',
        'date': 'Quarta-feira',
        'difficulty': 'Intermediário'
      },
      {
        'name': 'Treino de Ombros',
        'date': 'Sexta-feira',
        'difficulty': 'Iniciante'
      },
    ];

    return Column(
      children: upcomingWorkouts.map((workout) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.fitness_center, color: Colors.blue),
              ),
              title: Text(workout['name']!),
              subtitle: Text('${workout['date']} • ${workout['difficulty']}'),
              trailing: IconButton(
                onPressed: () => _viewWorkoutDetails(workout['name']!),
                icon: const Icon(Icons.visibility),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutHistory() {
    final workoutHistory = [
      {'name': 'Treino de Braços', 'date': 'Ontem', 'completed': true},
      {'name': 'Treino Funcional', 'date': '2 dias atrás', 'completed': true},
      {'name': 'Cardio HIIT', 'date': '3 dias atrás', 'completed': false},
    ];

    return Column(
      children: workoutHistory.map((workout) {
        final isCompleted = workout['completed'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.cancel,
                  color: isCompleted ? Colors.green : Colors.red,
                ),
              ),
              title: Text(workout['name'] as String),
              subtitle: Text(workout['date'] as String),
              trailing: Text(
                isCompleted ? 'Concluído' : 'Não realizado',
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _startWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Treino'),
        content: const Text(
            'Funcionalidade para executar treinos em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _viewWorkoutDetails(String workoutName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes: $workoutName'),
        content:
            const Text('Visualização detalhada do treino em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetails(WorkoutTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkoutTemplateDetailsSheet(template: template),
    );
  }

  void _showAssignWorkoutDialog(WorkoutTemplate template) {
    // TODO: Show dialog to assign workout to athlete
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atribuir "${template.name}"'),
        content: const Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
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
    switch (difficulty) {
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

class WorkoutTemplateDetailsSheet extends StatelessWidget {
  final WorkoutTemplate template;

  const WorkoutTemplateDetailsSheet({
    super.key,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (template.description?.isNotEmpty ?? false)
                        Text(
                          template.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip('Categoria', template.category ?? 'Geral',
                          Colors.blue),
                      _buildInfoChip(
                          'Dificuldade',
                          _getDifficultyLabel(template.difficultyLevel),
                          _getDifficultyColor(template.difficultyLevel)),
                      _buildInfoChip('Duração',
                          '${template.durationMinutes} min', Colors.green),
                      if (template.exerciseCount != null)
                        _buildInfoChip('Exercícios',
                            '${template.exerciseCount}', Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Exercises section
                  if (template.exercises?.isNotEmpty ?? false) ...[
                    const Text(
                      'Exercícios',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...template.exercises!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      return _buildExerciseItem(index + 1, exercise);
                    }),
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Detalhes dos exercícios não disponíveis',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildExerciseItem(int index, WorkoutTemplateExercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise.exerciseName ?? 'Exercício #${exercise.exerciseId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (exercise.sets != null || exercise.reps != null)
            Text(
              '${exercise.sets ?? '-'} séries × ${exercise.reps ?? '-'} repetições',
              style: TextStyle(color: Colors.grey[600]),
            ),
          if (exercise.weight != null && exercise.weight!.isNotEmpty)
            Text(
              'Peso: ${exercise.weight}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          if (exercise.durationSeconds != null)
            Text(
              'Duração: ${exercise.durationSeconds! ~/ 60}min ${exercise.durationSeconds! % 60}s',
              style: TextStyle(color: Colors.grey[600]),
            ),
          if (exercise.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              'Obs: ${exercise.notes}',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
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
    switch (difficulty) {
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
