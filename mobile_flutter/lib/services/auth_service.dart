import 'api_client.dart';

/// Servicio de autenticación contra el backend. Mientras el backend
/// no esté disponible, AuthProvider sigue validando usuarios en
/// memoria; este servicio queda listo para sustituir ese modo local
/// llamando a login() y guardando el token en ApiClient.authToken.
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
}
