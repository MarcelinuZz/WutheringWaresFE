import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../utils/auth_store.dart';
import '../utils/validators.dart';
import '../widgets/action_buttons.dart';
import '../widgets/auth_layout.dart';
import '../widgets/status_text.dart';
import '../widgets/terminal_field.dart';
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onRegister,
    required this.onLoginSuccess,
    required this.onOAuth,
  });

  final VoidCallback onRegister;
  final VoidCallback onLoginSuccess;
  final Future<void> Function(OAuthProvider provider) onOAuth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _emailError = validateEmail(_email.text);
      _passwordError = _password.text.isEmpty ? 'Password wajib diisi.' : null;
      _generalError = null;
    });
    if (_emailError != null || _passwordError != null) return;
    setState(() => _loading = true);
    final result = await Api.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.success && result.token != null) {
      await AuthStore.save(result.token!, result.expiresAt);
      widget.onLoginSuccess();
      return;
    }
    setState(() {
      if (result.message == 'Email tidak terdaftar.') {
        _emailError = result.message;
      } else if (result.message == 'Password salah.') {
        _passwordError = result.message;
      } else {
        _generalError = result.message.isEmpty
            ? 'Login gagal.'
            : result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AuthCard(
        children: [
          const AuthHeader(
            title: 'MASUK',
            subtitle: 'Masukkan kredensial untuk mengakses terminal aman.',
          ),
          TerminalField(
            label: 'EMAIL',
            hint: 'email@domain.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          TerminalField(
            label: 'PASSWORD',
            hint: 'Kata sandi',
            controller: _password,
            obscureText: true,
            error: _passwordError,
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          if (_generalError != null) StatusText(_generalError!, success: false),
          PrimaryActionButton(
            text: 'MASUK',
            loading: _loading,
            onPressed: _login,
          ),
          SecondaryActionButton(
            text: 'Masuk dengan Google',
            icon: Icons.g_mobiledata,
            onPressed: () => widget.onOAuth(OAuthProvider.google),
          ),
          SecondaryActionButton(
            text: 'Masuk dengan Discord',
            icon: Icons.discord,
            onPressed: () => widget.onOAuth(OAuthProvider.discord),
          ),
          TextButton(
            onPressed: widget.onRegister,
            child: const Text('Daftar akun baru'),
          ),
        ],
      ),
    );
  }
}
