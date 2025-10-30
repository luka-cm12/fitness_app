// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_service.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _ApiService implements ApiService {
  _ApiService(
    this._dio, {
    this.baseUrl,
  });

  final Dio _dio;

  String? baseUrl;

  @override
  Future<ApiResponse<User>> getCurrentUser() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final Map<String, dynamic>? _data = null;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<ApiResponse<User>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
            .compose(
              _dio.options,
              '/auth/me',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = ApiResponse<User>.fromJson(
      _result.data!,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  @override
  Future<ApiResponse<void>> completeWorkout(
      int workoutId, Map<String, dynamic> completionData) {
    // TODO: implement completeWorkout
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<AssignedWorkout>>> getAssignedWorkouts(
      {int page = 1, int limit = 20, String? status}) {
    // TODO: implement getAssignedWorkouts
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<NutritionPlan>>> getNutritionPlans(
      {int page = 1, int limit = 20}) {
    // TODO: implement getNutritionPlans
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<WorkoutTemplate>>> getWorkoutTemplates(
      {int page = 1,
      int limit = 20,
      String? category,
      String? difficultyLevel}) {
    // TODO: implement getWorkoutTemplates
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> logFood(Map<String, dynamic> foodLog) {
    // TODO: implement logFood
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AuthResponse>> login(String email, String password) {
    // TODO: implement login
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AuthResponse>> register(
      {required String email,
      required String password,
      required String firstName,
      required String lastName,
      required UserType userType,
      String? phone}) {
    // TODO: implement register
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<Food>>> searchFoods(String query) {
    // TODO: implement searchFoods
    throw UnimplementedError();
  }
}
