class ReportData {
  final Map<String, int> totalComplaints;
  final Map<String, int> statusOverview;
  final Map<String, int> deptWise;
  final Map<String, dynamic> slaMetrics;
  final Map<String, int> staffPerformance;
  final double resolutionRate;
  final Map<String, dynamic> pendingAging;
  final double slaCompliance;

  ReportData({
    required this.totalComplaints,
    required this.statusOverview,
    required this.deptWise,
    required this.slaMetrics,
    required this.staffPerformance,
    required this.resolutionRate,
    required this.pendingAging,
    required this.slaCompliance,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      totalComplaints: Map<String, int>.from(json['total_complaints'] ?? {}),
      statusOverview: Map<String, int>.from(json['status_overview'] ?? {}),
      deptWise: Map<String, int>.from(json['dept_wise'] ?? {}),
      slaMetrics: Map<String, dynamic>.from(json['sla_metrics'] ?? {}),
      staffPerformance: Map<String, int>.from(json['staff_performance'] ?? {}),
      resolutionRate: json['resolution_rate']?.toDouble() ?? 0.0,
      pendingAging: Map<String, dynamic>.from(json['pending_aging'] ?? {}),
      slaCompliance: json['sla_compliance']?.toDouble() ?? 0.0,
    );
  }
}