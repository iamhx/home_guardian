import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/dialog_utils.dart';
import 'navigation_service.dart';

/// Service for handling Firebase Cloud Messaging notifications
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _isWakeWordDialogShowing = false;

  /// Initialize FCM and set up message listeners
  static Future<void> init({
    Function(RemoteMessage)? onForegroundMessage,
    Function(RemoteMessage)? onNotificationTap,
  }) async {
    await _messaging.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Check if it's a wake word notification
      if (message.data['type'] == 'wake_word' ||
          message.notification?.title?.contains('Home Guardian Alert') ==
              true) {
        _showWakeWordDialog(message);
      }

      if (onForegroundMessage != null) onForegroundMessage(message);
    });

    // Handle notification taps (when app is in background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Check if it's a wake word notification
      if (message.data['type'] == 'wake_word' ||
          message.notification?.title?.contains('Home Guardian Alert') ==
              true) {
        // Small delay to ensure the app has fully loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          _showWakeWordDialog(message);
        });
      }

      if (onNotificationTap != null) onNotificationTap(message);
    });
  }

  /// Centralized method to show wake word dialog with duplicate prevention
  static void _showWakeWordDialog(RemoteMessage message) {
    if (_isWakeWordDialogShowing) {
      return;
    }

    final context = NavigationService.currentContext;
    if (context != null) {
      try {
        _isWakeWordDialogShowing = true;
        DialogUtils.showWakeWordDialog(context, message);

        // Reset flag after a delay to allow for dialog dismissal
        Future.delayed(const Duration(seconds: 1), () {
          _isWakeWordDialogShowing = false;
        });
      } catch (e) {
        debugPrint('[FCM] Error showing wake word dialog: $e');
        _isWakeWordDialogShowing = false;
      }
    }
  }

  /// Get the FCM token for this device
  static Future<String?> getToken() => _messaging.getToken();

  /// Subscribe to the wake-word topic for notifications
  static Future<void> subscribeToWakeWordTopic() async {
    await _messaging.subscribeToTopic('wake-word');
  }

  /// Unsubscribe from the wake-word topic
  static Future<void> unsubscribeFromWakeWordTopic() async {
    await _messaging.unsubscribeFromTopic('wake-word');
  }
}
