class CartData {
  const CartData({required this.items, required this.summary});

  factory CartData.fromJson(Map<String, dynamic> json) => CartData(
    items: (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList(),
    summary: CartSummary.fromJson(
      json['summary'] is Map<String, dynamic>
          ? json['summary'] as Map<String, dynamic>
          : const {},
    ),
  );

  final List<CartItem> items;
  final CartSummary summary;
}

class CartItem {
  const CartItem({
    required this.cartId,
    required this.itemId,
    required this.name,
    required this.type,
    required this.price,
    required this.stock,
    required this.quantity,
    required this.subtotal,
    this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    cartId: json['cart_id']?.toString() ?? '',
    itemId: json['item_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    image: json['image']?.toString(),
    price: _intValue(json['price']),
    stock: _intValue(json['stock']),
    quantity: _intValue(json['quantity']),
    subtotal: _intValue(json['subtotal']),
  );

  final String cartId;
  final String itemId;
  final String name;
  final String type;
  final String? image;
  final int price;
  final int stock;
  final int quantity;
  final int subtotal;
}

class CartSummary {
  const CartSummary({
    required this.totalItems,
    required this.totalPrice,
    required this.tax,
    required this.grandTotal,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) => CartSummary(
    totalItems: _intValue(json['total_items']),
    totalPrice: _intValue(json['total_price']),
    tax: _intValue(json['tax']),
    grandTotal: _intValue(json['grand_total']),
  );

  final int totalItems;
  final int totalPrice;
  final int tax;
  final int grandTotal;
}

int _intValue(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
