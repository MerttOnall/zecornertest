class RefCountryModel {
  final String code;
  final String name;
  final String? phoneCode;

  RefCountryModel({
    required this.code,
    required this.name,
    this.phoneCode,
  });

  factory RefCountryModel.fromJson(Map<String, dynamic> json) {
    return RefCountryModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      phoneCode: json['phone_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'phone_code': phoneCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefCountryModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'RefCountryModel(code: $code, name: $name)';
}

class RefCountryResponseModel {
  final List<RefCountryModel> countries;

  RefCountryResponseModel({
    required this.countries,
  });

  factory RefCountryResponseModel.fromJson(List<dynamic> json) {
    return RefCountryResponseModel(
      countries: json.map((e) => RefCountryModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return countries.map((e) => e.toJson()).toList();
  }
}
