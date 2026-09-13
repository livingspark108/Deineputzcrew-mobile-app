import 'package:flutter/material.dart';
import 'login.dart';
import 'l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false; // prevent default back behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.termsLink,
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
                l10n.pageHeading,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.introParagraph2,
                style: const TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.sectionHeader8,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sectionBody,
                style: const TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.sectionHeader9,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sectionBody2,
                style: const TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.sectionHeader10,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sectionBody3,
                style: const TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.sectionHeader11,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.sectionBody4,
                style: const TextStyle(fontSize: 15, height: 1.6),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 30),
              Text(
                l10n.footer2,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
