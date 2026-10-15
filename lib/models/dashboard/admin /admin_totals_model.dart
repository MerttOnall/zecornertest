class AdminTotalsModel {
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

  AdminTotalsModel({
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
  });

  factory AdminTotalsModel.fromJson(Map<String, dynamic> json) {
    // API'den gelen değerler string olarak geliyor, direkt kullan
    return AdminTotalsModel(
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  @override
  String toString() {
    return 'AdminTotalsModel(active: $active, forSale: $forSale, forRent: $forRent, sold: $sold, rented: $rented, rejected: $rejected, cancelled: $cancelled, changesRequired: $changesRequired, waitingForApproval: $waitingForApproval, expired: $expired, draft: $draft, customers: $customers, totalRevenue: $totalRevenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminTotalsModel &&
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
        other.totalRevenue == totalRevenue;
  }

  @override
  int get hashCode {
    return active.hashCode ^
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
        totalRevenue.hashCode;
  }
}
