import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/user_profile_cubit.dart';
import 'package:zecorner/core/cubit/user_profile_state.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/infrastructure/award/award_repository.dart';
import 'package:zecorner/models/award/award_filter_options.dart';
import 'package:zecorner/models/award/reward_model.dart';

class AwardScreen extends StatefulWidget {
  const AwardScreen({super.key});

  @override
  State<AwardScreen> createState() => _AwardScreenState();
}

class _AwardScreenState extends State<AwardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AwardRepository _awardRepository = AwardRepository();
  
  String _selectedAwardTitle = AwardRepository.defaultAwardTitle;
  DateTime? _startDate;
  DateTime? _endDate;
  
  List<RewardModel> _awardResults = [];
  bool _isContactGroup = false;
  bool _isLoading = false;
  bool _filterSettled = false;
  String? _errorMessage;
  int _filterRequestId = 0;

  /// Admin tüm sıralamayı görür; diğer kullanıcılar yalnızca kendi satırını.
  bool _isAdmin = false;
  int? _userOfficeId;
  int? _userContactNo;
  bool _identityLoaded = false;

  @override
  void initState() {
    super.initState();
    _startDate = _defaultStartDate();
    _endDate = _defaultEndDate();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeDateFormatting();
      await _loadUserIdentity();
      if (mounted) {
        _applyFilters();
      }
    });
  }

  /// Web `startOf('year')` / `endOf('year')`.
  DateTime _defaultStartDate() {
    final year = DateTime.now().year;
    return DateTime(year, 1, 1);
  }

  DateTime _defaultEndDate() {
    final year = DateTime.now().year;
    return DateTime(year, 12, 31);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _loadUserIdentity() async {
    try {
      final authCubit = context.read<AuthCubit>();
      UserProfileCubit? profileCubit;
      try {
        profileCubit = context.read<UserProfileCubit>();
      } catch (_) {
        profileCubit = null;
      }

      final roleCodes = await authCubit.getUserRoleCodes();
      var isAdmin = roleCodes.contains('role_admin') || authCubit.isAdmin;

      int? officeId = await authCubit.getStoredOfficeId();
      officeId ??= await authCubit.getOfficeId();

      int? contactNo = await authCubit.getStoredAdvisorId();
      contactNo ??= await authCubit.getAdvisorId();

      final prefs = await SharedPreferences.getInstance();
      final prefsContact = int.tryParse(prefs.getString('userID') ?? '');
      if ((contactNo == null || contactNo == 0) &&
          prefsContact != null &&
          prefsContact > 0) {
        contactNo = prefsContact;
      }

      if (profileCubit != null) {
        try {
          if (profileCubit.state is! UserProfileLoaded) {
            await profileCubit.loadUserProfile();
          }
          if (profileCubit.state is UserProfileLoaded) {
            final profile =
                (profileCubit.state as UserProfileLoaded).userProfile;
            isAdmin = isAdmin ||
                profile.isAdmin ||
                profile.roles.any(
                  (r) => r.code == 'role_admin' || r.isAdmin,
                );
            if ((contactNo == null || contactNo == 0) &&
                profile.contactNo > 0) {
              contactNo = profile.contactNo;
            }
            if ((officeId == null || officeId == 0) &&
                profile.connectedContact > 0) {
              officeId = profile.connectedContact;
            }
          }
        } catch (_) {
          // Profil yoksa prefs / auth bilgisiyle devam et
        }
      }

      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _userOfficeId = officeId;
        _userContactNo = contactNo;
        _identityLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _identityLoaded = true;
      });
    }
  }

  bool _isOwnReward(RewardModel reward) {
    if (_isContactGroup) {
      final contactNo = _userContactNo;
      if (contactNo == null || contactNo <= 0) return false;
      return reward.contactNo == contactNo;
    }
    final officeId = _userOfficeId;
    if (officeId == null || officeId <= 0) return false;
    return reward.officeNo == officeId;
  }

  /// Admin: tüm liste. Diğerleri: yalnızca kendi sırası (gerçek sıra numarası korunur).
  List<({int rank, RewardModel reward})> get _displayRows {
    if (_isAdmin) {
      return [
        for (var i = 0; i < _awardResults.length; i++)
          (rank: i + 1, reward: _awardResults[i]),
      ];
    }
    final index = _awardResults.indexWhere(_isOwnReward);
    if (index < 0) return [];
    return [(rank: index + 1, reward: _awardResults[index])];
  }

  String get _emptyStateTitle {
    if (!_identityLoaded) return 'Yükleniyor...';
    if (_awardResults.isEmpty) {
      return _filterSettled ? 'Sonuç bulunamadı' : 'Henüz sonuç bulunmuyor';
    }
    if (!_isAdmin) return 'Sıralamada yeriniz yok';
    return 'Henüz sonuç bulunmuyor';
  }

  String get _emptyStateMessage {
    if (!_identityLoaded) {
      return 'Kullanıcı bilgileri kontrol ediliyor';
    }
    if (_awardResults.isEmpty) {
      return _filterSettled
          ? 'Seçili tarih aralığı ve ödül başlığı için sonuç yok. Filtreyi değiştirip tekrar deneyin.'
          : 'Filtreleme yaparak sonuçları görüntüleyebilirsiniz';
    }
    if (!_isAdmin) {
      return 'Bu filtrede sıralamada görünmüyorsunuz. Yalnızca kendi sıranızı görebilirsiniz.';
    }
    return 'Filtreleme yaparak sonuçları görüntüleyebilirsiniz';
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('tr_TR', null);
  }

  void _pickDate({
    required BuildContext pickerContext,
    required DateTime currentTime,
    required ValueChanged<DateTime> onConfirm,
  }) {
    DatePicker.showDatePicker(
      pickerContext,
      showTitleActions: true,
      minTime: DateTime(2020, 1, 1),
      maxTime: DateTime(2030, 12, 31),
      currentTime: currentTime,
      locale: LocaleType.tr,
      onConfirm: onConfirm,
    );
  }

  void _showAwardTitlePicker({
    required BuildContext pickerContext,
    required String currentTitle,
    required ValueChanged<String> onSelected,
  }) {
    String optionSearch = '';

    showModalBottomSheet(
      context: pickerContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = optionSearch.trim().toLowerCase();
            final titles = AwardFilterOptions.titles
                .where((t) => query.isEmpty || t.toLowerCase().contains(query))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Ödül Başlığı',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D2E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                          color: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: TextField(
                      onChanged: (v) =>
                          setSheetState(() => optionSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE53935),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: titles.length,
                      itemBuilder: (context, index) {
                        final title = titles[index];
                        final isSelected = currentTitle == title;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                if (title != currentTitle) {
                                  onSelected(title);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE53935)
                                            .withOpacity(0.35)
                                        : const Color(0xFFE5E7EB),
                                  ),
                                  color: isSelected
                                      ? const Color(0xFFFFEBEE)
                                      : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.emoji_events_rounded,
                                      size: 20,
                                      color: isSelected
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFFE53935)
                                              : const Color(0xFF1A1D2E),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                  ],
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
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    var draftTitle = _selectedAwardTitle;
    var draftStart = _startDate;
    var draftEnd = _endDate;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final maxHeight = MediaQuery.of(context).size.height * 0.86;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxHeight),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Color(0xFFE53935),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Filtrele',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1D2E),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  draftTitle =
                                      AwardRepository.defaultAwardTitle;
                                  draftStart = _defaultStartDate();
                                  draftEnd = _defaultEndDate();
                                });
                              },
                              child: const Text(
                                'Sıfırla',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF6B7280),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Ödül Başlığı'),
                              const SizedBox(height: 8),
                              _modernTapField(
                                onTap: () => _showAwardTitlePicker(
                                  pickerContext: context,
                                  currentTitle: draftTitle,
                                  onSelected: (title) => setSheetState(
                                    () => draftTitle = title,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.military_tech_rounded,
                                      size: 18,
                                      color: Color(0xFFE53935),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        draftTitle,
                                        style: const TextStyle(
                                          color: Color(0xFF1A1D2E),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFFE53935),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('Başlangıç'),
                                        const SizedBox(height: 8),
                                        _modernTapField(
                                          onTap: () => _pickDate(
                                            pickerContext: context,
                                            currentTime:
                                                draftStart ?? DateTime.now(),
                                            onConfirm: (picked) {
                                              final day = _dateOnly(picked);
                                              setSheetState(() {
                                                draftStart = day;
                                                if (draftEnd != null &&
                                                    day.isAfter(draftEnd!)) {
                                                  draftEnd = day;
                                                }
                                              });
                                            },
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _formatDate(draftStart),
                                                  style: TextStyle(
                                                    color: draftStart != null
                                                        ? const Color(0xFF1A1D2E)
                                                        : const Color(0xFF9CA3AF),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.calendar_month_rounded,
                                                size: 18,
                                                color: Color(0xFFE53935),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('Bitiş'),
                                        const SizedBox(height: 8),
                                        _modernTapField(
                                          onTap: () => _pickDate(
                                            pickerContext: context,
                                            currentTime:
                                                draftEnd ?? DateTime.now(),
                                            onConfirm: (picked) {
                                              final day = _dateOnly(picked);
                                              setSheetState(() {
                                                draftEnd = day;
                                                if (draftStart != null &&
                                                    day.isBefore(draftStart!)) {
                                                  draftStart = day;
                                                }
                                              });
                                            },
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _formatDate(draftEnd),
                                                  style: TextStyle(
                                                    color: draftEnd != null
                                                        ? const Color(0xFF1A1D2E)
                                                        : const Color(0xFF9CA3AF),
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.calendar_month_rounded,
                                                size: 18,
                                                color: Color(0xFFE53935),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              var start = draftStart == null
                                  ? null
                                  : _dateOnly(draftStart!);
                              var end = draftEnd == null
                                  ? null
                                  : _dateOnly(draftEnd!);
                              if (start != null &&
                                  end != null &&
                                  start.isAfter(end)) {
                                final swap = start;
                                start = end;
                                end = swap;
                              }
                              setState(() {
                                _selectedAwardTitle = draftTitle;
                                _startDate = start;
                                _endDate = end;
                              });
                              Navigator.pop(sheetContext);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Filtrele',
                                  style: TextStyle(
                                    fontSize: 15.5,
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tarih Seçiniz';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  double? _tryParseAmount(String raw) {
    final trimmed = raw.trim();
    final direct = double.tryParse(trimmed);
    if (direct != null) return direct;
    if (trimmed.contains(',') && trimmed.contains('.')) {
      return double.tryParse(trimmed.replaceAll('.', '').replaceAll(',', '.'));
    }
    if (trimmed.contains(',') && !trimmed.contains('.')) {
      return double.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  String _formatPrice(String price) {
    final priceValue = _tryParseAmount(price);
    if (priceValue == null) return price;
    try {
      return NumberFormat('#,##0.00', 'tr_TR').format(priceValue);
    } catch (_) {
      final negative = priceValue < 0;
      final parts = priceValue.abs().toStringAsFixed(2).split('.');
      final digits = parts[0];
      final buffer = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
        buffer.write(digits[i]);
      }
      final formatted = '$buffer,${parts[1]}';
      return negative ? '-$formatted' : formatted;
    }
  }

  Future<void> _applyFilters({bool keepPrevious = false}) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen başlangıç ve bitiş tarihlerini seçiniz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    var startDate = _dateOnly(_startDate!);
    var endDate = _dateOnly(_endDate!);
    if (startDate.isAfter(endDate)) {
      final swap = startDate;
      startDate = endDate;
      endDate = swap;
    }

    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _isLoading = true;
      _errorMessage = null;
      if (!keepPrevious) {
        _awardResults = [];
        _isContactGroup = false;
      }
    });

    final requestId = ++_filterRequestId;

    try {
      final awardTitle = _selectedAwardTitle;
      final result = await _awardRepository.getRewards(
        startDate: startDate,
        endDate: endDate,
        awardTitle: awardTitle,
      );

      if (!mounted || requestId != _filterRequestId) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _filterSettled = true;
            _errorMessage = failure.message;
            _awardResults = [];
          });
        },
        (response) {
          final rewards = List<RewardModel>.from(response.rewards);
          rewards.sort((a, b) {
            final aTotal = _tryParseAmount(a.total) ?? 0;
            final bTotal = _tryParseAmount(b.total) ?? 0;
            return bTotal.compareTo(aTotal);
          });
          setState(() {
            _isLoading = false;
            _filterSettled = true;
            _isContactGroup = response.isContactGroup;
            _awardResults = rewards;
          });
        },
      );
    } catch (e) {
      if (!mounted || requestId != _filterRequestId) return;
      setState(() {
        _isLoading = false;
        _filterSettled = true;
        _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
        _awardResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _displayRows;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F8),
      drawer: RoleSidebar(currentPage: 'Ödül Sistemi'),
      appBar: AdminPanelAppBar(
        title: 'Ödül Sistemi',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading && _awardResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    ),
                  )
                : _errorMessage != null && _awardResults.isEmpty
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: () => _applyFilters(keepPrevious: true),
                        color: const Color(0xFFE53935),
                        child: !_identityLoaded || rows.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height * 0.18,
                                  ),
                                  _buildEmptyState(),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: rows.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _buildLeaderboardHeader(
                                      count: rows.length,
                                    );
                                  }
                                  final row = rows[index - 1];
                                  final result = row.reward;
                                  return _buildRankCard(
                                    rank: row.rank,
                                    primary: result.displayPrimary(
                                      isContactGroup: _isContactGroup,
                                    ),
                                    secondary: result.displaySecondary(
                                      isContactGroup: _isContactGroup,
                                    ),
                                    total: _formatPrice(result.total),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminNavbar(currentIndex: 0, onTap: null),
    );
  }

  Widget _buildFilterBar() {
    final dateLabel = _startDate != null && _endDate != null
        ? '${_formatDate(_startDate)}  –  ${_formatDate(_endDate)}'
        : 'Tarih seçiniz';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _showFilterSheet,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liderlik Tablosu',
                        style: TextStyle(
                          color: Color(0xFF1A1D2E),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$_selectedAwardTitle  ·  $dateLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Filtre',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _modernTapField({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLeaderboardHeader({required int count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.leaderboard_rounded,
                  size: 16,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(width: 6),
                Text(
                  _isContactGroup ? 'Kişi Sıralaması' : 'Ofis Sıralaması',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '$count sonuç',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            size: 42,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _emptyStateTitle,
          style: const TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _emptyStateMessage,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildRankCard({
    required int rank,
    required String primary,
    required String? secondary,
    required String total,
  }) {
    final isTopThree = rank <= 3;
    final medal = _medalForRank(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTopThree
              ? medal.accent.withOpacity(0.35)
              : const Color(0xFFE5E7EB),
          width: isTopThree ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? medal.accent.withOpacity(0.12)
                : Colors.black.withOpacity(0.035),
            blurRadius: isTopThree ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: isTopThree
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  medal.accent.withOpacity(0.08),
                  Colors.white,
                ],
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  medal.accent,
                  medal.accentDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: medal.accent.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(medal.icon, color: Colors.white, size: 22)
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank <= 3)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      medal.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: medal.accentDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                Text(
                  primary,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary != null && secondary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          secondary,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺$total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: rank == 1
                      ? const Color(0xFFB45309)
                      : const Color(0xFF1A1D2E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _MedalStyle _medalForRank(int rank) {
    switch (rank) {
      case 1:
        return const _MedalStyle(
          accent: Color(0xFFFBBF24),
          accentDark: Color(0xFFD97706),
          icon: Icons.workspace_premium_rounded,
          label: '1. ALTIN',
        );
      case 2:
        return const _MedalStyle(
          accent: Color(0xFF94A3B8),
          accentDark: Color(0xFF64748B),
          icon: Icons.military_tech_rounded,
          label: '2. GÜMÜŞ',
        );
      case 3:
        return const _MedalStyle(
          accent: Color(0xFFD97706),
          accentDark: Color(0xFF92400E),
          icon: Icons.emoji_events_rounded,
          label: '3. BRONZ',
        );
      default:
        return const _MedalStyle(
          accent: Color(0xFF9CA3AF),
          accentDark: Color(0xFF6B7280),
          icon: Icons.circle,
          label: '',
        );
    }
  }
}

class _MedalStyle {
  final Color accent;
  final Color accentDark;
  final IconData icon;
  final String label;

  const _MedalStyle({
    required this.accent,
    required this.accentDark,
    required this.icon,
    required this.label,
  });
}

