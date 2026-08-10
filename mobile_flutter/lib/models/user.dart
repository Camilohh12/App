enum UserRole {
  admin,
  cashier,
  kitchen,
  waiter,
  bar,
}

class AppUser {
  final int id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.cashier,
      ),
    );
  }

  /// No incluye contraseña: nunca se guarda ni se vuelve a enviar
  /// tras el login. El registro de usuario usa su propio payload en
  /// `auth_service.dart` (con password).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
    };
  }
}
