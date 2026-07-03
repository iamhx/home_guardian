import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/home_guardian_client_v2.dart';
import '../models/camera_status.dart';
import '../services/action_log_service.dart';
import '../models/action_log.dart';

class CameraViewProvider extends ChangeNotifier {
  HomeGuardianClientV2? _client;
  CameraStatus? _cameraStatus;
  String? _error;
  String? _cameraName; // Add camera name to track for logging

  //Slider pan/tilt
  double _sliderPan = 90.0;
  double _sliderTilt = 90.0;

  //Loading states
  bool _isLoading = true;
  bool _isPowerLoading = false;
  bool _isPatrolLoading = false;
  bool _isSmartPatrolLoading = false;
  bool _isLoadingCenterServos = false;

  // Face detection data
  int _facesDetected = 0;
  StreamSubscription? _faceDetectionSub;

  // WebRTC stream
  bool _isStreamReady = false;
  bool webRTCStreamBuilt = false;

  // Getters
  CameraStatus? get cameraStatus => _cameraStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get facesDetected => _facesDetected;
  bool get isStreamReady => _isStreamReady;
  bool get isPowerLoading => _isPowerLoading;
  bool get isPatrolLoading => _isPatrolLoading;
  bool get isSmartPatrolLoading => _isSmartPatrolLoading;
  bool get isLoadingCenterServos => _isLoadingCenterServos;
  double get sliderPan => _sliderPan;
  double get sliderTilt => _sliderTilt;

  //Setters
  void setSliderPan(double value) {
    _sliderPan = value;
    _sendManualCommand();
    notifyListeners();
  }

  void setSliderTilt(double value) {
    _sliderTilt = value;
    _sendManualCommand();
    notifyListeners();
  }

  // Send manual pan/tilt command via WebSocket
  void _sendManualCommand() {
    if (_client != null && _client!.isManualConnected) {
      _client!.sendManualPanTilt(_sliderPan.toInt(), _sliderTilt.toInt());
    }
  }

  // Computed getters
  bool get servosActive => _cameraStatus?.active == true;
  String get mode => _cameraStatus?.mode ?? 'inactive';

  Future<void> initialize(String url, {String? cameraName}) async {
    _isLoading = true;
    _error = null;
    _cameraStatus = null;
    _isStreamReady = false;
    _facesDetected = 0;
    _cameraName = cameraName; // Store camera name for logging
    await stopFaceDetection();
    notifyListeners();

    try {
      _client ??= HomeGuardianClientV2(baseUrl: url);

      final status = await _client!.getStatus();
      if (status == null) throw Exception('Failed to load camera status');
      _cameraStatus = status;

      final healthCheck = await _client!.getHealth();
      if (healthCheck == null) throw Exception('Camera went offline');
      _isStreamReady = healthCheck['ready'] == true;
      await startFaceDetection();
    } catch (e) {
      _error = e.toString();
      _cameraStatus = null;
      _isStreamReady = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initializeManualControl() async {
    if (_client == null) throw Exception('Client not initialized');
    var status = await _client!.getStatus();
    if (status == null) throw Exception('Failed to load camera status');
    _cameraStatus = status;
    _sliderPan = _cameraStatus!.currentPan.toDouble();
    _sliderTilt = _cameraStatus!.currentTilt.toDouble();

    // Connect to manual control WebSocket
    await _client!.connectManualWebSocket(
      onDone: () {},
      onError: (error) {
        _error = 'Manual control connection error: $error';
        notifyListeners();
      },
      onStatusUpdate: (statusData) {
        // Update camera status from WebSocket message
        _cameraStatus = CameraStatus(
          active: statusData['active'] ?? false,
          mode: statusData['mode'] ?? 'inactive',
          currentPan: statusData['current_pan'] ?? 90,
          currentTilt: statusData['current_tilt'] ?? 90,
          lastUpdate:
              statusData['last_update'] ?? DateTime.now().toIso8601String(),
        );
        _sliderPan = _cameraStatus!.currentPan.toDouble();
        _sliderTilt = _cameraStatus!.currentTilt.toDouble();
        notifyListeners();
      },
    );

    // Log manual mode start
    if (_cameraName != null) {
      ActionLogService.logAction(
        cameraName: _cameraName!,
        actionType: ActionType.manualModeStart,
      );
    }

    // Remove the delay and extra getStatus call since we now get status via WebSocket
    notifyListeners();
  }

  Future<void> disposeManualControl() async {
    if (_client == null) throw Exception('Client not initialized');
    await _client!.disconnectManualWebSocket();

    // Log manual mode stop
    if (_cameraName != null) {
      ActionLogService.logAction(
        cameraName: _cameraName!,
        actionType: ActionType.manualModeStop,
      );
    }

    // Give the server a moment to process the mode change from MANUAL to IDLE
    await Future.delayed(Duration(milliseconds: 400));

    final status = await _client!.getStatus();
    if (status == null) throw Exception('Failed to load camera status');
    _cameraStatus = status;
    notifyListeners();
  }

  Future<void> centerServos() async {
    _isLoadingCenterServos = true;
    notifyListeners();
    if (_client == null) throw Exception('Client not initialized');
    final status = await _client!.centerServos();
    if (status == null) throw Exception('Failed to load camera status');
    _cameraStatus = status;
    _sliderPan = _cameraStatus!.currentPan.toDouble();
    _sliderTilt = _cameraStatus!.currentTilt.toDouble();
    _isLoadingCenterServos = false;
    notifyListeners();
  }

  /// Start listening for face detection events from the backend WebSocket
  Future<void> startFaceDetection() async {
    if (_client == null) throw Exception('Client not initialized');
    await _client!.connectFaceDetectionWebSocket();
    final stream = _client!.faceDetectionStream;
    if (stream == null) {
      throw Exception('Failed to connect to face detection WebSocket');
    }
    _faceDetectionSub = stream.listen(
      (event) {
        _facesDetected = event.faceCount;
        notifyListeners();
      },
      onError: (err) {
        _facesDetected = 0;
        _error =
            'Face detection error: '
            '${err is Exception ? err.toString() : (err ?? 'Unknown error')}';
        notifyListeners();
      },
    );
  }

  Future<void> stopFaceDetection() async {
    await _faceDetectionSub?.cancel();
    _faceDetectionSub = null;
    await _client?.disconnectFaceDetectionWebSocket();
  }

  Future<void> cleanup() async {
    await stopFaceDetection();
  }

  String? getWebRTCStreamUrl() {
    if (_client == null) return null;
    return _client!.getWebRTCStreamUrl();
  }

  /// Generic toggle helper that encapsulates the repeated pattern:
  /// guard -> set loading -> determine action -> call API -> log -> unset loading.
  Future<void> _executeToggle({
    required bool isAlreadyLoading,
    required void Function(bool) setLoading,
    required bool condition,
    required Future<CameraStatus?> Function() onTrue,
    required Future<CameraStatus?> Function() onFalse,
    required ActionType actionOnTrue,
    required ActionType actionOnFalse,
    required String errorPrefix,
  }) async {
    if (_client == null || _cameraStatus == null || isAlreadyLoading) return;

    setLoading(true);
    notifyListeners();

    try {
      final newStatus = condition ? await onTrue() : await onFalse();
      final actionType = condition ? actionOnTrue : actionOnFalse;

      if (newStatus != null) {
        _cameraStatus = newStatus;
        if (_cameraName != null) {
          ActionLogService.logAction(
            cameraName: _cameraName!,
            actionType: actionType,
          );
        }
      }
    } catch (e) {
      _error = '$errorPrefix: $e';
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<void> togglePower() => _executeToggle(
    isAlreadyLoading: _isPowerLoading,
    setLoading: (v) => _isPowerLoading = v,
    condition: _cameraStatus?.active == true,
    onTrue: () => _client!.detachServos(),
    onFalse: () => _client!.attachServos(),
    actionOnTrue: ActionType.powerOff,
    actionOnFalse: ActionType.powerOn,
    errorPrefix: 'Power toggle failed',
  );

  Future<void> togglePatrol() => _executeToggle(
    isAlreadyLoading: _isPatrolLoading,
    setLoading: (v) => _isPatrolLoading = v,
    condition: _cameraStatus?.mode == 'patrol',
    onTrue: () => _client!.stopPatrol(),
    onFalse: () => _client!.startPatrol(),
    actionOnTrue: ActionType.patrolStop,
    actionOnFalse: ActionType.patrolStart,
    errorPrefix: 'Patrol toggle failed',
  );

  Future<void> toggleSmartPatrol() => _executeToggle(
    isAlreadyLoading: _isSmartPatrolLoading,
    setLoading: (v) => _isSmartPatrolLoading = v,
    condition: _cameraStatus?.mode == 'smart',
    onTrue: () => _client!.stopSmartPatrol(),
    onFalse: () => _client!.startSmartPatrol(),
    actionOnTrue: ActionType.smartPatrolStop,
    actionOnFalse: ActionType.smartPatrolStart,
    errorPrefix: 'Smart patrol toggle failed',
  );
}
