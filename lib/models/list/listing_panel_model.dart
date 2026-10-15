import 'package:zecorner/models/list/property_model.dart';
import 'package:zecorner/models/list/media_model.dart';
import 'package:zecorner/models/realestate/myrealestate_model.dart' as re;

class ListingPanelModel {
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
  final String? picture;
  final String? coverPicture;
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
  final List<MediaModel> medias; // Medias listesi

  /// Bağlı portföy (BAMMA `real_estate`) id'si — düzenleme ekranı için.
  final String? realEstate;

  ListingPanelModel({
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
    this.picture,
    this.coverPicture,
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
    this.realEstate,
  });

  /// `real_estate` düz id, `{ id: ... }` nesnesi veya `real_estate_id` olabilir.
  static String? parseRealEstateId(Map<String, dynamic> json) {
    for (final key in ['real_estate', 'real_estate_id', 'realEstate', 'realEstateId']) {
      final v = json[key];
      if (v == null) continue;
      if (v is Map) {
        final id = v['id']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
        continue;
      }
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  factory ListingPanelModel.fromJson(Map<String, dynamic> json) {
    // Properties short list
    List<PropertyModel> shortList = [];
    if (json['properties_short_list'] != null) {
      shortList = (json['properties_short_list'] as List)
          .map((item) => PropertyModel.fromJson(item))
          .toList();
    }

    // Properties map - array veya map formatını destekle
    Map<String, PropertyModel> propertiesMap = {};
    if (json['properties'] != null) {
      if (json['properties'] is List) {
        // Array formatında geliyor (detay API'sinde)
        for (var item in json['properties'] as List) {
          try {
            if (item is Map<String, dynamic>) {
              // Eğer item bir Map ise, code'u key olarak kullan
              final code = item['code'] ?? item['property_code'] ?? '';
              if (code.isNotEmpty) {
                propertiesMap[code] = PropertyModel.fromJson(item);
              }
            }
          } catch (e) {
            print('⚠️ Property parse hatası: $e');
          }
        }
      } else if (json['properties'] is Map) {
        // Map formatında geliyor (liste API'sinde)
        (json['properties'] as Map<String, dynamic>).forEach((key, value) {
          try {
            if (value is Map<String, dynamic>) {
              propertiesMap[key] = PropertyModel.fromJson(value);
            }
          } catch (e) {
            print('⚠️ Property parse hatası: $e');
          }
        });
      }
    }

    // Medias listesi
    List<MediaModel> mediasList = [];
    if (json['medias'] != null) {
      mediasList = (json['medias'] as List)
          .map((item) => MediaModel.fromJson(item))
          .toList();
    }

    return ListingPanelModel(
      id: json['id'] ?? '',
      listingNo: _asInt(json['listing_no'] ?? json['listingNo']),
      title: json['title'] ?? '',
      price: _asInt(json['price']),
      currency: json['currency'] ?? '',
      type: json['type'] ?? '',
      provinceCode: _asInt(json['province_code']),
      provinceName: json['province_name'] ?? '',
      districtCode: _asInt(json['district_code']),
      districtName: json['district_name'] ?? '',
      quarterCode: _asInt(json['quarter_code']),
      quarterName: json['quarter_name'] ?? '',
      propertiesShortList: shortList,
      contactNo: _asInt(json['contact_no']),
      contactTitle: json['contact_title'] ?? '',
      picture: json['picture'],
      coverPicture: json['cover_picure'] ?? json['cover_picture'],
      contactTypeDescription: json['contact_type_description'] ?? '',
      realEstateType: json['real_estate_type'] ?? '',
      contactType: json['contact_type'] ?? '',
      state: json['state'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      connectedContact: _asInt(json['connected_contact']),
      parentType: json['parent_type'] ?? '',
      internal: json['internal'] ?? false,
      slug: json['slug'] ?? '',
      contactSlug: json['contact_slug'] ?? '',
      startDate: json['start_date'],
      endDate: json['end_date'],
      viewCount: _asInt(json['view_count']),
      connectedContactTitle: json['connected_contact_title'] ?? '',
      closingPrice: json['closing_price']?.toString(),
      properties: propertiesMap,
      medias: mediasList,
      realEstate: parseRealEstateId(json),
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
      'real_estate': realEstate,
    };
  }

  List<Object?> get props => [
    id, listingNo, title, price, currency, type, provinceCode, provinceName,
    districtCode, districtName, quarterCode, quarterName, propertiesShortList,
    contactNo, contactTitle, picture, coverPicture, contactTypeDescription,
    realEstateType, contactType, state, createdAt, updatedAt, connectedContact,
    parentType, internal, slug, contactSlug, startDate, endDate, viewCount,
    connectedContactTitle, closingPrice, properties, medias
  ];

  // Helper getters for UI
  String get fullLocation => '$provinceName / $districtName / $quarterName';

  /// Portföyüm kartından düzenleme ekranına geçerken kullanılan minimal
  /// portföy modeli. `realEstateId` verilmezse `realEstate`, o da yoksa
  /// ilan id'si kullanılır. Düzenleme ekranı ayrıntıları ayrıca sunucudan
  /// çeker; buradaki değerler yalnızca ilk doldurma içindir.
  re.RealEstateModel toRealEstateModel({String? realEstateId}) {
    final resolvedId = (realEstateId ?? realEstate ?? '').trim();
    final thumb = (coverPicture != null && coverPicture!.isNotEmpty)
        ? coverPicture!
        : (picture ?? '');
    final hasUavt = provinceCode > 0 || districtCode > 0 || quarterCode > 0;

    return re.RealEstateModel(
      id: resolvedId.isNotEmpty ? resolvedId : id,
      type: realEstateType,
      description: '',
      status: state.toUpperCase() == 'ACTIVE' ? 1 : 0,
      updatedAt: updatedAt ?? createdAt,
      recordedAt: createdAt,
      address: re.AddressModel(
        address: fullLocation,
        lat: 0.0,
        lon: 0.0,
        district: districtName.isNotEmpty ? districtName : null,
        city: provinceName.isNotEmpty ? provinceName : null,
        source: 'listing',
        uavtAddress: hasUavt
            ? re.UavtAddressModel(
                provinceCode: provinceCode,
                provinceName: provinceName,
                districtCode: districtCode,
                districtName: districtName,
                quarterCode: quarterCode,
                quarterName: quarterName,
              )
            : null,
      ),
      properties: properties.map(
        (key, value) => MapEntry(key, re.PropertyModel.fromJson(value.toJson())),
      ),
      thumbnail: thumb,
      contact: contactNo,
      contactType: contactType,
      title: title,
      price: price > 0 ? price : null,
    );
  }
  
  String get formattedPrice {
    if (price == 0) return 'Fiyat Görüşülür';
    
    if (price >= 1000000) {
      return '₺${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '₺${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return '₺$price';
    }
  }
  
  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().split('.').first) ?? 0;
  }

  String get displayType {
    switch (type.toLowerCase()) {
      case 'kiralik':
        return 'Kiralık';
      case 'satilik':
        return 'Satılık';
      default:
        return type;
    }
  }

  String get displayRealEstateType {
    switch (realEstateType) {
      case 'konut-daire':
        return 'Daire';
      case 'konut-villa':
        return 'Villa';
      case 'konut-residence':
        return 'Residence';
      case 'konut-ciftlik-evi':
        return 'Çiftlik Evi';
      case 'konut-penthouse':
        return 'Penthouse';
      case 'konut-dubleks':
        return 'Dubleks';
      case 'konut-mustakil-ev':
        return 'Müstakil Ev';
      default:
        return realEstateType;
    }
  }
  
  String get displayState {
    switch (state.toUpperCase()) {
      case 'LIVE':
        return 'Yayında';
      case 'RENTED':
        return 'Kiralandı';
      case 'SOLD':
        return 'Satıldı';
      case 'DRAFT':
        return 'Taslak';
      case 'PENDING':
      case 'WAITING_FOR_APPROVAL':
        return 'Onay Bekliyor';
      case 'CHANGE_REQUIRED':
        return 'Değişiklik İsteniyor';
      case 'CLOSURE_APPROVAL':
      case 'WAITING_FOR_CLOSE_APPROVAL':
        return 'Kapama Onayı Bekliyor';
      case 'REJECTED':
        return 'Reddedildi';
      case 'EXPIRED':
        return 'Süresi Dolmuş';
      case 'CANCELLED':
        return 'İptal Edildi';
      default:
        return state;
    }
  }
  
  String get area {
    final m2Brut = properties['m2-brut']?.numberValue;
    final m2Net = properties['m2-net']?.numberValue;
    final m2 = properties['m2']?.numberValue;
    
    if (m2Brut != null && m2Brut > 0) return '$m2Brut';
    if (m2Net != null && m2Net > 0) return '$m2Net';
    if (m2 != null && m2 > 0) return '$m2';
    return 'N/A';
  }
  
  String get rooms {
    final odaSayisi = properties['oda-sayisi']?.value;
    if (odaSayisi != null) {
      if (odaSayisi.contains('oda-sayisi-')) {
        final roomCode = odaSayisi.replaceAll('oda-sayisi-', '');
        switch (roomCode) {
          case '21':
            return '2+1';
          case '31':
            return '3+1';
          case '41':
            return '4+1';
          case '51':
            return '5+1';
          default:
            return roomCode;
        }
      }
    }
    return 'N/A';
  }
  
  String get imageUrl {
    if (coverPicture != null && coverPicture!.isNotEmpty) {
      return 'https://test.d1cegqpdj9080.amplifyapp.com/api/zecorner/images/$coverPicture';
    }
    return 'https://picsum.photos/800/400?random=${id.hashCode}';
  }
  
  String get formattedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return createdAt;
    }
  }
}