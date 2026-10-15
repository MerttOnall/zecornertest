import 'package:flutter/foundation.dart';

class HttpNetworkRecord {
  final String id;
  final String method;
  final String url;
  final DateTime startedAt;
  final Map<String, dynamic> requestHeaders;
  final dynamic requestBody;
  int? statusCode;
  dynamic responseBody;
  String? errorMessage;
  Duration? duration;

  HttpNetworkRecord({
    required this.id,
    required this.method,
    required this.url,
    required this.startedAt,
    required this.requestHeaders,
    required this.requestBody,
  });

  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  bool get isError =>
      errorMessage != null || (statusCode != null && statusCode! >= 400);

  String get shortPath {
    final u = Uri.tryParse(url);
    if (u == null) return url;
    final path = u.path;
    return path.isNotEmpty ? path : url;
  }
}

class HttpNetworkDebugStore extends ChangeNotifier {
  HttpNetworkDebugStore._();

  static final HttpNetworkDebugStore instance = HttpNetworkDebugStore._();

  final List<HttpNetworkRecord> _records = [];
  int _counter = 0;

  List<HttpNetworkRecord> get records => List.unmodifiable(_records);

  HttpNetworkRecord start({
    required String method,
    required String url,
    required Map<String, dynamic> headers,
    required dynamic body,
  }) {
    final record = HttpNetworkRecord(
      id: '${++_counter}',
      method: method.toUpperCase(),
      url: url,
      startedAt: DateTime.now(),
      requestHeaders: Map<String, dynamic>.from(headers),
      requestBody: body,
    );
    _records.insert(0, record);
    if (_records.length > 200) {
      _records.removeRange(200, _records.length);
    }
    notifyListeners();
    return record;
  }

  void complete(HttpNetworkRecord record, {int? statusCode, dynamic body}) {
    record.statusCode = statusCode;
    record.responseBody = body;
    record.duration = DateTime.now().difference(record.startedAt);
    notifyListeners();
  }

  void fail(
    HttpNetworkRecord record, {
    int? statusCode,
    dynamic body,
    String? error,
  }) {
    record.statusCode = statusCode;
    record.responseBody = body;
    record.errorMessage = error;
    record.duration = DateTime.now().difference(record.startedAt);
    notifyListeners();
  }

  void clear() {
    _records.clear();
    notifyListeners();
  }
}
