class RefProfessionModel {
  final String id;
  final String code;
  final String description;

  RefProfessionModel({
    this.id = '',
    required this.code,
    required this.description,
  });

  factory RefProfessionModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? '').toString();
    final rawCode = (json['code'] ?? '').toString();
    return RefProfessionModel(
      id: rawId.isNotEmpty ? rawId : rawCode,
      code: rawCode.isNotEmpty ? rawCode : rawId,
      description: (json['description'] ?? json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefProfessionModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'RefProfessionModel(code: $code, description: $description)';
}

class RefProfessionResponseModel {
  final List<RefProfessionModel> professions;

  RefProfessionResponseModel({
    required this.professions,
  });

  factory RefProfessionResponseModel.fromJson(List<dynamic> json) {
    return RefProfessionResponseModel(
      professions: json.map((e) => RefProfessionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return professions.map((e) => e.toJson()).toList();
  }
}

/// Meslek id/kod → açıklama. Liste kartlarında yalnızca id geldiğinde N/A kalmasın.
class ProfessionCatalog {
  static final Map<String, String> _labels = {};

  static bool get isReady => _labels.isNotEmpty;

  static void remember(Iterable<RefProfessionModel> items) {
    for (final item in items) {
      final label = item.description.trim();
      if (label.isEmpty) continue;
      if (item.id.isNotEmpty) _labels[item.id] = label;
      if (item.code.isNotEmpty) _labels[item.code] = label;
    }
  }

  static String? labelFor(String? key) {
    final text = key?.trim() ?? '';
    if (text.isEmpty) return null;
    return _labels[text];
  }
}
