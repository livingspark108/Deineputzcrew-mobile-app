import 'package:flutter/material.dart';
import 'login.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Privacy Policy",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0.8,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "Your privacy is important to us. This Privacy Policy describes how we collect, "
                    "use, and protect your personal information when you use our application.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "1. Information We Collect",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "We collect information such as your name, email address, contact details, "
                    "and device information for account verification and app functionality.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "2. How We Use Your Information",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "Your data is used to provide, maintain, and improve our services. "
                    "We do not sell or share your data with third parties without consent.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "3. Data Security",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "We use advanced encryption and secure storage methods to protect your personal information.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "4. Your Rights",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "You can request to view, edit, or delete your personal information by contacting our support team.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "5. Updates to This Policy",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "We may revise this Privacy Policy occasionally. Continued use of the app implies consent to the latest version.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                "Last updated: November 2025",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
