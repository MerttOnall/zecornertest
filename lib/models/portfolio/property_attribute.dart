class PropertyAttribute {
  /// BAMMA `realEstate` gövdesinde `properties[].id` — ref API satır kimliği.
  final String? id;
  final String propertyCode;
  final String control;
  final String? group;
  final PropertyValidation? validation;
  final List<PropertyValue> values;
  final List<PropertyAttribute>? properties;

  PropertyAttribute({
    this.id,
    required this.propertyCode,
    required this.control,
    this.group,
    this.validation,
    required this.values,
    this.properties,
  });

  /// Ref API bazen satır kimliğini farklı anahtarlarla döner; `values[].id` seçenek id’sidir (satır id değil).
  static String? _parseAttributeRowId(Map<String, dynamic> json) {
    const keys = [
      'id',
      'property_id',
      'row_id',
      'definition_id',
      'ref_property_id',
      'ref_id',
      'property_uuid',
      'uuid',
      'pk',
      '_id',
      'propertyId',
      'definitionId',
    ];
    for (final k in keys) {
      final v = json[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    final nested = json['property'];
    if (nested is Map<String, dynamic>) {
      return _parseAttributeRowId(nested);
    }
    return null;
  }

  factory PropertyAttribute.fromJson(Map<String, dynamic> json) {
    final valuesList = json['values'];
    final values = (valuesList is List)
        ? valuesList
            .map((v) => PropertyValue.fromJson(v as Map<String, dynamic>))
            .toList()
        : <PropertyValue>[];

    return PropertyAttribute(
      id: _parseAttributeRowId(json),
      propertyCode:
          json['property_code']?.toString() ?? json['propertyCode']?.toString() ?? '',
      control: json['control']?.toString() ?? '',
      group: json['group']?.toString(),
      validation: json['validation'] != null
          ? PropertyValidation.fromJson(
              json['validation'] as Map<String, dynamic>,
            )
          : null,
      values: values,
      properties: json['properties'] != null
          ? (json['properties'] as List)
              .map((p) => PropertyAttribute.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class PropertyValue {
  final String? id;
  final String? code;

  PropertyValue({
    this.id,
    this.code,
  });

  factory PropertyValue.fromJson(Map<String, dynamic> json) {
    return PropertyValue(
      id: json['id'],
      code: json['code'],
    );
  }
}

class PropertyValidation {
  final bool? required;
  final ValidationComparison? gt;
  final ValidationComparison? lt;

  PropertyValidation({
    this.required,
    this.gt,
    this.lt,
  });

  factory PropertyValidation.fromJson(Map<String, dynamic> json) {
    return PropertyValidation(
      required: json['required'],
      gt: json['gt'] != null 
          ? ValidationComparison.fromJson(json['gt'])
          : null,
      lt: json['lt'] != null 
          ? ValidationComparison.fromJson(json['lt'])
          : null,
    );
  }
}

class ValidationComparison {
  final String from;
  final String compare;

  ValidationComparison({
    required this.from,
    required this.compare,
  });

  factory ValidationComparison.fromJson(Map<String, dynamic> json) {
    return ValidationComparison(
      from: json['from'],
      compare: json['compare'],
    );
  }
}

class PropertyAttributesResponse {
  final List<PropertyAttribute> properties;
  final List<dynamic> poiTypes;

  PropertyAttributesResponse({
    required this.properties,
    required this.poiTypes,
  });

  factory PropertyAttributesResponse.fromJson(Map<String, dynamic> json) {
    return PropertyAttributesResponse(
      properties: (json['properties'] as List)
          .map((p) => PropertyAttribute.fromJson(p))
          .toList(),
      poiTypes: json['poi_types'] ?? [],
    );
  }
}

