class MyRealEstateResponseModel {
  final List<RealEstateModel> realEstates;
  final int totalCount;
  final int totalPages;
  final int page;

  MyRealEstateResponseModel({
    required this.realEstates,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory MyRealEstateResponseModel.fromJson(Map<String, dynamic> json) {
    return MyRealEstateResponseModel(
      realEstates: (json['real_estates'] as List<dynamic>?)
              ?.map((e) => RealEstateModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'real_estates': realEstates.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

class RealEstateModel {
  final String id;
  final String type;
  final String description;
  final int status;
  final String updatedAt;
  final String recordedAt;
  final AddressModel address;
  final Map<String, PropertyModel> properties;
  final String thumbnail;
  final int contact;
  final String contactType;
  final String title;
  final int? price;

  RealEstateModel({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.updatedAt,
    required this.recordedAt,
    required this.address,
    required this.properties,
    required this.thumbnail,
    required this.contact,
    required this.contactType,
    required this.title,
    this.price,
  });

  factory RealEstateModel.fromJson(Map<String, dynamic> json) {
    return RealEstateModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      recordedAt: json['recorded_at'] ?? '',
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      properties: _parseProperties(json['properties'] as Map<String, dynamic>? ?? {}),
      thumbnail: json['thumbnail'] ?? '',
      contact: json['contact'] ?? 0,
      contactType: json['contact_type'] ?? '',
      title: json['title'] ?? '',
      price: _parseOptionalInt(json['price']),
    );
  }

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().split('.').first);
  }

  static Map<String, PropertyModel> _parseProperties(Map<String, dynamic> propertiesJson) {
    Map<String, PropertyModel> properties = {};
    propertiesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        properties[key] = PropertyModel.fromJson(value);
      }
    });
    return properties;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'status': status,
      'updated_at': updatedAt,
      'recorded_at': recordedAt,
      'address': address.toJson(),
      'properties': properties.map((key, value) => MapEntry(key, value.toJson())),
      'thumbnail': thumbnail,
      'contact': contact,
      'contact_type': contactType,
      'title': title,
      'price': price,
    };
  }
}

class AddressModel {
  final String address;
  final double lat;
  final double lon;
  final String? district;
  final String? city;
  final String? countryCode;
  final String? countryName;
  final String? source;
  final UavtAddressModel? uavtAddress;

  AddressModel({
    required this.address,
    required this.lat,
    required this.lon,
    this.district,
    this.city,
    this.countryCode,
    this.countryName,
    this.source,
    this.uavtAddress,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      address: json['address'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      district: json['district'],
      city: json['city'],
      countryCode: json['country_code'],
      countryName: json['country_name'],
      source: json['source'],
      uavtAddress: json['uavt_address'] != null
          ? UavtAddressModel.fromJson(json['uavt_address'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'lat': lat,
      'lon': lon,
      'district': district,
      'city': city,
      'country_code': countryCode,
      'country_name': countryName,
      'source': source,
      'uavt_address': uavtAddress?.toJson(),
    };
  }
}

class UavtAddressModel {
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;

  UavtAddressModel({
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
  });

  factory UavtAddressModel.fromJson(Map<String, dynamic> json) {
    return UavtAddressModel(
      provinceCode: json['province_code'] ?? 0,
      provinceName: json['province_name'] ?? '',
      districtCode: json['district_code'] ?? 0,
      districtName: json['district_name'] ?? '',
      quarterCode: json['quarter_code'] ?? 0,
      quarterName: json['quarter_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province_code': provinceCode,
      'province_name': provinceName,
      'district_code': districtCode,
      'district_name': districtName,
      'quarter_code': quarterCode,
      'quarter_name': quarterName,
    };
  }
}

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
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final code = safeStr(json['code']).isNotEmpty
        ? safeStr(json['code'])
        : safeStr(json['property']);

    int? numberValue = safeInt(json['number_value']);
    final rawValue = json['value'];
    if (numberValue == null && rawValue is num) {
      numberValue = safeInt(rawValue);
    }

    return PropertyModel(
      code: code,
      numberValue: numberValue,
      stringValue: json['string_value']?.toString(),
      valueId: safeStr(json['value_id'] ?? json['property_value']),
      value: safeStr(rawValue),
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
}

// Helper Extension for Easy Access
extension RealEstateModelHelpers on RealEstateModel {
  /// Emlak tipini Türkçe olarak döndürür
  String get typeDisplayName {
    switch (type) {
      case 'konut-daire':
        return 'Konut - Daire';
      case 'konut-mustakil-ev':
        return 'Konut - Müstakil Ev';
      case 'konut-yali-dairesi':
        return 'Konut - Yalı Dairesi';
      case 'is-yeri-apartman-dairesi':
        return 'İş Yeri - Apartman Dairesi';
      case 'is-yeri-fabrika':
        return 'İş Yeri - Fabrika';
      default:
        return type.replaceAll('-', ' ').toUpperCase();
    }
  }

  /// Adres bilgisini tek satırda döndürür
  String get fullAddress {
    if (address.uavtAddress != null) {
      return '${address.uavtAddress!.quarterName}, ${address.uavtAddress!.districtName}, ${address.uavtAddress!.provinceName}';
    }
    return address.address.isNotEmpty ? address.address : 'Adres bilgisi yok';
  }

  /// Brüt m2 değerini döndürür
  double? get brutM2 {
    final brutProperty = properties['m2-brut'];
    return brutProperty?.numberValue?.toDouble();
  }

  /// Net m2 değerini döndürür
  double? get netM2 {
    final netProperty = properties['m2-net'];
    return netProperty?.numberValue?.toDouble();
  }

  /// Oda sayısını döndürür
  String? get roomCount {
    final roomProperty = properties['oda-sayisi'];
    return roomProperty?.value.replaceAll('oda-sayisi-', '');
  }

  /// Aidat miktarını döndürür
  double? get maintenanceFee {
    final aidatProperty = properties['aidat-tl'];
    return aidatProperty?.numberValue?.toDouble();
  }

  /// Taşınmaz numarasını döndürür
  String? get propertyNumber {
    final propertyNumProperty = properties['tasinmaz-numarasi'];
    return propertyNumProperty?.stringValue;
  }

  /// Durum bilgisini Türkçe döndürür
  String get statusDisplayName {
    switch (status) {
      case 0:
        return 'Pasif';
      case 1:
        return 'Aktif';
      case 2:
        return 'Beklemede';
      case 3:
        return 'Satıldı/Kiralandı';
      default:
        return 'Bilinmiyor';
    }
  }
}
