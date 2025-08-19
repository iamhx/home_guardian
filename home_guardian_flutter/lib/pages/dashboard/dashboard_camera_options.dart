import 'package:flutter/material.dart';
import '../../models/camera.dart';
import '../../providers/camera_provider.dart';
import '../../utils/navigation_utils.dart';
import 'dashboard_edit_camera_dialog.dart';

void showDashboardCameraOptions(BuildContext context, Camera camera, CameraProvider cameraProvider) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            camera.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('View Camera'),
            onTap: () {
              Navigator.pop(context);
              navigateToCameraViewGuarded(context: context, camera: camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Camera'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => EditCameraDialog(camera: camera),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove Camera', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              navigator.pop();
              final confirmed = await _showDeleteConfirmation(context, camera.name);
              if (confirmed) {
                final success = await cameraProvider.removeCamera(camera.id);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Camera "${camera.name}" removed successfully'
                        : 'Failed to remove camera "${camera.name}"'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<bool> _showDeleteConfirmation(BuildContext context, String cameraName) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Camera'),
          content: Text('Are you sure you want to remove "$cameraName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;
}
