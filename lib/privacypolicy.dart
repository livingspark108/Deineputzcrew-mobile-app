import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'login.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine platform-specific policy content
    final bool isIOS = Platform.isIOS;
    final String policyTitle = isIOS ? "Privacy Policy - iOS" : "Privacy Policy - Android";
    final String effectiveDate = isIOS ? "06/01/2025" : "6 January 2026";
    final String storeReference = isIOS ? "Apple App Store" : "Google Play Store";
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            policyTitle,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0.8,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policyTitle,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Effective Date: $effectiveDate",
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black),
                  children: [
                    const TextSpan(
                      text: "This Privacy Policy explains how ",
                    ),
                    const TextSpan(
                      text: "LivingSpark Global Tech Pvt Ltd",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text: " (\"we\", \"our\", \"us\"), the developer and operator of ",
                    ),
                    const TextSpan(
                      text: "DeinePutzCrew",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ", collects, uses, stores, and protects personal data when you use the DeinePutzCrew ${isIOS ? 'iOS' : 'Android'} application published on the $storeReference, and related services provided via ",
                    ),
                    const TextSpan(
                      text: "https://deineputzcrew.de",
                      style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              _buildSection(
                "1. App Purpose",
                "The DeinePutzCrew ${isIOS ? 'iOS' : 'Android'} app is used exclusively for:\n\n" +
                "• Managing employee tasks at predefined work locations\n" +
                "• Verifying employee presence via location check-in\n" +
                "• Recording work time (clock-in / clock-out)\n" +
                "• Uploading selfies and work photos for task verification\n\n" +
                "The app is intended for professional use only."
              ),

              _buildSection(
                "2. Data We Collect",
                "2.1 Personal Information\n" +
                "• Full name\n• Email address\n• Phone number\n• Employee/User ID\n• Login credentials (securely encrypted)\n\n" +
                "2.2 Location Data\n" +
                "• GPS location during check-in and check-out only\n• Location is used to verify presence at assigned work locations\n• No background location tracking is performed\n\n" +
                "2.3 Photos & Media\n" +
                "• Selfie photo at check-in (attendance verification)\n• Work photos uploaded before check-out (task validation)\n• Photos are never used for marketing or advertising"
              ),

              _buildSection(
                "3. How We Use Your Data",
                "We use collected data strictly to:\n\n" +
                "• Confirm employee presence at registered job locations\n" +
                "• Track working hours and attendance\n" +
                "• Verify task completion\n" +
                "• Allow administrators to manage workforce operations\n" +
                "• Ensure system security and prevent misuse\n\n" +
                "We do NOT use data for:\n\n" +
                "• Advertising\n• Marketing\n• Analytics across other apps\n• Profiling or automated decision-making"
              ),

              _buildSection(
                "4. Data Storage & Security",
                "• All application servers and databases are hosted in Germany using DigitalOcean infrastructure\n" +
                "• No production data is stored outside Germany unless legally required\n" +
                "• All data is transmitted using secure encryption (HTTPS/SSL)\n" +
                "• Data is stored on secured servers with restricted access\n" +
                "• Only authorized administrators can access employee data"
              ),

              _buildSection(
                "5. User Rights (EU / GDPR)",
                "Users have the right to:\n\n" +
                "• Access their personal data\n" +
                "• Request correction of inaccurate data\n" +
                "• Request deletion of data (subject to legal obligations)\n" +
                "• Withdraw consent for optional permissions\n\n" +
                "Requests can be submitted to: info@deineputzcrew.de"
              ),

              _buildSection(
                "6. Contact Information",
                "LivingSpark Global Tech Pvt Ltd\n" +
                "Developer of DeinePutzCrew\n" +
                "Website: https://deineputzcrew.de\n" +
                "Email: info@deineputzcrew.de"
              ),

              const SizedBox(height: 30),
              Text(
                "Last updated: $effectiveDate",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.6),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
