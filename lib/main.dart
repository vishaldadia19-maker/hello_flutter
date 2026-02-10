import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // iOS & Android → use native config files
    await Firebase.initializeApp();
  }

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          'FIREBASE CORE OK',
          style: TextStyle(fontSize: 24),
        ),
      ),
    ),
  ));
}
