import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/catalog_item.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class Api {
  static Future<ApiResponse> login(String email, String password) => _post('/auth/login', {'email': email, 'password': password});
  static Future<ApiResponse> sendOtp(String email) => _post('/auth/register/send-otp/', {'email': email});
  static Future<ApiResponse> exchangeToken(String code) => _post('/auth/exchange-token', {'code': code});
  static Future<ApiResponse> register({required String fullName, required String email, required String otpCode, required String password}) => _post('/auth/register/verify-otp/', {'full_name': fullName, 'email': email, 'otp_code': otpCode, 'password': password});
  static Future<ApiResponse> me(String token) => _get('/users/me', token: token);
  static Future<ApiResponse> items(String? type) => _get(type == null ? '/items/' : '/items?type=$type');
  static Future<ApiResponse> changePassword(String token, String oldPassword, String newPassword, String confirmPassword) => _patch('/users/change-password', {'old_password': oldPassword, 'new_password': newPassword, 'confirm_password': confirmPassword}, token);
  static Future<ApiResponse> terminateSession(String token) => _delete('/auth/terminate-session', token);
  static Future<ApiResponse> logout(String token) => _delete('/auth/logout', token);
  static Future<ApiResponse> bind(String token, String provider, String bindCode) => _post('/users/bind/$provider', {'bind_code': bindCode}, token: token);
  static Future<ApiResponse> unbind(String token, String provider) => _delete('/users/unbind/$provider', token);
  static Future<ApiResponse> deleteItem(String token, String id) => _delete('/items/$id', token);
  static Future<ApiResponse> addToCart(String token, String itemId, int quantity) => _post('/cart/', {'item_id': itemId, 'quantity': quantity}, token: token);
  static Future<ApiResponse> cart(String token) => _get('/cart/', token: token);
  static Future<ApiResponse> updateCartQuantity(String token, String cartId, int quantity) => _patch('/cart/$cartId', {'quantity': quantity}, token);
  static Future<ApiResponse> deleteCartItem(String token, String cartId) => _delete('/cart/$cartId', token);
  static Future<ApiResponse> checkout(String token) => _post('/orders/checkout/', const {}, token: token);
  static Future<ApiResponse> orders(String token) => _get('/orders/orders', token: token);
  static Future<ApiResponse> orderDetail(String token, String orderId) => _get('/orders/orders/$orderId', token: token);

  static Future<ApiResponse> addItem(String token, ItemPayload payload) => _multipart('/items/', token, payload);
  static Future<ApiResponse> updateItem(String token, String id, ItemPayload payload) => _multipart('/items/$id', token, payload, method: 'PUT');

  static Future<ApiResponse> _post(String path, Map<String, dynamic> body, {String? token}) => _request(() => http.post(Uri.parse('$apiBase$path'), headers: _headers(token: token), body: jsonEncode(body)));
  static Future<ApiResponse> _patch(String path, Map<String, dynamic> body, String token) => _request(() => http.patch(Uri.parse('$apiBase$path'), headers: _headers(token: token), body: jsonEncode(body)));
  static Future<ApiResponse> _get(String path, {String? token}) => _request(() => http.get(Uri.parse('$apiBase$path'), headers: _headers(token: token)));
  static Future<ApiResponse> _delete(String path, String token) => _request(() => http.delete(Uri.parse('$apiBase$path'), headers: _headers(token: token)));

  static Future<ApiResponse> _multipart(String path, String token, ItemPayload payload, {String method = 'POST'}) async {
    try {
      final request = http.MultipartRequest(method, Uri.parse('$apiBase$path'));
      request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      payload.fields.forEach((key, value) {
        if (value != null && value.isNotEmpty) request.fields[key] = value;
      });
      if (payload.imagePath != null && payload.imagePath!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', payload.imagePath!));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parse(json);
    } catch (error) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan koneksi: $error');
    }
  }

  static Map<String, String> _headers({String? token}) => {'Content-Type': 'application/json', 'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};

  static Future<ApiResponse> _request(Future<http.Response> Function() send) async {
    try {
      final response = await send().timeout(const Duration(seconds: 15));
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parse(json);
    } catch (error) {
      return ApiResponse(success: false, message: 'Terjadi kesalahan koneksi: $error');
    }
  }

  static ApiResponse _parse(Map<String, dynamic> json) {
    final userJson = json['user'];
    final dataJson = json['data'];
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: dataJson,
      token: json['token']?.toString(),
      expiresAt: json['expires_at']?.toString(),
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
      items: dataJson is List ? dataJson.whereType<Map<String, dynamic>>().map(CatalogItem.fromJson).toList() : const [],
    );
  }
}

class ItemPayload {
  const ItemPayload({this.name, this.type, this.price, this.rarity, this.description, this.imagePath});

  final String? name;
  final String? type;
  final String? price;
  final String? rarity;
  final String? description;
  final String? imagePath;

  Map<String, String?> get fields => {'name': name, 'type': type, 'price': price, 'rarity': rarity, 'description': description};

  bool get isEmpty => [name, type, price, rarity, description, imagePath].every((value) => value == null || value.isEmpty);
}
