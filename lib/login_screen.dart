import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/dashboard_screen.dart';
import 'utils/user_session.dart';
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
  bool _isLoading = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
      await prefs.setString('username', usernameController.text.trim());
      await prefs.setString('password', passwordController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    }
  }

  // ================= SAVE FCM TOKEN =================

  Future<void> _saveFcmToken(int bdmId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse(
            'https://backoffice.thecubeclub.co/apis/save_fcm_token.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'bdm_id': bdmId,
          'fcm_token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );
    } catch (_) {
      // Silent fail – push token save should not break login
    }
  }

  // ================= LOGIN =================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://backoffice.thecubeclub.co/apis/login.php'),
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
            int.tryParse(data['user']['bdm_id'].toString()) ?? 0;

        final String userName =
            data['user']['name']?.toString() ?? '';

        final bool isVoiceUser =
            usernameController.text.trim().toLowerCase().endsWith('voice');

        await UserSession.save(
          bdmId: bdmId,
          userName: userName,
          isVoiceUser: isVoiceUser,
        );

        await _saveCredentials();

        // Save FCM token (non-blocking)
        _saveFcmToken(bdmId);

        // Handle pending notification
        final int? pendingLeadId =
            await UserSession.consumePendingLead();

        if (pendingLeadId != null) {
          if (!mounted) return;

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

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(bdmId: bdmId),
          ),
        );
      } else {
        _showMessage(data['message'] ?? 'Login failed');
      }
    } catch (_) {
      _showMessage('Network error. Please try again.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
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

                  Image.asset('assets/logo.png', height: 200),

                  const SizedBox(height: 16),

                  const Text(
                    'CRM Login',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

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

                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
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

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text('Login'),
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
