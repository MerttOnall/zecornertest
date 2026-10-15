class FeaturedListingModel {
  final int id;
  final String startDate;
  final String endDate;
  final int position;
  final int status;
  final String listingId;
  final int listingNo;
  final String title;
  final double price;
  final String currency;
  final String type;
  final String provinceName;
  final String districtName;
  final String quarterName;
  final int contactNo;
  final String contactTitle;
  final String? picture;
  final String? coverPicure;
  final String realEstateType;
  final String contactTypeDescription;
  final Map<String, dynamic>? properties;

  FeaturedListingModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.position,
    required this.status,
    required this.listingId,
    required this.listingNo,
    required this.title,
    required this.price,
    required this.currency,
    required this.type,
    required this.provinceName,
    required this.districtName,
    required this.quarterName,
    required this.contactNo,
    required this.contactTitle,
    this.picture,
    this.coverPicure,
    required this.realEstateType,
    required this.contactTypeDescription,
    this.properties,
  });

  factory FeaturedListingModel.fromJson(Map<String, dynamic> json) {
    return FeaturedListingModel(
      id: json['id'] ?? 0,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      position: json['position'] ?? 0,
      status: json['status'] ?? 0,
      listingId: json['listing_id'] ?? '',
      listingNo: json['listing_no'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TL',
      type: json['type'] ?? '',
      provinceName: json['province_name'] ?? '',
      districtName: json['district_name'] ?? '',
      quarterName: json['quarter_name'] ?? '',
      contactNo: json['contact_no'] ?? 0,
      contactTitle: json['contact_title'] ?? '',
      picture: json['picture'],
      coverPicure: json['cover_picure'],
      realEstateType: json['real_estate_type'] ?? '',
      contactTypeDescription: json['contact_type_description'] ?? '',
      properties: json['properties'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate,
      'end_date': endDate,
      'position': position,
      'status': status,
      'listing_id': listingId,
      'listing_no': listingNo,
      'title': title,
      'price': price,
      'currency': currency,
      'type': type,
      'province_name': provinceName,
      'district_name': districtName,
      'quarter_name': quarterName,
      'contact_no': contactNo,
      'contact_title': contactTitle,
      'picture': picture,
      'cover_picure': coverPicure,
      'real_estate_type': realEstateType,
      'contact_type_description': contactTypeDescription,
      'properties': properties,
    };
  }
}

class FeaturedListingResponse {
  final List<FeaturedListingModel> featuredListings;
  final int totalCount;
  final int totalPages;
  final int page;

  FeaturedListingResponse({
    required this.featuredListings,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory FeaturedListingResponse.fromJson(Map<String, dynamic> json) {
    return FeaturedListingResponse(
      featuredListings: (json['featured_listings'] as List<dynamic>?)
              ?.map((item) => FeaturedListingModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }
}

