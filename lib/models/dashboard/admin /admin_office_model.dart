class AdminOfficeModel {
  final List<OfficeItem> offices;
  final int page;
  final int totalCount;
  final int totalPages;

  AdminOfficeModel({
    required this.offices,
    required this.page,
    required this.totalCount,
    required this.totalPages,
  });

  factory AdminOfficeModel.fromJson(dynamic json) {
    // API: { "offices": [...], "page": 1, "totalCount": 31, "totalPages": 4 } veya { "data": { ... } } sarmalı
    List<OfficeItem> offices = [];
    int page = 1, totalCount = 0, totalPages = 1;

    if (json is List) {
      for (final e in json) {
        if (e is Map) {
          try {
            offices.add(OfficeItem.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
      return AdminOfficeModel(offices: offices, page: page, totalCount: totalCount, totalPages: totalPages);
    }

    if (json is! Map) {
      return AdminOfficeModel(offices: [], page: 1, totalCount: 0, totalPages: 1);
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(json);

    // Önce root'ta "offices" var mı bak (senin API formatın)
    List? officesList = map['offices'] is List ? map['offices'] as List : null;
    Map<String, dynamic> dataForPagination = map;

    if (officesList == null && map['data'] is Map) {
      final data = Map<String, dynamic>.from(map['data'] as Map);
      officesList = data['offices'] is List ? data['offices'] as List : (data['data'] is List ? data['data'] as List : null);
      dataForPagination = data;
    }
    if (officesList == null && map['result'] is Map) {
      final data = Map<String, dynamic>.from(map['result'] as Map);
      officesList = data['offices'] is List ? data['offices'] as List : null;
      dataForPagination = data;
    }

    if (officesList != null) {
      for (final e in officesList) {
        if (e is Map) {
          try {
            offices.add(OfficeItem.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
    }

    final data = dataForPagination;
    page = data['page'] is int ? data['page'] as int : (int.tryParse(data['page']?.toString() ?? '1') ?? 1);
    totalCount = data['totalCount'] is int ? data['totalCount'] as int : (int.tryParse(data['totalCount']?.toString() ?? '0') ?? 0);
    totalPages = data['totalPages'] is int ? data['totalPages'] as int : (int.tryParse(data['totalPages']?.toString() ?? '1') ?? 1);

    return AdminOfficeModel(offices: offices, page: page, totalCount: totalCount, totalPages: totalPages);
  }

  Map<String, dynamic> toJson() {
    return {
      'offices': offices.map((office) => office.toJson()).toList(),
      'page': page,
      'totalCount': totalCount,
      'totalPages': totalPages,
    };
  }

  /// En yüksek gelirli ofisleri döndür
  List<OfficeItem> get topOffices {
    final sortedOffices = List<OfficeItem>.from(offices);
    sortedOffices.sort((a, b) => (b.revenue ?? 0).compareTo(a.revenue ?? 0));
    return sortedOffices.take(3).toList();
  }

  /// Haftanın ofisi (en yüksek gelirli)
  OfficeItem? get officeOfTheWeek => topOffices.isNotEmpty ? topOffices[0] : null;

  /// Ayın ofisi (ikinci en yüksek gelirli)
  OfficeItem? get officeOfTheMonth => topOffices.length > 1 ? topOffices[1] : null;

  /// Yılın ofisi (üçüncü en yüksek gelirli)
  OfficeItem? get officeOfTheYear => topOffices.length > 2 ? topOffices[2] : null;

  @override
  String toString() {
    return 'AdminOfficeModel(offices: $offices, page: $page, totalCount: $totalCount, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminOfficeModel &&
        other.offices == offices &&
        other.page == page &&
        other.totalCount == totalCount &&
        other.totalPages == totalPages;
  }

  @override
  int get hashCode {
    return offices.hashCode ^
        page.hashCode ^
        totalCount.hashCode ^
        totalPages.hashCode;
  }
}

class OfficeItem {
  final int office;
  final String officeTitle;
  final double? revenue;
  final int? region;
  final String? lastTransaction;

  OfficeItem({
    required this.office,
    required this.officeTitle,
    this.revenue,
    this.region,
    this.lastTransaction,
  });

  /// Aynı ofis, lastTransaction güncellenmiş kopya (advisors verisinden doldurmak için)
  OfficeItem copyWith({String? lastTransaction}) {
    return OfficeItem(
      office: office,
      officeTitle: officeTitle,
      revenue: revenue,
      region: region,
      lastTransaction: lastTransaction ?? this.lastTransaction,
    );
  }

  /// API'den gelen son işlem tarihi - birden fazla alan adı ve tip desteklenir (T sol=tarih, sağ=saat)
  static String? _parseLastTransaction(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value.trim();
    if (value is int) {
      if (value > 10000000000) return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
      return DateTime.fromMillisecondsSinceEpoch(value * 1000).toIso8601String();
    }
    if (value is num) {
      final n = value.toInt();
      if (n > 10000000000) return DateTime.fromMillisecondsSinceEpoch(n).toIso8601String();
      return DateTime.fromMillisecondsSinceEpoch(n * 1000).toIso8601String();
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      final v = value['value'] ?? value['dateTime'] ?? value['date'];
      if (v != null) return _parseLastTransaction(v);
      final date = value['date'];
      final time = value['time'];
      if (date != null && time != null) return '$date${time.toString().startsWith('T') ? time : 'T$time'}';
    }
    return null;
  }

  static int _parseOfficeId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  factory OfficeItem.fromJson(Map<String, dynamic> json) {
    // Son işlem tarihi: doğrudan alanlarda veya stats/meta içinde (API bağlantısı)
    dynamic lastTransaction = json['last_transaction'] ??
        json['lastTransaction'] ??
        json['last_transaction_date'] ??
        json['last_transaction_at'] ??
        json['updated_at'] ??
        json['last_activity'] ??
        json['son_islem_tarihi'];
    if (lastTransaction == null && json['stats'] is Map) {
      final stats = json['stats'] as Map;
      lastTransaction = stats['last_transaction'] ?? stats['last_transaction_date'];
    }
    if (lastTransaction == null && json['meta'] is Map) {
      final meta = json['meta'] as Map;
      lastTransaction = meta['last_transaction'] ?? meta['last_transaction_date'];
    }
    return OfficeItem(
      office: OfficeItem._parseOfficeId(json['office']),
      officeTitle: (json['office_title'] ?? json['officeTitle'] ?? '').toString().trim(),
      revenue: json['revenue'] != null ? double.tryParse(json['revenue'].toString()) : null,
      region: json['region'] is int ? json['region'] as int? : int.tryParse(json['region']?.toString() ?? ''),
      lastTransaction: OfficeItem._parseLastTransaction(lastTransaction),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office': office,
      'office_title': officeTitle,
      'revenue': revenue?.toString(),
      'region': region,
      'last_transaction': lastTransaction,
    };
  }

  @override
  String toString() {
    return 'OfficeItem(office: $office, officeTitle: $officeTitle, revenue: $revenue, region: $region, lastTransaction: $lastTransaction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeItem &&
        other.office == office &&
        other.officeTitle == officeTitle &&
        other.revenue == revenue &&
        other.region == region &&
        other.lastTransaction == lastTransaction;
  }

  @override
  int get hashCode {
    return office.hashCode ^
        officeTitle.hashCode ^
        revenue.hashCode ^
        region.hashCode ^
        lastTransaction.hashCode;
  }
}
