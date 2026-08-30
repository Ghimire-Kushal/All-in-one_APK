import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/feature_card.dart';
import 'date_converter_screen.dart';
import 'stopwatch_screen.dart';
import 'timer_screen.dart';
import 'age_calculator_screen.dart';
import '../unit_converter/unit_converter_screen.dart';
import '../calculator/calculator_screen.dart';

class UtilitiesHubScreen extends StatelessWidget {
  const UtilitiesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(
        'Date Converter',
        'AD ↔ BS conversion',
        Icons.calendar_month_rounded,
        AppColors.dateConverter,
        const DateConverterScreen(),
      ),
      _Item(
        'Stopwatch',
        'Measure elapsed time',
        Icons.timer_rounded,
        AppColors.stopwatch,
        const StopwatchScreen(),
      ),
      _Item(
        'Timer',
        'Countdown timer',
        Icons.hourglass_bottom_rounded,
        AppColors.timer,
        const TimerScreen(),
      ),
      _Item(
        'Age Calculator',
        'Calculate exact age',
        Icons.cake_rounded,
        AppColors.ageCal,
        const AgeCalculatorScreen(),
      ),
      _Item(
        'Unit Converter',
        'Length, weight, temperature & more',
        Icons.swap_horiz_rounded,
        AppColors.unitConverter,
        const UnitConverterScreen(),
      ),
      _Item(
        'Calculator',
        'Calculator with saved totals & base converter',
        Icons.calculate_rounded,
        AppColors.calculator,
        const CalculatorScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Utilities',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FeatureCard(
            label: items[i].label,
            icon: items[i].icon,
            color: items[i].color,
            subtitle: items[i].subtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => items[i].screen),
            ),
            compact: true,
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String label, subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  _Item(this.label, this.subtitle, this.icon, this.color, this.screen);
}
