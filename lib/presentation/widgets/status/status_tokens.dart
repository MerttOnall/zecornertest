import 'package:flutter/material.dart';

enum AppStatusKind {
  loading,
  success,
  error,
  notFound,
  missing,
}

class StatusTokens {
  StatusTokens._();

  static const Color red = Color(0xFFEE2E24);
  static const Color redDark = Color(0xFFD42018);
  static const Color ink = Color(0xFF1A1D23);
  static const Color muted = Color(0xFF8B909A);
  static const Color background = Color(0xFFF7F8FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE6E8EE);

  static const String loadingLabel = 'LÜTFEN BEKLEYİN';
  static const String loadingTitle = 'Sayfanız hazırlanıyor.';
  static const String loadingMessage =
      'İçerik yüklenirken lütfen bekleyin. Bu işlem birkaç saniye sürebilir.';

  static const String successLabel = 'ONAYLANDI';
  static const String successTitle = 'İşleminiz başarıyla tamamlandı.';
  static const String successMessage =
      'Talebiniz alındı ve başarıyla kaydedildi.';

  static const String errorCode = 'HATA';
  static const String errorTitle = 'Bu sayfada bir şeyler ters gitti.';
  static const String errorMessage =
      'İşleminiz şu anda tamamlanamıyor. Lütfen tekrar deneyin veya ana sayfaya dönün.';

  static const String notFoundCode = '';
  static const String notFoundTitle = 'Sayfa bulunamadı';
  static const String notFoundMessage =
      'Bu sayfa mevcut değil veya taşınmış olabilir. Ana sayfaya dönebilirsiniz.';

  static const String missingCode = '';
  static const String missingTitle = 'Veri yok';
  static const String missingMessage =
      'Gösterilecek kayıt bulunamadı.';
}
