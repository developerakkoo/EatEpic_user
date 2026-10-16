import 'package:food_app/core/config/app_config.dart';

/// Resolves uploaded asset paths relative to API host (mirrors backend media.js).
String? resolveMediaUrl(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('assets/')) return s;
  if (s.startsWith('/')) return '${AppConfig.apiBaseUrl}$s';
  if (s.startsWith('uploads/')) return '${AppConfig.apiBaseUrl}/$s';
  return '${AppConfig.apiBaseUrl}/uploads/$s';
}
