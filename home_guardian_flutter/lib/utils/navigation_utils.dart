import 'package:flutter/material.dart';
import 'package:home_guardian/pages/camera_view/camera_view_page_wrapper.dart';
import '../models/camera.dart';
import '../services/camera_service.dart';

/// Utility function to guard navigation to the camera view.
Future<void> navigateToCameraViewGuarded({
  required BuildContext context,
  required Camera camera,
}) async {
  bool isOnline = false;
  String? errorMessage;

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Force refresh status for this camera
    final health = await CameraService.getServerHealth(camera.url);
    isOnline = health != null && health['ready'] == true;
    if (!isOnline) {
      errorMessage = 'Camera server is offline or unreachable.';
    }
  } catch (e) {
    errorMessage = 'Failed to connect to camera server: $e';
  }

  // Check if context is still mounted before using it
  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

  if (!context.mounted) return;

  if (isOnline) {
    // Navigate to camera view
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraViewPageWrapper(camera: camera),
      ),
    );
  } else {
    // Show error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: Text(errorMessage ?? 'Unknown error.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
