import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/models/camera.dart';

void main() {
  group('Camera', () {
    late Camera camera;
    late DateTime now;

    setUp(() {
      now = DateTime(2025, 1, 1);
      camera = Camera(
        id: 'cam-1',
        name: 'Living Room',
        url: 'http://192.168.1.100:8234',
        description: 'Main camera',
        status: CameraStatus.online,
        lastChecked: now,
        dateAdded: now,
      );
    });

    test('constructor sets all fields', () {
      expect(camera.id, 'cam-1');
      expect(camera.name, 'Living Room');
      expect(camera.url, 'http://192.168.1.100:8234');
      expect(camera.description, 'Main camera');
      expect(camera.status, CameraStatus.online);
      expect(camera.lastChecked, now);
      expect(camera.dateAdded, now);
    });

    test('constructor with null description', () {
      final cam = Camera(
        id: 'cam-2',
        name: 'Kitchen',
        url: 'http://192.168.1.101:8234',
        status: CameraStatus.offline,
        lastChecked: now,
        dateAdded: now,
      );

      expect(cam.description, isNull);
    });

    test('toMap converts correctly', () {
      final map = camera.toMap();

      expect(map['id'], 'cam-1');
      expect(map['name'], 'Living Room');
      expect(map['url'], 'http://192.168.1.100:8234');
      expect(map['description'], 'Main camera');
      expect(map['status'], 'online');
      expect(map['lastChecked'], now);
      expect(map['dateAdded'], now);
    });

    test('copyWith returns new instance with updated fields', () {
      final updated = camera.copyWith(
        name: 'Bedroom',
        status: CameraStatus.offline,
      );

      expect(updated.id, 'cam-1');
      expect(updated.name, 'Bedroom');
      expect(updated.url, 'http://192.168.1.100:8234');
      expect(updated.status, CameraStatus.offline);
      expect(updated.description, 'Main camera');
    });

    test('copyWith with no changes returns equivalent camera', () {
      final copy = camera.copyWith();

      expect(copy.id, camera.id);
      expect(copy.name, camera.name);
      expect(copy.url, camera.url);
      expect(copy.status, camera.status);
    });

    test('equality based on id', () {
      final sameCam = Camera(
        id: 'cam-1',
        name: 'Different Name',
        url: 'http://different.com',
        status: CameraStatus.offline,
        lastChecked: DateTime(2024, 1, 1),
        dateAdded: DateTime(2024, 1, 1),
      );

      expect(camera, equals(sameCam));
    });

    test('inequality with different id', () {
      final differentCam = Camera(
        id: 'cam-2',
        name: 'Living Room',
        url: 'http://192.168.1.100:8234',
        status: CameraStatus.online,
        lastChecked: now,
        dateAdded: now,
      );

      expect(camera, isNot(equals(differentCam)));
    });

    test('hashCode based on id', () {
      expect(camera.hashCode, 'cam-1'.hashCode);
    });

    test('toString includes key fields', () {
      final str = camera.toString();

      expect(str, contains('cam-1'));
      expect(str, contains('Living Room'));
      expect(str, contains('http://192.168.1.100:8234'));
      expect(str, contains('online'));
    });

    test('fromMap with valid data', () {
      final data = {
        'name': 'Garage',
        'url': 'http://192.168.1.102:8234',
        'description': 'Garage cam',
        'status': 'offline',
        'lastChecked': now,
        'dateAdded': now,
      };

      final cam = Camera.fromMap(data, 'cam-3');

      expect(cam.id, 'cam-3');
      expect(cam.name, 'Garage');
      expect(cam.url, 'http://192.168.1.102:8234');
      expect(cam.description, 'Garage cam');
      expect(cam.status, CameraStatus.offline);
    });

    test('fromMap with missing name defaults to Unnamed Camera', () {
      final data = {
        'url': 'http://192.168.1.102:8234',
        'status': 'online',
        'lastChecked': now,
        'dateAdded': now,
      };

      final cam = Camera.fromMap(data, 'cam-4');

      expect(cam.name, 'Unnamed Camera');
    });

    test('fromMap with missing url defaults to empty string', () {
      final data = {
        'name': 'Test',
        'status': 'online',
        'lastChecked': now,
        'dateAdded': now,
      };

      final cam = Camera.fromMap(data, 'cam-5');

      expect(cam.url, '');
    });

    test('fromMap with invalid status defaults to offline', () {
      final data = {
        'name': 'Test',
        'url': 'http://test.com',
        'status': 'nonexistent',
        'lastChecked': now,
        'dateAdded': now,
      };

      final cam = Camera.fromMap(data, 'cam-6');

      expect(cam.status, CameraStatus.offline);
    });
  });

  group('CameraStatus', () {
    test('has three values', () {
      expect(CameraStatus.values.length, 3);
    });

    test('displayName returns correct strings', () {
      expect(CameraStatus.online.displayName, 'Online');
      expect(CameraStatus.offline.displayName, 'Offline');
      expect(CameraStatus.checking.displayName, 'Checking...');
    });

    test('color returns non-null for all statuses', () {
      for (final status in CameraStatus.values) {
        expect(status.color, isNotNull);
      }
    });

    test('online color is green', () {
      expect(CameraStatus.online.color.value, 0xFF10B981);
    });

    test('offline color is red', () {
      expect(CameraStatus.offline.color.value, 0xFFEF4444);
    });

    test('checking color is gray', () {
      expect(CameraStatus.checking.color.value, 0xFF6B7280);
    });
  });
}
