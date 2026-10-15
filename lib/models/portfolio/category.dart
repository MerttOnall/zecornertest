class Category {
  final String id;
  final String code;
  final String name;
  final String? parentId;

  Category({
    required this.id,
    required this.code,
    required this.name,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'parent_id': parentId,
    };
  }
}

