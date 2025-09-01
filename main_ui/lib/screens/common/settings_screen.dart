import 'package:flutter/material.dart';
import 'package:main_ui/l10n/app_localizations.dart'; // adjust based on your project structure

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.darkMode),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (val) {
              // Toggle theme
            },
          ),
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: Localizations.localeOf(context).languageCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
              ],
              onChanged: (value) {
                // Update locale (requires app restart or dynamic rebuild)
              },
            ),
          ),
        ],
      ),
    );
  }
}