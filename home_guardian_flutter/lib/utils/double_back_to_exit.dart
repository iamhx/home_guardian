import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that wraps its child and requires the user to press back twice to exit the app.
/// Shows a snackbar on first back press, exits on second within [interval].
class DoubleBackToExitWrapper extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration interval;

  const DoubleBackToExitWrapper({
    super.key,
    required this.child,
    this.message = 'Press back again to exit',
    this.interval = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackToExitWrapper> createState() => _DoubleBackToExitWrapperState();
}

class _DoubleBackToExitWrapperState extends State<DoubleBackToExitWrapper> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: widget.child,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > widget.interval) {
          _lastPressedAt = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(widget.message)),
            );
          }
          // Block pop
          return;
        }
        // Allow pop (exit app)
        await SystemNavigator.pop();
      },
    );
  }
}
