/// Coupon Template Model - Kupon Şablonu modeli
/// API Endpoint: GET /api/zecorner/pay/coupon-templates

class CouponTemplateModel {
  final int id;
  final String name;
  final String description;
  final String type; // "FREE", "DISCOUNT"
  final String? code;
  final int? limit;
  final Map<String, dynamic>? data; // discount data
  final String? appliesTo; // "advisor", "training", null
  final int status; // 1 = aktif, 0 = pasif

  CouponTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.code,
    this.limit,
    this.data,
    this.appliesTo,
    required this.status,
  });

  factory CouponTemplateModel.fromJson(Map<String, dynamic> json) {
    return CouponTemplateModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      code: json['code'],
      limit: json['limit'],
      data: json['data'] as Map<String, dynamic>?,
      appliesTo: json['applies_to'],
      status: json['status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'code': code,
      'limit': limit,
      'data': data,
      'applies_to': appliesTo,
      'status': status,
    };
  }

  /// Durum kontrolleri
  bool get isActive => status == 1;

  /// UI için durum metni
  String get statusText => isActive ? 'Aktif' : 'Pasif';

  /// Tür metni (UI)
  String get typeText {
    switch (type.toUpperCase()) {
      case 'FREE':
        return 'Ücretsiz';
      case 'DISCOUNT':
        return 'İndirim';
      default:
        return type;
    }
  }

  /// İndirim detayı metni
  String get discountDetailText {
    if (type.toUpperCase() == 'FREE') {
      return '-';
    } else if (type.toUpperCase() == 'DISCOUNT' && data != null) {
      final amount = data!['amount'] ?? 0;
      final threshold = data!['threshold'] ?? 1;
      final discountType = data!['discount_type'] ?? 'percent';
      
      final maxD = data!['max_discount'];
      final capLine = (maxD != null && '$maxD'.isNotEmpty)
          ? '\nTavan: ${maxD}₺'
          : '';
      if (discountType == 'percent') {
        return '%$amount\nMin: ${threshold}₺$capLine';
      } else {
        return '$amount₺\nMin: ${threshold}₺$capLine';
      }
    }
    return '-';
  }

  /// Kupon türü kontrolleri
  bool get isFree => type.toUpperCase() == 'FREE';
  bool get isDiscount => type.toUpperCase() == 'DISCOUNT';

  @override
  String toString() {
    return 'CouponTemplateModel(id: $id, name: $name, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponTemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Coupon Template List Response
class CouponTemplateListResponse {
  final List<CouponTemplateModel> templates;

  CouponTemplateListResponse({required this.templates});

  factory CouponTemplateListResponse.fromJson(dynamic json) {
    // Eğer response direkt array ise
    if (json is List) {
      final templatesList = json
          .map((item) => CouponTemplateModel.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return CouponTemplateListResponse(templates: templatesList);
    }
    
    // Eğer response object ise
    if (json is Map<String, dynamic>) {
      final templatesList = (json['templates'] as List<dynamic>?)
          ?.map((item) => CouponTemplateModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      
      return CouponTemplateListResponse(templates: templatesList);
    }
    
    // Fallback
    return CouponTemplateListResponse(templates: []);
  }

  Map<String, dynamic> toJson() {
    return {
      'templates': templates.map((t) => t.toJson()).toList(),
    };
  }

  bool get isEmpty => templates.isEmpty;
}

