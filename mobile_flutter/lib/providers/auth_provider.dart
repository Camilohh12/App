import 'package:flutter/material.dart';

import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  final List<AppUser> _users = const [
    AppUser(
      name: 'Administrador',
      email: 'admin@comandapos.com',
      password: '1234',
      role: UserRole.admin,
    ),
    AppUser(
      name: 'Cajero',
      email: 'cajero@comandapos.com',
      password: '1234',
      role: UserRole.cashier,
    ),
    AppUser(
      name: 'Cocina',
      email: 'cocina@comandapos.com',
      password: '1234',
      role: UserRole.kitchen,
    ),
  ];

  bool login({
    required String email,
    required String password,
  }) {
    try {
      _currentUser = _users.firstWhere(
            (user) =>
        user.email.toLowerCase() == email.trim().toLowerCase() &&
            user.password == password,
      );

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}