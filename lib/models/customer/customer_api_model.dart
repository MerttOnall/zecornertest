class CustomerApiModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final int type;
  final String typeDescription;
  final String? tcIdNumber;
  final String taxNo;
  final String taxOffice;
  final String nationality;
  final String? sex;
  final String eMail;
  final String tel;
  final int status;
  final String? updatedAt;
  final String? source;
  final CustomerDetail detail;
  final int? connectedContact;
  final String createdAt;

  CustomerApiModel({
    required this.contactNo,
    required this.title,
    required this.name,
    required this.surname,
    required this.type,
    required this.typeDescription,
    this.tcIdNumber,
    required this.taxNo,
    required this.taxOffice,
    required this.nationality,
    this.sex,
    required this.eMail,
    required this.tel,
    required this.status,
    this.updatedAt,
    this.source,
    required this.detail,
    this.connectedContact,
    required this.createdAt,
  });

  factory CustomerApiModel.fromJson(Map<String, dynamic> json) {
    final detailJson = json['detail'];
    return CustomerApiModel(
      contactNo: _asInt(json['contact_no']),
      title: _asString(json['title']),
      name: _asString(json['name']),
      surname: _asString(json['surname']),
      type: _asTypeCode(json['type']),
      typeDescription: _asString(json['type_description']),
      tcIdNumber: _asNullableString(json['tc_id_number']),
      taxNo: _asString(json['tax_no']),
      taxOffice: _asString(json['tax_office']),
      nationality: _asString(json['nationality'], fallback: 'TR'),
      sex: _asNullableString(json['sex']),
      eMail: _asString(json['e_mail']),
      tel: _asString(json['tel']),
      status: _asInt(json['status']),
      updatedAt: _asNullableString(json['updated_at']),
      source: _asNullableString(json['source']),
      detail: detailJson is Map<String, dynamic>
          ? CustomerDetail.fromJson(detailJson)
          : CustomerDetail.empty(),
      connectedContact: json['connected_contact'] == null
          ? null
          : _asInt(json['connected_contact']),
      createdAt: _asString(json['created_at']),
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
      'connected_contact': connectedContact,
      'created_at': createdAt,
    };
  }

  // Backend'in CREATE endpoint'i için özel serileştirme
  Map<String, dynamic> toCreateJson() {
    return {
      'status': status,
      'name': name,
      'surname': surname,
      'type': type,
      if (tcIdNumber != null && tcIdNumber!.isNotEmpty) 'tc_id_number': tcIdNumber,
      if (taxNo.isNotEmpty) 'tax_no': taxNo,
      if (taxOffice.isNotEmpty) 'tax_office': taxOffice,
      'nationality': nationality,
      if (sex != null) 'sex': sex,
      'e_mail': eMail,
      'tel': tel,
      'listings': [],
      'real_estates': [],
      'detail': {
        if (detail.birthday != null && detail.birthday!.isNotEmpty) 'birthday': detail.birthday,
        if (_isServerRef(detail.profession?.id)) 'profession': detail.profession!.id,
        if (!_isServerRef(detail.profession?.id) && _isServerRef(detail.profession?.code))
          'profession': detail.profession!.code,
        if (_isServerRef(detail.education?.id)) 'education': detail.education!.id,
        if (detail.picture != null && detail.picture!.isNotEmpty) 'picture': detail.picture,
        if (detail.socialMedia?.instagram != null ||
            detail.socialMedia?.facebook != null ||
            detail.socialMedia?.x != null ||
            detail.socialMedia?.linkedin != null)
          'social_media': {
            if (detail.socialMedia?.instagram != null) 'instagram': detail.socialMedia!.instagram,
            if (detail.socialMedia?.facebook != null) 'facebook': detail.socialMedia!.facebook,
            if (detail.socialMedia?.x != null) 'x': detail.socialMedia!.x,
            if (detail.socialMedia?.linkedin != null) 'linkedin': detail.socialMedia!.linkedin,
          },
        if (detail.whereYouHeardUs.isNotEmpty) 'where_you_heard_us': detail.whereYouHeardUs,
        if (detail.coverLetter.isNotEmpty) 'cover_letter': detail.coverLetter,
        'detail': {
          if (detail.detail?.tags != null && detail.detail!.tags!.isNotEmpty) 'tags': detail.detail!.tags,
          'children_amount': detail.detail?.childrenAmount ?? 0,
          if (detail.detail?.monthlySalary != null &&
              detail.detail!.monthlySalary!.isNotEmpty &&
              detail.detail!.monthlySalary != 'N/A')
            'monthly_salary': detail.detail!.monthlySalary,
          if (detail.detail?.maritalStatus != null) 'marital_status': detail.detail!.maritalStatus,
        },
      },
    };
  }

  // Helper getters
  bool get isActive => status == 1;
  String get fullName => '$name $surname';
  String get displayPhone => tel.isEmpty ? 'N/A' : tel;
  String get displayEmail => eMail.isEmpty ? 'N/A' : eMail;
  String get displayTaxNo => taxNo.isEmpty ? 'N/A' : taxNo;
  String get displayTaxOffice => taxOffice.isEmpty ? 'N/A' : taxOffice;
  String get displayProfession => detail.profession?.description ?? 'N/A';
  String get displayEducation => detail.education?.description ?? 'N/A';
  String get displayGender => sex == 'M' ? 'Erkek' : sex == 'F' ? 'Kadın' : 'N/A';
  String get displayMaritalStatus {
    if (detail.detail?.maritalStatus == '1') return 'Bekar';
    if (detail.detail?.maritalStatus == '2') return 'Evli';
    return 'N/A';
  }
  int get childrenCount => detail.detail?.childrenAmount ?? 0;
  String get monthlySalary => detail.detail?.monthlySalary ?? 'N/A';
  List<String> get tags => detail.detail?.tags ?? [];
  
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

class CustomerDetail {
  final String id;
  final String? birthday;
  final Profession? profession;
  final Education? education;
  final SocialMedia? socialMedia;
  final String whereYouHeardUs;
  final String coverLetter;
  final int? sectoralExperience;
  final String? picture;
  final String? reference;
  final String? areasOfExpertise;
  final bool marketingCommunicationPermission;
  final int? rating;
  final String? logo;
  final CustomerDetailInfo? detail;

  CustomerDetail({
    required this.id,
    this.birthday,
    this.profession,
    this.education,
    this.socialMedia,
    required this.whereYouHeardUs,
    required this.coverLetter,
    this.sectoralExperience,
    this.picture,
    this.reference,
    this.areasOfExpertise,
    required this.marketingCommunicationPermission,
    this.rating,
    this.logo,
    this.detail,
  });

  factory CustomerDetail.empty() {
    return CustomerDetail(
      id: '',
      whereYouHeardUs: '',
      coverLetter: '',
      marketingCommunicationPermission: false,
    );
  }

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final profession = asMap(json['profession']);
    final education = asMap(json['education']);
    final socialMedia = asMap(json['social_media']);
    final nestedDetail = asMap(json['detail']);

    return CustomerDetail(
      id: _asString(json['id']),
      birthday: _asNullableString(json['birthday']),
      profession: profession == null ? null : Profession.fromJson(profession),
      education: education == null ? null : Education.fromJson(education),
      socialMedia: socialMedia == null ? null : SocialMedia.fromJson(socialMedia),
      whereYouHeardUs: _asString(json['where_you_heard_us']),
      coverLetter: _asString(json['cover_letter']),
      sectoralExperience: json['sectoral_experience'] == null
          ? null
          : _asInt(json['sectoral_experience']),
      picture: _asNullableString(json['picture']),
      reference: _asNullableString(json['reference']),
      areasOfExpertise: _asNullableString(json['areas_of_expertise']),
      marketingCommunicationPermission:
          json['marketing_communication_permission'] == true,
      rating: json['rating'] == null ? null : _asInt(json['rating']),
      logo: _asNullableString(json['logo']),
      detail: nestedDetail == null
          ? null
          : CustomerDetailInfo.fromJson(nestedDetail),
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
      'detail': detail?.toJson(),
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
      id: _asNullableString(json['id']),
      code: _asNullableString(json['code']),
      description: _asNullableString(json['description']),
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
      id: _asNullableString(json['id']),
      code: _asNullableString(json['code']),
      description: _asNullableString(json['description']),
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

class SocialMedia {
  final String? instagram;
  final String? facebook;
  final String? x;
  final String? linkedin;

  SocialMedia({
    this.instagram,
    this.facebook,
    this.x,
    this.linkedin,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      instagram: _asNullableString(json['instagram']),
      facebook: _asNullableString(json['facebook']),
      x: _asNullableString(json['x']),
      linkedin: _asNullableString(json['linkedin']),
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

class CustomerDetailInfo {
  final List<String>? tags;
  final int childrenAmount;
  final String? monthlySalary;
  final String? maritalStatus;

  CustomerDetailInfo({
    this.tags,
    required this.childrenAmount,
    this.monthlySalary,
    this.maritalStatus,
  });

  factory CustomerDetailInfo.fromJson(Map<String, dynamic> json) {
    List<String>? tags;
    final rawTags = json['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }
    return CustomerDetailInfo(
      tags: tags,
      childrenAmount: _asInt(json['children_amount']),
      monthlySalary: _asNullableString(json['monthly_salary']),
      maritalStatus: _asNullableString(json['marital_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tags': tags,
      'children_amount': childrenAmount,
      'monthly_salary': monthlySalary,
      'marital_status': maritalStatus,
    };
  }
}

class CustomerApiResponse {
  final List<CustomerApiModel> customers;
  final int totalCount;
  final int totalPages;
  final int page;

  CustomerApiResponse({
    required this.customers,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory CustomerApiResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['customers'] ?? json['data'] ?? const [];
    final customers = <CustomerApiModel>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        try {
          customers.add(
            CustomerApiModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {}
      }
    }
    return CustomerApiResponse(
      customers: customers,
      totalCount: _asInt(json['totalCount'] ?? json['total']),
      totalPages: _asInt(json['totalPages'] ?? json['total_pages']),
      page: _asInt(json['page'], fallback: 1),
    );
  }
}

int _asTypeCode(dynamic value) {
  if (value is Map) {
    return _asInt(value['code'] ?? value['id'] ?? value['type']);
  }
  return _asInt(value);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text == 'null' ? fallback : text;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty || text == 'null' ? null : text;
}

/// Meslek / eğitim referansı. Serbest metin uuid kolonuna gidince sunucu 500 döner.
bool _isServerRef(String? value) {
  if (value == null || value.isEmpty) return false;
  if (RegExp(r'^\d+$').hasMatch(value)) return true;
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
