class CatalogItem {
  const CatalogItem({required this.id, required this.name, required this.type, required this.price, this.stock = 0, this.rarity = 1, this.description = '', this.image});

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
    price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
    rarity: int.tryParse(json['rarity']?.toString() ?? '1') ?? 1,
    description: json['description']?.toString() ?? '',
    image: json['image']?.toString(),
  );

  final String id;
  final String name;
  final String type;
  final int stock;
  final int price;
  final int rarity;
  final String description;
  final String? image;
}
