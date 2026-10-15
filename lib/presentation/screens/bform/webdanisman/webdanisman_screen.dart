import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/bform/web_advisor_repository.dart';
import 'package:zecorner/models/bform/web_advisor_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';

const _kRed = Color(0xFFE53935);

/// Telefon uygulamasını açar. Numara boşsa veya cihaz arayamıyorsa uyarır.
Future<void> _callPhone(BuildContext context, String rawPhone) async {
  var digits = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.startsWith('00')) digits = '+${digits.substring(2)}';
  if (digits.replaceAll('+', '').length < 7) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçerli bir telefon numarası yok')),
    );
    return;
  }
  final uri = Uri(scheme: 'tel', path: digits);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arama başlatılamadı')),
    );
  }
}

class WebDanismanScreen extends StatefulWidget {
  const WebDanismanScreen({super.key});

  @override
  State<WebDanismanScreen> createState() => _WebDanismanScreenState();
}

class _WebDanismanScreenState extends State<WebDanismanScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late final WebAdvisorRepository _repository;
  late final Future<List<String>> _rolesFuture;

  final List<WebAdvisorApplication> _items = [];
  List<WebAdvisorLookupItem> _statusTypes = [];
  List<WebAdvisorLookupItem> _contactTypes = [];

  bool _isLoading = false;
  bool _isDrawerOpen = false;
  bool _canManage = false;
  String? _errorMessage;
  int _nextPage = 1;
  int _totalPages = 1;
  int _requestId = 0;
  bool _hasMore = true;
  String? _statusCode;
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _repository = WebAdvisorRepository(dio: Dio());
    _rolesFuture = context.read<AuthCubit>().getUserRoleCodes();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 120 &&
          _hasMore &&
          !_isLoading) {
        _load(loadMore: true);
      }
    });
    _loadAccess();
    _loadLookups();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? [];
    final permissions = (prefs.getString('userPermissions') ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final isAdmin = prefs.getBool('userIsAdmin') == true;
    if (!mounted) return;
    setState(() {
      _canManage = RoleSidebar.allows(
        const ['admin_only', 'role_office_broker', 'form.web_advisor.manage'],
        isAdmin: isAdmin,
        roleCodes: roles,
        permissions: permissions,
      );
    });
  }

  Future<void> _loadLookups() async {
    final result = await _repository.fetchLookups();
    if (!mounted) return;
    result.fold((_) {}, (lookups) {
      setState(() {
        _statusTypes = lookups.statusTypes;
        _contactTypes = lookups.contactTypes;
      });
    });
  }

  Future<void> _load({bool loadMore = false}) async {
    if (loadMore && (_isLoading || !_hasMore || _nextPage > _totalPages)) {
      if (loadMore && !_hasMore) setState(() => _hasMore = false);
      return;
    }
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      if (!loadMore) _errorMessage = null;
    });
    final page = loadMore ? _nextPage : 1;
    final result = await _repository.fetchList(
      page: page,
      searchText: _searchController.text,
      currentStatus: _statusCode,
      startDate: _startDate,
      endDate: _endDate,
    );
    if (!mounted || requestId != _requestId) return;
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
          if (!loadMore) _items.clear();
        });
      },
      (response) {
        setState(() {
          _isLoading = false;
          if (!loadMore) _items.clear();
          final known = _items.map((e) => e.id).toSet();
          _items.addAll(
            response.applications.where((e) => known.add(e.id)),
          );
          _totalPages = response.totalPages;
          _nextPage = response.page + 1;
          _hasMore = response.page < response.totalPages &&
              response.applications.isNotEmpty;
        });
        _fillIfFiltered();
      },
    );
  }

  /// Sunucu bir filtreyi yok sayarsa sayfa boş kalmasın: filtre açıkken
  /// görünen kart azsa ve devamı varsa sonraki sayfayı çek.
  void _fillIfFiltered() {
    if (!_hasActiveFilters || !_hasMore || _isLoading) return;
    if (_visibleItems.length >= 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(loadMore: true);
    });
  }

  void _reload() {
    _searchDebounce?.cancel();
    _nextPage = 1;
    _hasMore = true;
    _load();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // yerel süzgeç anında uygulansın
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      (_statusCode != null && _statusCode!.isNotEmpty) ||
      _startDate != null ||
      _endDate != null;

  /// Sunucu süzgecinin üstüne yerel süzgeç: listede yalnızca seçilen
  /// durum, arama metni ve tarih aralığına uyan kartlar kalır.
  List<WebAdvisorApplication> get _visibleItems {
    if (!_hasActiveFilters) return _items;
    final query = _normalize(_searchController.text);
    final status = _statusCode;
    final start = _startDate == null
        ? null
        : DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = _endDate == null
        ? null
        : DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);

    return _items.where((item) {
      if (status != null && status.isNotEmpty) {
        if ((item.currentStatus ?? '').toLowerCase() != status.toLowerCase()) {
          return false;
        }
      }
      if (start != null || end != null) {
        final created = item.createdAt?.toLocal();
        if (created == null) return false;
        if (start != null && created.isBefore(start)) return false;
        if (end != null && created.isAfter(end)) return false;
      }
      if (query.isNotEmpty) {
        final haystack = _normalize([
          item.fullName,
          item.email,
          item.tel,
          item.tel.replaceAll(RegExp(r'\D'), ''),
          item.officeTitle ?? '',
          item.cityName ?? '',
          item.professionDescription ?? '',
        ].join(' '));
        final digits = query.replaceAll(RegExp(r'\D'), '');
        final matchesText = haystack.contains(query);
        final matchesPhone = digits.length >= 3 && haystack.contains(digits);
        if (!matchesText && !matchesPhone) return false;
      }
      return true;
    }).toList();
  }

  String _normalize(String value) {
    const from = 'İIıŞşĞğÜüÖöÇç';
    const to = 'iiissgguuoocc';
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final ch = String.fromCharCode(rune);
      final index = from.indexOf(ch);
      buffer.write(index >= 0 ? to[index] : ch.toLowerCase());
    }
    return buffer.toString().trim();
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('tr'),
    );
    if (range == null || !mounted) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    _reload();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _startDate = null;
      _endDate = null;
      _statusCode = null;
      _searchController.clear();
    });
    _reload();
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _reload();
  }

  Future<void> _openDetail(WebAdvisorApplication item) async {
    var changed = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WebAdvisorDetailSheet(
        repository: _repository,
        application: item,
        statusTypes: _statusTypes,
        contactTypes: _contactTypes,
        canManage: _canManage,
        onChanged: () => changed = true,
      ),
    );
    if (changed) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const RoleSidebar(currentPage: 'Web Danışman Başvuruları'),
      onDrawerChanged: (opened) => setState(() => _isDrawerOpen = opened),
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: 'Web Danışman Başvuruları',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) _scaffoldKey.currentState?.closeDrawer();
          FocusScope.of(context).unfocus();
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: Column(
            children: [
              _buildFilters(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: FutureBuilder<List<String>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          final roles = snapshot.data ?? const <String>[];
          if (roles.contains('role_office_broker') ||
              roles.contains('role_office_assistant')) {
            return const BrokerNavbar(currentIndex: 0);
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildFilters() {
    final rangeLabel = _startDate == null
        ? 'Tarih aralığı'
        : '${_fmt(_startDate)} - ${_fmt(_endDate)}';
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _fieldShell(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Ad, telefon veya e-posta',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _redButton('Temizle', _clearFilters),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _fieldShell(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _statusTypes.any((s) => s.code == _statusCode)
                          ? _statusCode
                          : null,
                      hint: const Text('Tüm durumlar'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tüm durumlar'),
                        ),
                        ..._statusTypes.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item.code,
                            child: Text(item.description),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == _statusCode) return;
                        setState(() => _statusCode = value);
                        _reload();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _pickRange,
                  borderRadius: BorderRadius.circular(12),
                  child: _fieldShell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rangeLabel,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _startDate == null ? Colors.grey[700] : Colors.black87,
                                fontWeight: _startDate == null ? FontWeight.w400 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_startDate != null)
                            GestureDetector(
                              onTap: _clearDateRange,
                              child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.red[400]),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              _redButton('Tekrar dene', _reload),
            ],
          ),
        ),
      );
    }
    final visible = _visibleItems;
    if (visible.isEmpty) {
      if (_isLoading || (_hasActiveFilters && _hasMore)) {
        return const Center(child: CircularProgressIndicator(color: _kRed));
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                _hasActiveFilters
                    ? 'Filtreye uygun başvuru bulunamadı'
                    : 'Başvuru bulunamadı',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              if (_hasActiveFilters) ...[
                const SizedBox(height: 12),
                _redButton('Filtreleri temizle', _clearFilters),
              ],
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _kRed,
      onRefresh: () async {
        _reload();
        while (_isLoading && mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: visible.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: _kRed)),
            );
          }
          final item = visible[index];
          return _ApplicationCard(
            item: item,
            onTap: () => _openDetail(item),
          );
        },
      ),
    );
  }

  Widget _fieldShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _redButton(String label, VoidCallback onTap) {
    return Material(
      color: _kRed,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.item, required this.onTap});

  final WebAdvisorApplication item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.email.isEmpty ? item.tel : item.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _callTile(context)),
                    Expanded(child: _info(Icons.location_city_outlined, 'İl', item.cityName ?? '-')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _info(Icons.work_outline, 'Meslek', item.professionDescription ?? '-')),
                    Expanded(child: _info(Icons.school_outlined, 'Eğitim', item.educationDescription ?? '-')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _info(Icons.apartment_outlined, 'Ofis', item.officeTitle ?? '-')),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            _statusChip(item),
                            const SizedBox(height: 6),
                            Text(
                              _fmt(item.createdAt),
                              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ofis Başvuruları'ndaki "Hemen Ara" kutusuyla aynı görünüm.
  Widget _callTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _callPhone(context, item.tel),
          borderRadius: BorderRadius.circular(14),
          splashColor: _kRed.withValues(alpha: 0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kRed.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kRed.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_rounded, size: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hemen Ara',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _kRed, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.tel.isEmpty ? '-' : item.tel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: _kRed, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _WebAdvisorDetailSheet extends StatefulWidget {
  const _WebAdvisorDetailSheet({
    required this.repository,
    required this.application,
    required this.statusTypes,
    required this.contactTypes,
    required this.canManage,
    required this.onChanged,
  });

  final WebAdvisorRepository repository;
  final WebAdvisorApplication application;
  final List<WebAdvisorLookupItem> statusTypes;
  final List<WebAdvisorLookupItem> contactTypes;
  final bool canManage;
  final VoidCallback onChanged;

  @override
  State<_WebAdvisorDetailSheet> createState() => _WebAdvisorDetailSheetState();
}

class _WebAdvisorDetailSheetState extends State<_WebAdvisorDetailSheet> {
  late WebAdvisorApplication _item;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _item = widget.application;
    _refresh();
  }

  Future<void> _refresh() async {
    final result = await widget.repository.fetchDetail(_item.id);
    if (!mounted) return;
    result.fold((_) {}, (detail) => setState(() => _item = detail));
  }

  Future<void> _addStatus() async {
    if (widget.statusTypes.isEmpty || widget.contactTypes.isEmpty) {
      _toast('Durum listesi yüklenemedi');
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _StatusFormDialog(
        repository: widget.repository,
        applicationId: _item.id,
        statusTypes: widget.statusTypes,
        contactTypes: widget.contactTypes,
      ),
    );
    if (saved == true) {
      widget.onChanged();
      await _refresh();
    }
  }

  Future<void> _deleteStatus(WebAdvisorStatus status) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum kaydını sil'),
        content: Text('${status.statusLabel} kaydı silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final result = await widget.repository.deleteStatus(id: _item.id, statusId: status.id);
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _busy = false);
        _toast(failure.message);
      },
      (detail) {
        widget.onChanged();
        setState(() {
          _busy = false;
          _item = detail;
        });
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<WebAdvisorStatus> get _history {
    final list = List<WebAdvisorStatus>.from(_item.statuses);
    list.sort((a, b) {
      final left = a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 28),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 20 + bottom),
              children: [
                _header(),
                const SizedBox(height: 14),
                _infoCard(),
                const SizedBox(height: 18),
                _historyHeader(),
                const SizedBox(height: 10),
                if (_history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Henüz durum kaydı yok',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ..._history.map(_statusTile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    final color = _tone(_item.currentStatus);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 16),
      decoration: BoxDecoration(
        color: _kRed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _initials(_item.fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _item.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _item.officeTitle ?? 'Ofis belirtilmedi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _item.statusLabel,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _infoLine(Icons.mail_outline, 'E-posta', _item.email),
          _infoLine(
            Icons.phone_outlined,
            'Telefon',
            _item.tel,
            trailing: Material(
              color: _kRed,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _callPhone(context, _item.tel),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Ara',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _infoLine(Icons.apartment_outlined, 'Ofis', _item.officeTitle ?? '-'),
          Row(
            children: [
              Expanded(child: _infoLine(Icons.cake_outlined, 'Doğum', _fmt(_item.birthday))),
              Expanded(child: _infoLine(Icons.person_outline, 'Cinsiyet', _item.sexLabel)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _infoLine(Icons.work_outline, 'Meslek', _item.professionDescription ?? '-')),
              Expanded(child: _infoLine(Icons.school_outlined, 'Eğitim', _item.educationDescription ?? '-')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _infoLine(Icons.location_city_outlined, 'İl', _item.cityName ?? '-')),
              Expanded(child: _infoLine(Icons.event_outlined, 'Başvuru', _fmt(_item.createdAt))),
            ],
          ),
          if ((_item.utmSource ?? '').isNotEmpty)
            _infoLine(Icons.campaign_outlined, 'Kaynak', _item.utmSource!),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _kRed),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _historyHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Durum geçmişi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.canManage)
          Material(
            color: _kRed,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _busy ? null : _addStatus,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Durum ekle',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusTile(WebAdvisorStatus status) {
    final color = _tone(status.statusType);
    final person = status.createdByTitle?.trim() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.statusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const Spacer(),
              if (widget.canManage)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: _busy ? null : () => _deleteStatus(status),
                  icon: Icon(Icons.delete_outline, color: Colors.grey[500]),
                ),
            ],
          ),
          Text(status.contactLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
          if ((status.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status.description!),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            person.isEmpty
                ? _fmt(status.date ?? status.createdAt)
                : '${_fmt(status.date ?? status.createdAt)}  ·  $person',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Color _tone(String? code) {
  switch (code) {
    case 'approved':
      return const Color(0xFF15803D);
    case 'rejected':
      return const Color(0xFFDC2626);
    case 'called':
      return const Color(0xFF1D4ED8);
    default:
      return _kRed;
  }
}

String _initials(String name) {
  final parts = name.split(' ').where((part) => part.trim().isNotEmpty).toList();
  if (parts.isEmpty || parts.first == '-') return '?';
  String letter(String value) => value.substring(0, 1).toUpperCase();
  if (parts.length == 1) return letter(parts.first);
  return '${letter(parts.first)}${letter(parts.last)}';
}

class _StatusFormDialog extends StatefulWidget {
  const _StatusFormDialog({
    required this.repository,
    required this.applicationId,
    required this.statusTypes,
    required this.contactTypes,
  });

  final WebAdvisorRepository repository;
  final int applicationId;
  final List<WebAdvisorLookupItem> statusTypes;
  final List<WebAdvisorLookupItem> contactTypes;

  @override
  State<_StatusFormDialog> createState() => _StatusFormDialogState();
}

class _StatusFormDialogState extends State<_StatusFormDialog> {
  late String _status;
  late String _contact;
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.statusTypes.first.code;
    _contact = widget.contactTypes.first.code;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.repository.createStatus(
      id: widget.applicationId,
      statusType: _status,
      contactType: _contact,
      description: _note.text,
      date: _date,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) => Navigator.pop(context, true),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Durum ekle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _boxedField(
                label: 'Durum',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _status,
                    items: widget.statusTypes
                        .map((e) => DropdownMenuItem(value: e.code, child: Text(e.description)))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _status = value ?? _status),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _boxedField(
                label: 'Görüşme şekli',
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _contact,
                    items: widget.contactTypes
                        .map((e) => DropdownMenuItem(value: e.code, child: Text(e.description)))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _contact = value ?? _contact),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Not', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Görüşme notu',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF6F7F9),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tarih', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Material(
                color: const Color(0xFFF6F7F9),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _saving ? null : _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: _kRed),
                        const SizedBox(width: 10),
                        Text(_fmt(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: _kRed, fontSize: 13)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kRed.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boxedField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ],
    );
  }
}

Widget _statusChip(WebAdvisorApplication item) {
  return _statusChipLabel(item.statusLabel);
}

Widget _statusChipLabel(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _kRed.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: const TextStyle(color: _kRed, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

String _fmt(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}
