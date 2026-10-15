class Note {
  final int id;
  final String title;
  final String content;
  final String type;
  final int contact;
  final int status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? customerTitle;
  final String? typeDescription;
  final String? listingTitle;
  final String? listingNo;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.contact,
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.customerTitle,
    this.typeDescription,
    this.listingTitle,
    this.listingNo,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: _parseInt(json['id'], 0),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? '',
      contact: _parseInt(json['contact'], 0),
      status: _parseInt(json['status'], 0),
      startDate: _parseDateTime(json['start_date']),
      endDate: _parseDateTime(json['end_date']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      customerTitle: json['customer_title'] as String?,
      typeDescription: json['type_description'] as String?,
      listingTitle: json['listing_title'] as String?,
      listingNo: json['listing_no']?.toString(),
    );
  }

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
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
      'title': title,
      'content': content,
      'type': type,
      'contact': contact,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_title': customerTitle,
      'type_description': typeDescription,
      'listing_title': listingTitle,
      'listing_no': listingNo,
    };
  }
}

class NoteResponse {
  final List<Note> notes;
  final int totalCount;
  final int totalPages;
  final int page;

  NoteResponse({
    required this.notes,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'] ?? json['data'] ?? json['items'];
    final notesList = notesRaw is List<dynamic>
        ? notesRaw
            .where((item) => item is Map<String, dynamic>)
            .map((item) => Note.fromJson(item as Map<String, dynamic>))
            .toList()
        : <Note>[];
        
    return NoteResponse(
      notes: notesList,
      totalCount: Note._parseInt(json['totalCount'] ?? json['total_count'], 0),
      totalPages: Note._parseInt(json['totalPages'] ?? json['total_pages'], 1),
      page: Note._parseInt(json['page'], 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notes': notes.map((n) => n.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
