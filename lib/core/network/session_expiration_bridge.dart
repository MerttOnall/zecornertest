/// Dio gibi UI dışı katmanların oturum düşürmesi için köprü.
/// [MaterialApp] altında bir widget handler kaydeder.
Future<void> Function()? _sessionExpiredHandler;
bool _notifying = false;

void registerSessionExpiredHandler(Future<void> Function()? handler) {
  _sessionExpiredHandler = handler;
}

Future<void> notifySessionExpired() async {
  if (_notifying) return;
  _notifying = true;
  try {
    await _sessionExpiredHandler?.call();
  } finally {
    _notifying = false;
  }
}
