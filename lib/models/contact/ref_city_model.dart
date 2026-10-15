class RefCityModel {
  final String code;
  final String name;
  final String? countryCode;

  RefCityModel({
    required this.code,
    required this.name,
    this.countryCode,
  });

  factory RefCityModel.fromJson(Map<String, dynamic> json) {
    return RefCityModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      countryCode: json['country_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'country_code': countryCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RefCityModel && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'RefCityModel(code: $code, name: $name)';
}

class RefCityResponseModel {
  final List<RefCityModel> cities;

  RefCityResponseModel({
    required this.cities,
  });

  factory RefCityResponseModel.fromJson(List<dynamic> json) {
    return RefCityResponseModel(
      cities: json.map((e) => RefCityModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  List<Map<String, dynamic>> toJson() {
    return cities.map((e) => e.toJson()).toList();
  }
}
