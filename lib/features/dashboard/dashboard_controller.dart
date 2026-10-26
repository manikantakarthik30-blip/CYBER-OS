import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/scan_result.dart';
import '../../data/repositories/scan_repository.dart';

final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repo = ref.watch(scanRepositoryProvider);
  return DashboardController(repo);
});

class DashboardState {
  final ScanResult? latestScan;
  final List<ScanResult> recentScans;
  final bool isLoading;

  DashboardState({
    this.latestScan,
    this.recentScans = const [],
    this.isLoading = false,
  });

  DashboardState copyWith({
    ScanResult? latestScan,
    List<ScanResult>? recentScans,
    bool? isLoading,
  }) {
    return DashboardState(
      latestScan: latestScan ?? this.latestScan,
      recentScans: recentScans ?? this.recentScans,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final ScanRepository _repository;

  DashboardController(this._repository)
      : super(DashboardState(
          latestScan: _repository.getLatestScan(),
          recentScans: _repository.getHistory(),
        ));

  void refresh() {
    state = state.copyWith(
      latestScan: _repository.getLatestScan(),
      recentScans: _repository.getHistory(),
    );
  }
}
