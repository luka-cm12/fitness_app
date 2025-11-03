import 'package:json_annotation/json_annotation.dart';

part 'athlete_model.g.dart';

@JsonSerializable()
class Athlete {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'trainer_id')
  final int? trainerId;
  final String? goals;
  @JsonKey(name: 'fitness_level')
  final String? fitnessLevel;
  @JsonKey(name: 'medical_conditions')
  final String? medicalConditions;
  @JsonKey(name: 'subscription_status')
  final String subscriptionStatus;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // User info from join
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;
  final String? phone;

  // Statistics
  @JsonKey(name: 'total_workouts')
  final int? totalWorkouts;
  @JsonKey(name: 'completed_workouts')
  final int? completedWorkouts;
  @JsonKey(name: 'workout_streak')
  final int? workoutStreak;
  @JsonKey(name: 'last_workout_date')
  final DateTime? lastWorkoutDate;

  Athlete({
    required this.id,
    required this.userId,
    this.trainerId,
    this.goals,
    this.fitnessLevel,
    this.medicalConditions,
    required this.subscriptionStatus,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.totalWorkouts,
    this.completedWorkouts,
    this.workoutStreak,
    this.lastWorkoutDate,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) =>
      _$AthleteFromJson(json);
  Map<String, dynamic> toJson() => _$AthleteToJson(this);

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

@JsonSerializable()
class TrainerStats {
  @JsonKey(name: 'total_athletes')
  final int totalAthletes;
  @JsonKey(name: 'workouts_this_week')
  final int workoutsThisWeek;
  @JsonKey(name: 'completed_this_week')
  final int completedThisWeek;
  @JsonKey(name: 'workout_templates')
  final int workoutTemplates;
  @JsonKey(name: 'completion_rate')
  final int completionRate;

  TrainerStats({
    required this.totalAthletes,
    required this.workoutsThisWeek,
    required this.completedThisWeek,
    required this.workoutTemplates,
    required this.completionRate,
  });

  factory TrainerStats.fromJson(Map<String, dynamic> json) =>
      _$TrainerStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TrainerStatsToJson(this);
}

@JsonSerializable()
class RecentActivity {
  final int id;
  final String status;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'athlete_name')
  final String athleteName;

  RecentActivity({
    required this.id,
    required this.status,
    required this.scheduledDate,
    this.completedAt,
    required this.workoutName,
    required this.athleteName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityFromJson(json);
  Map<String, dynamic> toJson() => _$RecentActivityToJson(this);
}

@JsonSerializable()
class UpcomingWorkout {
  final int id;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'workout_name')
  final String workoutName;
  @JsonKey(name: 'difficulty_level')
  final String difficultyLevel;
  @JsonKey(name: 'athlete_name')
  final String athleteName;

  UpcomingWorkout({
    required this.id,
    required this.scheduledDate,
    required this.workoutName,
    required this.difficultyLevel,
    required this.athleteName,
  });

  factory UpcomingWorkout.fromJson(Map<String, dynamic> json) =>
      _$UpcomingWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$UpcomingWorkoutToJson(this);
}

@JsonSerializable()
class TrainerDashboard {
  final TrainerStats stats;
  @JsonKey(name: 'recent_activity')
  final List<RecentActivity> recentActivity;
  @JsonKey(name: 'upcoming_workouts')
  final List<UpcomingWorkout> upcomingWorkouts;

  TrainerDashboard({
    required this.stats,
    required this.recentActivity,
    required this.upcomingWorkouts,
  });

  factory TrainerDashboard.fromJson(Map<String, dynamic> json) =>
      _$TrainerDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$TrainerDashboardToJson(this);
}
