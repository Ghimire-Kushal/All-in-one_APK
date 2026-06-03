class TimetableEntry {
  final String id;
  String title;
  String? notes;
  int categoryIndex; // 0–7, maps to _kCategories
  List<int> days; // 1=Mon…7=Sun. [1,2,3,4,5,6,7] = every day
  int startHour;
  int startMinute;
  int? endHour;
  int? endMinute;
  String colorHex;
  bool notifyEnabled;
  int notifyMinutesBefore; // 0 = at time, 5/10/15/30 = before

  TimetableEntry({
    required this.id,
    required this.title,
    this.notes,
    this.categoryIndex = 7,
    required this.days,
    required this.startHour,
    required this.startMinute,
    this.endHour,
    this.endMinute,
    this.colorHex = 'FF42A5F5',
    this.notifyEnabled = true,
    this.notifyMinutesBefore = 0,
  });

  bool get isEveryDay => days.length == 7;

  int get startMinutes => startHour * 60 + startMinute;

  String get startLabel => _fmt(startHour, startMinute);
  String? get endLabel =>
      (endHour != null && endMinute != null) ? _fmt(endHour!, endMinute!) : null;

  String _fmt(int h, int m) {
    final hour = h % 12 == 0 ? 12 : h % 12;
    final min = m.toString().padLeft(2, '0');
    return '$hour:$min ${h < 12 ? 'AM' : 'PM'}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'categoryIndex': categoryIndex,
        'days': days,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'colorHex': colorHex,
        'notifyEnabled': notifyEnabled,
        'notifyMinutesBefore': notifyMinutesBefore,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        id: j['id'] as String,
        title: j['title'] as String,
        notes: j['notes'] as String?,
        categoryIndex: j['categoryIndex'] as int? ?? 7,
        days: (j['days'] as List?)?.map((e) => e as int).toList() ??
            [1, 2, 3, 4, 5, 6, 7],
        startHour: j['startHour'] as int,
        startMinute: j['startMinute'] as int,
        endHour: j['endHour'] as int?,
        endMinute: j['endMinute'] as int?,
        colorHex: j['colorHex'] as String? ?? 'FF42A5F5',
        notifyEnabled: j['notifyEnabled'] as bool? ?? true,
        notifyMinutesBefore: j['notifyMinutesBefore'] as int? ?? 0,
      );

  TimetableEntry copyWith({
    String? title,
    String? notes,
    int? categoryIndex,
    List<int>? days,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? colorHex,
    bool? notifyEnabled,
    int? notifyMinutesBefore,
  }) =>
      TimetableEntry(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        categoryIndex: categoryIndex ?? this.categoryIndex,
        days: days ?? List.from(this.days),
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
        colorHex: colorHex ?? this.colorHex,
        notifyEnabled: notifyEnabled ?? this.notifyEnabled,
        notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
      );
}
