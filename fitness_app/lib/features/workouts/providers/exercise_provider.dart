import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/exercise_model.dart';
import '../../../core/services/api_service.dart';

class ExerciseFilters {
  final String? category;
  final String? difficultyLevel;
  final String? search;
  final int page;
  final int limit;

  ExerciseFilters({
    this.category,
    this.difficultyLevel,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFilters &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          difficultyLevel == other.difficultyLevel &&
          search == other.search &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      category.hashCode ^
      difficultyLevel.hashCode ^
      search.hashCode ^
      page.hashCode ^
      limit.hashCode;
}

// Provider para listar exercícios com filtros
final exercisesProvider =
    FutureProvider.autoDispose.family<List<Exercise>, ExerciseFilters>(
  (ref, filters) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.getExercises(
        page: filters.page,
        limit: filters.limit,
        category: filters.category,
        difficultyLevel: filters.difficultyLevel,
        search: filters.search,
      );

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao carregar exercícios: $e');
    }
  },
);

// Provider para um exercício específico
final exerciseProvider = FutureProvider.autoDispose.family<Exercise, int>(
  (ref, exerciseId) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      return await apiService.getExercise(exerciseId);
    } catch (e) {
      throw Exception('Erro ao carregar exercício: $e');
    }
  },
);

// Provider para templates de treino
final workoutTemplatesProvider = FutureProvider.autoDispose
    .family<List<WorkoutTemplate>, WorkoutTemplateFilters>(
  (ref, filters) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.getWorkoutTemplates(
        page: filters.page,
        limit: filters.limit,
        category: filters.category,
        difficultyLevel: filters.difficultyLevel,
      );

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao carregar templates de treino: $e');
    }
  },
);

class WorkoutTemplateFilters {
  final String? category;
  final String? difficultyLevel;
  final int page;
  final int limit;
  final bool myTemplatesOnly;

  WorkoutTemplateFilters({
    this.category,
    this.difficultyLevel,
    this.page = 1,
    this.limit = 20,
    this.myTemplatesOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTemplateFilters &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          difficultyLevel == other.difficultyLevel &&
          page == other.page &&
          limit == other.limit &&
          myTemplatesOnly == other.myTemplatesOnly;

  @override
  int get hashCode =>
      category.hashCode ^
      difficultyLevel.hashCode ^
      page.hashCode ^
      limit.hashCode ^
      myTemplatesOnly.hashCode;
}

// Provider para criar template de treino
final createWorkoutTemplateProvider = FutureProvider.autoDispose
    .family<WorkoutTemplate, CreateWorkoutTemplateRequest>(
  (ref, request) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.createWorkoutTemplate(request);

      if (response.success) {
        // Invalidar a lista de templates após criar um novo
        ref.invalidate(workoutTemplatesProvider);
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao criar template de treino: $e');
    }
  },
);

// Provider para obter template específico com exercícios
final workoutTemplateProvider =
    FutureProvider.autoDispose.family<WorkoutTemplate, int>(
  (ref, templateId) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.getWorkoutTemplate(templateId);

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao carregar template de treino: $e');
    }
  },
);

// Provider para atribuir treino
final assignWorkoutProvider =
    FutureProvider.autoDispose.family<AssignedWorkout, AssignWorkoutRequest>(
  (ref, request) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.assignWorkout({
        'athlete_id': request.athleteId,
        'workout_template_id': request.workoutTemplateId,
        'scheduled_date': request.scheduledDate.toIso8601String(),
        'notes': request.notes,
      });

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao atribuir treino: $e');
    }
  },
);

class AssignWorkoutRequest {
  final int athleteId;
  final int workoutTemplateId;
  final DateTime scheduledDate;
  final String? notes;

  AssignWorkoutRequest({
    required this.athleteId,
    required this.workoutTemplateId,
    required this.scheduledDate,
    this.notes,
  });
}
