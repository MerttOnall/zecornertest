class MyOfficeApiModel {
  final int contactNo;
  final String title;
  final String? name;
  final String? surname;
  final int type;
  final String typeDescription;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final String? tcIdNumber;
  final String taxNo;
  final String taxOffice;
  final String nationality;
  final String? sex;
  final String eMail;
  final String tel;
  final int status;
  final String updatedAt;
  final String? source;
  final MyOfficeDetail detail;
  final dynamic attachments;
  final MyOfficeAddress address;
  final dynamic connectedContact;
  final String? connectedContactTitle;
  final dynamic connectedContactType;
  final String? connectedContactDescription;
  final String? connectedContactPicture;
  final String? connectedContactLogo;
  final bool isCustomer;
  final String slug;
  final String? connectedContactSlug;
  final dynamic startingRate;
  final dynamic advisorLevel;
  final int officeRegion;

  MyOfficeApiModel({
    required this.contactNo,
    required this.title,
    this.name,
    this.surname,
    required this.type,
    required this.typeDescription,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    this.tcIdNumber,
    required this.taxNo,
    required this.taxOffice,
    required this.nationality,
    this.sex,
    required this.eMail,
    required this.tel,
    required this.status,
    required this.updatedAt,
    this.source,
    required this.detail,
    this.attachments,
    required this.address,
    this.connectedContact,
    this.connectedContactTitle,
    this.connectedContactType,
    this.connectedContactDescription,
    this.connectedContactPicture,
    this.connectedContactLogo,
    required this.isCustomer,
    required this.slug,
    this.connectedContactSlug,
    this.startingRate,
    this.advisorLevel,
    required this.officeRegion,
  });

  factory MyOfficeApiModel.fromJson(Map<String, dynamic> json) {
    return MyOfficeApiModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      name: json['name'],
      surname: json['surname'],
      type: json['type'] ?? 0,
      typeDescription: json['type_description'] ?? '',
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'] ?? '',
      taxOffice: json['tax_office'] ?? '',
      nationality: json['nationality'] ?? '',
      sex: json['sex'],
      eMail: json['e_mail'] ?? '',
      tel: json['tel'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      source: json['source'],
      detail: MyOfficeDetail.fromJson(json['detail'] ?? {}),
      attachments: json['attachments'],
      address: MyOfficeAddress.fromJson(json['address'] ?? {}),
      connectedContact: json['connected_contact'],
      connectedContactTitle: json['connected_contact_title'],
      connectedContactType: json['connected_contact_type'],
      connectedContactDescription: json['connected_contact_description'],
      connectedContactPicture: json['connected_contact_picture'],
      connectedContactLogo: json['connected_contact_logo'],
      isCustomer: json['is_customer'] ?? false,
      slug: json['slug'] ?? '',
      connectedContactSlug: json['connected_contact_slug'],
      startingRate: json['starting_rate'],
      advisorLevel: json['advisor_level'],
      officeRegion: json['office_region'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contact_no': contactNo,
      'title': title,
      'name': name,
      'surname': surname,
      'type': type,
      'type_description': typeDescription,
      'is_company': isCompany,
      'is_employee': isEmployee,
      'is_agency': isAgency,
      'tc_id_number': tcIdNumber,
      'tax_no': taxNo,
      'tax_office': taxOffice,
      'nationality': nationality,
      'sex': sex,
      'e_mail': eMail,
      'tel': tel,
      'status': status,
      'updated_at': updatedAt,
      'source': source,
      'detail': detail.toJson(),
      'attachments': attachments,
      'address': address.toJson(),
      'connected_contact': connectedContact,
      'connected_contact_title': connectedContactTitle,
      'connected_contact_type': connectedContactType,
      'connected_contact_description': connectedContactDescription,
      'connected_contact_picture': connectedContactPicture,
      'connected_contact_logo': connectedContactLogo,
      'is_customer': isCustomer,
      'slug': slug,
      'connected_contact_slug': connectedContactSlug,
      'starting_rate': startingRate,
      'advisor_level': advisorLevel,
      'office_region': officeRegion,
    };
  }

  // Helper getters
  bool get isActive => status == 1;
  String get displayPhone => tel.isNotEmpty ? tel : 'Telefon yok';
  String get displayEmail => eMail.isNotEmpty ? eMail : 'E-posta yok';
  String get displayAddress => address.address.isNotEmpty ? address.address : 'Adres yok';
  String get displayTaxOffice => taxOffice.isNotEmpty ? taxOffice : 'Vergi dairesi yok';
  String get displayTaxNo => taxNo.isNotEmpty ? taxNo : 'Vergi no yok';
}

class MyOfficeDetail {
  final String id;
  final String? birthday;
  final MyOfficeProfession? profession;
  final MyOfficeEducation? education;
  final MyOfficeSocialMedia socialMedia;
  final String? whereYouHeardUs;
  final String? coverLetter;
  final dynamic sectoralExperience;
  final String? picture;
  final dynamic reference;
  final dynamic areasOfExpertise;
  final bool marketingCommunicationPermission;
  final dynamic rating;
  final String? logo;
  final dynamic detail;

  MyOfficeDetail({
    required this.id,
    this.birthday,
    this.profession,
    this.education,
    required this.socialMedia,
    this.whereYouHeardUs,
    this.coverLetter,
    this.sectoralExperience,
    this.picture,
    this.reference,
    this.areasOfExpertise,
    required this.marketingCommunicationPermission,
    this.rating,
    this.logo,
    this.detail,
  });

  factory MyOfficeDetail.fromJson(Map<String, dynamic> json) {
    return MyOfficeDetail(
      id: json['id'] ?? '',
      birthday: json['birthday'],
      profession: json['profession'] != null ? MyOfficeProfession.fromJson(json['profession']) : null,
      education: json['education'] != null ? MyOfficeEducation.fromJson(json['education']) : null,
      socialMedia: MyOfficeSocialMedia.fromJson(json['social_media'] ?? {}),
      whereYouHeardUs: json['where_you_heard_us'],
      coverLetter: json['cover_letter'],
      sectoralExperience: json['sectoral_experience'],
      picture: json['picture'],
      reference: json['reference'],
      areasOfExpertise: json['areas_of_expertise'],
      marketingCommunicationPermission: json['marketing_communication_permission'] ?? false,
      rating: json['rating'],
      logo: json['logo'],
      detail: json['detail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'birthday': birthday,
      'profession': profession?.toJson(),
      'education': education?.toJson(),
      'social_media': socialMedia.toJson(),
      'where_you_heard_us': whereYouHeardUs,
      'cover_letter': coverLetter,
      'sectoral_experience': sectoralExperience,
      'picture': picture,
      'reference': reference,
      'areas_of_expertise': areasOfExpertise,
      'marketing_communication_permission': marketingCommunicationPermission,
      'rating': rating,
      'logo': logo,
      'detail': detail,
    };
  }
}

class MyOfficeProfession {
  final String? id;
  final String? code;
  final String? description;

  MyOfficeProfession({
    this.id,
    this.code,
    this.description,
  });

  factory MyOfficeProfession.fromJson(Map<String, dynamic> json) {
    return MyOfficeProfession(
      id: json['id'],
      code: json['code'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
    };
  }
}

class MyOfficeEducation {
  final String? id;
  final String? code;
  final String? description;

  MyOfficeEducation({
    this.id,
    this.code,
    this.description,
  });

  factory MyOfficeEducation.fromJson(Map<String, dynamic> json) {
    return MyOfficeEducation(
      id: json['id'],
      code: json['code'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
    };
  }
}

class MyOfficeSocialMedia {
  final String? instagram;
  final String? facebook;
  final String? x;
  final String? linkedin;

  MyOfficeSocialMedia({
    this.instagram,
    this.facebook,
    this.x,
    this.linkedin,
  });

  factory MyOfficeSocialMedia.fromJson(Map<String, dynamic> json) {
    return MyOfficeSocialMedia(
      instagram: json['instagram'],
      facebook: json['facebook'],
      x: json['x'],
      linkedin: json['linkedin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'x': x,
      'linkedin': linkedin,
    };
  }
}

class MyOfficeAddress {
  final String id;
  final String address;
  final int district;
  final int city;
  final String countryCode;
  final String countryName;
  final String? source;
  final double lat;
  final double lon;
  final MyOfficeUavtAddress uavtAddress;

  MyOfficeAddress({
    required this.id,
    required this.address,
    required this.district,
    required this.city,
    required this.countryCode,
    required this.countryName,
    this.source,
    required this.lat,
    required this.lon,
    required this.uavtAddress,
  });

  factory MyOfficeAddress.fromJson(Map<String, dynamic> json) {
    return MyOfficeAddress(
      id: json['id'] ?? '',
      address: json['address'] ?? '',
      district: json['district'] ?? 0,
      city: json['city'] ?? 0,
      countryCode: json['country_code'] ?? '',
      countryName: json['country_name'] ?? '',
      source: json['source'],
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
      uavtAddress: MyOfficeUavtAddress.fromJson(json['uavt_address'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'district': district,
      'city': city,
      'country_code': countryCode,
      'country_name': countryName,
      'source': source,
      'lat': lat,
      'lon': lon,
      'uavt_address': uavtAddress.toJson(),
    };
  }
}

class MyOfficeUavtAddress {
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;

  MyOfficeUavtAddress({
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
  });

  factory MyOfficeUavtAddress.fromJson(Map<String, dynamic> json) {
    return MyOfficeUavtAddress(
      provinceCode: json['province_code'] ?? 0,
      provinceName: json['province_name'] ?? '',
      districtCode: json['district_code'] ?? 0,
      districtName: json['district_name'] ?? '',
      quarterCode: json['quarter_code'] ?? 0,
      quarterName: json['quarter_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'province_code': provinceCode,
      'province_name': provinceName,
      'district_code': districtCode,
      'district_name': districtName,
      'quarter_code': quarterCode,
      'quarter_name': quarterName,
    };
  }
}
