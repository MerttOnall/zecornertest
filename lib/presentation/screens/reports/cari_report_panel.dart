import 'package:flutter/material.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/reports/reports_api_repository.dart';
import 'package:zecorner/models/reports/cari_report_model.dart';
import 'package:zecorner/presentation/screens/reports/report_empty_state.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class CariReportPanel extends StatefulWidget {
  const CariReportPanel({super.key});

  @override
  State<CariReportPanel> createState() => _CariReportPanelState();
}

class _CariReportPanelState extends State<CariReportPanel> {
  final ReportsApiRepository _repository = ReportsApiRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  CariReportModel? _report;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getOfficeCurrentAccount();
      if (!mounted) return;
      setState(() {
        _report = data;
        _isLoading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _report = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        _report = null;
      });
    }
  }

  List<CariAccountRow> get _accounts {
    final list = List<CariAccountRow>.from(_report?.accounts ?? []);
    list.sort((a, b) => b.remainingBalance.compareTo(a.remainingBalance));
    final q = reportFold(_searchController.text.trim());
    if (q.isEmpty) return list;
    return list.where((account) {
      final haystack = reportFold(
        '${account.officeTitle} ${account.tradeName} ${account.officeContactNo}',
      );
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppStatusView.loading(
        title: 'Cari rapor hazırlanıyor',
        message: 'Ofis cari bakiyeleri yükleniyor.',
      );
    }

    if (_errorMessage != null) {
      return AppStatusView.error(
        message: _errorMessage!,
        onRetry: _load,
      );
    }

    final accounts = _accounts;
    final invoiceTotal = accounts.fold<double>(
      0,
      (sum, row) => sum + row.totalInvoiceAmount,
    );
    final balanceTotal = accounts.fold<double>(
      0,
      (sum, row) => sum + row.remainingBalance,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 15,
                  color: ReportTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ofis veya ticari unvan ara',
                  hintStyle: const TextStyle(
                    color: ReportTheme.textMuted,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: ReportTheme.textMuted,
                    size: 22,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SummaryBar(
                invoice: formatReportAmount(invoiceTotal),
                balance: formatReportAmount(balanceTotal),
                officeCount: accounts.length,
                balanceOpen: balanceTotal > 0,
              ),
            ],
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? const ReportEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Kayıt bulunamadı',
                  message: 'Bu aramaya uygun ofis cari hesabı yok.',
                )
              : RefreshIndicator(
                  color: ReportTheme.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _CariCard(account: accounts[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final String invoice;
  final String balance;
  final int officeCount;
  final bool balanceOpen;

  const _SummaryBar({
    required this.invoice,
    required this.balance,
    required this.officeCount,
    required this.balanceOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D2E).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _SummaryFigure(
                label: 'Fatura tutarı',
                value: invoice,
                caption: '$officeCount ofis',
              ),
            ),
            const VerticalDivider(
              width: 28,
              thickness: 1,
              color: ReportTheme.border,
            ),
            Expanded(
              child: _SummaryFigure(
                label: 'Kalan bakiye',
                value: balance,
                valueColor: balanceOpen
                    ? ReportTheme.primary
                    : ReportTheme.soldFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryFigure extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  const _SummaryFigure({
    required this.label,
    required this.value,
    this.caption,
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
            color: ReportTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? ReportTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: const TextStyle(
              color: ReportTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class _CariCard extends StatelessWidget {
  final CariAccountRow account;

  const _CariCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final settled = account.isSettled;
    final balanceColor = account.remainingBalance > 0
        ? ReportTheme.primary
        : ReportTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D2E).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                      account.officeTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                        color: ReportTheme.textPrimary,
                      ),
                    ),
                    if (account.tradeName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        account.tradeName,
                        style: const TextStyle(
                          color: ReportTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: settled ? ReportTheme.soldBg : ReportTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: settled ? ReportTheme.soldFg : ReportTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      settled ? 'Kapalı' : 'Açık',
                      style: TextStyle(
                        color: settled ? ReportTheme.soldFg : ReportTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Fatura',
                        value: '${account.totalInvoiceCount}',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Açık fatura',
                        value: '${account.openInvoiceCount}',
                        valueColor: account.openInvoiceCount > 0
                            ? ReportTheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'Fatura tutarı',
                        value: formatReportAmount(account.totalInvoiceAmount),
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'Ödenen',
                        value: formatReportAmount(account.totalPaymentAmount),
                        valueColor: ReportTheme.soldFg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (account.lastPaymentDate != null)
                Expanded(
                  child: Text(
                    formatReportDate(account.lastPaymentDate!),
                    style: const TextStyle(
                      color: ReportTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Kalan',
                    style: TextStyle(
                      color: ReportTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatReportAmount(account.remainingBalance),
                    style: TextStyle(
                      color: balanceColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor ?? ReportTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
