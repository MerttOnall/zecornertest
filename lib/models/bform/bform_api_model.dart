import 'package:flutter/material.dart';

class BformStatusHistory {
  final int id;
  final String statusType;
  final String contactType;
  final int? relatedContact;
  final String? name;
  final String? surname;
  final String? description;
  final int? rating;
  final DateTime? createdAt;
  final int? createdBy;
  final int? status;
  final DateTime? date;
  final String? email;
  final String? typeDescription;
  final String? picture;

  BformStatusHistory({
    required this.id,
    required this.statusType,
    required this.contactType,
    this.relatedContact,
    this.name,
    this.surname,
    this.description,
    this.rating,
    this.createdAt,
    this.createdBy,
    this.status,
    this.date,
    this.email,
    this.typeDescription,
    this.picture,
  });

  factory BformStatusHistory.fromJson(Map<String, dynamic> json) {
    try {
      return BformStatusHistory(
        id: BformApiModel._parseInt(json['id']) ?? 0,
        statusType: BformApiModel._parseString(json['status_type']) ?? '',
        contactType: BformApiModel._parseString(json['contact_type']) ?? '',
        relatedContact: BformApiModel._parseInt(json['related_contact']) ??
            BformApiModel._parseInt(json['related_contact_no']),
        name: BformApiModel._parseString(json['related_contact_name']) ??
            BformApiModel._parseString(json['name']),
        surname: BformApiModel._parseString(json['related_contact_surname']) ??
            BformApiModel._parseString(json['surname']),
        description: BformApiModel._parseString(json['description']),
        rating: BformApiModel._parseInt(json['rating']),
        createdAt: BformApiModel._parseDateTime(json['created_at']),
        createdBy: BformApiModel._parseInt(json['created_by']),
        status: BformApiModel._parseInt(json['status']),
        date: BformApiModel._parseDateTime(json['date']),
        email: BformApiModel._parseString(json['related_contact_e_mail']),
        typeDescription:
            BformApiModel._parseString(json['related_contact_type_description']),
        picture: BformApiModel._parseString(json['related_contact_picture']),
      );
    } catch (e) {
      print('❌ Error parsing BformStatusHistory: $e');
      print('❌ JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_type': statusType,
      'contact_type': contactType,
      'related_contact': relatedContact,
      'name': name,
      'surname': surname,
      'description': description,
      'rating': rating,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
      'status': status,
      'date': date?.toIso8601String(),
    };
  }

  String get assignedFullName {
    final parts = [name, surname].where((p) => p != null && p.trim().isNotEmpty);
    if (parts.isEmpty) return '';
    return parts.join(' ');
  }

  String get statusTypeDisplay {
    switch (statusType.toLowerCase()) {
      case 'called':
        return 'Arandı';
      case 'on-going':
        return 'Devam Ediyor';
      case 'not-interviewed':
        return 'Görüşülmedi';
      case 'rejected':
        return 'Olumsuz';
      case 'approved':
        return 'Onaylandı';
      case 'interviewed':
        return 'Görüşüldü';
      case 'unanswered':
        return 'Cevapsız';
      case 'not-available':
        return 'Müsait Değil';
      default:
        return statusType.isEmpty ? '-' : statusType;
    }
  }

  String get contactTypeDisplay {
    switch (contactType.toLowerCase()) {
      case 'not-interviewed':
        return 'Görüşülmedi';
      case 'mail':
        return 'Mail İle İletişim';
      case 'video':
        return 'Video Görüşme';
      case 'face-to-face':
      case 'face':
        return 'Yüzyüze Görüşme';
      case 'phone':
        return 'Telefon İle Görüşüldü';
      default:
        return contactType.isEmpty ? '-' : contactType;
    }
  }
}

class BformApiModel {
  final int id;
  final String name;
  final String surname;
  final String mail;
  final String phone;
  final int? quarter;
  final String? message;
  final String? listingType;
  final String? propertyType;
  final String? profession; // UUID for advisor forms
  final String? professionDescription; // Description for advisor forms
  final String? education; // UUID for advisor forms
  final String? educationDescription; // Description for advisor forms
  final int? city; // City code for advisor forms
  final int? district; // District code for advisor forms
  final DateTime createdAt;
  final String currentStatus;
  final int? relatedContact;
  final String districtText;
  final String? rcName;
  final String? rcSurname;
  final String? rcTypeDescription;
  final String? rcPicture;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;
  final String? adName;
  final String? detail; // Detail for blacklist
  final int? rating; // Rating for blacklist
  final DateTime? updatedAt; // Updated at timestamp
  final bool? blacklist; // Is blacklist entry
  final List<BformStatusHistory>? statusHistory; // Status history array
  final int officeId;
  final String officeTitle;

  BformApiModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.mail,
    required this.phone,
    this.quarter,
    this.message,
    this.listingType,
    this.propertyType,
    this.profession,
    this.professionDescription,
    this.education,
    this.educationDescription,
    this.city,
    this.district,
    required this.createdAt,
    required this.currentStatus,
    this.relatedContact,
    required this.districtText,
    this.rcName,
    this.rcSurname,
    this.rcTypeDescription,
    this.rcPicture,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
    this.adName,
    this.detail,
    this.rating,
    this.updatedAt,
    this.blacklist,
    this.statusHistory,
    this.officeId = 0,
    this.officeTitle = '',
  });

  // Helper method to safely parse String from JSON (handles Map cases)
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      // If it's a Map, try to extract a meaningful string value
      if (value.containsKey('id')) return value['id'].toString();
      if (value.containsKey('name')) return value['name'].toString();
      if (value.containsKey('value')) return value['value'].toString();
      return null;
    }
    return value.toString();
  }

  // Helper method to safely parse int from JSON
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // Helper method to safely parse bool from JSON
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  // Helper method to safely parse DateTime from JSON
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory BformApiModel.fromJson(Map<String, dynamic> json) {
    try {
      return BformApiModel(
        id: json['id'] as int? ?? 0,
        name: _parseString(json['name']) ?? '',
        surname: _parseString(json['surname']) ?? '',
        mail: _parseString(json['e_mail']) ?? _parseString(json['mail']) ?? '',
        phone: _parseString(json['tel']) ?? _parseString(json['phone']) ?? '',
        quarter: _parseInt(json['quarter']) ?? 0,
        message: _parseString(json['message']),
        listingType: _parseString(json['listing_type']),
        propertyType: _parseString(json['property_type']),
        profession: _parseString(json['profession']),
        professionDescription: _parseString(json['profession_description']),
        education: _parseString(json['education']),
        educationDescription: _parseString(json['education_description']),
        city: _parseInt(json['city']),
        district: _parseInt(json['district']),
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
        currentStatus: _parseString(json['current_status']) ?? '',
        relatedContact: _parseInt(json['related_contact']),
        districtText: _parseString(json['district_text']) ?? '',
        rcName: _parseString(json['rc_name']),
        rcSurname: _parseString(json['rc_surname']),
        rcTypeDescription: _parseString(json['rc_type_description']),
        rcPicture: _parseString(json['rc_picture']),
        utmSource: _parseString(json['utm_source']),
        utmMedium: _parseString(json['utm_medium']),
        utmCampaign: _parseString(json['utm_campaign']),
        utmContent: _parseString(json['utm_content']),
        utmTerm: _parseString(json['utm_term']),
        adName: _parseString(json['ad_name']),
        detail: _parseString(json['detail']),
        rating: _parseInt(json['rating']),
        updatedAt: _parseDateTime(json['updated_at']),
        blacklist: _parseBool(json['blacklist']),
        officeId: _parseInt(json['office']) ??
            _parseInt(json['office_id']) ??
            _parseInt(json['connected_contact']) ??
            0,
        officeTitle: _parseString(json['office_title']) ??
            _parseString(json['connected_contact_title']) ??
            _parseString(json['ofis_contact_title']) ??
            '',
        statusHistory: json['status'] != null && json['status'] is List
            ? (json['status'] as List)
                .map((item) {
                  try {
                    if (item is Map<String, dynamic>) {
                      return BformStatusHistory.fromJson(item);
                    }
                    return null;
                  } catch (e) {
                    return null;
                  }
                })
                .whereType<BformStatusHistory>()
                .toList()
            : null,
      );
    } catch (e) {
      // Log error for debugging
      print('❌ Error parsing BformApiModel: $e');
      print('❌ JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'mail': mail,
      'phone': phone,
      'quarter': quarter,
      'message': message,
      'listing_type': listingType,
      'property_type': propertyType,
      'profession': profession,
      'profession_description': professionDescription,
      'education': education,
      'education_description': educationDescription,
      'city': city,
      'district': district,
      'created_at': createdAt.toIso8601String(),
      'current_status': currentStatus,
      'related_contact': relatedContact,
      'district_text': districtText,
      'rc_name': rcName,
      'rc_surname': rcSurname,
      'rc_type_description': rcTypeDescription,
      'rc_picture': rcPicture,
      'utm_source': utmSource,
      'utm_medium': utmMedium,
      'utm_campaign': utmCampaign,
      'utm_content': utmContent,
      'utm_term': utmTerm,
      'ad_name': adName,
      'detail': detail,
      'rating': rating,
      'updated_at': updatedAt?.toIso8601String(),
      'blacklist': blacklist,
      'office': officeId,
      'office_title': officeTitle,
      'status': statusHistory?.map((item) => item.toJson()).toList(),
    };
  }

  // Helper getters
  String get fullName => '$name $surname';
  
  String get contactInfo => '$mail\n$phone';
  
  String get propertyTypeDisplay {
    if (propertyType == null || propertyType!.isEmpty) {
      return '-';
    }
    switch (propertyType) {
      case 'arsa':
        return 'Satılık Arsa';
      case 'konut':
        return 'Satılık Konut';
      case 'is-yeri':
        return 'Kiralık İş Yeri';
      default:
        return propertyType!.toUpperCase();
    }
  }
  
  String get statusDisplay {
    switch (currentStatus.toLowerCase()) {
      case 'called':
        return 'Arandı';
      case 'on-going':
        return 'Devam Ediyor';
      case 'not-interviewed':
        return 'Görüşülmedi';
      case 'rejected':
        return 'Olumsuz';
      case 'approved':
        return 'Onaylandı';
      case 'assigned':
        return 'Atandı';
      case 'interviewed':
        return 'Görüşüldü';
      case 'unanswered':
        return 'Cevapsız';
      case 'not-available':
        return 'Müsait Değil';
      default:
        return currentStatus.isEmpty ? '-' : currentStatus;
    }
  }
  
  Color get statusColor {
    switch (currentStatus.toLowerCase()) {
      case 'called':
        return Colors.purple;
      case 'on-going':
        return Colors.blue;
      case 'not-interviewed':
        return Colors.pink;
      case 'rejected':
        return Colors.red;
      case 'approved':
      case 'assigned':
        return const Color(0xFF10B981);
      case 'interviewed':
        return Colors.teal;
      case 'unanswered':
      case 'not-available':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
  
  String get relatedPersonName {
    if (rcName != null && rcSurname != null) {
      return '$rcName $rcSurname';
    }
    return '-';
  }
  
  String get relatedPersonType {
    return rcTypeDescription ?? '-';
  }
  
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
  
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

class BformResponse {
  final List<BformApiModel> data;
  final int totalCount;
  final int totalPages;
  final int page;

  BformResponse({
    required this.data,
    required this.totalCount,
    required this.totalPages,
    required this.page,
  });

  factory BformResponse.fromJson(Map<String, dynamic> json) {
    return BformResponse(
      data: (json['data'] as List)
          .map((item) => BformApiModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as int?) ?? (json['total_count'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? (json['total_pages'] as int?) ?? 1,
      page: (json['page'] as int?) ?? 1,
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
