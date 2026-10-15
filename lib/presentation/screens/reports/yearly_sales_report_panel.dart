import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/reports/reports_api_repository.dart';
import 'package:zecorner/models/reports/yearly_sales_report_model.dart';
import 'package:zecorner/presentation/screens/reports/report_empty_state.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class YearlySalesReportPanel extends StatefulWidget {
  const YearlySalesReportPanel({super.key});

  @override
  State<YearlySalesReportPanel> createState() => _YearlySalesReportPanelState();
}

class _YearlySalesReportPanelState extends State<YearlySalesReportPanel> {
  final ReportsApiRepository _repository = ReportsApiRepository();
  final TextEditingController _searchController = TextEditingController();

  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;
  String? _errorMessage;
  YearlySalesReportModel? _report;
  int? _expandedAdvisor;

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
      final data = await _repository.getYearlySalesReport(year: _selectedYear);
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

  List<double> get _monthlyTotals =>
      _report?.monthlyTotals ?? List<double>.filled(12, 0);

  List<int> get _monthlyCounts =>
      _report?.monthlyCounts ?? List<int>.filled(12, 0);

  List<YearlyAdvisorRow> get _visibleRows {
    final rows = List<YearlyAdvisorRow>.from(_report?.rows ?? []);
    rows.sort((a, b) => b.yearTotal.compareTo(a.yearTotal));
    final q = reportFold(_searchController.text.trim());
    if (q.isEmpty) {
      return rows.where((row) => row.yearTotal > 0 || row.yearCount > 0).toList();
    }
    return rows.where((row) {
      final haystack = reportFold('${row.advisorTitle} ${row.officeTitle}');
      return haystack.contains(q);
    }).toList();
  }

  List<int> get _yearOptions {
    final current = DateTime.now().year;
    return List.generate(6, (i) => current - i);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppStatusView.loading(
        title: 'Yıllık rapor hazırlanıyor',
        message: 'Aylık satış dağılımı hesaplanıyor.',
      );
    }

    if (_errorMessage != null) {
      return AppStatusView.error(
        message: _errorMessage!,
        onRetry: _load,
      );
    }

    final monthly = _monthlyTotals;
    final counts = _monthlyCounts;
    final maxY = monthly.fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxY <= 0 ? 1.0 : maxY * 1.2;
    final rows = _visibleRows;
    final report = _report;

    return RefreshIndicator(
      color: ReportTheme.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReportTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Yıl Seçimi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ReportTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: ReportTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: ReportTheme.primary,
                          ),
                          items: _yearOptions
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    '$y',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ReportTheme.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (year) {
                            if (year == null) return;
                            setState(() => _selectedYear = year);
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ReportTheme.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Danışman veya ofis ara...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: ReportTheme.primary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Yıllık Net',
                  value: formatReportAmount(report?.total ?? 0),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'İşlem',
                  value: '${report?.count ?? 0}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Danışman',
                  value: '${report?.advisorCount ?? 0}',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Ofis',
                  value: '${report?.officeCount ?? 0}',
                  icon: Icons.apartment_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ReportTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'Aylık Net Kazanç',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ReportTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      maxY: chartMax,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: ReportTheme.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = [
                                'O',
                                'Ş',
                                'M',
                                'N',
                                'M',
                                'H',
                                'T',
                                'A',
                                'E',
                                'E',
                                'K',
                                'A',
                              ];
                              final i = value.toInt();
                              if (i < 0 || i > 11) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  labels[i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ReportTheme.textMuted,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: monthly[i],
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              color: ReportTheme.primary,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aylık Özet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ReportTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(12, (i) {
            if (monthly[i] <= 0 && counts[i] <= 0) {
              return const SizedBox.shrink();
            }
            final monthName = DateFormat(
              'MMMM',
              'tr_TR',
            ).format(DateTime(_selectedYear, i + 1));
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ReportTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: ReportTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: ReportTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ReportTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${counts[i]} işlem',
                          style: const TextStyle(
                            color: ReportTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatReportAmount(monthly[i]),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ReportTheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            'Danışman Performansı',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ReportTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: ReportEmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Satış Bulunamadı',
                message: 'Seçilen yılda kayıtlı satış bulunamadı.',
              ),
            )
          else
            ...rows.map((row) {
              final expanded = _expandedAdvisor == row.advisor;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ReportTheme.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedAdvisor =
                              expanded ? null : row.advisor;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.advisorTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ReportTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    row.officeTitle,
                                    style: const TextStyle(
                                      color: ReportTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${row.yearCount} işlem',
                                    style: const TextStyle(
                                      color: ReportTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatReportAmount(row.yearTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ReportTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: ReportTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (expanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: row.months
                              .where((m) => m.total > 0 || m.count > 0)
                              .map((month) {
                            final name = DateFormat(
                              'MMMM',
                              'tr_TR',
                            ).format(DateTime(_selectedYear, month.month));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: ReportTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${month.count} işlem',
                                    style: const TextStyle(
                                      color: ReportTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatReportAmount(month.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ReportTheme.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ReportTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReportTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
