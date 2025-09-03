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
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
    _fetchData();
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
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
      drawer: const CustomNavigationDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterDropdown(theme, loc),
              const SizedBox(height: 20),
              kpiData != null
                  ? Column(
                      children: [
                        _buildKpiCard(theme, kpiData, loc),
                        const SizedBox(height: 20),
                        _buildPieChartCard(theme, kpiData, loc),
                        const SizedBox(height: 20),
                        _buildLineChartCard(theme, kpiData, loc),
                        const SizedBox(height: 20),
                        _buildBarChartCard(theme, kpiData, loc),
                        const SizedBox(height: 20),
                        _buildSlaCard(theme, kpiData, loc),
                        const SizedBox(height: 20),
                        Text(loc.recentComplaints ?? 'Recent Complaints',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _buildRecentComplaints(loc),
                        const SizedBox(height: 24),
                        _buildExportButtons(loc),
                      ],
                    )
                  : EmptyState(
                      icon: Icons.error,
                      title: loc.noGrievances,
                      message: loc.noGrievancesMessage,
                      actionButton: ElevatedButton(
                        onPressed: _fetchData,
                        child: Text(loc.retry),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(ThemeData theme, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(loc.filterByPeriod ?? 'Time Period: ',
            style: theme.textTheme.bodyMedium),
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
            if (value != null) {
              setState(() => _selectedPeriod = value);
              _fetchData();
            }
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final totalComplaints = kpiData.totalComplaints ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.totalComplaints ?? 'Total Complaints',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetricItem(loc.day ?? 'Day', totalComplaints['day'] ?? 0),
                _buildMetricItem(
                    loc.week ?? 'Week', totalComplaints['week'] ?? 0),
                _buildMetricItem(
                    loc.month ?? 'Month', totalComplaints['month'] ?? 0),
                _buildMetricItem(
                    loc.year ?? 'Year', totalComplaints['year'] ?? 0),
                _buildMetricItem(
                    loc.allTime ?? 'All Time', totalComplaints['all'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, int value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final statusOverview = kpiData.statusOverview ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.complaintStatusOverview ?? 'Complaint Status Overview',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: statusOverview.isNotEmpty
                  ? PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(statusOverview),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    )
                  : const Center(child: LoadingIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, dynamic> statusOverview) {
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.grey,
      Colors.purple
    ];
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
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
        badgeWidget: Tooltip(
          message: '${entry.key.capitalize()}: ${value.toInt()}',
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLineChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final totalComplaints = kpiData.totalComplaints ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.grievanceTrend ?? 'Grievance Trend Over Time',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: totalComplaints.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                            axisNameWidget: Text(loc.numberOfGrievances ?? 'Number of Grievances'),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = ['Day', 'Week', 'Month', 'Year', 'All'];
                                return Text(
                                  labels[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                            axisNameWidget: Text(loc.timePeriod ?? 'Time Period'),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: 4,
                        minY: 0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, (totalComplaints['day'] ?? 0).toDouble()),
                              FlSpot(1, (totalComplaints['week'] ?? 0).toDouble()),
                              FlSpot(2, (totalComplaints['month'] ?? 0).toDouble()),
                              FlSpot(3, (totalComplaints['year'] ?? 0).toDouble()),
                              FlSpot(4, (totalComplaints['all'] ?? 0).toDouble()),
                            ],
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: LoadingIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final deptWise = kpiData.deptWise ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.deptWiseDistribution ?? 'Department-Wise Distribution',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: deptWise.isNotEmpty
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: _buildBarChartGroups(deptWise),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                            axisNameWidget: Text(loc.numberOfGrievances ?? 'Number of Grievances'),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final keys = deptWise.keys.toList();
                                return Text(
                                  keys[value.toInt()].capitalize(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                            axisNameWidget: Text(loc.department ?? 'Department'),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        gridData: FlGridData(show: true),
                      ),
                    )
                  : const Center(child: LoadingIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarChartGroups(Map<String, dynamic> deptWise) {
    const colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
    ];
    return deptWise.entries.toList().asMap().entries.map((entry) {
  final index = entry.key;
  final dept = entry.value.key;
  final value = entry.value.value is num
      ? (entry.value.value as num).toDouble()
      : double.tryParse(entry.value.value.toString()) ?? 0.0;

  return BarChartGroupData(
    x: index,
    barRods: [
      BarChartRodData(
        toY: value,
        color: colors[index % colors.length],
        width: 16,
        borderRadius: BorderRadius.circular(4),
      ),
    ],
  );
}).toList();

  }

  Widget _buildSlaCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final slaMetrics = kpiData.slaMetrics ?? {};

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.slaMetrics ?? 'SLA Metrics',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSlaMetricItem(loc.slaDays ?? 'SLA Days',
                '${slaMetrics['sla_days'] ?? 7}'),
            _buildSlaMetricItem(loc.complianceRate ?? 'Compliance Rate',
                '${(slaMetrics['sla_compliance_rate'] ?? 0).toStringAsFixed(2)}%'),
            _buildSlaMetricItem(
                loc.avgResolutionTime ?? 'Avg Resolution Time',
                '${(slaMetrics['avg_resolution_time_days'] ?? 0).toStringAsFixed(2)} days'),
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

  Widget _buildRecentComplaints(AppLocalizations loc) {
    return FutureBuilder<List<Grievance>>(
      future: _grievancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        } else if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error,
            title: loc.error,
            message: '${loc.noGrievancesMessage}\n${snapshot.error}',
            actionButton: ElevatedButton(
              onPressed: () {
                setState(() {
                  _grievancesFuture = ref.read(adminProvider.notifier).getAllGrievances();
                });
              },
              child: Text(loc.retry),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyState(
            icon: Icons.inbox,
            title: loc.noGrievances,
            message: loc.noGrievancesMessage,
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

  Widget _buildExportButtons(AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: () => _exportReport('pdf'),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(loc.exportPDF ?? 'Export PDF'),
        ),
        OutlinedButton.icon(
          onPressed: () => _exportReport('csv'),
          icon: const Icon(Icons.table_chart),
          label: Text(loc.exportCSV ?? 'Export CSV'),
        ),
        OutlinedButton.icon(
          onPressed: () => _exportReport('excel'),
          icon: const Icon(Icons.grid_on),
          label: Text(loc.exportExcel ?? 'Export Excel'),
        ),
      ],
    );
  }

  Future<void> _exportReport(String format) async {
  final loc = AppLocalizations.of(context)!;
  try {
    final data = await ref
        .read(adminProvider.notifier)
        .generateReport(_selectedPeriod, format);
    final fileName =
        'report_${_selectedPeriod}_$format.${format == 'excel' ? 'xlsx' : format}';

    if (kIsWeb) {
      // Web-specific file download
      final blob = html.Blob([data]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.reportExported ?? 'Report exported'}: $fileName')));
    } else {
      // Mobile/desktop file handling
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = io.File(filePath);
      await file.writeAsBytes(data);
      await OpenFile.open(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.reportExported ?? 'Report exported'}: $fileName')));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorExportingReport ?? 'Error exporting report'}: $e')));
  }
}
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}