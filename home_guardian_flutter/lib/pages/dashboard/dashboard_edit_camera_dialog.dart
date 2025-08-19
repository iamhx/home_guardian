import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../models/camera.dart';
import '../../services/camera_service.dart';

class EditCameraDialog extends StatefulWidget {
  final Camera camera;
  
  const EditCameraDialog({
    super.key,
    required this.camera,
  });

  @override
  State<EditCameraDialog> createState() => _EditCameraDialogState();
}

class _EditCameraDialogState extends State<EditCameraDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Pre-populate fields with current camera data
    _nameController = TextEditingController(text: widget.camera.name);
    _urlController = TextEditingController(text: widget.camera.url);
    _descriptionController = TextEditingController(text: widget.camera.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, cameraProvider, child) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF3B82F6)),
              SizedBox(width: 12),
              Text('Edit Camera'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Camera Name Field
                    TextFormField(
                      controller: _nameController,
                      enabled: !cameraProvider.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Camera Name',
                        hintText: 'e.g., Living Room Camera',
                        prefixIcon: Icon(Icons.videocam),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a camera name';
                        }
                        if (value.trim().length < 2) {
                          return 'Camera name must be at least 2 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    
                    // Server URL Field
                    TextFormField(
                      controller: _urlController,
                      enabled: !cameraProvider.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'camera.tailnet.ts.net:8000',
                        prefixIcon: Icon(Icons.link),
                        border: OutlineInputBorder(),
                        helperText: 'Tailscale MagicDNS address with port 8000',
                        helperMaxLines: 2,
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a server URL';
                        }
                        if (!CameraService.isValidUrl(value.trim())) {
                          return 'Please enter a valid URL (e.g., camera1.tailnet.ts.net:8000)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description Field (Optional)
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !cameraProvider.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Additional details about this camera',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Color(0xFF3B82F6), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Changes will be tested for connectivity before saving.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: cameraProvider.isLoading ? null : () {
                cameraProvider.clearError();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: cameraProvider.isLoading ? null : () => _updateCamera(cameraProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: cameraProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update Camera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateCamera(CameraProvider cameraProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    cameraProvider.clearError();

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final description = _descriptionController.text.trim().isEmpty 
        ? null 
        : _descriptionController.text.trim();

    // Check if anything actually changed
    if (name == widget.camera.name &&
        url == widget.camera.url &&
        description == widget.camera.description) {
      // No changes made
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes were made.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final success = await cameraProvider.updateCamera(
        cameraId: widget.camera.id,
        name: name != widget.camera.name ? name : null,
        url: url != widget.camera.url ? url : null,
        description: description != widget.camera.description ? description : null,
      );

      if (mounted) {
        if (success) {
          // Close dialog and show success message
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error dialog without closing the edit dialog
          _showErrorDialog(cameraProvider.errorMessage ?? 'Failed to update camera');
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error dialog for exceptions
        _showErrorDialog('Error updating camera: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Update Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
