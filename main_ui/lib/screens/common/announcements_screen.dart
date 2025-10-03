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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.addAnnouncement,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.title,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: const Color(0xFFf8fbff),
                      ),
                      validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.error : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.message,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: const Color(0xFFf8fbff),
                      ),
                      validator: (value) => value!.isEmpty ? AppLocalizations.of(context)!.error : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      items: ['general', 'emergency'].map((t) => DropdownMenuItem(
                        value: t, 
                        child: Text(t.capitalize(), style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (value) => setState(() => _type = value!),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.type,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: const Color(0xFFf8fbff),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFf8fbff),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text(
                          _expiresAt == null
                              ? AppLocalizations.of(context)!.selectExpiration
                              : DateFormat('yyyy-MM-dd').format(_expiresAt!),
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(Icons.calendar_today, size: 20),
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
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _targetRole,
                      items: [
                        {'label': 'CITIZEN', 'value': 'citizen'},
                        {'label': 'SUPERVISOR', 'value': 'member_head'},
                        {'label': 'FIELD_STAFF', 'value': 'field_staff'},
                        {'label': 'ADMIN', 'value': 'admin'},
                      ].map((role) => DropdownMenuItem(
                        value: role['value'],
                        child: Text(role['label']!, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (value) => setState(() => _targetRole = value),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.targetRole,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: const Color(0xFFf8fbff),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        const SizedBox(width: 8),
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
                                    content: Text(AppLocalizations.of(context)!.announcementAdded),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(AppLocalizations.of(context)!.submit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(int id) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDelete),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/admins/announcements/$id');
        ref.refresh(announcementsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider);
    final isAdmin = user?.role?.toUpperCase() == 'ADMIN';
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(localizations.announcements),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add),
            )
          : null,
      body: announcementsAsync.when(
        data: (announcements) => announcements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.announcement, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      localizations.noAnnouncements,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Card(
                      color: const Color(0xFFecf2fe),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ann.type == 'emergency' ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    ann.type == 'emergency' ? Icons.warning : Icons.info,
                                    color: ann.type == 'emergency' ? Colors.red : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ann.title,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ann.message,
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: ann.type == 'emergency' ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        ann.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: ann.type == 'emergency' ? Colors.red : Colors.blue,
                                        ),
                                      ),
                                    ),
                                    if (isAdmin)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _deleteAnnouncement(ann.id),
                                        tooltip: 'Delete Announcement',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.grey.shade300, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Posted on ${DateFormat('dd/MM/yyyy').format(ann.createdAt)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                if (ann.expiresAt != null) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires on ${DateFormat('dd/MM/yyyy').format(ann.expiresAt!)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '${localizations.error}: $err',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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