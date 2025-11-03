// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType:
          $enumDecode(_$NotificationTypeEnumMap, json['notification_type']),
      priority: $enumDecode(_$NotificationPriorityEnumMap, json['priority']),
      isRead: json['is_read'] as bool,
      isDeleted: json['is_deleted'] as bool,
      actionUrl: json['action_url'] as String?,
      actionData: json['action_data'] as Map<String, dynamic>?,
      imageUrl: json['image_url'] as String?,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      senderId: (json['sender_id'] as num?)?.toInt(),
      senderName: json['sender_name'] as String?,
      senderImage: json['sender_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'title': instance.title,
      'message': instance.message,
      'notification_type':
          _$NotificationTypeEnumMap[instance.notificationType]!,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'is_read': instance.isRead,
      'is_deleted': instance.isDeleted,
      'action_url': instance.actionUrl,
      'action_data': instance.actionData,
      'image_url': instance.imageUrl,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'sender_id': instance.senderId,
      'sender_name': instance.senderName,
      'sender_image': instance.senderImage,
      'created_at': instance.createdAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.workout: 'workout',
  NotificationType.nutrition: 'nutrition',
  NotificationType.reminder: 'reminder',
  NotificationType.approval: 'approval',
  NotificationType.system: 'system',
  NotificationType.message: 'message',
  NotificationType.subscription: 'subscription',
  NotificationType.progress: 'progress',
  NotificationType.achievement: 'achievement',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.medium: 'medium',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};

NotificationResponse _$NotificationResponseFromJson(
        Map<String, dynamic> json) =>
    NotificationResponse(
      notifications: (json['notifications'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: NotificationPagination.fromJson(
          json['pagination'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationResponseToJson(
        NotificationResponse instance) =>
    <String, dynamic>{
      'notifications': instance.notifications,
      'pagination': instance.pagination,
      'unread_count': instance.unreadCount,
    };

NotificationPagination _$NotificationPaginationFromJson(
        Map<String, dynamic> json) =>
    NotificationPagination(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationPaginationToJson(
        NotificationPagination instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'pages': instance.pages,
    };

NotificationStats _$NotificationStatsFromJson(Map<String, dynamic> json) =>
    NotificationStats(
      overall: NotificationOverallStats.fromJson(
          json['overall'] as Map<String, dynamic>),
      byType: (json['by_type'] as List<dynamic>)
          .map((e) => NotificationTypeStats.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$NotificationStatsToJson(NotificationStats instance) =>
    <String, dynamic>{
      'overall': instance.overall,
      'by_type': instance.byType,
    };

NotificationOverallStats _$NotificationOverallStatsFromJson(
        Map<String, dynamic> json) =>
    NotificationOverallStats(
      total: (json['total'] as num).toInt(),
      unread: (json['unread'] as num).toInt(),
      highPriority: (json['high_priority'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationOverallStatsToJson(
        NotificationOverallStats instance) =>
    <String, dynamic>{
      'total': instance.total,
      'unread': instance.unread,
      'high_priority': instance.highPriority,
    };

NotificationTypeStats _$NotificationTypeStatsFromJson(
        Map<String, dynamic> json) =>
    NotificationTypeStats(
      notificationType: json['notification_type'] as String,
      total: (json['total'] as num).toInt(),
      unread: (json['unread'] as num).toInt(),
    );

Map<String, dynamic> _$NotificationTypeStatsToJson(
        NotificationTypeStats instance) =>
    <String, dynamic>{
      'notification_type': instance.notificationType,
      'total': instance.total,
      'unread': instance.unread,
    };
