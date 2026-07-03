import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/camera_status.dart';
import '../models/face_detection_event.dart';

/// Home Guardian Client V2 - minimal, robust, matches new backend
class HomeGuardianClientV2 {
  final String baseUrl;
  late final String wsBaseUrl;

  HomeGuardianClientV2({required String baseUrl})
    : baseUrl = _normalizeUrl(baseUrl) {
    // Create WebSocket base URL more carefully
    final uri = Uri.parse(this.baseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    wsBaseUrl = '$wsScheme://${uri.host}:${uri.port}';
  }

  static String _normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'http://$url';
  }

  // ================= REST API =================

  /// Generic POST helper that sends a request to [path] and parses a
  /// [CameraStatus] from the JSON response. Returns null on failure.
  Future<CameraStatus?> _postCameraStatus(String path) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl$path'));
      if (response.statusCode == 200) {
        return CameraStatus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<CameraStatus?> getStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/status'));
      if (response.statusCode == 200) {
        return CameraStatus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<CameraStatus?> attachServos() => _postCameraStatus('/api/servos/attach');

  Future<CameraStatus?> detachServos() => _postCameraStatus('/api/servos/detach');

  Future<CameraStatus?> centerServos() => _postCameraStatus('/api/servos/center');

  Future<CameraStatus?> startPatrol() => _postCameraStatus('/api/patrol/start');

  Future<CameraStatus?> stopPatrol() => _postCameraStatus('/api/patrol/stop');

  Future<CameraStatus?> startSmartPatrol() => _postCameraStatus('/api/smart_patrol/start');

  Future<CameraStatus?> stopSmartPatrol() => _postCameraStatus('/api/smart_patrol/stop');

  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // ================= WebSocket: Manual Mode =================

  WebSocketChannel? _manualWs;
  bool get isManualConnected => _manualWs != null;

  /// Connect to /ws/manual for manual pan/tilt control
  Future<void> connectManualWebSocket({
    void Function()? onDone,
    void Function(dynamic)? onError,
    void Function(Map<String, dynamic>)? onStatusUpdate,
  }) async {
    await disconnectManualWebSocket();
    final url = '$wsBaseUrl/ws/manual';
    _manualWs = WebSocketChannel.connect(Uri.parse(url));
    _manualWs!.stream.listen(
      (message) {
        // Handle messages from server (like initial status)
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'status' && onStatusUpdate != null) {
            onStatusUpdate(data);
          }
        } catch (_) {
          // Ignore malformed messages
        }
      },
      onDone: () async {
        _manualWs = null;
        if (onDone != null) onDone();
      },
      onError: (err) async {
        _manualWs = null;
        if (onError != null) onError(err);
      },
    );
  }

  /// Send pan/tilt command (0-170, 0-150)
  void sendManualPanTilt(int pan, int tilt) {
    if (_manualWs != null) {
      final msg = jsonEncode({'pan': pan, 'tilt': tilt});
      _manualWs!.sink.add(msg);
    }
  }

  Future<void> disconnectManualWebSocket() async {
    if (_manualWs != null) {
      await _manualWs!.sink.close(1000, 'Client closed');
      _manualWs = null;
    }
  }

  // ================= WebSocket: Face Detection =================

  WebSocketChannel? _faceDetectionWs;
  StreamController<FaceDetectionEvent>? _faceDetectionController;
  bool get isFaceDetectionConnected => _faceDetectionWs != null;
  Stream<FaceDetectionEvent>? get faceDetectionStream =>
      _faceDetectionController?.stream;

  /// Connect to /ws/face_detection for real-time face events
  Future<void> connectFaceDetectionWebSocket({
    void Function()? onDone,
    void Function(dynamic)? onError,
  }) async {
    await disconnectFaceDetectionWebSocket();
    final url = '$wsBaseUrl/ws/face_detection';
    _faceDetectionWs = WebSocketChannel.connect(Uri.parse(url));
    _faceDetectionController = StreamController<FaceDetectionEvent>.broadcast();
    _faceDetectionWs!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          final event = FaceDetectionEvent.fromJson(data);
          _faceDetectionController?.add(event);
        } catch (_) {}
      },
      onDone: () async {
        if (_faceDetectionController != null &&
            !_faceDetectionController!.isClosed) {
          await _faceDetectionController?.close();
        }
        _faceDetectionWs = null;
        if (onDone != null) onDone();
      },
      onError: (err) async {
        _faceDetectionController?.addError(err);
        if (_faceDetectionController != null &&
            !_faceDetectionController!.isClosed) {
          await _faceDetectionController?.close();
        }
        _faceDetectionWs = null;
        if (onError != null) onError(err);
      },
    );
  }

  Future<void> disconnectFaceDetectionWebSocket() async {
    if (_faceDetectionWs != null) {
      await _faceDetectionWs!.sink.close(1000, 'Client closed');
      _faceDetectionWs = null;
    }
    if (_faceDetectionController != null &&
        !_faceDetectionController!.isClosed) {
      await _faceDetectionController?.close();
    }
    _faceDetectionController = null;
  }

  // ================= WebRTC Stream =================

  /// Get WebRTC stream URL (mediamtx on port 8889)
  String getWebRTCStreamUrl() {
    final uri = Uri.parse(baseUrl);
    final webRTCUrl = '${uri.scheme}://${uri.host}:8889/cam';
    return webRTCUrl;
  }
}
