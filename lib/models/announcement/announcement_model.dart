class Announcement {
  final int id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? announcementTime;
  final String state;
  final int status;
  final String category;
  final List<int> contactTypes;

  Announcement({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.announcementTime,
    required this.state,
    required this.status,
    required this.category,
    required this.contactTypes,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      announcementTime: json['announcement_time'] != null
          ? DateTime.parse(json['announcement_time'] as String)
          : null,
      state: json['state'] as String,
      status: json['status'] as int,
      category: json['category'] as String,
      contactTypes: (json['contact_types'] as List<dynamic>)
          .map((item) => item as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'announcement_time': announcementTime?.toIso8601String(),
      'state': state,
      'status': status,
      'category': category,
      'contact_types': contactTypes,
    };
  }

  // Yardımcı metodlar
  bool get isLive => state == 'LIVE';
  bool get isActive => status == 1;
  
  // Kategori description için yardımcı method
  String get categoryDescription {
    switch (category) {
      case 'default':
        return 'Genel Duyuru';
      case 'maintenance':
        return 'Bakım';
      case 'info':
        return 'Bilgilendirme';
      default:
        return category;
    }
  }
}

class AnnouncementResponse {
  final List<Announcement> announcements;
  final int totalCount;
  final int totalPages;
  final int page;

  AnnouncementResponse({
    required this.announcements,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      announcements: (json['announcements'] as List<dynamic>)
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'announcements': announcements.map((a) => a.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}

