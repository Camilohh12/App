import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error lanzado cuando la API responde con un código fuera del
/// rango 2xx, o cuando la respuesta no puede decodificarse.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP compartido por todos los servicios. Centraliza la
/// URL base, el token de autenticación y la decodificación/errores
/// de las respuestas, para que cada servicio solo defina sus rutas.
class ApiClient {
  ApiClient({
    this.baseUrl = 'http://localhost:3000/api',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  /// Token recibido tras el login. Se agrega como Bearer token a
  /// todas las peticiones siguientes mientras no sea null.
  String? authToken;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> get(String path) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: _headers,
    );

    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _decode(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final response = await _httpClient.patch(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final isSuccess =
        response.statusCode >= 200 && response.statusCode < 300;

    dynamic decodedBody;

    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException {
        decodedBody = null;
      }
    }

    if (!isSuccess) {
      final message = decodedBody is Map && decodedBody['message'] != null
          ? decodedBody['message'].toString()
          : 'Error de comunicación con el servidor';

      throw ApiException(message, statusCode: response.statusCode);
    }

    return decodedBody;
  }

  void dispose() {
    _httpClient.close();
  }
}
