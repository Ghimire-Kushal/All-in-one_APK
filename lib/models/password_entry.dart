class PasswordEntry {
  final String id;
  String title;
  String username;
  String password;
  String website;
  String note;
  final DateTime createdAt;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website = '',
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'username': username,
    'password': password,
    'website': website,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    website: json['website'] as String? ?? '',
    note: json['note'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
