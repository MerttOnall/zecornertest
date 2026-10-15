import 'package:flutter/material.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/rapor/rapor_repository.dart';
import 'package:zecorner/models/rapor/broker_row_model.dart';
import 'package:zecorner/models/rapor/rapor_row_model.dart';
import 'package:zecorner/presentation/screens/reports/report_empty_state.dart';
import 'package:zecorner/presentation/screens/reports/report_theme.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

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

class GeneralReportPanel extends StatefulWidget {
  const GeneralReportPanel({super.key});

  @override
  State<GeneralReportPanel> createState() => _GeneralReportPanelState();
}

class _GeneralReportPanelState extends State<GeneralReportPanel> {
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

  (String, String) _getDateRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return (
      '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
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
        final list = await _raporRepo.getAdminListings(
          RaporListParams(
            startDate: startDate,
            endDate: endDate,
            type: _kapsamDanisman ? 'advisor' : 'office',
            state: raporTuruToState(_selectedRaporTuru),
            page: 1,
            pageSize: 9999,
          ),
        );
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
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ReportTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRaporTuru,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    items: _raporTuruOptions
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedRaporTuru = v);
                    },
                  ),
                ),
              ),
              if (!_isTumBrokerlar) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ReportTheme.surface,
                    borderRadius: BorderRadius.circular(12),
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
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadReport,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(_isLoading ? 'Yükleniyor…' : 'Raporu Getir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ReportTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const AppStatusView.loading(
                  title: 'Rapor hazırlanıyor',
                  message: 'Seçilen rapor türü yükleniyor.',
                )
              : _loadError != null
                  ? AppStatusView.error(
                      message: _loadError!,
                      onRetry: _loadReport,
                    )
                  : (_isTumBrokerlar ? _brokerRows.isEmpty : _rows.isEmpty)
                      ? const ReportEmptyState(
                          icon: Icons.assessment_outlined,
                          title: 'Rapor Bulunamadı',
                          message: 'Bu rapor türünde gösterilecek veri yok.',
                        )
                      : RefreshIndicator(
                          color: ReportTheme.primary,
                          onRefresh: _loadReport,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: _isTumBrokerlar
                                ? _brokerRows.length
                                : _rows.length,
                            itemBuilder: (context, index) {
                              if (_isTumBrokerlar) {
                                return _BrokerCard(
                                  broker: _brokerRows[index],
                                  rank: index + 1,
                                );
                              }
                              return _ReportCard(
                                row: _rows[index],
                                rank: index + 1,
                              );
                            },
                          ),
                        ),
        ),
      ],
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
      color: selected ? ReportTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : ReportTheme.textSecondary,
              fontWeight: FontWeight.w600,
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

  const _ReportCard({required this.row, required this.rank});

  @override
  Widget build(BuildContext context) {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ReportTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
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
                  row.officeOrConsultant.isNotEmpty
                      ? row.officeOrConsultant
                      : '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ReportTheme.textPrimary,
                  ),
                ),
                if (row.consultant.isNotEmpty)
                  Text(
                    row.consultant,
                    style: const TextStyle(
                      color: ReportTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ReportTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${row.count}',
              style: const TextStyle(
                color: ReportTheme.primary,
                fontWeight: FontWeight.w700,
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

  const _BrokerCard({required this.broker, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ReportTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$rank',
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
                  broker.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ReportTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  broker.tcVergiDisplay,
                  style: const TextStyle(
                    color: ReportTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (broker.email.isNotEmpty || broker.tel.isNotEmpty)
                  Text(
                    [broker.email, broker.tel]
                        .where((e) => e.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(
                      color: ReportTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (broker.connectedContactTitle?.isNotEmpty == true)
                  Text(
                    broker.connectedContactTitle!,
                    style: const TextStyle(
                      color: ReportTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
