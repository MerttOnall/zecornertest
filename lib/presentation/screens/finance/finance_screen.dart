import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/finance_cubit.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/infrastructure/finance/finance_api_repository.dart';
import 'package:zecorner/models/finance/finance_record_model.dart';
import 'package:zecorner/models/finance/finance_type_model.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:flutter/services.dart';

/// Web ile aynı: `32.000` / `32.000,50` → API için double.
double? _parseTurkishMoneyInput(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final normalized = t.replaceAll('.', '').replaceAll(',', '.');
  if (normalized.isEmpty || normalized == '.') return null;
  return double.tryParse(normalized);
}

/// Yazarken binlik `.`, ondalık `,` (en fazla 2 basamak).
class _TurkishCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    var raw = newValue.text.replaceAll(RegExp(r'\s'), '').replaceAll('.', '');

    final buf = StringBuffer();
    var commaSeen = false;
    var fracCount = 0;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c == ',') {
        if (!commaSeen) {
          commaSeen = true;
          buf.write(',');
        }
        continue;
      }
      final isDigit = c.compareTo('0') >= 0 && c.compareTo('9') <= 0;
      if (!isDigit) continue;

      if (commaSeen) {
        if (fracCount < 2) {
          buf.write(c);
          fracCount++;
        }
      } else {
        buf.write(c);
      }
    }
    raw = buf.toString();

    if (raw.isEmpty) {
      return const TextEditingValue();
    }

    final parts = raw.split(',');
    var intStr = parts[0];
    final hasComma = parts.length > 1;
    var frac = hasComma ? parts[1] : '';
    final trailingComma = hasComma && frac.isEmpty;

    if (frac.length > 2) {
      frac = frac.substring(0, 2);
    }

    intStr = intStr.replaceFirst(RegExp(r'^0+'), '');
    if (intStr.isEmpty) {
      intStr = '0';
    }

    String withThousands(String digits) {
      if (digits.isEmpty) return '0';
      final rev = digits.split('').reversed.join();
      final sb = StringBuffer();
      for (var i = 0; i < rev.length; i++) {
        if (i > 0 && i % 3 == 0) {
          sb.write('.');
        }
        sb.write(rev[i]);
      }
      return sb.toString().split('').reversed.join();
    }

    final intFmt = withThousands(intStr);

    final display = trailingComma
        ? '$intFmt,'
        : frac.isNotEmpty
            ? '$intFmt,$frac'
            : intFmt;

    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}

const Color _financeExpenseAccent = Color(0xFFE53935);
const Color _financeExpenseAccentFocus = Color.fromRGBO(238, 46, 36, 1);

InputDecoration financeAddExpensePlainFieldDecoration({
  required String hint,
  Widget? prefixIcon,
  String? prefixText,
  TextStyle? prefixStyle,
}) {
  const fill = Color(0xFFFFFFFF);
  final borderRadius = BorderRadius.circular(12);
  final idle = OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    prefixStyle: prefixStyle,
    prefixIconConstraints: prefixIcon != null
        ? const BoxConstraints(minWidth: 48, minHeight: 48)
        : null,
    floatingLabelBehavior: FloatingLabelBehavior.never,
    isCollapsed: false,
    hintStyle: TextStyle(
      color: Colors.grey.shade500,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.25,
    ),
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: idle,
    enabledBorder: idle,
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _financeExpenseAccentFocus, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _financeExpenseAccent, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _financeExpenseAccent, width: 2),
    ),
  );
}

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({Key? key}) : super(key: key);

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  String _selectedFilter = 'Tümü';
  final ScrollController _scrollController = ScrollController();
  late FinanceCubit _financeCubit;

  @override
  void initState() {
    super.initState();
    _financeCubit = FinanceCubit(FinanceApiRepository());
    _financeCubit.loadFinanceTypes();
    _financeCubit.loadFinanceRecords(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _financeCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _financeCubit.loadMoreRecords();
    }
  }

  String formatAmount(double amount) {
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    return formatter.format(amount);
  }

  Color _getTypeColor(FinanceRecord record) {
    return record.isExpense || record.amountAsDouble < 0
        ? const Color(0xFFFFE5E5)
        : const Color(0xFFE6F4EA);
  }

  IconData _getTypeIcon(FinanceRecord record) {
    return record.isExpense || record.amountAsDouble < 0
        ? Icons.arrow_downward
        : Icons.arrow_upward;
  }

  Color _getTypeTextColor(FinanceRecord record) {
    return record.isExpense || record.amountAsDouble < 0
        ? const Color(0xFFE53935)
        : const Color(0xFF2E7D32);
  }

  /// Bu ekranda: giriş yapmış her kullanıcıya “Gider Ekle” (sidebar’da Finans = `any` ile uyumlu).
  Widget _financeFilterRow(BuildContext context, {required bool showAddExpense}) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedFilter,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            dropdownColor: Colors.white,
            items: const [
              DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
              DropdownMenuItem(value: 'Gelir', child: Text('Gelir')),
              DropdownMenuItem(value: 'Gider', child: Text('Gider')),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _selectedFilter = v;
                });
                _financeCubit.filterRecords(v);
              }
            },
          ),
        ),
        if (showAddExpense) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              elevation: 0,
            ),
            onPressed: () => _showAddExpenseDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Gider Ekle',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _financeCubit,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF3F6FB),
        // Role sistemine göre sidebar seçimi
        drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
            // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
            return RoleSidebar(currentPage: 'Finans');
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
          title: 'Hesap Cüzdanım',
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: GestureDetector(
          onTap: () {
            if (_isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          child: AbsorbPointer(
            absorbing: _isDrawerOpen,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final showAdd =
                            authState is AuthAuthenticated;
                        return _financeFilterRow(
                          context,
                          showAddExpense: showAdd,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Hesap Hareketleri',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: Color.fromRGBO(238, 46, 36, 1),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: BlocConsumer<FinanceCubit, FinanceState>(
                      listener: (context, state) {
                        if (state is FinanceError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.failure.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is FinanceLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                            ),
                          );
                        }

                        List<FinanceRecord> records;
                        if (state is FinanceLoaded) {
                          records = state.allRecords;
                        } else {
                          records = const [];
                        }

                        if (state is FinanceLoaded) {
                          if (records.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Henüz kayıt bulunmuyor',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () => _financeCubit.refreshRecords(),
                            color: const Color(0xFFE53935),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              itemCount: records.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final record = records[index];
                                final typeLabel = record.typeDescription.trim().isNotEmpty
                                    ? record.typeDescription
                                    : record.type;
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  elevation: 4,
                                  shadowColor: Colors.blueGrey.withOpacity(0.08),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(record),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: Icon(
                                            _getTypeIcon(record),
                                            color: _getTypeTextColor(record),
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.displayDescription,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getTypeColor(record),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  typeLabel,
                                                  style: TextStyle(
                                                    color: _getTypeTextColor(record),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                  record.createdAt.toLocal(),
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          formatAmount(record.amountAsDouble),
                                          style: TextStyle(
                                            color: _getTypeTextColor(record),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        } else if (state is FinanceError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 80,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.failure.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _financeCubit.loadFinanceRecords(refresh: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                  ),
                                  child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final userRoleCodes = snapshot.data ?? [];
                  print('Finance Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                  
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
      ),
    );
  }

  /// Gider tipi için Material dropdown yerine mobil uyumlu seçim sayfası.
  Future<String?> _pickExpenseType(
    BuildContext context,
    List<FinanceType> types,
    String? currentCode,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        final maxH = MediaQuery.sizeOf(ctx).height * 0.55;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxH),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gider tipi seçin',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade700,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Listeden bir gider kategorisi seçin',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
                    itemCount: types.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = types[index];
                      final selected = t.code == currentCode;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(t.code),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF5F5)
                                  : const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? _financeExpenseAccent : Colors.grey.shade200,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? _financeExpenseAccent.withValues(alpha: 0.12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: selected ? _financeExpenseAccent : Colors.grey.shade600,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    t.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                      color: const Color(0xFF1A1A1A),
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Icon(Icons.check_circle_rounded, color: _financeExpenseAccent, size: 26)
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.grey.shade400,
                                    size: 26,
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
        );
      },
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final auth = context.read<AuthCubit>();
    if (auth.state is! AuthAuthenticated) {
      return;
    }

    if (!context.mounted) return;

    final expenseTypes = _financeCubit.financeTypes
        .where((t) => t.isExpense)
        .toList();

    if (expenseTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gider türleri yüklenemedi veya tanımlı gider türü yok. Sayfayı yenileyip tekrar deneyin.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000),
      builder: (context) => _FinanceAddExpenseSheet(
        financeCubit: _financeCubit,
        expenseTypes: expenseTypes,
        scaffoldMessenger: scaffoldMessenger,
        pickExpenseType: _pickExpenseType,
      ),
    );
    // Sheet tamamen kapandıktan sonra yenile — sunucudaki son kayıt listeye düşsün.
    if (!mounted) return;
    if (added == true) {
      await _financeCubit.refreshRecords();
    }
  }
}

class _FinanceAddExpenseSheet extends StatefulWidget {
  const _FinanceAddExpenseSheet({
    required this.financeCubit,
    required this.expenseTypes,
    required this.scaffoldMessenger,
    required this.pickExpenseType,
  });

  final FinanceCubit financeCubit;
  final List<FinanceType> expenseTypes;
  final ScaffoldMessengerState scaffoldMessenger;
  final Future<String?> Function(
    BuildContext context,
    List<FinanceType> types,
    String? currentCode,
  ) pickExpenseType;

  @override
  State<_FinanceAddExpenseSheet> createState() => _FinanceAddExpenseSheetState();
}

class _FinanceAddExpenseSheetState extends State<_FinanceAddExpenseSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _desc;
  String? _type;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    _formKey.currentState!.save();
    final amountValue = _parseTurkishMoneyInput(_amountController.text) ?? 0.0;
    setState(() => _submitting = true);
    final Failure? fail = await widget.financeCubit.addExpense(
      description: _desc!.trim(),
      amount: amountValue,
      type: _type!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (fail != null) {
      widget.scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(fail.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Kaydedildi'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final viewportH = screenH - viewInsets.bottom;
    final scrollMaxH = (viewInsets.bottom > 0 ? viewportH * 0.48 : screenH * 0.40)
        .clamp(160.0, 340.0);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          elevation: 6,
          shadowColor: Colors.black26,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 10, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Gider Ekle',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Material(
                      color: _financeExpenseAccent,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: scrollMaxH),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormField<String>(
                          initialValue: _type,
                          onSaved: (v) => _type = v,
                          validator: (v) => v == null ? 'Gider tipi seçin' : null,
                          builder: (fieldState) {
                            FinanceType? selectedType;
                            for (final t in widget.expenseTypes) {
                              if (t.code == fieldState.value) {
                                selectedType = t;
                                break;
                              }
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final code = await widget.pickExpenseType(
                                        context,
                                        widget.expenseTypes,
                                        fieldState.value,
                                      );
                                      if (code != null && mounted) {
                                        fieldState.didChange(code);
                                        setState(() => _type = code);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: financeAddExpensePlainFieldDecoration(
                                        hint: 'Gider tipi seçin',
                                      ).copyWith(
                                        errorText: fieldState.errorText,
                                      ),
                                      isEmpty: fieldState.value == null,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: selectedType == null
                                                ? const SizedBox(height: 22)
                                                : Text(
                                                    selectedType.description,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      height: 1.25,
                                                      color: Color(0xFF1A1A1A),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.grey.shade700,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: financeAddExpensePlainFieldDecoration(
                            hint: 'Açıklama yazın',
                          ),
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          onSaved: (v) => _desc = v,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Açıklama girin' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amountController,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                          decoration: financeAddExpensePlainFieldDecoration(
                            hint: 'Örn. 32.000',
                          ).copyWith(
                            prefixText: '₺ ',
                            prefixStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              height: 1.25,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            _TurkishCurrencyInputFormatter(),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Tutar girin';
                            }
                            final n = _parseTurkishMoneyInput(v);
                            if (n == null || n <= 0) {
                              return 'Geçerli tutar girin';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ColoredBox(
                color: const Color(0xFFF7F8FA),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + padding.bottom),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _financeExpenseAccent,
                            disabledBackgroundColor:
                                _financeExpenseAccent.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'EKLE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                        ),
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
