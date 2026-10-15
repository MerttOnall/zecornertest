import 'package:zecorner/core/utils/image_utils.dart';

class ZeDosyaApiModel {
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
  final bool featured;
  final List<int>? connectedContacts;

  ZeDosyaApiModel({
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
    required this.featured,
    this.connectedContacts,
  });

  factory ZeDosyaApiModel.fromJson(Map<String, dynamic> json) {
    return ZeDosyaApiModel(
      id: json['id'] as int,
      title: json['title'] as String,
      subTitle: json['sub_title'] as String,
      fileName: json['file_name'] as String,
      uuid: json['uuid'] as String,
      category: json['category'] as int,
      thumbnail: json['thumbnail'] as String?,
      detail: json['detail'],
      status: json['status'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      featured: json['featured'] as bool,
      connectedContacts: json['connected_contacts'] != null 
          ? List<int>.from(json['connected_contacts'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sub_title': subTitle,
      'file_name': fileName,
      'uuid': uuid,
      'category': category,
      'thumbnail': thumbnail,
      'detail': detail,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'featured': featured,
      'connected_contacts': connectedContacts,
    };
  }

  /// S3'ten thumbnail URL'i oluştur
  String get thumbnailUrl {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      return ImageUtils.getS3FileUrl(thumbnail);
    }
    return '';
  }

  /// Dosya türüne göre renk döndür
  String get fileTypeColor {
    switch (subTitle.toLowerCase()) {
      case 'word':
        return '#1976D2';
      case 'excel':
        return '#43A047';
      case 'png':
        return '#E53935';
      default:
        return '#9E9E9E';
    }
  }

  /// Dosya türüne göre icon döndür
  String get fileTypeIcon {
    switch (subTitle.toLowerCase()) {
      case 'word':
        return 'description_rounded';
      case 'excel':
        return 'grid_on_rounded';
      case 'png':
        return 'image_rounded';
      default:
        return 'insert_drive_file_rounded';
    }
  }

  /// Dosya boyutunu formatla (eğer detail'de varsa)
  String get formattedFileSize {
    // Detail'den dosya boyutunu al, yoksa varsayılan
    return 'N/A';
  }

  /// Oluşturulma tarihini formatla
  String get formattedCreatedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

class ZeDosyaResponse {
  final List<ZeDosyaApiModel> data;
  final int totalCount;
  final int totalPages;
  final int page;

  ZeDosyaResponse({
    required this.data,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory ZeDosyaResponse.fromJson(Map<String, dynamic> json) {
    return ZeDosyaResponse(
      data: (json['data'] as List)
          .map((item) => ZeDosyaApiModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'totalCount': totalCount,
      'totalPages': totalPages,
      'page': page,
    };
  }
}
