import 'package:zecorner/core/network/network_info.dart';

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Basit network kontrolü - her zaman true döndür
    // Gerçek uygulamada connectivity_plus paketi kullanılabilir
    return true;
  }
}
