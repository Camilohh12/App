import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._apiClient) : _authService = AuthService(_apiClient);

  final ApiClient _apiClient;
  final AuthService _authService;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email.trim(),
        password: password,
      );

      _apiClient.authToken = response['token'] as String;
      _currentUser = AppUser.fromJson(
        response['user'] as Map<String, dynamic>,
      );

      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No fue posible conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _apiClient.authToken = null;
    notifyListeners();
  }

  /// Crea un nuevo usuario. Solo un administrador autenticado puede
  /// hacerlo (el backend lo exige). Devuelve null si todo salió
  /// bien, o un mensaje de error para mostrar.
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      await _authService.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role.name,
      );

      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No fue posible conectar con el servidor';
    }
  }
}
