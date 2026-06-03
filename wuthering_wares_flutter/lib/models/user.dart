class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.linkedAccounts = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id']?.toString() ?? '',
    fullName: json['full_name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    linkedAccounts: _parseLinkedAccounts(json['linked_accounts']),
  );

  final String id;
  final String fullName;
  final String email;
  final String role;
  final List<String> linkedAccounts;

  bool isLinked(String provider) => linkedAccounts
      .map((item) => item.toLowerCase())
      .contains(provider.toLowerCase());

  User withProvider(String provider, bool linked) {
    final next = linkedAccounts.toSet();
    if (linked) {
      next.add(provider);
    } else {
      next.removeWhere((item) => item.toLowerCase() == provider.toLowerCase());
    }
    return User(
      id: id,
      fullName: fullName,
      email: email,
      role: role,
      linkedAccounts: next.toList(),
    );
  }

  static List<String> _parseLinkedAccounts(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((entry) {
          if (entry is String) return entry;
          if (entry is Map) {
            return (entry['provider'] ?? entry['type'] ?? entry['name'] ?? '')
                .toString();
          }
          return '';
        })
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}
