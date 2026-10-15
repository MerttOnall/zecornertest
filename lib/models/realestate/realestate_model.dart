class RealEstateDetailModel {
  final String id;
  final String type;
  final String description;
  final int status;
  final String updatedAt;
  final String recordedAt;
  final RealEstateAddressModel address;
  final List<RealEstatePropertyModel> properties;
  final List<RealEstateMediaModel> medias;
  final dynamic pois; // null olabiliyor
  final String title;

  RealEstateDetailModel({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.updatedAt,
    required this.recordedAt,
    required this.address,
    required this.properties,
    required this.medias,
    this.pois,
    required this.title,
  });

  factory RealEstateDetailModel.fromJson(Map<String, dynamic> json) {
    return RealEstateDetailModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      recordedAt: json['recorded_at'] ?? '',
      address: RealEstateAddressModel.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => RealEstatePropertyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      medias: (json['medias'] as List<dynamic>?)
              ?.map((e) => RealEstateMediaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pois: json['pois'],
      title: json['title'] ?? '',
    );
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
      'properties': properties.map((e) => e.toJson()).toList(),
      'medias': medias.map((e) => e.toJson()).toList(),
      'pois': pois,
      'title': title,
    };
  }
}

class RealEstateAddressModel {
  final String address;
  final double lat;
  final double lon;
  final String? district;
  final String? city;
  final String? countryCode;
  final String? countryName;
  final String? source;
  final RealEstateUavtAddressModel? uavtAddress;

  RealEstateAddressModel({
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

  factory RealEstateAddressModel.fromJson(Map<String, dynamic> json) {
    return RealEstateAddressModel(
      address: json['address'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      district: json['district'],
      city: json['city'],
      countryCode: json['country_code'],
      countryName: json['country_name'],
      source: json['source'],
      uavtAddress: json['uavt_address'] != null
          ? RealEstateUavtAddressModel.fromJson(json['uavt_address'] as Map<String, dynamic>)
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

class RealEstateUavtAddressModel {
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;

  RealEstateUavtAddressModel({
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
  });

  factory RealEstateUavtAddressModel.fromJson(Map<String, dynamic> json) {
    return RealEstateUavtAddressModel(
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

class RealEstatePropertyModel {
  final String code;
  final String value;
  final String? stringValue;
  final int? numberValue;
  final String propertyValue;
  final String property;

  RealEstatePropertyModel({
    required this.code,
    required this.value,
    this.stringValue,
    this.numberValue,
    required this.propertyValue,
    required this.property,
  });

  factory RealEstatePropertyModel.fromJson(Map<String, dynamic> json) {
    return RealEstatePropertyModel(
      code: json['code'] ?? '',
      value: json['value'] ?? '',
      stringValue: json['string_value'],
      numberValue: json['number_value'],
      propertyValue: json['property_value'] ?? '',
      property: json['property'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'value': value,
      'string_value': stringValue,
      'number_value': numberValue,
      'property_value': propertyValue,
      'property': property,
    };
  }
}

class RealEstateMediaModel {
  final String type;
  final String thumbnail;
  final String standard;
  final String hd;
  final bool isCover;

  RealEstateMediaModel({
    required this.type,
    required this.thumbnail,
    required this.standard,
    required this.hd,
    required this.isCover,
  });

  factory RealEstateMediaModel.fromJson(Map<String, dynamic> json) {
    return RealEstateMediaModel(
      type: json['type'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      standard: json['standart'] ?? '', // API'de "standart" olarak yazılmış
      hd: json['hd'] ?? '',
      isCover: json['is_cover'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'thumbnail': thumbnail,
      'standart': standard, // API formatına uygun olarak "standart"
      'hd': hd,
      'is_cover': isCover,
    };
  }
}

// Helper Extension for Easy Access
extension RealEstateDetailModelHelpers on RealEstateDetailModel {
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

  /// Belirli kod ile property bulur
  RealEstatePropertyModel? getProperty(String code) {
    try {
      return properties.firstWhere((property) => property.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Brüt m2 değerini döndürür
  double? get brutM2 {
    final brutProperty = getProperty('m2-brut');
    return brutProperty?.numberValue?.toDouble();
  }

  /// Net m2 değerini döndürür
  double? get netM2 {
    final netProperty = getProperty('m2-net');
    return netProperty?.numberValue?.toDouble();
  }

  /// Oda sayısını döndürür
  String? get roomCount {
    final roomProperty = getProperty('oda-sayisi');
    return roomProperty?.value.replaceAll('oda-sayisi-', '');
  }

  /// Aidat miktarını döndürür
  double? get maintenanceFee {
    final aidatProperty = getProperty('aidat-tl');
    return aidatProperty?.numberValue?.toDouble();
  }

  /// Taşınmaz numarasını döndürür
  String? get propertyNumber {
    final propertyNumProperty = getProperty('tasinmaz-numarasi');
    return propertyNumProperty?.stringValue;
  }

  /// Bina yaşını döndürür
  String? get buildingAge {
    final ageProperty = getProperty('bina-yasi');
    return ageProperty?.value.replaceAll('bina-yasi-', '');
  }

  /// Bulunduğu katı döndürür
  String? get floor {
    final floorProperty = getProperty('bulundugu-kat');
    return floorProperty?.value.replaceAll('bulundugu-kat-', '');
  }

  /// Banyo sayısını döndürür
  String? get bathroomCount {
    final bathroomProperty = getProperty('banyo-sayisi');
    return bathroomProperty?.value.replaceAll('banyo-sayisi-', '');
  }

  /// Isıtma tipini döndürür
  String? get heatingType {
    final heatingProperty = getProperty('isitma');
    return heatingProperty?.value.replaceAll('isitma-', '').replaceAll('-', ' ');
  }

  /// Kapak fotoğrafını döndürür
  RealEstateMediaModel? get coverImage {
    try {
      return medias.firstWhere((media) => media.isCover);
    } catch (e) {
      return medias.isNotEmpty ? medias.first : null;
    }
  }

  /// Tüm fotoğrafları döndürür (sadece image type)
  List<RealEstateMediaModel> get imageMedias {
    return medias.where((media) => media.type == 'image').toList();
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

  /// Eşyalı mı kontrol eder
  bool get isFurnished {
    final furnitureProperty = getProperty('esyali');
    return furnitureProperty?.value == 'esyali-evet';
  }

  /// Balkon var mı kontrol eder
  bool get hasBalcony {
    final balconyProperty = getProperty('balkon');
    return balconyProperty?.value == 'balkon-var';
  }

  /// Asansör var mı kontrol eder
  bool get hasElevator {
    final elevatorProperty = getProperty('asansor');
    return elevatorProperty?.value == 'asansor-var';
  }
}
