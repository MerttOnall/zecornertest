import 'package:flutter/material.dart';

const Color _couponRed = Color(0xFFE53935);

/// Kırmızı tema + Türkçe takvim/saat (MaterialApp’te `localizationsDelegates` gerekir).
Future<DateTime?> pickCouponValidUntil(
  BuildContext context, {
  required DateTime? current,
  required DateTime firstSelectableDate,
}) async {
  final now = DateTime.now();
  final initial = current ?? now.add(const Duration(days: 30));
  var date = initial;
  if (date.isBefore(firstSelectableDate)) {
    date = firstSelectableDate;
  }

  ThemeData redPickerTheme(BuildContext ctx) {
    return Theme.of(ctx).copyWith(
      colorScheme: const ColorScheme.light(
        primary: _couponRed,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1F2937),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _couponRed),
      ),
    );
  }

  final pickedDate = await showDatePicker(
    context: context,
    initialDate: date,
    firstDate: firstSelectableDate,
    lastDate: DateTime(2100, 12, 31),
    locale: const Locale('tr', 'TR'),
    helpText: 'Tarih seçin',
    cancelText: 'İptal',
    confirmText: 'Tamam',
    builder: (ctx, child) => Theme(data: redPickerTheme(ctx), child: child!),
  );
  if (pickedDate == null || !context.mounted) return null;

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current ?? date),
    helpText: 'Saat seçin',
    cancelText: 'İptal',
    confirmText: 'Tamam',
    builder: (ctx, child) => Theme(data: redPickerTheme(ctx), child: child!),
  );
  if (pickedTime == null || !context.mounted) return null;

  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
