import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/shared_widgets.dart';
import 'camera_form_fields.dart';

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
              Icon(Icons.add_circle, color: kPrimaryBlue),
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
                    CameraFormFields(
                      nameController: _nameController,
                      urlController: _urlController,
                      descriptionController: _descriptionController,
                      enabled: !cameraProvider.isLoading,
                    ),
                    const SizedBox(height: 16),
                    const CameraDialogInfoCard(
                      message: 'We\'ll test the connection to make sure the Home Guardian server is running.',
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
                backgroundColor: kPrimaryBlue,
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera "${_nameController.text.trim()}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        DialogUtils.showErrorDialog(
          context,
          'Connection Error',
          cameraProvider.errorMessage ?? 'Failed to add camera',
        );
      }
    }
  }
}


