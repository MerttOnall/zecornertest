// Invoice Model - Fatura modeli
// API: BAMMA `GET /pay/invoices` (Next proxy: `/api/zecorner/pay/invoices` veya `/api/get-invoices/`)

class InvoiceModel {
  final String id;
  final int contact;
  final String contactTitle;
  final DateTime date;
  final DateTime? due;
  final DateTime? paidDate;
  final String type;
  final String typeDescription;
  final String invoiceNumber;
  final double amount;
  final Map<String, dynamic>? metaData;
  final String state;
  final int status;
  final double paidAmount;
  final String? paymentSource;
  final String? ofisContactTitle;

  InvoiceModel({
    required this.id,
    required this.contact,
    required this.contactTitle,
    required this.date,
    this.due,
    this.paidDate,
    required this.type,
    required this.typeDescription,
    required this.invoiceNumber,
    required this.amount,
    this.metaData,
    required this.state,
    required this.status,
    this.paidAmount = 0,
    this.paymentSource,
    this.ofisContactTitle,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      contact: _asInt(json['contact']),
      contactTitle: json['contact_title']?.toString() ??
          json['ofis_contact_title']?.toString() ??
          '',
      date: _asDate(json['date']) ?? DateTime.now(),
      due: _asDate(json['due']),
      paidDate: _asDate(json['paid_date']),
      type: json['type']?.toString() ?? '',
      typeDescription: json['type_description']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      metaData: json['meta_data'] is Map
          ? Map<String, dynamic>.from(json['meta_data'] as Map)
          : null,
      state: json['state']?.toString() ?? 'PENDING',
      status: _asInt(json['status']),
      paidAmount: _parseAmount(json['paid_amount']),
      paymentSource: json['payment_source']?.toString(),
      ofisContactTitle: json['ofis_contact_title']?.toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact,
      'contact_title': contactTitle,
      'date': date.toIso8601String(),
      'due': due?.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'type': type,
      'type_description': typeDescription,
      'invoice_number': invoiceNumber,
      'amount': amount.toString(),
      'meta_data': metaData,
      'state': state,
      'status': status,
      'paid_amount': paidAmount.toString(),
      'payment_source': paymentSource,
      'ofis_contact_title': ofisContactTitle,
    };
  }

  /// Durum kontrolleri
  bool get isPaid => state.toUpperCase() == 'PAID';
  bool get isPending => state.toUpperCase() == 'PENDING';
  bool get isCancelled => state.toUpperCase() == 'CANCELLED';
  bool get isNotPaid => state.toUpperCase() == 'NOT_PAID';
  bool get isAwaitingPayment => state.toUpperCase() == 'AWAITING_PAYMENT';

  /// UI için durum metni
  String get stateText {
    switch (state.toUpperCase()) {
      case 'PAID':
        return 'Ödendi';
      case 'NOT_PAID':
        return 'Ödenmedi';
      case 'PENDING':
        return 'Bekliyor';
      case 'CANCELLED':
        return 'İptal';
      case 'AWAITING_PAYMENT':
        return 'Havale';
      default:
        return state;
    }
  }

  /// Fatura türü için ikon belirleme
  String get typeIcon {
    switch (type) {
      case 'training':
        return 'school';
      case 'advisor':
        return 'person_add';
      case 'monthly':
        return 'calendar_month';
      case 'franchise':
        return 'business';
      case 'event':
        return 'event';
      default:
        return 'receipt_long';
    }
  }

  @override
  String toString() {
    return 'InvoiceModel(id: $id, contactTitle: $contactTitle, amount: $amount, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvoiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class InvoiceAmounts {
  final double totalAmount;
  final double billedAmount;
  final double paidAmount;

  const InvoiceAmounts({
    this.totalAmount = 0,
    this.billedAmount = 0,
    this.paidAmount = 0,
  });

  factory InvoiceAmounts.fromJson(dynamic json) {
    if (json is! Map) return const InvoiceAmounts();
    final map = Map<String, dynamic>.from(json);
    return InvoiceAmounts(
      totalAmount: InvoiceModel._parseAmount(map['total_amount']),
      billedAmount: InvoiceModel._parseAmount(map['billed_amount']),
      paidAmount: InvoiceModel._parseAmount(map['paid_amount']),
    );
  }
}

/// BAMMA/Next bazen `{ invoices, totalCount }` kökte, bazen `data` / `result` içinde döner.
Map<String, dynamic>? extractInvoiceResponseJson(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    return {
      'invoices': data,
      'totalCount': data.length,
      'totalPages': 1,
      'page': 1,
    };
  }
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);

  if (map['invoices'] is List) return map;

  for (final key in ['data', 'result', 'payload']) {
    final nested = extractInvoiceResponseJson(map[key]);
    if (nested != null) return nested;
  }
  return null;
}

/// API Response Model
class InvoiceResponse {
  final List<InvoiceModel> invoices;
  final int totalCount;
  final int totalPages;
  final int page;
  final InvoiceAmounts amounts;

  InvoiceResponse({
    required this.invoices,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    this.amounts = const InvoiceAmounts(),
  });

  factory InvoiceResponse.fromJson(dynamic json) {
    final root = extractInvoiceResponseJson(json) ??
        (json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{});
    final rawList = root['invoices'];
    final invoices = <InvoiceModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        try {
          invoices.add(InvoiceModel.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          continue;
        }
      }
    }

    return InvoiceResponse(
      invoices: invoices,
      totalCount: InvoiceModel._asInt(root['totalCount'] ?? root['total_count']),
      totalPages: InvoiceModel._asInt(root['totalPages'] ?? root['total_pages']) == 0
          ? 1
          : InvoiceModel._asInt(root['totalPages'] ?? root['total_pages']),
      page: InvoiceModel._asInt(root['page']) == 0
          ? 1
          : InvoiceModel._asInt(root['page']),
      amounts: InvoiceAmounts.fromJson(root['amounts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoices': invoices.map((i) => i.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }

  bool get hasMore => page < totalPages;
  bool get isEmpty => invoices.isEmpty;
}
