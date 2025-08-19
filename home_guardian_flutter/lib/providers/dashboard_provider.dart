import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firebase_messaging_service.dart';

class DashboardProvider with ChangeNotifier {
  bool _hasNewNotification = false;
  RemoteMessage? _lastMessage;

  bool get hasNewNotification => _hasNewNotification;
  RemoteMessage? get lastMessage => _lastMessage;

  DashboardProvider() {
    _initializeMessaging();
  }

  Future<String?> getToken() async {
    return await FirebaseMessagingService.getToken();
  }

  Future<void> _initializeMessaging() async {
    await FirebaseMessagingService.init(
      onForegroundMessage: _onForegroundMessage,
      onNotificationTap: _onNotificationTap,
    );
  }

  Future<void> subscribeToWakeWordTopic() async {
    await FirebaseMessagingService.subscribeToWakeWordTopic();
  }

  void _onForegroundMessage(RemoteMessage message) {
    _hasNewNotification = true;
    _lastMessage = message;
    notifyListeners();
  }

  void _onNotificationTap(RemoteMessage message) {
    // Optionally handle notification tap
    _hasNewNotification = false;
    _lastMessage = message;
    notifyListeners();
  }

  void clearNotificationFlag() {
    _hasNewNotification = false;
    notifyListeners();
  }
}
