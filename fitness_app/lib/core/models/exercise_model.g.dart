// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: json['category'] as String,
      muscleGroups: json['muscle_groups'] as String,
      equipment: json['equipment'] as String,
      instructions: json['instructions'] as String,
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
      difficultyLevel: json['difficulty_level'] as String,
      createdBy: (json['created_by'] as num?)?.toInt(),
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'muscle_groups': instance.muscleGroups,
      'equipment': instance.equipment,
      'instructions': instance.instructions,
      'video_url': instance.videoUrl,
      'image_url': instance.imageUrl,
      'difficulty_level': instance.difficultyLevel,
      'created_by': instance.createdBy,
      'is_public': instance.isPublic,
      'created_at': instance.createdAt.toIso8601String(),
    };

WorkoutTemplateExercise _$WorkoutTemplateExerciseFromJson(
        Map<String, dynamic> json) =>
    WorkoutTemplateExercise(
      id: (json['id'] as num).toInt(),
      workoutTemplateId: (json['workout_template_id'] as num).toInt(),
      exerciseId: (json['exercise_id'] as num).toInt(),
      sets: (json['sets'] as num?)?.toInt(),
      reps: json['reps'] as String?,
      weight: json['weight'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      orderIndex: (json['order_index'] as num).toInt(),
      notes: json['notes'] as String?,
      exerciseName: json['exercise_name'] as String?,
      exerciseCategory: json['exercise_category'] as String?,
      muscleGroups: json['muscle_groups'] as String?,
      equipment: json['equipment'] as String?,
      instructions: json['instructions'] as String?,
    );

Map<String, dynamic> _$WorkoutTemplateExerciseToJson(
        WorkoutTemplateExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workout_template_id': instance.workoutTemplateId,
      'exercise_id': instance.exerciseId,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight': instance.weight,
      'duration_seconds': instance.durationSeconds,
      'rest_seconds': instance.restSeconds,
      'order_index': instance.orderIndex,
      'notes': instance.notes,
      'exercise_name': instance.exerciseName,
      'exercise_category': instance.exerciseCategory,
      'muscle_groups': instance.muscleGroups,
      'equipment': instance.equipment,
      'instructions': instance.instructions,
    };

WorkoutTemplate _$WorkoutTemplateFromJson(Map<String, dynamic> json) =>
    WorkoutTemplate(
      id: (json['id'] as num).toInt(),
      trainerId: (json['trainer_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      difficultyLevel: json['difficulty_level'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      category: json['category'] as String?,
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      trainerName: json['trainer_name'] as String?,
      exerciseCount: (json['exercise_count'] as num?)?.toInt(),
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) =>
              WorkoutTemplateExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkoutTemplateToJson(WorkoutTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trainer_id': instance.trainerId,
      'name': instance.name,
      'description': instance.description,
      'difficulty_level': instance.difficultyLevel,
      'duration_minutes': instance.durationMinutes,
      'category': instance.category,
      'is_public': instance.isPublic,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'trainer_name': instance.trainerName,
      'exercise_count': instance.exerciseCount,
      'exercises': instance.exercises,
    };

CreateWorkoutTemplateRequest _$CreateWorkoutTemplateRequestFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutTemplateRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      difficultyLevel: json['difficulty_level'] as String,
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      category: json['category'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => CreateWorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreateWorkoutTemplateRequestToJson(
        CreateWorkoutTemplateRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'difficulty_level': instance.difficultyLevel,
      'duration_minutes': instance.durationMinutes,
      'category': instance.category,
      'is_public': instance.isPublic,
      'exercises': instance.exercises,
    };

CreateWorkoutExercise _$CreateWorkoutExerciseFromJson(
        Map<String, dynamic> json) =>
    CreateWorkoutExercise(
      exerciseId: (json['exercise_id'] as num).toInt(),
      sets: (json['sets'] as num?)?.toInt(),
      reps: json['reps'] as String?,
      weight: json['weight'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CreateWorkoutExerciseToJson(
        CreateWorkoutExercise instance) =>
    <String, dynamic>{
      'exercise_id': instance.exerciseId,
      'sets': instance.sets,
      'reps': instance.reps,
      'weight': instance.weight,
      'duration_seconds': instance.durationSeconds,
      'rest_seconds': instance.restSeconds,
      'notes': instance.notes,
    };

AssignedWorkout _$AssignedWorkoutFromJson(Map<String, dynamic> json) =>
    AssignedWorkout(
      id: (json['id'] as num).toInt(),
      athleteId: (json['athlete_id'] as num).toInt(),
      trainerId: (json['trainer_id'] as num).toInt(),
      workoutTemplateId: (json['workout_template_id'] as num).toInt(),
      assignedDate: DateTime.parse(json['assigned_date'] as String),
      scheduledDate: json['scheduled_date'] == null
          ? null
          : DateTime.parse(json['scheduled_date'] as String),
      status: json['status'] as String,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      notes: json['notes'] as String?,
      trainerFeedback: json['trainer_feedback'] as String?,
      workoutName: json['workout_name'] as String?,
      workoutDescription: json['workout_description'] as String?,
      difficultyLevel: json['difficulty_level'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      category: json['category'] as String?,
      athleteName: json['athlete_name'] as String?,
      trainerName: json['trainer_name'] as String?,
    );

Map<String, dynamic> _$AssignedWorkoutToJson(AssignedWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'athlete_id': instance.athleteId,
      'trainer_id': instance.trainerId,
      'workout_template_id': instance.workoutTemplateId,
      'assigned_date': instance.assignedDate.toIso8601String(),
      'scheduled_date': instance.scheduledDate?.toIso8601String(),
      'status': instance.status,
      'completed_at': instance.completedAt?.toIso8601String(),
      'notes': instance.notes,
      'trainer_feedback': instance.trainerFeedback,
      'workout_name': instance.workoutName,
      'workout_description': instance.workoutDescription,
      'difficulty_level': instance.difficultyLevel,
      'duration_minutes': instance.durationMinutes,
      'category': instance.category,
      'athlete_name': instance.athleteName,
      'trainer_name': instance.trainerName,
    };
