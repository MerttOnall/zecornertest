import 'package:zecorner/models/reports/report_json.dart';

class CariAccountRow {
  final int officeContactNo;
  final String officeTitle;
  final String tradeName;
  final int totalInvoiceCount;
  final double totalInvoiceAmount;
  final double totalPaymentAmount;
  final double remainingBalance;
  final int openInvoiceCount;
  final String? lastPaymentDate;
  final int status;

  const CariAccountRow({
    required this.officeContactNo,
    required this.officeTitle,
    required this.tradeName,
    required this.totalInvoiceCount,
    required this.totalInvoiceAmount,
    required this.totalPaymentAmount,
    required this.remainingBalance,
    required this.openInvoiceCount,
    required this.lastPaymentDate,
    required this.status,
  });

  bool get isSettled => remainingBalance <= 0 && openInvoiceCount <= 0;

  factory CariAccountRow.fromJson(dynamic json) {
    final map = asJsonMap(json) ?? <String, dynamic>{};
    return CariAccountRow(
      officeContactNo: pickInt(
        firstKey(map, ['ofis_contact_no', 'office_contact_no', 'office']),
      ),
      officeTitle: pickString(
        firstKey(map, ['ofis_contact_title', 'office_title', 'title']),
        '—',
      ),
      tradeName: pickString(
        firstKey(map, ['ofis_trade_name', 'trade_name']),
      ),
      totalInvoiceCount: pickInt(
        firstKey(map, ['total_invoice_count']),
      ),
      totalInvoiceAmount: pickDouble(
        firstKey(map, ['total_invoice_amount']),
      ),
      totalPaymentAmount: pickDouble(
        firstKey(map, ['total_payment_amount']),
      ),
      remainingBalance: pickDouble(
        firstKey(map, ['remaining_balance']),
      ),
      openInvoiceCount: pickInt(
        firstKey(map, ['open_invoice_count']),
      ),
      lastPaymentDate: pickString(
        firstKey(map, ['last_payment_date']),
      ).isEmpty
          ? null
          : pickString(firstKey(map, ['last_payment_date'])),
      status: pickInt(firstKey(map, ['status']), 1),
    );
  }
}

class CariReportModel {
  final List<CariAccountRow> accounts;

  const CariReportModel({required this.accounts});

  double get totalInvoiceAmount =>
      accounts.fold(0, (sum, row) => sum + row.totalInvoiceAmount);

  double get totalPaymentAmount =>
      accounts.fold(0, (sum, row) => sum + row.totalPaymentAmount);

  double get remainingBalance =>
      accounts.fold(0, (sum, row) => sum + row.remainingBalance);

  factory CariReportModel.fromJson(dynamic json) {
    final rows = pickList(json, [
      'offices',
      'accounts',
      'items',
      'list',
      'results',
      'data',
    ]).map(CariAccountRow.fromJson).toList();
    return CariReportModel(accounts: rows);
  }
}
