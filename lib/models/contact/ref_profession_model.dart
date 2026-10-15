class RefProfessionModel {
  final String code;
  final String description;

  RefProfessionModel({
    required this.code,
    required this.description,
  });

  factory RefProfessionModel.fromJson(Map<String, dynamic> json) {
    return RefProfessionModel(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
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
