class AdminTopModel {
  final TopItemModel? week;
  final TopItemModel? month;
  final TopItemModel? year;
  final List<OfficeTopItemModel>? officeWeek;
  final List<OfficeTopItemModel>? officeMonth;
  final List<OfficeTopItemModel>? officeYear;

  AdminTopModel({
    this.week,
    this.month,
    this.year,
    this.officeWeek,
    this.officeMonth,
    this.officeYear,
  });

  factory AdminTopModel.fromJson(Map<String, dynamic> json) {
    return AdminTopModel(
      week: json['week'] != null && json['week'] is List && (json['week'] as List).isNotEmpty
          ? TopItemModel.fromJson((json['week'] as List)[0] as Map<String, dynamic>)
          : (json['week'] != null && json['week'] is Map<String, dynamic>
              ? TopItemModel.fromJson(json['week'] as Map<String, dynamic>)
              : null),
      month: json['month'] != null && json['month'] is List && (json['month'] as List).isNotEmpty
          ? TopItemModel.fromJson((json['month'] as List)[0] as Map<String, dynamic>)
          : (json['month'] != null && json['month'] is Map<String, dynamic>
              ? TopItemModel.fromJson(json['month'] as Map<String, dynamic>)
              : null),
      year: json['year'] != null && json['year'] is List && (json['year'] as List).isNotEmpty
          ? TopItemModel.fromJson((json['year'] as List)[0] as Map<String, dynamic>)
          : (json['year'] != null && json['year'] is Map<String, dynamic>
              ? TopItemModel.fromJson(json['year'] as Map<String, dynamic>)
              : null),
      officeWeek: json['office_week'] != null && json['office_week'] is List
          ? (json['office_week'] as List)
              .map((item) => OfficeTopItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : (json['office_week'] != null && json['office_week'] is Map<String, dynamic>
              ? [OfficeTopItemModel.fromJson(json['office_week'] as Map<String, dynamic>)]
              : null),
      officeMonth: json['office_month'] != null && json['office_month'] is List
          ? (json['office_month'] as List)
              .map((item) => OfficeTopItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : (json['office_month'] != null && json['office_month'] is Map<String, dynamic>
              ? [OfficeTopItemModel.fromJson(json['office_month'] as Map<String, dynamic>)]
              : null),
      officeYear: json['office_year'] != null && json['office_year'] is List
          ? (json['office_year'] as List)
              .map((item) => OfficeTopItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : (json['office_year'] != null && json['office_year'] is Map<String, dynamic>
              ? [OfficeTopItemModel.fromJson(json['office_year'] as Map<String, dynamic>)]
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week': week?.toJson(),
      'month': month?.toJson(),
      'year': year?.toJson(),
      'office_week': officeWeek?.map((item) => item.toJson()).toList(),
      'office_month': officeMonth?.map((item) => item.toJson()).toList(),
      'office_year': officeYear?.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'AdminTopModel(week: $week, month: $month, year: $year, officeWeek: $officeWeek, officeMonth: $officeMonth, officeYear: $officeYear)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminTopModel &&
        other.week == week &&
        other.month == month &&
        other.year == year &&
        _listEquals(other.officeWeek, officeWeek) &&
        _listEquals(other.officeMonth, officeMonth) &&
        _listEquals(other.officeYear, officeYear);
  }

  @override
  int get hashCode {
    return week.hashCode ^
        month.hashCode ^
        year.hashCode ^
        (officeWeek?.hashCode ?? 0) ^
        (officeMonth?.hashCode ?? 0) ^
        (officeYear?.hashCode ?? 0);
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class TopItemModel {
  final int? advisor;
  final String? advisorTitle;
  final int office;
  final String officeTitle;
  final String total;
  final String? revenue;

  TopItemModel({
    this.advisor,
    this.advisorTitle,
    required this.office,
    required this.officeTitle,
    required this.total,
    this.revenue,
  });

  factory TopItemModel.fromJson(Map<String, dynamic> json) {
    return TopItemModel(
      advisor: json['advisor'],
      advisorTitle: json['advisor_title'],
      office: json['office'] ?? 0,
      officeTitle: json['office_title'] ?? '',
      total: json['total'] ?? '',
      revenue: json['revenue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advisor': advisor,
      'advisor_title': advisorTitle,
      'office': office,
      'office_title': officeTitle,
      'total': total,
      'revenue': revenue,
    };
  }

  @override
  String toString() {
    return 'TopItemModel(advisor: $advisor, advisorTitle: $advisorTitle, office: $office, officeTitle: $officeTitle, total: $total, revenue: $revenue)';
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
        other.revenue == revenue;
  }

  @override
  int get hashCode {
    return advisor.hashCode ^
        advisorTitle.hashCode ^
        office.hashCode ^
        officeTitle.hashCode ^
        total.hashCode ^
        revenue.hashCode;
  }
}

class OfficeTopItemModel {
  final int office;
  final String officeTitle;
  final String total;
  final String? revenue;

  OfficeTopItemModel({
    required this.office,
    required this.officeTitle,
    required this.total,
    this.revenue,
  });

  factory OfficeTopItemModel.fromJson(Map<String, dynamic> json) {
    return OfficeTopItemModel(
      office: json['office'] ?? 0,
      officeTitle: json['office_title'] ?? '',
      total: json['total'] ?? '',
      revenue: json['revenue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'office': office,
      'office_title': officeTitle,
      'total': total,
      'revenue': revenue,
    };
  }

  @override
  String toString() {
    return 'OfficeTopItemModel(office: $office, officeTitle: $officeTitle, total: $total, revenue: $revenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfficeTopItemModel &&
        other.office == office &&
        other.officeTitle == officeTitle &&
        other.total == total &&
        other.revenue == revenue;
  }

  @override
  int get hashCode {
    return office.hashCode ^
        officeTitle.hashCode ^
        total.hashCode ^
        revenue.hashCode;
  }
}
