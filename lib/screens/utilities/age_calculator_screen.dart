import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgeCalculatorScreen extends StatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime? _dob;
  DateTime _targetDate = DateTime.now();

  Map<String, int>? _age;
  int? _totalDays;
  int? _totalMonths;
  String? _nextBirthday;

  void _calculate() {
    if (_dob == null) return;
    final dob = _dob!;
    final target = _targetDate;

    if (dob.isAfter(target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth cannot be in the future')),
      );
      return;
    }

    int years = target.year - dob.year;
    int months = target.month - dob.month;
    int days = target.day - dob.day;

    if (days < 0) {
      months--;
      final prevMonth = DateTime(target.year, target.month - 1, dob.day);
      days = target.difference(prevMonth).inDays;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final totalDays = target.difference(dob).inDays;
    final totalMonths = years * 12 + months;

    // Next birthday
    DateTime nextBd = DateTime(target.year, dob.month, dob.day);
    if (!nextBd.isAfter(target)) {
      nextBd = DateTime(target.year + 1, dob.month, dob.day);
    }
    final daysToNext = nextBd.difference(target).inDays;

    setState(() {
      _age = {'years': years, 'months': months, 'days': days};
      _totalDays = totalDays;
      _totalMonths = totalMonths;
      _nextBirthday =
          '$daysToNext days until next birthday (${DateFormat('MMM d, yyyy').format(nextBd)})';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Age Calculator',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date of Birth',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _dateTile(
              _dob == null
                  ? 'Select date of birth'
                  : DateFormat('MMMM d, yyyy').format(_dob!),
              Icons.cake_rounded,
              cs.primary,
              () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(2000, 1, 1),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dob = picked);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Calculate Age At',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _dateTile(
              DateFormat('MMMM d, yyyy').format(_targetDate),
              Icons.today_rounded,
              cs.secondary,
              () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calculate Age'),
              ),
            ),
            if (_age != null) ...[
              const SizedBox(height: 32),
              _bigResult(context, cs),
              const SizedBox(height: 16),
              _statsRow(context, cs),
              const SizedBox(height: 16),
              if (_nextBirthday != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text('🎂', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nextBirthday!,
                          style: TextStyle(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bigResult(BuildContext context, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            '${_age!['years']} years, ${_age!['months']} months, ${_age!['days']} days',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your age',
            style: TextStyle(
              fontSize: 12,
              color: cs.onPrimaryContainer.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '$_totalDays',
            'Total days',
            cs.secondaryContainer,
            cs.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            '$_totalMonths',
            'Total months',
            cs.tertiaryContainer,
            cs.onTertiaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String val, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
