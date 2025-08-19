import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'camera.g.dart';

@HiveType(typeId: 0)
class Camera extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final CameraStatus status;

  @HiveField(5)
  final DateTime lastChecked;

  @HiveField(6)
  final DateTime dateAdded;

  Camera({
    required this.id,
    required this.name,
    required this.url,
    this.description,
    required this.status,
    required this.lastChecked,
    required this.dateAdded,
  });

  // Create from Map (for migration or manual creation)
  factory Camera.fromMap(Map<String, dynamic> data, String id) {
    return Camera(
      id: id,
      name: data['name'] ?? 'Unnamed Camera',
      url: data['url'] ?? '',
      description: data['description'],
      status: CameraStatus.values.firstWhere(
        (e) => e.toString() == 'CameraStatus.${data['status']}',
        orElse: () => CameraStatus.offline,
      ),
      lastChecked: data['lastChecked'] is DateTime 
          ? data['lastChecked']
          : DateTime.fromMillisecondsSinceEpoch(
              data['lastChecked']?.millisecondsSinceEpoch ?? 0,
            ),
      dateAdded: data['dateAdded'] is DateTime
          ? data['dateAdded']
          : DateTime.fromMillisecondsSinceEpoch(
              data['dateAdded']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            ),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'description': description,
      'status': status.toString().split('.').last,
      'lastChecked': lastChecked,
      'dateAdded': dateAdded,
    };
  }

  // Create a copy with updated values
  Camera copyWith({
    String? id,
    String? name,
    String? url,
    String? description,
    CameraStatus? status,
    DateTime? lastChecked,
    DateTime? dateAdded,
  }) {
    return Camera(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  String toString() {
    return 'Camera(id: $id, name: $name, url: $url, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Camera && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 1)
enum CameraStatus {
  @HiveField(0)
  online,
  @HiveField(1)
  offline,
  @HiveField(2)
  checking,
}

extension CameraStatusExtension on CameraStatus {
  String get displayName {
    switch (this) {
      case CameraStatus.online:
        return 'Online';
      case CameraStatus.offline:
        return 'Offline';
      case CameraStatus.checking:
        return 'Checking...';
    }
  }

  Color get color {
    switch (this) {
      case CameraStatus.online:
        return const Color(0xFF10B981); // Green
      case CameraStatus.offline:
        return const Color(0xFFEF4444); // Red
      case CameraStatus.checking:
        return const Color(0xFF6B7280); // Gray
    }
  }
}
