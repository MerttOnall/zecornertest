import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'http_network_debug_store.dart';

class HttpNetworkDebugInterceptor extends Interceptor {
  static const _extraKey = 'httpNetworkRecordId';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    final record = HttpNetworkDebugStore.instance.start(
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers.map((k, v) => MapEntry(k.toString(), v)),
      body: options.data,
    );
    options.extra[_extraKey] = record.id;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final record = _findRecord(response.requestOptions);
      if (record != null) {
        HttpNetworkDebugStore.instance.complete(
          record,
          statusCode: response.statusCode,
          body: response.data,
        );
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final record = _findRecord(err.requestOptions);
      if (record != null) {
        HttpNetworkDebugStore.instance.fail(
          record,
          statusCode: err.response?.statusCode,
          body: err.response?.data,
          error: err.message,
        );
      }
    }
    handler.next(err);
  }

  HttpNetworkRecord? _findRecord(RequestOptions options) {
    final id = options.extra[_extraKey]?.toString();
    if (id == null) return null;
    for (final r in HttpNetworkDebugStore.instance.records) {
      if (r.id == id) return r;
    }
    return null;
  }
}
