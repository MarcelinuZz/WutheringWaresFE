import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String apiBase = 'http://10.0.2.2:3000/api';
const String tokenMissingMessage =
    'Token tidak ditemukan. Silakan login terlebih dahulu.';

void main() {
  runApp(const WutheringWaresApp());
}

class WutheringWaresApp extends StatefulWidget {
  const WutheringWaresApp({super.key});

  @override
  State<WutheringWaresApp> createState() => _WutheringWaresAppState();
}

class _WutheringWaresAppState extends State<WutheringWaresApp> {
  AppPage _page = AppPage.login;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    NativeBridge.setDeepLinkHandler((uri) {
      _handleOAuthCallback(uri);
    });

    final token = await AuthStore.token;
    if (!mounted) return;
    setState(() => _page = token == null ? AppPage.login : AppPage.home);

    final initialLink = await NativeBridge.initialLink();
    if (initialLink != null) {
      await _handleOAuthCallback(initialLink);
    }
  }

  Future<void> _handleOAuthCallback(Uri uri) async {
    final error = uri.queryParameters['error'];
    final message = uri.queryParameters['message'];
    final code = uri.queryParameters['code'];

    if (error != null) {
      _showMessage(message ?? error, success: false);
      setState(() => _page = AppPage.login);
      return;
    }

    if (code == null || code.isEmpty) {
      setState(() => _page = AppPage.login);
      return;
    }

    final result = await Api.exchangeToken(code);
    if (!mounted) return;
    if (result.success && result.token != null) {
      await AuthStore.save(result.token!, result.expiresAt);
      setState(() => _page = AppPage.home);
    } else {
      _showMessage(result.message.isEmpty ? 'Login OAuth gagal.' : result.message,
          success: false);
      setState(() => _page = AppPage.login);
    }
  }

  Future<void> _launchOAuth(OAuthProvider provider) async {
    final path = provider == OAuthProvider.google ? '/auth/google/' : '/auth/discord/';
    final uri = Uri.parse('$apiBase$path');
    final opened = await NativeBridge.openUrl(uri.toString());
    if (opened != true) {
      _showMessage('Tidak dapat membuka login OAuth.', success: false);
    }
  }

  void _showMessage(String message, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthStore.clear();
    if (!mounted) return;
    setState(() => _page = AppPage.login);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            showMessage: _showMessage,
          ),
        AppPage.register => RegisterPage(
            onLogin: () => setState(() => _page = AppPage.login),
            onRegisterSuccess: () => setState(() => _page = AppPage.home),
            onOAuth: _launchOAuth,
            showMessage: _showMessage,
          ),
        AppPage.home => HomePage(
            onTokenInvalid: _logout,
            showMessage: _showMessage,
          ),
      },
    );
  }
}

enum AppPage { login, register, home }
enum OAuthProvider { google, discord }
enum MainTab { catalog, payment, cart, profile }
enum ItemFilter {
  all('Semua', null),
  equipment('Equipment', 'equipment'),
  supplies('Supplies', 'supplies');

  const ItemFilter(this.label, this.type);
  final String label;
  final String? type;
}

class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.token,
    this.expiresAt,
    this.user,
    this.items = const [],
  });

  final bool success;
  final String message;
  final String? token;
  final String? expiresAt;
  final User? user;
  final List<CatalogItem> items;
}

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String role;
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    this.image,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      image: json['image']?.toString(),
    );
  }

  final String id;
  final String name;
  final String type;
  final int price;
  final String? image;
}

class AuthStore {
  static const _tokenKey = 'token';
  static const _expiresAtKey = 'expires_at';

  static Future<String?> get token async {
    return NativeBridge.getString(_tokenKey);
  }

  static Future<void> save(String token, String? expiresAt) async {
    await NativeBridge.setString(_tokenKey, token);
    if (expiresAt != null) {
      await NativeBridge.setString(_expiresAtKey, expiresAt);
    }
  }

  static Future<void> clear() async {
    await NativeBridge.remove(_tokenKey);
    await NativeBridge.remove(_expiresAtKey);
  }
}

class NativeBridge {
  static const _channel = MethodChannel('wuthering_wares/native');

  static void setDeepLinkHandler(void Function(Uri uri) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'deepLink' && call.arguments is String) {
        handler(Uri.parse(call.arguments as String));
      }
    });
  }

  static Future<Uri?> initialLink() async {
    final value = await _channel.invokeMethod<String>('initialLink');
    if (value == null || value.isEmpty) return null;
    return Uri.parse(value);
  }

  static Future<bool?> openUrl(String url) {
    return _channel.invokeMethod<bool>('openUrl', url);
  }

  static Future<String?> getString(String key) {
    return _channel.invokeMethod<String>('getString', key);
  }

  static Future<void> setString(String key, String value) {
    return _channel.invokeMethod<void>('setString', {'key': key, 'value': value});
  }

  static Future<void> remove(String key) {
    return _channel.invokeMethod<void>('remove', key);
  }
}

class Api {
  static Future<ApiResponse> login(String email, String password) {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  static Future<ApiResponse> sendOtp(String email) {
    return _post('/auth/register/send-otp/', {'email': email});
  }

  static Future<ApiResponse> register({
    required String fullName,
    required String email,
    required String otpCode,
    required String password,
  }) {
    return _post('/auth/register/verify-otp/', {
      'full_name': fullName,
      'email': email,
      'otp_code': otpCode,
      'password': password,
    });
  }

  static Future<ApiResponse> exchangeToken(String code) {
    return _post('/auth/exchange-token', {'code': code});
  }

  static Future<ApiResponse> me(String token) {
    return _get('/users/me', token: token);
  }

  static Future<ApiResponse> items(String? type) {
    return _get(type == null ? '/items/' : '/items?type=$type');
  }

  static Future<ApiResponse> _post(String path, Map<String, dynamic> body) async {
    return _request(
      () => http.post(
        Uri.parse('$apiBase$path'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  static Future<ApiResponse> _get(String path, {String? token}) async {
    return _request(
      () => http.get(
        Uri.parse('$apiBase$path'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  static Future<ApiResponse> _request(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(const Duration(seconds: 15));
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;
      return _parse(json);
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Terjadi kesalahan koneksi: $error',
      );
    }
  }

  static ApiResponse _parse(Map<String, dynamic> json) {
    final userJson = json['user'];
    final dataJson = json['data'];
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      token: json['token']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      items: dataJson is List
          ? dataJson
              .whereType<Map<String, dynamic>>()
              .map(CatalogItem.fromJson)
              .toList()
          : const [],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onRegister,
    required this.onLoginSuccess,
    required this.onOAuth,
    required this.showMessage,
  });

  final VoidCallback onRegister;
  final VoidCallback onLoginSuccess;
  final Future<void> Function(OAuthProvider provider) onOAuth;
  final void Function(String message, {required bool success}) showMessage;

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
        _generalError = result.message.isEmpty ? 'Login gagal.' : result.message;
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
            subtitle: 'Masukan kredensial untuk mengakses halaman utama.',
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onLogin,
    required this.onRegisterSuccess,
    required this.onOAuth,
    required this.showMessage,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegisterSuccess;
  final Future<void> Function(OAuthProvider provider) onOAuth;
  final void Function(String message, {required bool success}) showMessage;

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
  bool _emailMessageSuccess = false;
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
        _emailMessageSuccess = false;
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
      _emailMessageSuccess = result.success;
    });
  }

  Future<void> _register() async {
    setState(() {
      _nameError = _fullName.text.trim().isEmpty ? 'Nama lengkap wajib diisi.' : null;
      _emailMessage = validateEmail(_email.text);
      _emailMessageSuccess = false;
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
        _emailMessageSuccess = false;
      } else {
        _generalError =
            result.message.isEmpty ? 'Registrasi gagal.' : result.message;
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
                  errorSuccess: _emailMessageSuccess,
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

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onTokenInvalid,
    required this.showMessage,
  });

  final VoidCallback onTokenInvalid;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? _user;
  MainTab _tab = MainTab.catalog;
  ItemFilter _filter = ItemFilter.all;
  String _search = '';
  List<CatalogItem> _items = const [];
  bool _loadingUser = true;
  bool _loadingItems = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadItems();
  }

  Future<void> _loadUser() async {
    final token = await AuthStore.token;
    if (token == null) {
      widget.showMessage(tokenMissingMessage, success: false);
      widget.onTokenInvalid();
      return;
    }

    final result = await Api.me(token);
    if (!mounted) return;
    setState(() => _loadingUser = false);
    if (result.success && result.user != null) {
      setState(() => _user = result.user);
      return;
    }

    final message =
        result.message.isEmpty ? 'Gagal memuat data pengguna.' : result.message;
    widget.showMessage(message, success: false);
    if (message == tokenMissingMessage) {
      widget.onTokenInvalid();
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loadingItems = true);
    final result = await Api.items(_filter.type);
    if (!mounted) return;
    setState(() {
      _loadingItems = false;
      if (result.success) {
        _items = result.items;
        _error = null;
      } else {
        _error = result.message.isEmpty ? 'Gagal memuat item.' : result.message;
      }
    });
  }

  List<CatalogItem> get _visibleItems {
    final keyword = _search.trim().toLowerCase();
    if (keyword.isEmpty) return _items;
    return _items.where((item) {
      return item.name.toLowerCase().contains(keyword) ||
          item.type.toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandHeader(),
                  if (!_loadingUser && _user != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Halo, ${_user!.fullName}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(child: _buildTab()),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomNav(
                selected: _tab,
                onSelected: (tab) => setState(() => _tab = tab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    return switch (_tab) {
      MainTab.catalog => CatalogPage(
          filter: _filter,
          onFilter: (filter) {
            setState(() => _filter = filter);
            _loadItems();
          },
          search: _search,
          onSearch: (value) => setState(() => _search = value),
          loading: _loadingItems,
          error: _error,
          items: _visibleItems,
        ),
      MainTab.payment => const PlaceholderPanel(
          title: 'Pembayaran',
          description: 'Riwayat dan status pembayaran akan ditampilkan di sini.',
        ),
      MainTab.cart => const PlaceholderPanel(
          title: 'Keranjang',
          description: 'Item yang dipilih akan masuk ke halaman keranjang.',
        ),
      MainTab.profile => PlaceholderPanel(
          title: 'Profil',
          description: _user == null
              ? 'Data profil belum tersedia.'
              : '${_user!.fullName}\n${_user!.email}\nRole: ${_user!.role}',
        ),
    };
  }
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({
    super.key,
    required this.filter,
    required this.onFilter,
    required this.search,
    required this.onSearch,
    required this.loading,
    required this.error,
    required this.items,
  });

  final ItemFilter filter;
  final ValueChanged<ItemFilter> onFilter;
  final String search;
  final ValueChanged<String> onSearch;
  final bool loading;
  final String? error;
  final List<CatalogItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ItemFilter.values.map((option) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: FilterPill(
                  text: option.label,
                  selected: option == filter,
                  onTap: () => onFilter(option),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        SearchField(value: search, onChanged: onSearch),
        const SizedBox(height: 16),
        if (error != null) StatusText(error!, success: false),
        Expanded(
          child: Builder(
            builder: (context) {
              if (loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                );
              }
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Item belum tersedia.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 104),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 18,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => ItemCard(item: items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121C26), AppColors.background, Color(0xFF08131B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.stroke),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 26,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: withSpacing(children, 14),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.terminal, color: AppColors.textSecondary, size: 22),
            SizedBox(width: 10),
            Text(
              'WUTHERING WARES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 18,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class TerminalField extends StatelessWidget {
  const TerminalField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.error,
    this.errorSuccess = false,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final bool errorSuccess;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.65)),
            filled: true,
            fillColor: AppColors.input,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.cyan),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          StatusText(error!, success: errorSuccess),
        ],
      ],
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  final String text;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.stroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: const Icon(Icons.hexagon, color: AppColors.cyan, size: 30),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wuthering',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Text(
                'Wares',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 72),
      ],
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withValues(alpha: 0.12) : AppColors.panel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.stroke,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.cyan : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        hintText: 'Cari item...',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.panel,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.image == null ? null : '$apiBase${item.image}';
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.14,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: image == null
                    ? const Center(
                        child: Text(
                          'ITEM',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'ITEM',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              titleCase(item.type),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              formatRupiah(item.price),
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.selected, required this.onSelected});

  final MainTab selected;
  final ValueChanged<MainTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: AppColors.stroke.withValues(alpha: 0.6))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MainTab.values.map((tab) {
            return NavItem(
              tab: tab,
              selected: selected == tab,
              onTap: () => onSelected(tab),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final MainTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (tab) {
      MainTab.catalog => Icons.home_filled,
      MainTab.payment => Icons.credit_card,
      MainTab.cart => Icons.shopping_cart,
      MainTab.profile => Icons.person,
    };
    final label = switch (tab) {
      MainTab.catalog => 'KATALOG',
      MainTab.payment => 'PAYMENT',
      MainTab.cart => 'CART',
      MainTab.profile => 'PROFILE',
    };
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.cyan.withValues(alpha: 0.22) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.cyan : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.cyan : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPanel extends StatelessWidget {
  const PlaceholderPanel({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 110),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key, required this.success});

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: success ? AppColors.success : AppColors.error,
        fontSize: 12,
        height: 1.35,
      ),
    );
  }
}

class AppColors {
  static const background = Color(0xFF071018);
  static const panel = Color(0xFF111A23);
  static const input = Color(0xFF091722);
  static const stroke = Color(0xFF243442);
  static const cyan = Color(0xFF11DCE8);
  static const textPrimary = Color(0xFFE7EEF4);
  static const textSecondary = Color(0xFFAAB4BE);
  static const textMuted = Color(0xFF687580);
  static const success = Color(0xFF46D67F);
  static const error = Color(0xFFFF5D6C);
}

String? validateEmail(String email) {
  final value = email.trim();
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (value.isEmpty) return 'Email wajib diisi.';
  if (!pattern.hasMatch(value)) return 'Format email tidak valid.';
  return null;
}

String? validatePassword(String password) {
  if (password.isEmpty) return 'Password wajib diisi.';
  if (password.length < 8) return 'Password minimal 8 karakter.';
  return null;
}

String formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && (reverseIndex - 1) % 3 == 0) {
      buffer.write('.');
    }
  }
  return 'Rp ${buffer.toString()}';
}

String titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

List<Widget> withSpacing(List<Widget> children, double spacing) {
  final spaced = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    spaced.add(children[i]);
    if (i != children.length - 1) spaced.add(SizedBox(height: spacing));
  }
  return spaced;
}
