import 'dart:convert';

class ContactModel {
  final int? no;
  final String? title;
  final String? name;
  final String? surname;
  final ContactType? type;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String? nationality;
  final int? sex;
  final String? eMail;
  final String? tel;
  final int? status;
  final ContactDetail? detail;
  final ContactAddress? address;
  final int? connectedContact;
  final String? source;
  final int? advisorLevel;
  final int? startingRate;
  final int? officeRegion;

  ContactModel({
    this.no,
    this.title,
    this.name,
    this.surname,
    this.type,
    this.tcIdNumber,
    this.taxNo,
    this.taxOffice,
    this.nationality,
    this.sex,
    this.eMail,
    this.tel,
    this.status,
    this.detail,
    this.address,
    this.connectedContact,
    this.source,
    this.advisorLevel,
    this.startingRate,
    this.officeRegion,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      no: json['no'],
      title: json['title'],
      name: json['name'],
      surname: json['surname'],
      type: json['type'] != null ? ContactType.fromJson(json['type']) : null,
      tcIdNumber: json['tcIdNumber'],
      taxNo: json['taxNo'],
      taxOffice: json['taxOffice'],
      nationality: json['nationality'],
      sex: json['sex'],
      eMail: json['eMail'],
      tel: json['tel'],
      status: json['status'],
      detail: json['detail'] != null ? ContactDetail.fromJson(json['detail']) : null,
      address: json['address'] != null ? ContactAddress.fromJson(json['address']) : null,
      connectedContact: json['connectedContact'],
      source: json['source'],
      advisorLevel: json['advisor_level'],
      startingRate: json['starting_rate'],
      officeRegion: json['office_region'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'no': no,
      'title': title,
      'name': name,
      'surname': surname,
      'type': type?.toJson(),
      'tcIdNumber': tcIdNumber,
      'taxNo': taxNo,
      'taxOffice': taxOffice,
      'nationality': nationality,
      'sex': sex,
      'eMail': eMail,
      'tel': tel,
      'status': status,
      'detail': detail?.toJson(),
      'address': address?.toJson(),
      'connectedContact': connectedContact,
      'source': source,
      'advisor_level': advisorLevel,
      'starting_rate': startingRate,
      'office_region': officeRegion,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory ContactModel.fromJsonString(String jsonString) {
    return ContactModel.fromJson(jsonDecode(jsonString));
  }

  // Tam adı döndüren yardımcı method
  String get fullName {
    if (name != null && surname != null) {
      return '$name $surname';
    } else if (name != null) {
      return name!;
    } else if (surname != null) {
      return surname!;
    }
    return title ?? 'İsimsiz';
  }

  // Contact tipine göre kısa açıklama
  String get contactTypeDescription {
    if (type == null) return 'Bilinmeyen';
    
    if (type!.isCompany == true) return 'Şirket';
    if (type!.isEmployee == true) return 'Çalışan';
    if (type!.isAgency == true) return 'Ajans';
    if (type!.isCustomer == true) return 'Müşteri';
    if (type!.isAdmin == true) return 'Admin';
    if (type!.isAgencyEmployee == true) return 'Ajans Çalışanı';
    
    return type!.description ?? 'Diğer';
  }
}

class ContactType {
  final int? code;
  final String? description;
  final bool? isCompany;
  final bool? isEmployee;
  final bool? isAgency;
  final bool? isCustomer;
  final bool? isAdmin;
  final bool? isAgencyEmployee;

  ContactType({
    this.code,
    this.description,
    this.isCompany,
    this.isEmployee,
    this.isAgency,
    this.isCustomer,
    this.isAdmin,
    this.isAgencyEmployee,
  });

  factory ContactType.fromJson(Map<String, dynamic> json) {
    return ContactType(
      code: json['code'],
      description: json['description'],
      isCompany: json['is_company'],
      isEmployee: json['is_employee'],
      isAgency: json['is_agency'],
      isCustomer: json['is_customer'],
      isAdmin: json['is_admin'],
      isAgencyEmployee: json['is_agency_employee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'is_company': isCompany,
      'is_employee': isEmployee,
      'is_agency': isAgency,
      'is_customer': isCustomer,
      'is_admin': isAdmin,
      'is_agency_employee': isAgencyEmployee,
    };
  }
}

class ContactDetail {
  final String? id;
  final String? birthday;
  final Profession? profession;
  final Education? education;
  final String? whereYouHeardUs;
  final String? coverLetter;
  final int? sectoralExperience;
  final String? picture;
  final String? reference;
  final List<Attachment>? attachments;
  final String? areasOfExpertise;
  final SocialMedia? socialMedia;
  final bool? marketingCommunicationPermission;
  final int? rating;
  final String? logo;

  ContactDetail({
    this.id,
    this.birthday,
    this.profession,
    this.education,
    this.whereYouHeardUs,
    this.coverLetter,
    this.sectoralExperience,
    this.picture,
    this.reference,
    this.attachments,
    this.areasOfExpertise,
    this.socialMedia,
    this.marketingCommunicationPermission,
    this.rating,
    this.logo,
  });

  factory ContactDetail.fromJson(Map<String, dynamic> json) {
    return ContactDetail(
      id: json['id'],
      birthday: json['birthday'],
      profession: json['profession'] != null ? Profession.fromJson(json['profession']) : null,
      education: json['education'] != null ? Education.fromJson(json['education']) : null,
      whereYouHeardUs: json['whereYouHeardUs'],
      coverLetter: json['coverLetter'],
      sectoralExperience: json['sectoralExperience'],
      picture: json['picture'],
      reference: json['reference'],
      attachments: json['attachments'] != null 
          ? List<Attachment>.from(json['attachments'].map((x) => Attachment.fromJson(x)))
          : null,
      areasOfExpertise: json['areas_of_expertise'],
      socialMedia: json['socialMedia'] != null ? SocialMedia.fromJson(json['socialMedia']) : null,
      marketingCommunicationPermission: json['marketingCommunicationPermission'],
      rating: json['rating'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'birthday': birthday,
      'profession': profession?.toJson(),
      'education': education?.toJson(),
      'whereYouHeardUs': whereYouHeardUs,
      'coverLetter': coverLetter,
      'sectoralExperience': sectoralExperience,
      'picture': picture,
      'reference': reference,
      'attachments': attachments?.map((x) => x.toJson()).toList(),
      'areas_of_expertise': areasOfExpertise,
      'socialMedia': socialMedia?.toJson(),
      'marketingCommunicationPermission': marketingCommunicationPermission,
      'rating': rating,
      'logo': logo,
    };
  }
}

class Profession {
  final String? id;
  final String? code;
  final String? description;

  Profession({
    this.id,
    this.code,
    this.description,
  });

  factory Profession.fromJson(Map<String, dynamic> json) {
    return Profession(
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

class Education {
  final String? id;
  final String? code;
  final String? description;

  Education({
    this.id,
    this.code,
    this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
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

class Attachment {
  final String? id;
  final String? type;
  final String? attachment;
  final String? description;

  Attachment({
    this.id,
    this.type,
    this.attachment,
    this.description,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'],
      type: json['type'],
      attachment: json['attachment'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'attachment': attachment,
      'description': description,
    };
  }
}

class SocialMedia {
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String? facebook;

  SocialMedia({
    this.linkedin,
    this.x,
    this.instagram,
    this.facebook,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
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

class ContactAddress {
  final String? id;
  final int? contact;
  final String? address;
  final String? district;
  final String? city;
  final String? country;
  final String? source;
  final UavtQuarter? uavtQuarter;

  ContactAddress({
    this.id,
    this.contact,
    this.address,
    this.district,
    this.city,
    this.country,
    this.source,
    this.uavtQuarter,
  });

  factory ContactAddress.fromJson(Map<String, dynamic> json) {
    return ContactAddress(
      id: json['id'],
      contact: json['contact'],
      address: json['address'],
      district: json['district'],
      city: json['city'],
      country: json['country'],
      source: json['source'],
      uavtQuarter: json['uavt_quarter'] != null ? UavtQuarter.fromJson(json['uavt_quarter']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact': contact,
      'address': address,
      'district': district,
      'city': city,
      'country': country,
      'source': source,
      'uavt_quarter': uavtQuarter?.toJson(),
    };
  }

  // Tam adresi döndüren yardımcı method
  String get fullAddress {
    List<String> parts = [];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    
    return parts.join(', ');
  }
}

class UavtQuarter {
  final int? code;
  final String? name;
  final String? type;

  UavtQuarter({
    this.code,
    this.name,
    this.type,
  });

  factory UavtQuarter.fromJson(Map<String, dynamic> json) {
    return UavtQuarter(
      code: json['code'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
    };
  }
}
