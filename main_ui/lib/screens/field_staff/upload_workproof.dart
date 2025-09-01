// lib/screens/employer/upload_workproof.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/file_upload_widget.dart'; // Assuming this exists for file picking

class UploadWorkproof extends ConsumerWidget {
  const UploadWorkproof({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    List<dynamic> selectedFiles = []; // Static holder for selected files

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.uploadWorkproof ?? 'Upload Work Proof'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FileUploadWidget(
              onFilesSelected: (files) {
                selectedFiles = files;
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: l10n.upload ?? 'Upload',
              onPressed: () {
                // Add API upload logic later (no real upload now)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Files selected (upload simulated)')),
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