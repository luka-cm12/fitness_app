import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_model.dart';
import '../utils/storage_service.dart';

part 'api_service.g.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = Dio();

  // Add interceptor for authentication
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return ApiService(dio, baseUrl: 'http://localhost:3000/api');
});

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  // Auth endpoints
  @POST('/auth/login')
  Future<ApiResponse<AuthResponse>> login(
    @Field() String email,
    @Field() String password,
  );

  @POST('/auth/register')
  Future<ApiResponse<AuthResponse>> register({
    @Field() required String email,
    @Field() required String password,
    @Field('first_name') required String firstName,
    @Field('last_name') required String lastName,
    @Field('user_type') required UserType userType,
    @Field() String? phone,
  });

  @GET('/users/profile')
  Future<User> getCurrentUser();

  // Workouts endpoints
  @GET('/workouts/templates')
  Future<ApiResponse<List<WorkoutTemplate>>> getWorkoutTemplates({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('category') String? category,
    @Query('difficulty_level') String? difficultyLevel,
  });

  @GET('/workouts/assigned')
  Future<ApiResponse<List<AssignedWorkout>>> getAssignedWorkouts({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('status') String? status,
  });

  @PUT('/athletes/workouts/{id}/complete')
  Future<ApiResponse<void>> completeWorkout(
    @Path('id') int workoutId,
    @Body() Map<String, dynamic> completionData,
  );

  // Nutrition endpoints
  @GET('/nutrition/plans')
  Future<ApiResponse<List<NutritionPlan>>> getNutritionPlans({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  @GET('/nutrition/foods/search')
  Future<ApiResponse<List<Food>>> searchFoods(@Query('q') String query);

  @POST('/nutrition/log')
  Future<ApiResponse<void>> logFood(@Body() Map<String, dynamic> foodLog);
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT(json['data']),
    );
  }
}

// Placeholder models - these should be in separate files
class WorkoutTemplate {
  final int id;
  final String name;
  final String? description;
  final String difficultyLevel;
  final int durationMinutes;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.difficultyLevel,
    required this.durationMinutes,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      difficultyLevel: json['difficulty_level'],
      durationMinutes: json['duration_minutes'],
    );
  }
}

class AssignedWorkout {
  final int id;
  final String status;
  final DateTime scheduledDate;
  final String workoutName;

  AssignedWorkout({
    required this.id,
    required this.status,
    required this.scheduledDate,
    required this.workoutName,
  });

  factory AssignedWorkout.fromJson(Map<String, dynamic> json) {
    return AssignedWorkout(
      id: json['id'],
      status: json['status'],
      scheduledDate: DateTime.parse(json['scheduled_date']),
      workoutName: json['workout_name'],
    );
  }
}

class NutritionPlan {
  final int id;
  final String name;
  final int totalCalories;

  NutritionPlan({
    required this.id,
    required this.name,
    required this.totalCalories,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'],
      name: json['name'],
      totalCalories: json['total_calories'],
    );
  }
}

class Food {
  final int id;
  final String name;
  final double caloriesPerServing;

  Food({
    required this.id,
    required this.name,
    required this.caloriesPerServing,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      caloriesPerServing: json['calories_per_serving'].toDouble(),
    );
  }
}
