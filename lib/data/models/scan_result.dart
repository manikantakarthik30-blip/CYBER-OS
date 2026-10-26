import 'vulnerability.dart';

class ScanResult {
  final String id;
  final String projectName;
  final String targetUrlOrPath;
  final int securityScore;
  final List<Vulnerability> vulnerabilities;
  final bool secretsDetected;
  final bool mcpSecure;
  final bool promptInjectionSafe;
  final bool dependenciesSafe;
  final bool apiSecure;
  final String deployStatus; // SAFE_TO_DEPLOY / NOT_SAFE
  final DateTime scannedAt;
  final List<String> logs;

  ScanResult({
    String? id,
    required this.projectName,
    this.targetUrlOrPath = '',
    required this.securityScore,
    required this.vulnerabilities,
    required this.secretsDetected,
    required this.mcpSecure,
    required this.promptInjectionSafe,
    required this.dependenciesSafe,
    this.apiSecure = true,
    required this.deployStatus,
    DateTime? scannedAt,
    this.logs = const [],
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       scannedAt = scannedAt ?? DateTime.now();

  int get criticalCount =>
      vulnerabilities.where((v) => v.severity == 'CRITICAL').length;
  int get highCount =>
      vulnerabilities.where((v) => v.severity == 'HIGH').length;
  int get mediumCount =>
      vulnerabilities.where((v) => v.severity == 'MEDIUM').length;
  int get lowCount =>
      vulnerabilities.where((v) => v.severity == 'LOW').length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectName': projectName,
    'targetUrlOrPath': targetUrlOrPath,
    'securityScore': securityScore,
    'vulnerabilities': vulnerabilities.map((v) => v.toJson()).toList(),
    'secretsDetected': secretsDetected,
    'mcpSecure': mcpSecure,
    'promptInjectionSafe': promptInjectionSafe,
    'dependenciesSafe': dependenciesSafe,
    'apiSecure': apiSecure,
    'deployStatus': deployStatus,
    'scannedAt': scannedAt.toIso8601String(),
    'logs': logs,
  };

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    id: json['id'] as String?,
    projectName: json['projectName'] as String,
    targetUrlOrPath: (json['targetUrlOrPath'] as String?) ?? '',
    securityScore: json['securityScore'] as int,
    vulnerabilities: (json['vulnerabilities'] as List<dynamic>)
        .map((v) => Vulnerability.fromJson(v as Map<String, dynamic>))
        .toList(),
    secretsDetected: json['secretsDetected'] as bool,
    mcpSecure: json['mcpSecure'] as bool,
    promptInjectionSafe: json['promptInjectionSafe'] as bool,
    dependenciesSafe: json['dependenciesSafe'] as bool,
    apiSecure: (json['apiSecure'] as bool?) ?? true,
    deployStatus: json['deployStatus'] as String,
    scannedAt: DateTime.parse(json['scannedAt'] as String),
    logs: (json['logs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}
