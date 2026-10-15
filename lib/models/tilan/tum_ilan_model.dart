import 'package:zecorner/models/list/listing_panel_model.dart';

class TumIlanModel {
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
  final String? closingPrice;
  final Map<String, dynamic> properties;

  TumIlanModel({
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
    required this.properties,
  });

  factory TumIlanModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? 0;
    }

    String asString(dynamic v, [String fallback = '']) {
      if (v == null) return fallback;
      final s = v.toString().trim();
      return s.isEmpty ? fallback : s;
    }

    String? asNullableString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    Map<String, dynamic> asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return {};
    }

    bool asBool(dynamic v) {
      if (v == true || v == 1) return true;
      final s = v?.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return TumIlanModel(
      id: asString(json['id']),
      listingNo: asInt(json['listing_no'] ?? json['listingNo']),
      title: asString(json['title']),
      price: asInt(json['price']),
      currency: asString(json['currency'], 'TRY'),
      type: asString(json['type']),
      provinceCode: asInt(json['province_code']),
      provinceName: asString(json['province_name']),
      districtCode: asInt(json['district_code']),
      districtName: asString(json['district_name']),
      quarterCode: asInt(json['quarter_code']),
      quarterName: asString(json['quarter_name']),
      contactNo: asInt(json['contact_no']),
      contactTitle: asString(json['contact_title']),
      picture: asNullableString(json['picture']),
      coverPicture: asNullableString(
        json['cover_picure'] ?? json['cover_picture'],
      ),
      contactTypeDescription: asString(json['contact_type_description']),
      realEstateType: asString(json['real_estate_type']),
      contactType: asString(json['contact_type']),
      state: asString(json['state']),
      createdAt: asString(json['created_at']),
      updatedAt: asNullableString(json['updated_at']),
      connectedContact: asInt(json['connected_contact']),
      parentType: asString(json['parent_type']),
      internal: asBool(json['internal']),
      slug: asString(json['slug']),
      contactSlug: asString(json['contact_slug']),
      startDate: asNullableString(json['start_date']),
      endDate: asNullableString(json['end_date']),
      viewCount: asInt(json['view_count']),
      connectedContactTitle: asString(json['connected_contact_title']),
      closingPrice: asNullableString(json['closing_price']),
      properties: asMap(json['properties']),
    );
  }

  factory TumIlanModel.fromListingPanel(ListingPanelModel panel) {
    return TumIlanModel.fromJson(panel.toJson());
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
      'properties': properties,
    };
  }

  // Web tasarımına göre veri eşleme metodları
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      final months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  String get location {
    return '$provinceName / $districtName / $quarterName';
  }

  String get formattedPrice {
    return '₺${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String get roomInfo {
    // API bazı ilanlarda oda-sayisi'ni number_value yerine value ile gönderir:
    // örn: "oda-sayisi-31", "oda-sayisi-251", "oda-sayisi-studyo-10"
    final oda = properties['oda-sayisi'];
    final salon = properties['salon-sayisi'];

    final odaNumber = oda is Map<String, dynamic> ? oda['number_value'] : null;
    final salonNumber = salon is Map<String, dynamic> ? salon['number_value'] : null;

    if (odaNumber != null && salonNumber != null) {
      return '${odaNumber.toString()}+${salonNumber.toString()}';
    }
    if (odaNumber != null) {
      return '${odaNumber.toString()}+0';
    }

    final odaValue = (oda is Map<String, dynamic>) ? (oda['value']?.toString()) : null;
    final parsed = _parseOdaSayisiValue(odaValue);
    return parsed ?? 'Bilinmiyor';
  }

  String? _parseOdaSayisiValue(String? raw) {
    if (raw == null || raw.isEmpty || raw == '-') return null;
    final v = raw.toLowerCase();

    // "oda-sayisi-studyo-10" gibi
    if (v.contains('studyo')) {
      // Stüdyo gösterimi
      return '1+0';
    }

    // "oda-sayisi-31" gibi
    final match = RegExp(r'oda-sayisi-(.+)$').firstMatch(v);
    if (match == null) return null;
    final code = match.group(1) ?? '';

    // Bazı kodlar direkt map ediliyor
    switch (code) {
      case '11':
        return '1+1';
      case '10':
        return '1+0';
      case '21':
        return '2+1';
      case '31':
        return '3+1';
      case '41':
        return '4+1';
      case '51':
        return '5+1';
      case '251':
        return '2.5+1';
      case '151':
        return '1.5+1';
      case '42':
        return '4+2';
    }

    // Genel fallback:
    // - sadece rakamsa (örn: "32" -> "3+2")
    // - 3 haneli özel format (örn: "251" -> "2.5+1" yukarıda yakalandı, ama genelleyelim)
    if (RegExp(r'^\d+$').hasMatch(code)) {
      if (code.length == 2) {
        return '${code[0]}+${code[1]}';
      }
      if (code.length == 3) {
        // 151 => 1.5+1 gibi: ortadaki 5 ise ".5" kabul et
        final a = code[0];
        final b = code[1];
        final c = code[2];
        if (b == '5') return '$a.5+$c';
        return '$a$b+$c';
      }
      return code;
    }

    return null;
  }

  String get areaInfo {
    final m2NetRaw = properties['m2-net'];
    final m2BrutRaw = properties['m2-brut'];
    final m2Raw = properties['m2'];

    num? numberOf(dynamic raw) {
      if (raw is Map) {
        final v = raw['number_value'];
        if (v is num) return v;
        return num.tryParse(v?.toString() ?? '');
      }
      return null;
    }

    final m2Net = numberOf(m2NetRaw);
    final m2Brut = numberOf(m2BrutRaw);
    final m2 = numberOf(m2Raw);

    if (m2Net != null) {
      return '$m2Net m²';
    } else if (m2Brut != null) {
      return '$m2Brut m²';
    } else if (m2 != null) {
      return '$m2 m²';
    } else {
      return 'Bilinmiyor';
    }
  }

  String get statusText {
    switch (state.toUpperCase()) {
      case 'SOLD':
        return 'Satıldı';
      case 'RENTED':
        return 'Kiralandı';
      case 'LIVE':
        return 'Aktif';
      default:
        return state;
    }
  }

  String get typeText {
    switch (type.toLowerCase()) {
      case 'satilik':
        return 'SATILIK';
      case 'kiralik':
        return 'KİRALIK';
      default:
        return type.toUpperCase();
    }
  }

  // S3'ten resim URL'i oluşturma - ImageUtils kullanılacak
  String? get coverImageS3Id => coverPicture;
  String? get pictureS3Id => picture;

  // İlanları tarihe göre sıralama için DateTime dönüştürme
  DateTime get createdAtDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now(); // Hata durumunda şimdiki zaman
    }
  }

  /// Yayındaki ilan.
  bool get isActive => state.toUpperCase() == 'LIVE';

  /// Satıldı / kiralandı kartta PASİF gösterilmez; durum rozeti kullanılır.
  bool get showPassiveOverlay {
    switch (state.toUpperCase()) {
      case 'EXPIRED':
      case 'CANCELLED':
      case 'REJECTED':
      case 'DRAFT':
        return true;
      default:
        return false;
    }
  }
}

class TumIlanResponse {
  final List<TumIlanModel> listings;
  final int totalCount;
  final int totalPages;
  final int page;
  final bool hasMore;

  TumIlanResponse({
    required this.listings,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    this.hasMore = false,
  });

  factory TumIlanResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['listings'];
    final listings = <TumIlanModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        try {
          listings.add(
            TumIlanModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e) {
          print('⚠️ TumIlan parse atlandı: $e');
        }
      }
    }

    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    int pickInt(List<String> keys, int fallback) {
      for (final key in keys) {
        if (!json.containsKey(key) || json[key] == null) continue;
        final value = asInt(json[key], -1);
        if (value >= 0) return value;
      }
      return fallback;
    }

    return TumIlanResponse(
      listings: listings,
      totalCount: pickInt(
        ['totalCount', 'total_count', 'count', 'total'],
        0,
      ),
      totalPages: pickInt(
        ['totalPages', 'total_pages', 'pages'],
        0,
      ),
      page: pickInt(['page', 'currentPage', 'current_page'], 1),
      hasMore: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listings': listings.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
