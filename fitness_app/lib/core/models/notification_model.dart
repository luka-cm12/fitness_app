import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String title;
  final String message;
  @JsonKey(name: 'notification_type')
  final NotificationType notificationType;
  final NotificationPriority priority;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  @JsonKey(name: 'action_url')
  final String? actionUrl;
  @JsonKey(name: 'action_data')
  final Map<String, dynamic>? actionData;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @JsonKey(name: 'sender_id')
  final int? senderId;
  @JsonKey(name: 'sender_name')
  final String? senderName;
  @JsonKey(name: 'sender_image')
  final String? senderImage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.priority,
    required this.isRead,
    required this.isDeleted,
    this.actionUrl,
    this.actionData,
    this.imageUrl,
    this.expiresAt,
    this.senderId,
    this.senderName,
    this.senderImage,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? notificationType,
    NotificationPriority? priority,
    bool? isRead,
    bool? isDeleted,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    String? imageUrl,
    DateTime? expiresAt,
    int? senderId,
    String? senderName,
    String? senderImage,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      actionUrl: actionUrl ?? this.actionUrl,
      actionData: actionData ?? this.actionData,
      imageUrl: imageUrl ?? this.imageUrl,
      expiresAt: expiresAt ?? this.expiresAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasAction => actionUrl != null || actionData != null;
  bool get hasSender => senderId != null;
}

@JsonEnum(valueField: 'value')
enum NotificationType {
  workout('workout'),
  nutrition('nutrition'),
  reminder('reminder'),
  approval('approval'),
  system('system'),
  message('message'),
  subscription('subscription'),
  progress('progress'),
  achievement('achievement');

  const NotificationType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationType.workout:
        return 'Treino';
      case NotificationType.nutrition:
        return 'Nutrição';
      case NotificationType.reminder:
        return 'Lembrete';
      case NotificationType.approval:
        return 'Aprovação';
      case NotificationType.system:
        return 'Sistema';
      case NotificationType.message:
        return 'Mensagem';
      case NotificationType.subscription:
        return 'Assinatura';
      case NotificationType.progress:
        return 'Progresso';
      case NotificationType.achievement:
        return 'Conquista';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.workout:
        return '🏋️';
      case NotificationType.nutrition:
        return '🥗';
      case NotificationType.reminder:
        return '⏰';
      case NotificationType.approval:
        return '✅';
      case NotificationType.system:
        return '⚙️';
      case NotificationType.message:
        return '💬';
      case NotificationType.subscription:
        return '💳';
      case NotificationType.progress:
        return '📈';
      case NotificationType.achievement:
        return '🏆';
    }
  }
}

@JsonEnum(valueField: 'value')
enum NotificationPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Baixa';
      case NotificationPriority.medium:
        return 'Média';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }
}

@JsonSerializable()
class NotificationResponse {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;
  @JsonKey(name: 'unread_count')
  final int unreadCount;

  const NotificationResponse({
    required this.notifications,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationResponseToJson(this);
}

@JsonSerializable()
class NotificationPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const NotificationPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) =>
      _$NotificationPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPaginationToJson(this);
}

@JsonSerializable()
class NotificationStats {
  final NotificationOverallStats overall;
  @JsonKey(name: 'by_type')
  final List<NotificationTypeStats> byType;

  const NotificationStats({
    required this.overall,
    required this.byType,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) =>
      _$NotificationStatsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationStatsToJson(this);
}

@JsonSerializable()
class NotificationOverallStats {
  final int total;
  final int unread;
  @JsonKey(name: 'high_priority')
  final int highPriority;

  const NotificationOverallStats({
    required this.total,
    required this.unread,
    required this.highPriority,
  });

  factory NotificationOverallStats.fromJson(Map<String, dynamic> json) =>
      _$NotificationOverallStatsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationOverallStatsToJson(this);
}

@JsonSerializable()
class NotificationTypeStats {
  @JsonKey(name: 'notification_type')
  final String notificationType;
  final int total;
  final int unread;

  const NotificationTypeStats({
    required this.notificationType,
    required this.total,
    required this.unread,
  });

  factory NotificationTypeStats.fromJson(Map<String, dynamic> json) =>
      _$NotificationTypeStatsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTypeStatsToJson(this);
}
