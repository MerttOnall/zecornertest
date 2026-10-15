import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/infrastructure/sales/sales_repository.dart';
import 'package:zecorner/infrastructure/users/users_repository.dart';
import 'package:zecorner/models/dashboard/admin /admin_sales_model.dart';
import 'package:zecorner/models/office/office_api_model.dart';
import 'package:zecorner/models/users/users_model.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class _SraporColors {
  static const Color primary = Color(0xFFE53935);
  static const Color primaryLight = Color(0xFFFFEBEE);
  static const Color surface = Color(0xFFF3F4F6);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
}

class SraporScreen extends StatefulWidget {
  const SraporScreen({super.key});

  @override
  State<SraporScreen> createState() => _SraporScreenState();
}

class _SraporScreenState extends State<SraporScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final OfficeApiRepository _officeRepository = OfficeApiRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final SalesRepository _salesRepository = SalesRepository();

  AdminSalesModel? _salesData;
  List<OfficeApiModel> _offices = [];
  List<UserModel> _users = [];
  OfficeApiModel? _selectedOffice;
  UserModel? _selectedUser;

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedSort = 'Hepsi';
  String _selectedStatus = 'Hepsi';
  DateTime? _startDate;
  DateTime? _endDate;
  String _roleCode = 'role_admin';

  static const List<String> _sortOptions = [
    'Hepsi',
    'A-Z',
    'Z-A',
    'En Yüksek Kazanç',
    'En Düşük Kazanç',
  ];

  static const List<String> _statusOptions = ['Hepsi', 'Kiralandı', 'Satıldı'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, 1, 1);
    _endDate = now;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initScreen());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    await _resolveRoleCode();
    await Future.wait([
      _loadOffices(),
      _loadUsers(),
      _loadSalesData(),
    ]);
  }

  Future<void> _resolveRoleCode() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final roleCodes = await authCubit.getUserRoleCodes();
      if (roleCodes.contains('role_advisor')) {
        _roleCode = 'role_advisor';
      } else if (roleCodes.contains('role_office_broker')) {
        _roleCode = 'role_office_broker';
      } else if (roleCodes.contains('role_office_assistant')) {
        _roleCode = 'role_office_assistant';
      } else if (roleCodes.contains('role_accountant')) {
        _roleCode = 'role_accountant';
      } else {
        _roleCode = 'role_admin';
      }
    } catch (_) {
      _roleCode = 'role_admin';
    }
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

  Future<void> _loadUsers() async {
    final result = await _usersRepository.getUsers(page: 1, limit: 200);
    result.fold((_) {}, (response) {
      if (mounted) setState(() => _users = response.users);
    });
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSalesData() async {
    if (!mounted) return;
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

      final data = await _salesRepository.getAllSales(
        roleCode: _roleCode,
        params: SalesQueryParams(
          pageSize: 9999,
          startDate: startDate,
          endDate: endDate,
          status: status,
          officeContactNo: _selectedOffice?.contactNo,
          userContactNo: _selectedUser?.contactNo,
        ),
      );

      if (!mounted) return;
      setState(() {
        _salesData = data;
        _isLoading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _salesData = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _salesData = null;
      });
    }
  }

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

  List<SaleModel> get _displaySales {
    var sales = List<SaleModel>.from(_salesData?.sales ?? []);

    final office = _selectedOffice;
    if (office != null) {
      final officeTitle = reportFold(office.title);
      sales = sales.where((sale) {
        return sale.office == office.contactNo ||
            (officeTitle.isNotEmpty &&
                reportFold(sale.officeTitle) == officeTitle);
      }).toList();
    }

    final user = _selectedUser;
    if (user != null) {
      final userTitle = reportFold(user.title);
      sales = sales.where((sale) {
        return sale.advisor == user.contactNo ||
            (userTitle.isNotEmpty && reportFold(sale.advisorTitle) == userTitle);
      }).toList();
    }

    if (_selectedStatus == 'Kiralandı') {
      sales = sales.where((sale) => sale.state.toUpperCase() == 'RENTED').toList();
    } else if (_selectedStatus == 'Satıldı') {
      sales = sales.where((sale) => sale.state.toUpperCase() == 'SOLD').toList();
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

  String get _dateText {
    if (_startDate == null && _endDate == null) return 'Tarih aralığı seçin';
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM/yyyy').format(_startDate!)} — ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
    return 'Tarih aralığı seçin';
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedSort != 'Hepsi') count++;
    if (_selectedStatus != 'Hepsi') count++;
    if (_selectedOffice != null) count++;
    if (_selectedUser != null) count++;
    return count;
  }

  String _formatPrice(String value) {
    final price = double.tryParse(value) ?? 0;
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(price);
    return '₺$formatted';
  }

  String get _totalNetGain {
    if (_salesData?.totalRevenue.isNotEmpty == true) {
      return _formatPrice(_salesData!.totalRevenue);
    }
    final total = _displaySales.fold<double>(
      0,
      (sum, sale) => sum + (double.tryParse(sale.totalComission) ?? 0),
    );
    return _formatPrice(total.toString());
  }

  String get _zecornerReturn {
    final raw = _salesData?.totalRevenue ?? '0';
    final total = double.tryParse(raw) ?? 0;
    return _formatPrice((total * 0.07).toString());
  }

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
    _loadSalesData();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Filtreler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _SraporColors.textPrimary,
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSheetDropdown(
                            label: 'Gelişmiş Sıralama',
                            value: _selectedSort,
                            items: _sortOptions,
                            onChanged: (v) => setSheetState(() => _selectedSort = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildSheetDropdown(
                            label: 'Durum',
                            value: _selectedStatus,
                            items: _statusOptions,
                            onChanged: (v) => setSheetState(() => _selectedStatus = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildSheetDropdown<String?>(
                            label: 'Ofis',
                            value: _selectedOffice?.title ?? 'Tüm ofisler',
                            items: ['Tüm ofisler', ..._offices.map((o) => o.title)],
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == null || v == 'Tüm ofisler') {
                                  _selectedOffice = null;
                                } else {
                                  _selectedOffice = _offices.firstWhere((o) => o.title == v);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildSheetDropdown<String?>(
                            label: 'Kullanıcı',
                            value: _selectedUser?.title ?? 'Tüm kullanıcılar',
                            items: [
                              'Tüm kullanıcılar',
                              ..._users.map((u) => u.title),
                            ],
                            onChanged: (v) {
                              setSheetState(() {
                                if (v == null || v == 'Tüm kullanıcılar') {
                                  _selectedUser = null;
                                } else {
                                  _selectedUser = _users.firstWhere((u) => u.title == v);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              DatePicker.showDatePicker(
                                context,
                                showTitleActions: true,
                                minTime: DateTime(2020),
                                maxTime: DateTime.now().add(const Duration(days: 365)),
                                currentTime: _startDate ?? DateTime.now(),
                                locale: LocaleType.tr,
                                onConfirm: (pickedStart) {
                                  DatePicker.showDatePicker(
                                    context,
                                    showTitleActions: true,
                                    minTime: pickedStart,
                                    maxTime: DateTime.now().add(const Duration(days: 365)),
                                    currentTime: _endDate ?? pickedStart,
                                    locale: LocaleType.tr,
                                    onConfirm: (pickedEnd) {
                                      setSheetState(() {
                                        _startDate = pickedStart;
                                        _endDate = DateTime(
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
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Tarih Aralığı',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: const Icon(
                                  Icons.calendar_month_outlined,
                                  color: _SraporColors.primary,
                                ),
                              ),
                              child: Text(
                                _dateText,
                                style: const TextStyle(
                                  color: _SraporColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                            ),
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
                              foregroundColor: _SraporColors.primary,
                              side: const BorderSide(color: _SraporColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Filtreyi Temizle'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadSalesData();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _SraporColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Uygula'),
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

  Widget _buildSheetDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(
                  e.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = _displaySales;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _SraporColors.surface,
      drawer: const RoleSidebar(currentPage: 'Satış Raporu'),
      appBar: AdminPanelAppBar(
        title: 'Satış Raporu',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _SraporColors.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Arayın...',
                            prefixIcon: Icon(Icons.search, color: _SraporColors.primary),
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
                          color: _SraporColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _showFilterSheet,
                            borderRadius: BorderRadius.circular(12),
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.tune_rounded,
                                color: _SraporColors.primary,
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
                                color: _SraporColors.primary,
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
                      const SizedBox(width: 10),
                      _SummaryChip(
                        label: "Zecorner'a Getiri",
                        value: _zecornerReturn,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppStatusView.loading(
                    title: 'Rapor hazırlanıyor.',
                    message: 'Satış kayıtları yüklenirken lütfen bekleyin.',
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : sales.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: _SraporColors.primary,
                            onRefresh: _loadSalesData,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: sales.length,
                              itemBuilder: (context, index) {
                                return _SaleCard(
                                  sale: sales[index],
                                  formatPrice: _formatPrice,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                final roleCodes = snapshot.data ?? [];
                if (roleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 1);
                }
                if (roleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 1);
                }
                if (roleCodes.contains('role_office_broker') ||
                    roleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 1);
                }
                return const FrancahiseNavbar(currentIndex: 1);
              },
            );
          }
          return const AdminNavbar(currentIndex: 1);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return AppStatusView.error(
      message: _errorMessage ?? 'Bir hata oluştu',
      onRetry: _loadSalesData,
    );
  }

  Widget _buildEmptyState() {
    return const AppStatusView.missing(
      title: 'Satış kaydı bulunamadı',
      message: 'Seçilen kriterlere uygun bir satış kaydı yok.',
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
        color: _SraporColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _SraporColors.primary.withOpacity(0.25),
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
  final String Function(String) formatPrice;

  const _SaleCard({
    required this.sale,
    required this.formatPrice,
  });

  bool get _isSold => sale.state == 'SOLD';
  String get _statusLabel => _isSold ? 'Satıldı' : 'Kiralandı';

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy, HH:mm', 'tr_TR').format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buyerCommission = sale.buyerComission?.isNotEmpty == true
        ? formatPrice(sale.buyerComission!)
        : '-';
    final closingPrice = sale.closingPrice?.isNotEmpty == true
        ? formatPrice(sale.closingPrice!)
        : formatPrice(sale.price.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _SraporColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _SraporColors.border),
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
                    color: _SraporColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: _SraporColors.primary,
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
                          color: _SraporColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.customerTitle,
                        style: const TextStyle(
                          color: _SraporColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sale.officeTitle,
                        style: const TextStyle(
                          color: _SraporColors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _isSold
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _isSold
                          ? const Color(0xFF065F46)
                          : const Color(0xFF1E40AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: _SraporColors.border),
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
                    value: formatPrice(sale.sellerCommission),
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
                    value: formatPrice(sale.totalComission),
                    valueColor: _SraporColors.primary,
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
                  color: _SraporColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(sale.date),
                  style: const TextStyle(
                    color: _SraporColors.textMuted,
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
            color: _SraporColors.textMuted,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _SraporColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
