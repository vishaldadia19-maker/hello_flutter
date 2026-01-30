import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Android / iOS will use native config
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDa-MUTEv_NKrP6pYkPsDLjryLG5w8Bik",
    authDomain: "cubecrm.firebaseapp.com",
    projectId: "cubecrm",
    storageBucket: "cubecrm.firebasestorage.app",
    messagingSenderId: "29305465417",
    appId: "1:29305465417:web:c16383fb7fbaad7c3cad98",
    measurementId: "G-NBGD1MNSM7", // optional
  );
}
