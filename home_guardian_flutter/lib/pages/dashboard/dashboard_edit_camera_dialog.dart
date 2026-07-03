import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../models/camera.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/shared_widgets.dart';
import 'camera_form_fields.dart';

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
              Icon(Icons.edit, color: kPrimaryBlue),
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
                    CameraFormFields(
                      nameController: _nameController,
                      urlController: _urlController,
                      descriptionController: _descriptionController,
                      enabled: !cameraProvider.isLoading,
                    ),
                    const SizedBox(height: 16),
                    const CameraDialogInfoCard(
                      message: 'Changes will be tested for connectivity before saving.',
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
                backgroundColor: kPrimaryBlue,
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
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          DialogUtils.showErrorDialog(
            context,
            'Update Error',
            cameraProvider.errorMessage ?? 'Failed to update camera',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogUtils.showErrorDialog(
          context,
          'Update Error',
          'Error updating camera: $e',
        );
      }
    }
  }
}
