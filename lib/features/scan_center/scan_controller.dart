import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security_engine/security_engine.dart';
import '../../data/models/scan_result.dart';
import '../../data/repositories/scan_repository.dart';
import '../dashboard/dashboard_controller.dart';
import '../settings/settings_controller.dart';

enum ScanStateStatus { idle, scanning, complete, error }

class ScanState {
  final ScanStateStatus status;
  final double progress;
  final String currentModule;
  final String currentAction;
  final List<String> logs;
  final ScanResult? result;
  final String? errorMessage;

  ScanState({
    this.status = ScanStateStatus.idle,
    this.progress = 0.0,
    this.currentModule = 'Security Kernel',
    this.currentAction = 'Idle',
    this.logs = const [],
    this.result,
    this.errorMessage,
  });

  ScanState copyWith({
    ScanStateStatus? status,
    double? progress,
    String? currentModule,
    String? currentAction,
    List<String>? logs,
    ScanResult? result,
    String? errorMessage,
  }) {
    return ScanState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentModule: currentModule ?? this.currentModule,
      currentAction: currentAction ?? this.currentAction,
      logs: logs ?? this.logs,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>((ref) {
  final repository = ref.watch(scanRepositoryProvider);
  return ScanController(repository, ref);
});

class ScanController extends StateNotifier<ScanState> {
  final ScanRepository _repository;
  final Ref _ref;
  final SecurityEngine _engine = SecurityEngine();

  ScanController(this._repository, this._ref) : super(ScanState());

  void reset() {
    state = ScanState();
  }

  Future<void> scanGitHubRepo(String repoUrl) async {
    if (repoUrl.trim().isEmpty) {
      state = state.copyWith(
        status: ScanStateStatus.error,
        errorMessage: 'Repository URL cannot be empty.',
      );
      return;
    }

    state = ScanState(
      status: ScanStateStatus.scanning,
      progress: 0.02,
      currentModule: 'GitHub Ingest Engine',
      currentAction: 'Contacting GitHub API...',
      logs: ['[${DateTime.now().toIso8601String().substring(11, 19)}] Initiating GitHub scan for $repoUrl'],
    );

    try {
      final settings = _ref.read(settingsControllerProvider);
      final result = await _engine.runScanOnGitHubRepo(
        repoUrl: repoUrl,
        settings: settings,
        onProgress: ({
          required double progress,
          required String currentModule,
          required String currentAction,
          required String logLine,
          String? logType,
        }) {
          state = state.copyWith(
            progress: progress,
            currentModule: currentModule,
            currentAction: currentAction,
            logs: [...state.logs, logLine],
          );
        },
      );

      _repository.addScanResult(result);
      _ref.read(dashboardControllerProvider.notifier).refresh();

      state = state.copyWith(
        status: ScanStateStatus.complete,
        progress: 1.0,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStateStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> pickAndScanFiles() async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        return;
      }

      state = ScanState(
        status: ScanStateStatus.scanning,
        progress: 0.05,
        currentModule: 'File Ingest System',
        currentAction: 'Parsing uploaded file assets...',
        logs: ['[${DateTime.now().toIso8601String().substring(11, 19)}] Ingesting local files for inspection...'],
      );

      final Map<String, String> fileContents = {};
      String projectName = 'Uploaded-Project';

      for (final file in pickerResult.files) {
        final name = file.name;
        final bytes = file.bytes;
        if (bytes == null) continue;

        if (name.toLowerCase().endsWith('.zip')) {
          // Unzip files
          try {
            final archive = ZipDecoder().decodeBytes(bytes);
            projectName = name.replaceAll('.zip', '');
            for (final archFile in archive) {
              if (archFile.isFile) {
                try {
                  final data = archFile.content as List<int>;
                  fileContents[archFile.name] = utf8.decode(data, allowMalformed: true);
                } catch (_) {}
              }
            }
          } catch (_) {}
        } else {
          try {
            fileContents[name] = utf8.decode(bytes, allowMalformed: true);
          } catch (_) {
            fileContents[name] = String.fromCharCodes(bytes);
          }
        }
      }

      if (fileContents.isEmpty) {
        throw Exception('Could not extract readable text files from uploaded payload.');
      }

      final settings = _ref.read(settingsControllerProvider);
      final result = await _engine.runScanOnFiles(
        projectName: projectName,
        targetPathOrUrl: 'Uploaded (${fileContents.length} files)',
        fileContents: fileContents,
        settings: settings,
        onProgress: ({
          required double progress,
          required String currentModule,
          required String currentAction,
          required String logLine,
          String? logType,
        }) {
          state = state.copyWith(
            progress: progress,
            currentModule: currentModule,
            currentAction: currentAction,
            logs: [...state.logs, logLine],
          );
        },
      );

      _repository.addScanResult(result);
      _ref.read(dashboardControllerProvider.notifier).refresh();

      state = state.copyWith(
        status: ScanStateStatus.complete,
        progress: 1.0,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: ScanStateStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
