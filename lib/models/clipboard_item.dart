class ClipboardItem {
  final String id;
  String text;
  bool isPinned;
  final DateTime createdAt;

  ClipboardItem({
    required this.id,
    required this.text,
    this.isPinned = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isPinned': isPinned,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ClipboardItem.fromJson(Map<String, dynamic> json) => ClipboardItem(
    id: json['id'] as String,
    text: json['text'] as String,
    isPinned: json['isPinned'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
