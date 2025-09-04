/// models/user_info.dart
class UserInfo {
  final int id;
  final String username;
  final bool isActive;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserInfo({
    required this.id,
    required this.username,
    required this.isActive,
    required this.isAdmin,
    this.createdAt,
    this.updatedAt,
  });

  /// Robust bool parsing (handles true/false, 1/0, "true"/"false").
  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  factory UserInfo.fromJson(Map<String, dynamic> j) => UserInfo(
    id: j['id'] as int,
    username: (j['username'] ?? j['userName'] ?? '') as String,
    isActive: _asBool(j['isActive'] ?? j['active'], fallback: true),
    isAdmin: _asBool(j['isAdmin'] ?? j['admin']),
    createdAt:
        j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
    updatedAt:
        j['updatedAt'] != null
            ? DateTime.tryParse(j['updatedAt'].toString())
            : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'isActive': isActive,
    'isAdmin': isAdmin,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  UserInfo copyWith({
    int? id,
    String? username,
    bool? isActive,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserInfo(
      id: id ?? this.id,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
