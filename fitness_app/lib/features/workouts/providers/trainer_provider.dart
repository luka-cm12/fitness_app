import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/athlete_model.dart';
import '../../../core/services/api_service.dart';

// Provider para atletas do treinador
final trainerAthletesProvider = FutureProvider.autoDispose<List<Athlete>>(
  (ref) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.getTrainerAthletes();

      if (response.success) {
        return response.data;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Erro ao carregar atletas: $e');
    }
  },
);

// Provider para dashboard do treinador
final trainerDashboardProvider = FutureProvider.autoDispose<TrainerDashboard>(
  (ref) async {
    final apiService = ref.watch(apiServiceProvider);

    try {
      final response = await apiService.getTrainerDashboard();

      if (response.response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return TrainerDashboard.fromJson(data['data']);
      } else {
        throw Exception('Erro na resposta do servidor');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dashboard: $e');
    }
  },
); // Provider para estatísticas do treinador
final trainerStatsProvider = FutureProvider.autoDispose<TrainerStats>(
  (ref) async {
    final dashboard = await ref.watch(trainerDashboardProvider.future);
    return dashboard.stats;
  },
);

// Provider para atividades recentes
final trainerRecentActivitiesProvider =
    FutureProvider.autoDispose<List<RecentActivity>>(
  (ref) async {
    final dashboard = await ref.watch(trainerDashboardProvider.future);
    return dashboard.recentActivity;
  },
);

// Provider para próximos treinos
final trainerUpcomingWorkoutsProvider =
    FutureProvider.autoDispose<List<UpcomingWorkout>>(
  (ref) async {
    final dashboard = await ref.watch(trainerDashboardProvider.future);
    return dashboard.upcomingWorkouts;
  },
);
