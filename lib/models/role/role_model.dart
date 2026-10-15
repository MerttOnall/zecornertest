import 'dart:convert';

class RoleModel {
  final int? id;
  final String? name;
  final String? code;
  final ContactType? contactType;
  final int? contactTypeCode; // JSON'dan gelen int değer için
  final bool? isAdmin;
  final List<String>? permissions;

  RoleModel({
    this.id,
    this.name,
    this.code,
    this.contactType,
    this.contactTypeCode,
    this.isAdmin,
    this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    // contact_type hem int hem de object olabilir
    ContactType? contactTypeObj;
    int? contactTypeInt;
    
    if (json['contact_type'] != null) {
      if (json['contact_type'] is Map) {
        contactTypeObj = ContactType.fromJson(json['contact_type']);
        contactTypeInt = contactTypeObj.code;
      } else if (json['contact_type'] is int) {
        contactTypeInt = json['contact_type'] as int;
      }
    }
    
    return RoleModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      contactType: contactTypeObj,
      contactTypeCode: contactTypeInt,
      isAdmin: json['is_admin'] ?? false,
      permissions: json['permissions'] != null 
          ? List<String>.from(json['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'contact_type': contactTypeCode ?? contactType?.toJson(),
      'is_admin': isAdmin ?? false,
      'permissions': permissions,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory RoleModel.fromJsonString(String jsonString) {
    return RoleModel.fromJson(jsonDecode(jsonString));
  }

  // Rol adını döndüren yardımcı method
  String get displayName {
    return name ?? 'İsimsiz Rol';
  }

  // Rol kodunu döndüren yardımcı method
  String get displayCode {
    return code ?? 'KOD_YOK';
  }

  // Contact tipine göre kısa açıklama
  String get contactTypeDescription {
    if (contactType != null) {
      if (contactType!.isCompany == true) return 'Şirket';
      if (contactType!.isEmployee == true) return 'Çalışan';
      if (contactType!.isAgency == true) return 'Ajans';
      if (contactType!.isCustomer == true) return 'Müşteri';
      if (contactType!.isAdmin == true) return 'Admin';
      if (contactType!.isAgencyEmployee == true) return 'Ajans Çalışanı';
      return contactType!.description ?? 'Diğer';
    }
    
    if (contactTypeCode != null) {
      return 'Tip Kodu: $contactTypeCode';
    }
    
    return 'Tip Belirtilmemiş';
  }

  // Rol ve contact tipini birleştiren method
  String get fullDescription {
    return '$displayName ($contactTypeDescription)';
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

  // Contact tipinin aktif olup olmadığını kontrol eden method
  bool get isActive {
    return isCompany == true || 
           isEmployee == true || 
           isAgency == true || 
           isCustomer == true || 
           isAdmin == true || 
           isAgencyEmployee == true;
  }

  // Aktif tipleri liste olarak döndüren method
  List<String> get activeTypes {
    List<String> types = [];
    
    if (isCompany == true) types.add('Şirket');
    if (isEmployee == true) types.add('Çalışan');
    if (isAgency == true) types.add('Ajans');
    if (isCustomer == true) types.add('Müşteri');
    if (isAdmin == true) types.add('Admin');
    if (isAgencyEmployee == true) types.add('Ajans Çalışanı');
    
    return types;
  }

  // Aktif tipleri string olarak döndüren method
  String get activeTypesString {
    return activeTypes.join(', ');
  }
}

