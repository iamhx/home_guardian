import 'package:flutter/material.dart';
import '../../services/camera_service.dart';
import '../../utils/shared_widgets.dart';

/// Reusable form fields for camera add/edit dialogs.
/// Encapsulates the name, URL, and description fields with shared validation.
class CameraFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController descriptionController;
  final bool enabled;

  const CameraFormFields({
    super.key,
    required this.nameController,
    required this.urlController,
    required this.descriptionController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Camera Name',
            hintText: 'e.g., Living Room Camera',
            prefixIcon: Icon(Icons.videocam),
            border: OutlineInputBorder(),
          ),
          validator: validateCameraName,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: urlController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'camera.tailnet.ts.net:8000',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
            helperText: 'Tailscale MagicDNS address with port 8000',
            helperMaxLines: 2,
          ),
          validator: validateCameraUrl,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Additional details about this camera',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  static String? validateCameraName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a camera name';
    }
    if (value.trim().length < 2) {
      return 'Camera name must be at least 2 characters';
    }
    return null;
  }

  static String? validateCameraUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a server URL';
    }
    if (!CameraService.isValidUrl(value.trim())) {
      return 'Please enter a valid URL (e.g., camera1.tailnet.ts.net:8000)';
    }
    return null;
  }
}

/// Builds the info card shown at the bottom of camera dialogs.
class CameraDialogInfoCard extends StatelessWidget {
  final String message;

  const CameraDialogInfoCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: kPrimaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: kPrimaryBlue,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
