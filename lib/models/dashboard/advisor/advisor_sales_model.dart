class AdvisorSalesModel {
  final List<SaleModel> sales;
  final int totalCount;
  final int totalPages;
  final int page;
  final String totalRevenue;

  AdvisorSalesModel({
    required this.sales,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    required this.totalRevenue,
  });

  factory AdvisorSalesModel.fromJson(Map<String, dynamic> json) {
    return AdvisorSalesModel(
      sales: (json['sales'] as List<dynamic>?)
              ?.map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sales': sales.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
      'totalRevenue': totalRevenue,
    };
  }

  @override
  String toString() {
    return 'AdvisorSalesModel(sales: $sales, totalCount: $totalCount, totalPages: $totalPages, page: $page, totalRevenue: $totalRevenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvisorSalesModel &&
        other.sales == sales &&
        other.totalCount == totalCount &&
        other.totalPages == totalPages &&
        other.page == page &&
        other.totalRevenue == totalRevenue;
  }

  @override
  int get hashCode {
    return sales.hashCode ^
        totalCount.hashCode ^
        totalPages.hashCode ^
        page.hashCode ^
        totalRevenue.hashCode;
  }
}

class SaleModel {
  final String listing;
  final String state;
  final int advisor;
  final String advisorTitle;
  final String customerTitle;
  final String sellerCommission;
  final String buyerComission;
  final String totalComission;
  final String date;
  final int office;
  final String listingTitle;
  final String officeTitle;
  final String? closingPrice;
  final int price;
  final int sellerAdvisor;
  final int buyerAdvisor;
  final String sellerAdvisorTitle;
  final String buyerAdvisorTitle;
  final String commissionSide;

  SaleModel({
    required this.listing,
    required this.state,
    required this.advisor,
    required this.advisorTitle,
    required this.customerTitle,
    required this.sellerCommission,
    required this.buyerComission,
    required this.totalComission,
    required this.date,
    required this.office,
    required this.listingTitle,
    required this.officeTitle,
    this.closingPrice,
    required this.price,
    this.sellerAdvisor = 0,
    this.buyerAdvisor = 0,
    this.sellerAdvisorTitle = '',
    this.buyerAdvisorTitle = '',
    this.commissionSide = '',
  });

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _asString(dynamic value) => value?.toString() ?? '';

  static int _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        final parsed = _asInt(json[key]);
        if (parsed > 0) return parsed;
      }
    }
    return 0;
  }

  static String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _asString(json[key]).trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      listing: _asString(json['listing']),
      state: _asString(json['state']),
      advisor: _asInt(json['advisor']),
      advisorTitle: _asString(json['advisor_title']),
      customerTitle: _asString(json['customer_title']),
      sellerCommission: _asString(json['seller_commission']),
      buyerComission: _firstString(json, [
        'buyer_comission',
        'buyer_commission',
      ]),
      totalComission: _asString(json['total_comission']),
      date: _asString(json['date']),
      office: _asInt(json['office']),
      listingTitle: _asString(json['listing_title']),
      officeTitle: _asString(json['office_title']),
      closingPrice: json['closing_price']?.toString(),
      price: _asInt(json['price']),
      sellerAdvisor: _firstInt(json, [
        'seller_advisor',
        'seller_advisor_no',
        'seller_contact',
        'seller_contact_no',
      ]),
      buyerAdvisor: _firstInt(json, [
        'buyer_advisor',
        'buyer_advisor_no',
        'buyer_contact',
        'buyer_contact_no',
      ]),
      sellerAdvisorTitle: _firstString(json, [
        'seller_advisor_title',
        'seller_contact_title',
      ]),
      buyerAdvisorTitle: _firstString(json, [
        'buyer_advisor_title',
        'buyer_contact_title',
      ]),
      commissionSide: _firstString(json, [
        'commission_side',
        'advisor_side',
        'side',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing': listing,
      'state': state,
      'advisor': advisor,
      'advisor_title': advisorTitle,
      'customer_title': customerTitle,
      'seller_commission': sellerCommission,
      'buyer_comission': buyerComission,
      'total_comission': totalComission,
      'date': date,
      'office': office,
      'listing_title': listingTitle,
      'office_title': officeTitle,
      'closing_price': closingPrice,
      'price': price,
      'seller_advisor': sellerAdvisor,
      'buyer_advisor': buyerAdvisor,
      'seller_advisor_title': sellerAdvisorTitle,
      'buyer_advisor_title': buyerAdvisorTitle,
      'commission_side': commissionSide,
    };
  }

  @override
  String toString() {
    return 'SaleModel(listing: $listing, state: $state, advisor: $advisor, advisorTitle: $advisorTitle, customerTitle: $customerTitle, sellerCommission: $sellerCommission, buyerComission: $buyerComission, totalComission: $totalComission, date: $date, office: $office, listingTitle: $listingTitle, officeTitle: $officeTitle, closingPrice: $closingPrice, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SaleModel &&
        other.listing == listing &&
        other.state == state &&
        other.advisor == advisor &&
        other.advisorTitle == advisorTitle &&
        other.customerTitle == customerTitle &&
        other.sellerCommission == sellerCommission &&
        other.buyerComission == buyerComission &&
        other.totalComission == totalComission &&
        other.date == date &&
        other.office == office &&
        other.listingTitle == listingTitle &&
        other.officeTitle == officeTitle &&
        other.closingPrice == closingPrice &&
        other.price == price &&
        other.sellerAdvisor == sellerAdvisor &&
        other.buyerAdvisor == buyerAdvisor &&
        other.sellerAdvisorTitle == sellerAdvisorTitle &&
        other.buyerAdvisorTitle == buyerAdvisorTitle &&
        other.commissionSide == commissionSide;
  }

  @override
  int get hashCode {
    return listing.hashCode ^
        state.hashCode ^
        advisor.hashCode ^
        advisorTitle.hashCode ^
        customerTitle.hashCode ^
        sellerCommission.hashCode ^
        buyerComission.hashCode ^
        totalComission.hashCode ^
        date.hashCode ^
        office.hashCode ^
        listingTitle.hashCode ^
        officeTitle.hashCode ^
        closingPrice.hashCode ^
        price.hashCode ^
        sellerAdvisor.hashCode ^
        buyerAdvisor.hashCode ^
        sellerAdvisorTitle.hashCode ^
        buyerAdvisorTitle.hashCode ^
        commissionSide.hashCode;
  }
}
