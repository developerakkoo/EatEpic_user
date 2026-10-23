import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:food_app/core/config/google_auth_config.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/data/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final _services = AppServices.instance;

  static bool _googleInitialized = false;

  bool _isLoading = false;
  bool _requiresRegistration = false;
  String? _pendingMobile;
  String? _lastError;
  String _countryCode = '+91';
  AppUser? _user;

  // Google signup completion state
  String? _googleIdToken;
  String? _googleFullName;
  String? _googleEmail;

  bool get isLoading => _isLoading;
  bool get requiresRegistration => _requiresRegistration;
  String? get pendingMobile => _pendingMobile;
  String? get lastError => _lastError;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isGoogleRegistration =>
      _requiresRegistration && _googleIdToken != null;
  String? get googleFullName => _googleFullName;
  String? get googleEmail => _googleEmail;
  String? get phone =>
      _user != null ? '${_user!.countryCode} ${_user!.mobileNumber}' : _pendingMobile;

  void clearError() {
    _lastError = null;
  }

  /// Returns the login form to the first step without calling the API.
  void cancelRegistration() {
    _requiresRegistration = false;
    _pendingMobile = null;
    _lastError = null;
    _clearGoogleState();
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final hasToken = await _services.authRepository.hasSession();
    if (!hasToken) return false;
    try {
      _user = await _services.userRepository.getProfile();
      await _services.socketService.connect();
      notifyListeners();
      return true;
    } catch (_) {
      await _services.authRepository.logout();
      return false;
    }
  }

  /// Returns true when login completed or registration step is needed.
  Future<bool> loginWithMobile(String mobile) async {
    _isLoading = true;
    _requiresRegistration = false;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _services.authRepository.login(
        countryCode: _countryCode,
        mobileNumber: mobile,
      );
      if (result.requiresRegistration) {
        _requiresRegistration = true;
        _pendingMobile = mobile;
        return true;
      }
      await _completeLogin(result);
      return true;
    } on DioException catch (e) {
      _lastError = AuthRepository.messageFromDio(e);
      return false;
    } catch (e) {
      _lastError = 'login.loginFailed'.tr();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerAndLogin({
    required String fullName,
    String? email,
  }) async {
    if (_pendingMobile == null) return false;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _services.authRepository.register(
        countryCode: _countryCode,
        mobileNumber: _pendingMobile!,
        fullName: fullName,
        email: email,
      );
      await _completeLogin(result);
      _requiresRegistration = false;
      return true;
    } on DioException catch (e) {
      _lastError = AuthRepository.messageFromDio(e);
      return false;
    } catch (e) {
      _lastError = 'login.registrationFailed'.tr();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: GoogleAuthConfig.serverClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS &&
              GoogleAuthConfig.iosClientId.isNotEmpty
          ? GoogleAuthConfig.iosClientId
          : null,
    );
    _googleInitialized = true;
  }

  /// Runs the Google Sign-In flow. Returns true when login completed or the
  /// mobile-number registration step is needed; false on error. A user
  /// cancelling the Google account picker returns false with no error set.
  Future<bool> signInWithGoogle() async {
    if (!GoogleAuthConfig.isConfigured) {
      _lastError = 'login.googleNotConfigured'.tr();
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _requiresRegistration = false;
    _lastError = null;
    notifyListeners();

    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        _lastError = 'login.googleFailed'.tr();
        return false;
      }

      final result = await _services.authRepository.loginWithGoogle(
        idToken: idToken,
      );
      if (result.requiresRegistration) {
        _requiresRegistration = true;
        _googleIdToken = idToken;
        _googleFullName = result.googleFullName;
        _googleEmail = result.googleEmail;
        return true;
      }
      await _completeLogin(result);
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return false; // user dismissed the picker; not an error
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        _lastError = 'login.googleConsoleNotSetup'.tr();
        return false;
      }
      final detail = e.description?.trim();
      _lastError = (detail != null && detail.isNotEmpty)
          ? detail
          : 'login.googleFailed'.tr();
      return false;
    } on DioException catch (e) {
      _lastError = AuthRepository.messageFromDio(e);
      return false;
    } catch (_) {
      _lastError = 'login.googleFailed'.tr();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completes Google signup with the user's mobile number.
  Future<bool> registerWithGoogle(String mobileNumber) async {
    final idToken = _googleIdToken;
    if (idToken == null) return false;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await _services.authRepository.registerWithGoogle(
        idToken: idToken,
        mobileNumber: mobileNumber,
        countryCode: _countryCode,
        fullName: _googleFullName,
      );
      await _completeLogin(result);
      _requiresRegistration = false;
      _clearGoogleState();
      return true;
    } on DioException catch (e) {
      _lastError = AuthRepository.messageFromDio(e);
      return false;
    } catch (_) {
      _lastError = 'login.registrationFailed'.tr();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearGoogleState() {
    _googleIdToken = null;
    _googleFullName = null;
    _googleEmail = null;
  }

  Future<void> _completeLogin(LoginResult result) async {
    await _services.authRepository.persistSession(result);
    _user = result.user;
    if (_user == null || _user!.id.isEmpty) {
      _user = await _services.userRepository.getProfile();
    }
    _pendingMobile = null;
    await _services.socketService.connect();
  }

  Future<void> refreshProfile() async {
    _user = await _services.userRepository.getProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    _services.socketService.disconnect();
    await _services.authRepository.logout();
    await _services.catalogCache.clearAll();
    // Also sign out of Google so the account picker shows on next login.
    if (GoogleAuthConfig.isConfigured) {
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Google sign-out is best-effort; local session is already cleared.
      }
    }
    _user = null;
    _pendingMobile = null;
    _requiresRegistration = false;
    _lastError = null;
    _clearGoogleState();
    notifyListeners();
  }

  void setPhone(String value) {
    _pendingMobile = value;
    notifyListeners();
  }
}
