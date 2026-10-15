class RewardModel {
  final String total;
  final String officeTitle;
  final int officeNo;
  final String officeCity;
  final String officeDistrict;
  final String? title;
  final String? contactTypeDescription;
  final int? contactNo;

  RewardModel({
    required this.total,
    required this.officeTitle,
    required this.officeNo,
    this.officeCity = '',
    this.officeDistrict = '',
    this.title,
    this.contactTypeDescription,
    this.contactNo,
  });

  String get locationLabel {
    if (officeCity.isEmpty && officeDistrict.isEmpty) return '';
    if (officeCity.isNotEmpty && officeDistrict.isNotEmpty) {
      return '$officeCity / $officeDistrict';
    }
    return officeCity.isNotEmpty ? officeCity : officeDistrict;
  }

  String displayPrimary({required bool isContactGroup}) {
    if (isContactGroup) {
      return title?.trim().isNotEmpty == true
          ? title!.trim()
          : (contactTypeDescription?.trim().isNotEmpty == true
              ? contactTypeDescription!.trim()
              : officeTitle);
    }
    return officeTitle;
  }

  String? displaySecondary({required bool isContactGroup}) {
    if (isContactGroup) {
      final parts = <String>[];
      if (contactTypeDescription?.trim().isNotEmpty == true) {
        parts.add(contactTypeDescription!.trim());
      }
      if (officeTitle.trim().isNotEmpty) {
        parts.add(officeTitle.trim());
      }
      return parts.isEmpty ? null : parts.join(' • ');
    }
    return locationLabel.isEmpty ? null : locationLabel;
  }

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      total: json['total']?.toString() ?? '0.00',
      officeTitle: json['office_title']?.toString() ?? '',
      officeNo: json['office_no'] is int
          ? json['office_no'] as int
          : int.tryParse(json['office_no']?.toString() ?? '') ?? 0,
      officeCity: json['office_city']?.toString() ?? '',
      officeDistrict: json['office_district']?.toString() ?? '',
      title: json['title']?.toString(),
      contactTypeDescription: json['contact_type_description']?.toString(),
      contactNo: json['contact_no'] is int
          ? json['contact_no'] as int
          : int.tryParse(json['contact_no']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'office_title': officeTitle,
      'office_no': officeNo,
      'office_city': officeCity,
      'office_district': officeDistrict,
      'title': title,
      'contact_type_description': contactTypeDescription,
      'contact_no': contactNo,
    };
  }
}

class RewardResponse {
  final List<RewardModel> rewards;
  final String groupBy;

  RewardResponse({
    required this.rewards,
    this.groupBy = 'office',
  });

  bool get isContactGroup => groupBy == 'contact';

  factory RewardResponse.fromJson(
    dynamic json, {
    String groupBy = 'office',
  }) {
    if (json is List) {
      return RewardResponse(
        groupBy: groupBy,
        rewards: json
            .whereType<Map>()
            .map((item) => RewardModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    }
    if (json is Map<String, dynamic>) {
      final list = json['rewards'] ?? json['data'] ?? json['items'];
      if (list is List) {
        return RewardResponse(
          groupBy: groupBy,
          rewards: list
              .whereType<Map>()
              .map((item) => RewardModel.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
        );
      }
    }
    return RewardResponse(rewards: [], groupBy: groupBy);
  }
}
