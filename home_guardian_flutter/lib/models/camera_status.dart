/// Camera status model matching /api/status
class CameraStatus {
  final bool active;
  final String mode;
  final int currentPan;
  final int currentTilt;
  final String lastUpdate;

  CameraStatus({
    required this.active,
    required this.mode,
    required this.currentPan,
    required this.currentTilt,
    required this.lastUpdate,
  });

  factory CameraStatus.fromJson(Map<String, dynamic> json) {
    return CameraStatus(
      active: json['active'] ?? false,
      mode: json['mode'] ?? 'inactive',
      currentPan: json['current_pan'] ?? 90,
      currentTilt: json['current_tilt'] ?? 90,
      lastUpdate: json['last_update'] ?? '',
    );
  }

  @override
  String toString() {
    return 'CameraStatus(active: $active, mode: $mode, currentPan: $currentPan, currentTilt: $currentTilt, lastUpdate: $lastUpdate)';
  }
}
