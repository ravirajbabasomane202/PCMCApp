import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Background color
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: const Color(0xFFECF2FE), // Matching card theme
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: const Color(0xFFECF2FE), // Card background
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Our Commitment",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We value your privacy and are committed to protecting your personal data. "
                  "This policy explains how we handle your information securely.",
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                ),
                SizedBox(height: 20),
                Text(
                  "1. Data Collection",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "We collect your name, email, and grievance details only to process complaints.",
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                SizedBox(height: 20),
                Text(
                  "2. Data Usage",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your data is used solely for grievance redressal and system improvement.",
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
                SizedBox(height: 20),
                Text(
                  "3. Security",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "We implement encryption and strict access policies to safeguard your information.",
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
