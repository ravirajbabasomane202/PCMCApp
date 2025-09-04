import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import '../../providers/user_provider.dart';

class ManageUsers extends ConsumerStatefulWidget {
  const ManageUsers({Key? key}) : super(key: key);

  @override
  ConsumerState<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends ConsumerState<ManageUsers> {
  Future<void> _showAddUserDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phoneNumber = '';
    String password = '';
    String role = 'CITIZEN';
    String? departmentId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addUser),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: validateRequired,
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: validateEmail,
                  onChanged: (value) => email = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                  onChanged: (value) => phoneNumber = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => password = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: InputDecoration(
                    labelText: l10n.role,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['CITIZEN', 'MEMBER_HEAD', 'FIELD_STAFF', 'ADMIN']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) => role = value ?? 'CITIZEN',
                  validator: validateRequired,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Department ID (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => departmentId = value.isEmpty ? null : value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CustomButton(
            text: l10n.add,
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  await ref.read(usersProvider.notifier).addUser({
                    'name': name,
                    'email': email,
                    'phone_number': phoneNumber,
                    'password': password,
                    'role': role,
                    'department_id':
                        departmentId != null ? int.tryParse(departmentId!) : null,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userAddedSuccess)),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.failedToAddUser}: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserDialog(User user) async {
  final l10n = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  String name = user.name ?? "";
  String email = user.email ?? '';
  String phoneNumber = user.phoneNumber ?? '';
  // Normalize role to match dropdown items
  String role = ['CITIZEN', 'MEMBER_HEAD', 'FIELD_STAFF', 'ADMIN']
      .contains(user.role?.toUpperCase())
      ? user.role!.toUpperCase()
      : 'CITIZEN'; // Default to 'CITIZEN' if invalid
  String? departmentId = user.departmentId?.toString();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.editUser ?? 'Edit User'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: validateRequired,
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: validateEmail,
                onChanged: (value) => email = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: phoneNumber,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                    return 'Invalid phone number';
                  }
                  return null;
                },
                onChanged: (value) => phoneNumber = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(
                  labelText: l10n.role,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['CITIZEN', 'MEMBER_HEAD', 'FIELD_STAFF', 'ADMIN']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) => setState(() {
                  role = value ?? 'CITIZEN';
                }),
                validator: validateRequired,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: departmentId,
                decoration: InputDecoration(
                  labelText: 'Department ID (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => departmentId = value.isEmpty ? null : value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CustomButton(
          text: l10n.update,
          onPressed: () async {
            if (formKey.currentState?.validate() ?? false) {
              try {
                await ref.read(usersProvider.notifier).updateUser(user.id, {
                  'id': user.id,
                  'name': name,
                  'email': email,
                  'phone_number': phoneNumber,
                  'role': role,
                  'department_id':
                      departmentId != null ? int.tryParse(departmentId!) : null,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.userUpdatedSuccess ??
                          'User updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '${l10n.failedToUpdateUser ?? 'Failed to update user'}: $e')),
                );
              }
            }
          },
        ),
      ],
    ),
  );
}

  Future<void> _confirmDeleteUser(int userId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUser ?? 'Delete User'),
        content: Text(l10n.deleteUserConfirmation ??
            'Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          CustomButton(
            text: l10n.delete ?? 'Delete',
            backgroundColor: Colors.red,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(usersProvider.notifier).deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(l10n.userDeletedSuccess ?? 'User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${l10n.failedToDeleteUser ?? 'Failed to delete user'}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(usersProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageUsers),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(usersProvider.notifier).fetchUsers(),
            tooltip: l10n.retry,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
        tooltip: l10n.addUser,
      ),
      body: users.isEmpty
          ? EmptyState(
              icon: Icons.people_outline,
              title: l10n.noUsers,
              message: l10n.noUsersMessage,
              actionButton: CustomButton(
                text: l10n.addUser,
                onPressed: _showAddUserDialog,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        (user.name?.isNotEmpty ?? false) ? user.name![0] : '?',
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(user.name ?? "", style: theme.textTheme.titleMedium),
                    subtitle: Text(
                      '${user.email ?? l10n.noEmail} • ${user.role}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditUserDialog(user),
                          tooltip: l10n.editUser,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteUser(user.id),
                          tooltip: l10n.deleteUser,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
