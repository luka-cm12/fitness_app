import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/notification_model_simple.dart';

class NotificationBanner extends ConsumerStatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
  });

  @override
  ConsumerState<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends ConsumerState<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  Color _getBackgroundColor() {
    switch (widget.notification.notificationType) {
      case NotificationType.workout:
        return Colors.blue.withOpacity(0.95);
      case NotificationType.nutrition:
        return Colors.green.withOpacity(0.95);
      case NotificationType.reminder:
        return Colors.orange.withOpacity(0.95);
      case NotificationType.approval:
        return Colors.purple.withOpacity(0.95);
      case NotificationType.system:
        return Colors.grey[800]!.withOpacity(0.95);
      case NotificationType.message:
        return Colors.cyan.withOpacity(0.95);
      case NotificationType.subscription:
        return Colors.amber.withOpacity(0.95);
      case NotificationType.progress:
        return Colors.teal.withOpacity(0.95);
      case NotificationType.achievement:
        return Colors.yellow[700]!.withOpacity(0.95);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          widget.notification.notificationType.icon,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Close button
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _dismiss,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para gerenciar múltiplas notificações em banner
class NotificationOverlay extends ConsumerStatefulWidget {
  const NotificationOverlay({super.key});

  @override
  ConsumerState<NotificationOverlay> createState() =>
      _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<NotificationOverlay> {
  final List<NotificationModel> _activeNotifications = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _activeNotifications.asMap().entries.map((entry) {
        final index = entry.key;
        final notification = entry.value;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 16 + (index * 80),
          left: 16,
          right: 16,
          child: NotificationBanner(
            notification: notification,
            onDismiss: () {
              setState(() {
                _activeNotifications.remove(notification);
              });
            },
            onTap: () {
              // Navegar para detalhes ou ação
              setState(() {
                _activeNotifications.remove(notification);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  void showNotification(NotificationModel notification) {
    setState(() {
      _activeNotifications.add(notification);
    });
  }

  void clearAll() {
    setState(() {
      _activeNotifications.clear();
    });
  }
}
