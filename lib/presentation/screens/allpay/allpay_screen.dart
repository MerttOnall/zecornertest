import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/invoice_cubit.dart';
import 'package:zecorner/infrastructure/invoice/invoice_api_repository.dart';
import 'package:zecorner/models/invoice/invoice_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:intl/intl.dart';

/// Tüm Faturalar Ekranı
/// API: get-invoices/?all=true
class AllPayScreen extends StatefulWidget {
  const AllPayScreen({Key? key}) : super(key: key);

  @override
  State<AllPayScreen> createState() => _AllPayScreenState();
}

class _AllPayScreenState extends State<AllPayScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  String _selectedFilter = 'Tümü';
  String? _selectedTypeFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _canApproveInvoice = false;
  bool _canSeeAmounts = false;

  static const _primaryRed = Color(0xFFE53935);

  static const List<Map<String, String>> _invoiceTypes = [
    {'value': 'training', 'label': 'Eğitim'},
    {'value': 'advisor', 'label': 'Danışman'},
    {'value': 'monthly', 'label': 'Aidat'},
    {'value': 'franchise', 'label': 'Franchise'},
    {'value': 'event', 'label': 'Etkinlik'},
  ];
  
  late InvoiceCubit _invoiceCubit;

  @override
  void initState() {
    super.initState();
    // fetchAllInvoices: true ile tüm faturalar çekilecek
    _invoiceCubit = InvoiceCubit(InvoiceApiRepository(), fetchAllInvoices: true);
    _invoiceCubit.loadInvoices();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovePermission();
    });
  }

  Future<void> _loadApprovePermission() async {
    try {
      final authCubit = context.read<AuthCubit>();
      final roleCodes = await authCubit.getUserRoleCodes();
      if (!mounted) return;
      setState(() {
        _canApproveInvoice = roleCodes.contains('role_admin') ||
            roleCodes.contains('role_accountant') ||
            authCubit.isAdmin;
        _canSeeAmounts =
            roleCodes.contains('role_admin') || authCubit.isAdmin;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _canApproveInvoice = false;
        _canSeeAmounts = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _invoiceCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _invoiceCubit.loadMoreInvoices();
    }
  }

  Future<void> _applyCurrentFilters() async {
    await _invoiceCubit.applyFilters(
      stateFilter: _selectedFilter,
      typeFilter: _selectedTypeFilter,
      search: _searchController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyCurrentFilters();
  }

  void _onTypeFilterChanged(String? type) {
    setState(() {
      _selectedTypeFilter = type;
    });
    _applyCurrentFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {}); // clear (X) butonu için
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _applyCurrentFilters();
    });
  }

  void _onSearchSubmitted(String query) {
    _searchDebounce?.cancel();
    _applyCurrentFilters();
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _searchController.clear();
    });
    _applyCurrentFilters();
  }

  Future<void> _onRefresh() async {
    await _invoiceCubit.refreshInvoices();
  }

  Future<void> _clearAllFilters() async {
    _searchDebounce?.cancel();
    setState(() {
      _selectedFilter = 'Tümü';
      _selectedTypeFilter = null;
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
    await _invoiceCubit.clearFilters();
  }

  bool get _hasActiveFilters =>
      _selectedFilter != 'Tümü' ||
      _selectedTypeFilter != null ||
      _startDate != null ||
      _endDate != null ||
      _searchController.text.trim().isNotEmpty;

  InvoiceAmounts _amountsFromState(InvoiceState state, List<InvoiceModel> invoices) {
    InvoiceAmounts amounts = const InvoiceAmounts();
    if (state is InvoiceLoaded) {
      amounts = state.invoiceResponse.amounts;
    } else if (state is InvoiceLoadingMore) {
      amounts = state.amounts;
    }

    if (amounts.totalAmount > 0 || amounts.paidAmount > 0) {
      return amounts;
    }

    double total = 0;
    double paid = 0;
    for (final invoice in invoices) {
      total += invoice.amount;
      paid += invoice.paidAmount;
    }
    return InvoiceAmounts(totalAmount: total, paidAmount: paid);
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  String _getStatusText(String state) {
    switch (state.toUpperCase()) {
      case 'PAID':
        return 'Ödendi';
      case 'NOT_PAID':
        return 'Ödenmedi';
      case 'PENDING':
        return 'Bekliyor';
      case 'CANCELLED':
        return 'İptal';
      case 'AWAITING_PAYMENT':
        return 'Havale';
      default:
        return state;
    }
  }

  Color _getStatusColor(String state) {
    switch (state.toUpperCase()) {
      case 'PAID':
        return const Color(0xFF10B981);
      case 'NOT_PAID':
        return const Color(0xFFDC2626);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'AWAITING_PAYMENT':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(InvoiceModel invoice) {
    switch (invoice.state.toUpperCase()) {
      case 'PAID':
        return Icons.check_circle_rounded;
      case 'NOT_PAID':
        return Icons.money_off_rounded;
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'AWAITING_PAYMENT':
        return Icons.account_balance_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  IconData _getInvoiceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'training':
        return Icons.school_rounded;
      case 'advisor':
        return Icons.person_add_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      case 'franchise':
        return Icons.business_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        // Fallback to description based
        if (type.contains('Eğitim')) return Icons.school_rounded;
        if (type.contains('Danışman')) return Icons.person_add_rounded;
        if (type.contains('Aidat')) return Icons.calendar_month_rounded;
        if (type.contains('Franchise')) return Icons.business_rounded;
        if (type.contains('Etkinlik') || type.contains('event')) return Icons.event_rounded;
        return Icons.receipt_long_rounded;
    }
  }

  void _showInvoiceDetail(InvoiceModel invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(invoice.state).withOpacity(0.15),
                              _getStatusColor(invoice.state).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getInvoiceTypeIcon(invoice.type),
                          size: 40,
                          color: _getStatusColor(invoice.state),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Amount - Center
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formatAmount(invoice.amount),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoice.state).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(invoice.state),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusText(invoice.state),
                                  style: TextStyle(
                                    color: _getStatusColor(invoice.state),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildDetailItem(
                            icon: Icons.business_rounded,
                            label: 'Kullanıcı/Ofis',
                            value: invoice.contactTitle,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.category_rounded,
                            label: 'Fatura Türü',
                            value: invoice.typeDescription,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.numbers_rounded,
                            label: 'Fatura No',
                            value: invoice.invoiceNumber,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.event_rounded,
                            label: 'Oluşturulma Tarihi',
                            value: _formatDateTime(invoice.date),
                          ),
                          if (invoice.paidDate != null) ...[
                            _buildDivider(),
                            _buildDetailItem(
                              icon: Icons.check_circle_rounded,
                              label: 'Ödeme Tarihi',
                              value: _formatDateTime(invoice.paidDate!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // AWAITING_PAYMENT: Faturayı Onayla yalnızca admin / muhasebe
                    if (invoice.isAwaitingPayment && _canApproveInvoice) ...[
                      // Ödenecek Tutar Kartı
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ödenecek Tutar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Text(
                              _formatAmount(invoice.amount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Faturayı Onayla Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showApproveConfirmDialog(invoice),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Faturayı Onayla',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Ödendi durumunda - Faturayı İndir butonu
                    if (invoice.isPaid) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Text('Fatura indiriliyor...'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Faturayı İndir',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Onay popup'ı göster
  void _showApproveConfirmDialog(InvoiceModel invoice) {
    if (!_canApproveInvoice) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Ödeme Onayla',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Bu ödemeyi onaylamak istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildConfirmDetailRow('Fatura No:', invoice.invoiceNumber),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tutar:', _formatAmount(invoice.amount)),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Kullanıcı/Ofis:', invoice.contactTitle),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Fatura Türü:', invoice.typeDescription),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tarih:', _formatDateTime(invoice.date)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // İptal Butonu
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Onayla Butonu
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context); // Bottom sheet'i kapat
                          _invoiceCubit.approveInvoice(invoice.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Fatura onaylanıyor...'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFFE53935),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Evet, Onayla',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Confirm dialog için detay satırı
  Widget _buildConfirmDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Faturalar');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: 'Faturalar',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // Role sistemine göre navbar seçimi
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                
                final userRoleCodes = snapshot.data ?? [];
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else {
                  return const FrancahiseNavbar(currentIndex: 0);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        bloc: _invoiceCubit,
        builder: (context, state) {
          final listInvoices = state is InvoiceLoaded
              ? state.allInvoices
              : state is InvoiceLoadingMore
                  ? state.currentInvoices
                  : <InvoiceModel>[];
          final amounts = _amountsFromState(state, listInvoices);
          final showSummary = _canSeeAmounts &&
              (state is InvoiceLoaded || state is InvoiceLoadingMore);

          return GestureDetector(
            onTap: () {
              if (_isDrawerOpen) {
                _scaffoldKey.currentState?.closeDrawer();
              }
              FocusScope.of(context).unfocus();
            },
            child: AbsorbPointer(
              absorbing: _isDrawerOpen,
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: _primaryRed,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Search, Filters & Summary
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Column(
                            children: [
                              _buildSearchAndFilterRow(),
                              const SizedBox(height: 14),
                              if (showSummary) _buildSummaryCards(amounts),
                              if (showSummary) const SizedBox(height: 14),
                              _buildStatusChips(),
                              if (_hasActiveFilters) ...[
                                const SizedBox(height: 10),
                                _buildActiveFiltersBar(),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Content based on state
                      if (state is InvoiceLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _primaryRed,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else if (state is InvoiceError)
                        SliverFillRemaining(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Bir hata oluştu',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.failure.message,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _onRefresh,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Tekrar Dene'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryRed,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (state is InvoiceLoaded || state is InvoiceLoadingMore)
                        ..._buildInvoiceListSlivers(state)
                      else
                        const SliverToBoxAdapter(child: SizedBox.shrink()),
                      
                      // Bottom Padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    final hasSearchText = _searchController.text.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: 'Fatura no, ofis, ünvan ara...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: _primaryRed,
                      size: 18,
                    ),
                  ),
                ),
                suffixIcon: hasSearchText
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryRed,
                    _primaryRed.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                  if (_hasActiveFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _primaryRed, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(InvoiceAmounts amounts) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Toplam Tutar',
            value: _formatAmount(amounts.totalAmount),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            label: 'Ödenen Tutar',
            value: _formatAmount(amounts.paidAmount),
            icon: Icons.payments_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('Tümü'),
          const SizedBox(width: 10),
          _buildFilterChip('Ödendi'),
          const SizedBox(width: 10),
          _buildFilterChip('Bekliyor'),
          const SizedBox(width: 10),
          _buildFilterChip('Havale'),
          const SizedBox(width: 10),
          _buildFilterChip('Ödenmedi'),
          const SizedBox(width: 10),
          _buildFilterChip('İptal'),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    String? typeLabel;
    for (final type in _invoiceTypes) {
      if (type['value'] == _selectedTypeFilter) {
        typeLabel = type['label'];
        break;
      }
    }

    final dateLabel = (_startDate != null || _endDate != null)
        ? '${_startDate != null ? _formatDate(_startDate!) : '...'} - ${_endDate != null ? _formatDate(_endDate!) : '...'}'
        : null;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              if (_selectedTypeFilter != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRemovableChip(
                    label: typeLabel ?? _selectedTypeFilter!,
                    onRemove: () => _onTypeFilterChanged(null),
                  ),
                ),
              if (dateLabel != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRemovableChip(
                    label: dateLabel,
                    onRemove: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _applyCurrentFilters();
                    },
                  ),
                ),
              if (_searchController.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRemovableChip(
                    label: '"${_searchController.text.trim()}"',
                    onRemove: _clearSearch,
                  ),
                ),
              GestureDetector(
                onTap: _clearAllFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt_off_rounded, size: 14, color: _primaryRed),
                      SizedBox(width: 6),
                      Text(
                        'Temizle',
                        style: TextStyle(
                          color: _primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    String tempStatus = _selectedFilter;
    String? tempType = _selectedTypeFilter;
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    final tempSearchController = TextEditingController(text: _searchController.text);
    var searchDisposed = false;

    void disposeSearch() {
      if (searchDisposed) return;
      searchDisposed = true;
      tempSearchController.dispose();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate({required bool isStart}) async {
              DatePicker.showDatePicker(
                context,
                showTitleActions: true,
                minTime: DateTime(2020, 1, 1),
                maxTime: DateTime(2035, 12, 31),
                currentTime: isStart
                    ? (tempStart ?? DateTime.now())
                    : (tempEnd ?? tempStart ?? DateTime.now()),
                locale: LocaleType.tr,
                onConfirm: (picked) {
                  setModalState(() {
                    if (isStart) {
                      tempStart = picked;
                      if (tempEnd != null && picked.isAfter(tempEnd!)) {
                        tempEnd = picked;
                      }
                    } else {
                      tempEnd = picked;
                      if (tempStart != null && picked.isBefore(tempStart!)) {
                        tempStart = picked;
                      }
                    }
                  });
                },
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                          const Expanded(
                            child: Text(
                              'Filtrele',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempStatus = 'Tümü';
                                tempType = null;
                                tempStart = null;
                                tempEnd = null;
                                tempSearchController.clear();
                              });
                            },
                            child: const Text(
                              'Sıfırla',
                              style: TextStyle(
                                color: _primaryRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetSectionTitle('Ara'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: tempSearchController,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Fatura no, ofis, ünvan...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: _primaryRed,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: _primaryRed, width: 1.4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSheetSectionTitle('Tarih Aralığı'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Başlangıç',
                                    value: tempStart,
                                    onTap: () => pickDate(isStart: true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Bitiş',
                                    value: tempEnd,
                                    onTap: () => pickDate(isStart: false),
                                  ),
                                ),
                              ],
                            ),
                            if (tempStart != null || tempEnd != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      tempStart = null;
                                      tempEnd = null;
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primaryRed,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Tarihi temizle',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            _buildSheetSectionTitle('Durum'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final status in [
                                  'Tümü',
                                  'Ödendi',
                                  'Bekliyor',
                                  'Havale',
                                  'Ödenmedi',
                                  'İptal',
                                ])
                                  _buildSheetChoiceChip(
                                    label: status,
                                    selected: tempStatus == status,
                                    onTap: () => setModalState(() => tempStatus = status),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            _buildSheetSectionTitle('Fatura Türü'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSheetChoiceChip(
                                  label: 'Tüm türler',
                                  selected: tempType == null,
                                  onTap: () => setModalState(() => tempType = null),
                                ),
                                for (final type in _invoiceTypes)
                                  _buildSheetChoiceChip(
                                    label: type['label']!,
                                    selected: tempType == type['value'],
                                    onTap: () => setModalState(
                                      () => tempType = type['value'],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  disposeSearch();
                                  Navigator.pop(sheetContext);
                                  await _clearAllFilters();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryRed,
                                  side: const BorderSide(color: _primaryRed),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Filtreleri temizle',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final searchText = tempSearchController.text;
                                  disposeSearch();
                                  Navigator.pop(sheetContext);
                                  setState(() {
                                    _selectedFilter = tempStatus;
                                    _selectedTypeFilter = tempType;
                                    _startDate = tempStart;
                                    _endDate = tempEnd;
                                    _searchController.text = searchText;
                                  });
                                  await _applyCurrentFilters();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
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
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(disposeSearch);
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value != null ? _primaryRed.withOpacity(0.35) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: value != null ? _primaryRed : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _formatDate(value) : 'Seçiniz',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value != null
                          ? const Color(0xFF1F2937)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSheetChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _primaryRed : Colors.grey.shade200,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Build invoice list slivers based on state
  List<Widget> _buildInvoiceListSlivers(InvoiceState state) {
    List<InvoiceModel> invoices = [];
    bool isLoadingMore = false;
    
    if (state is InvoiceLoaded) {
      invoices = state.allInvoices;
    } else if (state is InvoiceLoadingMore) {
      invoices = state.currentInvoices;
      isLoadingMore = true;
    }
    
    if (invoices.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade100,
                          Colors.grey.shade50,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fatura bulunamadı',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Farklı bir filtre deneyin veya\narama teriminizi değiştirin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_hasActiveFilters)
                    GestureDetector(
                      onTap: _clearAllFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: _primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: _primaryRed,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Filtreleri Sıfırla',
                              style: TextStyle(
                                color: _primaryRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final invoice = invoices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInvoiceCard(invoice),
              );
            },
            childCount: invoices.length,
          ),
        ),
      ),
      if (isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE53935),
                strokeWidth: 2,
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    Color chipColor;
    IconData chipIcon;
    if (label == 'Ödendi') {
      chipColor = const Color(0xFF10B981);
      chipIcon = Icons.check_circle_rounded;
    } else if (label == 'Bekliyor') {
      chipColor = const Color(0xFFF59E0B);
      chipIcon = Icons.schedule_rounded;
    } else if (label == 'İptal') {
      chipColor = const Color(0xFFEF4444);
      chipIcon = Icons.cancel_rounded;
    } else if (label == 'Havale') {
      chipColor = const Color(0xFF3B82F6);
      chipIcon = Icons.account_balance_rounded;
    } else {
      chipColor = const Color(0xFFE53935);
      chipIcon = Icons.filter_list_rounded;
    }
    
    return GestureDetector(
      onTap: () {
        _onFilterChanged(label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade200,
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: chipColor.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                chipIcon,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final statusColor = _getStatusColor(invoice.state);
    
    return GestureDetector(
      onTap: () => _showInvoiceDetail(invoice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: statusColor.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle gradient accent on left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row - Icon, Title, Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Modern Icon with gradient background
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE53935),
                                const Color(0xFFE53935).withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getInvoiceTypeIcon(invoice.type),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with status badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      invoice.contactTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Modern Status Badge - Compact
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _getStatusIcon(invoice),
                                          size: 12,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getStatusText(invoice.state),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Invoice type badge - flexible width
                              Wrap(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      invoice.typeDescription,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bottom Row - Amount & Date (simplified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Amount
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tutar',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      _formatAmount(invoice.amount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          Container(
                            width: 1,
                            height: 32,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200.withOpacity(0),
                                  Colors.grey.shade200,
                                  Colors.grey.shade200.withOpacity(0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          
                          // Date
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tarih',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(invoice.date),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Color(0xFF1F2937),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

