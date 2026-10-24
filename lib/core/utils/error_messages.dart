import 'package:dio/dio.dart';

/// Extracts a human-readable message from any error, preferring the backend's
/// `message` field when the error is a [DioException] with a response body.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return error.toString();
}
