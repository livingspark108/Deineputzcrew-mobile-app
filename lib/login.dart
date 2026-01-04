import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'privacypolicy.dart';
import 'terms.dart';
import 'forgetpasswordscreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown-ios";
      } else {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id ?? "unknown";
      }
    } catch (e) {
      return "unknown-device";
    }
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return "${iosInfo.name} ${iosInfo.model}";
      } else {
        final androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.manufacturer} ${androidInfo.model}";
      }
    } catch (e) {
      return "unknown-device";
    }
  }

  Future<void> loginUser() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔑 Device info
      final deviceId = await getDeviceId();
      final prefs = await SharedPreferences.getInstance();

      /// 🔔 FCM token (already created in main.dart)
      final String? fcmToken = prefs.getString('fcm_token');

      final Uri url = Uri.parse("https://admin.deineputzcrew.de/api/login/");

      // Prepare request body - only include token fields if they exist
      Map<String, dynamic> requestBody = {
        "username": email,
        "password": password,
        "device_id": deviceId,
        "device_type": Theme.of(context).platform == TargetPlatform.iOS ? "ios" : "android",
        "device_name": await getDeviceName(),
        "platform": "flutter",
      };

      // Only add FCM tokens if they exist and are not empty
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody["fcm_token"] = fcmToken;
        requestBody["device_token"] = fcmToken;
      }

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      /// 🚨 Debug: Print API response
      debugPrint("Login API Response:");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("Parsed Data: $data");

      if (response.statusCode == 200 && (data['success'] == true || data['success'] == "true" || data['status'] == "success")) {
        final token = data['token'];
        final userid = data['data']['id'];
        final username =
            "${data['data']['first_name']} ${data['data']['last_name']}";

        /// 💾 Save locally
        await prefs.setString('token', token);
        await prefs.setInt('userid', userid);
        await prefs.setString('username', username);
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainApp()),
        );
      } else {
        /// 🚨 Debug: Show why login failed
        debugPrint("Login failed - Status: ${response.statusCode}, Success: ${data['success']}, Message: ${data['message']}");
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login failed - Status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      /// 🚨 Debug: Show actual error in debug mode
      debugPrint("Login error: $e");
      
      /// 🌐 OFFLINE LOGIN FALLBACK
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');

      if (savedEmail == email && savedPassword == password) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainApp()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offline login successful")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Login failed: ${e.toString()}")),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('Log in',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Please enter login credentials to continue.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Enter Email',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.deepPurpleAccent, width: 1.2),
                  ),
                ),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter Password',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: Colors.deepPurpleAccent, width: 1.2),
                  ),
                ),
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : loginUser,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Log in', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(
                    text: 'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen()),
                        );
                      },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 👇 Terms and Privacy Section
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'By logging in, you agree to our ',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // TODO: Navigate to Terms & Conditions page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => TermsConditionsScreen()),
                            );
                          },
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // TODO: Navigate to Privacy Policy page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                            );
                          },
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
