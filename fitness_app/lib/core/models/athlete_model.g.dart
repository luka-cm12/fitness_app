// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'athlete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Athlete _$AthleteFromJson(Map<String, dynamic> json) => Athlete(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      trainerId: (json['trainer_id'] as num?)?.toInt(),
      goals: json['goals'] as String?,
      fitnessLevel: json['fitness_level'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
      subscriptionStatus: json['subscription_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt(),
      completedWorkouts: (json['completed_workouts'] as num?)?.toInt(),
      workoutStreak: (json['workout_streak'] as num?)?.toInt(),
      lastWorkoutDate: json['last_workout_date'] == null
          ? null
          : DateTime.parse(json['last_workout_date'] as String),
    );

Map<String, dynamic> _$AthleteToJson(Athlete instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'trainer_id': instance.trainerId,
      'goals': instance.goals,
      'fitness_level': instance.fitnessLevel,
      'medical_conditions': instance.medicalConditions,
      'subscription_status': instance.subscriptionStatus,
      'created_at': instance.createdAt.toIso8601String(),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'total_workouts': instance.totalWorkouts,
      'completed_workouts': instance.completedWorkouts,
      'workout_streak': instance.workoutStreak,
      'last_workout_date': instance.lastWorkoutDate?.toIso8601String(),
    };

TrainerStats _$TrainerStatsFromJson(Map<String, dynamic> json) => TrainerStats(
      totalAthletes: (json['total_athletes'] as num).toInt(),
      workoutsThisWeek: (json['workouts_this_week'] as num).toInt(),
      completedThisWeek: (json['completed_this_week'] as num).toInt(),
      workoutTemplates: (json['workout_templates'] as num).toInt(),
      completionRate: (json['completion_rate'] as num).toInt(),
    );

Map<String, dynamic> _$TrainerStatsToJson(TrainerStats instance) =>
    <String, dynamic>{
      'total_athletes': instance.totalAthletes,
      'workouts_this_week': instance.workoutsThisWeek,
      'completed_this_week': instance.completedThisWeek,
      'workout_templates': instance.workoutTemplates,
      'completion_rate': instance.completionRate,
    };

RecentActivity _$RecentActivityFromJson(Map<String, dynamic> json) =>
    RecentActivity(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      workoutName: json['workout_name'] as String,
      athleteName: json['athlete_name'] as String,
    );

Map<String, dynamic> _$RecentActivityToJson(RecentActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'workout_name': instance.workoutName,
      'athlete_name': instance.athleteName,
    };

UpcomingWorkout _$UpcomingWorkoutFromJson(Map<String, dynamic> json) =>
    UpcomingWorkout(
      id: (json['id'] as num).toInt(),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      workoutName: json['workout_name'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      athleteName: json['athlete_name'] as String,
    );

Map<String, dynamic> _$UpcomingWorkoutToJson(UpcomingWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'workout_name': instance.workoutName,
      'difficulty_level': instance.difficultyLevel,
      'athlete_name': instance.athleteName,
    };

TrainerDashboard _$TrainerDashboardFromJson(Map<String, dynamic> json) =>
    TrainerDashboard(
      stats: TrainerStats.fromJson(json['stats'] as Map<String, dynamic>),
      recentActivity: (json['recent_activity'] as List<dynamic>)
          .map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingWorkouts: (json['upcoming_workouts'] as List<dynamic>)
          .map((e) => UpcomingWorkout.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TrainerDashboardToJson(TrainerDashboard instance) =>
    <String, dynamic>{
      'stats': instance.stats,
      'recent_activity': instance.recentActivity,
      'upcoming_workouts': instance.upcomingWorkouts,
    };
