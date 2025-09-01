// lib/screens/employer/update_status.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/custom_button.dart';

class UpdateStatus extends ConsumerWidget {
  const UpdateStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Static dummy statuses (replace with enum/API later)
    final List<String> dummyStatuses = ['In Progress', 'On Hold', 'Resolved'];
    String? selectedStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.updateStatus),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              hint: Text(l10n.selectStatus),
              items: dummyStatuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) => selectedStatus = value,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: l10n.update,
              onPressed: () {
                // Add API update logic later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Status updated to $selectedStatus')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}