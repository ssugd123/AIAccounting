class Budget {
  final int? id;
  final String type;
  final double amount;
  final bool isActive;
  final DateTime createdAt;

  const Budget({this.id, required this.type, required this.amount,
    this.isActive = true, required this.createdAt});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'type': type, 'amount': amount,
    'is_active': isActive ? 1 : 0, 'created_at': createdAt.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] as int?,
    type: map['type'] as String,
    amount: (map['amount'] as num).toDouble(),
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Budget copyWith({int? id, String? type, double? amount, bool? isActive,
      DateTime? createdAt}) => Budget(
    id: id ?? this.id, type: type ?? this.type, amount: amount ?? this.amount,
    isActive: isActive ?? this.isActive, createdAt: createdAt ?? this.createdAt,
  );
}
