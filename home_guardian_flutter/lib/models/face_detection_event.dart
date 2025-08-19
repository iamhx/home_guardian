/// Face detection event model from /ws/face_detection
class FaceDetectionEvent {
  final int faceCount;
  final bool detected;

  FaceDetectionEvent({required this.faceCount, required this.detected});

  factory FaceDetectionEvent.fromJson(Map<String, dynamic> json) {
    return FaceDetectionEvent(
      faceCount: json['face_count'] ?? 0,
      detected: json['detected'] ?? false,
    );
  }
}
