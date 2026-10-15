class OfficeApiModel {
  final int contactNo;
  final String title;
  final String? name;
  final String? surname;
  final int type;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String nationality;
  final int? sex;
  final String eMail;
  final String tel;
  final int status;
  final String? updatedAt;
  final String createdAt;
  final String? source;
  final String typeDescription;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final String? birthday;
  final String? professionCode;
  final String? professionDescription;
  final String? educationCode;
  final String? educationDescription;
  final String? whereYouHeardUs;
  final int? sectoralExperience;
  final String? picture;
  final bool marketingCommunicationPermission;
  final String? address;
  final String? district;
  final String? postCode;
  final String? city;
  final String country;
  final String? addressSource;
  final int? provinceCode;
  final String? provinceName;
  final int? districtCode;
  final String? districtName;
  final int? quarterCode;
  final String? quarterName;
  final int? connectedContact;
  final String? connectedContactTitle;
  final int? connectedContactType;
  final String? connectedContactDescription;
  final bool isCustomer;
  final String slug;
  /// API: `trade_name` — ticari ünvan (şirket unvanından farklı olabilir)
  final String? tradeName;
  /// Liste cevabında `detail` çoğunlukla detay kaydı UUID’si (string); obje değil.
  final String? detailRef;

  OfficeApiModel({
    required this.contactNo,
    required this.title,
    this.name,
    this.surname,
    required this.type,
    this.tcIdNumber,
    this.taxNo,
    this.taxOffice,
    required this.nationality,
    this.sex,
    required this.eMail,
    required this.tel,
    required this.status,
    this.updatedAt,
    required this.createdAt,
    this.source,
    required this.typeDescription,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    this.birthday,
    this.professionCode,
    this.professionDescription,
    this.educationCode,
    this.educationDescription,
    this.whereYouHeardUs,
    this.sectoralExperience,
    this.picture,
    required this.marketingCommunicationPermission,
    this.address,
    this.district,
    this.postCode,
    this.city,
    required this.country,
    this.addressSource,
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
    this.quarterCode,
    this.quarterName,
    this.connectedContact,
    this.connectedContactTitle,
    this.connectedContactType,
    this.connectedContactDescription,
    required this.isCustomer,
    required this.slug,
    this.tradeName,
    this.detailRef,
  });

  factory OfficeApiModel.fromJson(Map<String, dynamic> json) {
    return OfficeApiModel(
      contactNo: json['contact_no'] as int,
      title: json['title'] as String? ?? '',
      name: json['name'] as String?,
      surname: json['surname'] as String?,
      type: json['type'] as int,
      tcIdNumber: json['tc_id_number'] as String?,
      taxNo: json['tax_no'] as String?,
      taxOffice: json['tax_office'] as String?,
      nationality: json['nationality'] as String? ?? 'TR',
      sex: json['sex'] as int?,
      eMail: json['e_mail'] as String? ?? '',
      tel: json['tel'] as String? ?? '',
      status: json['status'] as int,
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String? ?? DateTime.now().toUtc().toIso8601String(),
      source: json['source'] as String?,
      typeDescription: json['type_description'] as String? ?? '',
      isCompany: json['is_company'] as bool? ?? false,
      isEmployee: json['is_employee'] as bool? ?? false,
      isAgency: json['is_agency'] as bool? ?? false,
      birthday: json['birthday'] as String?,
      professionCode: json['profession_code'] as String?,
      professionDescription: json['profession_description'] as String?,
      educationCode: json['education_code'] as String?,
      educationDescription: json['education_description'] as String?,
      whereYouHeardUs: json['where_you_heard_us'] as String?,
      sectoralExperience: json['sectoral_experience'] as int?,
      picture: json['picture'] as String?,
      marketingCommunicationPermission: json['marketing_communication_permission'] as bool? ?? false,
      address: json['address'] as String?,
      district: json['district'] as String?,
      postCode: json['post_code'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String? ?? 'TR',
      addressSource: json['address_source'] as String?,
      provinceCode: json['province_code'] as int?,
      provinceName: json['province_name'] as String?,
      districtCode: json['district_code'] as int?,
      districtName: json['district_name'] as String?,
      quarterCode: json['quarter_code'] is int 
          ? json['quarter_code'] as int?
          : json['quarter_code'] is String 
              ? int.tryParse(json['quarter_code'] as String)
              : null,
      quarterName: json['quarter_name'] as String?,
      connectedContact: json['connected_contact'] as int?,
      connectedContactTitle: json['connected_contact_title'] as String?,
      connectedContactType: json['connected_contact_type'] as int?,
      connectedContactDescription: json['connected_contact_description'] as String?,
      isCustomer: json['is_customer'] as bool? ?? false,
      slug: json['slug'] as String? ?? '',
      tradeName: json['trade_name'] == null ? null : json['trade_name'].toString(),
      detailRef: json['detail'] is String && (json['detail'] as String).isNotEmpty
          ? json['detail'] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_no': contactNo,
      'title': title,
      'name': name,
      'surname': surname,
      'type': type,
      'tc_id_number': tcIdNumber,
      'tax_no': taxNo,
      'tax_office': taxOffice,
      'nationality': nationality,
      'sex': sex,
      'e_mail': eMail,
      'tel': tel,
      'status': status,
      'updated_at': updatedAt,
      'created_at': createdAt,
      'source': source,
      'type_description': typeDescription,
      'is_company': isCompany,
      'is_employee': isEmployee,
      'is_agency': isAgency,
      'birthday': birthday,
      'profession_code': professionCode,
      'profession_description': professionDescription,
      'education_code': educationCode,
      'education_description': educationDescription,
      'where_you_heard_us': whereYouHeardUs,
      'sectoral_experience': sectoralExperience,
      'picture': picture,
      'marketing_communication_permission': marketingCommunicationPermission,
      'address': address,
      'district': district,
      'post_code': postCode,
      'city': city,
      'country': country,
      'address_source': addressSource,
      'province_code': provinceCode,
      'province_name': provinceName,
      'district_code': districtCode,
      'district_name': districtName,
      'quarter_code': quarterCode,
      'quarter_name': quarterName,
      'connected_contact': connectedContact,
      'connected_contact_title': connectedContactTitle,
      'connected_contact_type': connectedContactType,
      'connected_contact_description': connectedContactDescription,
      'is_customer': isCustomer,
      'slug': slug,
      if (tradeName != null) 'trade_name': tradeName,
      if (detailRef != null) 'detail': detailRef,
    };
  }

  /// Adres: VM_DETAIL şema ile uyumlu — `city` / `district` yalnızca sayısal kod olmalı;
  /// isimler `province_name`, `district_name` ile gider (ContactApiModel._buildAddressPayload ile aynı mantık).
  Map<String, dynamic> _buildAddressPayloadForUpdate() {
    final out = <String, dynamic>{};

    int? pCode = provinceCode;
    if (pCode == null && city != null && city!.isNotEmpty) {
      pCode = int.tryParse(city!);
    }
    int? dCode = districtCode;
    if (dCode == null && district != null && district!.isNotEmpty) {
      dCode = int.tryParse(district!);
    }
    final qCode = quarterCode;

    if (pCode != null) {
      out['city'] = pCode;
      out['province_code'] = pCode;
    }
    if (provinceName != null && provinceName!.isNotEmpty) {
      out['province_name'] = provinceName;
    }
    if (dCode != null) {
      out['district'] = dCode;
      out['district_code'] = dCode;
    }
    if (districtName != null && districtName!.isNotEmpty) {
      out['district_name'] = districtName;
    }
    if (qCode != null) {
      out['quarter_code'] = qCode;
    }
    if (quarterName != null && quarterName!.isNotEmpty) {
      out['quarter_name'] = quarterName;
    }
    if (country.isNotEmpty) {
      out['country'] = country;
    }
    if (address != null && address!.isNotEmpty) {
      out['address'] = address;
    }
    if (postCode != null && postCode!.isNotEmpty) {
      out['postCode'] = postCode;
      out['post_code'] = postCode;
    }
    return out;
  }

  // Update için özel JSON metodu (Contact mantığıyla aynı)
  Map<String, dynamic> toUpdateJson() {
    // Ana request objesi (camelCase formatı)
    final requestData = <String, dynamic>{
      'name': name ?? '',
      'surname': surname ?? '',
      'tel': tel,
      'eMail': eMail,
      'nationality': nationality,
      'type': {
        'code': type.toString(), // ContactApiModel.toUpdateJson ile aynı (string)
      },
      'status': status,
    };

    // Tüzel / ofis kayıtlarında cinsiyet zorunlu değil; kişi değilse sex gönderme (VM hatası önlenir)
    if (!isCompany) {
      requestData['sex'] = sex ?? 1;
    } else if (sex != null) {
      requestData['sex'] = sex;
    }

    // Tax bilgileri (office için önemli)
    if (taxNo != null && taxNo!.isNotEmpty) {
      requestData['taxNo'] = taxNo;
    }
    if (taxOffice != null && taxOffice!.isNotEmpty) {
      requestData['taxOffice'] = taxOffice;
    }

    // TC Kimlik (opsiyonel)
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) {
      requestData['tcIdNumber'] = tcIdNumber;
    }

    // Title (office name)
    if (title.isNotEmpty) {
      requestData['title'] = title;
    }

    final tn = tradeName?.trim();
    if (tn != null && tn.isNotEmpty) {
      requestData['trade_name'] = tn;
    }

    // Mevcut detay kaydı (liste/GET’te `detail` genelde UUID string); güncellemede VM_DETAIL için gerekli.
    final detailObj = <String, dynamic>{};
    final ref = detailRef?.trim();
    if (ref != null && ref.isNotEmpty) {
      detailObj['id'] = ref;
    }

    if (birthday != null && birthday!.isNotEmpty) {
      detailObj['birthday'] = birthday;
    }

    if (professionCode != null && professionCode!.isNotEmpty) {
      detailObj['profession'] = {
        'code': professionCode,
        'description': professionDescription ?? '',
      };
    }

    if (educationCode != null && educationCode!.isNotEmpty) {
      detailObj['education'] = {
        'code': educationCode,
        'description': educationDescription ?? '',
      };
    }

    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = whereYouHeardUs!;
    }
    if (sectoralExperience != null) {
      detailObj['sectoralExperience'] = sectoralExperience!;
    }
    if (picture != null && picture!.isNotEmpty) {
      detailObj['picture'] = picture!;
    }

    // Boş `socialMedia: {}` BAMMA VM_DETAIL’de "Variable mapping assignment error" üretebiliyor;
    // önceki çalışan gövde yalnızca `attachments` (+ isteğe bağlı alanlar) idi.
    detailObj['attachments'] = <dynamic>[];

    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }

    // Boş `{}` adres VM tarafında hata üretebiliyor; ContactApiModel ile aynı: doluysa gönder
    final addressObj = _buildAddressPayloadForUpdate();
    if (addressObj.isNotEmpty) {
      requestData['address'] = addressObj;
    }

    // Connected contact (opsiyonel)
    if (connectedContact != null) {
      requestData['connectedContact'] = connectedContact;
    }

    // Marketing permission
    requestData['marketingCommunicationPermission'] = marketingCommunicationPermission;

    return requestData;
  }

  // Helper getters
  bool get isActive => status == 1;
  String get displayPhone => tel.isEmpty ? 'N/A' : tel;
  String get displayEmail => eMail.isEmpty ? 'N/A' : eMail;
  String get displayLocation => '${provinceName ?? 'N/A'}/${districtName ?? 'N/A'}';
  String get displayTaxNo => taxNo ?? 'N/A';
  String get displayAddress => address ?? 'N/A';
  
  // Format created date
  String get formattedCreatedDate {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class OfficeApiResponse {
  final List<OfficeApiModel> offices;
  final int totalCount;
  final int totalPages;
  final int page;

  OfficeApiResponse({
    required this.offices,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory OfficeApiResponse.fromJson(Map<String, dynamic> json) {
    return OfficeApiResponse(
      offices: (json['contacts'] as List)
          .map((e) => OfficeApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
    );
  }
}
