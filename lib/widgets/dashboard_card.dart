import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/todo_provider.dart';

// Get a free API key at https://openweathermap.org/api
const _kWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';

class DashboardCard extends StatefulWidget {
  const DashboardCard({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  int? _temp;
  int? _feelsLike;
  int? _humidity;
  String? _condition;
  String? _description;
  String? _city;
  bool _weatherLoading = true;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();

    if (widget.isActive) _startClock();

    _fetchWeather();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      setState(() => _now = DateTime.now());
      _startClock();
    } else {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.isActive) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _fetchWeather() async {
    try {
      // A placeholder key means weather is deliberately disabled. Do not wake
      // the location hardware or ask for permission in that configuration.
      if (_kWeatherApiKey == 'YOUR_OPENWEATHER_API_KEY') {
        _stopLoading();
        return;
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        _stopLoading();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _stopLoading();
        return;
      }

      // Reuse a cached location whenever possible to avoid powering up GPS.
      final pos =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          ).timeout(const Duration(seconds: 15));

      final lat = pos.latitude;
      final lon = pos.longitude;

      // One Call API 3.0 + Geocoding API in parallel
      final results = await Future.wait([
        http
            .get(
              Uri.parse(
                'https://api.openweathermap.org/data/3.0/onecall'
                '?lat=$lat&lon=$lon&exclude=minutely,hourly,daily,alerts'
                '&appid=$_kWeatherApiKey&units=metric',
              ),
            )
            .timeout(const Duration(seconds: 10)),
        http
            .get(
              Uri.parse(
                'https://api.openweathermap.org/geo/1.0/reverse'
                '?lat=$lat&lon=$lon&limit=1&appid=$_kWeatherApiKey',
              ),
            )
            .timeout(const Duration(seconds: 10)),
      ]);

      if (!mounted) return;

      final weatherRes = results[0];
      final geoRes = results[1];

      if (weatherRes.statusCode == 200) {
        final w = jsonDecode(weatherRes.body) as Map<String, dynamic>;
        final current = w['current'] as Map<String, dynamic>;

        String? cityName;
        if (geoRes.statusCode == 200) {
          final geo = jsonDecode(geoRes.body) as List<dynamic>;
          if (geo.isNotEmpty) cityName = geo[0]['name'] as String?;
        }

        setState(() {
          _temp = (current['temp'] as num).round();
          _feelsLike = (current['feels_like'] as num).round();
          _humidity = current['humidity'] as int;
          _condition = (current['weather'] as List).first['main'] as String;
          _description =
              (current['weather'] as List).first['description'] as String;
          _city = cityName;
          _weatherLoading = false;
        });
      } else {
        _stopLoading();
      }
    } catch (_) {
      if (mounted) _stopLoading();
    }
  }

  void _stopLoading() {
    if (mounted) setState(() => _weatherLoading = false);
  }

  String _greeting() {
    final h = _now.hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good evening';
  }

  IconData _greetingIcon() {
    final h = _now.hour;
    if (h < 5 || h >= 21) return Icons.nights_stay_rounded;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.light_mode_rounded;
    return Icons.wb_twilight_rounded;
  }

  ({IconData icon, Color color}) get _weatherIconData => switch (_condition) {
    'Clear' => (icon: Icons.wb_sunny_rounded, color: const Color(0xFFFFB300)),
    'Clouds' => (icon: Icons.cloud_rounded, color: const Color(0xFF90A4AE)),
    'Rain' => (icon: Icons.water_drop_rounded, color: const Color(0xFF42A5F5)),
    'Drizzle' => (icon: Icons.grain_rounded, color: const Color(0xFF64B5F6)),
    'Thunderstorm' => (
      icon: Icons.thunderstorm_rounded,
      color: const Color(0xFFCE93D8),
    ),
    'Snow' => (icon: Icons.ac_unit_rounded, color: const Color(0xFFB0BEC5)),
    'Mist' || 'Fog' || 'Haze' || 'Smoke' => (
      icon: Icons.cloud_queue_rounded,
      color: const Color(0xFFB0BEC5),
    ),
    _ => (icon: Icons.wb_cloudy_rounded, color: const Color(0xFF90A4AE)),
  };

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>().notes.length;
    final tasks = context.watch<TodoProvider>().pending.length;
    final todayExpense = context.watch<ExpenseProvider>().totalToday;
    final userName = context.watch<AppAuthProvider>().displayName;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nepaliNow = NepaliDateTime.now();
    final nepaliDate = NepaliDateFormat(
      'd MMMM y',
      Language.nepali,
    ).format(nepaliNow);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1F3E), const Color(0xFF0E1428)]
                    : [const Color(0xFF3F51B5), const Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF3F51B5,
                  ).withValues(alpha: isDark ? 0.18 : 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _TopSection(
                  now: _now,
                  nepaliDate: nepaliDate,
                  greeting: _greeting(),
                  greetingIcon: _greetingIcon(),
                  userName: userName,
                  weatherLoading: _weatherLoading,
                  temp: _temp,
                  feelsLike: _feelsLike,
                  humidity: _humidity,
                  condition: _condition,
                  description: _description,
                  city: _city,
                  weatherIconData: _weatherIconData,
                ),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                _StatsRow(
                  notes: notes,
                  tasks: tasks,
                  todayExpense: todayExpense,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top section (time / date / weather) ──────────────────────────────────────

class _TopSection extends StatelessWidget {
  final DateTime now;
  final String nepaliDate;
  final String greeting;
  final IconData greetingIcon;
  final String userName;
  final bool weatherLoading;
  final int? temp;
  final int? feelsLike;
  final int? humidity;
  final String? condition;
  final String? description;
  final String? city;
  final ({IconData icon, Color color}) weatherIconData;

  const _TopSection({
    required this.now,
    required this.nepaliDate,
    required this.greeting,
    required this.greetingIcon,
    required this.userName,
    required this.weatherLoading,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.city,
    required this.weatherIconData,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _leftColumn()),
          const SizedBox(width: 12),
          _rightWeather(),
        ],
      ),
    );
  }

  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting with name
        Row(
          children: [
            Icon(greetingIcon, color: Colors.white54, size: 13),
            const SizedBox(width: 5),
            Text(
              '$greeting, $userName',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Live clock
        Text(
          DateFormat('h:mm:ss a').format(now),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 5),

        // English date
        Text(
          DateFormat('EEEE, MMM d, y').format(now),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),

        // Nepali date
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            nepaliDate,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rightWeather() {
    if (weatherLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white30,
          ),
        ),
      );
    }

    if (temp == null) return const SizedBox.shrink();

    final displayDesc = description != null
        ? '${description![0].toUpperCase()}${description!.substring(1)}'
        : condition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Weather icon circle
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: weatherIconData.color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            weatherIconData.icon,
            color: weatherIconData.color,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),

        // Temperature
        Text(
          '$temp°C',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),

        // Description (e.g. "Few clouds")
        if (displayDesc != null)
          Text(
            displayDesc,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),

        // Feels like + humidity
        if (feelsLike != null || humidity != null) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (feelsLike != null) ...[
                const Icon(
                  Icons.thermostat_rounded,
                  color: Colors.white38,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  '$feelsLike°',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
              if (feelsLike != null && humidity != null)
                const SizedBox(width: 6),
              if (humidity != null) ...[
                const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white38,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Text(
                  '$humidity%',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ],
          ),
        ],

        // City with location pin
        if (city != null) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white38,
                size: 11,
              ),
              const SizedBox(width: 2),
              Text(
                city!,
                style: const TextStyle(color: Colors.white38, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int notes;
  final int tasks;
  final double todayExpense;

  const _StatsRow({
    required this.notes,
    required this.tasks,
    required this.todayExpense,
  });

  @override
  Widget build(BuildContext context) {
    final expenseStr = todayExpense >= 1000
        ? 'Rs ${(todayExpense / 1000).toStringAsFixed(1)}k'
        : 'Rs ${todayExpense.toInt()}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.sticky_note_2_rounded,
              value: '$notes',
              label: 'Notes',
              color: const Color(0xFFFFA726),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.checklist_rounded,
              value: '$tasks',
              label: 'Pending',
              color: const Color(0xFF66BB6A),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.account_balance_wallet_rounded,
              value: expenseStr,
              label: 'Today',
              color: const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.15),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 9.5),
        ),
      ],
    );
  }
}
