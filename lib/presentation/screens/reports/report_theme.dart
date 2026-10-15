import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportTheme {
  static const Color primary = Color(0xFFE53935);
  static const Color primaryLight = Color(0xFFFFEBEE);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color soldBg = Color(0xFFD1FAE5);
  static const Color soldFg = Color(0xFF065F46);
  static const Color rentedBg = Color(0xFFDBEAFE);
  static const Color rentedFg = Color(0xFF1E40AF);
}

enum ReportsTab {
  sales,
  yearly,
  cari,
  general,
}

extension ReportsTabX on ReportsTab {
  String get label {
    switch (this) {
      case ReportsTab.sales:
        return 'Satış Raporu';
      case ReportsTab.yearly:
        return 'Yıllık Satış Raporu';
      case ReportsTab.cari:
        return 'Cari Rapor';
      case ReportsTab.general:
        return 'Genel Raporlar';
    }
  }

  String get sidebarTitle {
    switch (this) {
      case ReportsTab.sales:
        return 'Satış Raporu';
      case ReportsTab.yearly:
        return 'Yıllık Satış Raporu';
      case ReportsTab.cari:
        return 'Cari Rapor';
      case ReportsTab.general:
        return 'Genel Raporlar';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportsTab.sales:
        return Icons.trending_up_rounded;
      case ReportsTab.yearly:
        return Icons.calendar_month_rounded;
      case ReportsTab.cari:
        return Icons.account_balance_wallet_outlined;
      case ReportsTab.general:
        return Icons.assessment_outlined;
    }
  }

  static ReportsTab fromArgument(Object? args) {
    if (args is ReportsTab) return args;
    if (args is Map) {
      final raw = args['tab'];
      if (raw is ReportsTab) return raw;
      if (raw is String) {
        switch (raw) {
          case 'yearly':
            return ReportsTab.yearly;
          case 'cari':
            return ReportsTab.cari;
          case 'general':
            return ReportsTab.general;
          default:
            return ReportsTab.sales;
        }
      }
    }
    if (args is String) {
      switch (args) {
        case 'yearly':
        case 'Yıllık Satış Raporu':
          return ReportsTab.yearly;
        case 'cari':
        case 'Cari Rapor':
          return ReportsTab.cari;
        case 'general':
        case 'Genel Raporlar':
        case 'Raporlar':
          return ReportsTab.general;
        default:
          return ReportsTab.sales;
      }
    }
    return ReportsTab.sales;
  }
}

String formatReportPrice(String value) {
  final price = double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return '₺${NumberFormat('#,##0.00', 'tr_TR').format(price)}';
}

String reportFold(String value) {
  return value
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

String formatReportAmount(double value) {
  return '₺${NumberFormat('#,##0.00', 'tr_TR').format(value)}';
}

String formatReportDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(date);
  } catch (_) {
    return dateString;
  }
}
