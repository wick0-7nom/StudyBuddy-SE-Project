import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/notifications_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Initialize local + Firebase notifications
  await NotificationService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const StudyBuddyApp(),
    ),
  );
}

class StudyBuddyApp extends StatefulWidget {
  const StudyBuddyApp({super.key});

  @override
  State<StudyBuddyApp> createState() => _StudyBuddyAppState();
}

class _StudyBuddyAppState extends State<StudyBuddyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // অ্যাপ ব্যাকগ্রাউন্ডে যাওয়া ও আসার ট্র্যাকিং শুরু
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final appState = Provider.of<AppState>(context, listen: false);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // ইউজার অ্যাপ থেকে বের হয়ে গেলে বা মিনিমাইজ করলে:
      appState.setOnlineStatus(false);
      appState.updateFocusStatus('paused'); // টাইমার পজ করে দেওয়া হলো
    } else if (state == AppLifecycleState.resumed) {
      // ইউজার আবার অ্যাপে ফিরলে:
      appState.setOnlineStatus(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Buddy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routes: {
        '/notifications': (_) => const NotificationsScreen(),
      },
      home: Consumer<AppState>(
        builder: (_, app, __) {
          if (app.isLoggedIn) {
            return const HomeScreen();
          }

          if (app.awaitingVerification) {
            return const VerifyEmailScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}