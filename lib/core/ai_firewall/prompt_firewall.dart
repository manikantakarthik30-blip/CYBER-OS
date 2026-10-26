import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../data/models/vulnerability.dart';
import '../../services/gemini_service.dart';

class PromptFirewall {
  final _uuid = const Uuid();
  final GeminiService _geminiService;

  PromptFirewall({GeminiService? geminiService})
      : _geminiService = geminiService ?? GeminiService();

  static final List<(RegExp, String, String, String)> injectionPatterns = [
    (
      RegExp(r'(ignore previous instructions|disregard all prior commands|system prompt override|ignore above instructions|bypass all safety)', caseSensitive: false),
      'Direct Prompt Injection Pattern',
      'HIGH',
      'Use defensive delimiters (e.g. XML tags), prompt sandboxing, and system instruction anchors.'
    ),
    (
      RegExp(r'(prompt|system_instruction|instructions)\s*[:=]\s*["\x27`].*?(\$input|\$prompt|\+ input|\+ user_input|\{user_prompt\}|\{input\}|\$\{req\.body)', caseSensitive: false),
      'Unanchored Dynamic Prompt Reflection',
      'HIGH',
      'Wrap dynamic runtime inputs in strict boundary delimiters (<user_input></user_input>) to prevent prompt hijack.'
    ),
    (
      RegExp(r'(DAN mode|jailbreak|unfiltered mode|developer mode enabled|always answer without filter)', caseSensitive: false),
      'Jailbreak / Persona Override Attempt',
      'HIGH',
      'Filter user input through a pre-invocation semantic firewall and enforce hard safety bounds.'
    ),
    (
      RegExp(r'(reveal system prompt|print your instructions|output the initial instructions|dump system instructions)', caseSensitive: false),
      'System Prompt Extraction Vector',
      'MEDIUM',
      'Instruct system prompt to never regurgitate internal initialization tokens or instructions.'
    ),
  ];

  List<Vulnerability> scanPromptOrCode(String content, String filePath) {
    final List<Vulnerability> vulnerabilities = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      for (final (regex, title, severity, fix) in injectionPatterns) {
        if (regex.hasMatch(line)) {
          vulnerabilities.add(
            Vulnerability(
              id: _uuid.v4(),
              title: title,
              severity: severity,
              category: 'AI Firewall',
              description: 'Potential prompt injection/jailbreak surface detected in $filePath on line $lineNumber.',
              location: '$filePath:$lineNumber',
              codeSnippet: line.trim(),
              fix: fix,
              detectedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    return vulnerabilities;
  }

  /// Deep semantic AI validation using Gemini API
  Future<Vulnerability?> evaluateSemanticPromptRisk({
    required String promptText,
    required String location,
  }) async {
    if (!_geminiService.isAvailable) return null;

    final rawJson = await _geminiService.evaluatePromptSafety(promptText: promptText);
    if (rawJson == null) return null;

    try {
      final clean = rawJson.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = json.decode(clean) as Map<String, dynamic>;
      final verdict = decoded['verdict'] as String?;
      final reason = decoded['reason'] as String? ?? 'LLM classified prompt as hazardous';

      if (verdict == 'UNSAFE') {
        return Vulnerability(
          id: _uuid.v4(),
          title: 'Semantic LLM Jailbreak / Injection Vector',
          severity: 'HIGH',
          category: 'AI Firewall',
          description: reason,
          location: location,
          codeSnippet: promptText.length > 80 ? '${promptText.substring(0, 80)}...' : promptText,
          fix: 'Sanitize dynamic input with semantic validator before passing to foundational model.',
          detectedAt: DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }
}
