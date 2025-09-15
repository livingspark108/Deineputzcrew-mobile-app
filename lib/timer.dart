// work_timer_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class WorkTimerService {
  static final WorkTimerService _instance = WorkTimerService._internal();
  factory WorkTimerService() => _instance;
  WorkTimerService._internal();

  DateTime? _punchInTime;
  Duration _pausedDuration = Duration.zero;
  bool _onBreak = false;
  Timer? _timer;

  Duration workingDuration = Duration.zero;

  Future<void> start({bool isResuming = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isResuming) {
      _punchInTime = DateTime.now();
      _pausedDuration = Duration.zero;
      await prefs.setString('punchInStartTime', _punchInTime!.toIso8601String());
      await prefs.setInt('pausedDuration', 0);
      await prefs.setBool('onBreak', false);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_onBreak && _punchInTime != null) {
        workingDuration = DateTime.now().difference(_punchInTime!) - _pausedDuration;
        print("Working Duration: $workingDuration");
      }
    });
  }

  void stop() {
    _timer?.cancel();
  }
}
