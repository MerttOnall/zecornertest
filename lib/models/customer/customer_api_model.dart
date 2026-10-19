import 'dart:convert';

import 'package:zecorner/models/contact/ref_profession_model.dart';

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
  final List<CustomerAsset> listings;
  final List<CustomerAsset> realEstates;

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
    this.listings = const [],
    this.realEstates = const [],
  });

  factory CustomerApiModel.fromJson(Map<String, dynamic> json) {
    final typeMap = _asMap(json['type']);
    final typeDescription = _firstText([
      json['type_description'],
      json['typeDescription'],
      typeMap?['description'],
      typeMap?['name'],
    ]);
    var name = _firstText([json['name'], json['first_name'], json['firstName']]);
    var surname = _firstText([json['surname'], json['last_name'], json['lastName']]);
    final title = _firstText([json['title'], json['full_name'], json['fullName']]);
    if (name.isEmpty && surname.isEmpty && title.isNotEmpty) {
      final parts = title.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        name = parts.first;
        if (parts.length > 1) surname = parts.sublist(1).join(' ');
      }
    }
    final detailMap = _asMap(json['detail']);
    return CustomerApiModel(
      contactNo: _asInt(json['contact_no'] ?? json['contactNo'] ?? json['id']),
      title: title.isNotEmpty ? title : '$name $surname'.trim(),
      name: name,
      surname: surname,
      type: _asTypeCode(json['type']),
      typeDescription: typeDescription,
      tcIdNumber: _asNullableString(
        json['tc_id_number'] ?? json['tcIdNumber'] ?? json['tc_no'] ?? json['identity_number'],
      ),
      taxNo: _firstText([json['tax_no'], json['taxNo']]),
      taxOffice: _firstText([json['tax_office'], json['taxOffice']]),
      nationality: _countryCode(json['nationality']),
      sex: _asSex(json['sex'] ?? json['gender']),
      eMail: _firstText([json['e_mail'], json['email'], json['eMail'], json['mail']]),
      tel: _firstText([json['tel'], json['phone'], json['gsm'], json['mobile']]),
      status: _asInt(json['status'], fallback: 1),
      updatedAt: _asNullableString(json['updated_at'] ?? json['updatedAt']),
      source: _asNullableString(json['source']),
      detail: CustomerDetail.fromJson(_withRootDetail(json, detailMap)),
      connectedContact: json['connected_contact'] == null && json['connectedContact'] == null
          ? null
          : _asInt(json['connected_contact'] ?? json['connectedContact']),
      createdAt: _firstText([json['created_at'], json['createdAt']]),
      listings: _asAssets(json['listings'] ?? json['listing']),
      realEstates: _asAssets(json['real_estates'] ?? json['realEstates']),
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
      'listings': listings.map((e) => e.id).where((id) => id.isNotEmpty).toList(),
      'real_estates': realEstates.map((e) => e.id).where((id) => id.isNotEmpty).toList(),
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

  /// Web müşteri tipleri: 201 Alıcı, 202 Satıcı, 203 Potansiyel,
  /// 204 Potansiyel Alıcı, 205 Potansiyel Satıcı, 206 Alıcı & Satıcı.
  static int? typeCodeForLabel(String? label) {
    switch (label?.trim()) {
      case 'Alıcı':
        return 201;
      case 'Satıcı':
        return 202;
      case 'Potansiyel':
        return 203;
      case 'Potansiyel Alıcı':
        return 204;
      case 'Potansiyel Satıcı':
        return 205;
      case 'Alıcı & Satıcı':
        return 206;
      default:
        return null;
    }
  }

  static String? labelForType(int type) {
    switch (type) {
      case 201:
        return 'Alıcı';
      case 202:
        return 'Satıcı';
      case 203:
        return 'Potansiyel';
      case 204:
        return 'Potansiyel Alıcı';
      case 205:
        return 'Potansiyel Satıcı';
      case 206:
        return 'Alıcı & Satıcı';
      default:
        return null;
    }
  }

  // Helper getters
  bool get isActive => status == 1;
  String get fullName => '$name $surname';
  String get displayPhone => tel.isEmpty ? 'N/A' : tel;
  String get displayEmail => eMail.isEmpty ? 'N/A' : eMail;
  String get displayTaxNo => taxNo.isEmpty ? 'N/A' : taxNo;
  String get displayTaxOffice => taxOffice.isEmpty ? 'N/A' : taxOffice;
  String get displayProfession {
    final desc = detail.profession?.description?.trim();
    if (_isReadableLabel(desc)) return desc!;
    final resolved = ProfessionCatalog.labelFor(detail.profession?.id) ??
        ProfessionCatalog.labelFor(detail.profession?.code);
    if (_isReadableLabel(resolved)) return resolved!;
    final area = detail.areasOfExpertise?.trim();
    if (_isReadableLabel(area)) return area!;
    return 'N/A';
  }
  String get displayEducation => detail.education?.description ?? 'N/A';
  String get displayGender => sex == 'M' ? 'Erkek' : sex == 'F' ? 'Kadın' : 'N/A';
  String get displayMaritalStatus {
    if (detail.detail?.maritalStatus == '1') return 'Bekar';
    if (detail.detail?.maritalStatus == '2') return 'Evli';
    return 'N/A';
  }
  int get childrenCount => detail.detail?.childrenAmount ?? 0;
  String get monthlySalary {
    final value = _cleanMonthlySalary(detail.detail?.monthlySalary);
    return value.isEmpty ? 'N/A' : value;
  }
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

    final profession = Profession.parse(
      json['profession'],
      fallbackDescription: _asNullableString(
        json['profession_description'] ?? json['profession_name'],
      ),
    );
    final educationRaw = json['education'] ?? json['education_description'];
    final education = educationRaw is Map
        ? Education.fromJson(Map<String, dynamic>.from(educationRaw))
        : (educationRaw is String && educationRaw.trim().isNotEmpty
            ? Education(
                id: educationRaw.trim(),
                code: educationRaw.trim(),
                description: _looksLikeLabel(educationRaw) ? educationRaw.trim() : null,
              )
            : null);
    final socialMedia = asMap(json['social_media'] ?? json['socialMedia']) ??
        _decodeObject(json['social_media'] ?? json['socialMedia']);
    final nestedDetail = asMap(json['detail']);

    return CustomerDetail(
      id: _asString(json['id']),
      birthday: _asNullableString(json['birthday'] ?? json['birth_date'] ?? json['birthDate']),
      profession: profession,
      education: education,
      socialMedia: socialMedia == null ? null : SocialMedia.fromJson(socialMedia),
      whereYouHeardUs: _firstText([
        json['where_you_heard_us'],
        json['whereYouHeardUs'],
      ]),
      coverLetter: _firstText([
        json['cover_letter'],
        json['coverLetter'],
        json['notes'],
        json['note'],
      ]),
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
      id: _asNullableString(json['id'] ?? json['code']),
      code: _asNullableString(json['code'] ?? json['id']),
      description: _asNullableString(
        json['description'] ?? json['name'] ?? json['title'] ?? json['label'],
      ),
    );
  }

  static Profession? parse(dynamic raw, {String? fallbackDescription}) {
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty || text == 'null') {
        return _isReadableLabel(fallbackDescription)
            ? Profession(description: fallbackDescription)
            : null;
      }
      return Profession(
        id: text,
        code: text,
        description: _isReadableLabel(fallbackDescription) ? fallbackDescription : null,
      );
    }
    if (raw is Map) {
      return Profession.fromJson(Map<String, dynamic>.from(raw));
    }
    if (_isReadableLabel(fallbackDescription)) {
      return Profession(description: fallbackDescription);
    }
    return null;
  }

  String? get serverRef {
    if (_isServerRef(id)) return id;
    if (_isServerRef(code)) return code;
    return null;
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

  String? get serverRef {
    if (_isServerRef(id)) return id;
    if (_isServerRef(code)) return code;
    return null;
  }

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: _asNullableString(json['id'] ?? json['code']),
      code: _asNullableString(json['code'] ?? json['id']),
      description: _asNullableString(
        json['description'] ?? json['name'] ?? json['title'],
      ),
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
      tags = rawTags.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      tags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return CustomerDetailInfo(
      tags: tags,
      childrenAmount: _asInt(
        json['children_amount'] ?? json['children_count'],
      ),
      monthlySalary: _cleanMonthlySalary(
        json['monthly_salary'] ?? json['income'] ?? json['monthlySalary'],
      ),
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic>? _decodeObject(dynamic value) {
  if (value is! String || !value.trim().startsWith('{')) return null;
  try {
    return _asMap(jsonDecode(value));
  } catch (_) {
    return null;
  }
}

bool _present(dynamic value) {
  if (value == null) return false;
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text.isNotEmpty && text != 'null' && text != 'n/a';
  }
  if (value is List) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

String _firstText(List<dynamic> values) {
  for (final value in values) {
    if (value is Map) {
      final nested = _firstText([
        value['description'],
        value['name'],
        value['title'],
        value['label'],
        value['code'],
      ]);
      if (nested.isNotEmpty) return nested;
      continue;
    }
    final text = _asString(value);
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

String _countryCode(dynamic value) {
  if (value is Map) {
    return _asString(value['code'] ?? value['id'] ?? value['name'], fallback: 'TR');
  }
  return _asString(value, fallback: 'TR');
}

String? _asSex(dynamic value) {
  final text = value?.toString().trim().toLowerCase() ?? '';
  if (text.isEmpty || text == 'null') return null;
  if (text == 'm' || text == 'male' || text == 'erkek' || text == '1' || text == '0') {
    if (text == '0') return null;
    return 'M';
  }
  if (text == 'f' || text == 'female' || text == 'kadın' || text == 'kadin' || text == '2') {
    return 'F';
  }
  return null;
}

bool _looksLikeLabel(String value) {
  final text = value.trim();
  if (text.isEmpty) return false;
  if (RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(text)) return false;
  return RegExp(r'[A-Za-zĞÜŞİÖÇğüşıöç]').hasMatch(text);
}

Map<String, dynamic> _withRootDetail(Map<String, dynamic> root, Map<String, dynamic>? detail) {
  final merged = Map<String, dynamic>.from(detail ?? {});
  void fill(String key, List<dynamic> candidates) {
    if (_present(merged[key])) return;
    for (final candidate in candidates) {
      if (_present(candidate)) {
        merged[key] = candidate;
        return;
      }
    }
  }

  fill('birthday', [root['birthday'], root['birth_date']]);
  fill('profession', [root['profession'], root['profession_description']]);
  fill('education', [root['education'], root['education_description']]);
  fill('social_media', [root['social_media'], root['socialMedia']]);
  fill('where_you_heard_us', [root['where_you_heard_us'], root['whereYouHeardUs']]);
  fill('cover_letter', [root['cover_letter'], root['coverLetter'], root['notes']]);
  fill('picture', [root['picture'], root['photo']]);
  fill('areas_of_expertise', [root['areas_of_expertise'], root['areasOfExpertise']]);

  final inner = Map<String, dynamic>.from(_asMap(merged['detail']) ?? {});
  void fillInner(String key, List<dynamic> candidates) {
    if (_present(inner[key])) return;
    for (final candidate in candidates) {
      if (_present(candidate)) {
        inner[key] = candidate;
        return;
      }
    }
  }

  fillInner('monthly_salary', [root['monthly_salary'], root['income'], inner['income']]);
  fillInner('marital_status', [root['marital_status'], root['maritalStatus']]);
  fillInner('children_amount', [root['children_amount'], root['children_count'], inner['children_count']]);
  fillInner('tags', [root['tags']]);
  if (inner.isNotEmpty) merged['detail'] = inner;
  return merged;
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

bool _isReadableLabel(String? value) {
  if (value == null) return false;
  final text = value.trim().toLowerCase();
  return text.isNotEmpty && text != 'n/a' && text != 'null' && text != '-';
}

/// Aylık geliri düz rakama çevirir. N/A, ondalık çöplüğü ve taşan değerler boş döner.
String _cleanMonthlySalary(dynamic value) {
  if (value == null) return '';
  if (value is Map) {
    value = value['amount'] ?? value['value'] ?? value['monthly_salary'] ?? value['income'];
  }
  var text = value.toString().trim();
  if (!_isReadableLabel(text)) return '';
  if (text.contains(',') && text.contains('.')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else if (text.contains(',') && !text.contains('.')) {
    text = text.replaceAll(',', '.');
  }
  final asNum = num.tryParse(text);
  if (asNum != null) {
    final whole = asNum.round();
    if (whole < 0 || whole > 999999999) return '';
    return whole.toString();
  }
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty || digits.length > 9) return '';
  return digits;
}

List<CustomerAsset> _asAssets(dynamic raw) {
  if (raw is! List) return const [];
  final items = <CustomerAsset>[];
  for (final entry in raw) {
    if (entry is String && entry.trim().isNotEmpty) {
      items.add(CustomerAsset(id: entry.trim(), title: ''));
      continue;
    }
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    final id = _asString(
      map['id'] ?? map['listing_id'] ?? map['real_estate_id'] ?? map['uuid'],
    );
    if (id.isEmpty) continue;
    final listingNo = map['listing_no']?.toString();
    final title = _asString(map['title']);
    items.add(
      CustomerAsset(
        id: id,
        title: title.isNotEmpty
            ? title
            : (listingNo != null && listingNo.isNotEmpty ? 'İlan #$listingNo' : 'Kayıt'),
        image: _asNullableString(
          map['thumbnail'] ?? map['cover_picure'] ?? map['cover_picture'] ?? map['picture'],
        ),
      ),
    );
  }
  return items;
}

class CustomerAsset {
  final String id;
  final String title;
  final String? image;

  const CustomerAsset({
    required this.id,
    required this.title,
    this.image,
  });

  static List<CustomerAsset> listFrom(dynamic raw) => _asAssets(raw);
}

/// Meslek / eğitim referansı. Serbest metin uuid kolonuna gidince sunucu 500 döner.
bool _isServerRef(String? value) {
  if (value == null || value.isEmpty) return false;
  if (RegExp(r'^\d+$').hasMatch(value)) return true;
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
