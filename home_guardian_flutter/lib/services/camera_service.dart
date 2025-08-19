import 'dart:convert';
import 'package:http/http.dart' as http;


class CameraService {
  /// Fetch /api/health and return the parsed JSON, or null on error
  static Future<Map<String, dynamic>?> getServerHealth(String url) async {
    try {
      final uri = _buildUri(url, '/api/health');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return null;
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
  static const Duration _timeout = Duration(seconds: 10);

  /// Test if a Home Guardian server is reachable using /api/health
  static Future<bool> testServerConnection(String url) async {
    try {
      final uri = _buildUri(url, '/api/health');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return false;
      final data = json.decode(response.body) as Map<String, dynamic>;
      // Only check for Home Guardian signature
      return data['home_guardian'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Build proper URI from URL string
  static Uri _buildUri(String url, String path) {
    String cleanUrl = url.replaceAll(RegExp(r'/+$'), '');
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    final baseUri = Uri.parse(cleanUrl);
    return baseUri.replace(path: path);
  }


  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      String cleanUrl = url.trim();
      if (cleanUrl.isEmpty) return false;
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'http://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      return uri.hasScheme && uri.hasAuthority && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Extract hostname/display name from URL for UI
  static String getDisplayName(String url) {
    try {
      String cleanUrl = url;
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'http://$cleanUrl';
      }
      final uri = Uri.parse(cleanUrl);
      String host = uri.host;
      if (uri.hasPort && uri.port != 80 && uri.port != 443) {
        host += ':${uri.port}';
      }
      return host;
    } catch (_) {
      return url;
    }
  }
}
