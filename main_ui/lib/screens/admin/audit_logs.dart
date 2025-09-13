// lib/screens/admin/audit_logs.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';

class AuditLogs extends ConsumerStatefulWidget {
  const AuditLogs({super.key});

  @override
  ConsumerState<AuditLogs> createState() => _AuditLogsState();
}

class _AuditLogsState extends ConsumerState<AuditLogs> {
  late Future<List<dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchLogs();
  }

  Future<List<dynamic>> _fetchLogs() async {
    final response = await ApiService.get('/admins/audit-logs');
    return response.data as List<dynamic>;
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: const Text(
          'Audit Logs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue.shade600),
            tooltip: "Refresh Logs",
            onPressed: _refreshLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade600,
                strokeWidth: 3,
              ),
            );
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Error Loading Logs',
              message: 'Failed to load audit logs. Please try again.',
              actionButton: CustomButton(
                text: 'Retry',
                onPressed: _refreshLogs,
                backgroundColor: Colors.blue.shade600,
                
              ),
            );
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.history_toggle_off,
              title: 'No Audit Logs',
              message: 'There are no audit logs to display at this time.',
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activities',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${logs.length} entries',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _buildLogCard(log, theme);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFecf2fe),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle log item tap if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getActionIcon(log['action']),
                    color: Colors.blue.shade800,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['action'] ?? 'Unknown Action',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.person,
                        'Performed by: ${log['performed_by'] ?? 'Unknown'}',
                        theme,
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        Icons.access_time,
                        'At: ${_formatTimestamp(log['timestamp'])}',
                        theme,
                      ),
                      if (log['details'] != null) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow(
                          Icons.description,
                          'Details: ${log['details']}',
                          theme,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('login')) return Icons.login;
    if (lowerAction.contains('create') || lowerAction.contains('add')) return Icons.add_circle;
    if (lowerAction.contains('update') || lowerAction.contains('edit')) return Icons.edit;
    if (lowerAction.contains('delete') || lowerAction.contains('remove')) return Icons.delete;
    if (lowerAction.contains('view') || lowerAction.contains('read')) return Icons.visibility;
    if (lowerAction.contains('export')) return Icons.download;
    if (lowerAction.contains('import')) return Icons.upload;
    return Icons.info;
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}