import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
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
      onError: (e, handler) async {
        // Token Refresh Logic
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/refresh') && !e.requestOptions.path.contains('/auth/login')) {
          final refreshToken = await _storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              final tokenDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
              final res = await tokenDio.post('/auth/refresh', data: {
                'refreshToken': refreshToken
              });
              
              if (res.data['success'] == true) {
                final newAccessToken = res.data['data']['accessToken'];
                final newRefreshToken = res.data['data']['refreshToken'];
                
                await _storage.write(key: 'jwt', value: newAccessToken);
                await _storage.write(key: 'refreshToken', value: newRefreshToken);
                
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                
                final retryResponse = await _dio.fetch(e.requestOptions);
                return handler.resolve(retryResponse);
              }
            } catch (refreshErr) {
              await _storage.delete(key: 'jwt');
              await _storage.delete(key: 'refreshToken');
              // TODO: Global event to route to login
            }
          }
        }

        String message = "Server communication failed";
        if (e.response != null) {
          if (e.response?.statusCode == 401) {
            message = "Session expired. Please login again.";
          } else if (e.response?.statusCode == 403) {
            message = "Access denied.";
          } else if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
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
