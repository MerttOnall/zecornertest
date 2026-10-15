import 'package:zecorner/core/utils/image_utils.dart';

class OfficePersonsApiModel {
  final int contactNo;
  final String title;
  final String? name;
  final String? surname;
  final int? type;
  final String? typeDescription;
  final String? eMail;
  final String? tel;
  final int? status;
  final bool isCompany;
  final bool isEmployee;
  final bool isAgency;
  final bool isCustomer;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String? nationality;
  final String? sex;
  final int? connectedContact;
  final String? connectedContactTitle;
  final String? createdAt;
  final String? updatedAt;
  final String? birthday;
  final String? professionCode;
  final String? professionDescription;
  final String? educationCode;
  final String? educationDescription;
  final int? sectoralExperience;
  final String? picture;
  final bool? marketingCommunicationPermission;
  final String? address;
  final String? district;
  final String? postCode;
  final String? city;
  final String? country;
  final int? connectedContactType;
  final String? connectedContactDescription;
  final String? slug;

  OfficePersonsApiModel({
    required this.contactNo,
    required this.title,
    this.name,
    this.surname,
    this.type,
    this.typeDescription,
    this.eMail,
    this.tel,
    this.status,
    required this.isCompany,
    required this.isEmployee,
    required this.isAgency,
    required this.isCustomer,
    this.tcIdNumber,
    this.taxNo,
    this.taxOffice,
    this.nationality,
    this.sex,
    this.connectedContact,
    this.connectedContactTitle,
    this.createdAt,
    this.updatedAt,
    this.birthday,
    this.professionCode,
    this.professionDescription,
    this.educationCode,
    this.educationDescription,
    this.sectoralExperience,
    this.picture,
    this.marketingCommunicationPermission,
    this.address,
    this.district,
    this.postCode,
    this.city,
    this.country,
    this.connectedContactType,
    this.connectedContactDescription,
    this.slug,
  });

  factory OfficePersonsApiModel.fromJson(Map<String, dynamic> json) {
    return OfficePersonsApiModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      name: json['name'],
      surname: json['surname'],
      type: json['type'],
      typeDescription: json['type_description'],
      eMail: json['e_mail'],
      tel: json['tel'],
      status: json['status'],
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      isCustomer: json['is_customer'] ?? false,
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'],
      taxOffice: json['tax_office'],
      nationality: json['nationality'],
      sex: json['sex'],
      connectedContact: json['connected_contact'],
      connectedContactTitle: json['connected_contact_title'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      birthday: json['birthday'],
      professionCode: json['profession_code'],
      professionDescription: json['profession_description'],
      educationCode: json['education_code'],
      educationDescription: json['education_description'],
      sectoralExperience: json['sectoral_experience'],
      picture: json['picture'],
      marketingCommunicationPermission: json['marketing_communication_permission'],
      address: json['address'],
      district: json['district'],
      postCode: json['post_code'],
      city: json['city'],
      country: json['country'],
      connectedContactType: json['connected_contact_type'],
      connectedContactDescription: json['connected_contact_description'],
      slug: json['slug'],
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
      'e_mail': eMail,
      'tel': tel,
      'status': status,
      'is_company': isCompany,
      'is_employee': isEmployee,
      'is_agency': isAgency,
      'is_customer': isCustomer,
      'tc_id_number': tcIdNumber,
      'tax_no': taxNo,
      'tax_office': taxOffice,
      'nationality': nationality,
      'sex': sex,
      'connected_contact': connectedContact,
      'connected_contact_title': connectedContactTitle,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'birthday': birthday,
      'profession_code': professionCode,
      'profession_description': professionDescription,
      'education_code': educationCode,
      'education_description': educationDescription,
      'sectoral_experience': sectoralExperience,
      'picture': picture,
      'marketing_communication_permission': marketingCommunicationPermission,
      'address': address,
      'district': district,
      'post_code': postCode,
      'city': city,
      'country': country,
      'connected_contact_type': connectedContactType,
      'connected_contact_description': connectedContactDescription,
      'slug': slug,
    };
  }

  // Helper getters
  bool get isActive => status == 1;
  
  // Status helper getters for different statuses
  String get statusText {
    switch (status) {
      case 0:
        return 'Pasif';
      case 1:
        return 'Aktif';
      case 3:
        return 'Onay Bekliyor';
      case 5:
        return 'Ödeme Bekleniyor';
      case 6:
        return 'Düzenleme Bekleniyor';
      default:
        return 'Bilinmiyor';
    }
  }
  
  // Status emoji/symbol for quick visual identification
  String get statusEmoji {
    switch (status) {
      case 0:
        return '⛔';
      case 1:
        return '✓';
      case 3:
        return '⏳';
      case 5:
        return '💳';
      case 6:
        return '✏️';
      default:
        return '?';
    }
  }
  
  // Status color getter - Modern vibrant colors
  int get statusColorValue {
    switch (status) {
      case 0:
        return 0xFFDC2626; // Modern Red - Pasif
      case 1:
        return 0xFF16A34A; // Modern Green - Aktif
      case 3:
        return 0xFFF59E0B; // Modern Amber - Onay Bekliyor
      case 5:
        return 0xFFDC2626; // Modern Red - Ödeme Bekleniyor
      case 6:
        return 0xFFEA580C; // Modern Orange - Düzenleme Bekleniyor
      default:
        return 0xFF6B7280; // Modern Grey - Unknown
    }
  }
  
  // Background color for status badge (lighter version)
  int get statusBackgroundColorValue {
    switch (status) {
      case 0:
        return 0xFFFEE2E2; // Light Red - Pasif
      case 1:
        return 0xFFDCFCE7; // Light Green - Aktif
      case 3:
        return 0xFFFEF3C7; // Light Amber - Onay Bekliyor
      case 5:
        return 0xFFFEE2E2; // Light Red - Ödeme Bekleniyor
      case 6:
        return 0xFFFFEDD5; // Light Orange - Düzenleme Bekleniyor
      default:
        return 0xFFF3F4F6; // Light Grey
    }
  }
  
  // Border color for status badge
  int get statusBorderColorValue {
    switch (status) {
      case 0:
        return 0xFFFCA5A5; // Red border - Pasif
      case 1:
        return 0xFF86EFAC; // Green border - Aktif
      case 3:
        return 0xFFFCD34D; // Amber border - Onay Bekliyor
      case 5:
        return 0xFFFCA5A5; // Red border - Ödeme Bekleniyor
      case 6:
        return 0xFFFDBA74; // Orange border - Düzenleme Bekleniyor
      default:
        return 0xFFD1D5DB; // Grey border
    }
  }
  
  // Check if status shows payment is needed
  bool get isPaymentPending => status == 5;
  
  String get fullName {
    if (name != null && surname != null) {
      return '$name $surname';
    }
    return title;
  }
  
  String get displayEmail => eMail == null || eMail!.isEmpty ? "Belirtilmemiş" : eMail!;
  
  String get displayPhone => tel == "0" || tel == null || tel!.isEmpty ? "Belirtilmemiş" : tel!;
  
  String get displayAddress => address ?? "Adres belirtilmemiş";
  
  String get displayTaxOffice => taxOffice == null || taxOffice!.isEmpty ? "Belirtilmemiş" : taxOffice!;
  
  String get displayTaxNo => taxNo == null || taxNo!.isEmpty ? "Belirtilmemiş" : taxNo!;
  
  String get displayTcId => tcIdNumber == null || tcIdNumber!.isEmpty ? "Belirtilmemiş" : tcIdNumber!;
  
  String get displayNationality {
    switch (nationality) {
      case "TR": return "Türkiye Cumhuriyeti";
      case "US": return "Amerika Birleşik Devletleri";
      case "DE": return "Almanya";
      case "FR": return "Fransa";
      case "GB": return "Birleşik Krallık";
      default: return nationality ?? "Belirtilmemiş";
    }
  }
  
  String get displaySex {
    switch (sex) {
      case "M": return "Erkek";
      case "F": return "Kadın";
      default: return "Belirtilmemiş";
    }
  }
  
  String get userType {
    switch (type) {
      case 10: return "Broker";
      case 11: return "Gayrimenkul Danışmanı";
      case 12: return "Takım Lideri";
      case 13: return "Ofis Asistanı";
      default: return typeDescription ?? "Belirtilmemiş";
    }
  }
  
  String get formattedCreatedDate {
    if (createdAt == null) return "Belirtilmemiş";
    try {
      final date = DateTime.parse(createdAt!);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (e) {
      return createdAt!;
    }
  }
  
  String get formattedCreatedTime {
    if (createdAt == null) return "Belirtilmemiş";
    try {
      final date = DateTime.parse(createdAt!);
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Belirtilmemiş";
    }
  }
  
  String get experience {
    if (sectoralExperience != null) {
      return sectoralExperience.toString();
    }
    return "-";
  }
  
  String get profileImageUrl {
    if (picture != null && picture!.isNotEmpty) {
      return ImageUtils.getProfileImageUrl(picture);
    }
    return "";
  }
}

class OfficePersonsDetail {
  final String? logo;
  final String? description;
  final OfficePersonsDetailInfo? detail;

  OfficePersonsDetail({
    this.logo,
    this.description,
    this.detail,
  });

  factory OfficePersonsDetail.fromJson(Map<String, dynamic> json) {
    return OfficePersonsDetail(
      logo: json['logo'],
      description: json['description'],
      detail: json['detail'] != null ? OfficePersonsDetailInfo.fromJson(json['detail']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo,
      'description': description,
      'detail': detail?.toJson(),
    };
  }
}

class OfficePersonsDetailInfo {
  final int? experience;
  final String? profession;
  final String? education;
  final String? maritalStatus;
  final int? childrenAmount;
  final String? monthlySalary;
  final List<String>? tags;

  OfficePersonsDetailInfo({
    this.experience,
    this.profession,
    this.education,
    this.maritalStatus,
    this.childrenAmount,
    this.monthlySalary,
    this.tags,
  });

  factory OfficePersonsDetailInfo.fromJson(Map<String, dynamic> json) {
    return OfficePersonsDetailInfo(
      experience: json['experience'],
      profession: json['profession'],
      education: json['education'],
      maritalStatus: json['marital_status'],
      childrenAmount: json['children_amount'],
      monthlySalary: json['monthly_salary'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experience': experience,
      'profession': profession,
      'education': education,
      'marital_status': maritalStatus,
      'children_amount': childrenAmount,
      'monthly_salary': monthlySalary,
      'tags': tags,
    };
  }
}

class OfficePersonsAddress {
  final String? country;
  final String? city;
  final String? district;
  final String? neighborhood;
  final String? street;
  final String? buildingNo;
  final String? apartmentNo;
  final String? postalCode;
  final String? addressText;

  OfficePersonsAddress({
    this.country,
    this.city,
    this.district,
    this.neighborhood,
    this.street,
    this.buildingNo,
    this.apartmentNo,
    this.postalCode,
    this.addressText,
  });

  factory OfficePersonsAddress.fromJson(Map<String, dynamic> json) {
    return OfficePersonsAddress(
      country: json['country'],
      city: json['city'],
      district: json['district'],
      neighborhood: json['neighborhood'],
      street: json['street'],
      buildingNo: json['building_no'],
      apartmentNo: json['apartment_no'],
      postalCode: json['postal_code'],
      addressText: json['address_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'street': street,
      'building_no': buildingNo,
      'apartment_no': apartmentNo,
      'postal_code': postalCode,
      'address_text': addressText,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (country != null && country!.isNotEmpty) parts.add(country!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (buildingNo != null && buildingNo!.isNotEmpty) parts.add('No: $buildingNo');
    if (apartmentNo != null && apartmentNo!.isNotEmpty) parts.add('Daire: $apartmentNo');
    
    if (parts.isEmpty && addressText != null && addressText!.isNotEmpty) {
      return addressText!;
    }
    
    return parts.join(', ');
  }
}

class OfficePersonsApiResponse {
  final List<OfficePersonsApiModel> contacts;
  final int totalCount;
  final int totalPages;
  final int page;

  OfficePersonsApiResponse({
    required this.contacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory OfficePersonsApiResponse.fromJson(Map<String, dynamic> json) {
    return OfficePersonsApiResponse(
      contacts: (json['contacts'] as List<dynamic>?)
          ?.map((contact) => OfficePersonsApiModel.fromJson(contact))
          .toList() ?? [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
