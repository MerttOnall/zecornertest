class ContactType {
  final int id;
  final String name;
  final bool? isCompany;
  final bool? isEmployee;
  final bool? isAgency;
  final bool? isCustomer;
  final bool? isAdmin;
  final bool? isAgencyEmployee;

  ContactType({
    required this.id,
    required this.name,
    this.isCompany,
    this.isEmployee,
    this.isAgency,
    this.isCustomer,
    this.isAdmin,
    this.isAgencyEmployee,
  });

  factory ContactType.fromJson(Map<String, dynamic> json) {
    return ContactType(
      id: json['code'] as int, // API'de 'code' field'ı ID olarak kullanılıyor
      name: json['description'] as String, // API'de 'description' field'ı name olarak kullanılıyor
      isCompany: json['is_company'] as bool?,
      isEmployee: json['is_employee'] as bool?,
      isAgency: json['is_agency'] as bool?,
      isCustomer: json['is_customer'] as bool?,
      isAdmin: json['is_admin'] as bool?,
      isAgencyEmployee: json['is_agency_employee'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': id,
      'description': name,
      if (isCompany != null) 'is_company': isCompany,
      if (isEmployee != null) 'is_employee': isEmployee,
      if (isAgency != null) 'is_agency': isAgency,
      if (isCustomer != null) 'is_customer': isCustomer,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isAgencyEmployee != null) 'is_agency_employee': isAgencyEmployee,
    };
  }
}

