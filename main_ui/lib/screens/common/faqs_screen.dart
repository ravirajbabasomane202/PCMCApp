import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {"q": "How to submit a grievance?", "a": "Go to 'Submit Grievance' from the home screen and fill in details."},
      {"q": "How can I track my complaint?", "a": "Navigate to 'Track Grievance' and enter your grievance ID."},
      {"q": "Can I upload documents?", "a": "Yes, you can upload photos or PDFs as proof while submitting grievances."},
      {"q": "How long does it take to resolve?", "a": "It usually takes 7 working days, depending on priority."},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("FAQs")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(faqs[index]['q']!, style: const TextStyle(fontWeight: FontWeight.w600)),
            children: [Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(faqs[index]['a']!),
            )],
          );
        },
      ),
    );
  }
}
