enum UserRole {
  admin,
  cashier,
  kitchen,
}

class AppUser {
  final String name;
  final String email;
  final String password;
  final UserRole role;

  const AppUser({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });
}