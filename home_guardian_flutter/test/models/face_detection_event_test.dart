import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/models/face_detection_event.dart';

void main() {
  group('FaceDetectionEvent', () {
    test('fromJson parses correctly when face detected', () {
      final json = {'face_count': 2, 'detected': true};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 2);
      expect(event.detected, true);
    });

    test('fromJson parses correctly when no face detected', () {
      final json = {'face_count': 0, 'detected': false};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 0);
      expect(event.detected, false);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 0);
      expect(event.detected, false);
    });

    test('fromJson handles null values with defaults', () {
      final json = {'face_count': null, 'detected': null};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 0);
      expect(event.detected, false);
    });

    test('fromJson handles single face', () {
      final json = {'face_count': 1, 'detected': true};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 1);
      expect(event.detected, true);
    });

    test('fromJson handles many faces', () {
      final json = {'face_count': 10, 'detected': true};

      final event = FaceDetectionEvent.fromJson(json);

      expect(event.faceCount, 10);
      expect(event.detected, true);
    });
  });
}
