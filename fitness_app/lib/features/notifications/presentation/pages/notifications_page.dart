import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/notification_model_simple.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Carregar notificações ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final notifier = ref.read(notificationsProvider.notifier);

    switch (_tabController.index) {
      case 0:
        notifier.applyFilter(null);
        break;
      case 1:
        notifier.setUnreadOnly(true);
        break;
      case 2:
        notifier.applyFilter(NotificationType.system);
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas as notificações marcadas como lidas'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.deleteNotification(notification);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação excluída'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    final notifier = ref.read(notificationsProvider.notifier);

    // Marcar como lida
    notifier.markAsRead(notification);

    // Navegar se houver URL de ação
    if (notification.actionUrl != null) {
      // Implementar navegação baseada na URL de ação
      // Por exemplo, /workout/123, /nutrition/456, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

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
          if (state.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFF6C63FF)),
              onPressed: _markAllAsRead,
              tooltip: 'Marcar todas como lidas',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
            onPressed: () =>
                ref.read(notificationsProvider.notifier).loadNotifications(),
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey[600],
          tabs: [
            const Tab(text: 'Todas'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não Lidas'),
                  if (state.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        state.unreadCount.toString(),
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
      body: state.status == NotificationsStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(notificationsProvider.notifier).loadNotifications(),
              child: state.filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.filteredNotifications[index];
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
    final isExpired = notification.isExpired;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                                  color: _getTypeColor(
                                          notification.notificationType)
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

                          if (isExpired) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Expirada',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
