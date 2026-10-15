class ContactDetailModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final int type;
  final String typeDescription;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String nationality;
  final String? sex;
  final String email;
  final String tel;
  final int status;
  final String? updatedAt;
  final String? source;
  final ContactDetailInfoModel detail;
  final dynamic attachments;
  final ContactAddressModel address;
  final int? connectedContact;
  final String? connectedContactTitle;
  final int? connectedContactType;
  final String? connectedContactDescription;
  final String? connectedContactPicture;
  final String? connectedContactLogo;
  final bool isCustomer;
  final String slug;
  final String? connectedContactSlug;
  final int? startingRate;
  final int? advisorLevel;
  final String? officeRegion;

  ContactDetailModel({
    required this.contactNo,
    required this.title,
    required this.name,
    required this.surname,
    required this.type,
    required this.typeDescription,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    this.tcIdNumber,
    this.taxNo,
    this.taxOffice,
    required this.nationality,
    this.sex,
    required this.email,
    required this.tel,
    required this.status,
    this.updatedAt,
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
    this.officeRegion,
  });

  factory ContactDetailModel.fromJson(Map<String, dynamic> json) {
    return ContactDetailModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      type: json['type'] ?? 0,
      typeDescription: json['type_description'] ?? '',
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'],
      taxOffice: json['tax_office'],
      nationality: json['nationality'] ?? '',
      sex: json['sex'],
      email: json['e_mail'] ?? '',
      tel: json['tel'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'],
      source: json['source'],
      detail: ContactDetailInfoModel.fromJson(json['detail'] as Map<String, dynamic>? ?? {}),
      attachments: json['attachments'],
      address: ContactAddressModel.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
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
      officeRegion: json['office_region'],
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
      'e_mail': email,
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
}

class ContactDetailInfoModel {
  final String? id;
  final String? birthday;
  final ContactProfessionModel profession;
  final ContactEducationModel education;
  final Map<String, dynamic> socialMedia;
  final String? whereYouHeardUs;
  final String? coverLetter;
  final String? sectoralExperience;
  final String? picture;
  final String? reference;
  final String? areasOfExpertise;
  final bool marketingCommunicationPermission;
  final double? rating;
  final String? logo;
  final String? detail;

  ContactDetailInfoModel({
    this.id,
    this.birthday,
    required this.profession,
    required this.education,
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

  factory ContactDetailInfoModel.fromJson(Map<String, dynamic> json) {
    return ContactDetailInfoModel(
      id: json['id'],
      birthday: json['birthday'],
      profession: ContactProfessionModel.fromJson(json['profession'] as Map<String, dynamic>? ?? {}),
      education: ContactEducationModel.fromJson(json['education'] as Map<String, dynamic>? ?? {}),
      socialMedia: json['social_media'] as Map<String, dynamic>? ?? {},
      whereYouHeardUs: json['where_you_heard_us'],
      coverLetter: json['cover_letter'],
      sectoralExperience: json['sectoral_experience'],
      picture: json['picture'],
      reference: json['reference'],
      areasOfExpertise: json['areas_of_expertise'],
      marketingCommunicationPermission: json['marketing_communication_permission'] ?? false,
      rating: json['rating']?.toDouble(),
      logo: json['logo'],
      detail: json['detail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'birthday': birthday,
      'profession': profession.toJson(),
      'education': education.toJson(),
      'social_media': socialMedia,
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

class ContactProfessionModel {
  final String? id;
  final String? code;
  final String? description;

  ContactProfessionModel({
    this.id,
    this.code,
    this.description,
  });

  factory ContactProfessionModel.fromJson(Map<String, dynamic> json) {
    return ContactProfessionModel(
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

class ContactEducationModel {
  final String? id;
  final String? code;
  final String? description;

  ContactEducationModel({
    this.id,
    this.code,
    this.description,
  });

  factory ContactEducationModel.fromJson(Map<String, dynamic> json) {
    return ContactEducationModel(
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

class ContactAddressModel {
  final String? id;
  final String? address;
  final String? district;
  final String? city;
  final String? countryCode;
  final String? countryName;
  final String? source;
  final double? lat;
  final double? lon;
  final ContactUavtAddressModel uavtAddress;

  ContactAddressModel({
    this.id,
    this.address,
    this.district,
    this.city,
    this.countryCode,
    this.countryName,
    this.source,
    this.lat,
    this.lon,
    required this.uavtAddress,
  });

  factory ContactAddressModel.fromJson(Map<String, dynamic> json) {
    return ContactAddressModel(
      id: json['id'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      countryCode: json['country_code'],
      countryName: json['country_name'],
      source: json['source'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      uavtAddress: ContactUavtAddressModel.fromJson(json['uavt_address'] as Map<String, dynamic>? ?? {}),
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

class ContactUavtAddressModel {
  final int? provinceCode;
  final String? provinceName;
  final int? districtCode;
  final String? districtName;
  final int? quarterCode;
  final String? quarterName;

  ContactUavtAddressModel({
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
    this.quarterCode,
    this.quarterName,
  });

  factory ContactUavtAddressModel.fromJson(Map<String, dynamic> json) {
    return ContactUavtAddressModel(
      provinceCode: json['province_code'],
      provinceName: json['province_name'],
      districtCode: json['district_code'],
      districtName: json['district_name'],
      quarterCode: json['quarter_code'],
      quarterName: json['quarter_name'],
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


