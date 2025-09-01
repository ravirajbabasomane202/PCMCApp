import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/providers/locale_provider.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/loading_indicator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true; // Default; fetch from backend
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/settings'); // New backend route
      if (response != null) {
        setState(() {
          _notificationsEnabled = response.data['notifications_enabled'] ?? true;
          final user = ref.read(userNotifierProvider);
          _nameController.text = user?.name ?? '';
          _emailController.text = user?.email ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.post('/settings', {
        'notifications_enabled': _notificationsEnabled,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
      });
      await ref.read(userNotifierProvider.notifier).updateUser(); // Refresh user
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Section
                    Text(localizations.account, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: localizations.name),
                      validator: validateRequired,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: localizations.email),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: '${localizations.password} (optional)'),
                      obscureText: true,
                      validator: (value) => value!.isNotEmpty ? validateRequired(value) : null,
                    ),
                    const SizedBox(height: 24),

                    // Notifications
                    Text(localizations.notifications, style: Theme.of(context).textTheme.titleLarge),
                    SwitchListTile(
                      title: Text(localizations.enableNotifications ?? 'Enable Notifications'),
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                    ),
                    const SizedBox(height: 24),

                    // Language
                    Text(localizations.language, style: Theme.of(context).textTheme.titleLarge),
                    DropdownButton<Locale>(
                      value: locale,
                      items: const [
                        DropdownMenuItem(value: Locale('en'), child: Text('English')),
                        DropdownMenuItem(value: Locale('mr'), child: Text('Marathi')),
                        DropdownMenuItem(value: Locale('hi'), child: Text('Hindi')),
                      ],
                      onChanged: (value) => ref.read(localeNotifierProvider.notifier).setLocale(value!),
                    ),
                    const SizedBox(height: 24),

                    // Privacy & Security
                    Text(localizations.privacySecurity ?? 'Privacy & Security', style: Theme.of(context).textTheme.titleLarge),
                    ListTile(
                      title: Text(localizations.viewPrivacyPolicy ?? 'View Privacy Policy'),
                      onTap: () => Navigator.pushNamed(context, '/privacy'), // Add route if needed
                    ),
                    const SizedBox(height: 24),

                    // Help & Support
                    Text(localizations.helpSupport ?? 'Help & Support', style: Theme.of(context).textTheme.titleLarge),
                    ListTile(
                      title: Text(localizations.faqs ?? 'FAQs'),
                      onTap: () => Navigator.pushNamed(context, '/faqs'), // Add route if needed
                    ),
                    ListTile(
                      title: Text(localizations.contactSupport ?? 'Contact Support'),
                      onTap: () => Navigator.pushNamed(context, '/support'), // Add route if needed
                    ),
                    const SizedBox(height: 24),

                    // About
                    Text(localizations.about ?? 'About', style: Theme.of(context).textTheme.titleLarge),
                    ListTile(
                      title: Text(localizations.appVersion ?? 'App Version: 1.0.0'),
                    ),
                    const SizedBox(height: 24),

                    // Save & Logout
                    CustomButton(text: localizations.save ?? 'Save', onPressed: _saveSettings),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: localizations.logout ?? 'Logout',
                      backgroundColor: Colors.red,
                      onPressed: () async {
                        await AuthService.logout();
                        ref.read(userNotifierProvider.notifier).setUser(null);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}