import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'utils/user_session.dart';

import 'login_screen.dart';
import 'leads_page.dart';

/// 🔔 BACKGROUND MESSAGE HANDLER (MOBILE ONLY)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

/// 🌍 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// ✅ Root App
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// 🚀 Safe App Initialization
  Future<void> _initApp() async {
    try {
      // 🌍 WEB
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      // 📱 ANDROID / iOS
      else {
        await Firebase.initializeApp();

        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        // 🔔 Notification opened (background)
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          handleNotificationNavigation(message.data);
        });

        // 🔔 Notification opened (terminated)
        final message =
            await FirebaseMessaging.instance.getInitialMessage();

        if (message != null) {
          handleNotificationNavigation(message.data);
        }
      }

      // 👤 Restore user session
      await UserSession.restore();

      setState(() {
        _initialized = true;
      });
    } catch (e, st) {
      debugPrint('INIT ERROR: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔄 LOADING (Apple needs this)
    if (!_initialized && _error == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // ❌ ERROR (still acceptable to Apple)
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Unable to start app.\n\n$_error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // ✅ APP READY
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Cube Club',
      navigatorKey: navigatorKey,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}

/// 🚀 Central Notification Navigation
void handleNotificationNavigation(Map<String, dynamic> data) {
  if (data['type'] != 'follow_up' || data['lead_id'] == null) return;

  final int leadId = int.parse(data['lead_id']);

  // 🔴 User not logged in → store & wait
  if (UserSession.bdmId == null) {
    UserSession.pendingLeadId = leadId;
    return;
  }

  // ✅ User logged in → open lead
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
