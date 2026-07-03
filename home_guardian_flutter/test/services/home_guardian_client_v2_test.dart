import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/services/home_guardian_client_v2.dart';

void main() {
  group('HomeGuardianClientV2', () {
    group('URL normalization', () {
      test('preserves http:// prefix', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        expect(client.baseUrl, 'http://192.168.1.100:8234');
      });

      test('preserves https:// prefix', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'https://example.com:8234');

        expect(client.baseUrl, 'https://example.com:8234');
      });

      test('adds http:// when no scheme present', () {
        final client = HomeGuardianClientV2(baseUrl: '192.168.1.100:8234');

        expect(client.baseUrl, 'http://192.168.1.100:8234');
      });

      test('adds http:// for hostname without port', () {
        final client = HomeGuardianClientV2(baseUrl: 'myserver.local');

        expect(client.baseUrl, 'http://myserver.local');
      });
    });

    group('WebSocket URL generation', () {
      test('generates ws:// from http://', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        expect(client.wsBaseUrl, startsWith('ws://'));
        expect(client.wsBaseUrl, contains('192.168.1.100'));
        expect(client.wsBaseUrl, contains('8234'));
      });

      test('generates wss:// from https://', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'https://example.com:8234');

        expect(client.wsBaseUrl, startsWith('wss://'));
        expect(client.wsBaseUrl, contains('example.com'));
      });
    });

    group('WebRTC stream URL', () {
      test('returns correct WebRTC URL with custom port', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        final url = client.getWebRTCStreamUrl();

        expect(url, 'http://192.168.1.100:8889/cam');
      });

      test('preserves scheme for https', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'https://myserver.com:8234');

        final url = client.getWebRTCStreamUrl();

        expect(url, 'https://myserver.com:8889/cam');
      });
    });

    group('connection state', () {
      test('isManualConnected defaults to false', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        expect(client.isManualConnected, false);
      });

      test('isFaceDetectionConnected defaults to false', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        expect(client.isFaceDetectionConnected, false);
      });

      test('faceDetectionStream defaults to null', () {
        final client =
            HomeGuardianClientV2(baseUrl: 'http://192.168.1.100:8234');

        expect(client.faceDetectionStream, isNull);
      });
    });
  });
}
