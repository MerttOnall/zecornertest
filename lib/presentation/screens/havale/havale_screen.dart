import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/transaction_cubit.dart';
import 'package:zecorner/infrastructure/transaction/transaction_api_repository.dart';
import 'package:zecorner/models/transaction/transaction_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:intl/intl.dart';

/// Havale Onayları Ekranı
/// API: GET https://zecorner.com/api/get-transactions/
class HavaleScreen extends StatefulWidget {
  const HavaleScreen({Key? key}) : super(key: key);

  @override
  State<HavaleScreen> createState() => _HavaleScreenState();
}

class _HavaleScreenState extends State<HavaleScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;

  /// Web ile aynı durum seçenekleri
  static const List<String> _statusOptions = [
    'Tümü',
    'Bekleyen',
    'Onaylandı',
    'İptal',
  ];

  /// Web ile aynı ödeme yöntemi seçenekleri
  static const List<String> _paymentOptions = [
    'Tümü',
    'Havale/EFT',
    'Kredi Kartı',
  ];

  String _selectedStatusFilter = 'Bekleyen';
  String _selectedPaymentFilter = 'Tümü';
  String _appliedSearch = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  late TransactionCubit _transactionCubit;

  @override
  void initState() {
    super.initState();
    _transactionCubit = TransactionCubit(TransactionApiRepository());
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardAccess());
  }

  /// Menüdeki admin bayrağıyla aynı: `is_admin`. Diğer roller bu sayfayı açamaz.
  Future<void> _guardAccess() async {
    final auth = context.read<AuthCubit>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final allowed = auth.isAdmin || prefs.getBool('userIsAdmin') == true;
    if (!allowed) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    _transactionCubit.loadTransactions(
      refresh: true,
      stateFilter: _selectedStatusFilter,
      sourceFilter: _selectedPaymentFilter,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _transactionCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _transactionCubit.loadMoreTransactions();
    }
  }

  /// Durum + ödeme + arama birlikte uygulanır (biri diğerini silmez).
  void _reloadWithFilters({String? search}) {
    final query = search ?? _searchController.text.trim();
    _appliedSearch = query;
    _transactionCubit.loadTransactions(
      refresh: true,
      stateFilter: _selectedStatusFilter,
      sourceFilter: _selectedPaymentFilter,
      search: query,
    );
  }

  void _onStatusFilterChanged(String filter) {
    setState(() => _selectedStatusFilter = filter);
    _reloadWithFilters();
  }

  void _onPaymentFilterChanged(String filter) {
    setState(() => _selectedPaymentFilter = filter);
    _reloadWithFilters();
  }

  void _onSearch(String query) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(seconds: 1), () {
      _reloadWithFilters(search: query.trim());
    });
  }

  Future<void> _onRefresh() async {
    await _transactionCubit.refreshTransactions();
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String state) {
    switch (state.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF16A34A);
      case 'PENDING':
        return const Color(0xFFDC2626);
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  bool get _hasActiveFilters =>
      _selectedStatusFilter != 'Bekleyen' ||
      _selectedPaymentFilter != 'Tümü' ||
      _searchController.text.trim().isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _selectedStatusFilter = 'Bekleyen';
      _selectedPaymentFilter = 'Tümü';
      _searchController.clear();
      _appliedSearch = '';
    });
    _reloadWithFilters(search: '');
  }

  Future<void> _showFilterPicker({
    required String title,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) async {
    final searchController = TextEditingController();
    var filtered = List<String>.from(options);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void filterOptions(String query) {
              setSheetState(() {
                filtered = options
                    .where((o) => o.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              });
            }

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: searchController,
                        onChanged: filterOptions,
                        decoration: InputDecoration(
                          hintText: 'Ara...',
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.35,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final option = filtered[index];
                            final isSelected = option == currentValue;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(
                                option,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF374151),
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_rounded, color: Color(0xFFE53935))
                                  : null,
                              onTap: () {
                                onSelected(option);
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  Widget _buildFilterChipButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isActive = label == 'Durum' ? value != 'Bekleyen' : value != 'Tümü';

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE53935).withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? const Color(0xFFE53935).withOpacity(0.35) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? const Color(0xFFE53935) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive ? const Color(0xFFE53935) : const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchController.text.isNotEmpty
                    ? const Color(0xFFE53935).withOpacity(0.35)
                    : const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Havale No',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChipButton(
                icon: Icons.filter_list_rounded,
                label: 'Durum',
                value: _selectedStatusFilter,
                onTap: () => _showFilterPicker(
                  title: 'Durum Seçin',
                  currentValue: _selectedStatusFilter,
                  options: _statusOptions,
                  onSelected: _onStatusFilterChanged,
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChipButton(
                icon: Icons.payments_outlined,
                label: 'Ödeme',
                value: _selectedPaymentFilter,
                onTap: () => _showFilterPicker(
                  title: 'Ödeme Yöntemi',
                  currentValue: _selectedPaymentFilter,
                  options: _paymentOptions,
                  onSelected: _onPaymentFilterChanged,
                ),
              ),
            ],
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Filtreyi Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCell({
    required String label,
    required String value,
    Color? valueColor,
    FontWeight valueWeight = FontWeight.w600,
    int maxLines = 1,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: valueWeight,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
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
                              _getStatusColor(transaction.state).withOpacity(0.15),
                              _getStatusColor(transaction.state).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          size: 40,
                          color: _getStatusColor(transaction.state),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Amount - Center
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _formatAmount(transaction.amount),
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
                              color: _getStatusColor(transaction.state).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(transaction.state),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  transaction.stateText,
                                  style: TextStyle(
                                    color: _getStatusColor(transaction.state),
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
                            icon: Icons.numbers_rounded,
                            label: 'Fatura No',
                            value: transaction.displayInvoiceNumber,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.payments_rounded,
                            label: 'Ödeme Yöntemi',
                            value: transaction.paymentMethod,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.business_rounded,
                            label: 'Kullanıcı/Ofis',
                            value: transaction.userOrOfficeDisplay,
                          ),
                          _buildDivider(),
                          _buildDetailItem(
                            icon: Icons.event_rounded,
                            label: 'Tarih',
                            value: transaction.formattedDate,
                          ),
                          if (transaction.isApproved) ...[
                            _buildDivider(),
                            _buildDetailItem(
                              icon: Icons.person_rounded,
                              label: 'Onaylayan',
                              value: transaction.approverDisplay,
                            ),
                            _buildDivider(),
                            _buildDetailItem(
                              icon: Icons.check_circle_rounded,
                              label: 'Onay Tarihi',
                              value: transaction.approvalDateDisplay,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Bekleyen durumda - Onayla ve Reddet butonları
                    if (transaction.isPending) ...[
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
                              _formatAmount(transaction.amount),
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
                      // Onayla Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showApproveConfirmDialog(transaction),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
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
                              Icon(Icons.check_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Onayla',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Reddet Butonu
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showRejectConfirmDialog(transaction),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.close_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Reddet',
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
                    
                    // Onaylanmış durumda - Sadece bilgilendirme
                    if (transaction.isApproved) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Havale Onaylandı',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  if (transaction.approvedOn != null)
                                    Text(
                                      'Onay Tarihi: ${_formatDateTime(transaction.approvedOn!)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
  void _showApproveConfirmDialog(TransactionModel transaction) {
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
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
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
                      _buildConfirmDetailRow('İşlem No:', '${transaction.id}'),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tutar:', _formatAmount(transaction.amount)),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Fatura No:', transaction.displayInvoiceNumber),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Kullanıcı/Ofis:', transaction.userOrOfficeDisplay),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tarih:', _formatDateTime(transaction.date)),
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
                          _transactionCubit.approveTransaction(transaction.id);
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

  /// Reddet popup'ı göster
  void _showRejectConfirmDialog(TransactionModel transaction) {
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
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFEF4444),
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Ödeme Reddet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Bu ödemeyi reddetmek istediğinize emin misiniz?',
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
                      _buildConfirmDetailRow('İşlem No:', '${transaction.id}'),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tutar:', _formatAmount(transaction.amount)),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Fatura No:', transaction.displayInvoiceNumber),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Kullanıcı/Ofis:', transaction.userOrOfficeDisplay),
                      const SizedBox(height: 10),
                      _buildConfirmDetailRow('Tarih:', _formatDateTime(transaction.date)),
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
                    // Reddet Butonu
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context); // Bottom sheet'i kapat
                          _transactionCubit.rejectTransaction(transaction.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Evet, Reddet',
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
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Havale Onayları');
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
        title: 'Havale Onayları',
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
      body: BlocConsumer<TransactionCubit, TransactionState>(
        bloc: _transactionCubit,
        listener: (context, state) {
          // Onay/Red sonuçlarını dinle
          if (state is TransactionApproved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Havale başarıyla onaylandı!'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state is TransactionApproveError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Hata: ${state.failure.message}')),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state is TransactionRejected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Havale reddedildi.'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state is TransactionRejectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Hata: ${state.failure.message}')),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
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
                  color: const Color(0xFFE53935),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Filter Section
                      SliverToBoxAdapter(
                        child: _buildModernFilterSection(),
                      ),
                      
                      // Content based on state
                      if (state is TransactionLoading &&
                          _transactionCubit.allTransactions.isEmpty)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else if (state is TransactionError)
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
                                      backgroundColor: const Color(0xFFE53935),
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
                      else if (state is TransactionLoaded ||
                          state is TransactionLoadingMore ||
                          _transactionCubit.allTransactions.isNotEmpty)
                        ..._buildTransactionListSlivers(state)
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

  /// Build transaction list slivers based on state
  List<Widget> _buildTransactionListSlivers(TransactionState state) {
    List<TransactionModel> transactions = [];
    bool isLoadingMore = false;

    if (state is TransactionLoaded) {
      transactions = state.allTransactions;
    } else if (state is TransactionLoadingMore) {
      transactions = state.currentTransactions;
      isLoadingMore = true;
    } else {
      transactions = _transactionCubit.allTransactions;
    }

    transactions = transactions
        .where(
          (item) =>
              item.matchesStatus(_selectedStatusFilter) &&
              item.matchesPayment(_selectedPaymentFilter) &&
              item.matchesQuery(_appliedSearch),
        )
        .toList();

    if (transactions.isEmpty) {
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
                      Icons.account_balance_rounded,
                      size: 44,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Havale bulunamadı',
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
              final transaction = transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTransactionCard(transaction),
              );
            },
            childCount: transactions.length,
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

  Widget _buildTransactionCard(TransactionModel transaction) {
    final statusColor = _getStatusColor(transaction.state);

    return GestureDetector(
      onTap: () => _showTransactionDetail(transaction),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FATURA NO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.displayInvoiceNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    transaction.stateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildInfoCell(
                    label: 'TUTAR',
                    value: _formatAmount(transaction.amount),
                    valueWeight: FontWeight.w800,
                  ),
                  _buildInfoCell(
                    label: 'ÖDEME YÖNTEMİ',
                    value: transaction.paymentMethod,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoCell(
                    label: 'KULLANICI/OFİS',
                    value: transaction.userOrOfficeDisplay,
                    maxLines: 2,
                  ),
                  _buildInfoCell(
                    label: 'TARİH',
                    value: transaction.formattedDate,
                  ),
                ],
              ),
              if (transaction.isApproved) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoCell(
                      label: 'ONAYLAYAN',
                      value: transaction.approverDisplay,
                      maxLines: 2,
                    ),
                    _buildInfoCell(
                      label: 'ONAY TARİHİ',
                      value: transaction.approvalDateDisplay,
                    ),
                  ],
                ),
              ],
              if (transaction.isPending) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFFDC2626)),
                      SizedBox(width: 8),
                      Text(
                        'Onaylamak için dokun',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
