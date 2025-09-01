class KpiData {
  final Map<String, int> totalComplaints;
  final Map<String, int> statusOverview;
  final Map<String, int> deptWise;
  final Map<String, dynamic> slaMetrics;
  final Map<String, int> staffPerformance;

  KpiData({
    required this.totalComplaints,
    required this.statusOverview,
    required this.deptWise,
    required this.slaMetrics,
    required this.staffPerformance,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      totalComplaints: Map<String, int>.from(json['total_complaints'] ?? {}),
      statusOverview: Map<String, int>.from(json['status_overview'] ?? {}),
      deptWise: Map<String, int>.from(json['dept_wise'] ?? {}),
      slaMetrics: Map<String, dynamic>.from(json['sla_metrics'] ?? {}),
      staffPerformance: Map<String, int>.from(json['staff_performance'] ?? {}),
    );
  }
}