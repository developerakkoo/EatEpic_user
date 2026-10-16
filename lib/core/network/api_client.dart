import 'package:dio/dio.dart';
import 'package:food_app/core/config/app_config.dart';
import 'package:food_app/core/storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isUnauthenticatedPath(error.requestOptions.path)) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              final token = await _tokenStorage.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;
  bool _refreshing = false;

  Dio get dio => _dio;

  static const _unauthenticatedPaths = <String>{
    '/api/user/login',
    '/api/user/register',
    '/api/user/google',
    '/api/user/google/register',
    '/api/user/refresh-token',
  };

  bool _isUnauthenticatedPath(String path) {
    return _unauthenticatedPaths.any(path.contains);
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).post(
        '/api/user/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final accessToken = response.data['data']?['accessToken'] as String?;
      if (accessToken == null) return false;

      final userId = await _tokenStorage.getUserId() ?? '';
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );
      return true;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
