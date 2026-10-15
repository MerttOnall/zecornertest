class AdminSalesModel {
  final List<SaleModel> sales;
  final int totalCount;
  final int totalPages;
  final int page;
  final String totalRevenue;

  AdminSalesModel({
    required this.sales,
    required this.totalCount,
    required this.totalPages,
    required this.page,
    required this.totalRevenue,
  });

  factory AdminSalesModel.fromJson(dynamic json) {
    Map<String, dynamic> map;
    if (json is Map<String, dynamic>) {
      map = json;
    } else if (json is Map) {
      map = Map<String, dynamic>.from(json);
    } else if (json is List) {
      map = {'sales': json};
    } else {
      map = <String, dynamic>{};
    }

    final nested = map['data'];
    if (nested is Map && map['sales'] == null) {
      map = {
        ...map,
        ...Map<String, dynamic>.from(nested),
      };
    }

    final rawList = map['sales'] ??
        map['results'] ??
        map['list'] ??
        map['items'] ??
        (nested is List ? nested : null);

    return AdminSalesModel(
      sales: (rawList as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => SaleModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      totalCount: map['totalCount'] ?? map['total_count'] ?? 0,
      totalPages: map['totalPages'] ?? map['total_pages'] ?? 0,
      page: map['page'] ?? 0,
      totalRevenue: (map['totalRevenue'] ??
              map['total_revenue'] ??
              map['total'] ??
              map['net'] ??
              '')
          .toString(),
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
    return 'AdminSalesModel(sales: $sales, totalCount: $totalCount, totalPages: $totalPages, page: $page, totalRevenue: $totalRevenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminSalesModel &&
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
  final String? buyerComission;
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
    this.buyerComission,
    required this.totalComission,
    required this.date,
    required this.office,
    required this.listingTitle,
    required this.officeTitle,
    this.closingPrice,
    required this.price,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    String str(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    int numInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    return SaleModel(
      listing: str(['listing', 'listing_id', 'listingId']),
      state: str(['state', 'status']),
      advisor: numInt(['advisor', 'advisor_no', 'contact']),
      advisorTitle: str(['advisor_title', 'advisorTitle', 'advisor_name']),
      customerTitle: str(['customer_title', 'customerTitle', 'customer_name']),
      sellerCommission: str(['seller_commission', 'sellerCommission']),
      buyerComission: json['buyer_comission']?.toString() ??
          json['buyer_commission']?.toString() ??
          json['buyerCommission']?.toString(),
      totalComission: str([
        'total_comission',
        'total_commission',
        'totalCommission',
        'net',
        'total',
      ]),
      date: str(['date', 'transaction_date', 'created_at']),
      office: numInt(['office', 'office_no']),
      listingTitle: str(['listing_title', 'listingTitle']),
      officeTitle: str(['office_title', 'officeTitle', 'office_name']),
      closingPrice: json['closing_price']?.toString() ??
          json['closingPrice']?.toString(),
      price: numInt(['price', 'closing_price']),
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
