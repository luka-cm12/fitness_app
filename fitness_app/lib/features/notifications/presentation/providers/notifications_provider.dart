import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/models/notification_model_simple.dart';
import '../../services/notification_service.dart';

// Provider para gerenciar o estado das notificações
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

// Provider para contar notificações não lidas
final unreadCountProvider = StateProvider<int>((ref) => 0);

// Estados possíveis das notificações
enum NotificationsStatus { initial, loading, loaded, error }

// Estado das notificações
class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationModel> notifications;
  final List<NotificationModel> filteredNotifications;
  final NotificationType? selectedFilter;
  final bool unreadOnly;
  final int unreadCount;
  final String? error;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.filteredNotifications = const [],
    this.selectedFilter,
    this.unreadOnly = false,
    this.unreadCount = 0,
    this.error,
  });

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? notifications,
    List<NotificationModel>? filteredNotifications,
    NotificationType? selectedFilter,
    bool? unreadOnly,
    int? unreadCount,
    String? error,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      filteredNotifications:
          filteredNotifications ?? this.filteredNotifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error ?? this.error,
    );
  }
}

// Notifier para gerenciar o estado das notificações
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  // Carregar notificações
  Future<void> loadNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    state = state.copyWith(status: NotificationsStatus.loading);

    try {
      final response = await NotificationService.getNotifications(
        page: page,
        limit: limit,
        type: state.selectedFilter,
        unreadOnly: state.unreadOnly,
      );

      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: response.notifications,
        filteredNotifications: response.notifications,
        unreadCount: response.unreadCount,
      );
    } catch (error) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        error: error.toString(),
      );
    }
  }

  // Aplicar filtro por tipo
  void applyFilter(NotificationType? type) {
    state = state.copyWith(
      selectedFilter: type,
      unreadOnly: false,
    );
    loadNotifications();
  }

  // Filtrar apenas não lidas
  void setUnreadOnly(bool unreadOnly) {
    state = state.copyWith(
      unreadOnly: unreadOnly,
      selectedFilter: null,
    );
    loadNotifications();
  }

  // Marcar notificação como lida
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await NotificationService.markAsRead(notification.id);

      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notification.id) {
          return n.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      final updatedFilteredNotifications = state.filteredNotifications.map((n) {
        if (n.id == notification.id) {
          return n.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        filteredNotifications: updatedFilteredNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Marcar todas como lidas
  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await loadNotifications();
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Excluir notificação
  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await NotificationService.deleteNotification(notification.id);

      final updatedNotifications =
          state.notifications.where((n) => n.id != notification.id).toList();
      final updatedFilteredNotifications = state.filteredNotifications
          .where((n) => n.id != notification.id)
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        filteredNotifications: updatedFilteredNotifications,
        unreadCount: !notification.isRead && state.unreadCount > 0
            ? state.unreadCount - 1
            : state.unreadCount,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Limpar erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}
