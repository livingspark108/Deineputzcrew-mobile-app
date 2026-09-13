import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'login.dart';
import 'punch_timezone.dart';
import 'l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final String code = codeController.text.trim();

    setState(() => _codeError = null);

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => _codeError = l10n.invalidCodeLengthInlineError);
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

        // 🌍 Use whatever timezone the backend reports for this account for
        // punch/break timestamps — never hardcoded.
        await applyTimezoneFromApiResponse(data);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? l10n.verifySuccessFallback)),
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
                  : l10n.sessionExpiredFallback),
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
                : l10n.invalidCodeFallback;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationExceptionSnackbar(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                l10n.screenHeading,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.subheading2,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
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
                      : Text(
                          l10n.verifyButton,
                          style: const TextStyle(
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
                child: Text(
                  l10n.backLink,
                  style: const TextStyle(
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
