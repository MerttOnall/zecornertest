class RefEducationModel {
  final String id;
  final String code;
  final String description;

  RefEducationModel({
    this.id = '',
    required this.code,
    required this.description,
  });

  factory RefEducationModel.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? '').toString();
    final rawCode = (json['code'] ?? '').toString();
    return RefEducationModel(
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
    return other is RefEducationModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'RefEducationModel(code: $code, description: $description)';
}

class RefEducationResponseModel {
  final List<RefEducationModel> educations;

  RefEducationResponseModel({
    required this.educations,
  });

  factory RefEducationResponseModel.fromJson(List<dynamic> json) {
    return RefEducationResponseModel(
      educations: json.map((e) => RefEducationModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return educations.map((e) => e.toJson()).toList();
  }
}
