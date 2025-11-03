import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/models/notification_model_simple.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:3000/api/notifications';

  static Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    NotificationType? type,
    bool unreadOnly = false,
  }) async {
    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (type != null) 'type': type.name,
          if (unreadOnly) 'unread_only': 'true',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationResponse.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar notificações');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<void> markAsRead(int notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
            error['message'] ?? 'Erro ao marcar notificação como lida');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ??
            'Erro ao marcar todas as notificações como lidas');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao deletar notificação');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<NotificationStats> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationStats.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao buscar estatísticas');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<NotificationModel> createNotification({
    required int userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    String? imageUrl,
    DateTime? expiresAt,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'title': title,
        'message': message,
        'notification_type': type.name,
        'priority': priority.name,
        if (actionUrl != null) 'action_url': actionUrl,
        if (actionData != null) 'action_data': actionData,
        if (imageUrl != null) 'image_url': imageUrl,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return NotificationModel.fromJson(data['data']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erro ao criar notificação');
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  static Future<String> _getAuthToken() async {
    const storage = FlutterSecureStorage();
    const tokenKey = 'auth_token';
    return await storage.read(key: tokenKey) ?? '';
  }
}
