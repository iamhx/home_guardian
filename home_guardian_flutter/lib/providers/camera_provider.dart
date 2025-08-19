import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/camera.dart';
import '../services/camera_service.dart';

class CameraProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Camera> _cameras = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _statusCheckTimer;
  bool _isRefreshingStatuses = false; // Prevent multiple simultaneous refreshes
  Box<Camera>? _cameraBox;

  // Getters
  List<Camera> get cameras => _cameras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCameras => _cameras.isNotEmpty;

  CameraProvider() {
    _initializeHive();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _cameraBox?.close();
    super.dispose();
  }

  /// Initialize Hive and load cameras from local storage
  Future<void> _initializeHive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Open user-specific camera box
      final boxName = 'cameras_${user.uid}';
      _cameraBox = await Hive.openBox<Camera>(boxName);
      
      // Load cameras from local storage
      _cameras = _cameraBox!.values.toList();
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      if (_cameras.isNotEmpty) {
        Future.microtask(() => refreshAllCameraStatuses());
        _startPeriodicStatusChecking();
      }
      
    } catch (e) {
      _errorMessage = 'Failed to initialize local storage: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new camera to local storage
  Future<bool> addCamera({
    required String name,
    required String url,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'User not authenticated';
      notifyListeners();
      return false;
    }

    if (_cameraBox == null) {
      _errorMessage = 'Storage not initialized';
      notifyListeners();
      return false;
    }

    // Validate URL format
    if (!CameraService.isValidUrl(url)) {
      _errorMessage = 'Invalid URL format';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validate Home Guardian server using /api/health
      final isValidServer = await CameraService.testServerConnection(url);
      if (!isValidServer) {
        _errorMessage = 'No Home Guardian server found at $url. Please ensure the server is running and accessible.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Generate unique ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      // Get current status from /api/health
      CameraStatus status = CameraStatus.offline;
      final health = await CameraService.getServerHealth(url);
      if (health != null && health['ready'] == true) {
        status = CameraStatus.online;
      }

      // Create camera object
      final camera = Camera(
        id: id,
        name: name,
        url: url,
        description: description,
        status: status,
        lastChecked: now,
        dateAdded: now,
      );

      // Save to Hive
      await _cameraBox!.put(id, camera);
      
      // Update local list
      _cameras = _cameraBox!.values.toList();
      
      _isLoading = false;
      notifyListeners();
      
      if (_cameras.length == 1) {
        _startPeriodicStatusChecking();
      }
      
      return true;

    } catch (e) {
      _errorMessage = 'Failed to add camera: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a camera from local storage
  Future<bool> removeCamera(String cameraId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    if (_cameraBox == null) {
      _errorMessage = 'Storage not initialized';
      notifyListeners();
      return false;
    }

    try {
      // Remove from Hive
      await _cameraBox!.delete(cameraId);
      
      // Update local list
      _cameras = _cameraBox!.values.toList();
      notifyListeners();
      
      if (_cameras.isEmpty) {
        _stopPeriodicStatusChecking();
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove camera: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update camera information in local storage
  Future<bool> updateCamera({
    required String cameraId,
    String? name,
    String? url,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    if (_cameraBox == null) {
      _errorMessage = 'Storage not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Get existing camera
      final existingCamera = _cameraBox!.get(cameraId);
      if (existingCamera == null) {
        _errorMessage = 'Camera not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate URL if provided
      if (url != null) {
        if (!CameraService.isValidUrl(url)) {
          _errorMessage = 'Invalid URL format';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
      // Validate Home Guardian server for new URL using /api/health
      final isValidServer = await CameraService.testServerConnection(url);
      if (!isValidServer) {
        _errorMessage = 'No Home Guardian server found at $url. Please ensure the server is running and accessible.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      }

      // Create updated camera
      final updatedCamera = Camera(
        id: existingCamera.id,
        name: name ?? existingCamera.name,
        url: url ?? existingCamera.url,
        description: description ?? existingCamera.description,
        status: existingCamera.status, // Keep existing status
        lastChecked: existingCamera.lastChecked,
        dateAdded: existingCamera.dateAdded,
      );

      // Save to Hive
      await _cameraBox!.put(cameraId, updatedCamera);
      
      // Update local list
      _cameras = _cameraBox!.values.toList();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update camera: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void resetRefreshFlag() {
    _isRefreshingStatuses = false;
  }

  Future<void> forceStatusRefresh() async {
    if (_cameras.isNotEmpty) {
      await refreshAllCameraStatuses();
    }
  }

  /// Manually refresh all camera statuses
  Future<void> refreshAllCameraStatuses() async {
    // Prevent multiple simultaneous refreshes
    if (_isRefreshingStatuses) {
      return;
    }
    
    if (_cameras.isEmpty) {
      return;
    }

    if (_cameraBox == null) {
      return;
    }

    _isRefreshingStatuses = true;

    try {
      // Add a timeout to the entire refresh operation
      await _performRefresh().timeout(const Duration(seconds: 30));
      
    } catch (e) {
      // If we timeout or fail, mark all cameras as offline
      for (final camera in _cameras) {
        await _updateCameraStatus(camera.id, CameraStatus.offline);
      }
    } finally {
      _isRefreshingStatuses = false;
    }
  }

  /// Perform the actual refresh operation
  Future<void> _performRefresh() async {
    // Update all cameras to checking status first
    for (final camera in _cameras) {
      await _updateCameraStatus(camera.id, CameraStatus.checking);
    }

    // Check each camera status using /api/health and the 'ready' field
    final futures = _cameras.map((camera) async {
      try {
        final health = await CameraService.getServerHealth(camera.url);
        final isOnline = health != null && health['ready'] == true;
        await _updateCameraStatus(
          camera.id,
          isOnline ? CameraStatus.online : CameraStatus.offline,
        );
      } catch (e) {
        await _updateCameraStatus(camera.id, CameraStatus.offline);
      }
    });
    await Future.wait(futures);
  }

  /// Update camera status in local storage
  Future<void> _updateCameraStatus(String cameraId, CameraStatus status) async {
    if (_cameraBox == null) return;

    try {
      final existingCamera = _cameraBox!.get(cameraId);
      if (existingCamera == null) return;

      // Create updated camera with new status
      final updatedCamera = Camera(
        id: existingCamera.id,
        name: existingCamera.name,
        url: existingCamera.url,
        description: existingCamera.description,
        status: status,
        lastChecked: DateTime.now(),
        dateAdded: existingCamera.dateAdded,
      );

      // Save to Hive
      await _cameraBox!.put(cameraId, updatedCamera);
      
      // Update local list
      _cameras = _cameraBox!.values.toList();
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to update camera status: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Start periodic status checking (every 2 minutes)
  void _startPeriodicStatusChecking() {
    _statusCheckTimer?.cancel();
    
    if (_cameras.isEmpty) {
      return;
    }

    _statusCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_cameras.isNotEmpty) {
        refreshAllCameraStatuses();
      } else {
        timer.cancel();
      }
    });
  }

  /// Stop periodic status checking
  void _stopPeriodicStatusChecking() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  /// Get camera by ID
  Camera? getCameraById(String id) {
    try {
      return _cameras.firstWhere((camera) => camera.id == id);
    } catch (e) {
      return null;
    }
  }
}
