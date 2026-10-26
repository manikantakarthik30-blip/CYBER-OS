import 'package:dio/dio.dart';

class OSVPackageQuery {
  final String name;
  final String ecosystem; // PyPI, npm, Pub, Maven, Go, etc.
  final String? version;

  OSVPackageQuery({
    required this.name,
    required this.ecosystem,
    this.version,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'package': {
        'name': name,
        'ecosystem': ecosystem,
      }
    };
    if (version != null && version!.isNotEmpty) {
      map['version'] = version;
    }
    return map;
  }
}

class OSVVulnerabilityDetail {
  final String id;
  final String summary;
  final String details;
  final String severity; // CRITICAL, HIGH, MEDIUM, LOW
  final List<String> aliases; // CVE IDs
  final String? fixedVersion;

  OSVVulnerabilityDetail({
    required this.id,
    required this.summary,
    required this.details,
    required this.severity,
    required this.aliases,
    this.fixedVersion,
  });
}

class OSVService {
  final Dio _dio;

  OSVService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Future<Map<String, List<OSVVulnerabilityDetail>>> queryBatch(
    List<OSVPackageQuery> queries,
  ) async {
    if (queries.isEmpty) return {};

    final Map<String, List<OSVVulnerabilityDetail>> results = {};

    try {
      const url = 'https://api.osv.dev/v1/querybatch';
      final payload = {
        'queries': queries.map((q) => q.toJson()).toList(),
      };

      final response = await _dio.post(
        url,
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final batchResults = response.data['results'] as List<dynamic>? ?? [];

        for (int i = 0; i < batchResults.length; i++) {
          if (i >= queries.length) break;
          final query = queries[i];
          final packageKey = '${query.name}@${query.version ?? "any"}';
          final vulnsList = batchResults[i]['vulns'] as List<dynamic>? ?? [];

          final parsedVulns = <OSVVulnerabilityDetail>[];
          for (final v in vulnsList) {
            final id = v['id'] as String? ?? 'OSV-UNKNOWN';
            final summary = v['summary'] as String? ?? 'Vulnerability identified in ${query.name}';
            final details = v['details'] as String? ?? summary;
            final aliases = (v['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

            // Calculate CVSS / Severity
            String severity = 'HIGH';
            final severityList = v['severity'] as List<dynamic>? ?? [];
            for (final s in severityList) {
              final scoreStr = s['score'] as String? ?? '';
              if (scoreStr.contains('CVSS')) {
                // If CVSS score present
                severity = _mapCvssToSeverity(scoreStr);
              }
            }

            // Extract fix version if available
            String? fixVersion;
            final affected = v['affected'] as List<dynamic>? ?? [];
            for (final aff in affected) {
              final ranges = aff['ranges'] as List<dynamic>? ?? [];
              for (final r in ranges) {
                final events = r['events'] as List<dynamic>? ?? [];
                for (final ev in events) {
                  if (ev['fixed'] != null) {
                    fixVersion = ev['fixed'].toString();
                    break;
                  }
                }
              }
            }

            parsedVulns.add(
              OSVVulnerabilityDetail(
                id: id,
                summary: summary,
                details: details,
                severity: severity,
                aliases: aliases,
                fixedVersion: fixVersion,
              ),
            );
          }

          if (parsedVulns.isNotEmpty) {
            results[packageKey] = parsedVulns;
          }
        }
      }
    } catch (_) {
      // Graceful fallback on network failure or offline scanning
    }

    return results;
  }

  String _mapCvssToSeverity(String cvssString) {
    if (cvssString.contains('AV:N') && cvssString.contains('PR:N') && cvssString.contains('C:H')) {
      return 'CRITICAL';
    }
    return 'HIGH';
  }
}
