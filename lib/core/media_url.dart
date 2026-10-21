/// URLs and request headers shared by thumbnails, images and media players.
class MediaUrl {
  static const tunnelHeaders = {'ngrok-skip-browser-warning': 'true'};

  static Map<String, String> headersFor(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return _isTunnel(host) ? tunnelHeaders : const {};
  }

  static bool _isTunnel(String host) =>
      host.endsWith('.ngrok-free.dev') ||
      host.endsWith('.ngrok-free.app') ||
      host.endsWith('.ngrok.app') ||
      host.endsWith('.ngrok.dev') ||
      host.endsWith('.ngrok.io');

  static bool _isLocalHost(String host) {
    if (host == 'localhost' || host == '::1' || host == '0.0.0.0') return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
      return false;
    }
    return parts[0] == 127 ||
        parts[0] == 10 ||
        (parts[0] == 192 && parts[1] == 168) ||
        (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31);
  }

  static String? resolve(String? value, String apiBaseUrl) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    final uri = Uri.tryParse(raw);
    final base = Uri.parse(apiBaseUrl);
    if (uri == null) return null;
    final path = uri.path;
    final isUpload =
        path.startsWith('/storage/') ||
        path.startsWith('storage/') ||
        path.startsWith('/api/media/') ||
        path.startsWith('api/media/');
    if (uri.hasScheme || uri.hasAuthority) {
      if (!['http', 'https'].contains(uri.scheme)) return null;
      final tunnel = _isTunnel(uri.host);
      if (!isUpload ||
          !(uri.host == base.host || _isLocalHost(uri.host) || tunnel)) {
        return raw;
      }
    }
    final storedPath = path
        .replaceFirst(RegExp(r'^/?(?:storage|api/media)/'), '')
        .replaceFirst(RegExp(r'^/+'), '');
    final mediaPath = '/api/media/$storedPath';
    return base
        .replace(
          path: mediaPath,
          query: uri.hasQuery ? uri.query : null,
          fragment: uri.hasFragment ? uri.fragment : null,
        )
        .toString();
  }

  static const _fields = {
    'thumbnail',
    'thumbnailUrl',
    'video_url',
    'videoUrl',
    'audio_url',
    'audioUrl',
    'file_url',
    'fileUrl',
    'profile_photo',
    'profilePhotoUrl',
  };

  /// Handles nested course/lesson/resource payloads without changing non-media fields.
  static dynamic resolveResponse(dynamic value, String apiBaseUrl) {
    if (value is List) {
      return value.map((v) => resolveResponse(v, apiBaseUrl)).toList();
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, item) => MapEntry(
          key.toString(),
          _fields.contains(key) && item is String
              ? resolve(item, apiBaseUrl)
              : resolveResponse(item, apiBaseUrl),
        ),
      );
    }
    return value;
  }
}
