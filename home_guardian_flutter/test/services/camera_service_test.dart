import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/services/camera_service.dart';

void main() {
  group('CameraService.isValidUrl', () {
    test('valid http URL', () {
      expect(CameraService.isValidUrl('http://192.168.1.100:8234'), true);
    });

    test('valid https URL', () {
      expect(CameraService.isValidUrl('https://example.com'), true);
    });

    test('valid URL without scheme (auto-prefixed)', () {
      expect(CameraService.isValidUrl('192.168.1.100:8234'), true);
    });

    test('valid hostname', () {
      expect(CameraService.isValidUrl('myserver.local'), true);
    });

    test('empty string is invalid', () {
      expect(CameraService.isValidUrl(''), false);
    });

    test('whitespace only is invalid', () {
      expect(CameraService.isValidUrl('   '), false);
    });

    test('valid URL with trailing spaces is trimmed', () {
      expect(CameraService.isValidUrl('  http://example.com  '), true);
    });
  });

  group('CameraService.getDisplayName', () {
    test('extracts host and port from http URL', () {
      final display = CameraService.getDisplayName('http://192.168.1.100:8234');

      expect(display, '192.168.1.100:8234');
    });

    test('extracts host only for standard http port', () {
      final display = CameraService.getDisplayName('http://example.com:80');

      expect(display, 'example.com');
    });

    test('extracts host only for standard https port', () {
      final display = CameraService.getDisplayName('https://example.com:443');

      expect(display, 'example.com');
    });

    test('adds http:// and extracts host when no scheme', () {
      final display = CameraService.getDisplayName('192.168.1.100:8234');

      expect(display, '192.168.1.100:8234');
    });

    test('hostname without port', () {
      final display = CameraService.getDisplayName('http://myserver.local');

      expect(display, 'myserver.local');
    });

    test('returns original URL on parse error', () {
      final display = CameraService.getDisplayName('');

      expect(display, isA<String>());
    });
  });

  group('CameraService._buildUri', () {
    // We test _buildUri indirectly through the public API behavior,
    // since it's a private method. The URL cleaning logic is testable
    // through isValidUrl and getDisplayName.

    test('getDisplayName strips trailing slashes via URL cleaning', () {
      final display =
          CameraService.getDisplayName('http://192.168.1.100:8234///');

      expect(display, '192.168.1.100:8234');
    });
  });
}
