import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GitHubRepoTarget {
  final String owner;
  final String repo;
  final String? branch;

  GitHubRepoTarget({required this.owner, required this.repo, this.branch});
}

class GitHubFileItem {
  final String path;
  final String type; // 'blob' or 'tree'
  final int? size;
  final String? url;

  GitHubFileItem({
    required this.path,
    required this.type,
    this.size,
    this.url,
  });
}

class GitHubService {
  final Dio _dio;

  GitHubService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  Map<String, String> _getHeaders() {
    final token = dotenv.isInitialized ? dotenv.maybeGet('GITHUB_TOKEN') : null;
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'CYBER_OS-Security-Kernel/1.0',
    };
    if (token != null && token.isNotEmpty && !token.contains('your_')) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  GitHubRepoTarget? parseRepoUrl(String input) {
    var sanitized = input.trim();
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    if (sanitized.endsWith('.git')) {
      sanitized = sanitized.substring(0, sanitized.length - 4);
    }

    // Match github.com/owner/repo or https://github.com/owner/repo
    final regex = RegExp(r'(?:https?:\/\/)?(?:www\.)?github\.com\/([^\/]+)\/([^\/]+)');
    final match = regex.firstMatch(sanitized);
    if (match != null) {
      return GitHubRepoTarget(
        owner: match.group(1)!,
        repo: match.group(2)!,
      );
    }

    // Match plain owner/repo
    final plainRegex = RegExp(r'^([a-zA-Z0-9_\-\.]+)\/([a-zA-Z0-9_\-\.]+)$');
    final plainMatch = plainRegex.firstMatch(sanitized);
    if (plainMatch != null) {
      return GitHubRepoTarget(
        owner: plainMatch.group(1)!,
        repo: plainMatch.group(2)!,
      );
    }

    return null;
  }

  Future<List<GitHubFileItem>> listAllFiles(String owner, String repo) async {
    try {
      final url = 'https://api.github.com/repos/$owner/$repo/git/trees/HEAD?recursive=1';
      final response = await _dio.get(
        url,
        options: Options(headers: _getHeaders()),
      );

      if (response.statusCode == 200 && response.data != null) {
        final tree = response.data['tree'] as List<dynamic>? ?? [];
        return tree
            .map((item) => GitHubFileItem(
                  path: item['path'] as String,
                  type: item['type'] as String,
                  size: item['size'] as int?,
                  url: item['url'] as String?,
                ))
            .where((item) => item.type == 'blob')
            .toList();
      }
      throw Exception('GitHub API returned status code ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Repository not found or is private. Verify the repository is public and the URL is correct.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('GitHub API public rate limit reached. Please wait a brief moment before re-scanning.');
      }
      throw Exception('GitHub Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to list repository files: $e');
    }
  }

  Future<String> fetchFileContent(String owner, String repo, String path) async {
    // Delay 100ms between calls to avoid hitting rate limits
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Primary: GitHub Contents API with raw media type (authenticated & branch-agnostic)
      final apiUrl = 'https://api.github.com/repos/$owner/$repo/contents/$path';
      final response = await _dio.get(
        apiUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            ..._getHeaders(),
            'Accept': 'application/vnd.github.v3.raw',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data.toString();
      }
    } catch (_) {
      // Secondary fallback: Try raw.githubusercontent.com on main and master
      for (final branch in ['main', 'master', 'HEAD']) {
        try {
          final rawUrl = 'https://raw.githubusercontent.com/$owner/$repo/$branch/$path';
          final rawResponse = await _dio.get(
            rawUrl,
            options: Options(
              responseType: ResponseType.plain,
              headers: _getHeaders(),
            ),
          );
          if (rawResponse.statusCode == 200 && rawResponse.data != null) {
            return rawResponse.data.toString();
          }
        } catch (_) {}
      }
    }

    return '';
  }
}
