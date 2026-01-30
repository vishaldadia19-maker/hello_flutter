import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:hello_flutter/utils/user_session.dart';

import 'login_screen.dart';
import 'leads_page.dart';

/// 🔔 BACKGROUND MESSAGE HANDLER (MUST BE TOP-LEVEL)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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


Map<String, dynamic>? _pendingNotificationData;


/// 🌍 Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }


  await UserSession.restore();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }
  
  runApp(const MyApp());
}

/// ✅ MyApp MUST be Stateful
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  void initState() {
    super.initState();

    // 🔔 BACKGROUND notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationNavigation(message.data);
    });

    // 🔔 TERMINATED notification tap (store only)
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null &&
          message.data['type'] == 'follow_up' &&
          message.data['lead_id'] != null) {

        final int leadId = int.parse(message.data['lead_id']);
        await UserSession.setPendingLead(leadId);
      }
    });
    

    // 🚀 Navigate ONLY after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingNotificationData != null) {
        handleNotificationNavigation(_pendingNotificationData!);
        _pendingNotificationData = null;
      }
    });
    
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

/// 🚀 Central Navigation Handler
void handleNotificationNavigation(Map<String, dynamic> data) {
  if (data['type'] != 'follow_up' || data['lead_id'] == null) return;

  final int leadId = int.parse(data['lead_id']);

  // 🔴 USER NOT LOGGED IN → SAVE & GO TO LOGIN
  if (UserSession.bdmId == null) {
    UserSession.pendingLeadId = leadId;
    return;
  }

  // ✅ USER LOGGED IN → OPEN LEAD
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

