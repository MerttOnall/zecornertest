class RelatedContact {
  final int id;
  final int contactNo;
  final String? picture;
  final String title;
  final String type;

  RelatedContact({
    required this.id,
    required this.contactNo,
    this.picture,
    required this.title,
    required this.type,
  });

  factory RelatedContact.fromJson(Map<String, dynamic> json) {
    return RelatedContact(
      id: _parseInt(json['id'], 0),
      contactNo: _parseInt(json['contact_no'], 0),
      picture: _asText(json['picture']),
      title: _asText(json['title']) ?? '',
      type: _asText(json['type']) ?? '',
    );
  }

  /// API metin alanını bazen sayı gönderebiliyor (`id`, `contact`).
  static String? _asText(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contact_no': contactNo,
      'picture': picture,
      'title': title,
      'type': type,
    };
  }

  /// Görev güncelleme isteği: sunucu bazen tam `toJson` ile bildirim satırına yanlışlıkla
  /// nesne aktarıp `"[object Object]"` integer hatası üretebiliyor; sadece FK/iş kuralları için gerekli alanlar.
  Map<String, dynamic> toTaskUpdateJson() {
    return {
      'id': id,
      'contact_no': contactNo,
      'type': type,
    };
  }
}

class Task {
  final String id;
  final String type;
  final String title;
  final String state;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? due;
  final DateTime createdAt;
  final List<String> contactType;
  final int contact;
  final List<RelatedContact> relatedContacts;
  final int priority;
  final String priorityDescription;
  final int status;

  Task({
    required this.id,
    required this.type,
    required this.title,
    required this.state,
    required this.startTime,
    this.endTime,
    this.due,
    required this.createdAt,
    required this.contactType,
    required this.contact,
    required this.relatedContacts,
    required this.priority,
    required this.priorityDescription,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final contactTypeRaw = json['contact_type'];
    final contactTypeList = contactTypeRaw is List<dynamic>
        ? contactTypeRaw.map((item) => item?.toString() ?? '').toList()
        : <String>[];
    final relatedContactsRaw = json['related_contacts'];
    final relatedContactsList = relatedContactsRaw is List
        ? relatedContactsRaw
            .map(asJsonMap)
            .whereType<Map<String, dynamic>>()
            .map(RelatedContact.fromJson)
            .toList()
        : <RelatedContact>[];
    return Task(
      id: (json['id']?.toString()) ?? '',
      type: RelatedContact._asText(json['type']) ?? '',
      title: RelatedContact._asText(json['title']) ?? '',
      state: RelatedContact._asText(json['state']) ?? 'ASSIGNED',
      startTime: _parseDateTime(json['start_time']) ?? DateTime.now(),
      endTime: _parseDateTime(json['end_time']),
      due: _parseDateTime(json['due']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      contactType: contactTypeList,
      contact: RelatedContact._parseInt(json['contact'], 0),
      relatedContacts: relatedContactsList,
      priority: RelatedContact._parseInt(json['priority'], 0),
      priorityDescription:
          RelatedContact._asText(json['priority_description']) ?? '',
      status: RelatedContact._parseInt(json['status'], 0),
    );
  }

  static Map<String, dynamic>? asJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'state': state,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'due': due?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'contact_type': contactType,
      'contact': contact,
      'related_contacts': relatedContacts.map((c) => c.toJson()).toList(),
      'priority': priority,
      'priority_description': priorityDescription,
      'status': status,
    };
  }

  // Helper methods
  bool get isAssigned => state == 'ASSIGNED';
  bool get isCompleted => state == 'COMPLETED';
  bool get isActive => status == 1;
  
  // State description için helper method
  String get stateDescription {
    switch (state.toUpperCase()) {
      case 'ASSIGNED':
        return 'Atandı';
      case 'COMPLETED':
        return 'Tamamlandı';
      case 'IN_PROGRESS':
        return 'Devam Ediyor';
      case 'CANCELLED':
        return 'İptal Edildi';
      default:
        // Eğer state tanınmıyorsa, varsayılan olarak "Atandı" döndür
        return 'Atandı';
    }
  }
  
  // Type description için helper method
  String get typeDescription {
    switch (type) {
      case 'CALL_CUSTOMER':
        return 'Müşteri Araması';
      case 'USER_TASK':
        return 'Kullanıcı Görevi';
      case 'MEETING':
        return 'Toplantı';
      default:
        return type;
    }
  }

  /// Kart / detay ekranında seçilebilir durumlar (Atandı, Tamamlandı, Devam Ediyor)
  static const List<String> cardPickerStatuses = [
    'Devam Ediyor',
    'Atandı',
    'Tamamlandı',
  ];

  /// Dropdown’da gösterilecek etiket (liste dışı API durumları için güvenli değer)
  String get pickerStatusLabel =>
      cardPickerStatuses.contains(stateDescription)
          ? stateDescription
          : 'Atandı';

  static String pickerLabelToApiState(String label) {
    switch (label) {
      case 'Devam Ediyor':
        return 'IN_PROGRESS';
      case 'Atandı':
        return 'ASSIGNED';
      case 'Tamamlandı':
        return 'COMPLETED';
      default:
        return 'ASSIGNED';
    }
  }

  Task copyWith({
    String? id,
    String? type,
    String? title,
    String? state,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? due,
    DateTime? createdAt,
    List<String>? contactType,
    int? contact,
    List<RelatedContact>? relatedContacts,
    int? priority,
    String? priorityDescription,
    int? status,
  }) {
    return Task(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      state: state ?? this.state,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      due: due ?? this.due,
      createdAt: createdAt ?? this.createdAt,
      contactType: contactType ?? this.contactType,
      contact: contact ?? this.contact,
      relatedContacts: relatedContacts ?? this.relatedContacts,
      priority: priority ?? this.priority,
      priorityDescription: priorityDescription ?? this.priorityDescription,
      status: status ?? this.status,
    );
  }
}

class TaskResponse {
  final List<Task> tasks;
  final int totalCount;
  final int totalPages;
  final int page;

  TaskResponse({
    required this.tasks,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    final tasksRaw = json['tasks'] ?? json['data'] ?? json['items'];
    final tasksList = tasksRaw is List
        ? tasksRaw
            .map(Task.asJsonMap)
            .whereType<Map<String, dynamic>>()
            .map(Task.fromJson)
            .toList()
        : <Task>[];
    final totalCount = _parseInt(json['totalCount'] ?? json['total_count'], 0);
    final totalPages = _parseInt(json['totalPages'] ?? json['total_pages'], 1);
    final page = _parseInt(json['page'], 1);
    return TaskResponse(
      tasks: tasksList,
      totalCount: totalCount,
      totalPages: totalPages,
      page: page,
    );
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

