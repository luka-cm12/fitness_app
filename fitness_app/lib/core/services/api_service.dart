import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_model.dart';
import '../models/exercise_model.dart';
import '../models/athlete_model.dart';
import '../utils/storage_service.dart';

part 'api_service.g.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = Dio();

  // Configure Dio for web CORS
  dio.options.headers['Content-Type'] = 'application/json';
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);

  // Add interceptor for authentication and debugging
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print('📡 API Request: ${options.method} ${options.uri}');
        print('📡 Headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (DioException error, handler) {
        print('❌ API Error: ${error.message}');
        print('❌ Error Type: ${error.type}');
        if (error.response != null) {
          print('❌ Status Code: ${error.response!.statusCode}');
          print('❌ Response Data: ${error.response!.data}');
        }
        handler.next(error);
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
  Future<HttpResponse<void>> completeWorkout(
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
  Future<HttpResponse<void>> logFood(@Body() Map<String, dynamic> foodLog);

  // Exercises endpoints
  @GET('/exercises')
  Future<ApiResponse<List<Exercise>>> getExercises({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('category') String? category,
    @Query('difficulty_level') String? difficultyLevel,
    @Query('search') String? search,
  });

  @GET('/exercises/{id}')
  Future<Exercise> getExercise(@Path('id') int id);

  // Workout Template management
  @POST('/workouts/templates')
  Future<ApiResponse<WorkoutTemplate>> createWorkoutTemplate(
    @Body() CreateWorkoutTemplateRequest request,
  );

  @GET('/workouts/templates/{id}')
  Future<ApiResponse<WorkoutTemplate>> getWorkoutTemplate(@Path('id') int id);

  @POST('/workouts/assign')
  Future<ApiResponse<AssignedWorkout>> assignWorkout(
      @Body() Map<String, dynamic> data);

  // Trainer specific endpoints
  @GET('/trainers/dashboard')
  Future<HttpResponse<dynamic>> getTrainerDashboard();

  @GET('/trainers/athletes')
  Future<ApiResponse<List<Athlete>>> getTrainerAthletes({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });
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
