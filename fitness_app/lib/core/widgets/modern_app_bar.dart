import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class ModernAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showUserInfo;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showUserInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      actions: [
        if (showUserInfo && user != null) ...[
          // Notificações
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),

          const SizedBox(width: 8),

          // Perfil do usuário
          _UserProfileButton(user: user),
        ],
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _UserProfileButton extends ConsumerWidget {
  final dynamic user;

  const _UserProfileButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 10),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: user.profileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        user.profileImage!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(context),
                      ),
                    )
                  : _buildInitialsAvatar(context),
            ),

            const SizedBox(width: 8),

            // Nome e tipo de usuário
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.length > 15
                      ? '${user.fullName.substring(0, 15)}...'
                      : user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _getUserTypeLabel(user.userType),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profile',
          child: const Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Meu Perfil'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: const Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Configurações'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'help',
          child: const Row(
            children: [
              Icon(Icons.help_outline, size: 20),
              SizedBox(width: 12),
              Text('Ajuda'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red[400]),
              const SizedBox(width: 12),
              Text('Sair', style: TextStyle(color: Colors.red[400])),
            ],
          ),
        ),
      ],
      onSelected: (String value) => _handleMenuAction(context, ref, value),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = user.fullName
        .split(' ')
        .take(2)
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .join();

    return Text(
      initials,
      style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  String _getUserTypeLabel(dynamic userType) {
    switch (userType.toString()) {
      case 'UserType.trainer':
        return 'Personal Trainer';
      case 'UserType.nutritionist':
        return 'Nutricionista';
      case 'UserType.athlete':
        return 'Atleta';
      default:
        return 'Usuário';
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'profile':
        context.push('/profile');
        break;
      case 'settings':
        // TODO: Implementar configurações
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações em desenvolvimento')),
        );
        break;
      case 'help':
        // TODO: Implementar ajuda
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Central de ajuda em desenvolvimento')),
        );
        break;
      case 'logout':
        _showLogoutDialog(context, ref);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Confirmar Saída'),
          content: const Text('Tem certeza que deseja sair da sua conta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.logout();
                ref.read(authProvider.notifier).state = null;
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }
}
