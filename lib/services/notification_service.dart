import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'task_reminders';
  static const _channelName = 'Task Reminders';

  Future<void> init() async {
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Explicitly create channels so sound/vibration settings are always correct
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Scheduled reminders for your to-do tasks',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'timetable_reminders',
        'Class Reminders',
        description: 'Alerts before your classes start',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder({
    required int id,
    required String taskTitle,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    // Build TZDateTime directly in the device's local timezone so the alarm
    // fires at the exact wall-clock time the user selected, regardless of
    // what timezone the device is in.
    final tzTime = tz.TZDateTime.local(
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    await _plugin.zonedSchedule(
      id,
      'Task Reminder',
      taskTitle,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Scheduled reminders for your to-do tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(taskTitle),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelTimetableReminder(int id) => _plugin.cancel(id);

  // Deterministic int IDs, within int32 safe range
  int idFromTaskId(String taskId) => taskId.hashCode.abs() % 2147483647;
  // Offset by 1B to avoid collision with task notification IDs
  int idFromTimetableId(String id) =>
      (id.hashCode.abs() % 1000000000) + 1000000000;

  /// Schedule a recurring weekly notification that fires [notifyMinutesBefore]
  /// minutes before [classHour]:[classMinute] every [classWeekday].
  Future<void> scheduleTimetableReminder({
    required int id,
    required String subject,
    required int classWeekday, // 1=Mon … 7=Sun
    required int classHour,
    required int classMinute,
    required int notifyMinutesBefore,
  }) async {
    final fireTime = _nextWeekdayFireTime(
      classWeekday,
      classHour,
      classMinute,
      notifyMinutesBefore,
    );

    await _plugin.zonedSchedule(
      id,
      'Class starting soon',
      '$subject in $notifyMinutesBefore min',
      fireTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'timetable_reminders',
          'Class Reminders',
          channelDescription: 'Alerts before your classes start',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(
            '$subject starts in $notifyMinutesBefore minutes',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Finds the next wall-clock DateTime that is on [classWeekday] at
  /// ([classHour]:[classMinute] − [minutesBefore]), then wraps it as a
  /// local TZDateTime so [zonedSchedule] fires at the correct time every week.
  tz.TZDateTime _nextWeekdayFireTime(
    int classWeekday,
    int classHour,
    int classMinute,
    int minutesBefore,
  ) {
    final now = DateTime.now();

    // Subtract the offset to get the actual fire time-of-day
    final classTotalMin = classHour * 60 + classMinute;
    final fireTotalMin = classTotalMin - minutesBefore;

    // Handle crossing midnight (e.g. class at 00:05, notify 15 min before)
    final int fireHour;
    final int fireMinute;
    final int fireWeekday;
    if (fireTotalMin < 0) {
      final adjusted = 24 * 60 + fireTotalMin;
      fireHour = adjusted ~/ 60;
      fireMinute = adjusted % 60;
      fireWeekday = classWeekday == 1 ? 7 : classWeekday - 1;
    } else {
      fireHour = fireTotalMin ~/ 60;
      fireMinute = fireTotalMin % 60;
      fireWeekday = classWeekday;
    }

    // Start from today at the fire time, then advance until weekday matches
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      fireHour,
      fireMinute,
    );
    while (candidate.weekday != fireWeekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return tz.TZDateTime.local(
      candidate.year,
      candidate.month,
      candidate.day,
      fireHour,
      fireMinute,
    );
  }
}
