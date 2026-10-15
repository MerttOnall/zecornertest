class AdvisorTotalsModel {
  final int contact;
  final int active;
  final int forSale;
  final int forRent;
  final int sold;
  final int rented;
  final int rejected;
  final int cancelled;
  final int changesRequired;
  final int waitingForApproval;
  final int expired;
  final int draft;
  final int customers;
  final int office;
  final List<RevenueModel> revenue;
  final ProgressModel progress;

  AdvisorTotalsModel({
    required this.contact,
    required this.active,
    required this.forSale,
    required this.forRent,
    required this.sold,
    required this.rented,
    required this.rejected,
    required this.cancelled,
    required this.changesRequired,
    required this.waitingForApproval,
    required this.expired,
    required this.draft,
    required this.customers,
    required this.office,
    required this.revenue,
    required this.progress,
  });

  factory AdvisorTotalsModel.fromJson(Map<String, dynamic> json) {
    // API'den gelen değerler string olarak geliyor, int'e parse et
    return AdvisorTotalsModel(
      contact: json['contact'] is int ? json['contact'] : (int.tryParse(json['contact']?.toString() ?? '0') ?? 0),
      active: json['active'] is int ? json['active'] : (int.tryParse(json['active']?.toString() ?? '0') ?? 0),
      forSale: json['for_sale'] is int ? json['for_sale'] : (int.tryParse(json['for_sale']?.toString() ?? '0') ?? 0),
      forRent: json['for_rent'] is int ? json['for_rent'] : (int.tryParse(json['for_rent']?.toString() ?? '0') ?? 0),
      sold: json['sold'] is int ? json['sold'] : (int.tryParse(json['sold']?.toString() ?? '0') ?? 0),
      rented: json['rented'] is int ? json['rented'] : (int.tryParse(json['rented']?.toString() ?? '0') ?? 0),
      rejected: json['rejected'] is int ? json['rejected'] : (int.tryParse(json['rejected']?.toString() ?? '0') ?? 0),
      cancelled: json['cancelled'] is int ? json['cancelled'] : (int.tryParse(json['cancelled']?.toString() ?? '0') ?? 0),
      changesRequired: json['changes_required'] is int ? json['changes_required'] : (int.tryParse(json['changes_required']?.toString() ?? '0') ?? 0),
      waitingForApproval: json['waiting_for_approval'] is int ? json['waiting_for_approval'] : (int.tryParse(json['waiting_for_approval']?.toString() ?? '0') ?? 0),
      expired: json['expired'] is int ? json['expired'] : (int.tryParse(json['expired']?.toString() ?? '0') ?? 0),
      draft: json['draft'] is int ? json['draft'] : (int.tryParse(json['draft']?.toString() ?? '0') ?? 0),
      customers: json['customers'] is int ? json['customers'] : (int.tryParse(json['customers']?.toString() ?? '0') ?? 0),
      office: json['office'] is int ? json['office'] : (int.tryParse(json['office']?.toString() ?? '0') ?? 0),
      revenue: (json['revenue'] as List<dynamic>?)
              ?.map((e) => RevenueModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      progress: ProgressModel.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact': contact,
      'active': active,
      'for_sale': forSale,
      'for_rent': forRent,
      'sold': sold,
      'rented': rented,
      'rejected': rejected,
      'cancelled': cancelled,
      'changes_required': changesRequired,
      'waiting_for_approval': waitingForApproval,
      'expired': expired,
      'draft': draft,
      'customers': customers,
      'office': office,
      'revenue': revenue.map((e) => e.toJson()).toList(),
      'progress': progress.toJson(),
    };
  }

  @override
  String toString() {
    return 'AdvisorTotalsModel(contact: $contact, active: $active, forSale: $forSale, forRent: $forRent, sold: $sold, rented: $rented, rejected: $rejected, cancelled: $cancelled, changesRequired: $changesRequired, waitingForApproval: $waitingForApproval, expired: $expired, draft: $draft, customers: $customers, office: $office, revenue: $revenue, progress: $progress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvisorTotalsModel &&
        other.contact == contact &&
        other.active == active &&
        other.forSale == forSale &&
        other.forRent == forRent &&
        other.sold == sold &&
        other.rented == rented &&
        other.rejected == rejected &&
        other.cancelled == cancelled &&
        other.changesRequired == changesRequired &&
        other.waitingForApproval == waitingForApproval &&
        other.expired == expired &&
        other.draft == draft &&
        other.customers == customers &&
        other.office == office &&
        other.revenue == revenue &&
        other.progress == progress;
  }

  @override
  int get hashCode {
    return contact.hashCode ^
        active.hashCode ^
        forSale.hashCode ^
        forRent.hashCode ^
        sold.hashCode ^
        rented.hashCode ^
        rejected.hashCode ^
        cancelled.hashCode ^
        changesRequired.hashCode ^
        waitingForApproval.hashCode ^
        expired.hashCode ^
        draft.hashCode ^
        customers.hashCode ^
        office.hashCode ^
        revenue.hashCode ^
        progress.hashCode;
  }
}

class RevenueModel {
  final int contact;
  final String year;
  final String revenue;

  RevenueModel({
    required this.contact,
    required this.year,
    required this.revenue,
  });

  factory RevenueModel.fromJson(Map<String, dynamic> json) {
    return RevenueModel(
      contact: json['contact'] ?? 0,
      year: json['year'] ?? '',
      revenue: json['revenue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact': contact,
      'year': year,
      'revenue': revenue,
    };
  }

  @override
  String toString() {
    return 'RevenueModel(contact: $contact, year: $year, revenue: $revenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RevenueModel &&
        other.contact == contact &&
        other.year == year &&
        other.revenue == revenue;
  }

  @override
  int get hashCode {
    return contact.hashCode ^ year.hashCode ^ revenue.hashCode;
  }
}

class ProgressModel {
  final int level;
  final int region;
  final double yearTotal;
  final double treshold;
  final double remaining;
  final double remainingTry;
  final double exchangeRate;

  ProgressModel({
    required this.level,
    required this.region,
    required this.yearTotal,
    required this.treshold,
    required this.remaining,
    required this.remainingTry,
    required this.exchangeRate,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      level: json['level'] ?? 0,
      region: json['region'] ?? 0,
      yearTotal: (json['year_total'] as num?)?.toDouble() ?? 0.0,
      treshold: (json['treshold'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      remainingTry: (json['remaining_try'] as num?)?.toDouble() ?? 0.0,
      exchangeRate: (json['exchange_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'region': region,
      'year_total': yearTotal,
      'treshold': treshold,
      'remaining': remaining,
      'remaining_try': remainingTry,
      'exchange_rate': exchangeRate,
    };
  }

  @override
  String toString() {
    return 'ProgressModel(level: $level, region: $region, yearTotal: $yearTotal, treshold: $treshold, remaining: $remaining, remainingTry: $remainingTry, exchangeRate: $exchangeRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressModel &&
        other.level == level &&
        other.region == region &&
        other.yearTotal == yearTotal &&
        other.treshold == treshold &&
        other.remaining == remaining &&
        other.remainingTry == remainingTry &&
        other.exchangeRate == exchangeRate;
  }

  @override
  int get hashCode {
    return level.hashCode ^
        region.hashCode ^
        yearTotal.hashCode ^
        treshold.hashCode ^
        remaining.hashCode ^
        remainingTry.hashCode ^
        exchangeRate.hashCode;
  }
}
