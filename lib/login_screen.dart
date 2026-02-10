import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/dashboard_screen.dart';
import 'utils/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leads_page.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool rememberMe = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }


Future<void> ensureFirebaseReady() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}



Future<void> _saveFcmToken(int bdmId) async {
  try {
    // 🚫 iOS / Android only, skip Web
    if (kIsWeb) return;

    // ✅ Ensure Firebase is ready
    await ensureFirebaseReady();

    debugPrint('🚀 ENTERED _saveFcmToken');

    final messaging = FirebaseMessaging.instance;

    String? token = await messaging.getToken();

    if (token == null) {
      debugPrint('❌ FCM token is null');
      return;
    }

    debugPrint('✅ Saving FCM token');

    await http.post(
      Uri.parse(
        'https://backoffice.thecubeclub.co/apis/save_fcm_token.php',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'bdm_id': bdmId,
        'fcm_token': token,
        'platform': 'ios', // ✅ FIX (was android)
      }),
    );
  } catch (e) {
    debugPrint('❌ Error saving FCM token: $e');
  }
}
  


  // ================= LOAD SAVED CREDENTIALS =================

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');
    final savedRemember = prefs.getBool('remember_me') ?? false;

    if (savedRemember &&
        savedUsername != null &&
        savedPassword != null) {
      setState(() {
        usernameController.text = savedUsername;
        passwordController.text = savedPassword;
        rememberMe = true;
      });
    }
  }

  // ================= SAVE / CLEAR CREDENTIALS =================

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setString(
          'username', usernameController.text.trim());
      await prefs.setString(
          'password', passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    }
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final url =
        Uri.parse('https://backoffice.thecubeclub.co/apis/login.php');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'pwd': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {


        final int bdmId =
            int.parse(data['user']['bdm_id'].toString());

        final String userName =
            data['user']['name']?.toString() ?? '';

        final String enteredUsername = usernameController.text.trim();

        final bool isVoiceUser =
            enteredUsername.toLowerCase().endsWith('voice');


        await UserSession.save(
          bdmId: bdmId,
          userName: userName,
          isVoiceUser: isVoiceUser, // 👈 NEW
        );


        await _saveCredentials();

        // ✅ SAVE FCM TOKEN HERE (non-blocking)
        //_saveFcmToken(bdmId);
        
        //await _saveFcmToken(bdmId);
        _saveFcmToken(bdmId);

        // 🔥 IF APP WAS OPENED FROM NOTIFICATION (COLD SAFE)
        final int? pendingLeadId = await UserSession.consumePendingLead();

        if (pendingLeadId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LeadsPage(
                bdmId: bdmId,
                leadId: pendingLeadId,
                reportType: 'search_lead',
              ),
            ),
          );
          return;
        }
        


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(bdmId: bdmId),
          ),
        );
      }else {
        _showMessage(data['message']);
      }
    } catch (e) {
      _showMessage('Network error. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

  debugPrint("🔥 LoginScreen build() called");
  
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// LOGO
                  Image.asset(
                    'assets/logo.png',
                    height: 200,
                  ),

                  const SizedBox(height: 16),

                  /// TITLE
                  const Text(
                    'CRM Login',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// USERNAME
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter username';
                      }
                      if (value.length < 3) {
                        return 'Minimum 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 4) {
                        return 'Minimum 4 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  /// REMEMBER ME
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (v) {
                          setState(() {
                            rememberMe = v ?? false;
                          });
                        },
                      ),
                      const Text('Save credentials'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                  ),
                  


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
