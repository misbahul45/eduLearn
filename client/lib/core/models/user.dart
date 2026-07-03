class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  String get roleLabel {
    switch (role) {
      case 'pengajar':
        return 'Pengajar';
      case 'admin':
        return 'Admin';
      default:
        return 'Siswa';
    }
  }

  bool get isPengajar => role == 'pengajar' || role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'siswa',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
