import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/startup_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/onboarding_screen.dart';
import 'navigation/main_navigation.dart';
import 'app_theme.dart';
import 'services/standup_service.dart';

// Handle background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Daily Standup push notifications
  try {
    final standupService = StandupService();
    await standupService.init();
    await standupService.scheduleDailyStandup();
  } catch (e) {
    debugPrint("Failed to initialize StandupService: $e");
  }

  runApp(
    const ProviderScope(
      child: SocioApp(),
    ),
  );
}

class SocioApp extends ConsumerWidget {
  const SocioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Socio',
      debugShowCheckedModeBanner: false,
      theme: SocioTheme.theme,
      home: authState.when(
        data: (user) {
          if (user == null) return const SignInScreen(); // Login Screen!
          
          // Watch startup configuration status
          final startupState = ref.watch(startupNotifierProvider);
          return startupState.when(
            data: (startup) {
              if (startup.name.isEmpty || startup.idea.isEmpty) {
                return const OnboardingScreen(); // Startup setup screen!
              }
              return const MainNavigation(); // Main dashboard!
            },
            loading: () => const _SplashScreen(),
            error: (_, __) => const OnboardingScreen(),
          );
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const SignInScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F4EB), // Warm Cream
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFF0B3A22), // Forest Green
              child: Text(
                'S',
                style: TextStyle(
                  color: Color(0xFFF7F4EB), // Warm Cream
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Socio',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15291C), // Deep charcoal/green
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your AI Co-Founder',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5E7063), // Sage muted
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              color: Color(0xFF0B3A22), // Forest Green
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

