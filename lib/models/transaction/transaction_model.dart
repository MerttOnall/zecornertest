/// Transaction Model - Havale Onayları için
/// API: GET https://zecorner.com/api/get-transactions/

class TransactionModel {
  final int id;
  final int contact;
  final double amount;
  final String source;
  final Map<String, dynamic> detail;
  final DateTime date;
  final String state; // PENDING, APPROVED
  final DateTime? approvedOn;
  final int? approvedBy;
  final String? approvedTitle;
  final String? contactTitle;
  final String? approverTitle;
  final String? invoiceNumber;

  TransactionModel({
    required this.id,
    required this.contact,
    required this.amount,
    required this.source,
    required this.detail,
    required this.date,
    required this.state,
    this.approvedOn,
    this.approvedBy,
    this.approvedTitle,
    this.contactTitle,
    this.approverTitle,
    this.invoiceNumber,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'] is Map
        ? Map<String, dynamic>.from(json['detail'] as Map)
        : <String, dynamic>{};

    String? invoiceNo;
    final rawInvoice = json['invoice_number'];
    if (rawInvoice != null && rawInvoice.toString().trim().isNotEmpty) {
      invoiceNo = rawInvoice.toString();
    } else {
      final fromDetail = detail['invoice_id'] ?? detail['qnb_invoice_id'];
      if (fromDetail != null && fromDetail.toString().trim().isNotEmpty) {
        invoiceNo = fromDetail.toString();
      }
    }

    return TransactionModel(
      id: _asInt(json['id']),
      contact: _asInt(json['contact']),
      amount: _parseAmount(json['amount']),
      source: json['source']?.toString() ?? 'transfer',
      detail: detail,
      date: _asDate(json['date']) ?? DateTime.now(),
      state: json['state']?.toString() ?? 'PENDING',
      approvedOn: _asDate(json['approved_on']),
      approvedBy: json['approved_by'] == null
          ? null
          : _asInt(json['approved_by']),
      approvedTitle: _normalizeTitle(json['approved_title']),
      contactTitle: _normalizeTitle(
        json['contact_title'] ??
            json['ofis_contact_title'] ??
            json['connected_contact_title'] ??
            json['title'],
      ),
      approverTitle: _normalizeTitle(
        json['approver_title'] ??
            json['approved_by_title'] ??
            json['approver_name'],
      ),
      invoiceNumber: invoiceNo,
    );
  }

  TransactionModel copyWith({
    String? contactTitle,
    String? approverTitle,
    String? approvedTitle,
  }) {
    return TransactionModel(
      id: id,
      contact: contact,
      amount: amount,
      source: source,
      detail: detail,
      date: date,
      state: state,
      approvedOn: approvedOn,
      approvedBy: approvedBy,
      approvedTitle: approvedTitle ?? this.approvedTitle,
      contactTitle: contactTitle ?? this.contactTitle,
      approverTitle: approverTitle ?? this.approverTitle,
      invoiceNumber: invoiceNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact,
      'amount': amount.toString(),
      'source': source,
      'detail': detail,
      'date': date.toIso8601String(),
      'state': state,
      'approved_on': approvedOn?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_title': approvedTitle,
      'contact_title': contactTitle,
      'approver_title': approverTitle,
      'invoice_number': invoiceNumber,
    };
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      return double.tryParse(amount.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  static String? _normalizeTitle(dynamic value) {
    if (value == null) return null;
    final text = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty || text == 'null') return null;
    return text;
  }

  bool get isPending => state.toUpperCase() == 'PENDING';
  bool get isApproved => state.toUpperCase() == 'APPROVED';
  bool get isRejected => state.toUpperCase() == 'REJECTED';

  String get paymentMethod {
    switch (source.toLowerCase().trim()) {
      case 'transfer':
      case 'eft':
      case 'havale':
        return 'Havale/EFT';
      case 'card':
      case 'creditcard':
      case 'credit_card':
        return 'Kredi Kartı';
      default:
        if (source.toLowerCase().contains('card')) return 'Kredi Kartı';
        if (source.toLowerCase().contains('transfer') ||
            source.toLowerCase().contains('havale')) {
          return 'Havale/EFT';
        }
        return source;
    }
  }

  String get stateText {
    switch (state.toUpperCase()) {
      case 'PENDING':
        return 'Bekleyen';
      case 'APPROVED':
        return 'Onaylandı';
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
        return 'İptal';
      default:
        return state;
    }
  }

  String get displayInvoiceNumber => invoiceNumber ?? '—';

  String get userOrOfficeDisplay {
    final fromContact = _normalizeTitle(contactTitle);
    if (fromContact != null) return fromContact;
    // Kredi kartı otomatik onayında approved_title genelde ödeme yapan kişidir.
    if (paymentMethod == 'Kredi Kartı') {
      final payer = _normalizeTitle(approvedTitle);
      if (payer != null) return payer;
    }
    if (contact > 0) return 'Kullanıcı #$contact';
    return '—';
  }

  String get approverDisplay {
    if (!isApproved) return '—';
    final fromApprover = _normalizeTitle(approverTitle);
    if (fromApprover != null) return fromApprover;
    final fromApproved = _normalizeTitle(approvedTitle);
    if (fromApproved != null) return fromApproved;
    if (approvedBy != null && approvedBy! > 0) return 'Kullanıcı #$approvedBy';
    return '—';
  }

  String get approvalDateDisplay {
    if (approvedOn == null) return '—';
    return _formatDateTime(approvedOn!);
  }

  static String _formatDateTime(DateTime date) {
    final d = date.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String get formattedDate => _formatDateTime(date);

  bool get needsContactLookup =>
      _normalizeTitle(contactTitle) == null && contact > 0;

  bool matchesStatus(String filter) {
    switch (filter) {
      case 'Bekleyen':
        return isPending;
      case 'Onaylandı':
      case 'Onaylanmış':
        return isApproved;
      case 'İptal':
        return isRejected ||
            state.toUpperCase() == 'CANCELLED' ||
            state.toUpperCase() == 'CANCELED';
      case 'Tümü':
      case '':
        return true;
      default:
        return stateText == filter || state.toUpperCase() == filter.toUpperCase();
    }
  }

  bool matchesPayment(String filter) {
    if (filter.isEmpty || filter == 'Tümü') return true;
    return paymentMethod == filter;
  }

  bool matchesQuery(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return true;
    final folded = _fold(raw);
    final haystack = _fold([
      displayInvoiceNumber,
      id.toString(),
      userOrOfficeDisplay,
      approverDisplay,
      paymentMethod,
      stateText,
      amount.toStringAsFixed(2),
      formattedDate,
      approvalDateDisplay,
    ].join(' '));
    if (haystack.contains(folded)) return true;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) return false;
    final invoiceDigits = displayInvoiceNumber.replaceAll(RegExp(r'\D'), '');
    return invoiceDigits.contains(digits) || id.toString().contains(digits);
  }

  static String _fold(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }
}

/// BAMMA/Next bazen `{ transactions, totalCount }` kökte, bazen `data` / `result` içinde döner.
Map<String, dynamic>? extractTransactionResponseJson(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    return {
      'transactions': data,
      'totalCount': data.length,
      'totalPages': 1,
      'page': 1,
    };
  }
  if (data is! Map) return null;
  final map = Map<String, dynamic>.from(data);

  if (map['transactions'] is List) return map;

  for (final key in ['data', 'result', 'payload']) {
    final nested = extractTransactionResponseJson(map[key]);
    if (nested != null) return nested;
  }
  return null;
}

class TransactionResponse {
  final List<TransactionModel> transactions;
  final int totalCount;
  final int totalPages;
  final int page;

  TransactionResponse({
    required this.transactions,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory TransactionResponse.fromJson(dynamic json) {
    final root = extractTransactionResponseJson(json) ??
        (json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{});
    final rawList = root['transactions'];
    final transactions = <TransactionModel>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is! Map) continue;
        try {
          transactions.add(
            TransactionModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          continue;
        }
      }
    }

    final totalPages = _asInt(root['totalPages'] ?? root['total_pages']);
    final page = _asInt(root['page']);

    return TransactionResponse(
      transactions: transactions,
      totalCount: _asInt(root['totalCount'] ?? root['total_count']),
      totalPages: totalPages == 0 ? 1 : totalPages,
      page: page == 0 ? 1 : page,
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
