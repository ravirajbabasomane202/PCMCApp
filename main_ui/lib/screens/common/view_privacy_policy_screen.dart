import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Our Commitment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "We value your privacy and are committed to protecting your personal data. "
              "This policy explains how we handle your information securely.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text("1. Data Collection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text("We collect your name, email, and grievance details only to process complaints."),
            SizedBox(height: 20),
            Text("2. Data Usage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text("Your data is used solely for grievance redressal and system improvement."),
            SizedBox(height: 20),
            Text("3. Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text("We implement encryption and strict access policies to safeguard your information."),
          ],
        ),
      ),
    );
  }
}
