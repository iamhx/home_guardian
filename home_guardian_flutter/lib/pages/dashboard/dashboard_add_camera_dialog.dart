import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../services/camera_service.dart';

class AddCameraDialog extends StatefulWidget {
  const AddCameraDialog({super.key});

  @override
  State<AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends State<AddCameraDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

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
              Icon(Icons.add_circle, color: Color(0xFF3B82F6)),
              SizedBox(width: 12),
              Text('Add Camera'),
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
                    const SizedBox(height: 8),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a server URL';
                        }
                        if (!CameraService.isValidUrl(value.trim())) {
                          return 'Please enter a valid URL (e.g., camera1.tailnet.ts.net:8000)';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.url,
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
                              'We\'ll test the connection to make sure the Home Guardian server is running.',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 12,
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
              onPressed: cameraProvider.isLoading ? null : () => _handleAddCamera(cameraProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: cameraProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Add Camera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAddCamera(CameraProvider cameraProvider) async {
    if (!_formKey.currentState!.validate()) return;

    cameraProvider.clearError();
    
    final success = await cameraProvider.addCamera(
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Close dialog and show success message
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera "${_nameController.text.trim()}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show error dialog without closing the add dialog
        _showErrorDialog(cameraProvider.errorMessage ?? 'Failed to add camera');
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
              Text('Connection Error'),
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

// Helper function to show the dialog
Future<void> showAddCameraDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return const AddCameraDialog();
    },
  );
}
