import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/rapor/rapor_repository.dart';
import 'package:zecorner/models/rapor/broker_row_model.dart';
import 'package:zecorner/models/rapor/rapor_row_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

/// Rapor türü seçenekleri (API'den de doldurulabilir)
const List<String> _raporTuruOptions = [
  'En çok satış yapan',
  'En çok kiralama yapan',
  'En çok satış ve kiralama yapan',
  'En çok ilanı olan',
  'Ofis Ciroları',
  'Danışman/Broker Ciroları',
  'Tüm danışmanlar',
  'Tüm brokerlar',
  'Tüm ofisler',
];

// Tasarım sabitleri
class _RaporColors {
  static const Color primary = Color(0xFFE53935);
  static const Color primaryLight = Color(0xFFFFEBEE);
  static const Color surface = Color(0xFFFFFFFF); // Beyaz arka plan
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
}

class RaporScreen extends StatefulWidget {
  const RaporScreen({super.key});

  @override
  State<RaporScreen> createState() => _RaporScreenState();
}

class _RaporScreenState extends State<RaporScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final RaporRepository _raporRepo = RaporRepository();

  String _selectedRaporTuru = _raporTuruOptions.first;
  bool _kapsamDanisman = true;
  bool _isLoading = false;
  List<RaporRowModel> _rows = [];
  List<BrokerRowModel> _brokerRows = [];
  String? _loadError;

  bool get _isTumBrokerlar => _selectedRaporTuru == 'Tüm brokerlar';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Tarih aralığı: bu yılın 1 Ocak - bugün
  (String, String) _getDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = now;
    return (
      '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (_selectedRaporTuru == 'Tüm brokerlar') {
        final list = await _raporRepo.getBrokersFromContactApi();
        if (!mounted) return;
        setState(() {
          _brokerRows = list;
          _rows = [];
          _isLoading = false;
        });
      } else {
        final (startDate, endDate) = _getDateRange();
        final params = RaporListParams(
          startDate: startDate,
          endDate: endDate,
          type: _kapsamDanisman ? 'advisor' : 'office',
          state: raporTuruToState(_selectedRaporTuru),
          page: 1,
          pageSize: 9999,
        );
        final list = await _raporRepo.getAdminListings(params);
        if (!mounted) return;
        setState(() {
          _rows = list;
          _brokerRows = [];
          _isLoading = false;
        });
      }
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoading = false;
        _rows = [];
        _brokerRows = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
        _rows = [];
        _brokerRows = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _RaporColors.surface,
      drawer: RoleSidebar(currentPage: 'Raporlar'),
      appBar: AdminPanelAppBar(
        title: 'Raporlar',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReport,
          color: _RaporColors.primary,
          backgroundColor: _RaporColors.card,
          strokeWidth: 2,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFiltersCard(),
                      const SizedBox(height: 20),
                      if (!_isTumBrokerlar) ...[
                        _buildScopeSection(),
                        const SizedBox(height: 24),
                      ] else
                        const SizedBox(height: 24),
                      _isTumBrokerlar ? _buildBrokerListHeader() : _buildListHeader(),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        color: _RaporColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                )
              else if (_loadError != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (_isTumBrokerlar ? _brokerRows.isEmpty : _rows.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  sliver: _isTumBrokerlar
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BrokerCard(
                                broker: _brokerRows[index],
                                rank: index + 1,
                              ),
                            ),
                            childCount: _brokerRows.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReportCard(
                                row: _rows[index],
                                rank: index + 1,
                              ),
                            ),
                            childCount: _rows.length,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
                }
                final userRoleCodes = snapshot.data ?? [];
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                }
                if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                }
                if (userRoleCodes.contains('role_office_broker') ||
                    userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                }
                return const FrancahiseNavbar(currentIndex: 0);
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RaporColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _RaporColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, color: _RaporColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rapor Türü',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _RaporColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RaporDropdownField(
            value: _selectedRaporTuru,
            options: _raporTuruOptions,
            onChanged: (v) => setState(() => _selectedRaporTuru = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadReport,
              icon: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 24),
              label: Text(_isLoading ? 'Yükleniyor…' : 'Bul'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _RaporColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kapsam',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _RaporColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _RaporColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _RaporColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _ScopeChip(
                  label: 'Danışman',
                  selected: _kapsamDanisman,
                  onTap: () => setState(() => _kapsamDanisman = true),
                ),
              ),
              Expanded(
                child: _ScopeChip(
                  label: 'Ofis',
                  selected: !_kapsamDanisman,
                  onTap: () => setState(() => _kapsamDanisman = false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            'Ofis / Danışman',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _RaporColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            'Danışman',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _RaporColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 40,
            child: Text(
              'Adet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textMuted,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrokerListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'Kişi / T.C & Vergi No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'İletişim Bilgileri',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Bağlı Ofis/Broker',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _RaporColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: _RaporColors.primary.withOpacity(0.9)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rapor yüklenemedi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _RaporColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _RaporColors.textMuted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Tekrar dene'),
              style: TextButton.styleFrom(
                foregroundColor: _RaporColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _RaporColors.primaryLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 56,
              color: _RaporColors.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bu kriterlere uygun kayıt yok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _RaporColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Modern dropdown: tıklanınca beyaz modal açar, üstte "Ara..." alanı, altta liste.
class _RaporDropdownField extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _RaporDropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _openDropdown(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RaporDropdownSheet(
        options: options,
        selectedValue: value,
        onSelected: (v) {
          onChanged(v);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _RaporColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openDropdown(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _RaporColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: _RaporColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _RaporColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaporDropdownSheet extends StatefulWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _RaporDropdownSheet({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  State<_RaporDropdownSheet> createState() => _RaporDropdownSheetState();
}

class _RaporDropdownSheetState extends State<_RaporDropdownSheet> {
  late TextEditingController _searchController;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _filtered = List.from(widget.options);
      } else {
        final lower = q.trim().toLowerCase();
        _filtered = widget.options
            .where((s) => s.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.6;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _RaporColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ara...',
                hintStyle: const TextStyle(
                  color: _RaporColors.textMuted,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _RaporColors.textMuted,
                  size: 22,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final option = _filtered[index];
                final isSelected = option == widget.selectedValue;
                return Material(
                  color: isSelected
                      ? _RaporColors.primaryLight.withOpacity(0.5)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? _RaporColors.primary
                              : _RaporColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _RaporColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _RaporColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _RaporColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final RaporRowModel row;
  final int rank;

  const _ReportCard({required this.row, this.rank = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _RaporColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RaporColors.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (rank > 0)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: rank <= 3 ? _RaporColors.primaryLight : _RaporColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? _RaporColors.primary : _RaporColors.textSecondary,
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.officeOrConsultant,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _RaporColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  row.consultant,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _RaporColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _RaporColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${row.count}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _RaporColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  final BrokerRowModel broker;
  final int rank;

  const _BrokerCard({required this.broker, this.rank = 0});

  static Color _avatarColor(String name) {
    if (name.isEmpty) return const Color(0xFF90A4AE);
    final h = name.hashCode % 360;
    return HSLColor.fromAHSL(1, h.toDouble(), 0.45, 0.65).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final initials = broker.displayName.isNotEmpty
        ? broker.displayName.trim().split(RegExp(r'\s+')).map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _RaporColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _RaporColors.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _RaporColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _avatarColor(broker.displayName),
                  child: broker.pictureUrl != null && broker.pictureUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            broker.pictureUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        broker.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _RaporColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        broker.tcVergiDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _RaporColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  broker.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _RaporColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  broker.tel.isEmpty ? '0' : broker.tel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _RaporColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              broker.connectedContactTitle ?? '—',
              style: const TextStyle(
                fontSize: 13,
                color: _RaporColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
