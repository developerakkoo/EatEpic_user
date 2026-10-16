import 'package:dio/dio.dart';
import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/core/storage/token_storage.dart';
import 'package:food_app/data/models/app_user.dart';

class LoginResult {
  final bool requiresRegistration;
  final AppUser? user;
  final String? accessToken;
  final String? refreshToken;

  /// Prefilled profile from Google when registration is still required.
  final String? googleFullName;
  final String? googleEmail;

  LoginResult({
    required this.requiresRegistration,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.googleFullName,
    this.googleEmail,
  });
}

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  static String messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your network and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  static bool _isRegistrationRequiredResponse(int? status, dynamic data) {
    if (status == 200 && data is Map) {
      final inner = data['data'];
      if (inner is Map && inner['requiresRegistration'] == true) {
        return true;
      }
    }
    if (status == 400 && data is Map) {
      final msg = (data['message'] ?? '').toString().toLowerCase();
      return msg.contains('full name') ||
          msg.contains('email required') ||
          msg.contains('new user');
    }
    return false;
  }

  Future<LoginResult> login({
    required String countryCode,
    required String mobileNumber,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/user/login',
        data: {
          'countryCode': countryCode,
          'mobileNumber': mobileNumber,
        },
      );
      final body = response.data;
      if (_isRegistrationRequiredResponse(response.statusCode, body)) {
        return LoginResult(requiresRegistration: true);
      }
      final data = body['data'] as Map<String, dynamic>? ?? {};
      return _parseAuthData(data);
    } on DioException catch (e) {
      if (_isRegistrationRequiredResponse(e.response?.statusCode, e.response?.data)) {
        return LoginResult(requiresRegistration: true);
      }
      rethrow;
    }
  }

  Future<LoginResult> register({
    required String countryCode,
    required String mobileNumber,
    required String fullName,
    String? email,
  }) async {
    final payload = {
      'countryCode': countryCode,
      'mobileNumber': mobileNumber,
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
    };

    try {
      final response = await _api.dio.post('/api/user/register', data: payload);
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      return _parseAuthData(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _legacyRegisterViaLogin(payload);
      }
      rethrow;
    }
  }

  /// Exchanges a Google ID token for app tokens. Returns
  /// `requiresRegistration: true` with the Google profile when the user
  /// still needs to provide a mobile number.
  Future<LoginResult> loginWithGoogle({required String idToken}) async {
    final response = await _api.dio.post(
      '/api/user/google',
      data: {'idToken': idToken},
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    if (data['requiresRegistration'] == true) {
      final profile = data['profile'] as Map<String, dynamic>? ?? {};
      return LoginResult(
        requiresRegistration: true,
        googleFullName: profile['fullName']?.toString(),
        googleEmail: profile['email']?.toString(),
      );
    }
    return _parseAuthData(data);
  }

  /// Completes Google signup by attaching a mobile number.
  Future<LoginResult> registerWithGoogle({
    required String idToken,
    required String mobileNumber,
    String countryCode = '+91',
    String? referralCode,
    String? fullName,
  }) async {
    final response = await _api.dio.post(
      '/api/user/google/register',
      data: {
        'idToken': idToken,
        'mobileNumber': mobileNumber,
        'countryCode': countryCode,
        if (referralCode != null && referralCode.isNotEmpty)
          'referralCode': referralCode,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return _parseAuthData(data);
  }

  /// Production API (pre register route): create user via login + fullName/email.
  Future<LoginResult> _legacyRegisterViaLogin(Map<String, dynamic> payload) async {
    final response = await _api.dio.post('/api/user/login', data: payload);
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return _parseAuthData(data);
  }

  Future<void> persistSession(LoginResult result) async {
    if (result.user == null ||
        result.user!.id.isEmpty ||
        result.accessToken == null ||
        result.accessToken!.isEmpty ||
        result.refreshToken == null ||
        result.refreshToken!.isEmpty) {
      throw StateError('Login response did not include tokens');
    }
    await _tokenStorage.saveTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken!,
      userId: result.user!.id,
    );
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<bool> hasSession() => _tokenStorage.hasValidSession();

  LoginResult _parseAuthData(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return LoginResult(
      requiresRegistration: false,
      user: AppUser.fromJson(userJson),
      accessToken: data['accessToken']?.toString(),
      refreshToken: data['refreshToken']?.toString(),
    );
  }
}
