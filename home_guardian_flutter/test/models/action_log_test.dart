import 'package:flutter_test/flutter_test.dart';
import 'package:home_guardian/models/action_log.dart';

void main() {
  group('ActionType', () {
    test('has all expected values', () {
      expect(ActionType.values.length, 9);
      expect(ActionType.values, contains(ActionType.powerOn));
      expect(ActionType.values, contains(ActionType.powerOff));
      expect(ActionType.values, contains(ActionType.patrolStart));
      expect(ActionType.values, contains(ActionType.patrolStop));
      expect(ActionType.values, contains(ActionType.smartPatrolStart));
      expect(ActionType.values, contains(ActionType.smartPatrolStop));
      expect(ActionType.values, contains(ActionType.manualModeStart));
      expect(ActionType.values, contains(ActionType.manualModeStop));
      expect(ActionType.values, contains(ActionType.unknown));
    });
  });

  group('ActionTypeExtension.description', () {
    test('powerOn description', () {
      expect(ActionType.powerOn.description, 'Camera powered on');
    });

    test('powerOff description', () {
      expect(ActionType.powerOff.description, 'Camera powered off');
    });

    test('patrolStart description', () {
      expect(ActionType.patrolStart.description, 'Patrol started');
    });

    test('patrolStop description', () {
      expect(ActionType.patrolStop.description, 'Patrol stopped');
    });

    test('smartPatrolStart description', () {
      expect(ActionType.smartPatrolStart.description, 'Smart patrol started');
    });

    test('smartPatrolStop description', () {
      expect(ActionType.smartPatrolStop.description, 'Smart patrol stopped');
    });

    test('manualModeStart description', () {
      expect(ActionType.manualModeStart.description, 'Manual control started');
    });

    test('manualModeStop description', () {
      expect(ActionType.manualModeStop.description, 'Manual control stopped');
    });

    test('unknown description', () {
      expect(ActionType.unknown.description, 'Unknown action');
    });

    test('all types have non-empty descriptions', () {
      for (final type in ActionType.values) {
        expect(type.description, isNotEmpty);
      }
    });
  });

  group('ActionTypeExtension.icon', () {
    test('all types have non-empty icons', () {
      for (final type in ActionType.values) {
        expect(type.icon, isNotEmpty);
      }
    });

    test('each type has a unique icon', () {
      final icons = ActionType.values.map((t) => t.icon).toSet();
      expect(icons.length, ActionType.values.length);
    });
  });

  group('ActionLog', () {
    test('constructor sets all fields', () {
      final timestamp = DateTime(2025, 6, 1, 12, 0, 0);
      final log = ActionLog(
        id: 'log-1',
        timestamp: timestamp,
        cameraName: 'Living Room',
        userId: 'user-123',
        userEmail: 'test@example.com',
        actionType: ActionType.powerOn,
      );

      expect(log.id, 'log-1');
      expect(log.timestamp, timestamp);
      expect(log.cameraName, 'Living Room');
      expect(log.userId, 'user-123');
      expect(log.userEmail, 'test@example.com');
      expect(log.actionType, ActionType.powerOn);
    });

    test('actionDescription returns type description', () {
      final log = ActionLog(
        id: 'log-2',
        timestamp: DateTime.now(),
        cameraName: 'Kitchen',
        userId: 'user-456',
        userEmail: 'user@example.com',
        actionType: ActionType.patrolStart,
      );

      expect(log.actionDescription, 'Patrol started');
    });

    test('toMap converts correctly', () {
      final timestamp = DateTime(2025, 6, 1, 12, 0, 0);
      final log = ActionLog(
        id: 'log-3',
        timestamp: timestamp,
        cameraName: 'Garage',
        userId: 'user-789',
        userEmail: 'garage@example.com',
        actionType: ActionType.smartPatrolStart,
      );

      final map = log.toMap();

      expect(map['camera_name'], 'Garage');
      expect(map['user_id'], 'user-789');
      expect(map['user_email'], 'garage@example.com');
      expect(map['action_type'], 'smartPatrolStart');
    });

    test('toMap serializes all action types correctly', () {
      for (final type in ActionType.values) {
        final log = ActionLog(
          id: 'test',
          timestamp: DateTime.now(),
          cameraName: 'Test',
          userId: 'user',
          userEmail: 'email',
          actionType: type,
        );

        final map = log.toMap();
        final serialized = map['action_type'] as String;

        expect(serialized, type.toString().split('.').last);
      }
    });
  });
}
