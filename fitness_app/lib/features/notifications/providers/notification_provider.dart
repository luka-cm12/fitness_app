import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/utils/storage_service.dart';

// Provider para o serviço de notificações
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider para notificações do usuário
final notificationsProvider =
    FutureProvider.family<NotificationResponse, NotificationParams>(
        (ref, params) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotifications(
    page: params.page,
    limit: params.limit,
    type: params.type,
    unreadOnly: params.unreadOnly,
  );
});

// Provider para estatísticas de notificações
final notificationStatsProvider =
    FutureProvider<NotificationStats>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return service.getNotificationStats();
});

// Provider para marcar notificação como lida
final markAsReadProvider =
    FutureProvider.family<bool, int>((ref, notificationId) async {
  final service = ref.watch(notificationServiceProvider);
  try {
    await service.markAsRead(notificationId);
    return true;
  } catch (e) {
    throw Exception('Erro ao marcar como lida: $e');
  }
});

// Serviço de notificações
class NotificationService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000/api';

  NotificationService() {
    _dio.interceptors.add(
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
  }

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (type != null) queryParams['type'] = type;
    if (unreadOnly) queryParams['unread_only'] = 'true';

    final response = await _dio.get(
      '$_baseUrl/notifications',
      queryParameters: queryParams,
    );

    return NotificationResponse.fromJson(response.data['data']);
  }

  Future<NotificationStats> getNotificationStats() async {
    final response = await _dio.get('$_baseUrl/notifications/stats');
    return NotificationStats.fromJson(response.data['data']);
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.put('$_baseUrl/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.put('$_baseUrl/notifications/mark-all-read');
  }

  Future<void> deleteNotification(int notificationId) async {
    await _dio.delete('$_baseUrl/notifications/$notificationId');
  }

  Future<NotificationModel> getNotification(int notificationId) async {
    final response = await _dio.get('$_baseUrl/notifications/$notificationId');
    return NotificationModel.fromJson(response.data['data']);
  }
}

// Parâmetros para busca de notificações
class NotificationParams {
  final int page;
  final int limit;
  final String? type;
  final bool unreadOnly;

  const NotificationParams({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.unreadOnly = false,
  });
}
