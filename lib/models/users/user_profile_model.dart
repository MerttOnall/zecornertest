/// User Profile Model - JSON yapısına göre oluşturulmuş
class UserProfileModel {
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
  final String updatedAt;
  final String? source;
  final UserDetailModel detail;
  final dynamic attachments;
  final UserAddressModel address;
  final int connectedContact;
  final String connectedContactTitle;
  final int connectedContactType;
  final String connectedContactDescription;
  final String? connectedContactPicture;
  final String? connectedContactLogo;
  final bool isCustomer;
  final String slug;
  final String connectedContactSlug;
  final int startingRate;
  final int advisorLevel;
  final String? officeRegion;
  final List<UserRoleModel> roles;
  final List<String> permissions;
  final String? eids;
  final bool isAdmin;

  UserProfileModel({
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
    required this.updatedAt,
    this.source,
    required this.detail,
    this.attachments,
    required this.address,
    required this.connectedContact,
    required this.connectedContactTitle,
    required this.connectedContactType,
    required this.connectedContactDescription,
    this.connectedContactPicture,
    this.connectedContactLogo,
    required this.isCustomer,
    required this.slug,
    required this.connectedContactSlug,
    required this.startingRate,
    required this.advisorLevel,
    this.officeRegion,
    required this.roles,
    required this.permissions,
    this.eids,
    this.isAdmin = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? 0;
    }

    return UserProfileModel(
      contactNo: asInt(json['contact_no']),
      title: json['title'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      type: asInt(json['type']),
      typeDescription: json['type_description'] ?? '',
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'],
      taxOffice: json['tax_office'],
      nationality: json['nationality'] ?? 'TR',
      sex: json['sex'],
      email: json['e_mail'] ?? '',
      tel: json['tel'] ?? '',
      status: asInt(json['status']),
      updatedAt: json['updated_at'] ?? '',
      source: json['source'],
      detail: UserDetailModel.fromJson(
        json['detail'] is Map
            ? Map<String, dynamic>.from(json['detail'] as Map)
            : <String, dynamic>{},
      ),
      attachments: json['attachments'],
      address: UserAddressModel.fromJson(
        json['address'] is Map
            ? Map<String, dynamic>.from(json['address'] as Map)
            : <String, dynamic>{},
      ),
      connectedContact: asInt(json['connected_contact']),
      connectedContactTitle: json['connected_contact_title'] ?? '',
      connectedContactType: asInt(json['connected_contact_type']),
      connectedContactDescription: json['connected_contact_description'] ?? '',
      connectedContactPicture: json['connected_contact_picture'],
      connectedContactLogo: json['connected_contact_logo'],
      isCustomer: json['is_customer'] ?? false,
      slug: json['slug'] ?? '',
      connectedContactSlug: json['connected_contact_slug'] ?? '',
      startingRate: asInt(json['starting_rate']),
      advisorLevel: asInt(json['advisor_level']),
      officeRegion: json['office_region'],
      roles: (json['roles'] as List<dynamic>?)
          ?.map((role) => UserRoleModel.fromJson(
                Map<String, dynamic>.from(role as Map),
              ))
          .toList() ?? [],
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((permission) => permission.toString())
          .toList() ?? [],
      eids: json['eids']?.toString(),
      isAdmin: json['is_admin'] == true,
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
      'roles': roles.map((role) => role.toJson()).toList(),
      'permissions': permissions,
      'eids': eids,
      'is_admin': isAdmin,
    };
  }

  // Güncelleme için sadece değişen alanları döndür
  Map<String, dynamic> toUpdateJson() {
    final detailJson = detail.toUpdateJson();
    if (attachments != null) {
      detailJson['attachments'] = attachments;
    }
    return {
      'name': name,
      'surname': surname,
      'e_mail': email,
      'tel': tel,
      if (eids != null && eids!.trim().isNotEmpty) 'eids': eids,
      'detail': detailJson,
      'address': address.toUpdateJson(),
    };
  }
}

class UserDetailModel {
  final String id;
  final String? birthday;
  final UserProfessionModel? profession;
  final UserEducationModel? education;
  final UserSocialMediaModel? socialMedia;
  final String? whereYouHeardUs;
  final String? coverLetter;
  final int? sectoralExperience;
  final String? picture;
  final String? reference;
  final String? areasOfExpertise;
  final bool marketingCommunicationPermission;
  final dynamic rating;
  final String? logo;
  final dynamic detail;

  UserDetailModel({
    required this.id,
    this.birthday,
    this.profession,
    this.education,
    this.socialMedia,
    this.whereYouHeardUs,
    this.coverLetter,
    this.sectoralExperience,
    this.picture,
    this.reference,
    this.areasOfExpertise,
    this.marketingCommunicationPermission = false,
    this.rating,
    this.logo,
    this.detail,
  });

  factory UserDetailModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final profession = asMap(json['profession']);
    final education = asMap(json['education']);
    final social = asMap(json['social_media']);

    return UserDetailModel(
      id: json['id']?.toString() ?? '',
      birthday: json['birthday']?.toString(),
      profession: profession != null
          ? UserProfessionModel.fromJson(profession)
          : null,
      education: education != null
          ? UserEducationModel.fromJson(education)
          : null,
      socialMedia:
          social != null ? UserSocialMediaModel.fromJson(social) : null,
      whereYouHeardUs: json['where_you_heard_us'],
      coverLetter: json['cover_letter'],
      sectoralExperience: json['sectoral_experience'] is int
          ? json['sectoral_experience'] as int
          : int.tryParse('${json['sectoral_experience'] ?? ''}'),
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
      'social_media': socialMedia?.toJson(),
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

  Map<String, dynamic> toUpdateJson() {
    return {
      'profession': profession?.toJson(),
      'education': education?.toJson(),
      'social_media': socialMedia?.toJson(),
      'cover_letter': coverLetter,
      'sectoral_experience': sectoralExperience,
      'reference': reference,
      'areas_of_expertise': areasOfExpertise,
      'marketing_communication_permission': marketingCommunicationPermission,
    };
  }
}

class UserProfessionModel {
  final String id;
  final String code;
  final String description;

  UserProfessionModel({
    required this.id,
    required this.code,
    required this.description,
  });

  factory UserProfessionModel.fromJson(Map<String, dynamic> json) {
    return UserProfessionModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
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

class UserEducationModel {
  final String id;
  final String code;
  final String description;

  UserEducationModel({
    required this.id,
    required this.code,
    required this.description,
  });

  factory UserEducationModel.fromJson(Map<String, dynamic> json) {
    return UserEducationModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
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

class UserSocialMediaModel {
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String? facebook;

  UserSocialMediaModel({
    this.linkedin,
    this.x,
    this.instagram,
    this.facebook,
  });

  factory UserSocialMediaModel.fromJson(Map<String, dynamic> json) {
    return UserSocialMediaModel(
      linkedin: json['linkedin'],
      x: json['x'],
      instagram: json['instagram'],
      facebook: json['facebook'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'linkedin': linkedin,
      'x': x,
      'instagram': instagram,
      'facebook': facebook,
    };
  }
}

class UserAddressModel {
  final String id;
  final String address;
  final int district;
  final int city;
  final String countryCode;
  final String countryName;
  final String? source;
  final double? lat;
  final double? lon;
  final UserUavtAddressModel? uavtAddress;

  UserAddressModel({
    required this.id,
    required this.address,
    required this.district,
    required this.city,
    required this.countryCode,
    required this.countryName,
    this.source,
    this.lat,
    this.lon,
    this.uavtAddress,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().trim()) ?? 0;
    }

    return UserAddressModel(
      id: json['id']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      district: asInt(json['district']),
      city: asInt(json['city']),
      countryCode: json['country_code'] ?? 'TR',
      countryName: json['country_name'] ?? 'Türkiye Cumhuriyeti',
      source: json['source'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      uavtAddress: json['uavt_address'] != null 
          ? UserUavtAddressModel.fromJson(json['uavt_address'])
          : null,
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
      'uavt_address': uavtAddress?.toJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'address': address,
      'district': district,
      'city': city,
    };
  }
}

class UserUavtAddressModel {
  final int provinceCode;
  final String provinceName;
  final int districtCode;
  final String districtName;
  final int quarterCode;
  final String quarterName;

  UserUavtAddressModel({
    required this.provinceCode,
    required this.provinceName,
    required this.districtCode,
    required this.districtName,
    required this.quarterCode,
    required this.quarterName,
  });

  factory UserUavtAddressModel.fromJson(Map<String, dynamic> json) {
    return UserUavtAddressModel(
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

class UserRoleModel {
  final String name;
  final String code;
  final bool isAdmin;

  UserRoleModel({
    required this.name,
    required this.code,
    required this.isAdmin,
  });

  factory UserRoleModel.fromJson(Map<String, dynamic> json) {
    return UserRoleModel(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isAdmin: json['is_admin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'is_admin': isAdmin,
    };
  }
}