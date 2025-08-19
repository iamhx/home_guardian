import 'package:flutter/material.dart';
import 'package:home_guardian/pages/dashboard/dashboard_add_camera_dialog.dart';
import 'package:home_guardian/providers/auth_provider.dart';
import 'package:home_guardian/providers/camera_provider.dart';
import 'package:home_guardian/providers/dashboard_provider.dart';
import 'package:home_guardian/utils/double_back_to_exit.dart';
import 'package:provider/provider.dart';
import 'action_history_page.dart';
import 'settings_page.dart';
import 'dashboard_welcome_section.dart';
import 'dashboard_cameras_section.dart';

void showAddCameraDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const AddCameraDialog());
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardProvider>().subscribeToWakeWordTopic();
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExitWrapper(
      child: Consumer2<AuthProvider, CameraProvider>(
        builder: (context, authProvider, cameraProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home Guardian'),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              actions: [
                // History button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActionHistoryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: 'Action History',
                ),
                // Settings button
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Settings',
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showAddCameraDialog(context),
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                    Color(0xFF6366F1),
                  ],
                ),
              ),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => cameraProvider.forceStatusRefresh(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardWelcomeSection(
                          authProvider: authProvider,
                          cameraProvider: cameraProvider,
                        ),
                        const SizedBox(height: 24),
                        DashboardCamerasSection(
                          cameraProvider: cameraProvider,
                          onAddCamera: () => showAddCameraDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
