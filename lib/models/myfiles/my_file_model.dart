class MyFileModel {
  final int id;
  final String title;
  final String subTitle;
  final String fileName;
  final String uuid;
  final int category;
  final String? thumbnail;
  final dynamic detail;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? contact;

  MyFileModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.fileName,
    required this.uuid,
    required this.category,
    this.thumbnail,
    this.detail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.contact,
  });

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime _asDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory MyFileModel.fromJson(Map<String, dynamic> json) {
    return MyFileModel(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      subTitle: json['sub_title']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      uuid: json['uuid']?.toString() ?? '',
      category: _asInt(json['category']),
      thumbnail: json['thumbnail']?.toString(),
      detail: json['detail'],
      status: _asInt(json['status'], 1),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      contact: json['contact'] != null ? _asInt(json['contact']) : null,
    );
  }
}

class MyFileResponse {
  final List<MyFileModel> data;
  final int totalCount;
  final int totalPages;
  final int page;

  MyFileResponse({
    required this.data,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory MyFileResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = rawList is List
        ? rawList
            .whereType<Map>()
            .map((item) => MyFileModel.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <MyFileModel>[];
    return MyFileResponse(
      data: items,
      totalCount: MyFileModel._asInt(json['totalCount'], items.length),
      totalPages: MyFileModel._asInt(json['totalPages'], 1),
      page: MyFileModel._asInt(json['page'], 1),
    );
  }
}
