class PNotificationModel {
  final int id;
  final String title;
  final String content;
  final String? picture;
  final String action;
  final NotificationData data;
  final int contact;
  final dynamic group;
  final dynamic source;
  final bool? read;
  final String createdAt;
  final int status;

  /// Okundu kabul edilmek için API'den açıkça true (veya 1) gelmeli; null/false okunmamış.
  bool get isRead => read == true;

  PNotificationModel({
    required this.id,
    required this.title,
    required this.content,
    this.picture,
    required this.action,
    required this.data,
    required this.contact,
    this.group,
    this.source,
    this.read,
    required this.createdAt,
    required this.status,
  });

  /// API bazen read alanını bool, bazen int (0/1) döndürebilir; hepsini tutarlı bool? yapıyoruz.
  static bool? _parseRead(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  PNotificationModel copyWith({
    bool? read,
  }) {
    return PNotificationModel(
      id: id,
      title: title,
      content: content,
      picture: picture,
      action: action,
      data: data,
      contact: contact,
      group: group,
      source: source,
      read: read ?? this.read,
      createdAt: createdAt,
      status: status,
    );
  }

  factory PNotificationModel.fromJson(Map<String, dynamic> json) {
    return PNotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      picture: json['picture'] as String?,
      action: json['action'] as String,
      data: NotificationData.fromJson(json['data'] as Map<String, dynamic>),
      contact: json['contact'] as int,
      group: json['group'],
      source: json['source'],
      read: _parseRead(json['read'] ?? json['is_read']),
      createdAt: json['created_at'] as String,
      status: json['status'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'picture': picture,
      'action': action,
      'data': data.toJson(),
      'contact': contact,
      'group': group,
      'source': source,
      'read': read,
      'created_at': createdAt,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'PNotificationModel(id: $id, title: $title, content: $content, picture: $picture, action: $action, data: $data, contact: $contact, group: $group, source: $source, read: $read, createdAt: $createdAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PNotificationModel &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.picture == picture &&
        other.action == action &&
        other.data == data &&
        other.contact == contact &&
        other.group == group &&
        other.source == source &&
        other.read == read &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        content.hashCode ^
        picture.hashCode ^
        action.hashCode ^
        data.hashCode ^
        contact.hashCode ^
        group.hashCode ^
        source.hashCode ^
        read.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }
}

class NotificationData {
  final int? form;
  final int? contactNo;
  final String? user;
  final String? link;

  NotificationData({
    this.form,
    this.contactNo,
    this.user,
    this.link,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      form: json['form'] as int?,
      contactNo: json['contact_no'] as int?,
      user: json['user'] as String?,
      link: json['link'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'form': form,
      'contact_no': contactNo,
      'user': user,
      'link': link,
    };
  }

  @override
  String toString() {
    return 'NotificationData(form: $form, contactNo: $contactNo, user: $user, link: $link)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationData &&
        other.form == form &&
        other.contactNo == contactNo &&
        other.user == user &&
        other.link == link;
  }

  @override
  int get hashCode {
    return form.hashCode ^
        contactNo.hashCode ^
        user.hashCode ^
        link.hashCode;
  }
}

class NotificationResponse {
  final List<PNotificationModel> notifications;
  final int totalCount;
  final int totalPages;
  final int page;

  NotificationResponse({
    required this.notifications,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notifications: (json['notifications'] as List)
          .map((notification) => PNotificationModel.fromJson(notification as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((notification) => notification.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }

  @override
  String toString() {
    return 'NotificationResponse(notifications: $notifications, totalCount: $totalCount, totalPages: $totalPages, page: $page)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationResponse &&
        other.notifications == notifications &&
        other.totalCount == totalCount &&
        other.totalPages == totalPages &&
        other.page == page;
  }

  @override
  int get hashCode {
    return notifications.hashCode ^
        totalCount.hashCode ^
        totalPages.hashCode ^
        page.hashCode;
  }
}
