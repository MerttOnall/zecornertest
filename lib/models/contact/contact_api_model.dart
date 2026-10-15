class ContactApiModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final String type;
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
  final String? country;
  final String? addressSource;
  final String? provinceCode;
  final String? provinceName;
  final String? districtCode;
  final String? districtName;
  final String? quarterCode;
  final String? quarterName;
  final int? connectedContact;
  final String? connectedContactTitle;
  final int? connectedContactType;
  final String? connectedContactDescription;
  final bool isCustomer;
  final String slug;
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? linkedin;
  final String? pastExperience;
  final String? coverLetter;
  final String? references;
  final String? aboutMe; // Hakkımda 
  final int? birthPlaceCode; // Doğum Yeri Kodu
  final String? birthPlaceName; // Doğum Yeri Adı
  final String? maritalStatus; // Medeni Durum
  final String? size; // Beden
  final bool? isForeignNationality; // Yabancı Uyruk
  final List<Map<String, dynamic>>? detailAttachments; // Mevcut belgeler (güncellemede korunacak)

  ContactApiModel({
    required this.contactNo,
    required this.title,
    required this.name,
    required this.surname,
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
    this.country,
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
    this.instagram,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.pastExperience,
    this.coverLetter,
    this.references,
    this.aboutMe,
    this.birthPlaceCode,
    this.birthPlaceName,
    this.maritalStatus,
    this.size,
    this.isForeignNationality,
    this.detailAttachments,
  });

  factory ContactApiModel.fromJson(Map<String, dynamic> json) {
    return ContactApiModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      type: _readTypeCode(json['type']) ?? '1',
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'],
      taxOffice: json['tax_office'],
      nationality: json['nationality'] ?? 'TR',
      sex: json['sex'],
      eMail: json['e_mail']?.toString() ?? '',
      tel: json['tel']?.toString() ?? '0',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      source: json['source']?.toString(),
      typeDescription: json['type_description']?.toString() ?? '',
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      birthday: json['detail']?['birthday']?.toString(),
      professionCode: json['detail']?['profession']?['code']?.toString(),
      professionDescription: json['detail']?['profession']?['description']?.toString(),
      educationCode: json['detail']?['education']?['code']?.toString(),
      educationDescription: json['detail']?['education']?['description']?.toString(),
      whereYouHeardUs: json['detail']?['where_you_heard_us']?.toString(),
      sectoralExperience: json['detail']?['sectoral_experience'],
      picture: json['detail']?['picture']?.toString(),
      marketingCommunicationPermission: json['detail']?['marketing_communication_permission'] ?? false,
      address: json['address']?['address']?.toString(),
      district: json['address']?['district']?.toString(),
      postCode: json['address']?['post_code']?.toString(),
      city: json['address']?['city']?.toString(),
      country: json['address']?['country']?.toString(),
      addressSource: json['address']?['address_source']?.toString(),
      provinceCode: json['address']?['province_code']?.toString(),
      provinceName: json['address']?['province_name']?.toString(),
      districtCode: json['address']?['district_code']?.toString(),
      districtName: json['address']?['district_name']?.toString(),
      quarterCode: json['address']?['quarter_code']?.toString(),
      quarterName: json['address']?['quarter_name']?.toString(),
      connectedContact: json['connected_contact'],
      connectedContactTitle: json['connected_contact_title']?.toString(),
      connectedContactType: json['connected_contact_type'],
      connectedContactDescription: json['connected_contact_description']?.toString(),
      isCustomer: json['is_customer'] ?? false,
      slug: json['slug']?.toString() ?? '',
      instagram: json['detail']?['instagram']?.toString(),
      facebook: json['detail']?['facebook']?.toString(),
      twitter: json['detail']?['twitter']?.toString(),
      linkedin: json['detail']?['linkedin']?.toString(),
      pastExperience: json['detail']?['past_experience']?.toString(),
      coverLetter: json['detail']?['cover_letter']?.toString(),
      references: json['detail']?['references']?.toString(),
      aboutMe: json['detail']?['about_me']?.toString(),
      birthPlaceCode: json['detail']?['birth_place_code'],
      birthPlaceName: json['detail']?['birth_place_name']?.toString(),
      maritalStatus: json['detail']?['marital_status']?.toString(),
      size: json['detail']?['size']?.toString(),
      isForeignNationality: json['detail']?['is_foreign_nationality'],
      detailAttachments: json['detail']?['attachments'] != null
          ? List<Map<String, dynamic>>.from(
              (json['detail']!['attachments'] as List).map((e) => Map<String, dynamic>.from(e as Map)))
          : null,
    );
  }

  /// Adres: DB/API il ve ilçe için **kod (int)** bekliyor; isimleri `*_name` alanlarında gönder.
  Map<String, dynamic> _buildAddressPayload() {
    final out = <String, dynamic>{};

    int? pCode = int.tryParse(provinceCode ?? '');
    if (pCode == null && city != null && city!.isNotEmpty) {
      pCode = int.tryParse(city!);
    }
    int? dCode = int.tryParse(districtCode ?? '');
    if (dCode == null && district != null && district!.isNotEmpty) {
      dCode = int.tryParse(district!);
    }
    final qCode = int.tryParse(quarterCode ?? '');

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
    if (country != null && country!.isNotEmpty) {
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

  Map<String, dynamic> toJson() {
    // Ana request objesi (camelCase formatı - Add sayfası ile aynı)
    final requestData = <String, dynamic>{
      'name': name,
      'surname': surname,
      'tel': tel,
      'eMail': eMail, // camelCase
      'nationality': nationality,
      'sex': sex ?? 1, // Default: Erkek
      'type': {
        'code': type, // String olarak obje içinde
      },
      'status': status,
    };
    
    // TC Kimlik (opsiyonel)
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) {
      requestData['tcIdNumber'] = tcIdNumber; // camelCase
    }
    
    // Detail objesi (opsiyonel)
    final detailObj = <String, dynamic>{};
    
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
    
    // Social Media
    final socialMediaObj = <String, dynamic>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialMediaObj['instagram'] = instagram!;
    }
    if (twitter != null && twitter!.isNotEmpty) {
      socialMediaObj['x'] = twitter!;
    }
    if (linkedin != null && linkedin!.isNotEmpty) {
      socialMediaObj['linkedin'] = linkedin!;
    }
    if (facebook != null && facebook!.isNotEmpty) {
      socialMediaObj['facebook'] = facebook!;
    }
    if (socialMediaObj.isNotEmpty) {
      detailObj['socialMedia'] = socialMediaObj; // camelCase
    }
    
    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = whereYouHeardUs!; // camelCase
    }
    if (coverLetter != null && coverLetter!.isNotEmpty) {
      detailObj['coverLetter'] = coverLetter!; // camelCase
    }
    if (sectoralExperience != null) {
      detailObj['sectoralExperience'] = sectoralExperience!; // camelCase
    }
    if (references != null && references!.isNotEmpty) {
      detailObj['references'] = references!; // references (not reference)
    }
    if (pastExperience != null && pastExperience!.isNotEmpty) {
      detailObj['pastExperience'] = pastExperience!;
    }
    if (picture != null && picture!.isNotEmpty) {
      detailObj['picture'] = picture!;
    }
    if (aboutMe != null && aboutMe!.isNotEmpty) {
      detailObj['aboutMe'] = aboutMe!;
    }
    if (birthPlaceCode != null) {
      detailObj['birthPlaceCode'] = birthPlaceCode!;
    }
    if (birthPlaceName != null && birthPlaceName!.isNotEmpty) {
      detailObj['birthPlaceName'] = birthPlaceName!;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      detailObj['maritalStatus'] = maritalStatus!;
    }
    if (size != null && size!.isNotEmpty) {
      detailObj['size'] = size!;
    }
    if (isForeignNationality != null) {
      detailObj['isForeignNationality'] = isForeignNationality!;
    }
    
    // Attachments (boş array bile olabilir - opsiyonel)
    // detailObj['attachments'] = []; // SADECE gerekliyse ekle
    
    // Detail objesini ekle (sadece boş değilse)
    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }
    
    final addressObj = _buildAddressPayload();
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

  // Update için özel JSON metodu (Add sayfasını bozmamak için ayrı)
  Map<String, dynamic> toUpdateJson() {
    // Ana request objesi (camelCase formatı)
    final requestData = <String, dynamic>{
      'name': name,
      'surname': surname,
      'tel': tel,
      'eMail': eMail,
      'nationality': nationality,
      'sex': sex ?? 1,
      'type': {
        'code': type.toString(), // String olarak
      },
      'status': status,
    };

    // TC Kimlik (opsiyonel)
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) {
      requestData['tcIdNumber'] = tcIdNumber;
    }

    // Detail objesi (opsiyonel)
    final detailObj = <String, dynamic>{};

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

    // Social Media
    final socialMediaObj = <String, dynamic>{};
    if (instagram != null && instagram!.isNotEmpty) {
      socialMediaObj['instagram'] = instagram!;
    }
    if (twitter != null && twitter!.isNotEmpty) {
      socialMediaObj['x'] = twitter!;
    }
    if (linkedin != null && linkedin!.isNotEmpty) {
      socialMediaObj['linkedin'] = linkedin!;
    }
    if (facebook != null && facebook!.isNotEmpty) {
      socialMediaObj['facebook'] = facebook!;
    }
    if (socialMediaObj.isNotEmpty) {
      detailObj['socialMedia'] = socialMediaObj;
    }

    if (whereYouHeardUs != null && whereYouHeardUs!.isNotEmpty) {
      detailObj['whereYouHeardUs'] = whereYouHeardUs!;
    }
    if (coverLetter != null && coverLetter!.isNotEmpty) {
      detailObj['coverLetter'] = coverLetter!;
    }
    if (sectoralExperience != null) {
      detailObj['sectoralExperience'] = sectoralExperience!;
    }
    if (references != null && references!.isNotEmpty) {
      detailObj['references'] = references!;
    }
    if (pastExperience != null && pastExperience!.isNotEmpty) {
      detailObj['pastExperience'] = pastExperience!;
    }
    if (picture != null && picture!.isNotEmpty) {
      detailObj['picture'] = picture!;
    }
    if (aboutMe != null && aboutMe!.isNotEmpty) {
      detailObj['aboutMe'] = aboutMe!;
    }
    if (birthPlaceCode != null) {
      detailObj['birthPlaceCode'] = birthPlaceCode!;
    }
    if (birthPlaceName != null && birthPlaceName!.isNotEmpty) {
      detailObj['birthPlaceName'] = birthPlaceName!;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      detailObj['maritalStatus'] = maritalStatus!;
    }
    if (size != null && size!.isNotEmpty) {
      detailObj['size'] = size!;
    }
    if (isForeignNationality != null) {
      detailObj['isForeignNationality'] = isForeignNationality!;
    }

    // Attachments (backend bunu mutlaka bekliyor - boş array bile olsa)
    detailObj['attachments'] = [];

    // Detail objesini ekle (sadece boş değilse)
    if (detailObj.isNotEmpty) {
      requestData['detail'] = detailObj;
    }

    requestData['address'] = _buildAddressPayload();

    // Connected contact (opsiyonel)
    if (connectedContact != null) {
      requestData['connectedContact'] = connectedContact;
    }

    // Marketing permission
    requestData['marketingCommunicationPermission'] = marketingCommunicationPermission;

    return requestData;
  }

  // Tam adı döndüren yardımcı method
  String get fullName {
    if (name.isNotEmpty && surname.isNotEmpty) {
      return '$name $surname';
    } else if (name.isNotEmpty) {
      return name;
    } else if (surname.isNotEmpty) {
      return surname;
    }
    return title;
  }

  // Aktif durumu kontrol eden method
  bool get isActive => status == 1;

  // Telefon numarası kontrol eden method
  String get displayPhone => tel == "0" ? "Belirtilmemiş" : tel;

  // E-posta kısaltma methodu
  String get displayEmail {
    if (eMail.length > 20) {
      return '${eMail.substring(0, 17)}...';
    }
    return eMail;
  }
}

class ContactApiResponse {
  final List<ContactApiModel> contacts;
  final int totalCount;
  final int totalPages;
  final int page;

  ContactApiResponse({
    required this.contacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ContactApiResponse.fromJson(Map<String, dynamic> json) {
    return ContactApiResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((contactJson) => ContactApiModel.fromJson(contactJson))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }
}

String? _readTypeCode(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return _readTypeCode(value['code'] ?? value['id']);
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
