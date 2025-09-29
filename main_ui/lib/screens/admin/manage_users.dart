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
  const ManageUsers({super.key});

  @override
  ConsumerState<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends ConsumerState<ManageUsers> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.addUser,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
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
                            filled: true,
                            fillColor: Colors.grey[50],
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: validateEmail,
                          onChanged: (value) => email = value,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: l10n.phoneNumber,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.phoneNumberRequired;
                            }
                            if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                              return l10n.invalidPhoneNumber;
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.passwordRequired;
                            }
                            if (value.length < 6) {
                              return l10n.passwordTooShort;
                            }
                            return null;
                          },
                          onChanged: (value) => password = value,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: InputDecoration(
                            labelText: l10n.role,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CITIZEN', child: Text('CITIZEN')),
                            DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('SUPERVISOR')),
                            DropdownMenuItem(value: 'FIELD_STAFF', child: Text('FIELD_STAFF')),
                            // DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                          ],
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
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => departmentId = value.isEmpty ? null : value,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[700])),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100, // Fixed width to avoid layout issues
                      child: CustomButton(
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
                                SnackBar(
                                  content: Text(l10n.userAddedSuccess),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${l10n.failedToAddUser}: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.editUser ?? 'Edit User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
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
                                  filled: true,
                                  fillColor: Colors.grey[50],
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
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: validateEmail,
                                onChanged: (value) => email = value,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                initialValue: phoneNumber,
                                decoration: InputDecoration(
                                  labelText: l10n.phoneNumber,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.phoneNumberRequired;
                                  }
                                  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
                                    return l10n.invalidPhoneNumber;
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
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'CITIZEN', child: Text('CITIZEN')),
                                  DropdownMenuItem(value: 'MEMBER_HEAD', child: Text('Supervisor')),
                                  DropdownMenuItem(value: 'FIELD_STAFF', child: Text('FIELD_STAFF')),
                                  // DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                                ],
                                onChanged: (value) => setDialogState(() {
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
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => departmentId = value.isEmpty ? null : value,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[700])),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 100, // Fixed width to avoid layout issues
                            child: CustomButton(
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
                                        content: Text(l10n.userUpdatedSuccess),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${l10n.failedToUpdateUser}: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(int userId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange[700]),
              const SizedBox(height: 16),
              Text(
                l10n.deleteUser,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.deleteUserConfirmation,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel, style: TextStyle(color: Colors.grey[700])),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 100, // Fixed width to avoid layout issues
                    child: CustomButton(
                      text: l10n.delete,
                      backgroundColor: Colors.red,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(usersProvider.notifier).deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.userDeletedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDeleteUser}: $e'),
            backgroundColor: Colors.red,
          ),
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
      backgroundColor: const Color(0xFFf8fbff), // Set background color
      appBar: AppBar(
        title: Text(l10n.manageUsers),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(usersProvider.notifier).fetchUsers(),
            tooltip: l10n.retry,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: theme.colorScheme.primary,
        tooltip: l10n.addUser,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchByNameOrEmail,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noUsers,
                    message: l10n.noUsersMessage,
                    actionButton: CustomButton(
                      text: l10n.addUser,
                      onPressed: _showAddUserDialog,
                    ),
                  )
                : _buildUserList(users, _searchController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<User> users, String query) {
    final l10n = AppLocalizations.of(context)!;
    final filteredUsers = users.where((user) {
      final lowerQuery = query.toLowerCase();
      return (user.name?.toLowerCase().contains(lowerQuery) ?? false) ||
             (user.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    if (filteredUsers.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.noResultsFound,
        message: l10n.noMatchingUsers,
        actionButton: CustomButton(
          text: l10n.retry,
          onPressed: () => _searchController.clear(),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        color: const Color(0xFFecf2fe), // Set card background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              (user.name?.isNotEmpty ?? false) ? user.name![0] : '?',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
          title: Text(user.name ?? "", 
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600
              )),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                user.email ?? l10n.noEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700]
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDisplayRole(user.role),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue[700]),
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
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'MEMBER_HEAD':
        return Colors.orange;
      case 'FIELD_STAFF':
        return Colors.green;
      case 'CITIZEN':
      
      default:
        return Colors.blue;
    }
  }

  String _getDisplayRole(String? role) {
    if (role == null) return '';
    switch (role.toLowerCase()) {
      case 'member_head':
        return AppLocalizations.of(context)!.roleSupervisor;
      default:
        return role.toUpperCase();
    }
  }
}