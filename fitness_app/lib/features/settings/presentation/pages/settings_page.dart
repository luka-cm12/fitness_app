import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/modern_app_bar.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'Português';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Configurações',
        showUserInfo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Preferências',
              [
                _buildSwitchTile(
                  'Modo Escuro',
                  'Ativar tema escuro',
                  Icons.dark_mode,
                  _darkModeEnabled,
                  (value) => setState(() => _darkModeEnabled = value),
                ),
                _buildListTile(
                  'Idioma',
                  _selectedLanguage,
                  Icons.language,
                  onTap: () => _showLanguageSelector(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Notificações',
              [
                _buildSwitchTile(
                  'Notificações Push',
                  'Receber notificações do app',
                  Icons.notifications,
                  _notificationsEnabled,
                  (value) => setState(() => _notificationsEnabled = value),
                ),
                _buildListTile(
                  'Configurar Horários',
                  'Definir quando receber lembretes',
                  Icons.schedule,
                  onTap: () => _showNotificationSettings(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Segurança',
              [
                _buildSwitchTile(
                  'Autenticação Biométrica',
                  'Usar impressão digital ou Face ID',
                  Icons.fingerprint,
                  _biometricEnabled,
                  (value) => setState(() => _biometricEnabled = value),
                ),
                _buildListTile(
                  'Alterar Senha',
                  'Modificar senha de acesso',
                  Icons.lock,
                  onTap: () => _showChangePassword(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Dados',
              [
                _buildListTile(
                  'Exportar Dados',
                  'Baixar seus dados pessoais',
                  Icons.download,
                  onTap: () => _exportData(),
                ),
                _buildListTile(
                  'Limpar Cache',
                  'Liberar espaço de armazenamento',
                  Icons.cleaning_services,
                  onTap: () => _clearCache(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Sobre',
              [
                _buildListTile(
                  'Versão do App',
                  '1.0.0',
                  Icons.info,
                ),
                _buildListTile(
                  'Termos de Uso',
                  'Ler termos e condições',
                  Icons.description,
                  onTap: () => _showTerms(),
                ),
                _buildListTile(
                  'Política de Privacidade',
                  'Como tratamos seus dados',
                  Icons.privacy_tip,
                  onTap: () => _showPrivacyPolicy(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutConfirmation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Sair da Conta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecionar Idioma',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...['Português', 'English', 'Español'].map(
              (language) => ListTile(
                title: Text(language),
                trailing: _selectedLanguage == language
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = language);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    // Implementar configurações de notificação
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Configurações de notificação em desenvolvimento')),
    );
  }

  void _showChangePassword() {
    // Implementar mudança de senha
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mudança de senha em desenvolvimento')),
    );
  }

  void _exportData() {
    // Implementar exportação de dados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportação de dados iniciada')),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Cache'),
        content: const Text(
            'Tem certeza que deseja limpar o cache? Isso pode tornar o app mais lento temporariamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache limpo com sucesso')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    // Implementar visualização de termos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Termos de uso em desenvolvimento')),
    );
  }

  void _showPrivacyPolicy() {
    // Implementar política de privacidade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Política de privacidade em desenvolvimento')),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text(
            'Tem certeza que deseja sair? Você precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementar logout
              Navigator.pushReplacementNamed(context, '/auth/login');
            },
            child: const Text('Sair', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
