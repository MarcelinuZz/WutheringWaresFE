import 'package:flutter/material.dart';

import 'apis/api.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'utils/auth_store.dart';
import 'utils/colors.dart';
import 'utils/constants.dart';
import 'utils/native_bridge.dart';

enum AppPage { login, register, home }

enum OAuthProvider { google, discord }

void main() {
  runApp(const WutheringWaresApp());
}

class WutheringWaresApp extends StatefulWidget {
  const WutheringWaresApp({super.key});

  @override
  State<WutheringWaresApp> createState() => _WutheringWaresAppState();
}

class _WutheringWaresAppState extends State<WutheringWaresApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  AppPage _page = AppPage.login;
  MainTab _initialHomeTab = MainTab.catalog;
  int _bindRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    NativeBridge.setDeepLinkHandler(_handleCallback);
    final token = await AuthStore.token;
    if (!mounted) return;
    setState(() => _page = token == null ? AppPage.login : AppPage.home);
    final initialLink = await NativeBridge.initialLink();
    if (initialLink != null) await _handleCallback(initialLink);
  }

  Future<void> _handleCallback(Uri uri) async {
    if (uri.host == 'bind') {
      await _handleBindCallback(uri);
      return;
    }
    await _handleAuthCallback(uri);
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    final error = uri.queryParameters['error'];
    final message = uri.queryParameters['message'];
    final code = uri.queryParameters['code'];
    if (error != null) {
      _showMessage(message ?? error, success: false);
      setState(() => _page = AppPage.login);
      return;
    }
    if (code == null || code.isEmpty) return;
    final result = await Api.exchangeToken(code);
    if (!mounted) return;
    if (result.success && result.token != null) {
      await AuthStore.save(result.token!, result.expiresAt);
      setState(() => _page = AppPage.home);
    } else {
      _showMessage(
        result.message.isEmpty ? 'Login OAuth gagal.' : result.message,
        success: false,
      );
      setState(() => _page = AppPage.login);
    }
  }

  Future<void> _handleBindCallback(Uri uri) async {
    final bindCode = uri.queryParameters['bind_code'];
    final provider = uri.queryParameters['provider'];
    if (bindCode == null || provider == null) return;
    final token = await AuthStore.token;
    if (token == null) {
      _showMessage(tokenMissingMessage, success: false);
      await _logoutLocal();
      return;
    }
    final result = await Api.bind(token, provider, bindCode);
    if (!mounted) return;
    _showMessage(
      result.message.isEmpty
          ? (result.success
                ? 'Akun berhasil dihubungkan.'
                : 'Gagal menghubungkan akun.')
          : result.message,
      success: result.success,
    );
    if (result.message == tokenMissingMessage) {
      await _logoutLocal();
      return;
    }
    if (result.success) {
      setState(() {
        _page = AppPage.home;
        _initialHomeTab = MainTab.profile;
        _bindRefreshKey++;
      });
    }
  }

  Future<void> _launchOAuth(OAuthProvider provider) async {
    final path = provider == OAuthProvider.google
        ? '/auth/google/'
        : '/auth/discord/';
    final opened = await NativeBridge.openUrl('$apiBase$path');
    if (opened != true) {
      _showMessage('Tidak dapat membuka login OAuth.', success: false);
    }
  }

  void _showMessage(String message, {required bool success}) {
    if (!mounted) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _logoutLocal() async {
    await AuthStore.clear();
    if (!mounted) return;
    setState(() => _page = AppPage.login);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Wuthering Wares',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: switch (_page) {
        AppPage.login => LoginPage(
          onRegister: () => setState(() => _page = AppPage.register),
          onLoginSuccess: () => setState(() => _page = AppPage.home),
          onOAuth: _launchOAuth,
        ),
        AppPage.register => RegisterPage(
          onLogin: () => setState(() => _page = AppPage.login),
          onRegisterSuccess: () => setState(() => _page = AppPage.home),
          onOAuth: _launchOAuth,
        ),
        AppPage.home => HomePage(
          initialTab: _initialHomeTab,
          bindRefreshKey: _bindRefreshKey,
          onTokenInvalid: _logoutLocal,
          onLogout: _logoutLocal,
          showMessage: _showMessage,
        ),
      },
    );
  }
}
