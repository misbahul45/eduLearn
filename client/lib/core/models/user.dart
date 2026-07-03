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
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
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
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'siswa',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'created_at': createdAt?.toIso8601String(),
      };
}

class UserStats {
  final int totalConversations;
  final int totalPredictions;
  final double avgPredictionScore;

  const UserStats({
    required this.totalConversations,
    required this.totalPredictions,
    required this.avgPredictionScore,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalConversations: json['total_conversations'] as int? ?? 0,
      totalPredictions: json['total_predictions'] as int? ?? 0,
      avgPredictionScore:
          (json['avg_prediction_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_conversations': totalConversations,
        'total_predictions': totalPredictions,
        'avg_prediction_score': avgPredictionScore,
      };
}
