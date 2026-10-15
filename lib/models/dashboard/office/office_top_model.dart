class OfficeTopModel {
  final List<TopItemModel> week;
  final List<TopItemModel> month;
  final List<TopItemModel> year;
  final TopItemModel? officeWeek;
  final TopItemModel? officeMonth;
  final TopItemModel? officeYear;

  OfficeTopModel({
    this.week = const [],
    this.month = const [],
    this.year = const [],
    this.officeWeek,
    this.officeMonth,
    this.officeYear,
  });

  factory OfficeTopModel.fromJson(Map<String, dynamic> json) {
    return OfficeTopModel(
      week: (json['week'] as List<dynamic>?)
          ?.map((item) => TopItemModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      month: (json['month'] as List<dynamic>?)
          ?.map((item) => TopItemModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      year: (json['year'] as List<dynamic>?)
          ?.map((item) => TopItemModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      officeWeek: json['office_week'] != null
          ? TopItemModel.fromJson(json['office_week'] as Map<String, dynamic>)
          : null,
      officeMonth: json['office_month'] != null
          ? TopItemModel.fromJson(json['office_month'] as Map<String, dynamic>)
          : null,
      officeYear: json['office_year'] != null
          ? TopItemModel.fromJson(json['office_year'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week.map((item) => item.toJson()).toList(),
      'month': month.map((item) => item.toJson()).toList(),
      'year': year.map((item) => item.toJson()).toList(),
      'office_week': officeWeek?.toJson(),
      'office_month': officeMonth?.toJson(),
      'office_year': officeYear?.toJson(),
    };
  }

  @override
  String toString() {
    return 'OfficeTopModel(week: $week, month: $month, year: $year, officeWeek: $officeWeek, officeMonth: $officeMonth, officeYear: $officeYear)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeTopModel &&
        other.week == week &&
        other.month == month &&
        other.year == year &&
        other.officeWeek == officeWeek &&
        other.officeMonth == officeMonth &&
        other.officeYear == officeYear;
  }

  @override
  int get hashCode {
    return week.hashCode ^ 
           month.hashCode ^ 
           year.hashCode ^
           officeWeek.hashCode ^
           officeMonth.hashCode ^
           officeYear.hashCode;
  }
}

class TopItemModel {
  final int advisor;
  final String advisorTitle;
  final int office;
  final String officeTitle;
  final String total;
  final String? no;

  TopItemModel({
    required this.advisor,
    required this.advisorTitle,
    required this.office,
    required this.officeTitle,
    required this.total,
    this.no,
  });

  factory TopItemModel.fromJson(Map<String, dynamic> json) {
    return TopItemModel(
      advisor: json['advisor'] ?? 0,
      advisorTitle: json['advisor_title'] ?? '',
      office: json['office'] ?? 0,
      officeTitle: json['office_title'] ?? '',
      total: json['total'] ?? '',
      no: json['no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisor': advisor,
      'advisor_title': advisorTitle,
      'office': office,
      'office_title': officeTitle,
      'total': total,
      'no': no,
    };
  }

  @override
  String toString() {
    return 'TopItemModel(advisor: $advisor, advisorTitle: $advisorTitle, office: $office, officeTitle: $officeTitle, total: $total, no: $no)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopItemModel &&
        other.advisor == advisor &&
        other.advisorTitle == advisorTitle &&
        other.office == office &&
        other.officeTitle == officeTitle &&
        other.total == total &&
        other.no == no;
  }

  @override
  int get hashCode {
    return advisor.hashCode ^
        advisorTitle.hashCode ^
        office.hashCode ^
        officeTitle.hashCode ^
        total.hashCode ^
        no.hashCode;
  }
}
