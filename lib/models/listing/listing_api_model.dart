import 'package:zecorner/core/utils/image_utils.dart';

/// API'den gelen değerler bazen int, bazen String olabilir. Güvenli parse için.
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.split('.').first);
  return null;
}

int _parseIntOrZero(dynamic value) => _parseInt(value) ?? 0;

class ListingApiModel {
  final String id;
  final int listingNo;
  final String title;
  final int price;
  final String currency;
  final String type;
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;
  final List<PropertyShort> propertiesShortList;
  final int contactNo;
  final String contactTitle;
  final String? picture;
  final String? coverPicture;
  final String contactTypeDescription;
  final String realEstateType;
  final String contactType;
  final String state;
  final String createdAt;
  final String? updatedAt;
  final int connectedContact;
  final String parentType;
  final bool internal;
  final String slug;
  final String contactSlug;
  final String? startDate;
  final String? endDate;
  final int viewCount;
  final String connectedContactTitle;
  final int? closingPrice;
  final bool isFavorite;
  final Map<String, Property> properties;

  ListingApiModel({
    required this.id,
    required this.listingNo,
    required this.title,
    required this.price,
    required this.currency,
    required this.type,
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
    required this.propertiesShortList,
    required this.contactNo,
    required this.contactTitle,
    this.picture,
    this.coverPicture,
    required this.contactTypeDescription,
    required this.realEstateType,
    required this.contactType,
    required this.state,
    required this.createdAt,
    this.updatedAt,
    required this.connectedContact,
    required this.parentType,
    required this.internal,
    required this.slug,
    required this.contactSlug,
    this.startDate,
    this.endDate,
    required this.viewCount,
    required this.connectedContactTitle,
    this.closingPrice,
    required this.isFavorite,
    required this.properties,
  });

  factory ListingApiModel.fromJson(Map<String, dynamic> json) {
    return ListingApiModel(
      id: json['id']?.toString() ?? '',
      listingNo: _parseIntOrZero(json['listing_no']),
      title: json['title']?.toString() ?? '',
      price: _parseIntOrZero(json['price']),
      currency: json['currency']?.toString() ?? 'TL',
      type: json['type']?.toString() ?? '',
      provinceCode: _parseIntOrZero(json['province_code']),
      provinceName: json['province_name']?.toString() ?? '',
      districtCode: _parseIntOrZero(json['district_code']),
      districtName: json['district_name']?.toString() ?? '',
      quarterCode: _parseIntOrZero(json['quarter_code']),
      quarterName: json['quarter_name']?.toString() ?? '',
      propertiesShortList: (json['properties_short_list'] as List<dynamic>?)
          ?.map((e) => PropertyShort.fromJson(e))
          .toList() ?? [],
      contactNo: _parseIntOrZero(json['contact_no']),
      contactTitle: json['contact_title']?.toString() ?? '',
      picture: json['picture']?.toString(),
      coverPicture: json['cover_picure']?.toString(),
      contactTypeDescription: json['contact_type_description']?.toString() ?? '',
      realEstateType: json['real_estate_type']?.toString() ?? '',
      contactType: json['contact_type']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
      connectedContact: _parseIntOrZero(json['connected_contact']),
      parentType: json['parent_type']?.toString() ?? '',
      internal: json['internal'] == true || json['internal'] == 'true',
      slug: json['slug']?.toString() ?? '',
      contactSlug: json['contact_slug']?.toString() ?? '',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      viewCount: _parseIntOrZero(json['view_count']),
      connectedContactTitle: json['connected_contact_title']?.toString() ?? '',
      closingPrice: _parseInt(json['closing_price']),
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 'true',
      properties: (json['properties'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, Property.fromJson(value)))
          ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_no': listingNo,
      'title': title,
      'price': price,
      'currency': currency,
      'type': type,
      'province_code': provinceCode,
      'province_name': provinceName,
      'district_code': districtCode,
      'district_name': districtName,
      'quarter_code': quarterCode,
      'quarter_name': quarterName,
      'properties_short_list': propertiesShortList.map((e) => e.toJson()).toList(),
      'contact_no': contactNo,
      'contact_title': contactTitle,
      'picture': picture,
      'cover_picure': coverPicture,
      'contact_type_description': contactTypeDescription,
      'real_estate_type': realEstateType,
      'contact_type': contactType,
      'state': state,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'connected_contact': connectedContact,
      'parent_type': parentType,
      'internal': internal,
      'slug': slug,
      'contact_slug': contactSlug,
      'start_date': startDate,
      'end_date': endDate,
      'view_count': viewCount,
      'connected_contact_title': connectedContactTitle,
      'closing_price': closingPrice,
      'is_favorite': isFavorite,
      'properties': properties.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  // Helper getters
  String get displayType {
    switch (type) {
      case 'kiralik':
        return 'Kiralık';
      case 'satilik':
        return 'Satılık';
      default:
        return type;
    }
  }

  String get displayPrice {
    if (price >= 1000000) {
      return '₺${(price / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (price >= 1000) {
      return '₺${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return '₺$price';
    }
  }

  String get fullPrice {
    return '₺${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  String get location {
    return '$provinceName / $districtName / $quarterName';
  }

  String get size {
    final m2 = areaSqm;
    if (m2 != null) return '$m2 m²';
    return 'Belirtilmemiş';
  }

  /// Filtre için m² değeri (net / brüt / m2)
  int? get areaSqm {
    final m2Net = properties['m2-net']?.numberValue;
    if (m2Net != null) return m2Net;
    final m2Brut = properties['m2-brut']?.numberValue;
    if (m2Brut != null) return m2Brut;
    final m2 = properties['m2']?.numberValue;
    if (m2 != null) return m2;
    for (final p in propertiesShortList) {
      final code = p.code.toLowerCase();
      if ((code.contains('m2') || code.contains('alan')) &&
          p.numberValue != null) {
        return p.numberValue;
      }
    }
    return null;
  }

  /// real_estate_type → Konut / İş Yeri / Arsa
  String get displayRealEstateCategory {
    final t = realEstateType.toLowerCase();
    if (t.startsWith('konut') || t.contains('daire') || t.contains('villa')) {
      return 'Konut';
    }
    if (t.contains('is-yeri') ||
        t.contains('isyeri') ||
        t.contains('is_yeri') ||
        t.contains('iş yeri') ||
        t.contains('ofis') ||
        t.contains('dukkan') ||
        t.contains('dükkan')) {
      return 'İş Yeri';
    }
    if (t.contains('arsa')) return 'Arsa';
    return realEstateType;
  }

  String get rooms {
    final odaSayisi = properties['oda-sayisi'];
    if (odaSayisi?.value != null && odaSayisi!.value.isNotEmpty) {
      final val = odaSayisi.value;
      switch (val) {
        case 'oda-sayisi-11':
        case 'oda-sayisi-151':
          return '1+1';
        case 'oda-sayisi-21':
          return '2+1';
        case 'oda-sayisi-31':
          return '3+1';
        case 'oda-sayisi-41':
          return '4+1';
        case 'oda-sayisi-51':
          return '5+1';
        case 'oda-sayisi-251':
          return '2.5+1';
        default:
          if (val.startsWith('oda-sayisi-')) {
            final suffix = val.replaceFirst('oda-sayisi-', '');
            if (suffix == '1' || suffix == '11') return '1+1';
            if (suffix == '2' || suffix == '21') return '2+1';
            if (suffix == '3' || suffix == '31') return '3+1';
            if (suffix == '4' || suffix == '41') return '4+1';
            if (suffix == '5' || suffix == '51') return '5+1';
            if (suffix == '251') return '2.5+1';
          }
          return 'Belirtilmemiş';
      }
    }
    // İşyeri için bölüm oda sayısı
    final bolumOda = properties['bolum-oda-sayisi'];
    if (bolumOda?.numberValue != null) {
      return '${bolumOda!.numberValue} oda';
    }
    return 'Belirtilmemiş';
  }

  String get coverImageUrl {
    if (coverPicture != null && coverPicture!.isNotEmpty) {
      return ImageUtils.getCoverImageUrl(coverPicture);
    }
    return "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=400&q=80";
  }

  String get contactImageUrl {
    if (picture != null && picture!.isNotEmpty) {
      return ImageUtils.getProfileImageUrl(picture);
    }
    return "";
  }

  String get formattedCreatedDate {
    if (createdAt.isEmpty) return "Belirtilmemiş";
    try {
      final date = DateTime.parse(createdAt);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return "Belirtilmemiş";
    }
  }
}

class PropertyShort {
  final String code;
  final int? numberValue;
  final String? stringValue;
  final String valueId;
  final String value;

  PropertyShort({
    required this.code,
    this.numberValue,
    this.stringValue,
    required this.valueId,
    required this.value,
  });

  factory PropertyShort.fromJson(Map<String, dynamic> json) {
    return PropertyShort(
      code: json['code']?.toString() ?? '',
      numberValue: _parseInt(json['number_value']),
      stringValue: json['string_value']?.toString(),
      valueId: json['value_id']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
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

class Property {
  final String code;
  final int? numberValue;
  final String? stringValue;
  final String valueId;
  final String value;

  Property({
    required this.code,
    this.numberValue,
    this.stringValue,
    required this.valueId,
    required this.value,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      code: json['code']?.toString() ?? '',
      numberValue: _parseInt(json['number_value']),
      stringValue: json['string_value']?.toString(),
      valueId: json['value_id']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
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

class ListingResponse {
  final List<ListingApiModel> listings;
  final int totalCount;
  final int totalPages;
  final int page;

  ListingResponse({
    required this.listings,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ListingResponse.fromJson(Map<String, dynamic> json) {
    return ListingResponse(
      listings: (json['listings'] as List<dynamic>?)
          ?.map((e) => ListingApiModel.fromJson(e))
          .toList() ?? [],
      totalCount: _parseIntOrZero(json['totalCount']),
      totalPages: _parseIntOrZero(json['totalPages']),
      page: _parseIntOrZero(json['page']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listings': listings.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
