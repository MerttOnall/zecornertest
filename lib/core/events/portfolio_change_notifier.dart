import 'package:flutter/foundation.dart';

/// Portföy/ilan oluşturulduğunda veya güncellendiğinde tetiklenir.
///
/// Liste ekranları (Portföyüm vb.) dinleyip kendini yeniler; böylece
/// "Portföy Ekle" hangi yoldan açılırsa açılsın (FAB, alt bar "+", route)
/// geri dönüşte elle refresh gerekmez.
class PortfolioChangeNotifier {
  PortfolioChangeNotifier._();

  /// Her değişiklikte artar; dinleyiciler değeri değil tetiklenmeyi kullanır.
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void notifyChanged() => version.value++;
}
