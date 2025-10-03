// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _name = '';
  String _email = '';
  String _password = '';
  String _address = '';  // New: for address
  String _phone = '';    // New: for mobile number
  String _voterId = '';  // New: for voter ID

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      
      try {
        if (_isLogin) {
          await ref.read(authProvider.notifier).loginWithEmail(_email, _password);
        } else {
          await ref.read(authProvider.notifier).register(
            _name, 
            _email, 
            _password,
            address: _address,    // Pass new fields
            phoneNumber: _phone,
            voterId: _voterId,
          );
        }
        
        final user = ref.read(authProvider);
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/${user.role}/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.authenticationFailed)),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_isLogin ? AppLocalizations.of(context)!.loginFailed : AppLocalizations.of(context)!.registrationFailed),
              content: Text("username and password is incorrect"),
              actions: <Widget>[TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.ok))],
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String? validatePhone(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.phoneNumberRequired;
    }
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
      return l10n.invalidMobileNumber;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  _isLogin ? l10n.login : l10n.register,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 32, // adjust as needed
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0076FD),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                _isLogin 
                  ? l10n.welcomeBack
                  : l10n.createAccountPrompt,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin)
                      Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: l10n.name,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: validateRequired,
                            onSaved: (value) => _name = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(  // New: Address field
                            decoration: InputDecoration(
                              labelText: l10n.address,
                              prefixIcon: Icon(Icons.home_outlined),
                            ),
                            validator: validateRequired,
                            onSaved: (value) => _address = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(  // New: Mobile Number field
                            decoration: InputDecoration(
                              labelText: l10n.phoneNumber,
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) => validatePhone(value, l10n),
                            onSaved: (value) => _phone = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(  // New: Voter ID field
                            decoration: InputDecoration(
                              labelText: l10n.voterId,
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: validateRequired,
                            onSaved: (value) => _voterId = value!,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: validateEmail,
                      onSaved: (value) => _email = value!,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: validateRequired,
                      onSaved: (value) => _password = value!,
                    ),
                    const SizedBox(height: 24),
                    
                    CustomButton(
                      text: _isLogin ? l10n.login : l10n.register,
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      fullWidth: true,
                      backgroundColor: const Color(0xFF151a2f),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? l10n.registerPrompt : l10n.loginPrompt,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0076FD),
                          ),
                          child: Text(_isLogin ? l10n.register : l10n.login),
                        ),
                      ],
                    ),
                    
                    // Commented out the OR divider line
                    /*
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: Divider(color: theme.dividerTheme.color)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ),
                        Expanded(child: Divider(color: theme.dividerTheme.color)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    */
                    
                    // Commented out the Google login button
                    /*
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Image.asset('assets/images/google_logo.png', height: 24, width: 24),
                        label: Text(l10n.googleLogin),
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);
                          try {
                            await ref.read(authProvider.notifier).loginWithGoogle();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${l10n.googleLoginFailed}: $e')),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.dividerTheme.color!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    )
                    */
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}