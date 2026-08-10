import 'package:dio/dio.dart';

/// Error lanzado cuando la API responde con un código fuera del
/// rango 2xx, cuando la respuesta no puede decodificarse, o cuando
/// la solicitud falla por red/tiempo de espera.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP compartido por todos los servicios, construido sobre
/// Dio (equivalente funcional a Retrofit/Volley en Android nativo).
/// Centraliza la URL base, el token de autenticación, los tiempos de
/// espera y la traducción de errores, para que cada servicio solo
/// defina sus rutas.
class ApiClient {
  ApiClient({
    this.baseUrl = 'http://localhost:3000/api',
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl
      ..contentType = Headers.jsonContentType
      ..connectTimeout = const Duration(seconds: 10)
      ..sendTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 10);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final String baseUrl;
  final Dio _dio;

  /// Token recibido tras el login. Se agrega como Bearer token a
  /// todas las peticiones siguientes mientras no sea null.
  String? authToken;

  /// Verifica si el backend responde, consultando /health (fuera del
  /// prefijo /api). Se usa para mostrar un estado de conexión real
  /// en la pantalla de login, no decorativo. Usa un tiempo de espera
  /// más corto que el resto de las peticiones porque es solo un ping.
  Future<bool> checkHealth() async {
    try {
      final root = baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - '/api'.length)
          : baseUrl;

      final response = await _dio.get(
        '$root/health',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> get(String path) => _send(() => _dio.get(path));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => _dio.post(path, data: body));

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (error) {
      throw _translate(error);
    }
  }

  ApiException _translate(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'El servidor tardó demasiado en responder. Intenta de nuevo.',
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const ApiException('No fue posible conectar con el servidor');

      case DioExceptionType.cancel:
        return const ApiException('Solicitud cancelada');

      case DioExceptionType.badResponse:
        final data = error.response?.data;
        final message = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Error de comunicación con el servidor';

        return ApiException(message, statusCode: error.response?.statusCode);
    }
  }

  void dispose() {
    _dio.close();
  }
}
