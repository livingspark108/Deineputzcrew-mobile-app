import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'login.dart';

class SecurityCodeScreen extends StatefulWidget {
  final String pendingToken;
  final String email;
  final String password;

  const SecurityCodeScreen({
    super.key,
    required this.pendingToken,
    required this.email,
    required this.password,
  });

  @override
  State<SecurityCodeScreen> createState() => _SecurityCodeScreenState();
}

class _SecurityCodeScreenState extends State<SecurityCodeScreen> {
  final TextEditingController codeController = TextEditingController();
  bool isLoading = false;
  String? _codeError;

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> verifyCode() async {
    final String code = codeController.text.trim();

    setState(() => _codeError = null);

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => _codeError = "Enter the 6-digit security code");
      return;
    }

    setState(() => isLoading = true);

    try {
      final Uri url =
          Uri.parse("https://admin.deineputzcrew.de/api/v2/login/verify/");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "pending_token": widget.pendingToken,
              "security_code": code,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && (data['success'] == true)) {
        final token = data['token'];
        final userid = data['data']['id'];
        final username =
            "${data['data']['first_name']} ${data['data']['last_name']}";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('userid', userid);
        await prefs.setString('username', username);
        await prefs.setString('saved_email', widget.email);
        await prefs.setString('saved_password', widget.password);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Login successful")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainApp()),
        );
      } else {
        final String backendMessage = (data['message'] ?? "").toString();

        if (backendMessage.toLowerCase().contains("session") ||
            backendMessage.toLowerCase().contains("expired") ||
            backendMessage.toLowerCase().contains("invalid pending")) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(backendMessage.isNotEmpty
                  ? backendMessage
                  : "Login session expired or invalid. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        } else {
          setState(() {
            _codeError = backendMessage.isNotEmpty
                ? backendMessage
                : "Invalid security code.";
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Enter Security Code',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ask your admin for the 6-digit security code shown on their dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  errorText: _codeError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 22),
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
                  onPressed: isLoading ? null : verifyCode,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: const Text(
                  'Back to login',
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
