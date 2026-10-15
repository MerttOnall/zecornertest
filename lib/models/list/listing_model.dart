import 'property_model.dart';
import 'media_model.dart';

class ListingModel {
  final String id;
  final int listingNo;
  final String title;
  final int price;
  final String currency;
  final String type;
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;
  final List<PropertyModel> propertiesShortList;
  final int contactNo;
  final String contactTitle;
  final String contactEmail;
  final String? contactTel;
  final String? contactPicture;
  final String? picture;
  final String coverPicture;
  final String contactTypeDescription;
  final String realEstateType;
  final String contactType;
  final String state;
  final String createdAt;
  final String? updatedAt;
  final int connectedContact;
  final String parentType;
  final bool internal;
  final String slug;
  final String contactSlug;
  final String? startDate;
  final String? endDate;
  final int viewCount;
  final String connectedContactTitle;
  final String? closingPrice;
  final Map<String, PropertyModel> properties;
  final List<MediaModel> medias;
  final String? description;
  final String? realEstateDescription;
  final double? lat;
  final double? lon;

  ListingModel({
    required this.id,
    required this.listingNo,
    required this.title,
    required this.price,
    required this.currency,
    required this.type,
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
    required this.propertiesShortList,
    required this.contactNo,
    required this.contactTitle,
    required this.contactEmail,
    this.contactTel,
    this.contactPicture,
    this.picture,
    required this.coverPicture,
    required this.contactTypeDescription,
    required this.realEstateType,
    required this.contactType,
    required this.state,
    required this.createdAt,
    this.updatedAt,
    required this.connectedContact,
    required this.parentType,
    required this.internal,
    required this.slug,
    required this.contactSlug,
    this.startDate,
    this.endDate,
    required this.viewCount,
    required this.connectedContactTitle,
    this.closingPrice,
    required this.properties,
    required this.medias,
    this.description,
    this.realEstateDescription,
    this.lat,
    this.lon,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    // Properties short list
    List<PropertyModel> shortList = [];
    if (json['properties_short_list'] != null) {
      shortList = (json['properties_short_list'] as List)
          .map((item) => PropertyModel.fromJson(item))
          .toList();
    }

    // Properties map - array veya map formatını destekle
    Map<String, PropertyModel> propertiesMap = {};
    void addPropertiesFromList(List<dynamic> items) {
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final property = PropertyModel.fromJson(item);
          propertiesMap[property.code] = property;
        }
      }
    }

    if (json['properties'] != null) {
      if (json['properties'] is List) {
        addPropertiesFromList(json['properties'] as List);
      } else if (json['properties'] is Map) {
        (json['properties'] as Map<String, dynamic>).forEach((key, value) {
          if (value is Map<String, dynamic>) {
            propertiesMap[key] = PropertyModel.fromJson(value);
          }
        });
      }
    }

    if (json['listing_properties'] is List) {
      addPropertiesFromList(json['listing_properties'] as List);
    }

    // Medias list
    List<MediaModel> mediasList = [];
    if (json['medias'] != null) {
      mediasList = (json['medias'] as List)
          .map((item) => MediaModel.fromJson(item))
          .toList();
    }
    // Kapak resmi: JSON'da cover_picture yoksa medias içinden is_cover olan veya ilk medyanın standart/thumbnail/hd ID'si
    String coverPicture = json['cover_picure']?.toString() ?? json['cover_picture']?.toString() ?? '';
    if (coverPicture.isEmpty && mediasList.isNotEmpty) {
      final coverCandidates = mediasList.where((m) => m.isCover).toList();
      final coverMedia = coverCandidates.isNotEmpty ? coverCandidates.first : mediasList.first;
      coverPicture = coverMedia.standart?.toString() ??
          coverMedia.thumbnail?.toString() ??
          coverMedia.hd?.toString() ??
          '';
    }

    // Favori/liste API'si bazen null veya farklı tip döner; güvenli parse
    int safeInt(dynamic v) => v is int ? v : (int.tryParse(v?.toString() ?? '0') ?? 0);
    String safeStr(dynamic v) => v?.toString() ?? '';
    String safeString(dynamic v) => v?.toString() ?? '';

    int provinceCode = safeInt(json['province_code']);
    String provinceName = safeStr(json['province_name']);
    int districtCode = safeInt(json['district_code']);
    String districtName = safeStr(json['district_name']);
    int quarterCode = safeInt(json['quarter_code']);
    String quarterName = safeStr(json['quarter_name']);
    double? lat;
    double? lon;
    
    // Eğer address.uavt_address varsa, onu kullan
    if (json['address'] != null && json['address'] is Map) {
      final address = json['address'] as Map<String, dynamic>;
      lat = address['lat'] != null ? (address['lat'] as num).toDouble() : null;
      lon = address['lon'] != null ? (address['lon'] as num).toDouble() : null;
      if (address['uavt_address'] != null && address['uavt_address'] is Map) {
        final uavtAddress = address['uavt_address'] as Map<String, dynamic>;
        provinceCode = uavtAddress['province_code'] ?? provinceCode;
        provinceName = uavtAddress['province_name'] ?? provinceName;
        districtCode = uavtAddress['district_code'] ?? districtCode;
        districtName = uavtAddress['district_name'] ?? districtName;
        quarterCode = uavtAddress['quarter_code'] ?? quarterCode;
        quarterName = uavtAddress['quarter_name'] ?? quarterName;
      }
    }

    return ListingModel(
      id: safeString(json['id']),
      listingNo: safeInt(json['listing_no']),
      title: safeString(json['title']),
      price: json['price'] is int ? json['price'] as int : safeInt(json['price']),
      currency: safeString(json['currency']),
      type: safeString(json['type']),
      provinceCode: provinceCode,
      provinceName: provinceName,
      districtCode: districtCode,
      districtName: districtName,
      quarterCode: quarterCode,
      quarterName: quarterName,
      propertiesShortList: shortList,
      contactNo: safeInt(json['contact_no']),
      contactTitle: safeString(json['contact_title']),
      contactEmail: safeString(json['contact_email'] ?? json['contact_e_mail']),
      contactTel: json['contact_tel']?.toString(),
      contactPicture: json['contact_picture']?.toString(),
      picture: json['picture']?.toString(),
      coverPicture: coverPicture,
      contactTypeDescription: safeString(json['contact_type_description']),
      realEstateType: safeString(json['real_estate_type']),
      contactType: safeString(json['contact_type']),
      state: safeString(json['state']),
      createdAt: safeString(json['created_at']),
      updatedAt: json['updated_at']?.toString(),
      connectedContact: safeInt(json['connected_contact']),
      parentType: safeString(json['parent_type']),
      internal: json['internal'] == true,
      slug: safeString(json['slug']),
      contactSlug: safeString(json['contact_slug']),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      viewCount: safeInt(json['view_count']),
      connectedContactTitle: safeString(json['connected_contact_title']),
      closingPrice: json['closing_price']?.toString(),
      properties: propertiesMap,
      medias: mediasList,
      description: json['description']?.toString(),
      realEstateDescription: json['real_estate_description']?.toString(),
      lat: lat,
      lon: lon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_no': listingNo,
      'title': title,
      'price': price,
      'currency': currency,
      'type': type,
      'province_code': provinceCode,
      'province_name': provinceName,
      'district_code': districtCode,
      'district_name': districtName,
      'quarter_code': quarterCode,
      'quarter_name': quarterName,
      'properties_short_list': propertiesShortList.map((prop) => prop.toJson()).toList(),
      'contact_no': contactNo,
      'contact_title': contactTitle,
      'contact_email': contactEmail,
      'contact_tel': contactTel,
      'contact_picture': contactPicture,
      'picture': picture,
      'cover_picure': coverPicture,
      'contact_type_description': contactTypeDescription,
      'real_estate_type': realEstateType,
      'contact_type': contactType,
      'state': state,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'connected_contact': connectedContact,
      'parent_type': parentType,
      'internal': internal,
      'slug': slug,
      'contact_slug': contactSlug,
      'start_date': startDate,
      'end_date': endDate,
      'view_count': viewCount,
      'connected_contact_title': connectedContactTitle,
      'closing_price': closingPrice,
      'properties': properties.map((key, value) => MapEntry(key, value.toJson())),
      'medias': medias.map((media) => media.toJson()).toList(),
      'description': description,
      'real_estate_description': realEstateDescription,
      'lat': lat,
      'lon': lon,
    };
  }

  List<Object?> get props => [
    id, listingNo, title, price, currency, type, provinceCode, provinceName,
    districtCode, districtName, quarterCode, quarterName, propertiesShortList,
    contactNo, contactTitle, contactEmail, contactTel, contactPicture, picture, coverPicture, contactTypeDescription,
    realEstateType, contactType, state, createdAt, updatedAt, connectedContact,
    parentType, internal, slug, contactSlug, startDate, endDate, viewCount,
    connectedContactTitle, closingPrice, properties, medias, description,
    realEstateDescription, lat, lon
  ];
}