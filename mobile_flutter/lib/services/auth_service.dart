import 'api_client.dart';

/// Servicio de autenticación contra el backend real.
class AuthService {
  const AuthService(this._client);

  final ApiClient _client;

  /// POST /api/auth/login
  /// Respuesta esperada: { "token": "...", "user": { ... } }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return response as Map<String, dynamic>;
  }

  /// POST /api/auth/register
  /// Requiere estar autenticado como admin (el backend lo exige).
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    return response as Map<String, dynamic>;
  }
}
