import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/models/camera_status.dart';

void main() {
  group('CameraStatus', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'active': true,
        'mode': 'patrol',
        'current_pan': 45,
        'current_tilt': 120,
        'last_update': '2025-01-01T00:00:00',
      };

      final status = CameraStatus.fromJson(json);

      expect(status.active, true);
      expect(status.mode, 'patrol');
      expect(status.currentPan, 45);
      expect(status.currentTilt, 120);
      expect(status.lastUpdate, '2025-01-01T00:00:00');
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final status = CameraStatus.fromJson(json);

      expect(status.active, false);
      expect(status.mode, 'inactive');
      expect(status.currentPan, 90);
      expect(status.currentTilt, 90);
      expect(status.lastUpdate, '');
    });

    test('fromJson handles null values with defaults', () {
      final json = {
        'active': null,
        'mode': null,
        'current_pan': null,
        'current_tilt': null,
        'last_update': null,
      };

      final status = CameraStatus.fromJson(json);

      expect(status.active, false);
      expect(status.mode, 'inactive');
      expect(status.currentPan, 90);
      expect(status.currentTilt, 90);
      expect(status.lastUpdate, '');
    });

    test('fromJson handles inactive mode', () {
      final json = {
        'active': false,
        'mode': 'inactive',
        'current_pan': 90,
        'current_tilt': 90,
        'last_update': '2025-06-01T12:00:00',
      };

      final status = CameraStatus.fromJson(json);

      expect(status.active, false);
      expect(status.mode, 'inactive');
    });

    test('fromJson handles smart mode', () {
      final json = {
        'active': true,
        'mode': 'smart',
        'current_pan': 85,
        'current_tilt': 60,
        'last_update': '2025-06-01T12:00:00',
      };

      final status = CameraStatus.fromJson(json);

      expect(status.mode, 'smart');
    });

    test('fromJson handles manual mode', () {
      final json = {
        'active': true,
        'mode': 'manual',
        'current_pan': 170,
        'current_tilt': 150,
        'last_update': '2025-06-01T12:00:00',
      };

      final status = CameraStatus.fromJson(json);

      expect(status.mode, 'manual');
      expect(status.currentPan, 170);
      expect(status.currentTilt, 150);
    });

    test('toString returns formatted string', () {
      final status = CameraStatus(
        active: true,
        mode: 'idle',
        currentPan: 90,
        currentTilt: 90,
        lastUpdate: '2025-01-01T00:00:00',
      );

      final str = status.toString();

      expect(str, contains('active: true'));
      expect(str, contains('mode: idle'));
      expect(str, contains('currentPan: 90'));
      expect(str, contains('currentTilt: 90'));
    });

    test('fromJson with extreme pan/tilt values', () {
      final json = {
        'active': true,
        'mode': 'manual',
        'current_pan': 0,
        'current_tilt': 0,
        'last_update': '2025-01-01T00:00:00',
      };

      final status = CameraStatus.fromJson(json);

      expect(status.currentPan, 0);
      expect(status.currentTilt, 0);
    });
  });
}
