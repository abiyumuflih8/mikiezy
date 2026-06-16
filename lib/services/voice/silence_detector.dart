import 'dart:async';

class SilenceDetector {
  SilenceDetector({required this.timeout});

  Duration timeout;
  Timer? _timer;

  bool get isRunning => _timer?.isActive ?? false;

  void start(void Function() onTimeout) {
    stop();
    _timer = Timer(timeout, onTimeout);
  }

  void reset(void Function() onTimeout) {
    start(onTimeout);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
