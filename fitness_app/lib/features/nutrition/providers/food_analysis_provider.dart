import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'dart:io';
import '../../../core/services/food_analysis_service.dart';
import '../../../core/models/food_analysis_model.dart';

// Provider para o serviço de análise
final foodAnalysisServiceProvider = Provider<FoodAnalysisService>((ref) {
  return FoodAnalysisService();
});

// Provider para análise de imagem
final analyzeFoodProvider =
    FutureProvider.family<FoodAnalysisModel?, File>((ref, imageFile) async {
  final service = ref.watch(foodAnalysisServiceProvider);
  return service.analyzeFood(imageFile);
});

// Provider para histórico de análises
final analysisHistoryProvider =
    FutureProvider.family<List<FoodAnalysisModel>, AnalysisHistoryParams>(
        (ref, params) async {
  final service = ref.watch(foodAnalysisServiceProvider);
  return service.getFullAnalysisHistory(
    page: params.page,
    limit: params.limit,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// Provider para deletar análise
final deleteAnalysisProvider =
    FutureProvider.family<bool, int>((ref, analysisId) async {
  final service = ref.watch(foodAnalysisServiceProvider);
  return service.deleteAnalysis(analysisId);
});

// Estados da análise
sealed class AnalysisState {
  const AnalysisState();

  const factory AnalysisState.initial() = AnalysisStateInitial;
  const factory AnalysisState.selecting() = AnalysisStateSelecting;
  const factory AnalysisState.analyzing() = AnalysisStateAnalyzing;
  const factory AnalysisState.completed(FoodAnalysisModel analysis) =
      AnalysisStateCompleted;
  const factory AnalysisState.error(String message) = AnalysisStateError;
}

class AnalysisStateInitial extends AnalysisState {
  const AnalysisStateInitial();
}

class AnalysisStateSelecting extends AnalysisState {
  const AnalysisStateSelecting();
}

class AnalysisStateAnalyzing extends AnalysisState {
  const AnalysisStateAnalyzing();
}

class AnalysisStateCompleted extends AnalysisState {
  final FoodAnalysisModel analysis;
  const AnalysisStateCompleted(this.analysis);
}

class AnalysisStateError extends AnalysisState {
  final String message;
  const AnalysisStateError(this.message);
}

// Parâmetros para histórico de análises
class AnalysisHistoryParams {
  final int page;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const AnalysisHistoryParams({
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
  });
}
