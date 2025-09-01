import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/grievance_card.dart';

import 'package:main_ui/providers/admin_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io' as io;

import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/models/kpi_model.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  String _selectedPeriod = 'all';
  late Future<List<Grievance>> _grievancesFuture;

  @override
  void initState() {
    super.initState();
    _grievancesFuture = ref.read(adminProvider.notifier).getAllGrievances();
  }

  Future<void> _fetchData() async {
    try {
      await ref.read(adminProvider.notifier).fetchAdvancedKPIs(timePeriod: _selectedPeriod);
      setState(() {
        _grievancesFuture = ref.read(adminProvider.notifier).getAllGrievances();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> statusOverview) {
    const colors = [Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.grey, Colors.purple];
    int index = 0;

    final entries = statusOverview.entries
        .where((entry) =>
            (entry.value is num && (entry.value as num) > 0) ||
            (entry.value is String && int.tryParse(entry.value) != null && int.parse(entry.value) > 0))
        .toList();

    if (entries.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 50,
        )
      ];
    }

    return entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      final value = entry.value is num
          ? (entry.value as num).toDouble()
          : double.tryParse(entry.value.toString()) ?? 0.0;

      return PieChartSectionData(
        value: value,
        title: '${entry.key.replaceAll('_', ' ').capitalize()}\n${value.toInt()}',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  Future<void> _exportReport(String format) async {
    try {
      final data = await ref.read(adminProvider.notifier).generateReport(_selectedPeriod, format);
      final dir = await getTemporaryDirectory();
      final fileName = 'report_${_selectedPeriod}_$format.${format == 'excel' ? 'xlsx' : format}';
      final filePath = '${dir.path}/$fileName';
      final file = io.File(filePath);
      await file.writeAsBytes(data);
      await OpenFile.open(filePath);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report exported: $fileName')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final kpiData = adminState.kpiData;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        centerTitle: true,
        elevation: 2,
      ),
      drawer: _buildDrawer(theme),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterDropdown(theme),
              const SizedBox(height: 20),
              if (kpiData != null) ...[
                _buildKpiCard(theme, kpiData),
                const SizedBox(height: 20),
                _buildPieChartCard(theme, kpiData),
                const SizedBox(height: 20),
                _buildSlaCard(theme, kpiData),
                const SizedBox(height: 20),
                Text('Recent Complaints', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildRecentComplaints(),
                const SizedBox(height: 24),
                _buildExportButtons(),
              ] else ...[
                const Center(child: Text('No KPI data available')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Admin Menu',
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
          _drawerItem(Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
          _drawerItem(Icons.history, 'View Audit Logs', () => Navigator.pushNamed(context, '/admin/audit')),
          _drawerItem(Icons.report_problem, 'Complaint Management', () => Navigator.pushNamed(context, '/admin/complaints')),
          _drawerItem(Icons.settings, 'Manage Configs', () => Navigator.pushNamed(context, '/admin/configs')),
          _drawerItem(Icons.subject, 'Manage Subjects', () => Navigator.pushNamed(context, '/admin/subjects')),
          _drawerItem(Icons.people, 'Manage Users', () => Navigator.pushNamed(context, '/admin/users')),
          _drawerItem(Icons.person_search, 'User History', () => Navigator.pushNamed(context, '/admin/all_users_history')),
          _drawerItem(Icons.map, 'Manage Areas', () => Navigator.pushNamed(context, '/admin/areas')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildFilterDropdown(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Time Period: '),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedPeriod,
          style: theme.textTheme.bodyMedium,
          items: ['day', 'week', 'month', 'year', 'all']
              .map((period) => DropdownMenuItem(
                    value: period,
                    child: Text(period.capitalize()),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedPeriod = value!);
            _fetchData();
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard(ThemeData theme, KpiData kpiData) {
    final totalComplaints = kpiData.totalComplaints;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Complaints', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetricItem('Day', totalComplaints['day']),
                _buildMetricItem('Week', totalComplaints['week']),
                _buildMetricItem('Month', totalComplaints['month']),
                _buildMetricItem('Year', totalComplaints['year']),
                _buildMetricItem('All Time', totalComplaints['all']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, int? value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          '${value ?? 0}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(ThemeData theme, KpiData kpiData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complaint Status Overview', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(kpiData.statusOverview),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaCard(ThemeData theme, KpiData kpiData) {
    final slaMetrics = kpiData.slaMetrics;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SLA Metrics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSlaMetricItem('SLA Days', '${slaMetrics['sla_days'] ?? 7}'),
            _buildSlaMetricItem('Compliance Rate', '${(slaMetrics['sla_compliance_rate'] ?? 0).toStringAsFixed(2)}%'),
            _buildSlaMetricItem('Avg Resolution Time', '${(slaMetrics['avg_resolution_time_days'] ?? 0).toStringAsFixed(2)} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaMetricItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentComplaints() {
    return FutureBuilder<List<Grievance>>(
      future: _grievancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        } else if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error,
            title: AppLocalizations.of(context)!.error,
            message: '${AppLocalizations.of(context)!.noGrievancesMessage}\n${snapshot.error}',
            actionButton: ElevatedButton(
              onPressed: () {
                setState(() {
                  _grievancesFuture = ref.read(adminProvider.notifier).getAllGrievances();
                });
              },
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.inbox,
            title: AppLocalizations.of(context)!.noGrievances,
            message: AppLocalizations.of(context)!.noGrievancesMessage,
          );
        }

        final grievances = snapshot.data!.take(5).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grievances.length,
          itemBuilder: (ctx, idx) => GrievanceCard(grievance: grievances[idx]),
        );
      },
    );
  }

  Widget _buildExportButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: () => _exportReport('pdf'),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => _exportReport('csv'),
          icon: const Icon(Icons.table_chart),
          label: const Text('Export CSV'),
        ),
        OutlinedButton.icon(
          onPressed: () => _exportReport('excel'),
          icon: const Icon(Icons.grid_on),
          label: const Text('Export Excel'),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}