import 'package:flutter/material.dart';
import 'package:home_guardian/models/camera.dart';
import 'package:home_guardian/pages/camera_view/camera_view_page.dart';
import 'package:home_guardian/providers/camera_view_provider.dart';
import 'package:provider/provider.dart';

class CameraViewPageWrapper extends StatelessWidget {
  final Camera camera;
  const CameraViewPageWrapper({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CameraViewProvider(),
      child: CameraViewPage(camera: camera),
    );
  }
}
