import 'package:flutter/material.dart';

/// Navigation service for global navigation and dialog management
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get the current context from navigator
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Show dialog globally
  static void showGlobalDialog(Widget dialog) {
    final context = currentContext;
    if (context != null) {
      showDialog(context: context, builder: (context) => dialog);
    }
  }
}
