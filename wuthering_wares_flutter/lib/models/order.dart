class CheckoutData {
  const CheckoutData({
    required this.transactionId,
    required this.midtransOrderId,
    required this.totalPrice,
    required this.tax,
    required this.grandTotal,
    required this.snapToken,
    required this.snapRedirectUrl,
    required this.status,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) => CheckoutData(
    transactionId: json['transaction_id']?.toString() ?? json['id']?.toString() ?? '',
    midtransOrderId: json['midtrans_order_id']?.toString() ?? '',
    totalPrice: _intValue(json['total_price']),
    tax: _intValue(json['tax']),
    grandTotal: _intValue(json['grand_total']),
    snapToken: json['snap_token']?.toString() ?? '',
    snapRedirectUrl: json['snap_redirect_url']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
  );

  final String transactionId;
  final String midtransOrderId;
  final int totalPrice;
  final int tax;
  final int grandTotal;
  final String snapToken;
  final String snapRedirectUrl;
  final String status;
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.itemSummary,
    required this.grandTotal,
    required this.status,
    this.paymentType,
    this.transactionDate,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    id: json['id']?.toString() ?? '',
    itemSummary: json['item_summary']?.toString() ?? '',
    grandTotal: _intValue(json['grand_total']),
    status: json['status']?.toString() ?? '',
    paymentType: json['payment_type']?.toString(),
    transactionDate: json['transaction_date']?.toString(),
  );

  final String id;
  final String itemSummary;
  final int grandTotal;
  final String status;
  final String? paymentType;
  final String? transactionDate;
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.totalPrice,
    required this.tax,
    required this.grandTotal,
    required this.status,
    required this.midtransOrderId,
    required this.snapToken,
    required this.snapRedirectUrl,
    required this.items,
    this.paymentType,
    this.transactionDate,
    this.paidAt,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    id: json['id']?.toString() ?? '',
    totalPrice: _intValue(json['total_price']),
    tax: _intValue(json['tax']),
    grandTotal: _intValue(json['grand_total']),
    status: json['status']?.toString() ?? '',
    paymentType: json['payment_type']?.toString(),
    midtransOrderId: json['midtrans_order_id']?.toString() ?? '',
    snapToken: json['snap_token']?.toString() ?? '',
    snapRedirectUrl: json['snap_redirect_url']?.toString() ?? '',
    transactionDate: json['transaction_date']?.toString(),
    paidAt: json['paid_at']?.toString(),
    items: (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderItem.fromJson)
        .toList(),
  );

  CheckoutData get checkoutData => CheckoutData(
    transactionId: id,
    midtransOrderId: midtransOrderId,
    totalPrice: totalPrice,
    tax: tax,
    grandTotal: grandTotal,
    snapToken: snapToken,
    snapRedirectUrl: snapRedirectUrl,
    status: status,
  );

  final String id;
  final int totalPrice;
  final int tax;
  final int grandTotal;
  final String status;
  final String? paymentType;
  final String midtransOrderId;
  final String snapToken;
  final String snapRedirectUrl;
  final String? transactionDate;
  final String? paidAt;
  final List<OrderItem> items;
}

class OrderItem {
  const OrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    itemId: json['item_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString(),
    price: _intValue(json['price']),
    quantity: _intValue(json['quantity']),
    subtotal: _intValue(json['subtotal']),
  );

  final String itemId;
  final String name;
  final String? image;
  final int price;
  final int quantity;
  final int subtotal;
}

int _intValue(dynamic value) => int.tryParse(value?.toString() ?? '0') ?? 0;
