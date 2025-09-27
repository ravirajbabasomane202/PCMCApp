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
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/settings/');
      setState(() {
        _notificationsEnabled = response.data['notifications_enabled'] ?? true;
        final user = ref.read(userNotifierProvider);
        _nameController.text = user?.name ?? '';
        _emailController.text = user?.email ?? '';
      });
        } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.post('/settings/', {
        'notifications_enabled': _notificationsEnabled,
        'name': _nameController.text,
        'email': _emailController.text,
        'password': _passwordController.text.isNotEmpty ? _passwordController.text : null,
      });
      await ref.read(userNotifierProvider.notifier).updateUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        title: Text(localizations.settings),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
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
                    _buildSectionTitle(localizations.account),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: localizations.name,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: validateRequired,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: localizations.email,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              validator: validateEmail,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: '${localizations.password} (optional)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              obscureText: true,
                              validator: (value) => value!.isNotEmpty ? validateRequired(value) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Notifications
                    _buildSectionTitle(localizations.notifications),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(localizations.enableNotifications ,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        value: _notificationsEnabled,
                        onChanged: (value) => setState(() => _notificationsEnabled = value),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Language
                    _buildSectionTitle(localizations.language),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: DropdownButtonFormField<Locale>(
                          initialValue: locale,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: const [
                            DropdownMenuItem(value: Locale('en'), child: Text('English')),
                            DropdownMenuItem(value: Locale('mr'), child: Text('Marathi')),
                            DropdownMenuItem(value: Locale('hi'), child: Text('Hindi')),
                          ],
                          onChanged: (value) => ref.read(localeNotifierProvider.notifier).setLocale(value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Privacy & Security
                    _buildSectionTitle(localizations.privacySecurity ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(localizations.viewPrivacyPolicy),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Help & Support
                    _buildSectionTitle(localizations.helpSupport ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(localizations.faqs ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(context, '/faqs'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(localizations.contactSupport ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.pushNamed(context, '/contact-support'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About
                    _buildSectionTitle(localizations.about ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: const Color(0xFFECF2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(localizations.appVersion ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushNamed(context, '/app-version'),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save & Logout
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: localizations.save ,
                        onPressed: _saveSettings,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: localizations.logout ,
                        backgroundColor: Colors.red,
                        onPressed: () async {
                          await AuthService.logout();
                          ref.read(userNotifierProvider.notifier).setUser(null);
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.blue,
      ),
    );
  }
}