class Seller {
  final String id;
  final String name;
  final String avatar;
  final String tagline;

  const Seller({
    required this.id,
    required this.name,
    required this.avatar,
    required this.tagline,
  });

  factory Seller.fromFirestore(String id, Map<String, dynamic> data) {
    return Seller(
      id: id,
      name: data['name'] as String? ?? 'Community Seller',
      avatar: data['avatar'] as String? ?? '🐠',
      tagline: data['tagline'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'avatar': avatar, 'tagline': tagline};
  }
}
