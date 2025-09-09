import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/utils/theme.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/file_upload_widget.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider);
    _nameController = TextEditingController(text: user?.name);
    _emailController = TextEditingController(text: user?.email);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _addressController = TextEditingController(text: user?.address);
    _twoFactorEnabled = user?.twoFactorEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userData = {
          'id': ref.read(userNotifierProvider)!.id.toString(), // Convert to string
          'name': _nameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'twoFactorEnabled': _twoFactorEnabled.toString(),
        };
        final updatedUser = await ApiService.addUpdateUser(userData);
        ref.read(userNotifierProvider.notifier).setUser(User.fromJson(updatedUser));
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.userUpdatedSuccess)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateUser)),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadProfilePicture(List<PlatformFile> files) async {
    if (files.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final file = files.first;
        final response = await ApiService.uploadProfilePicture(file);
        final user = ref.read(userNotifierProvider)!;
        ref.read(userNotifierProvider.notifier).setUser(
              User(
                id: user.id,
                name: user.name,
                email: user.email,
                phoneNumber: user.phoneNumber,
                role: user.role,
                departmentId: user.departmentId,
                address: user.address,
                profilePicture: response['file_path'],
                lastLogin: user.lastLogin,
                twoFactorEnabled: user.twoFactorEnabled,
                isActive: user.isActive,
              ),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture uploaded successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: localizations.logout,
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await AuthService.logout();
                  ref.read(userNotifierProvider.notifier).setUser(null);
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.logoutFailed)),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : user == null
              ? _buildNotLoggedInView(context, localizations, theme)
              : _buildProfileView(context, localizations, theme, user),
    );
  }

  Widget _buildNotLoggedInView(
      BuildContext context, AppLocalizations localizations, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.please_login,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200, // Constrain the button width
            child: CustomButton(
              text: localizations.login,
              icon: Icons.login,
              onPressed: () => Navigator.pushNamed(context, '/login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(
      BuildContext context, AppLocalizations localizations, ThemeData theme, User user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile header with picture
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(40), // Fixed: changed withValues to withAlpha
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                          backgroundColor: theme.colorScheme.primary,
                          child: user.profilePicture == null
                              ? Text(
                                  user.name?.isNotEmpty == true ? user.name![0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        if (_isEditing)
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => FileUploadWidget(
                                  onFilesSelected: _uploadProfilePicture,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name ?? localizations.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.role?.toUpperCase() ?? 'UNKNOWN',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Profile details card
              Card( 
                color: const Color(0xffecf2fe),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileField(
                        icon: Icons.email,
                        label: localizations.email,
                        value: user.email,
                        controller: _emailController,
                        enabled: _isEditing,
                        validator: (value) =>
                            value == null || !value.contains('@') ? localizations.invalidEmail : null,
                      ),
                      const Divider(),
                      _buildProfileField(
                        icon: Icons.person,
                        label: localizations.name,
                        value: user.name,
                        controller: _nameController,
                        enabled: _isEditing,
                        validator: (value) =>
                            value == null || value.isEmpty ? localizations.nameRequired : null,
                      ),
                      const Divider(),
                      _buildProfileField(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phoneNumber,
                        controller: _phoneController,
                        enabled: _isEditing,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Phone number is required' : null,
                      ),
                      const Divider(),
                      _buildProfileField(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: user.address,
                        controller: _addressController,
                        enabled: _isEditing,
                      ),
                      // const Divider(),
                      // ListTile(
                      //   leading: Icon(Icons.security, color: theme.colorScheme.primary),
                      //   title: Text('Two-Factor Authentication'),
                      //   trailing: Switch(
                      //     value: _twoFactorEnabled,
                      //     onChanged: _isEditing
                      //         ? (value) => setState(() => _twoFactorEnabled = value)
                      //         : null,
                      //   ),
                      // ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.access_time, color: theme.colorScheme.primary),
                        title: Text('Last Login'),
                        subtitle: Text(
                          user.lastLogin != null
                              ? DateFormat('dd/MM/yyyy HH:mm').format(user.lastLogin!)
                              : 'N/A',
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.verified_user, color: theme.colorScheme.primary),
                        title: Text('Account Status'),
                        subtitle: Text(user.isActive ? 'Active' : 'Inactive'),
                      ),
                      if (user.departmentId != null) ...[
                        const Divider(),
                        ListTile(
                          leading: Icon(Icons.location_city, color: theme.colorScheme.primary),
                          title: Text('Department'),
                          subtitle: FutureBuilder(
                            future: ApiService.getMasterArea(user.departmentId!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading...');
                              }
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                return const Text('Unknown');
                              }
                              return Text(snapshot.data!['name'] ?? 'Unknown');
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons - FIXED: Added proper constraints
              if (_isEditing) 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CustomButton(
                          text: localizations.cancel,
                          backgroundColor: theme.colorScheme.secondary,
                          onPressed: () => setState(() {
                            _isEditing = false;
                            _nameController.text = user.name ?? '';
                            _emailController.text = user.email ?? '';
                            _phoneController.text = user.phoneNumber ?? '';
                            _addressController.text = user.address ?? '';
                            _twoFactorEnabled = user.twoFactorEnabled ?? false;
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: CustomButton(
                          text: localizations.update,
                          icon: Icons.save,
                          onPressed: _updateProfile,
                          isLoading: _isLoading,
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Edit Profile',
                    icon: Icons.edit,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, // Make logout button full width
                child: CustomButton(
                  text: localizations.logout,
                  icon: Icons.logout,
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      await AuthService.logout();
                      ref.read(userNotifierProvider.notifier).setUser(null);
                      Navigator.pushReplacementNamed(context, '/login');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(localizations.logoutFailed)),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String? value,
    required TextEditingController controller,
    bool enabled = false,
    String? Function(String?)? validator,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: enabled
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: label,
              ),
              validator: validator,
            )
          : Text(value ?? 'N/A'),
    );
  }
}