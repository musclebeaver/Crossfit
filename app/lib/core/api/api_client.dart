import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api/v1', // 백엔드 주소 (에뮬레이터의 경우 10.0.2.2 등 조정 필요)
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  final _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        String message = "Server communication failed";
        if (e.response != null) {
          if (e.response?.statusCode == 401) {
            message = "Session expired. Please login again.";
            // TODO: Navigate to login screen if necessary
          } else if (e.response?.statusCode == 403) {
            message = "Access denied.";
          } else if (e.response?.data != null && e.response?.data['message'] != null) {
            message = e.response?.data['message'];
          }
        }
        debugPrint("API Error: $message");
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
