import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_view_provider.dart';

class CameraStatusRow extends StatelessWidget {
  const CameraStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Consumer<CameraViewProvider>(
        builder: (context, provider, child) => Row(
          children: [
            Expanded(
              child: _buildStatusItem(
                'Servos',
                provider.servosActive ? 'Active' : 'Inactive',
                provider.servosActive ? Colors.green : Colors.red,
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[700]),
            Expanded(
              child: _buildStatusItem(
                'Mode',
                provider.mode.toUpperCase(),
                _getModeColor(provider.mode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'patrol':
        return Colors.orange;
      case 'smart':
        return Colors.purple;
      case 'manual':
        return Colors.blue;
      case 'idle':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
