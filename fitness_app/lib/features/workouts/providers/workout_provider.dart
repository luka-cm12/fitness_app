import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/exercise_model.dart';

// Provider para templates de treinos
final workoutTemplatesProvider =
    FutureProvider.family<List<WorkoutTemplate>, WorkoutTemplateParams>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getWorkoutTemplates(
    page: params.page,
    limit: params.limit,
    category: params.category,
    difficultyLevel: params.difficultyLevel,
  );
  return response.data;
});

// Provider para treinos atribuídos
final assignedWorkoutsProvider =
    FutureProvider.family<List<AssignedWorkout>, AssignedWorkoutParams>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getAssignedWorkouts(
    page: params.page,
    limit: params.limit,
    status: params.status,
  );
  return response.data;
});

// Provider para completar treino
final completeWorkoutProvider =
    FutureProvider.family<bool, CompleteWorkoutParams>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    await apiService.completeWorkout(params.workoutId, params.completionData);
    return true;
  } catch (e) {
    throw Exception('Erro ao completar treino: $e');
  }
});

// Classes de parâmetros
class WorkoutTemplateParams {
  final int page;
  final int limit;
  final String? category;
  final String? difficultyLevel;

  const WorkoutTemplateParams({
    this.page = 1,
    this.limit = 20,
    this.category,
    this.difficultyLevel,
  });
}

class AssignedWorkoutParams {
  final int page;
  final int limit;
  final String? status;

  const AssignedWorkoutParams({
    this.page = 1,
    this.limit = 20,
    this.status,
  });
}

class CompleteWorkoutParams {
  final int workoutId;
  final Map<String, dynamic> completionData;

  const CompleteWorkoutParams({
    required this.workoutId,
    required this.completionData,
  });
}
