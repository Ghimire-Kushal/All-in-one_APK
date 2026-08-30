enum ExpenseCategory { food, travel, college, shopping, other }

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.college:
        return 'College';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.travel:
        return '🚌';
      case ExpenseCategory.college:
        return '📚';
      case ExpenseCategory.shopping:
        return '🛍';
      case ExpenseCategory.other:
        return '💸';
    }
  }
}

class Expense {
  final String id;
  String title;
  double amount;
  ExpenseCategory category;
  DateTime date;
  String note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: ExpenseCategory.values.firstWhere(
      (e) => e.name == json['category'],
      orElse: () => ExpenseCategory.other,
    ),
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String? ?? '',
  );
}
