import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/notification_model_simple.dart';

class NotificationsPageSimple extends ConsumerStatefulWidget {
  const NotificationsPageSimple({super.key});

  @override
  ConsumerState<NotificationsPageSimple> createState() =>
      _NotificationsPageSimpleState();
}

class _NotificationsPageSimpleState
    extends ConsumerState<NotificationsPageSimple>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Dados mockados para demonstração
    setState(() {
      _notifications = [
        NotificationModel(
          id: 1,
          userId: 1,
          title: 'Novo treino disponível',
          message:
              'Seu personal trainer criou um novo treino para você. Confira agora!',
          notificationType: NotificationType.workout,
          priority: NotificationPriority.high,
          isRead: false,
          isDeleted: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          actionUrl: '/workouts/123',
        ),
        NotificationModel(
          id: 2,
          userId: 1,
          title: 'Meta de água alcançada',
          message: 'Parabéns! Você alcançou sua meta diária de água.',
          notificationType: NotificationType.achievement,
          priority: NotificationPriority.medium,
          isRead: false,
          isDeleted: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: 3,
          userId: 1,
          title: 'Lembrete: Refeição pós-treino',
          message:
              'Não esqueça de fazer sua refeição pós-treino rica em proteínas.',
          notificationType: NotificationType.reminder,
          priority: NotificationPriority.medium,
          isRead: true,
          isDeleted: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          readAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        NotificationModel(
          id: 4,
          userId: 1,
          title: 'Atualização do sistema',
          message:
              'Nova versão do aplicativo disponível com melhorias de performance.',
          notificationType: NotificationType.system,
          priority: NotificationPriority.low,
          isRead: true,
          isDeleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          readAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
      _isLoading = false;
    });
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_tabController.index) {
      case 1: // Não lidas
        return _notifications.where((n) => !n.isRead).toList();
      case 2: // Sistema
        return _notifications
            .where((n) => n.notificationType == NotificationType.system)
            .toList();
      default: // Todas
        return _notifications;
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(
                isRead: true,
                readAt: n.readAt ?? DateTime.now(),
              ))
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas as notificações marcadas como lidas'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação excluída'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    if (notification.actionUrl != null) {
      // Navegar para a URL de ação
      context.push(notification.actionUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filteredNotifications;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6C63FF)),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFF6C63FF)),
              onPressed: _markAllAsRead,
              tooltip: 'Marcar todas como lidas',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
            onPressed: _loadMockData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey[600],
          onTap: (_) =>
              setState(() {}), // Rebuild para atualizar lista filtrada
          tabs: [
            const Tab(text: 'Todas'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não Lidas'),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Sistema'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadMockData(),
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas notificações aparecerão aqui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: !notification.isRead
            ? const BorderSide(color: Color(0xFF6C63FF), width: 1)
            : BorderSide.none,
      ),
      child: Dismissible(
        key: Key('notification_${notification.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 24,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir Notificação'),
                  content: const Text(
                      'Tem certeza que deseja excluir esta notificação?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (direction) {
          _deleteNotification(notification);
        },
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.notificationType)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      notification.notificationType.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C63FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Footer info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getTypeColor(notification.notificationType)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              notification.notificationType.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getTypeColor(
                                    notification.notificationType),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('dd/MM HH:mm')
                                .format(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.workout:
        return Colors.blue;
      case NotificationType.nutrition:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.approval:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey[700]!;
      case NotificationType.message:
        return Colors.cyan;
      case NotificationType.subscription:
        return Colors.amber;
      case NotificationType.progress:
        return Colors.teal;
      case NotificationType.achievement:
        return Colors.yellow[700]!;
    }
  }
}
