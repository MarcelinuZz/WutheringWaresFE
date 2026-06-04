import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/user.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/native_bridge.dart';
import '../widgets/action_buttons.dart';
import '../widgets/interactive_surface.dart';
import '../widgets/terminal_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.user,
    required this.onUserChanged,
    required this.onTokenInvalid,
    required this.onLogout,
    required this.showMessage,
  });

  final User? user;
  final ValueChanged<User> onUserChanged;
  final VoidCallback onTokenInvalid;
  final VoidCallback onLogout;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;

  Future<String?> _token() async {
    final token = await AuthStore.token;
    if (token == null) {
      widget.showMessage(tokenMissingMessage, success: false);
      widget.onTokenInvalid();
    }
    return token;
  }

  Future<void> _changePassword() async {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text(
            'Ubah Password',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TerminalField(
                label: 'PASSWORD LAMA',
                hint: 'Password lama',
                controller: oldPass,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TerminalField(
                label: 'PASSWORD BARU',
                hint: 'Password baru',
                controller: newPass,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TerminalField(
                label: 'KONFIRMASI',
                hint: 'Konfirmasi password',
                controller: confirm,
                obscureText: true,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (oldPass.text.isEmpty ||
                    newPass.text.isEmpty ||
                    confirm.text.isEmpty) {
                  setDialog(() => error = 'Semua field wajib diisi.');
                  return;
                }
                if (newPass.text.length < 8) {
                  setDialog(() => error = 'Password baru minimal 8 karakter.');
                  return;
                }
                if (newPass.text != confirm.text) {
                  setDialog(() => error = 'Konfirmasi password tidak sesuai.');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;
    final token = await _token();
    if (token == null) return;
    final result = await Api.changePassword(
      token,
      oldPass.text,
      newPass.text,
      confirm.text,
    );
    _handleResult(result.message, result.success);
  }

  Future<void> _terminateSession() async {
    final token = await _token();
    if (token == null) return;
    setState(() => _busy = true);
    final result = await Api.terminateSession(token);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success && result.token != null) {
      await AuthStore.save(result.token!, result.expiresAt);
    }
    _handleResult(result.message, result.success);
  }

  Future<void> _startBind(String provider) async {
    final opened = await NativeBridge.openUrl('$apiBase/auth/bind/$provider/');
    if (opened != true) {
      widget.showMessage('Tidak dapat membuka bind $provider.', success: false);
    }
  }

  Future<void> _unbind(String provider) async {
    final token = await _token();
    if (token == null || widget.user == null) return;
    setState(() => _busy = true);
    final result = await Api.unbind(token, provider);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      widget.onUserChanged(widget.user!.withProvider(provider, false));
    }
    _handleResult(result.message, result.success);
  }

  Future<void> _logout() async {
    final token = await _token();
    if (token == null) return;
    final result = await Api.logout(token);
    if (result.success) {
      await AuthStore.clear();
      widget.showMessage(result.message, success: true);
      widget.onLogout();
    } else {
      _handleResult(result.message, false);
    }
  }

  void _handleResult(String message, bool success) {
    final text = message.isEmpty ? (success ? 'Berhasil.' : 'Gagal.') : message;
    if (text == tokenMissingMessage) widget.onTokenInvalid();
    widget.showMessage(text, success: success);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 126),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            icon: Icons.badge_outlined,
            title: 'Informasi Pribadi',
            color: AppColors.cyan,
          ),
          InfoBox(label: 'Nama', value: user?.fullName ?? '-'),
          const SizedBox(height: 14),
          InfoBox(label: 'Email', value: user?.email ?? '-', accent: true),
          const SizedBox(height: 34),
          const SectionTitle(
            icon: Icons.shield_outlined,
            title: 'Keamanan',
            color: AppColors.pink,
          ),
          ActionRow(
            icon: Icons.password,
            title: 'Ubah Password',
            onTap: _changePassword,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _terminateSession,
            icon: const Icon(Icons.history, color: AppColors.pink),
            label: const Text('TERMINATE SESSION'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pink,
              side: const BorderSide(color: AppColors.pink),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
          const SizedBox(height: 34),
          const SectionTitle(
            icon: Icons.link,
            title: 'Akun Terhubung',
            color: AppColors.yellow,
          ),
          LinkRow(
            provider: 'google',
            title: 'Akun Google',
            bound: user?.isLinked('google') ?? false,
            onBind: () => _startBind('google'),
            onUnbind: () => _unbind('google'),
          ),
          const SizedBox(height: 14),
          LinkRow(
            provider: 'discord',
            title: 'Akun Discord',
            bound: user?.isLinked('discord') ?? false,
            onBind: () => _startBind('discord'),
            onUnbind: () => _unbind('discord'),
          ),
          const SizedBox(height: 34),
          PrimaryActionButton(
            text: 'LOGOUT SESSION',
            loading: false,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Divider(color: AppColors.stroke.withValues(alpha: 0.75)),
      const SizedBox(height: 18),
    ],
  );
}

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.input,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: accent ? AppColors.cyan : AppColors.textPrimary,
            fontSize: 19,
          ),
        ),
      ),
    ],
  );
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InteractiveSurface(
    onTap: onTap,
    borderRadius: 10,
    baseColor: AppColors.panel,
    hoverColor: AppColors.stroke.withValues(alpha: 0.7),
    borderColor: AppColors.stroke,
    hoverBorderColor: AppColors.cyan.withValues(alpha: 0.72),
    child: Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    ),
  );
}

class LinkRow extends StatelessWidget {
  const LinkRow({
    super.key,
    required this.provider,
    required this.title,
    required this.bound,
    required this.onBind,
    required this.onUnbind,
  });

  final String provider;
  final String title;
  final bool bound;
  final VoidCallback onBind;
  final VoidCallback onUnbind;

  @override
  Widget build(BuildContext context) => Container(
    height: 62,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.stroke),
    ),
    child: Row(
      children: [
        Icon(
          provider == 'google' ? Icons.g_mobiledata : Icons.discord,
          color: AppColors.textSecondary,
          size: 30,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ),
        TextButton(
          onPressed: bound ? onUnbind : onBind,
          child: Text(
            bound ? 'UNBIND' : 'BIND',
            style: TextStyle(
              color: bound ? AppColors.cyan : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}
