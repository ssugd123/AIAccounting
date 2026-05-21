class Expense {
  final int? id;
  final double amount;
  final int categoryId;
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;
  final String? externalId;

  const Expense({this.id, required this.amount, required this.categoryId,
    this.note, required this.recordedAt, required this.createdAt,
    required this.updatedAt, this.source = 'manual', this.externalId});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'amount': amount, 'category_id': categoryId,
    'note': note, 'recorded_at': recordedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'source': source,
    'external_id': externalId,
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    categoryId: map['category_id'] as int,
    note: map['note'] as String?,
    recordedAt: DateTime.parse(map['recorded_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    source: (map['source'] as String?) ?? 'manual',
    externalId: map['external_id'] as String?,
  );

  Expense copyWith({int? id, double? amount, int? categoryId, String? note,
      bool clearNote = false, DateTime? recordedAt, DateTime? createdAt,
      DateTime? updatedAt, String? source, String? externalId}) => Expense(
    id: id ?? this.id, amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    note: clearNote ? null : (note ?? this.note),
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source ?? this.source,
    externalId: externalId ?? this.externalId,
  );
}

class ExpenseWithCategory {
  final Expense expense;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;

  const ExpenseWithCategory({required this.expense, required this.categoryName,
    required this.categoryColor, required this.categoryIcon});

  factory ExpenseWithCategory.fromMap(Map<String, dynamic> map) =>
      ExpenseWithCategory(
        expense: Expense.fromMap(map),
        categoryName: map['category_name'] as String,
        categoryColor: map['category_color'] as String,
        categoryIcon: map['category_icon'] as String? ?? 'category',
      );
}
