class PropertyModel {
  final String code;
  final int? numberValue;
  final String? stringValue;
  final String valueId;
  final String value;

  PropertyModel({
    required this.code,
    this.numberValue,
    this.stringValue,
    required this.valueId,
    required this.value,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    String safeStr(dynamic v) => v?.toString() ?? '';
    int? safeInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }
    return PropertyModel(
      code: safeStr(json['code']),
      numberValue: safeInt(json['number_value']),
      stringValue: json['string_value']?.toString(),
      valueId: safeStr(json['value_id'] ?? json['property_value']),
      value: safeStr(json['value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'number_value': numberValue,
      'string_value': stringValue,
      'value_id': valueId,
      'value': value,
    };
  }

  List<Object?> get props => [code, numberValue, stringValue, valueId, value];
}
