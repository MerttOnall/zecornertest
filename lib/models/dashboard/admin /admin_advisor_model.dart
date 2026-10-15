class AdminAdvisorModel {
  final List<AdvisorItem> advisors;
  final int page;
  final int totalCount;
  final int totalPages;

  AdminAdvisorModel({
    required this.advisors,
    required this.page,
    required this.totalCount,
    required this.totalPages,
  });

  factory AdminAdvisorModel.fromJson(Map<String, dynamic> json) {
    // API farklı sarmalayıcılarla dönebilir: data, result, body veya doğrudan json (son işlem tarihi fallback için)
    final Map<String, dynamic> data = (json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : null) ??
        (json['result'] is Map ? Map<String, dynamic>.from(json['result'] as Map) : null) ??
        (json['body'] is Map ? Map<String, dynamic>.from(json['body'] as Map) : null) ??
        json;
    final advisorsList = data['advisors'] ?? (data['data'] is List ? data['data'] : null);
    final List<AdvisorItem> advisors = [];
    if (advisorsList is List) {
      for (final e in advisorsList) {
        if (e is Map) {
          try {
            advisors.add(AdvisorItem.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {}
        }
      }
    }
    return AdminAdvisorModel(
      advisors: advisors,
      page: (data['page'] is int)
          ? data['page'] as int
          : int.tryParse(data['page']?.toString() ?? '1') ?? 1,
      totalCount: (data['totalCount'] is int)
          ? data['totalCount'] as int
          : int.tryParse(data['totalCount']?.toString() ?? '0') ?? 0,
      totalPages: (data['totalPages'] is int)
          ? data['totalPages'] as int
          : int.tryParse(data['totalPages']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisors': advisors.map((advisor) => advisor.toJson()).toList(),
      'page': page,
      'totalCount': totalCount,
      'totalPages': totalPages,
    };
  }

  /// En yüksek gelirli danışmanları döndür
  List<AdvisorItem> get topAdvisors {
    final sortedAdvisors = List<AdvisorItem>.from(advisors);
    sortedAdvisors.sort((a, b) => (b.revenue ?? 0).compareTo(a.revenue ?? 0));
    return sortedAdvisors.take(3).toList();
  }

  /// Haftanın danışmanı (en yüksek gelirli)
  AdvisorItem? get advisorOfTheWeek => topAdvisors.isNotEmpty ? topAdvisors[0] : null;

  /// Ayın danışmanı (ikinci en yüksek gelirli)
  AdvisorItem? get advisorOfTheMonth => topAdvisors.length > 1 ? topAdvisors[1] : null;

  /// Yılın danışmanı (üçüncü en yüksek gelirli)
  AdvisorItem? get advisorOfTheYear => topAdvisors.length > 2 ? topAdvisors[2] : null;

  @override
  String toString() {
    return 'AdminAdvisorModel(advisors: $advisors, page: $page, totalCount: $totalCount, totalPages: $totalPages)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminAdvisorModel &&
        other.advisors == advisors &&
        other.page == page &&
        other.totalCount == totalCount &&
        other.totalPages == totalPages;
  }

  @override
  int get hashCode {
    return advisors.hashCode ^
        page.hashCode ^
        totalCount.hashCode ^
        totalPages.hashCode;
  }
}

class AdvisorItem {
  final int advisor;
  final String advisorTitle;
  final int? office;
  final String? officeTitle;
  final int? type;
  final String? typeDescription;
  final double? revenue;
  final String? lastTransaction;

  AdvisorItem({
    required this.advisor,
    required this.advisorTitle,
    this.office,
    this.officeTitle,
    this.type,
    this.typeDescription,
    this.revenue,
    this.lastTransaction,
  });

  /// API'den gelen son işlem tarihi - birden fazla alan adı ve tip desteklenir
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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString().trim());
  }

  factory AdvisorItem.fromJson(Map<String, dynamic> json) {
    final lastTransaction = json['last_transaction'] ??
        json['lastTransaction'] ??
        json['last_transaction_date'] ??
        json['last_transaction_at'] ??
        json['updated_at'] ??
        json['last_activity'] ??
        json['son_islem_tarihi'];
    return AdvisorItem(
      advisor: AdvisorItem._parseInt(json['advisor']) ?? 0,
      advisorTitle: (json['advisor_title'] ?? json['advisorTitle'] ?? '').toString().trim(),
      office: AdvisorItem._parseInt(json['office']),
      officeTitle: json['office_title']?.toString() ?? json['officeTitle']?.toString(),
      type: AdvisorItem._parseInt(json['type']),
      typeDescription: json['type_description']?.toString() ?? json['typeDescription']?.toString(),
      revenue: json['revenue'] != null ? double.tryParse(json['revenue'].toString()) : null,
      lastTransaction: AdvisorItem._parseLastTransaction(lastTransaction),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisor': advisor,
      'advisor_title': advisorTitle,
      'office': office,
      'office_title': officeTitle,
      'type': type,
      'type_description': typeDescription,
      'revenue': revenue?.toString(),
      'last_transaction': lastTransaction,
    };
  }

  @override
  String toString() {
    return 'AdvisorItem(advisor: $advisor, advisorTitle: $advisorTitle, office: $office, officeTitle: $officeTitle, type: $type, typeDescription: $typeDescription, revenue: $revenue, lastTransaction: $lastTransaction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvisorItem &&
        other.advisor == advisor &&
        other.advisorTitle == advisorTitle &&
        other.office == office &&
        other.officeTitle == officeTitle &&
        other.type == type &&
        other.typeDescription == typeDescription &&
        other.revenue == revenue &&
        other.lastTransaction == lastTransaction;
  }

  @override
  int get hashCode {
    return advisor.hashCode ^
        advisorTitle.hashCode ^
        office.hashCode ^
        officeTitle.hashCode ^
        type.hashCode ^
        typeDescription.hashCode ^
        revenue.hashCode ^
        lastTransaction.hashCode;
  }
}
