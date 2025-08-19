import 'package:cloud_firestore/cloud_firestore.dart';

class ActionLog {
  final String id;
  final DateTime timestamp;
  final String cameraName;
  final String userId;
  final String userEmail;
  final ActionType actionType;

  ActionLog({
    required this.id,
    required this.timestamp,
    required this.cameraName,
    required this.userId,
    required this.userEmail,
    required this.actionType,
  });

  // Convert from Firestore document
  factory ActionLog.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActionLog(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      cameraName: data['camera_name'] ?? '',
      userId: data['user_id'] ?? '',
      userEmail: data['user_email'] ?? '',
      actionType: ActionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['action_type'],
        orElse: () => ActionType.unknown,
      ),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'camera_name': cameraName,
      'user_id': userId,
      'user_email': userEmail,
      'action_type': actionType.toString().split('.').last,
    };
  }

  String get actionDescription => actionType.description;
}

enum ActionType {
  powerOn,
  powerOff,
  patrolStart,
  patrolStop,
  smartPatrolStart,
  smartPatrolStop,
  manualModeStart,
  manualModeStop,
  unknown,
}

extension ActionTypeExtension on ActionType {
  String get description {
    switch (this) {
      case ActionType.powerOn:
        return 'Camera powered on';
      case ActionType.powerOff:
        return 'Camera powered off';
      case ActionType.patrolStart:
        return 'Patrol started';
      case ActionType.patrolStop:
        return 'Patrol stopped';
      case ActionType.smartPatrolStart:
        return 'Smart patrol started';
      case ActionType.smartPatrolStop:
        return 'Smart patrol stopped';
      case ActionType.manualModeStart:
        return 'Manual control started';
      case ActionType.manualModeStop:
        return 'Manual control stopped';
      case ActionType.unknown:
        return 'Unknown action';
    }
  }

  String get icon {
    switch (this) {
      case ActionType.powerOn:
        return '⚡';
      case ActionType.powerOff:
        return '🔌';
      case ActionType.patrolStart:
        return '🔄';
      case ActionType.patrolStop:
        return '⏹️';
      case ActionType.smartPatrolStart:
        return '🤖';
      case ActionType.smartPatrolStop:
        return '🛑';
      case ActionType.manualModeStart:
        return '🎮';
      case ActionType.manualModeStop:
        return '🔒';
      case ActionType.unknown:
        return '❓';
    }
  }
}
