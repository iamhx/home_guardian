import 'package:flutter/material.dart';
import '../../models/camera.dart';
import '../../services/camera_service.dart';

class CameraCard extends StatelessWidget {
  final Camera camera;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CameraCard({
    super.key,
    required this.camera,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status indicator
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: camera.name,
                      child: Text(
                        camera.name,
                        style: TextStyle(
                          fontSize: _getAdaptiveFontSize(camera.name),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                        maxLines: _getMaxLines(camera.name),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildStatusIndicator(),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Camera icon/thumbnail area
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: camera.status == CameraStatus.online
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      camera.status == CameraStatus.online
                          ? Icons.videocam
                          : camera.status == CameraStatus.checking
                              ? Icons.refresh
                              : Icons.videocam_off,
                      color: camera.status == CameraStatus.online
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[600],
                      size: 32,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // URL and status
              Tooltip(
                message: camera.url,
                child: Text(
                  CameraService.getDisplayName(camera.url),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Last checked time
              Text(
                'Last checked: ${_formatLastChecked(camera.lastChecked)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Smart text sizing based on name length
  double _getAdaptiveFontSize(String name) {
    if (name.length <= 12) return 16.0;      // Short names: full size
    if (name.length <= 20) return 14.0;      // Medium names: smaller
    return 12.0;                             // Long names: smallest
  }

  int _getMaxLines(String name) {
    if (name.length <= 15) return 1;         // Short names: single line
    return 2;                                // Longer names: two lines
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: camera.status.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            camera.status.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastChecked(DateTime lastChecked) {
    final now = DateTime.now();
    final difference = now.difference(lastChecked);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class AddCameraCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddCameraCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF3B82F6),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add Camera',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect a new Home Guardian server',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
