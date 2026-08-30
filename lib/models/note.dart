class Note {
  final String id;
  String title;
  String content;
  bool isPinned;
  final DateTime createdAt;
  DateTime updatedAt;
  String colorHex;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex = '#FFFFFF',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'isPinned': isPinned,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'colorHex': colorHex,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    isPinned: json['isPinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    colorHex: json['colorHex'] as String? ?? '#FFFFFF',
  );
}
