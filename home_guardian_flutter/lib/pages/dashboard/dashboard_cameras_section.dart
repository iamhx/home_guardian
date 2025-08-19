import 'package:flutter/material.dart';
import '../../providers/camera_provider.dart';
import 'dashboard_camera_grid.dart';
import 'dashboard_empty_state.dart';

class DashboardCamerasSection extends StatelessWidget {
  final CameraProvider cameraProvider;
  final VoidCallback onAddCamera;
  const DashboardCamerasSection({super.key, required this.cameraProvider, required this.onAddCamera});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              const Text(
                'My Cameras',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (cameraProvider.hasCameras)
                Text(
                  '${cameraProvider.cameras.length} camera${cameraProvider.cameras.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Camera Grid
          Expanded(
            child: cameraProvider.isLoading && !cameraProvider.hasCameras
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : cameraProvider.hasCameras
                    ? DashboardCameraGrid(cameraProvider: cameraProvider, onAddCamera: onAddCamera)
                    : DashboardEmptyState(onAddCamera: onAddCamera),
          ),
        ],
      ),
    );
  }
}
