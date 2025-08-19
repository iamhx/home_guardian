import 'package:flutter/material.dart';
import 'package:home_guardian/pages/camera_view/camera_controls_widget.dart';
import 'package:provider/provider.dart';
import 'package:home_guardian/models/camera.dart';
import 'package:home_guardian/providers/camera_view_provider.dart';
import 'camera_stream_widget.dart';
import 'camera_status_row.dart';
import 'camera_error_widget.dart';

class CameraViewPage extends StatefulWidget {
  final Camera camera;
  const CameraViewPage({super.key, required this.camera});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraViewProvider>().initialize(
        widget.camera.url,
        cameraName: widget.camera.name,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CameraViewProvider>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final navigator = Navigator.of(context);
          await provider.cleanup();
          if (mounted) navigator.pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(widget.camera.name),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF6366F1)],
            ),
          ),
          child: SafeArea(
            child: Selector<CameraViewProvider, bool>(
              selector: (_, p) => p.isLoading,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return Selector<CameraViewProvider, String?>(
                  selector: (_, p) => p.error,
                  builder: (context, error, child) {
                    if (error != null) {
                      return CameraErrorWidget(
                        error: error,
                        onRetry: () => provider.initialize(
                          widget.camera.url,
                          cameraName: widget.camera.name,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        CameraStreamWidget(),
                        const SizedBox(height: 16),
                        CameraStatusRow(),
                        const SizedBox(height: 16),
                        Expanded(child: CameraControlsWidget()),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
