import 'package:flutter/material.dart';
import '../../providers/camera_provider.dart';

class DashboardSystemStatus extends StatelessWidget {
  final CameraProvider cameraProvider;
  const DashboardSystemStatus({super.key, required this.cameraProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSystemStatusColor(cameraProvider).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSystemStatusColor(cameraProvider).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSystemStatusIcon(cameraProvider),
            color: _getSystemStatusColor(cameraProvider),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getSystemStatusText(cameraProvider),
              style: TextStyle(
                color: _getSystemStatusColor(cameraProvider),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSystemStatusColor(CameraProvider cameraProvider) {
    if (!cameraProvider.hasCameras) return Colors.blue;
    final onlineCameras = cameraProvider.cameras.where((c) => c.status.toString() == 'CameraStatus.online').length;
    final totalCameras = cameraProvider.cameras.length;
    if (onlineCameras == totalCameras) return Colors.green;
    if (onlineCameras > 0) return Colors.orange;
    return Colors.red;
  }

  IconData _getSystemStatusIcon(CameraProvider cameraProvider) {
    if (!cameraProvider.hasCameras) return Icons.info;
    final onlineCameras = cameraProvider.cameras.where((c) => c.status.toString() == 'CameraStatus.online').length;
    final totalCameras = cameraProvider.cameras.length;
    if (onlineCameras == totalCameras) return Icons.check_circle;
    if (onlineCameras > 0) return Icons.warning;
    return Icons.error;
  }

  String _getSystemStatusText(CameraProvider cameraProvider) {
    if (!cameraProvider.hasCameras) {
      return 'No cameras configured - Add your first camera to get started';
    }
    final onlineCameras = cameraProvider.cameras.where((c) => c.status.toString() == 'CameraStatus.online').length;
    final totalCameras = cameraProvider.cameras.length;
    if (onlineCameras == totalCameras) {
      return 'All cameras online and operational';
    } else if (onlineCameras > 0) {
      return '$onlineCameras of $totalCameras cameras online';
    } else {
      return 'All cameras offline - Check network connections';
    }
  }
}
