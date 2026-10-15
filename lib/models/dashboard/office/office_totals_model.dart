class OfficeTotalsModel {
  final int office;
  final String active;
  final String forSale;
  final String forRent;
  final String sold;
  final String rented;
  final String rejected;
  final String cancelled;
  final String changesRequired;
  final String waitingForApproval;
  final String expired;
  final String draft;
  final String customers;
  final String totalRevenue;
  final QueryModel query;

  OfficeTotalsModel({
    required this.office,
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
    required this.totalRevenue,
    required this.query,
  });

  factory OfficeTotalsModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? 0;
    }

    final queryMap = json['query'] is Map
        ? Map<String, dynamic>.from(json['query'] as Map)
        : <String, dynamic>{};
    final office = asInt(json['office']) != 0
        ? asInt(json['office'])
        : asInt(queryMap['office']);

    return OfficeTotalsModel(
      office: office,
      active: json['active']?.toString() ?? '0',
      forSale: json['for_sale']?.toString() ?? '0',
      forRent: json['for_rent']?.toString() ?? '0',
      sold: json['sold']?.toString() ?? '0',
      rented: json['rented']?.toString() ?? '0',
      rejected: json['rejected']?.toString() ?? '0',
      cancelled: json['cancelled']?.toString() ?? '0',
      changesRequired: json['changes_required']?.toString() ?? '0',
      waitingForApproval: json['waiting_for_approval']?.toString() ?? '0',
      expired: json['expired']?.toString() ?? '0',
      draft: json['draft']?.toString() ?? '0',
      customers: json['customers']?.toString() ?? '0',
      totalRevenue: json['total_revenue']?.toString() ?? '0',
      query: QueryModel.fromJson(queryMap.isEmpty ? {'office': office} : queryMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office': office,
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
      'total_revenue': totalRevenue,
      'query': query.toJson(),
    };
  }

  @override
  String toString() {
    return 'OfficeTotalsModel(office: $office, active: $active, forSale: $forSale, forRent: $forRent, sold: $sold, rented: $rented, rejected: $rejected, cancelled: $cancelled, changesRequired: $changesRequired, waitingForApproval: $waitingForApproval, expired: $expired, draft: $draft, customers: $customers, totalRevenue: $totalRevenue, query: $query)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeTotalsModel &&
        other.office == office &&
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
        other.totalRevenue == totalRevenue &&
        other.query == query;
  }

  @override
  int get hashCode {
    return office.hashCode ^
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
        totalRevenue.hashCode ^
        query.hashCode;
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
    return contact.hashCode ^
        year.hashCode ^
        revenue.hashCode;
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
      yearTotal: (json['year_total'] ?? 0.0).toDouble(),
      treshold: (json['treshold'] ?? 0.0).toDouble(),
      remaining: (json['remaining'] ?? 0.0).toDouble(),
      remainingTry: (json['remaining_try'] ?? 0.0).toDouble(),
      exchangeRate: (json['exchange_rate'] ?? 0.0).toDouble(),
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

class QueryModel {
  final int office;

  QueryModel({
    required this.office,
  });

  factory QueryModel.fromJson(Map<String, dynamic> json) {
    return QueryModel(
      office: json['office'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office': office,
    };
  }

  @override
  String toString() {
    return 'QueryModel(office: $office)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryModel &&
        other.office == office;
  }

  @override
  int get hashCode {
    return office.hashCode;
  }
}
