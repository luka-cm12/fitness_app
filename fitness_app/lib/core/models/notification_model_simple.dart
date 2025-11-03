class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final NotificationType notificationType;
  final NotificationPriority priority;
  final bool isRead;
  final bool isDeleted;
  final String? actionUrl;
  final Map<String, dynamic>? actionData;
  final String? imageUrl;
  final DateTime? expiresAt;
  final int? senderId;
  final String? senderName;
  final String? senderImage;
  final DateTime createdAt;
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

  // Getters de conveniência
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isHighPriority =>
      priority == NotificationPriority.high ||
      priority == NotificationPriority.urgent;
  bool get hasSender => senderId != null && senderName != null;
  bool get hasAction => actionUrl != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>?,
      imageUrl: json['image_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      senderId: json['sender_id'] as int?,
      senderName: json['sender_name'] as String?,
      senderImage: json['sender_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': notificationType.name,
      'priority': priority.name,
      'is_read': isRead,
      'is_deleted': isDeleted,
      'action_url': actionUrl,
      'action_data': actionData,
      'image_url': imageUrl,
      'expires_at': expiresAt?.toIso8601String(),
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_image': senderImage,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

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
}

// Enums para tipos de notificação
enum NotificationType {
  workout('workout', '💪', 'Treino'),
  nutrition('nutrition', '🥗', 'Nutrição'),
  reminder('reminder', '⏰', 'Lembrete'),
  message('message', '💬', 'Mensagem'),
  approval('approval', '✅', 'Aprovação'),
  system('system', '🔧', 'Sistema'),
  subscription('subscription', '💳', 'Assinatura'),
  progress('progress', '📊', 'Progresso'),
  achievement('achievement', '🏆', 'Conquista');

  const NotificationType(this.name, this.icon, this.displayName);

  final String name;
  final String icon;
  final String displayName;
}

// Enums para prioridade
enum NotificationPriority {
  low('low', 'Baixa'),
  medium('medium', 'Média'),
  high('high', 'Alta'),
  urgent('urgent', 'Urgente');

  const NotificationPriority(this.name, this.displayName);

  final String name;
  final String displayName;
}

// Classes para resposta da API
class NotificationResponse {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;
  final int unreadCount;

  const NotificationResponse({
    required this.notifications,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['data'] as List)
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: NotificationPagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': notifications.map((n) => n.toJson()).toList(),
      'pagination': pagination.toJson(),
      'unread_count': unreadCount,
    };
  }
}

class NotificationPagination {
  final int currentPage;
  final int totalPages;
  final int perPage;
  final int total;

  const NotificationPagination({
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.total,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_pages': totalPages,
      'per_page': perPage,
      'total': total,
    };
  }
}

class NotificationStats {
  final int total;
  final int unread;
  final int today;
  final int thisWeek;

  const NotificationStats({
    required this.total,
    required this.unread,
    required this.today,
    required this.thisWeek,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int,
      unread: json['unread'] as int,
      today: json['today'] as int,
      thisWeek: json['this_week'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'today': today,
      'this_week': thisWeek,
    };
  }
}

class NotificationOverallStats {
  final NotificationStats stats;
  final List<NotificationTypeStats> byType;

  const NotificationOverallStats({
    required this.stats,
    required this.byType,
  });

  factory NotificationOverallStats.fromJson(Map<String, dynamic> json) {
    return NotificationOverallStats(
      stats: NotificationStats.fromJson(json['stats'] as Map<String, dynamic>),
      byType: (json['by_type'] as List)
          .map((item) =>
              NotificationTypeStats.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stats': stats.toJson(),
      'by_type': byType.map((item) => item.toJson()).toList(),
    };
  }
}

class NotificationTypeStats {
  final NotificationType type;
  final int count;
  final int unreadCount;

  const NotificationTypeStats({
    required this.type,
    required this.count,
    required this.unreadCount,
  });

  factory NotificationTypeStats.fromJson(Map<String, dynamic> json) {
    return NotificationTypeStats(
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      count: json['count'] as int,
      unreadCount: json['unread_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'count': count,
      'unread_count': unreadCount,
    };
  }
}
