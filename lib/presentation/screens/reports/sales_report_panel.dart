import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/auth/advisor_office_scope.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/contact/contacts_api_repository.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/infrastructure/sales/sales_repository.dart';
import 'package:zecorner/models/contact/contacts_api_model.dart';
import 'package:zecorner/models/dashboard/admin /admin_sales_model.dart';
import 'package:zecorner/models/office/office_api_model.dart';
import 'package:zecorner/presentation/screens/reports/report_empty_state.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

/// Satış raporunun kim neyi gördüğü.
/// [all]: admin ve bölge unvanları — tüm ofisler, ofis + kullanıcı filtresi.
/// [office]: broker — yalnız kendi ofisi, kullanıcı filtresi açık.
/// [self]: danışman — yalnız kendi işlemleri, ofis/kullanıcı filtresi yok.
enum SalesReportScope { all, office, self }

class SalesReportPanel extends StatefulWidget {
  final SalesReportScope scope;

  const SalesReportPanel({super.key, this.scope = SalesReportScope.all});

  @override
  State<SalesReportPanel> createState() => _SalesReportPanelState();
}

class _SalesReportPanelState extends State<SalesReportPanel> {
  final TextEditingController _searchController = TextEditingController();
  final OfficeApiRepository _officeRepository = OfficeApiRepository();
  final ContactsApiRepository _contactsRepository = ContactsApiRepository();
  final SalesRepository _salesRepository = SalesRepository();

  AdminSalesModel? _salesData;
  List<OfficeApiModel> _offices = [];
  List<ContactsApiModel> _users = [];
  OfficeApiModel? _selectedOffice;
  ContactsApiModel? _selectedUser;

  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _errorMessage;
  /// Eski / geç gelen satış yanıtlarını yok saymak için
  int _salesRequestId = 0;

  String _selectedSort = 'Hepsi';
  String _selectedStatus = 'Hepsi';
  DateTime? _startDate;
  DateTime? _endDate;
  AdvisorOfficeScope _officeScope = AdvisorOfficeScope.unrestricted;
  int _selfAdvisorId = 0;
  String _selfName = '';

  static const List<String> _sortOptions = [
    'Hepsi',
    'A-Z',
    'Z-A',
    'En Yüksek Kazanç',
    'En Düşük Kazanç',
  ];

  static const List<String> _statusOptions = ['Hepsi', 'Satıldı', 'Kiralandı'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = now;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _officeScope = await AdvisorOfficeScope.load();
    if (widget.scope == SalesReportScope.self) {
      final prefs = await SharedPreferences.getInstance();
      _selfAdvisorId = prefs.getInt('advisorId') ?? 0;
      _selfName = [
        prefs.getString('userName') ?? '',
        prefs.getString('userSurname') ?? '',
      ].join(' ').trim();
      await _loadSalesData();
      return;
    }
    if (widget.scope == SalesReportScope.office) {
      await _loadBrokerUsers();
      await _loadSalesData();
      return;
    }
    await Future.wait([_loadOffices(), _loadUsers(), _loadSalesData()]);
  }

  Future<void> _loadOffices() async {
    final result = await _officeRepository.getOffices(
      page: 1,
      limit: 200,
      status: 'Tümü',
    );
    result.fold((_) {}, (response) {
      if (mounted) setState(() => _offices = response.offices);
    });
  }

  /// Ofis kullanıcıları: API `connected_contact_title` / `connected_contact`
  /// ile ofise bağlar (ör. title "Zecorner Cadde", type 101).
  List<ContactsApiModel> _normalizeOfficeUsers(
    List<ContactsApiModel> raw, {
    int? officeId,
    String? officeTitle,
  }) {
    Iterable<ContactsApiModel> list = raw;
    final titleNorm = officeTitle?.trim().toLowerCase();
    final hasOfficeFilter =
        officeId != null || (titleNorm != null && titleNorm.isNotEmpty);

    if (hasOfficeFilter) {
      list = list.where((c) {
        // Web/API: people ofise connected_contact + connected_contact_title
        // ile bağlı (ör. "Zecorner Cadde", type 101)
        final byId =
            officeId != null && c.connectedContact == officeId;
        final byTitle = titleNorm != null &&
            titleNorm.isNotEmpty &&
            _norm(c.connectedContactTitle) == titleNorm;
        return byId || byTitle;
      });
    }

    // Ofis/şirket kartlarını kullanıcı listesine alma
    list = list.where((c) {
      if (c.title.trim().isEmpty) return false;
      if (c.isCompany) return false;
      // 100/101/102 = merkez/ofis/broker ofis tipleri
      if (c.type == 100 || c.type == 101 || c.type == 102) return false;
      return true;
    });

    // Aynı contact_no tekrarlarını tekilleştir
    final seen = <int>{};
    final unique = <ContactsApiModel>[];
    for (final c in list) {
      if (seen.add(c.contactNo)) unique.add(c);
    }
    unique.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return unique;
  }

  Future<List<ContactsApiModel>> _fetchUsersForOffice(
    OfficeApiModel? office,
  ) async {
    final officeId = office?.contactNo;
    final officeTitle = office?.title;
    final officeType = office?.type;

    Future<List<ContactsApiModel>> fetchRaw({int? officeParam}) async {
      final result = await _contactsRepository.getContacts(
        page: 1,
        limit: 9999,
        office: officeParam,
        useGetContacts: true,
      );
      return result.fold(
        (failure) {
          print('❌ Ofis kullanıcıları alınamadı: ${failure.message}');
          return <ContactsApiModel>[];
        },
        (response) => response.contacts,
      );
    }

    List<ContactsApiModel> normalize(List<ContactsApiModel> raw) =>
        _normalizeOfficeUsers(
          raw,
          officeId: officeId,
          officeTitle: officeTitle,
        );

    var raw = await fetchRaw(officeParam: officeId);
    var people = normalize(raw);

    // office= boş / yanlış id dönerse: tüm liste + title/id süz
    if (people.isEmpty && office != null) {
      print(
        '⚠️ Ofis="${officeTitle}" (#$officeId) filtreli liste boş; '
        'tüm contacts + connected_contact_title süzülecek',
      );
      raw = await fetchRaw(officeParam: null);
      people = normalize(raw);
    }

    print(
      '✅ Ofis kullanıcıları: "$officeTitle" (#$officeId, type=$officeType) → '
      '${raw.length} ham / ${people.length} filtreli',
    );
    return people;
  }

  /// Broker kullanıcı listesi yalnız kendi ofisine iner.
  Future<void> _loadBrokerUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);

    final officeId = _officeScope.officeId > 0 ? _officeScope.officeId : null;
    final officeTitle = _officeScope.officeTitle;

    Future<List<ContactsApiModel>> fetchRaw({int? officeParam}) async {
      final result = await _contactsRepository.getContacts(
        page: 1,
        limit: 9999,
        office: officeParam,
        useGetContacts: true,
      );
      return result.fold(
        (_) => <ContactsApiModel>[],
        (response) => response.contacts,
      );
    }

    var raw = await fetchRaw(officeParam: officeId);
    var people = _normalizeOfficeUsers(
      raw,
      officeId: officeId,
      officeTitle: officeTitle,
    );
    if (people.isEmpty &&
        (officeId != null || officeTitle.trim().isNotEmpty)) {
      raw = await fetchRaw();
      people = _normalizeOfficeUsers(
        raw,
        officeId: officeId,
        officeTitle: officeTitle,
      );
    }

    if (!mounted) return;
    setState(() {
      _users = people;
      _isLoadingUsers = false;
      if (_selectedUser != null &&
          !_users.any((u) => u.contactNo == _selectedUser!.contactNo)) {
        _selectedUser = null;
      }
    });
  }

  /// Ofis seçiliyse web ile aynı: `get-contacts/?office=…&pageSize=9999`
  Future<void> _loadUsers({OfficeApiModel? office}) async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);

    final selected = office ?? _selectedOffice;
    final people = await _fetchUsersForOffice(selected);

    if (!mounted) return;
    setState(() {
      _users = people;
      _isLoadingUsers = false;
      if (_selectedUser != null &&
          !_users.any((u) => u.contactNo == _selectedUser!.contactNo)) {
        _selectedUser = null;
      }
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  String _norm(String? value) => (value ?? '').trim().toLowerCase();

  bool _saleMatchesSearch(SaleModel sale, String query) {
    final status = switch (sale.state.toUpperCase()) {
      'RENTED' => 'Kiralandı',
      'SOLD' => 'Satıldı',
      _ => sale.state,
    };
    final haystack = reportFold([
      sale.customerTitle,
      sale.advisorTitle,
      sale.officeTitle,
      sale.listingTitle,
      status,
      sale.totalComission,
      sale.buyerComission ?? '',
      sale.sellerCommission,
      sale.closingPrice ?? '',
      sale.date,
    ].join(' '));
    return haystack.contains(query);
  }

  Future<void> _loadSalesData() async {
    if (!mounted) return;
    final requestId = ++_salesRequestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final startDate = _startDate ?? DateTime(DateTime.now().year, 1, 1);
      final endDate = _endDate ?? DateTime.now();

      String? status;
      if (_selectedStatus == 'Kiralandı') {
        status = 'RENTED';
      } else if (_selectedStatus == 'Satıldı') {
        status = 'SOLD';
      }

      final officeId = widget.scope == SalesReportScope.office
          ? (_officeScope.officeId > 0 ? _officeScope.officeId : null)
          : _selectedOffice?.contactNo;
      final selfContact = _officeScope.userContactNo > 0
          ? _officeScope.userContactNo
          : null;
      final userId = widget.scope == SalesReportScope.self
          ? selfContact
          : _selectedUser?.contactNo;
      final roleCode = switch (widget.scope) {
        SalesReportScope.office => 'role_office_broker',
        SalesReportScope.self => 'role_advisor',
        SalesReportScope.all => 'role_admin',
      };
      final data = await _salesRepository.getAllSales(
        roleCode: roleCode,
        roleEndpointOnly: widget.scope != SalesReportScope.all,
        params: SalesQueryParams(
          pageSize: 9999,
          startDate: startDate,
          endDate: endDate,
          status: status,
          officeContactNo: officeId,
          userContactNo: userId,
        ),
      );

      if (!mounted || requestId != _salesRequestId) return;
      setState(() {
        _salesData = data;
        _isLoading = false;
      });
    } on Failure catch (e) {
      if (!mounted || requestId != _salesRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _salesData = null;
      });
    } catch (e) {
      if (!mounted || requestId != _salesRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _salesData = null;
      });
    }
  }

  /// API + istemci süzmesi: tablo her zaman seçili ofis/kullanıcı ile uyumlu.
  List<SaleModel> get _displaySales {
    var sales = List<SaleModel>.from(_salesData?.sales ?? []);

    if (widget.scope == SalesReportScope.office) {
      sales = sales.where(_belongsToBrokerOffice).toList();
    } else if (widget.scope == SalesReportScope.self) {
      sales = sales.where(_isOwnSale).toList();
    }

    final office = _selectedOffice;
    if (office != null) {
      final officeTitle = _norm(office.title);
      sales = sales.where((s) {
        final byId = s.office == office.contactNo;
        final byTitle =
            officeTitle.isNotEmpty && _norm(s.officeTitle) == officeTitle;
        return byId || byTitle;
      }).toList();
    }

    final user = _selectedUser;
    if (user != null) {
      final userTitle = _norm(user.title);
      sales = sales.where((s) {
        final byId = s.advisor == user.contactNo;
        final byTitle =
            userTitle.isNotEmpty && _norm(s.advisorTitle) == userTitle;
        return byId || byTitle;
      }).toList();
    }

    if (_selectedStatus == 'Kiralandı') {
      sales = sales.where((s) => s.state.toUpperCase() == 'RENTED').toList();
    } else if (_selectedStatus == 'Satıldı') {
      sales = sales.where((s) => s.state.toUpperCase() == 'SOLD').toList();
    }

    final query = reportFold(_searchController.text.trim());
    if (query.isNotEmpty) {
      sales = sales.where((sale) => _saleMatchesSearch(sale, query)).toList();
    }

    switch (_selectedSort) {
      case 'A-Z':
        sales.sort((a, b) => a.customerTitle.compareTo(b.customerTitle));
        break;
      case 'Z-A':
        sales.sort((a, b) => b.customerTitle.compareTo(a.customerTitle));
        break;
      case 'En Yüksek Kazanç':
        sales.sort((a, b) {
          final aVal = double.tryParse(a.totalComission) ?? 0;
          final bVal = double.tryParse(b.totalComission) ?? 0;
          return bVal.compareTo(aVal);
        });
        break;
      case 'En Düşük Kazanç':
        sales.sort((a, b) {
          final aVal = double.tryParse(a.totalComission) ?? 0;
          final bVal = double.tryParse(b.totalComission) ?? 0;
          return aVal.compareTo(bVal);
        });
        break;
    }
    return sales;
  }

  /// Broker yalnız kendi ofisinin satışını görür.
  /// Ofis alanı boş kayıt durur; başka ofis düşer. Ofis kimliği yoksa liste boş kalır.
  bool _belongsToBrokerOffice(SaleModel sale) {
    final hasOwnOffice = _officeScope.officeId > 0 ||
        _officeScope.officeTitle.trim().isNotEmpty;
    if (!hasOwnOffice) return false;
    final hasId = sale.office > 0;
    final hasTitle = sale.officeTitle.trim().isNotEmpty;
    if (_officeScope.officeId > 0 && hasId && sale.office == _officeScope.officeId) {
      return true;
    }
    if (hasTitle && _officeScope.matchesTitle(sale.officeTitle)) return true;
    return !hasId && !hasTitle;
  }

  bool get _canIdentifySelf =>
      _officeScope.userContactNo > 0 ||
      _selfAdvisorId > 0 ||
      _selfName.trim().isNotEmpty;

  /// Danışman yalnız kendi işlemini görür. Kimliği yoksa liste boş kalır.
  bool _isOwnSale(SaleModel sale) {
    if (!_canIdentifySelf) return false;
    if (_officeScope.userContactNo > 0 &&
        sale.advisor == _officeScope.userContactNo) {
      return true;
    }
    if (_selfAdvisorId > 0 && sale.advisor == _selfAdvisorId) return true;
    final mine = reportFold(_selfName);
    final theirs = reportFold(sale.advisorTitle);
    if (mine.isNotEmpty && theirs.isNotEmpty && mine == theirs) return true;
    return sale.advisor <= 0 && sale.advisorTitle.trim().isEmpty;
  }

  String get _dateText {
    if (_startDate == null || _endDate == null) return 'Tarih aralığı seçin';
    return '${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedSort != 'Hepsi') count++;
    if (_selectedStatus != 'Hepsi') count++;
    if (_selectedOffice != null) count++;
    if (_selectedUser != null) count++;
    return count;
  }

  double get _displayedNetTotal => _displaySales.fold<double>(
        0,
        (sum, sale) => sum + (double.tryParse(sale.totalComission) ?? 0),
      );

  /// Özetler tablodaki (filtrelenmiş) satırlarla aynı kaynaktan.
  String get _totalNetGain => formatReportAmount(_displayedNetTotal);

  String get _zecornerReturn =>
      formatReportAmount(_displayedNetTotal * 0.07);

  void _clearFilters() {
    final now = DateTime.now();
    setState(() {
      _selectedSort = 'Hepsi';
      _selectedStatus = 'Hepsi';
      _selectedOffice = null;
      _selectedUser = null;
      _startDate = DateTime(now.year, 1, 1);
      _endDate = now;
      _searchController.clear();
    });
    if (widget.scope == SalesReportScope.office) {
      _loadBrokerUsers();
    } else if (widget.scope == SalesReportScope.all) {
      _loadUsers();
    }
    _loadSalesData();
  }

  void _showFilterSheet() {
    String draftSort = _selectedSort;
    String draftStatus = _selectedStatus;
    OfficeApiModel? draftOffice = _selectedOffice;
    ContactsApiModel? draftUser = _selectedUser;
    DateTime? draftStart = _startDate;
    DateTime? draftEnd = _endDate;
    List<ContactsApiModel> draftUsers = List.of(_users);
    bool draftUsersLoading = _isLoadingUsers;
    bool usersReloadScheduled = false;
    String expandedKey = '';
    String optionSearch = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> loadDraftUsers(
              OfficeApiModel? office, {
              bool clearUser = true,
            }) async {
              setSheetState(() {
                draftUsersLoading = true;
                draftUsers = [];
                if (clearUser) draftUser = null;
              });
              final people = await _fetchUsersForOffice(office);
              if (!sheetContext.mounted) return;
              setSheetState(() {
                draftUsers = people;
                draftUsersLoading = false;
                if (draftUser != null &&
                    !people.any(
                      (u) => u.contactNo == draftUser!.contactNo,
                    )) {
                  draftUser = null;
                }
              });
            }

            // Ofis seçiliyken sheet açılınca kullanıcıları taze çek (tablo ile senkron)
            if (draftOffice != null && !usersReloadScheduled) {
              usersReloadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!sheetContext.mounted) return;
                loadDraftUsers(draftOffice, clearUser: false);
              });
            }

            String officeOptionLabel(OfficeApiModel o) {
              final sameTitle =
                  _offices.where((x) => x.title == o.title).length;
              if (sameTitle > 1) {
                return '${o.title} (#${o.contactNo})';
              }
              return o.title;
            }

            String userOptionLabel(ContactsApiModel u) {
              final sameTitle =
                  draftUsers.where((x) => x.title == u.title).length;
              if (sameTitle > 1) {
                return '${u.title} (#${u.contactNo})';
              }
              return u.title;
            }

            String dateLabel() {
              if (draftStart == null || draftEnd == null) {
                return 'Tarih aralığı seçin';
              }
              return '${DateFormat('dd/MM/yyyy').format(draftStart!)} — ${DateFormat('dd/MM/yyyy').format(draftEnd!)}';
            }

            List<String> filteredOptions(List<String> all) {
              final q = optionSearch.trim().toLowerCase();
              if (q.isEmpty) return all;
              return all.where((e) => e.toLowerCase().contains(q)).toList();
            }

            Widget modernSelect({
              required String keyName,
              required String label,
              required String value,
              required List<String> options,
              required ValueChanged<String> onSelect,
              bool loading = false,
              bool enabled = true,
            }) {
              final isOpen = expandedKey == keyName;
              final visible = filteredOptions(options);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ReportTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 0,
                    child: InkWell(
                      onTap: !enabled || loading
                          ? null
                          : () {
                              setSheetState(() {
                                expandedKey = isOpen ? '' : keyName;
                                optionSearch = '';
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: enabled
                              ? Colors.white
                              : ReportTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOpen
                                ? ReportTheme.primary.withOpacity(0.35)
                                : ReportTheme.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                loading ? 'Yükleniyor...' : value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: enabled
                                      ? ReportTheme.textPrimary
                                      : ReportTheme.textMuted,
                                ),
                              ),
                            ),
                            if (loading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ReportTheme.primary,
                                ),
                              )
                            else
                              Icon(
                                isOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: ReportTheme.textSecondary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isOpen) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: ReportTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                            child: TextField(
                              onChanged: (v) =>
                                  setSheetState(() => optionSearch = v),
                              decoration: InputDecoration(
                                hintText: 'Ara...',
                                hintStyle: const TextStyle(
                                  color: ReportTheme.textMuted,
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: ReportTheme.textMuted,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: ReportTheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: visible.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Sonuç bulunamadı',
                                      style: TextStyle(
                                        color: ReportTheme.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: visible.length,
                                    itemBuilder: (context, index) {
                                      final item = visible[index];
                                      final selected = item == value;
                                      return InkWell(
                                        onTap: () {
                                          onSelect(item);
                                          setSheetState(() {
                                            expandedKey = '';
                                            optionSearch = '';
                                          });
                                        },
                                        child: Container(
                                          color: selected
                                              ? ReportTheme.surface
                                              : Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 13,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: selected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                    color: selected
                                                        ? ReportTheme.primary
                                                        : ReportTheme
                                                            .textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (selected)
                                                const Icon(
                                                  Icons.check_rounded,
                                                  size: 18,
                                                  color: ReportTheme.primary,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }

            final officeItems = [
              'Tüm ofisler',
              ..._offices.map(officeOptionLabel),
            ];
            final userItems = [
              'Tüm kullanıcılar',
              ...draftUsers.map(userOptionLabel),
            ];
            final draftOfficeValue = draftOffice == null
                ? 'Tüm ofisler'
                : officeOptionLabel(draftOffice!);
            final draftUserValue = draftUser == null
                ? 'Tüm kullanıcılar'
                : userOptionLabel(draftUser!);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Filtreler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ReportTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Column(
                        children: [
                          modernSelect(
                            keyName: 'sort',
                            label: 'Gelişmiş Sıralama',
                            value: draftSort,
                            options: _sortOptions,
                            onSelect: (v) =>
                                setSheetState(() => draftSort = v),
                          ),
                          const SizedBox(height: 14),
                          modernSelect(
                            keyName: 'status',
                            label: 'Durum',
                            value: draftStatus,
                            options: _statusOptions,
                            onSelect: (v) =>
                                setSheetState(() => draftStatus = v),
                          ),
                          if (widget.scope == SalesReportScope.all) ...[
                            const SizedBox(height: 14),
                            modernSelect(
                              keyName: 'office',
                              label: 'Ofis',
                              value: draftOfficeValue,
                              options: officeItems,
                              onSelect: (v) async {
                                if (v == 'Tüm ofisler') {
                                  setSheetState(() {
                                    draftOffice = null;
                                    draftUser = null;
                                  });
                                  await loadDraftUsers(null);
                                } else {
                                  final office = _offices.firstWhere(
                                    (o) => officeOptionLabel(o) == v,
                                    orElse: () => _offices.first,
                                  );
                                  setSheetState(() {
                                    draftOffice = office;
                                    draftUser = null;
                                  });
                                  await loadDraftUsers(office);
                                }
                              },
                            ),
                          ],
                          if (widget.scope != SalesReportScope.self) ...[
                            const SizedBox(height: 14),
                            modernSelect(
                              keyName: 'user',
                              label: 'Kullanıcı',
                              value: draftUserValue,
                              options: userItems,
                              loading: draftUsersLoading,
                              onSelect: (v) {
                                setSheetState(() {
                                  if (v == 'Tüm kullanıcılar') {
                                    draftUser = null;
                                  } else {
                                    draftUser = draftUsers.firstWhere(
                                      (u) => userOptionLabel(u) == v,
                                      orElse: () => draftUsers.first,
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tarih',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ReportTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    DatePicker.showDatePicker(
                                      context,
                                      showTitleActions: true,
                                      minTime: DateTime(2020),
                                      maxTime: DateTime.now()
                                          .add(const Duration(days: 365)),
                                      currentTime:
                                          draftStart ?? DateTime.now(),
                                      locale: LocaleType.tr,
                                      onConfirm: (pickedStart) {
                                        DatePicker.showDatePicker(
                                          context,
                                          showTitleActions: true,
                                          minTime: pickedStart,
                                          maxTime: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                          currentTime:
                                              draftEnd ?? pickedStart,
                                          locale: LocaleType.tr,
                                          onConfirm: (pickedEnd) {
                                            setSheetState(() {
                                              draftStart = DateTime(
                                                pickedStart.year,
                                                pickedStart.month,
                                                pickedStart.day,
                                              );
                                              draftEnd = DateTime(
                                                pickedEnd.year,
                                                pickedEnd.month,
                                                pickedEnd.day,
                                                23,
                                                59,
                                                59,
                                              );
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: ReportTheme.border,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            dateLabel(),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: ReportTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          color: ReportTheme.primary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _clearFilters();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ReportTheme.primary,
                              side: const BorderSide(
                                color: ReportTheme.primary,
                                width: 1.4,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Filtreyi Temizle',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Ofis değiştiyse kullanıcı listede yoksa düşür
                              ContactsApiModel? user = draftUser;
                              if (user != null &&
                                  !draftUsers.any(
                                    (u) => u.contactNo == user!.contactNo,
                                  )) {
                                user = null;
                              }
                              setState(() {
                                _selectedSort = draftSort;
                                _selectedStatus = draftStatus;
                                _selectedOffice = draftOffice;
                                _selectedUser = user;
                                _startDate = draftStart;
                                _endDate = draftEnd;
                                _users = List.of(draftUsers);
                              });
                              Navigator.pop(context);
                              _loadSalesData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ReportTheme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Uygula',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = _displaySales;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ReportTheme.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Arayın...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: ReportTheme.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: ReportTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _showFilterSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.tune_rounded,
                              color: ReportTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: ReportTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _SummaryChip(
                      label: 'Toplam Net Kazanç',
                      value: _totalNetGain,
                    ),
                    if (widget.scope == SalesReportScope.all) ...[
                      const SizedBox(width: 10),
                      _SummaryChip(
                        label: "Zecorner'a Getiri",
                        value: _zecornerReturn,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const AppStatusView.loading(
                  title: 'Rapor hazırlanıyor',
                  message: 'Satış kayıtları yüklenirken lütfen bekleyin.',
                )
              : _errorMessage != null
                  ? AppStatusView.error(
                      message: _errorMessage ?? 'Bir hata oluştu',
                      onRetry: _loadSalesData,
                    )
                  : sales.isEmpty
                      ? const ReportEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Satış Bulunamadı',
                          message:
                              'Seçilen kriterlere uygun bir satış kaydı yok.',
                        )
                      : RefreshIndicator(
                          color: ReportTheme.primary,
                          onRefresh: _loadSalesData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: sales.length,
                            itemBuilder: (context, index) {
                              return _SaleCard(sale: sales[index]);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ReportTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ReportTheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final SaleModel sale;

  const _SaleCard({required this.sale});

  bool get _isSold => sale.state == 'SOLD';

  @override
  Widget build(BuildContext context) {
    final buyerCommission = sale.buyerComission?.isNotEmpty == true
        ? formatReportPrice(sale.buyerComission!)
        : '-';
    final closingPrice = sale.closingPrice?.isNotEmpty == true
        ? formatReportPrice(sale.closingPrice!)
        : formatReportPrice(sale.price.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ReportTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: ReportTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: ReportTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.advisorTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ReportTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.customerTitle,
                        style: const TextStyle(
                          color: ReportTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.officeTitle,
                        style: const TextStyle(
                          color: ReportTheme.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isSold ? ReportTheme.soldBg : ReportTheme.rentedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isSold ? 'Satıldı' : 'Kiralandı',
                    style: TextStyle(
                      color:
                          _isSold ? ReportTheme.soldFg : ReportTheme.rentedFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: ReportTheme.border),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    label: 'Alıcı Komisyon',
                    value: buyerCommission,
                  ),
                ),
                Expanded(
                  child: _InfoCell(
                    label: 'Satıcı Komisyon',
                    value: formatReportPrice(sale.sellerCommission),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    label: 'Kapanış Fiyatı',
                    value: closingPrice,
                    valueColor: const Color(0xFF059669),
                  ),
                ),
                Expanded(
                  child: _InfoCell(
                    label: 'Net Kazanç',
                    value: formatReportPrice(sale.totalComission),
                    valueColor: ReportTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: ReportTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  formatReportDate(sale.date),
                  style: const TextStyle(
                    color: ReportTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCell({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReportTheme.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? ReportTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
