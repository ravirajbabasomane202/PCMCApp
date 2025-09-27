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
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:universal_html/html.dart' as html;
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
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(loc.appTitle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      drawer: const CustomNavigationDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        backgroundColor: Colors.white,
        color: Colors.blue.shade600,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(loc.recentComplaints ?? 'Recent Complaints',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(loc.filterByPeriod ?? 'Time Period: ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _selectedPeriod,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade800,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
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
      ),
    );
  }

  Widget _buildKpiCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final totalComplaints = kpiData.totalComplaints ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFecf2fe),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.totalComplaints ?? 'Total Complaints',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildMetricItem(loc.day ?? 'Day', totalComplaints['day'] ?? 0, Colors.blue),
                _buildMetricItem(loc.week ?? 'Week', totalComplaints['week'] ?? 0, Colors.green),
                _buildMetricItem(loc.month ?? 'Month', totalComplaints['month'] ?? 0, Colors.orange),
                _buildMetricItem(loc.year ?? 'Year', totalComplaints['year'] ?? 0, Colors.purple),
                _buildMetricItem(loc.allTime ?? 'All Time', totalComplaints['all'] ?? 0, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label, 
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            )),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final statusOverview = kpiData.statusOverview ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFecf2fe),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.complaintStatusOverview ?? 'Complaint Status Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: statusOverview.isNotEmpty
                  ? PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(statusOverview),
                        centerSpaceRadius: 50,
                        sectionsSpace: 0,
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade600,
                      ),
                    ),
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
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.deepOrange,
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
          color: Colors.grey.shade300,
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
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
        title: '${value.toInt()}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            entry.key.capitalize(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _buildLineChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final totalComplaints = kpiData.totalComplaints ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFecf2fe),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.grievanceTrend ?? 'Grievance Trend Over Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: totalComplaints.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = ['Day', 'Week', 'Month', 'Year', 'All'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
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
                            color: Colors.blue.shade600,
                            barWidth: 4,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue.shade600,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600.withOpacity(0.3),
                                  Colors.blue.shade100.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final deptWise = kpiData.deptWise ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFecf2fe),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.deptWiseDistribution ?? 'Department-Wise Distribution',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
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
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final keys = deptWise.keys.toList();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    keys[value.toInt()].capitalize(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue.shade600,
                      ),
                    ),
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
      Colors.teal,
      Colors.amber,
      Colors.deepOrange,
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
            width: 20,
            borderRadius: BorderRadius.circular(8),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: value * 1.1,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildSlaCard(ThemeData theme, KpiData kpiData, AppLocalizations loc) {
    final slaMetrics = kpiData.slaMetrics ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFecf2fe),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.slaMetrics ?? 'SLA Metrics',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            _buildSlaMetricItem(
              loc.slaDays ?? 'SLA Days',
              '${slaMetrics['sla_days'] ?? 7}',
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSlaMetricItem(
              loc.complianceRate ?? 'Compliance Rate',
              '${(slaMetrics['sla_compliance_rate'] ?? 0).toStringAsFixed(2)}%',
              Icons.percent,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSlaMetricItem(
              loc.avgResolutionTime ?? 'Avg Resolution Time',
              '${(slaMetrics['avg_resolution_time_days'] ?? 0).toStringAsFixed(2)} days',
              Icons.timer,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentComplaints(AppLocalizations loc) {
    return FutureBuilder<List<Grievance>>(
      future: _grievancesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
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
          itemBuilder: (ctx, idx) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GrievanceCard(grievance: grievances[idx]),
          ),
        );
      },
    );
  }

  Widget _buildExportButtons(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            loc.exportReports ?? 'Export Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildExportButton(
                icon: Icons.picture_as_pdf,
                label: loc.exportPDF ?? 'PDF',
                color: Colors.red,
                onPressed: () => _exportReport('pdf'),
              ),
              _buildExportButton(
                icon: Icons.table_chart,
                label: loc.exportCSV ?? 'CSV',
                color: Colors.green,
                onPressed: () => _exportReport('csv'),
              ),
              _buildExportButton(
                icon: Icons.grid_on,
                label: loc.exportExcel ?? 'Excel',
                color: Colors.blue,
                onPressed: () => _exportReport('excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
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
            SnackBar(
              content: Text('${loc.reportExported ?? 'Report exported'}: $fileName'),
              backgroundColor: Colors.green,
            ));
      } else {
        // Mobile/desktop file handling
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = io.File(filePath);
        await file.writeAsBytes(data);
        await OpenFile.open(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.reportExported ?? 'Report exported'}: $fileName'),
              backgroundColor: Colors.green,
            ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.errorExportingReport ?? 'Error exporting report'}: $e'),
            backgroundColor: Colors.red,
          ));
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}