import 'scan_result.dart';

class SecurityReport {
  final String title;
  final String generatedBy;
  final DateTime generatedAt;
  final ScanResult scanResult;
  final String summaryMarkdown;

  SecurityReport({
    required this.title,
    this.generatedBy = 'CYBER_OS v1.0 Kernel',
    DateTime? generatedAt,
    required this.scanResult,
    required this.summaryMarkdown,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'generatedBy': generatedBy,
    'generatedAt': generatedAt.toIso8601String(),
    'scanResult': scanResult.toJson(),
    'summaryMarkdown': summaryMarkdown,
  };
}
