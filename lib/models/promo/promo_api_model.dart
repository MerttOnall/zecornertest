class PromoApiModel {
  final int id;
  final String name;
  final String type;
  final int status;
  final String promoCode;
  final String promoRate;
  final String promoMinSpend;
  final DateTime startDate;
  final DateTime? endDate;
  final String promoScope;
  final String promoRules;
  final String? promoNotes;
  final String? bannerPicture;
  final List<int> targetContactTypes;
  final int notificationType;
  final DateTime createdAt;
  final int createdBy;
  final String brand;
  final List<String> categories;
  final String? campaignFile;

  PromoApiModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.promoCode,
    required this.promoRate,
    required this.promoMinSpend,
    required this.startDate,
    this.endDate,
    required this.promoScope,
    required this.promoRules,
    this.promoNotes,
    this.bannerPicture,
    required this.targetContactTypes,
    required this.notificationType,
    required this.createdAt,
    required this.createdBy,
    required this.brand,
    required this.categories,
    this.campaignFile,
  });

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static List<int> _asIntList(dynamic v) {
    if (v is! List) return const [];
    return v.map(_asInt).toList();
  }

  static List<String> _asStringList(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }

  factory PromoApiModel.fromJson(Map<String, dynamic> json) {
    final start = _asDate(json['start_date']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final created = _asDate(json['created_at']) ?? start;
    return PromoApiModel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      type: _asString(json['type']),
      status: _asInt(json['status']),
      promoCode: _asString(json['promo_code']),
      promoRate: _asString(json['promo_rate']),
      promoMinSpend: _asString(json['promo_min_spend']),
      startDate: start,
      endDate: _asDate(json['end_date']),
      promoScope: _asString(json['promo_scope']),
      promoRules: _asString(json['promo_rules']),
      promoNotes: json['promo_notes']?.toString(),
      bannerPicture: json['banner_picture']?.toString(),
      targetContactTypes: _asIntList(json['target_contact_types']),
      notificationType: _asInt(json['notification_type']),
      createdAt: created,
      createdBy: _asInt(json['created_by']),
      brand: _asString(json['brand']),
      categories: _asStringList(json['categories']),
      campaignFile: json['campaign_file']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'promo_code': promoCode,
      'promo_rate': promoRate,
      'promo_min_spend': promoMinSpend,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'promo_scope': promoScope,
      'promo_rules': promoRules,
      'promo_notes': promoNotes,
      'banner_picture': bannerPicture,
      'target_contact_types': targetContactTypes,
      'notification_type': notificationType,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'brand': brand,
      'categories': categories,
      'campaign_file': campaignFile,
    };
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isActive => status == 1;

  String get statusText {
    if (isExpired) return 'Tarihi Geçti!';
    if (isActive) return 'Aktif';
    return 'Pasif';
  }

  /// API kayıt durumu (Aktif/Pasif); süre dolumu [isExpired] ile karıştırılmaz.
  String get recordStatusLabel => isActive ? 'Aktif' : 'Pasif';

  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }

  String get formattedEndDate {
    if (endDate == null) return 'Süresiz';
    return '${endDate!.day}/${endDate!.month}/${endDate!.year}';
  }

  String get categoryDisplay {
    if (categories.isEmpty) return 'Diğer';
    return categories.first.toUpperCase();
  }

  String get discountDisplay {
    if (promoRate.isNotEmpty) return promoRate;
    return 'Özel Fiyat';
  }

  String get description {
    if (promoMinSpend.isNotEmpty) {
      return '$promoMinSpend ve üzeri alışverişte';
    }
    if (promoScope.isNotEmpty) {
      return promoScope;
    }
    return brand;
  }

  /// UI’da gösterilen tür etiketi (API `type` değerleri).
  String get typeDisplayLabel {
    switch (type.toLowerCase().replaceAll('_', '-').trim()) {
      case 'percent-sale':
        return 'Yüzdelik İndirim';
      case 'price-cut':
      case 'price-sale':
        return 'Fiyat İndirimi';
      case 'promo-code':
      case 'discount-code':
        return 'Promosyon Kodu';
      case 'gift-card':
      case 'gift-voucher':
        return 'Hediye Kartı';
      default:
        return type.isEmpty ? 'Diğer' : type;
    }
  }
}

class PromoResponse {
  final List<PromoApiModel> promos;
  final int totalCount;
  final int totalPages;
  final int page;
  final Map<String, dynamic> req;

  PromoResponse({
    required this.promos,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    required this.req,
  });

  factory PromoResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['promos'];
    final list = <PromoApiModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        try {
          list.add(PromoApiModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Tek bozuk kayıt tüm listeyi düşürmesin
        }
      }
    }

    int asInt(dynamic v, [int fb = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fb;
    }

    return PromoResponse(
      promos: list,
      totalCount: asInt(json['totalCount'], list.length),
      totalPages: asInt(json['totalPages'], 1),
      page: asInt(json['page'], 1),
      req: json['req'] is Map
          ? Map<String, dynamic>.from(json['req'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promos': promos.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
      'req': req,
    };
  }
}
