import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../utils/auth_store.dart';
import '../utils/validators.dart';
import '../widgets/action_buttons.dart';
import '../widgets/auth_layout.dart';
import '../widgets/status_text.dart';
import '../widgets/terminal_field.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onLogin,
    required this.onRegisterSuccess,
    required this.onOAuth,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegisterSuccess;
  final Future<void> Function(OAuthProvider provider) onOAuth;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  String? _nameError;
  String? _emailMessage;
  bool _emailSuccess = false;
  String? _otpError;
  String? _passwordError;
  String? _generalError;
  bool _sendingOtp = false;
  bool _registering = false;

  Future<void> _sendOtp() async {
    final emailError = validateEmail(_email.text);
    if (emailError != null) {
      setState(() {
        _emailMessage = emailError;
        _emailSuccess = false;
      });
      return;
    }
    setState(() => _sendingOtp = true);
    final result = await Api.sendOtp(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _sendingOtp = false;
      _emailMessage = result.message.isEmpty
          ? (result.success ? 'OTP berhasil dikirim.' : 'Gagal mengirim OTP.')
          : result.message;
      _emailSuccess = result.success;
    });
  }

  Future<void> _register() async {
    setState(() {
      _nameError = _fullName.text.trim().isEmpty
          ? 'Nama lengkap wajib diisi.'
          : null;
      _emailMessage = validateEmail(_email.text);
      _emailSuccess = false;
      _otpError = _otp.text.trim().isEmpty ? 'Kode OTP wajib diisi.' : null;
      _passwordError = validatePassword(_password.text);
      _generalError = null;
    });
    if (_nameError != null ||
        _emailMessage != null ||
        _otpError != null ||
        _passwordError != null) {
      return;
    }
    setState(() => _registering = true);
    final result = await Api.register(
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      otpCode: _otp.text.trim(),
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _registering = false);
    if (result.success && result.token != null) {
      await AuthStore.save(result.token!, result.expiresAt);
      widget.onRegisterSuccess();
      return;
    }
    setState(() {
      if (result.message == 'Kode OTP tidak valid.' ||
          result.message == 'Email tidak sesuai dengan kode OTP.') {
        _otpError = result.message;
      } else if (result.message == 'Email sudah terdaftar.') {
        _emailMessage = result.message;
      } else {
        _generalError = result.message.isEmpty
            ? 'Registrasi gagal.'
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
            title: 'DAFTAR',
            subtitle: 'Buat kredensial resonansi yang aman.',
          ),
          TerminalField(
            label: 'NAMA LENGKAP',
            hint: 'Nama lengkap',
            controller: _fullName,
            error: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TerminalField(
                  label: 'EMAIL',
                  hint: 'email@domain.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  error: _emailMessage,
                  errorSuccess: _emailSuccess,
                  onChanged: (_) => setState(() => _emailMessage = null),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _sendingOtp ? null : _sendOtp,
                    child: Text(_sendingOtp ? '...' : 'Kirim OTP'),
                  ),
                ),
              ),
            ],
          ),
          TerminalField(
            label: 'KODE VERIFIKASI',
            hint: 'Masukkan kode OTP',
            controller: _otp,
            keyboardType: TextInputType.number,
            error: _otpError,
            onChanged: (_) => setState(() => _otpError = null),
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
            text: 'BUAT AKUN',
            loading: _registering,
            onPressed: _register,
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
            onPressed: widget.onLogin,
            child: const Text('Kembali ke login'),
          ),
        ],
      ),
    );
  }
}
