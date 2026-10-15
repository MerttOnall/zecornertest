/// Coupon Model - Kupon modeli
/// API Endpoint: GET /api/zecorner/pay/coupons

class CouponModel {
  final String id;
  final int contact;
  final int template;
  final int amount;
  final DateTime validUntil;
  final int status; // 1 = aktif, 0 = pasif
  final String name;
  final String? appliesTo; // "advisor", null
  final String type; // "FREE", "DISCOUNT"
  final Map<String, dynamic>? data; // discount data
  final String title; // Kullanıcı/Ofis adı

  CouponModel({
    required this.id,
    required this.contact,
    required this.template,
    required this.amount,
    required this.validUntil,
    required this.status,
    required this.name,
    this.appliesTo,
    required this.type,
    this.data,
    required this.title,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? '',
      contact: json['contact'] ?? 0,
      template: json['template'] ?? 0,
      amount: json['amount'] ?? 0,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : DateTime.now(),
      status: json['status'] ?? 0,
      name: json['name'] ?? '',
      appliesTo: json['applies_to'],
      type: json['type'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact,
      'template': template,
      'amount': amount,
      'valid_until': validUntil.toIso8601String(),
      'status': status,
      'name': name,
      'applies_to': appliesTo,
      'type': type,
      'data': data,
      'title': title,
    };
  }

  /// Durum kontrolleri
  bool get isActive => status == 1;
  bool get isExpired => validUntil.isBefore(DateTime.now());

  /// UI için durum metni
  String get statusText => isActive ? 'Aktif' : 'Pasif';

  /// Tür metni
  String get typeText {
    switch (type.toUpperCase()) {
      case 'FREE':
        return '%100 İndirim';
      case 'DISCOUNT':
        if (data != null && data!['discount_type'] == 'percent') {
          final discountAmount = data!['amount'] ?? 0;
          return '%$discountAmount İndirim';
        }
        return 'İndirim';
      default:
        return type;
    }
  }

  /// İndirim yüzdesi
  String get discountText {
    switch (type.toUpperCase()) {
      case 'FREE':
        return '%100';
      case 'DISCOUNT':
        if (data != null && data!['discount_type'] == 'percent') {
          final discountAmount = data!['amount'] ?? 0;
          return '%$discountAmount';
        }
        return '-';
      default:
        return '-';
    }
  }

  /// Kupon türü kontrolleri
  bool get isFree => type.toUpperCase() == 'FREE';
  bool get isDiscount => type.toUpperCase() == 'DISCOUNT';

  /// Kupon kullanılabilir mi?
  bool get isUsable => isActive && !isExpired && amount > 0;

  /// Display description (dropdown için)
  String get displayDescription {
    if (isFree) {
      return '$name - Ücretsiz';
    } else if (isDiscount && data != null) {
      if (data!['discount_type'] == 'percent') {
        return '$name - %${data!['amount']} İndirim';
      } else {
        return '$name - ${data!['amount']} TL İndirim';
      }
    }
    return name;
  }

  /// Discount data helper class
  CouponDiscountData? get discountData {
    if (data == null) return null;
    return CouponDiscountData.fromMap(data!);
  }

  @override
  String toString() {
    return 'CouponModel(id: $id, name: $name, type: $type, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CouponModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// API Response Model
class CouponResponse {
  final List<CouponModel> coupons;
  final int totalCount;
  final int totalPages;
  final int page;

  CouponResponse({
    required this.coupons,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory CouponResponse.fromJson(dynamic json) {
    // Eğer response direkt array ise
    if (json is List) {
      final couponsList = json
          .map((item) => CouponModel.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return CouponResponse(
        coupons: couponsList,
        totalCount: couponsList.length,
        totalPages: 1,
        page: 1,
      );
    }
    
    // Eğer response object ise
    if (json is Map<String, dynamic>) {
      final couponsList = (json['coupons'] as List<dynamic>?)
          ?.map((item) => CouponModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [];
      
      // Pagination bilgileri - farklı formatlarda gelebilir
      final totalCount = json['totalCount'] ?? 
                        json['total_count'] ?? 
                        json['total'] ?? 
                        couponsList.length;
      
      final totalPages = json['totalPages'] ?? 
                         json['total_pages'] ?? 
                         json['pages'] ?? 
                         1;
      
      final page = json['page'] ?? 
                   json['currentPage'] ?? 
                   json['current_page'] ?? 
                   1;
      
      return CouponResponse(
        coupons: couponsList,
        totalCount: totalCount is int ? totalCount : (totalCount as num).toInt(),
        totalPages: totalPages is int ? totalPages : (totalPages as num).toInt(),
        page: page is int ? page : (page as num).toInt(),
      );
    }
    
    // Fallback
    return CouponResponse(
      coupons: [],
      totalCount: 0,
      totalPages: 1,
      page: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coupons': coupons.map((c) => c.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }

  bool get hasMore => page < totalPages;
  bool get isEmpty => coupons.isEmpty;
}

/// Coupon Discount Data Helper
class CouponDiscountData {
  final double amount;
  final int threshold;
  final String discountType; // 'percent' or 'fixed'

  CouponDiscountData({
    required this.amount,
    required this.threshold,
    required this.discountType,
  });

  factory CouponDiscountData.fromMap(Map<String, dynamic> map) {
    return CouponDiscountData(
      amount: (map['amount'] ?? 0).toDouble(),
      threshold: map['threshold'] ?? 1,
      discountType: map['discount_type'] ?? 'percent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'threshold': threshold,
      'discount_type': discountType,
    };
  }
}

/// Coupon List Response (eski repository için)
class CouponListResponse {
  final List<CouponModel> coupons;

  CouponListResponse({required this.coupons});

  factory CouponListResponse.fromJson(Map<String, dynamic> json) {
    return CouponListResponse(
      coupons: (json['coupons'] as List<dynamic>?)
          ?.map((item) => CouponModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
