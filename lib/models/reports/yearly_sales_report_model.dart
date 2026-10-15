import 'package:zecorner/models/reports/report_json.dart';

const _monthKeys = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

class YearlyMonthBucket {
  final int month;
  final double total;
  final int count;

  const YearlyMonthBucket({
    required this.month,
    required this.total,
    required this.count,
  });
}

class YearlyAdvisorRow {
  final int office;
  final String officeTitle;
  final int advisor;
  final String advisorTitle;
  final int reportYear;
  final List<YearlyMonthBucket> months;

  const YearlyAdvisorRow({
    required this.office,
    required this.officeTitle,
    required this.advisor,
    required this.advisorTitle,
    required this.reportYear,
    required this.months,
  });

  double get yearTotal =>
      months.fold(0, (sum, month) => sum + month.total);

  int get yearCount =>
      months.fold(0, (sum, month) => sum + month.count);

  factory YearlyAdvisorRow.fromJson(dynamic json) {
    final map = asJsonMap(json) ?? <String, dynamic>{};
    final months = <YearlyMonthBucket>[];
    for (var i = 0; i < _monthKeys.length; i++) {
      final key = _monthKeys[i];
      months.add(
        YearlyMonthBucket(
          month: i + 1,
          total: pickDouble(map['${key}_amount']),
          count: pickInt(map['${key}_count']),
        ),
      );
    }

    return YearlyAdvisorRow(
      office: pickInt(firstKey(map, ['office'])),
      officeTitle: pickString(
        firstKey(map, ['office_title', 'officeTitle']),
        '—',
      ),
      advisor: pickInt(firstKey(map, ['advisor'])),
      advisorTitle: pickString(
        firstKey(map, ['advisor_title', 'advisorTitle']),
        '—',
      ),
      reportYear: pickInt(firstKey(map, ['report_year', 'year'])),
      months: months,
    );
  }
}

class YearlySalesReportModel {
  final int year;
  final List<YearlyAdvisorRow> rows;

  const YearlySalesReportModel({
    required this.year,
    required this.rows,
  });

  double get total =>
      rows.fold(0, (sum, row) => sum + row.yearTotal);

  int get count =>
      rows.fold(0, (sum, row) => sum + row.yearCount);

  int get advisorCount => rows.length;

  int get officeCount => rows.map((row) => row.office).toSet().length;

  List<double> get monthlyTotals {
    final values = List<double>.filled(12, 0);
    for (final row in rows) {
      for (final month in row.months) {
        if (month.month >= 1 && month.month <= 12) {
          values[month.month - 1] += month.total;
        }
      }
    }
    return values;
  }

  List<int> get monthlyCounts {
    final values = List<int>.filled(12, 0);
    for (final row in rows) {
      for (final month in row.months) {
        if (month.month >= 1 && month.month <= 12) {
          values[month.month - 1] += month.count;
        }
      }
    }
    return values;
  }

  factory YearlySalesReportModel.fromJson(dynamic json, {required int year}) {
    final rows = pickList(json, [
      'items',
      'list',
      'results',
      'data',
      'sales',
    ]).map(YearlyAdvisorRow.fromJson).toList();

    return YearlySalesReportModel(year: year, rows: rows);
  }
}
