class AppUser {
  final String id; // Firebase Auth uid
  final String name;
  final String email;
  final String avatar;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory AppUser.fromFirestore(String uid, Map<String, dynamic> data) {
    return AppUser(
      id: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatar: data['avatar'] as String? ?? '🐠',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'email': email, 'avatar': avatar};
  }
}

/// Emoji choices offered on the profile screen.
const List<String> avatarChoices = ['🐠', '🐡', '🐟', '🦈', '🐙', '🦀', '🐢', '🧜'];
