import 'package:zecorner/models/contact/contact_api_model.dart';

class ContactsApiModel {
  final int contactNo;
  final String title;
  final String name;
  final String surname;
  final int type;
  final String? tcIdNumber;
  final String? taxNo;
  final String? taxOffice;
  final String nationality;
  final String? sex;
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
  final String? sectoralExperience;
  final String? picture;
  final bool marketingCommunicationPermission;
  final String? address;
  final String? district;
  final String? postCode;
  final String? city;
  final String? country;
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
  final List<Map<String, dynamic>>? detailAttachments;

  ContactsApiModel({
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
    this.detailAttachments,
  });

  static int _asTypeCode(dynamic v) {
    if (v is Map) {
      return _asInt(v['code'] ?? v['id'] ?? v['type']);
    }
    return _asInt(v);
  }

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _asString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  factory ContactsApiModel.fromJson(Map<String, dynamic> json) {
    return ContactsApiModel(
      contactNo: _asInt(
        json['contact_no'] ?? json['contactNo'] ?? json['no'],
      ),
      title: _asString(json['title']),
      name: _asString(json['name']),
      surname: _asString(json['surname']),
      type: _asTypeCode(json['type']),
      tcIdNumber: json['tc_id_number']?.toString(),
      taxNo: json['tax_no']?.toString(),
      taxOffice: json['tax_office']?.toString(),
      nationality: _asString(json['nationality'], 'TR'),
      sex: json['sex']?.toString(),
      eMail: _asString(json['e_mail']),
      tel: _asString(json['tel'], '0'),
      status: _asInt(json['status']),
      updatedAt: json['updated_at']?.toString(),
      createdAt: _asString(json['created_at']),
      source: json['source']?.toString(),
      typeDescription: _asString(json['type_description']),
      isCompany: json['is_company'] == true,
      isEmployee: json['is_employee'] == true,
      isAgency: json['is_agency'] == true,
      birthday: ContactApiModel.birthdayFrom(json) ?? json['birthday']?.toString(),
      professionCode: json['profession_code']?.toString(),
      professionDescription: json['profession_description']?.toString(),
      educationCode: json['education_code']?.toString(),
      educationDescription: json['education_description']?.toString(),
      whereYouHeardUs: json['where_you_heard_us']?.toString(),
      sectoralExperience: json['sectoral_experience']?.toString(),
      picture: json['picture']?.toString(),
      marketingCommunicationPermission:
          json['marketing_communication_permission'] == true,
      address: json['address']?.toString(),
      district: json['district']?.toString(),
      postCode: json['post_code']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      addressSource: json['address_source']?.toString(),
      provinceCode: _asIntOrNull(json['province_code']),
      provinceName: json['province_name']?.toString(),
      districtCode: _asIntOrNull(json['district_code']),
      districtName: json['district_name']?.toString(),
      quarterCode: _asIntOrNull(json['quarter_code']),
      quarterName: json['quarter_name']?.toString(),
      connectedContact: _asIntOrNull(json['connected_contact']),
      connectedContactTitle: json['connected_contact_title']?.toString(),
      connectedContactType: _asIntOrNull(json['connected_contact_type']),
      connectedContactDescription:
          json['connected_contact_description']?.toString(),
      isCustomer: json['is_customer'] == true,
      slug: _asString(json['slug']),
      detailAttachments: ContactApiModel.attachmentsFrom(json),
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
    };
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

class ContactsApiResponse {
  final List<ContactsApiModel> contacts;
  final int totalCount;
  final int totalPages;
  final int page;

  ContactsApiResponse({
    required this.contacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ContactsApiResponse.fromJson(Map<String, dynamic> json) {
    return ContactsApiResponse(
      contacts: (json['contacts'] as List<dynamic>)
          .map((contactJson) => ContactsApiModel.fromJson(contactJson))
          .toList(),
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }
}
