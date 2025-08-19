import 'package:flutter/material.dart';
import '../../providers/camera_provider.dart';
import '../../utils/navigation_utils.dart';
import 'dashboard_camera_card.dart';
import 'dashboard_camera_options.dart';

class DashboardCameraGrid extends StatelessWidget {
  final CameraProvider cameraProvider;
  final VoidCallback onAddCamera;
  const DashboardCameraGrid({super.key, required this.cameraProvider, required this.onAddCamera});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: cameraProvider.cameras.length + 1,
      itemBuilder: (context, index) {
        if (index == cameraProvider.cameras.length) {
          // Add Camera Card
          return AddCameraCard(onTap: onAddCamera);
        }
        final camera = cameraProvider.cameras[index];
        return CameraCard(
          camera: camera,
          onTap: () {
            navigateToCameraViewGuarded(context: context, camera: camera);
          },
          onLongPress: () => showDashboardCameraOptions(context, camera, cameraProvider),
        );
      },
    );
  }
}
