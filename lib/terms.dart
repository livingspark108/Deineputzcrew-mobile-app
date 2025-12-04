import 'package:flutter/material.dart';
import 'login.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return false; // prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Terms & Conditions",
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
                "Welcome to DiveInPuits!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "These Terms and Conditions govern your use of our application and services. "
                    "By accessing or using our app, you agree to comply with these terms.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "1. Account Responsibilities",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "You are responsible for maintaining the confidentiality of your account credentials. "
                    "You agree to notify us immediately of any unauthorized use of your account.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "2. Usage of Services",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "You agree not to misuse our services, including engaging in fraudulent, abusive, "
                    "or illegal activities within the app.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "3. Limitation of Liability",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "We are not responsible for any indirect, incidental, or consequential damages arising from your use of our app.",
                style: TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 20),
              Text(
                "4. Changes to Terms",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                "We may update these Terms from time to time. Continued use of the app after updates means you accept the new Terms.",
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
