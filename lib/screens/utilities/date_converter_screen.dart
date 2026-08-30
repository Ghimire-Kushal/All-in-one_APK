import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:intl/intl.dart';

class DateConverterScreen extends StatefulWidget {
  const DateConverterScreen({super.key});

  @override
  State<DateConverterScreen> createState() => _DateConverterScreenState();
}

class _DateConverterScreenState extends State<DateConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // AD → BS
  DateTime _adDate = DateTime.now();
  NepaliDateTime? _bsResult;

  // BS → AD
  int _bsYear = 2081;
  int _bsMonth = 1;
  int _bsDay = 1;
  DateTime? _adResult;

  // Current time display
  NepaliDateTime get _currentNepali => DateTime.now().toNepaliDateTime();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _convertAdToBs();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _convertAdToBs() {
    setState(() => _bsResult = _adDate.toNepaliDateTime());
  }

  void _convertBsToAd() {
    try {
      final bs = NepaliDateTime(_bsYear, _bsMonth, _bsDay);
      setState(() => _adResult = bs.toDateTime());
    } catch (e) {
      setState(() => _adResult = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Date Converter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'AD → BS'),
            Tab(text: 'BS → AD'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildAdToBs(context, cs),
          _buildBsToAd(context, cs),
          _buildToday(context, cs),
        ],
      ),
    );
  }

  Widget _buildAdToBs(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select English Date (AD)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _datePicker(
            DateFormat('MMMM d, yyyy').format(_adDate),
            Icons.calendar_today_rounded,
            cs.primary,
            () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _adDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2090),
              );
              if (picked != null) {
                setState(() => _adDate = picked);
                _convertAdToBs();
              }
            },
          ),
          const SizedBox(height: 32),
          if (_bsResult != null) ...[
            const Text(
              'Nepali Date (BS)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _resultCard(
              '${_bsResult!.year} - ${_bsResult!.month.toString().padLeft(2, '0')} - ${_bsResult!.day.toString().padLeft(2, '0')}',
              'Bikram Sambat',
              cs.primaryContainer,
              cs.onPrimaryContainer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBsToAd(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Nepali Date (BS)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _numField(
                  'Year',
                  _bsYear,
                  (v) => _bsYear = v,
                  2070,
                  2090,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField('Month', _bsMonth, (v) => _bsMonth = v, 1, 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField('Day', _bsDay, (v) => _bsDay = v, 1, 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _convertBsToAd,
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Convert'),
            ),
          ),
          const SizedBox(height: 32),
          if (_adResult != null) ...[
            const Text(
              'English Date (AD)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _resultCard(
              DateFormat('MMMM d, yyyy').format(_adResult!),
              'Gregorian Calendar',
              cs.secondaryContainer,
              cs.onSecondaryContainer,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToday(BuildContext context, ColorScheme cs) {
    final now = DateTime.now();
    final nepali = _currentNepali;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Date',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _resultCard(
            DateFormat('EEEE, MMMM d, yyyy').format(now),
            'English Date (AD)',
            cs.primaryContainer,
            cs.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          _resultCard(
            '${nepali.year} / ${nepali.month} / ${nepali.day}',
            'Nepali Date (BS)',
            cs.tertiaryContainer,
            cs.onTertiaryContainer,
          ),
          const SizedBox(height: 16),
          _resultCard(
            DateFormat('h:mm:ss a').format(now),
            'Current Time',
            cs.secondaryContainer,
            cs.onSecondaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _datePicker(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String main, String sub, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            main,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _numField(
    String label,
    int value,
    ValueChanged<int> onChanged,
    int min,
    int max,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: '$value',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null && parsed >= min && parsed <= max) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}
