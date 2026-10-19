import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/screens/reports/cari_report_panel.dart';
import 'package:zecorner/presentation/screens/reports/general_report_panel.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/screens/reports/sales_report_panel.dart';
import 'package:zecorner/presentation/screens/reports/yearly_sales_report_panel.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

/// Raporlar.
/// Admin ile franchise bölge müdürü / bölge yöneticisi herkesi görür.
/// Broker yalnız kendi ofisinin, danışman yalnız kendi işlemlerinin satış raporunu görür.
class ReportsScreen extends StatefulWidget {
  final ReportsTab initialTab;

  const ReportsScreen({
    super.key,
    this.initialTab = ReportsTab.sales,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late ReportsTab _activeTab;
  bool _checkingAccess = true;
  bool _isAdmin = false;
  bool _seesAll = false;
  bool _isAdvisor = false;
  bool _isBroker = false;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final roleCodes = await context.read<AuthCubit>().getUserRoleCodes();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final isAdmin = roleCodes.contains('role_admin') ||
          prefs.getBool('userIsAdmin') == true;
      final seesAll = isAdmin ||
          _seesEverySalesReport(prefs.getString('userTypeDescription'));
      final isBrokerRole = roleCodes.contains('role_office_broker') ||
          roleCodes.contains('role_office_assistant');
      setState(() {
        _isAdmin = isAdmin;
        _seesAll = seesAll;
        _isBroker = roleCodes.contains('role_office_broker') && !seesAll;
        _isAdvisor =
            roleCodes.contains('role_advisor') && !seesAll && !isBrokerRole;
        _checkingAccess = false;
        if (_isAdvisor || _isBroker) _activeTab = ReportsTab.sales;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _seesAll = false;
        _checkingAccess = false;
      });
    }
  }

  /// Admin dışındaki tam görünüm: saha / satış bölge müdürü ve bölge yöneticisi.
  /// Diğer franchise unvanları bu listeye girmez.
  bool _seesEverySalesReport(String? typeDescription) {
    if (AuthCubit.isFranchiseRegionDirector(typeDescription)) return true;
    final normalized = (typeDescription ?? '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    const titles = {
      'franchise saha ve gelistirme bolge muduru',
      'franchise saha ve gelistirme bolge yoneticisi',
      'franchise satis ve gelistirme bolge muduru',
      'franchise satis ve gelistirme bolge yoneticisi',
    };
    return titles.contains(normalized);
  }

  Widget _buildBody() {
    if (_checkingAccess) {
      return const AppStatusView.loading(
        title: 'Yetki kontrol ediliyor',
        message: 'Raporlar sayfasına erişim doğrulanıyor.',
      );
    }

    if (!_seesAll && !_isAdvisor && !_isBroker) {
      return AppStatusView.error(
        title: 'Erişim engellendi',
        message: 'Bu sayfa yalnızca admin kullanıcılar içindir.',
        onRetry: () => Navigator.of(context).maybePop(),
        retryLabel: 'Geri Dön',
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Raporlar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ReportTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Satış, yıllık, cari ve genel performans özetleri',
                style: TextStyle(
                  fontSize: 13,
                  color: ReportTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (_isAdvisor || _isBroker)
                const SizedBox.shrink()
              else
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ReportsTab.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = ReportsTab.values[index];
                    final selected = tab == _activeTab;
                    return Material(
                      color: selected
                          ? ReportTheme.primary
                          : ReportTheme.primaryLight,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = tab),
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                tab.icon,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : ReportTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : ReportTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildActivePanel()),
      ],
    );
  }

  Widget _buildActivePanel() {
    if (_isBroker) {
      return const SalesReportPanel(scope: SalesReportScope.office);
    }
    if (_isAdvisor) {
      return const SalesReportPanel(scope: SalesReportScope.self);
    }
    switch (_activeTab) {
      case ReportsTab.sales:
        return const SalesReportPanel(scope: SalesReportScope.all);
      case ReportsTab.yearly:
        return const YearlySalesReportPanel();
      case ReportsTab.cari:
        return const CariReportPanel();
      case ReportsTab.general:
        return const GeneralReportPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ReportTheme.surface,
      drawer: RoleSidebar(currentPage: _activeTab.sidebarTitle),
      appBar: AdminPanelAppBar(
        title: _activeTab.label,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _isAdmin
          ? const AdminNavbar(currentIndex: 1)
          : _isBroker
              ? const BrokerNavbar(currentIndex: 0)
              : _isAdvisor
                  ? const DanismanNavbar(currentIndex: 0)
                  : null,
    );
  }
}
