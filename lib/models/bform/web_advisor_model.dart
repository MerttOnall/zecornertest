class WebAdvisorLookupItem {
  final String code;
  final String description;

  const WebAdvisorLookupItem({required this.code, required this.description});

  factory WebAdvisorLookupItem.fromJson(Map<String, dynamic> json) {
    return WebAdvisorLookupItem(
      code: _str(json['code']) ?? '',
      description: _str(json['description']) ?? _str(json['code']) ?? '',
    );
  }
}

class WebAdvisorLookups {
  final List<WebAdvisorLookupItem> statusTypes;
  final List<WebAdvisorLookupItem> contactTypes;

  const WebAdvisorLookups({
    required this.statusTypes,
    required this.contactTypes,
  });

  factory WebAdvisorLookups.fromJson(Map<String, dynamic> json) {
    return WebAdvisorLookups(
      statusTypes: _items(json['status_types']),
      contactTypes: _items(json['contact_types']),
    );
  }

  static List<WebAdvisorLookupItem> _items(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => WebAdvisorLookupItem.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.code.isNotEmpty)
        .toList();
  }
}

class WebAdvisorStatus {
  final int id;
  final String statusType;
  final String? statusTypeDescription;
  final String? contactType;
  final String? contactTypeDescription;
  final String? description;
  final DateTime? date;
  final DateTime? createdAt;
  final String? createdByTitle;

  const WebAdvisorStatus({
    required this.id,
    required this.statusType,
    this.statusTypeDescription,
    this.contactType,
    this.contactTypeDescription,
    this.description,
    this.date,
    this.createdAt,
    this.createdByTitle,
  });

  factory WebAdvisorStatus.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'];
    String? title;
    if (createdBy is Map) {
      title = _str(createdBy['title']);
    }
    return WebAdvisorStatus(
      id: _int(json['id']) ?? 0,
      statusType: _str(json['status_type']) ?? '',
      statusTypeDescription: _str(json['status_type_description']),
      contactType: _str(json['contact_type']),
      contactTypeDescription: _str(json['contact_type_description']),
      description: _str(json['description']),
      date: _date(json['date']),
      createdAt: _date(json['created_at']),
      createdByTitle: title,
    );
  }

  String get statusLabel {
    final text = statusTypeDescription?.trim();
    if (text != null && text.isNotEmpty) return text;
    return statusType.isEmpty ? '-' : statusType;
  }

  String get contactLabel {
    final text = contactTypeDescription?.trim();
    if (text != null && text.isNotEmpty) return text;
    return (contactType ?? '').isEmpty ? '-' : contactType!;
  }
}

class WebAdvisorApplication {
  final int id;
  final String name;
  final String surname;
  final String email;
  final String tel;
  final DateTime? birthday;
  final String? sex;
  final String? professionDescription;
  final String? educationDescription;
  final String? cityName;
  final String? officeTitle;
  final String? currentStatus;
  final String? currentStatusDescription;
  final DateTime? createdAt;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final List<WebAdvisorStatus> statuses;

  const WebAdvisorApplication({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.tel,
    this.birthday,
    this.sex,
    this.professionDescription,
    this.educationDescription,
    this.cityName,
    this.officeTitle,
    this.currentStatus,
    this.currentStatusDescription,
    this.createdAt,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.statuses = const [],
  });

  factory WebAdvisorApplication.fromJson(Map<String, dynamic> json) {
    final rawStatuses = json['statuses'];
    final statuses = rawStatuses is List
        ? rawStatuses
            .whereType<Map>()
            .map((e) => WebAdvisorStatus.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WebAdvisorStatus>[];
    return WebAdvisorApplication(
      id: _int(json['id']) ?? 0,
      name: _str(json['name']) ?? '',
      surname: _str(json['surname']) ?? '',
      email: _str(json['e_mail']) ?? _str(json['email']) ?? '',
      tel: _str(json['tel']) ?? '',
      birthday: _date(json['birthday']),
      sex: _str(json['sex']),
      professionDescription: _str(json['profession_description']),
      educationDescription: _str(json['education_description']),
      cityName: _str(json['city_name']),
      officeTitle: _str(json['office_title']),
      currentStatus: _str(json['current_status']),
      currentStatusDescription: _str(json['current_status_description']),
      createdAt: _date(json['created_at']),
      utmSource: _str(json['utm_source']),
      utmMedium: _str(json['utm_medium']),
      utmCampaign: _str(json['utm_campaign']),
      statuses: statuses,
    );
  }

  String get fullName {
    final text = '$name $surname'.trim();
    return text.isEmpty ? '-' : text;
  }

  String get statusLabel {
    final text = currentStatusDescription?.trim();
    if (text != null && text.isNotEmpty) return text;
    return (currentStatus ?? '').isEmpty ? '-' : currentStatus!;
  }

  String get sexLabel {
    switch (sex) {
      case 'M':
        return 'Erkek';
      case 'F':
        return 'Kadın';
      default:
        return (sex ?? '').isEmpty ? '-' : sex!;
    }
  }
}

class WebAdvisorListResponse {
  final List<WebAdvisorApplication> applications;
  final int totalCount;
  final int totalPages;
  final int page;

  const WebAdvisorListResponse({
    required this.applications,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory WebAdvisorListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['applications'];
    final applications = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                WebAdvisorApplication.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <WebAdvisorApplication>[];
    return WebAdvisorListResponse(
      applications: applications,
      totalCount: _int(json['totalCount']) ?? applications.length,
      totalPages: _int(json['totalPages']) ?? 1,
      page: _int(json['page']) ?? 1,
    );
  }
}

String? _str(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null') return null;
  return text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _date(dynamic value) {
  final text = _str(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}
