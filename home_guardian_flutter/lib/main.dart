import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_guardian/pages/dashboard/dashboard_page.dart';
import 'package:home_guardian/pages/landing/landing_page.dart';
import 'package:home_guardian/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/camera.dart';
import 'providers/auth_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/action_history_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(CameraAdapter());
  Hive.registerAdapter(CameraStatusAdapter());

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase messaging
  await FirebaseMessagingService.init();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ActionHistoryProvider()),
      ],
      child: MaterialApp(
        title: 'Home Guardian',
        navigatorKey: NavigationService.navigatorKey, // Use navigation service
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Only check auth state on app start - for session persistence
            if (authProvider.isInitializing) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user has an active session, go to dashboard
            if (authProvider.isLoggedIn) {
              return const DashboardPage();
            }

            // Otherwise show landing page
            return const LandingPage();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
