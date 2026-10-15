import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'http_network_debug_store.dart';

class HttpNetworkDebugScreen extends StatefulWidget {
  const HttpNetworkDebugScreen({super.key, this.initialRecordId});

  final String? initialRecordId;

  @override
  State<HttpNetworkDebugScreen> createState() => _HttpNetworkDebugScreenState();
}

class _HttpNetworkDebugScreenState extends State<HttpNetworkDebugScreen> {
  final _store = HttpNetworkDebugStore.instance;
  HttpNetworkRecord? _selected;
  int _tabIndex = 2;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _selectInitial();
  }

  void _selectInitial() {
    final records = _store.records;
    if (records.isEmpty) return;
    if (widget.initialRecordId != null) {
      _selected = records.cast<HttpNetworkRecord?>().firstWhere(
            (r) => r!.id == widget.initialRecordId,
            orElse: () => records.first,
          );
    } else {
      _selected = records.first;
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final records = _store.records;
    final selected = _selected ?? (records.isNotEmpty ? records.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF252526),
        foregroundColor: Colors.white,
        title: const Text('API İstekleri'),
        actions: [
          IconButton(
            tooltip: 'Temizle',
            onPressed: () {
              _store.clear();
              setState(() => _selected = null);
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'Henüz istek yok.\nKaydet veya bir API çağrısı yap.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final isSelected = selected?.id == r.id;
                      return Material(
                        color: isSelected
                            ? const Color(0xFF094771)
                            : (index.isEven
                                ? const Color(0xFF2D2D30)
                                : const Color(0xFF252526)),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selected = r;
                            _tabIndex = 2;
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _MethodBadge(method: r.method),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    r.shortPath,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusBadge(record: r),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF3C3C3C)),
                if (selected != null)
                  Expanded(
                    flex: 3,
                    child: _DetailPanel(
                      record: selected,
                      tabIndex: _tabIndex,
                      onTabChanged: (i) => setState(() => _tabIndex = i),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    Color c = Colors.blueGrey;
    if (method == 'GET') c = Colors.green;
    if (method == 'POST') c = Colors.orange;
    if (method == 'PUT' || method == 'PATCH') c = Colors.amber;
    if (method == 'DELETE') c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.record});

  final HttpNetworkRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.statusCode == null) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final code = record.statusCode!;
    Color c = Colors.greenAccent;
    if (code >= 400) c = Colors.redAccent;
    else if (code >= 300) c = Colors.amberAccent;

    return Text(
      '$code',
      style: TextStyle(
        color: c,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.record,
    required this.tabIndex,
    required this.onTabChanged,
  });

  final HttpNetworkRecord record;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Headers', 'Request', 'Response'];
    String content;
    switch (tabIndex) {
      case 0:
        content = _prettyJson(record.requestHeaders);
        break;
      case 1:
        content = _prettyJson(record.requestBody);
        break;
      default:
        if (record.errorMessage != null) {
          content =
              'ERROR: ${record.errorMessage}\n\n${_prettyJson(record.responseBody)}';
        } else {
          content = _prettyJson(record.responseBody);
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            record.url,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(tabs.length, (i) {
            final selected = tabIndex == i;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      selected ? const Color(0xFF094771) : Colors.transparent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => onTabChanged(i),
                child: Text(tabs[i]),
              ),
            );
          }),
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: FloatingActionButton.small(
                  heroTag: 'copy_network',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Panoya kopyalandı')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _prettyJson(dynamic data) {
    if (data == null) return '(null)';
    if (data is String) {
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(data));
      } catch (_) {
        return data;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
