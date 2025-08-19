import 'package:flutter/material.dart';
import 'package:home_guardian/providers/camera_view_provider.dart';
import 'package:provider/provider.dart';

class ManualControlSheet extends StatefulWidget {
  const ManualControlSheet({super.key});

  @override
  State<ManualControlSheet> createState() => _ManualControlSheetState();
}

class _ManualControlSheetState extends State<ManualControlSheet> {
  bool _isClosing = false; // Guard to prevent multiple close operations

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraViewProvider>().initializeManualControl();
    });
  }

  Future<void> _handleClose() async {
    if (_isClosing) return; // Prevent multiple simultaneous close operations

    _isClosing = true;
    try {
      final navigator = Navigator.of(context);
      await context.read<CameraViewProvider>().disposeManualControl();
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Force close even if dispose fails
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_isClosing) {
          await _handleClose();
        }
      },
      child: SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual Control',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _isClosing ? null : _handleClose,
                    icon: _isClosing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                    ),
                    tooltip: _isClosing ? 'Closing...' : 'Close Manual Control',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Icon(Icons.rotate_left, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Pan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer<CameraViewProvider>(
                    builder: (context, provider, child) => Expanded(
                      child: Slider(
                        value: provider.sliderPan,
                        min: 0.0,
                        max: 170.0,
                        divisions: 170,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                        onChanged: (provider.isLoadingCenterServos)
                            ? null
                            : (value) {
                                provider.setSliderPan(value);
                              },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Consumer<CameraViewProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.sliderPan.toInt()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.rotate_right, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tilt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Consumer<CameraViewProvider>(
                    builder: (context, provider, child) => Expanded(
                      child: Slider(
                        value: provider.sliderTilt,
                        min: 0.0,
                        max: 150.0,
                        divisions: 150,
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                        onChanged: (provider.isLoadingCenterServos)
                            ? null
                            : (value) {
                                provider.setSliderTilt(value);
                              },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Consumer<CameraViewProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.sliderTilt.toInt()}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<CameraViewProvider>(
              builder: (context, provider, child) => ElevatedButton.icon(
                onPressed: provider.isLoadingCenterServos
                    ? null
                    : () async {
                        await provider.centerServos();
                      },
                icon: const Icon(Icons.center_focus_strong, size: 16),
                label: const Text('Center'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
