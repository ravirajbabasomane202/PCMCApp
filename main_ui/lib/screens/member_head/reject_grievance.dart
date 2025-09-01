// lib/screens/member_head/reject_grievance.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/custom_button.dart';

class RejectGrievance extends ConsumerWidget {
  const RejectGrievance({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController reasonController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rejectGrievance ?? 'Reject Grievance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.rejectionReason ?? 'Rejection Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: l10n.reject ?? 'Reject',
              onPressed: () {
                // Add API reject logic later
                final reason = reasonController.text;
                if (reason.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rejected: $reason')),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}