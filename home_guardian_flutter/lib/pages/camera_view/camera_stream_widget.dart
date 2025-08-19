import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_view_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraStreamWidget extends StatefulWidget {
  const CameraStreamWidget({super.key});

  @override
  State<CameraStreamWidget> createState() => _CameraStreamWidgetState();
}

class _CameraStreamWidgetState extends State<CameraStreamWidget> {
  WebViewController? _webViewController;

  @override
  void dispose() {
    // Attempt to stop all media in the WebView before disposing
    _webViewController?.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CameraViewProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 250,
              child: Selector<CameraViewProvider, bool>(
                selector: (_, p) => p.isStreamReady,
                builder: (context, isStreamReady, child) {
                  return (isStreamReady)
                      ? _buildWebRTCStream(provider)
                      : _buildStreamPlaceholder();
                },
              ),
            ),
            Positioned(
              top: 5,
              left: 5,
              child: Consumer<CameraViewProvider>(
                builder: (context, provider, child) {
                  return _buildStreamOverlay(provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebRTCStream(CameraViewProvider provider) {
    final webRTCUrl = provider.getWebRTCStreamUrl();
    if (webRTCUrl != null) {
      _webViewController ??= WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      _webViewController!.loadRequest(Uri.parse(webRTCUrl));
      provider.webRTCStreamBuilt = true;
      return WebViewWidget(controller: _webViewController!);
    }
    return _buildStreamPlaceholder();
  }

  Widget _buildStreamPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Camera Stream',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamOverlay(CameraViewProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.isStreamReady ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.face,
            color: provider.facesDetected > 0 ? Colors.orange : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${provider.facesDetected}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
