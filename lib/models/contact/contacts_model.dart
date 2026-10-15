class ContactsResponseModel {
  final List<ContactModel> contacts;
  final int totalCount;
  final int totalPages;
  final int page;

  ContactsResponseModel({
    required this.contacts,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ContactsResponseModel.fromJson(Map<String, dynamic> json) {
    return ContactsResponseModel(
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      page: json['page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contacts': contacts.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

class ContactModel {
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
  final String email;
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

  ContactModel({
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
    required this.email,
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
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      contactNo: json['contact_no'] ?? 0,
      title: json['title'] ?? '',
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      type: json['type'] ?? 0,
      tcIdNumber: json['tc_id_number'],
      taxNo: json['tax_no'],
      taxOffice: json['tax_office'],
      nationality: json['nationality'] ?? '',
      sex: json['sex'],
      email: json['e_mail'] ?? '',
      tel: json['tel'] ?? '',
      status: json['status'] ?? 0,
      updatedAt: json['updated_at'],
      createdAt: json['created_at'] ?? '',
      source: json['source'],
      typeDescription: json['type_description'] ?? '',
      isCompany: json['is_company'] ?? false,
      isEmployee: json['is_employee'] ?? false,
      isAgency: json['is_agency'] ?? false,
      birthday: json['birthday'],
      professionCode: json['profession_code'],
      professionDescription: json['profession_description'],
      educationCode: json['education_code'],
      educationDescription: json['education_description'],
      whereYouHeardUs: json['where_you_heard_us'],
      sectoralExperience: json['sectoral_experience'],
      picture: json['picture'],
      marketingCommunicationPermission: json['marketing_communication_permission'] ?? false,
      address: json['address'],
      district: json['district'],
      postCode: json['post_code'],
      city: json['city'],
      country: json['country'],
      addressSource: json['address_source'],
      provinceCode: json['province_code'],
      provinceName: json['province_name'],
      districtCode: json['district_code'],
      districtName: json['district_name'],
      quarterCode: json['quarter_code'],
      quarterName: json['quarter_name'],
      connectedContact: json['connected_contact'],
      connectedContactTitle: json['connected_contact_title'],
      connectedContactType: json['connected_contact_type'],
      connectedContactDescription: json['connected_contact_description'],
      isCustomer: json['is_customer'] ?? false,
      slug: json['slug'] ?? '',
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
      'e_mail': email,
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
}

// Helper Extension for Easy Access
extension ContactModelHelpers on ContactModel {
  /// Tam adı döndürür
  String get fullName => '$name $surname'.trim();

  /// Durum bilgisini Türkçe döndürür
  String get statusDisplayName {
    switch (status) {
      case 0:
        return 'Pasif';
      case 1:
        return 'Aktif';
      case 2:
        return 'Beklemede';
      default:
        return 'Bilinmiyor';
    }
  }

  /// Ülke kodu Türkçe ülke adına çevir
  String get countryDisplayName {
    switch (nationality) {
      case 'TR':
        return 'Türkiye';
      case 'AF':
        return 'Afganistan';
      case 'US':
        return 'Amerika Birleşik Devletleri';
      case 'DE':
        return 'Almanya';
      case 'FR':
        return 'Fransa';
      case 'GB':
        return 'İngiltere';
      default:
        return nationality;
    }
  }

  /// Cinsiyet Türkçe
  String? get sexDisplayName {
    switch (sex) {
      case 'M':
        return 'Erkek';
      case 'F':
        return 'Kadın';
      default:
        return sex;
    }
  }

  /// Kişi türü belirleme
  String get personType {
    if (isCompany) return 'Şirket';
    if (isEmployee && isAgency) return 'Broker';
    if (isEmployee) return 'Çalışan';
    if (isAgency) return 'Acente';
    if (isCustomer) return 'Müşteri';
    return 'Kişi';
  }

  /// Kişi türü ikonu
  String get personTypeIcon {
    if (isCompany) return '🏢';
    if (isEmployee && isAgency) return '🏪';
    if (isEmployee) return '👔';
    if (isAgency) return '🏬';
    if (isCustomer) return '👤';
    return '👤';
  }

  /// Tam adres bilgisi
  String get fullAddress {
    List<String> addressParts = [];
    
    if (address != null && address!.isNotEmpty) {
      addressParts.add(address!);
    }
    
    if (quarterName != null) addressParts.add(quarterName!);
    if (districtName != null) addressParts.add(districtName!);
    if (provinceName != null) addressParts.add(provinceName!);
    if (country != null) addressParts.add(countryDisplayName);
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Adres bilgisi yok';
  }

  /// Meslek bilgisi var mı kontrol et
  bool get hasProfessionInfo => professionCode != null && professionDescription != null;

  /// Eğitim bilgisi var mı kontrol et
  bool get hasEducationInfo => educationCode != null && educationDescription != null;

  /// Profil fotoğrafı var mı
  bool get hasProfilePicture => picture != null && picture!.isNotEmpty;

  /// Telefon numarası geçerli mi
  bool get hasValidPhone => tel != '0' && tel.isNotEmpty;

  /// Email geçerli mi (basit kontrol)
  bool get hasValidEmail => email.isNotEmpty && email.contains('@');

  /// Doğum tarihi var mı
  bool get hasBirthday => birthday != null && birthday!.isNotEmpty;

  /// Yaş hesapla (doğum tarihi varsa)
  int? get age {
    if (!hasBirthday) return null;
    
    try {
      final birthDate = DateTime.parse(birthday!);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Bağlı iletişim var mı
  bool get hasConnectedContact => connectedContact != null && connectedContactTitle != null;

  /// Marketing izni var mı
  bool get canReceiveMarketing => marketingCommunicationPermission;

  /// Aktif mi
  bool get isActive => status == 1;

  /// Son güncelleme tarihi var mı
  bool get hasLastUpdate => updatedAt != null && updatedAt!.isNotEmpty;

  /// Oluşturulma tarihi (formatlanmış)
  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  /// Son güncelleme tarihi (formatlanmış)
  String? get formattedUpdatedAt {
    if (!hasLastUpdate) return null;
    
    try {
      final date = DateTime.parse(updatedAt!);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return updatedAt;
    }
  }

  /// Meslek türü ikonu
  String get professionIcon {
    switch (professionCode) {
      case 'ACADEMIC':
        return '🎓';
      case 'REAL_ESTATE_CONSULTANT':
        return '🏠';
      case 'SOLDIER':
        return '⚔️';
      default:
        return '💼';
    }
  }

  /// Eğitim seviyesi ikonu
  String get educationIcon {
    switch (educationCode) {
      case 'PRIMARY_SCHOOL':
        return '📚';
      case 'UNIVERSITY':
        return '🎓';
      case 'POST_GRADUATE':
        return '👨‍🎓';
      default:
        return '📖';
    }
  }

  /// Contact özet bilgisi (liste görünümü için)
  String get summary {
    List<String> parts = [fullName];
    if (typeDescription.isNotEmpty) parts.add(typeDescription);
    if (hasProfessionInfo) parts.add(professionDescription!);
    return parts.join(' • ');
  }

  /// İletişim bilgileri tamamlığı (0-100 arası puan)
  int get completenessScore {
    int score = 0;
    int maxScore = 12;
    
    if (name.isNotEmpty) score++;
    if (surname.isNotEmpty) score++;
    if (hasValidEmail) score++;
    if (hasValidPhone) score++;
    if (address != null && address!.isNotEmpty) score++;
    if (hasBirthday) score++;
    if (hasProfessionInfo) score++;
    if (hasEducationInfo) score++;
    if (hasProfilePicture) score++;
    if (tcIdNumber != null && tcIdNumber!.isNotEmpty) score++;
    if (city != null && city!.isNotEmpty) score++;
    if (hasConnectedContact) score++;
    
    return ((score / maxScore) * 100).round();
  }
}

extension ContactsResponseModelHelpers on ContactsResponseModel {
  /// Aktif kontaklar
  List<ContactModel> get activeContacts => contacts.where((contact) => contact.isActive).toList();

  /// Pasif kontaklar
  List<ContactModel> get inactiveContacts => contacts.where((contact) => !contact.isActive).toList();

  /// Çalışanlar
  List<ContactModel> get employees => contacts.where((contact) => contact.isEmployee).toList();

  /// Müşteriler
  List<ContactModel> get customers => contacts.where((contact) => contact.isCustomer).toList();

  /// Acenteler
  List<ContactModel> get agencies => contacts.where((contact) => contact.isAgency).toList();

  /// Brokerlar
  List<ContactModel> get brokers => contacts.where((contact) => contact.isEmployee && contact.isAgency).toList();

  /// Şirketler
  List<ContactModel> get companies => contacts.where((contact) => contact.isCompany).toList();

  /// Profil fotoğrafı olan kontaklar
  List<ContactModel> get contactsWithPhoto => contacts.where((contact) => contact.hasProfilePicture).toList();

  /// Marketing izni veren kontaklar
  List<ContactModel> get marketingPermittedContacts => contacts.where((contact) => contact.canReceiveMarketing).toList();

  /// Türe göre gruplama
  Map<String, List<ContactModel>> get groupedByType {
    Map<String, List<ContactModel>> grouped = {};
    for (final contact in contacts) {
      final type = contact.typeDescription;
      grouped[type] = (grouped[type] ?? [])..add(contact);
    }
    return grouped;
  }

  /// Şehre göre gruplama
  Map<String, List<ContactModel>> get groupedByCity {
    Map<String, List<ContactModel>> grouped = {};
    for (final contact in contacts) {
      final city = contact.city ?? contact.provinceName ?? 'Bilinmiyor';
      grouped[city] = (grouped[city] ?? [])..add(contact);
    }
    return grouped;
  }

  /// İstatistikler
  Map<String, int> get statistics {
    return {
      'toplam': contacts.length,
      'aktif': activeContacts.length,
      'pasif': inactiveContacts.length,
      'calisan': employees.length,
      'musteri': customers.length,
      'acente': agencies.length,
      'broker': brokers.length,
      'sirket': companies.length,
      'fotografi_olan': contactsWithPhoto.length,
      'marketing_izinli': marketingPermittedContacts.length,
    };
  }

  /// Arama fonksiyonu
  List<ContactModel> searchContacts(String query) {
    if (query.isEmpty) return contacts;
    
    final lowerQuery = query.toLowerCase();
    return contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(lowerQuery) ||
             contact.email.toLowerCase().contains(lowerQuery) ||
             contact.typeDescription.toLowerCase().contains(lowerQuery) ||
             (contact.professionDescription?.toLowerCase().contains(lowerQuery) ?? false) ||
             (contact.connectedContactTitle?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
