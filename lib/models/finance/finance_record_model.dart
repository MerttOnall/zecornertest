class FinanceRecord {
  final int id;
  final int contact;
  final String? amount;
  final String type;
  final int? relatedContact;
  final String? relatedListing;
  final String? relatedRealEstate;
  final DateTime createdAt;
  final String typeDescription;
  final bool isExpense;
  final String? description;
  final int office;
  final String officeTitle;

  FinanceRecord({
    required this.id,
    required this.contact,
    this.amount,
    required this.type,
    this.relatedContact,
    this.relatedListing,
    this.relatedRealEstate,
    required this.createdAt,
    required this.typeDescription,
    required this.isExpense,
    this.description,
    this.office = 0,
    this.officeTitle = '',
  });

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s;
  }

  static DateTime _asDate(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Next `/api/finance-add-expense/` yalnızca `{ result: { code, message } }` döner; liste hemen yenilenir.
  factory FinanceRecord.stubAfterNextAddExpense({
    required String type,
    required String description,
    required double amount,
  }) {
    return FinanceRecord(
      id: 0,
      contact: 0,
      amount: (-amount.abs()).toString(),
      type: type,
      createdAt: DateTime.now(),
      typeDescription: '',
      isExpense: true,
      description: description,
    );
  }

  /// BAMMA `/finance/records` kaydı.
  factory FinanceRecord.fromJson(Map<String, dynamic> json) {
    String? amountValue;
    final rawAmount = json['amount'];
    if (rawAmount != null) {
      amountValue = rawAmount is String ? rawAmount : rawAmount.toString();
    }

    final isExpense = json['is_expense'] == true ||
        json['is_expense'] == 1 ||
        json['is_expense']?.toString().toLowerCase() == 'true';

    return FinanceRecord(
      id: _asInt(json['id']),
      contact: _asInt(json['contact']),
      amount: amountValue,
      type: _asString(json['type']),
      relatedContact: _asIntOrNull(json['related_contact']),
      relatedListing: _asStringOrNull(json['related_listing']),
      relatedRealEstate: _asStringOrNull(json['related_real_estate']),
      createdAt: _asDate(json['created_at']),
      typeDescription: _asString(json['type_description']),
      isExpense: isExpense,
      description: _asStringOrNull(json['description']),
      office: _asInt(
        json['office'] ?? json['office_id'] ?? json['connected_contact'],
      ),
      officeTitle: _asString(
        json['office_title'] ??
            json['connected_contact_title'] ??
            json['ofis_contact_title'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact,
      'amount': amount ?? '0.00',
      'type': type,
      'related_contact': relatedContact,
      'related_listing': relatedListing,
      'related_real_estate': relatedRealEstate,
      'created_at': createdAt.toIso8601String(),
      'type_description': typeDescription,
      'is_expense': isExpense,
      'description': description,
    };
  }

  double get amountAsDouble {
    if (amount == null || amount!.isEmpty) return 0.0;
    return double.tryParse(amount!) ?? 0.0;
  }

  String get amountDisplay {
    if (amount == null || amount!.isEmpty) return '0.00';
    return amount!;
  }

  bool get isIncome => !isExpense;

  /// Kart / tablo için açıklama (boşsa tür).
  String get displayDescription {
    final d = description?.trim() ?? '';
    if (d.isNotEmpty) return d;
    if (typeDescription.trim().isNotEmpty) return typeDescription;
    return type;
  }
}

class FinanceResponse {
  final List<FinanceRecord> records;
  final int totalCount;
  final int totalPages;
  final int page;
  final String? sum;

  FinanceResponse({
    required this.records,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    this.sum,
  });

  factory FinanceResponse.fromJson(Map<String, dynamic> json) {
    String? sumValue;
    if (json['sum'] != null) {
      sumValue = json['sum'] is String ? json['sum'] as String : json['sum'].toString();
    }

    int asInt(dynamic v, [int fb = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fb;
    }

    final raw = json['records'];
    final list = <FinanceRecord>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        try {
          list.add(FinanceRecord.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }

    return FinanceResponse(
      records: list,
      totalCount: asInt(json['totalCount'] ?? json['total_count'], list.length),
      totalPages: asInt(json['totalPages'] ?? json['total_pages'], 1),
      page: asInt(json['page'], 1),
      sum: sumValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'records': records.map((record) => record.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
      'sum': sum,
    };
  }

  double get sumAsDouble {
    if (sum == null || sum!.isEmpty) return 0.0;
    return double.tryParse(sum!) ?? 0.0;
  }

  String get sumDisplay {
    if (sum == null || sum!.isEmpty) return '0.00';
    return sum!;
  }
}
