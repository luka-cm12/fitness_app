import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// Provider para planos de nutrição
final nutritionPlansProvider =
    FutureProvider.family<List<NutritionPlan>, NutritionParams>(
        (ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getNutritionPlans(
    page: params.page,
    limit: params.limit,
  );
  return response.data;
});

// Provider para busca de alimentos
final searchFoodsProvider =
    FutureProvider.family<List<Food>, String>((ref, query) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.searchFoods(query);
  return response.data;
});

// Provider para registrar alimento
final logFoodProvider =
    FutureProvider.family<bool, Map<String, dynamic>>((ref, foodLog) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    await apiService.logFood(foodLog);
    return true;
  } catch (e) {
    throw Exception('Erro ao registrar alimento: $e');
  }
});

// Classes de parâmetros
class NutritionParams {
  final int page;
  final int limit;

  const NutritionParams({
    this.page = 1,
    this.limit = 20,
  });
}
