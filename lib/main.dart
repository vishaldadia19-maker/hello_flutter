import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'leads_page.dart';
import 'utils/user_session.dart';

/// 🌍 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

/// 🔔 BACKGROUND MESSAGE HANDLER (MUST BE TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  }
}

/// 🚀 MAIN ENTRY
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Correct Firebase initialization
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  // Restore saved user session
  await UserSession.restore();

  // Register background handler (mobile only)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  runApp(const MyApp());
}

/// ✅ Root App
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _configureFirebaseMessaging();
    }
  }

  /// 🔔 Configure Messaging (Foreground + Background + Terminated)
  Future<void> _configureFirebaseMessaging() async {
    // Request permission (important for iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔔 App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        handleNotificationNavigation(message.data);
      },
    );

    // 🔔 App opened from terminated state
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      handleNotificationNavigation(initialMessage.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Cube Club',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

/// 🚀 Central Notification Navigation
void handleNotificationNavigation(Map<String, dynamic> data) {
  if (data['type'] != 'follow_up' || data['lead_id'] == null) return;

  final int leadId = int.tryParse(data['lead_id'].toString()) ?? 0;
  if (leadId == 0) return;

  // 🔴 USER NOT LOGGED IN → STORE & WAIT
  if (UserSession.bdmId == null) {
    UserSession.pendingLeadId = leadId;
    return;
  }

  // ✅ USER LOGGED IN → NAVIGATE
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => LeadsPage(
        bdmId: UserSession.bdmId!,
        leadId: leadId,
        reportType: 'search_lead',
      ),
    ),
  );
}
  