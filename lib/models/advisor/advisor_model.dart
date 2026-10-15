class AdvisorPropertyModel {
  final String code;
  final String id;
  final String value;

  AdvisorPropertyModel({
    required this.code,
    required this.id,
    required this.value,
  });

  factory AdvisorPropertyModel.fromJson(Map<String, dynamic> json) {
    return AdvisorPropertyModel(
      code: json['code'] ?? '',
      id: json['id'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'id': id,
      'value': value,
    };
  }

  List<Object?> get props => [code, id, value];
}

class AdvisorListingModel {
  final String id;
  final String type;
  final String realEstate;
  final String title;
  final String description;
  final double price;
  final String currency;
  final List<AdvisorPropertyModel> properties;
  final bool internal;
  final String startDate;
  final String endDate;
  final String slug;

  AdvisorListingModel({
    required this.id,
    required this.type,
    required this.realEstate,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.properties,
    required this.internal,
    required this.startDate,
    required this.endDate,
    required this.slug,
  });

  factory AdvisorListingModel.fromJson(Map<String, dynamic> json) {
    List<AdvisorPropertyModel> propertiesList = [];
    if (json['properties'] != null) {
      propertiesList = (json['properties'] as List)
          .map((item) => AdvisorPropertyModel.fromJson(item))
          .toList();
      print('🏡 Advisor Properties parse edildi: ${propertiesList.length} adet');
    }

    return AdvisorListingModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      realEstate: json['real_estate'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? '',
      properties: propertiesList,
      internal: json['internal'] ?? false,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'real_estate': realEstate,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'properties': properties.map((prop) => prop.toJson()).toList(),
      'internal': internal,
      'start_date': startDate,
      'end_date': endDate,
      'slug': slug,
    };
  }

  List<Object?> get props => [
    id, type, realEstate, title, description, price, currency,
    properties, internal, startDate, endDate, slug
  ];
}

class AdvisorListingsResponseModel {
  final List<AdvisorListingModel> listings;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  AdvisorListingsResponseModel({
    required this.listings,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory AdvisorListingsResponseModel.fromJson(dynamic json) {
    List<AdvisorListingModel> listingsList = [];
    
    if (json is List) {
      // Eğer direkt array ise
      listingsList = json.map((item) => AdvisorListingModel.fromJson(item)).toList();
      print('📋 Advisor Listings array parse edildi: ${listingsList.length} adet');
      
      return AdvisorListingsResponseModel(
        listings: listingsList,
        totalCount: listingsList.length,
        currentPage: 1,
        totalPages: 1,
      );
    } else if (json is Map<String, dynamic>) {
      // Eğer object wrapper ise
      if (json['data'] != null && json['data'] is List) {
        listingsList = (json['data'] as List)
            .map((item) => AdvisorListingModel.fromJson(item))
            .toList();
      } else if (json['listings'] != null && json['listings'] is List) {
        listingsList = (json['listings'] as List)
            .map((item) => AdvisorListingModel.fromJson(item))
            .toList();
      }
      
      print('📋 Advisor Listings object parse edildi: ${listingsList.length} adet');
      
      return AdvisorListingsResponseModel(
        listings: listingsList,
        totalCount: json['total_count'] ?? listingsList.length,
        currentPage: json['current_page'] ?? 1,
        totalPages: json['total_pages'] ?? 1,
      );
    }
    
    // Fallback
    return AdvisorListingsResponseModel(
      listings: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listings': listings.map((listing) => listing.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
    };
  }

  List<Object?> get props => [listings, totalCount, currentPage, totalPages];
}
