import 'dart:convert';
import 'package:deineputzcrew/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final url = Uri.parse('https://admin.deineputzcrew.de/api/reset-password/');
    final body = jsonEncode({
      "email": _emailController.text.trim(),
      "otp": _otpController.text.trim(),
      "new_password": _passwordController.text.trim(),
      "confirm_password": _confirmPasswordController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      setState(() => _isSubmitting = false);

      final resBody = jsonDecode(response.body);
      String message = resBody['message'] ?? l10n.apiResultFallback;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (resBody['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exceptionSnackbar(e.toString()))),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          l10n.appbarTitleButtonLabel,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.emailFieldHint,
                  hintText: l10n.emailFieldHint2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.emailEmptyInlineError;
                  final emailRegex =
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(value)) return l10n.invalidEmailInlineError;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.otpFieldLabel,
                  hintText: l10n.otpFieldHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_clock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.otpRequiredValidation;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.newPasswordFieldLabel,
                  hintText: l10n.newPasswordFieldHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.passwordEmptyInlineError;
                  }
                  if (value.length < 8) {
                    return l10n.passwordLengthValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordFieldLabel,
                  hintText: l10n.confirmPasswordFieldHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.confirmPasswordRequiredValidation;
                  }
                  if (value != _passwordController.text) {
                    return l10n.passwordsMismatchValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000000),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    l10n.appbarTitleButtonLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
