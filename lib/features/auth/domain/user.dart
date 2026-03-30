// lib/features/auth/domain/user.dart

class User {
  final String id;
  final String pin;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    required this.pin,
    required this.createdAt,
    this.lastLoginAt,
    this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      pin: json['pin'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pin': pin,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? pin,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      pin: pin ?? this.pin,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }
}
