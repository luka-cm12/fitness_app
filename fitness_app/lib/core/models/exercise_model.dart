import 'package:json_annotation/json_annotation.dart';

part 'exercise_model.g.dart';

@JsonSerializable()
class Exercise {
  final int id;
  final String name;
  final String category;
  @JsonKey(name: 'muscle_groups')
  final String muscleGroups;
  final String equipment;
  final String instructions;
  @JsonKey(name: 'video_url')
  final String? videoUrl;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  @JsonKey(name: 'created_by')
  final int? createdBy;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroups,
    required this.equipment,
    required this.instructions,
    this.videoUrl,
    this.imageUrl,
    required this.difficultyLevel,
    this.createdBy,
    required this.isPublic,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable()
class WorkoutTemplateExercise {
  final int id;
  @JsonKey(name: 'workout_template_id')
  final int workoutTemplateId;
  @JsonKey(name: 'exercise_id')
  final int exerciseId;
  final int? sets;
  final String? reps;
  final String? weight;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;
  @JsonKey(name: 'order_index')
  final int orderIndex;
  final String? notes;

  // Nested exercise data
  @JsonKey(name: 'exercise_name')
  final String? exerciseName;
  @JsonKey(name: 'exercise_category')
  final String? exerciseCategory;
  @JsonKey(name: 'muscle_groups')
  final String? muscleGroups;
  final String? equipment;
  final String? instructions;

  WorkoutTemplateExercise({
    required this.id,
    required this.workoutTemplateId,
    required this.exerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.restSeconds,
    required this.orderIndex,
    this.notes,
    this.exerciseName,
    this.exerciseCategory,
    this.muscleGroups,
    this.equipment,
    this.instructions,
  });

  factory WorkoutTemplateExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutTemplateExerciseToJson(this);
}

@JsonSerializable()
class WorkoutTemplate {
  final int id;
  @JsonKey(name: 'trainer_id')
  final int trainerId;
  final String name;
  final String? description;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final String? category;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Nested data
  @JsonKey(name: 'trainer_name')
  final String? trainerName;
  @JsonKey(name: 'exercise_count')
  final int? exerciseCount;
  final List<WorkoutTemplateExercise>? exercises;

  WorkoutTemplate({
    required this.id,
    required this.trainerId,
    required this.name,
    this.description,
    required this.difficultyLevel,
    required this.durationMinutes,
    this.category,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.trainerName,
    this.exerciseCount,
    this.exercises,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkoutTemplateFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutTemplateToJson(this);
}

@JsonSerializable()
class CreateWorkoutTemplateRequest {
  final String name;
  final String? description;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  final String? category;
  @JsonKey(name: 'is_public')
  final bool isPublic;
  final List<CreateWorkoutExercise> exercises;

  CreateWorkoutTemplateRequest({
    required this.name,
    this.description,
    required this.difficultyLevel,
    required this.durationMinutes,
    this.category,
    this.isPublic = false,
    required this.exercises,
  });

  factory CreateWorkoutTemplateRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutTemplateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWorkoutTemplateRequestToJson(this);
}

@JsonSerializable()
class CreateWorkoutExercise {
  @JsonKey(name: 'exercise_id')
  final int exerciseId;
  final int? sets;
  final String? reps;
  final String? weight;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;
  @JsonKey(name: 'rest_seconds')
  final int? restSeconds;
  final String? notes;

  CreateWorkoutExercise({
    required this.exerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.restSeconds,
    this.notes,
  });

  factory CreateWorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkoutExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWorkoutExerciseToJson(this);
}

@JsonSerializable()
class AssignedWorkout {
  final int id;
  @JsonKey(name: 'athlete_id')
  final int athleteId;
  @JsonKey(name: 'trainer_id')
  final int trainerId;
  @JsonKey(name: 'workout_template_id')
  final int workoutTemplateId;
  @JsonKey(name: 'assigned_date')
  final DateTime assignedDate;
  @JsonKey(name: 'scheduled_date')
  final DateTime? scheduledDate;
  final String status;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  final String? notes;
  @JsonKey(name: 'trainer_feedback')
  final String? trainerFeedback;

  // Nested data
  @JsonKey(name: 'workout_name')
  final String? workoutName;
  @JsonKey(name: 'workout_description')
  final String? workoutDescription;
  @JsonKey(name: 'difficulty_level')
  final String? difficultyLevel;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  final String? category;
  @JsonKey(name: 'athlete_name')
  final String? athleteName;
  @JsonKey(name: 'trainer_name')
  final String? trainerName;

  AssignedWorkout({
    required this.id,
    required this.athleteId,
    required this.trainerId,
    required this.workoutTemplateId,
    required this.assignedDate,
    this.scheduledDate,
    required this.status,
    this.completedAt,
    this.notes,
    this.trainerFeedback,
    this.workoutName,
    this.workoutDescription,
    this.difficultyLevel,
    this.durationMinutes,
    this.category,
    this.athleteName,
    this.trainerName,
  });

  factory AssignedWorkout.fromJson(Map<String, dynamic> json) =>
      _$AssignedWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$AssignedWorkoutToJson(this);
}
