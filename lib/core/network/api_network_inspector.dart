import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'http_network_debug_interceptor.dart';
import 'http_network_debug_screen.dart';
import 'http_network_debug_store.dart';
import '../../router/app_navigator.dart';

/// Debug build'de mobil API isteklerini kaydeder ve gösterir.
class ApiNetworkInspector {
  ApiNetworkInspector._();

  static bool get isEnabled => kDebugMode;

  static void configure() {}

  static void attachToDio(Dio dio) {
    if (!isEnabled) return;
    final hasInterceptor =
        dio.interceptors.any((i) => i is HttpNetworkDebugInterceptor);
    if (hasInterceptor) return;
    dio.interceptors.add(HttpNetworkDebugInterceptor());
  }

  static void openScreen({String? recordId}) {
    final context = appNavigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HttpNetworkDebugScreen(initialRecordId: recordId),
      ),
    );
  }

  /// İstek tamamlanınca üstte kısa bildirim gösterir (Chucker benzeri).
  static void showRequestToast(HttpNetworkRecord record) {
    final context = appNavigatorKey.currentContext;
    if (context == null || !isEnabled) return;

    final code = record.statusCode ?? 0;
    final color = code >= 400
        ? Colors.red.shade700
        : code >= 300
            ? Colors.orange.shade800
            : Colors.green.shade700;

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        content: Text(
          '${record.method} ${record.shortPath} → $code',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Detay',
          textColor: Colors.white,
          onPressed: () => openScreen(recordId: record.id),
        ),
      ),
    );
  }
}

/// Store dinleyicisi: istek bitince toast gösterir.
class ApiNetworkInspectorListener extends StatefulWidget {
  const ApiNetworkInspectorListener({super.key, required this.child});

  final Widget child;

  @override
  State<ApiNetworkInspectorListener> createState() =>
      _ApiNetworkInspectorListenerState();
}

class _ApiNetworkInspectorListenerState
    extends State<ApiNetworkInspectorListener> {
  final _store = HttpNetworkDebugStore.instance;
  final Set<String> _toasted = {};

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!ApiNetworkInspector.isEnabled) return;
    for (final r in _store.records) {
      if (r.statusCode == null || _toasted.contains(r.id)) continue;
      _toasted.add(r.id);
      ApiNetworkInspector.showRequestToast(r);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Sağ altta yüzen API butonu.
class ApiNetworkInspectorButton extends StatelessWidget {
  const ApiNetworkInspectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ApiNetworkInspector.isEnabled) return const SizedBox.shrink();

    return Positioned(
      right: 12,
      bottom: 88,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF1B5E20),
        child: InkWell(
          onTap: () => ApiNetworkInspector.openScreen(),
          borderRadius: BorderRadius.circular(28),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_tethering, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'API',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
