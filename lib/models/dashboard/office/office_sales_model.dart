class OfficeSalesModel {
  final List<SaleModel> sales;
  final int totalCount;
  final int totalPages;
  final int page;
  final String totalRevenue;

  OfficeSalesModel({
    required this.sales,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    required this.totalRevenue,
  });

  factory OfficeSalesModel.fromJson(Map<String, dynamic> json) {
    return OfficeSalesModel(
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
    return 'OfficeSalesModel(sales: $sales, totalCount: $totalCount, totalPages: $totalPages, page: $page, totalRevenue: $totalRevenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeSalesModel &&
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
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      listing: json['listing'] ?? '',
      state: json['state'] ?? '',
      advisor: json['advisor'] ?? 0,
      advisorTitle: json['advisor_title'] ?? '',
      customerTitle: json['customer_title'] ?? '',
      sellerCommission: json['seller_commission'] ?? '',
      buyerComission: json['buyer_comission'] ?? '',
      totalComission: json['total_comission'] ?? '',
      date: json['date'] ?? '',
      office: json['office'] ?? 0,
      listingTitle: json['listing_title'] ?? '',
      officeTitle: json['office_title'] ?? '',
      closingPrice: json['closing_price'],
      price: json['price'] ?? 0,
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
        other.price == price;
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
        price.hashCode;
  }
}
