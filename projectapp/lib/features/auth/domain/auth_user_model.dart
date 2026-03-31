class AuthUserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;

  const AuthUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';

  factory AuthUserModel.fromJson(Map<String, dynamic> json) => AuthUserModel(
    id: json['id'],
    fullName: json['full_name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    avatarUrl: json['avatar_url'],
    role: json['role'] ?? 'customer',
    createdAt: DateTime.parse(json['created_at']),
  );

  AuthUserModel copyWith({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
  }) => AuthUserModel(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    role: role ?? this.role,
    createdAt: createdAt,
  );
}
