import 'catalog_item.dart';
import 'user.dart';

class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.token,
    this.expiresAt,
    this.user,
    this.items = const [],
  });

  final bool success;
  final String message;
  final dynamic data;
  final String? token;
  final String? expiresAt;
  final User? user;
  final List<CatalogItem> items;
}
