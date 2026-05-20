class Category {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isPreset;
  final DateTime createdAt;

  const Category({
    this.id, required this.name, this.icon = 'category',
    required this.color, this.sortOrder = 0, this.isPreset = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name, 'icon': icon, 'color': color,
    'sort_order': sortOrder, 'is_preset': isPreset ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    icon: map['icon'] as String? ?? 'category',
    color: map['color'] as String,
    sortOrder: map['sort_order'] as int? ?? 0,
    isPreset: (map['is_preset'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Category copyWith({int? id, String? name, String? icon, String? color,
      int? sortOrder, bool? isPreset, DateTime? createdAt}) => Category(
    id: id ?? this.id, name: name ?? this.name, icon: icon ?? this.icon,
    color: color ?? this.color, sortOrder: sortOrder ?? this.sortOrder,
    isPreset: isPreset ?? this.isPreset, createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is Category && id == other.id && name == other.name &&
      color == other.color && sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder);
}
