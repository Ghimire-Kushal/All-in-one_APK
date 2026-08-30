import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with WidgetsBindingObserver {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];
  bool _appIsResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  String get _elapsed => _format(_stopwatch.elapsed);

  String _format(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(
      2,
      '0',
    );
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$min:$sec.$ms';
  }

  void _start() {
    _stopwatch.start();
    _ensureRefreshTimer();
  }

  void _ensureRefreshTimer() {
    if (!_appIsResumed || !_stopwatch.isRunning || _timer?.isActive == true) {
      return;
    }
    // A 20fps refresh keeps the display smooth while cutting rebuilds by 40%
    // compared with the previous 30ms timer.
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && _appIsResumed && _stopwatch.isRunning) setState(() {});
    });
  }

  void _pause() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _reset() {
    _stopwatch.reset();
    _timer?.cancel();
    setState(() => _laps.clear());
  }

  void _lap() {
    setState(() => _laps.insert(0, 'Lap ${_laps.length + 1}  $_elapsed'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsResumed = state == AppLifecycleState.resumed;
    if (_appIsResumed) {
      _ensureRefreshTimer();
      if (mounted) setState(() {});
    } else {
      // Stopwatch continues to measure elapsed time without waking the UI
      // while the app is backgrounded.
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = _stopwatch.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stopwatch',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _elapsed,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(
                Icons.flag_rounded,
                cs.secondary,
                running ? _lap : null,
              ),
              const SizedBox(width: 20),
              _circleBtn(
                running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                cs.primary,
                running ? _pause : _start,
                large: true,
              ),
              const SizedBox(width: 20),
              _circleBtn(
                Icons.refresh_rounded,
                cs.error,
                !running && _stopwatch.elapsed > Duration.zero ? _reset : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_laps.isNotEmpty) ...[
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _laps.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      '${_laps.length - i}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    _laps[i],
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleBtn(
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool large = false,
  }) {
    final size = large ? 68.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? color : color.withValues(alpha: 0.3),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: Colors.white, size: large ? 30 : 22),
      ),
    );
  }
}
