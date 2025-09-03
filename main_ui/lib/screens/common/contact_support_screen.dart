import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  void _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'support@pcmcapp.com', query: 'subject=App Support');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+91-9876543210');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Support")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Need help?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("You can reach us via email or phone for assistance."),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text("Email Us"),
              subtitle: const Text("support@pcmcapp.com"),
              onTap: _launchEmail,
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("Call Us"),
              subtitle: const Text("+91-9876543210"),
              onTap: _launchPhone,
            ),
          ],
        ),
      ),
    );
  }
}
