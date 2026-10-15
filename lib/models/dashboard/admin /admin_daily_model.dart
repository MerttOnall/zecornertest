class AdminDailyModel {
  final List<DayModel> days;
  final double total;

  AdminDailyModel({
    required this.days,
    required this.total,
  });

  factory AdminDailyModel.fromJson(Map<String, dynamic> json) {
    return AdminDailyModel(
      days: (json['days'] as List<dynamic>?)
              ?.map((e) => DayModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }

  @override
  String toString() {
    return 'AdminDailyModel(days: $days, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminDailyModel &&
        other.days == days &&
        other.total == total;
  }

  @override
  int get hashCode {
    return days.hashCode ^ total.hashCode;
  }
}

class DayModel {
  final String day;
  final double revenue;

  DayModel({
    required this.day,
    required this.revenue,
  });

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      day: json['day'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'revenue': revenue,
    };
  }

  @override
  String toString() {
    return 'DayModel(day: $day, revenue: $revenue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayModel &&
        other.day == day &&
        other.revenue == revenue;
  }

  @override
  int get hashCode {
    return day.hashCode ^ revenue.hashCode;
  }
}
