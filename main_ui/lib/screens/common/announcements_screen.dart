// D:\Company_Data\PCMCApp\main_ui\lib\screens\common\announcements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/announcement_model.dart';
import 'package:main_ui/providers/user_provider.dart';
import 'package:main_ui/services/api_service.dart';

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final response = await ApiService.get('/admins/announcements');
  return (response.data as List).map((json) => Announcement.fromJson(json)).toList();
});

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _type = 'general';
  DateTime? _expiresAt;
  String? _targetRole;

  void _showAddAnnouncementDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addAnnouncement ?? 'Add Announcement'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title ?? 'Title'),
                    validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.error ?? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.message ?? 'Message'),
                    validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.error ?? 'Required' : null,
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: ['general', 'emergency'].map((t) => DropdownMenuItem(value: t, child: Text(t.capitalize()))).toList(),
                    onChanged: (value) => setState(() => _type = value!),
                    decoration: InputDecoration(labelText: AppLocalizations.of(context)!.type ?? 'Type'),
                  ),
                  ListTile(
                    title: Text(_expiresAt == null
                        ? AppLocalizations.of(context)!.selectExpiration ?? 'Select Expiration'
                        : DateFormat('yyyy-MM-dd').format(_expiresAt!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _expiresAt = picked);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _targetRole,
                    items: [
    {'label': 'CITIZEN', 'value': 'citizen'},
    {'label': 'MEMBER_HEAD', 'value': 'member_head'},
    {'label': 'FIELD_STAFF', 'value': 'field_staff'},
    {'label': 'ADMIN', 'value': 'admin'},
  ].map((role) => DropdownMenuItem(
        value: role['value'], // 👈 send lowercase to backend
        child: Text(role['label']!), // 👈 display uppercase to user
      ))
      .toList(),
                    onChanged: (value) => setState(() => _targetRole = value),
                    decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.targetRole ?? 'Target Role (Optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'title': _titleController.text,
                    'message': _messageController.text,
                    'type': _type,
                    'expires_at': _expiresAt?.toIso8601String(),
                    'target_role': _targetRole,
                    'is_active': true,
                  };
                  try {
                    await ApiService.post('/admins/announcements', data);
                    ref.refresh(announcementsProvider);
                    Navigator.pop(context);
                    _titleController.clear();
                    _messageController.clear();
                    _type = 'general';
                    _expiresAt = null;
                    _targetRole = null;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(AppLocalizations.of(context)!.announcementAdded ?? 'Announcement added')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(AppLocalizations.of(context)!.submit ?? 'Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider);
    final isAdmin = user?.role?.toUpperCase() == 'ADMIN';
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.announcements ?? 'Announcements')),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: announcementsAsync.when(
        data: (announcements) => announcements.isEmpty
            ? Center(
                child: Text(localizations.noAnnouncements ?? 'No announcements available'),
              )
            : ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Icon(
                        ann.type == 'emergency' ? Icons.warning : Icons.info,
                        color: ann.type == 'emergency' ? Colors.red : Colors.blue,
                      ),
                      title: Text(ann.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ann.message),
                          const SizedBox(height: 4),
                          Text(
                            'Posted on ${DateFormat('dd/MM/yyyy').format(ann.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (ann.expiresAt != null)
                            Text(
                              'Expires on ${DateFormat('dd/MM/yyyy').format(ann.expiresAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                      trailing: Text(ann.type.toUpperCase()),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${localizations.error}: $err')),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}