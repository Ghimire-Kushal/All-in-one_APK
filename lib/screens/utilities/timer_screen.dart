import 'dart:async';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _totalSeconds = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _running = false;
  bool _finished = false;

  int _hInput = 0, _mInput = 5, _sInput = 0;

  double get _progress =>
      _totalSeconds == 0 ? 0 : (_totalSeconds - _remaining) / _totalSeconds;

  String get _display {
    final h = _remaining ~/ 3600;
    final m = (_remaining % 3600) ~/ 60;
    final s = _remaining % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _start() {
    if (_remaining == 0) {
      _totalSeconds = _hInput * 3600 + _mInput * 60 + _sInput;
      _remaining = _totalSeconds;
    }
    if (_remaining == 0) return;
    setState(() {
      _running = true;
      _finished = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _running = false;
          _finished = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = 0;
      _totalSeconds = 0;
      _finished = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPicking = !_running && _remaining == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            if (isPicking)
              _buildPicker(context, cs)
            else
              _buildDisplay(context, cs),
            const SizedBox(height: 40),
            _buildControls(context, cs, isPicking),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Text(
            'Set Timer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _wheel('Hours', 23, _hInput, (v) => setState(() => _hInput = v)),
              _colon(),
              _wheel('Min', 59, _mInput, (v) => setState(() => _mInput = v)),
              _colon(),
              _wheel('Sec', 59, _sInput, (v) => setState(() => _sInput = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wheel(String label, int maxVal, int value, Function(int) onChange) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 70,
          height: 120,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: value),
            onSelectedItemChanged: onChange,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxVal + 1,
              builder: (context, i) => Center(
                child: Text(
                  i.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: i == value
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colon() => const Padding(
    padding: EdgeInsets.only(top: 20),
    child: Text(
      ':',
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    ),
  );

  Widget _buildDisplay(BuildContext context, ColorScheme cs) {
    final color = _finished ? cs.error : cs.primary;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 10,
            backgroundColor: cs.primaryContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        Column(
          children: [
            Text(
              _finished ? '🎉 Done!' : _display,
              style: TextStyle(
                fontSize: _finished ? 28 : 42,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (!_finished)
              Text(
                'remaining',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, ColorScheme cs, bool isPicking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isPicking) _btn(Icons.refresh_rounded, cs.error, _reset),
        const SizedBox(width: 20),
        _btn(
          _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          cs.primary,
          isPicking
              ? (_hInput + _mInput + _sInput > 0 ? _start : null)
              : (_running ? _pause : _start),
          large: true,
        ),
        const SizedBox(width: 20),
        if (!isPicking && !_running)
          _btn(Icons.add_rounded, cs.secondary, () {
            setState(() {
              _remaining = (_remaining + 60).clamp(0, 3600 * 24);
              _totalSeconds = _remaining;
            });
          })
        else
          const SizedBox(width: 52),
      ],
    );
  }

  Widget _btn(
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool large = false,
  }) {
    final size = large ? 68.0 : 52.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? color : color.withValues(alpha: 0.3),
        ),
        child: Icon(icon, color: Colors.white, size: large ? 30 : 22),
      ),
    );
  }
}
