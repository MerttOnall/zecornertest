class SearchRealEstateResponseModel {
  final List<SearchRealEstateModel> realEstates;
  final int totalCount;

  SearchRealEstateResponseModel({
    required this.realEstates,
    required this.totalCount,
  });

  factory SearchRealEstateResponseModel.fromJson(dynamic json) {
    if (json is List) {
      // Sadece array gelirse
      final List<SearchRealEstateModel> estates = json
          .map((e) => SearchRealEstateModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return SearchRealEstateResponseModel(
        realEstates: estates,
        totalCount: estates.length,
      );
    } else if (json is Map<String, dynamic>) {
      // Object formatında gelirse
      return SearchRealEstateResponseModel(
        realEstates: (json['real_estates'] as List<dynamic>?)
                ?.map((e) => SearchRealEstateModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        totalCount: json['totalCount'] ?? json['total_count'] ?? 0,
      );
    }
    
    // Fallback
    return SearchRealEstateResponseModel(realEstates: [], totalCount: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'real_estates': realEstates.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
    };
  }
}

class SearchRealEstateModel {
  final String id;
  final String type;
  final String description;
  final int status;
  final String updatedAt;
  final String recordedAt;
  final SearchAddressModel address;
  final Map<String, SearchPropertyModel> properties;
  final String thumbnail;
  final int contact;
  final String contactType;
  final String title;

  SearchRealEstateModel({
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
  });

  factory SearchRealEstateModel.fromJson(Map<String, dynamic> json) {
    return SearchRealEstateModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      recordedAt: json['recorded_at'] ?? '',
      address: SearchAddressModel.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      properties: _parseProperties(json['properties'] as Map<String, dynamic>? ?? {}),
      thumbnail: json['thumbnail'] ?? '',
      contact: json['contact'] ?? 0,
      contactType: json['contact_type'] ?? '',
      title: json['title'] ?? '',
    );
  }

  static Map<String, SearchPropertyModel> _parseProperties(Map<String, dynamic> propertiesJson) {
    Map<String, SearchPropertyModel> properties = {};
    propertiesJson.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        properties[key] = SearchPropertyModel.fromJson(value);
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
    };
  }
}

class SearchAddressModel {
  final String address;
  final double lat;
  final double lon;
  final String? district;
  final String? city;
  final String? countryCode;
  final String? countryName;
  final String? source;
  final SearchUavtAddressModel? uavtAddress;

  SearchAddressModel({
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

  factory SearchAddressModel.fromJson(Map<String, dynamic> json) {
    return SearchAddressModel(
      address: json['address'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      district: json['district'],
      city: json['city'],
      countryCode: json['country_code'],
      countryName: json['country_name'],
      source: json['source'],
      uavtAddress: json['uavt_address'] != null
          ? SearchUavtAddressModel.fromJson(json['uavt_address'] as Map<String, dynamic>)
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

class SearchUavtAddressModel {
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;

  SearchUavtAddressModel({
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
  });

  factory SearchUavtAddressModel.fromJson(Map<String, dynamic> json) {
    return SearchUavtAddressModel(
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

class SearchPropertyModel {
  final String code;
  final int? numberValue;
  final String? stringValue;
  final String valueId;
  final String value;

  SearchPropertyModel({
    required this.code,
    this.numberValue,
    this.stringValue,
    required this.valueId,
    required this.value,
  });

  factory SearchPropertyModel.fromJson(Map<String, dynamic> json) {
    return SearchPropertyModel(
      code: json['code'] ?? '',
      numberValue: json['number_value'],
      stringValue: json['string_value'],
      valueId: json['value_id'] ?? '',
      value: json['value'] ?? '',
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
extension SearchRealEstateModelHelpers on SearchRealEstateModel {
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
  SearchPropertyModel? getProperty(String code) {
    return properties[code];
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

  /// Açık alan m2 değerini döndürür (fabrika, ev vb. için)
  double? get openAreaM2 {
    final openAreaProperty = getProperty('acik-alan-m2');
    return openAreaProperty?.numberValue?.toDouble();
  }

  /// Kapalı alan m2 değerini döndürür (fabrika vb. için)
  double? get closedAreaM2 {
    final closedAreaProperty = getProperty('kapali-alan-m2');
    return closedAreaProperty?.numberValue?.toDouble();
  }

  /// Oda sayısını döndürür
  String? get roomCount {
    final roomProperty = getProperty('oda-sayisi');
    if (roomProperty?.numberValue != null) {
      return roomProperty!.numberValue.toString();
    }
    return roomProperty?.value.replaceAll('oda-sayisi-', '');
  }

  /// Salon sayısını döndürür (yalı dairesi için)
  int? get salonCount {
    final salonProperty = getProperty('salon-sayisi');
    return salonProperty?.numberValue;
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
    if (ageProperty?.numberValue != null) {
      return ageProperty!.numberValue.toString();
    }
    return ageProperty?.value.replaceAll('bina-yasi-', '');
  }

  /// Bulunduğu katı döndürür
  String? get floor {
    final floorProperty = getProperty('bulundugu-kat');
    return floorProperty?.value.replaceAll('bulundugu-kat-', '').replaceAll('-', ' ');
  }

  /// Banyo sayısını döndürür
  String? get bathroomCount {
    final bathroomProperty = getProperty('banyo-sayisi');
    if (bathroomProperty?.numberValue != null) {
      return bathroomProperty!.numberValue.toString();
    }
    return bathroomProperty?.value.replaceAll('banyo-sayisi-', '');
  }

  /// Isıtma tipini döndürür
  String? get heatingType {
    final heatingProperty = getProperty('isitma');
    return heatingProperty?.value.replaceAll('isitma-', '').replaceAll('-', ' ');
  }

  /// Cepheyi döndürür
  String? get facade {
    final facadeProperty = getProperty('cephe');
    return facadeProperty?.value;
  }

  /// İç özellikleri döndürür
  String? get interiorFeatures {
    final interiorProperty = getProperty('ic-ozellikler');
    return interiorProperty?.value.replaceAll('-', ' ');
  }

  /// Dış özellikleri döndürür
  String? get exteriorFeatures {
    final exteriorProperty = getProperty('dis-ozellikler');
    return exteriorProperty?.value.replaceAll('-', ' ');
  }

  /// Manzarayı döndürür
  String? get view {
    final viewProperty = getProperty('manzara');
    return viewProperty?.value;
  }

  /// Konut tipini döndürür
  String? get housingType {
    final housingProperty = getProperty('konut-tipi');
    return housingProperty?.value.replaceAll('konut-tipi-', '').replaceAll('-', ' ');
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

  /// Otopark bilgisini döndürür
  String? get parkingInfo {
    final parkingProperty = getProperty('otopark');
    return parkingProperty?.value.replaceAll('otopark-', '').replaceAll('-', ' ');
  }

  /// Engelliye uygun mu kontrol eder
  String? get disabilityFriendly {
    final disabilityProperty = getProperty('engelliye-ve-yasliya-uygun');
    return disabilityProperty?.value;
  }

  /// Bina adedi (fabrika için)
  int? get buildingCount {
    final buildingProperty = getProperty('bina-adedi');
    return buildingProperty?.numberValue;
  }

  /// Bölüm/oda sayısı (fabrika için)
  int? get roomSectionCount {
    final roomSectionProperty = getProperty('bolum-oda-sayisi');
    return roomSectionProperty?.numberValue;
  }

  /// Yapının durumu
  String? get buildingCondition {
    final conditionProperty = getProperty('yapinin-durumu');
    return conditionProperty?.value.replaceAll('yapinin-durumu-', '');
  }

  /// Fiyat aralığı için temel m2 değeri
  double? get primaryAreaSize {
    return brutM2 ?? netM2 ?? openAreaM2 ?? closedAreaM2;
  }
}
