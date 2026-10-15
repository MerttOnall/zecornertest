import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/location/ref_location_resolution.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/office_persons/office_persons_api_repository.dart';
import 'package:zecorner/models/office_persons/office_persons_api_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/router/app_router.dart';

const Color _kBrand = Color(0xFFE53935);
const Color _kInk = Color(0xFF1F2937);
const Color _kPageBg = Color(0xFFF0F2F5);
const Color _kSegmentTrack = Color(0xFFE4E6EB);
const Color _kErrorFill = Color(0xFFFFF1F0);

OutlineInputBorder _inputOutline({required Color color, double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

InputDecoration transactionInputDecoration({
  bool hasError = false,
  IconData? suffix,
  String? hintText,
}) {
  final normal = _inputOutline(color: const Color(0xFFE5E7EB));
  final error = _inputOutline(color: _kBrand, width: 1.6);
  final focused = _inputOutline(color: _kBrand, width: 1.5);
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: Colors.grey.shade400,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    ),
    filled: true,
    fillColor: hasError ? _kErrorFill : Colors.grey.shade50,
    border: hasError ? error : normal,
    enabledBorder: hasError ? error : normal,
    focusedBorder: hasError ? error : focused,
    errorBorder: error,
    focusedErrorBorder: error,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix != null
        ? Icon(
            suffix,
            color: hasError ? _kBrand : Colors.grey.shade400,
            size: 22,
          )
        : null,
  );
}
const double _kVatRate = 0.20; // KDV %20
const double _kZecornerRate = 0.07; // Zecorner bedeli = KDV hariç toplamın %7'si

/// Adres ülkeleri (web DEFAULT_ADDRESS_COUNTRY / CT ile uyumlu)
const List<({String code, String name})> _kAddressCountries = [
  (code: 'TR', name: 'Türkiye'),
  (code: 'CT', name: 'Kıbrıs'),
];

/// Diğer işlem bildirimi — mobil öncelikli, tek sütun akışı.
class OtherTransactionstScreen extends StatefulWidget {
  const OtherTransactionstScreen({super.key});

  @override
  State<OtherTransactionstScreen> createState() => _OtherTransactionstScreenState();
}

class _OtherTransactionstScreenState extends State<OtherTransactionstScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;
  bool _highlightInvalidFields = false;

  final TextEditingController _listingPriceController = TextEditingController();
  final TextEditingController _transactionAmountController = TextEditingController();
  final TextEditingController _buyerFeeController = TextEditingController();
  final TextEditingController _sellerFeeController = TextEditingController();

  final TextEditingController _listingTitleController = TextEditingController();
  final TextEditingController _buyerCustomerSearchController = TextEditingController();
  final TextEditingController _sellerCustomerSearchController = TextEditingController();
  final TextEditingController _grossAreaController = TextEditingController();
  final TextEditingController _netAreaController = TextEditingController();

  /// 0: Konut, 1: Ticari, null: henüz seçilmedi
  int? _portfolioKind;
  String? _portfolioSubType;
  String? _listingType;
  String _countryCode = 'TR';
  String _countryName = 'Türkiye';
  String? _province;
  String? _district;
  String? _neighborhood;

  late DateTime _transactionDate;

  final ContactApiRepository _contactApiRepository = ContactApiRepository();
  final OfficePersonsApiRepository _officePersonsRepository =
      OfficePersonsApiRepository();
  ProvincesResponseModel? _provincesModel;
  ProvincesDetailResponseModel? _districtsDetailCache;
  List<String> _provinceOptions = [];
  List<String> _districtOptions = [];
  List<String> _quarterOptions = [];
  bool _refLocationLoading = false;

  List<OfficePersonsApiModel> _officeContacts = [];
  bool _officeContactsLoading = false;
  bool _isPerformerMe = false;
  OfficePersonsApiModel? _selectedPerformer;
  int? _currentUserContactNo;
  OfficePersonsApiModel? _currentUserFallback;

  @override
  void initState() {
    super.initState();
    _transactionDate = DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_syncTabIndex);
    _listingPriceController.addListener(_onFormChanged);
    _transactionAmountController.addListener(_onFormChanged);
    _buyerFeeController.addListener(_onFormChanged);
    _sellerFeeController.addListener(_onFormChanged);
    _listingTitleController.addListener(_onFormChanged);
    _buyerCustomerSearchController.addListener(_onFormChanged);
    _sellerCustomerSearchController.addListener(_onFormChanged);
    _grossAreaController.addListener(_onFormChanged);
    _netAreaController.addListener(_onFormChanged);
    _bootstrapRefAddresses();
    _loadOfficeContacts();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  void _syncTabIndex() {
    final i = _tabController.index;
    if (i != _tabIndex) setState(() => _tabIndex = i);
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncTabIndex);
    _listingPriceController.removeListener(_onFormChanged);
    _transactionAmountController.removeListener(_onFormChanged);
    _buyerFeeController.removeListener(_onFormChanged);
    _sellerFeeController.removeListener(_onFormChanged);
    _listingTitleController.removeListener(_onFormChanged);
    _buyerCustomerSearchController.removeListener(_onFormChanged);
    _sellerCustomerSearchController.removeListener(_onFormChanged);
    _grossAreaController.removeListener(_onFormChanged);
    _netAreaController.removeListener(_onFormChanged);
    _tabController.dispose();
    _listingPriceController.dispose();
    _transactionAmountController.dispose();
    _buyerFeeController.dispose();
    _sellerFeeController.dispose();
    _listingTitleController.dispose();
    _buyerCustomerSearchController.dispose();
    _sellerCustomerSearchController.dispose();
    _grossAreaController.dispose();
    _netAreaController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    var s = raw.trim().replaceAll('₺', '').replaceAll(RegExp(r'\s'), '');
    if (s.isEmpty) return null;

    if (s.contains('.') && s.contains(',')) {
      // 3.000,50 → 3000.50
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (s.contains(',')) {
      s = s.replaceAll(',', '.');
    } else if (s.contains('.')) {
      final parts = s.split('.');
      // 2.500 → 2500 (TR binlik ayırıcı)
      if (parts.length > 1 && parts.last.length == 3) {
        s = s.replaceAll('.', '');
      }
    }
    return double.tryParse(s);
  }

  String _formatTry(double value, {bool forceDecimals = false}) {
    if (value == 0 && !forceDecimals) return '0₺';
    final isWhole = !forceDecimals && value == value.roundToDouble();
    final formatter = NumberFormat(isWhole ? '#,##0' : '#,##0.00', 'tr_TR');
    return '${formatter.format(value)}₺';
  }

  String _formatFeeInput(double value) {
    if (value == value.roundToDouble()) {
      return NumberFormat('#,##0', 'tr_TR').format(value);
    }
    return NumberFormat('#,##0.00', 'tr_TR').format(value);
  }

  bool _hasPositiveAmount(TextEditingController controller) {
    final value = _parseAmount(controller.text);
    return value != null && value > 0;
  }

  double get _buyerFeeInclVat => _parseAmount(_buyerFeeController.text) ?? 0;
  double get _sellerFeeInclVat => _parseAmount(_sellerFeeController.text) ?? 0;
  double get _buyerFeeExclVat =>
      _buyerFeeInclVat <= 0 ? 0 : _buyerFeeInclVat / (1 + _kVatRate);
  double get _sellerFeeExclVat =>
      _sellerFeeInclVat <= 0 ? 0 : _sellerFeeInclVat / (1 + _kVatRate);
  double get _totalFeeInclVat => _buyerFeeInclVat + _sellerFeeInclVat;
  double get _totalFeeExclVat => _buyerFeeExclVat + _sellerFeeExclVat;
  double get _zecornerFee =>
      _totalFeeExclVat <= 0 ? 0 : _totalFeeExclVat * _kZecornerRate;

  bool get _isTransactionStepValid =>
      _hasPositiveAmount(_listingPriceController) &&
      _hasPositiveAmount(_transactionAmountController) &&
      _hasPositiveAmount(_buyerFeeController) &&
      _hasPositiveAmount(_sellerFeeController) &&
      _selectedPerformer != null;

  bool get _isListingStepValid {
    final titleOk = _listingTitleController.text.trim().isNotEmpty;
    final typeOk = _portfolioKind != null &&
        (_portfolioSubType ?? '').trim().isNotEmpty &&
        (_listingType ?? '').trim().isNotEmpty;
    final locationOk = _countryCode.trim().isNotEmpty &&
        (_province ?? '').trim().isNotEmpty &&
        (_district ?? '').trim().isNotEmpty &&
        (_quarterOptions.isEmpty || (_neighborhood ?? '').trim().isNotEmpty);
    final areaOk = _hasPositiveAmount(_grossAreaController) &&
        _hasPositiveAmount(_netAreaController);
    return titleOk && typeOk && locationOk && areaOk;
  }

  bool get _isCustomerStepValid =>
      _buyerCustomerSearchController.text.trim().isNotEmpty &&
      _sellerCustomerSearchController.text.trim().isNotEmpty;

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _isTransactionStepValid;
      case 1:
        return _isListingStepValid;
      case 2:
        return _isCustomerStepValid;
      default:
        return false;
    }
  }

  bool _fieldError(bool isInvalid) => _highlightInvalidFields && isInvalid;

  void _clearFieldHighlights() {
    if (!_highlightInvalidFields) return;
    setState(() => _highlightInvalidFields = false);
  }

  void _showIncompleteStepMessage() {
    setState(() => _highlightInvalidFields = true);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        elevation: 10,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _kBrand.withValues(alpha: 0.35), width: 1.4),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        content: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _kBrand,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Eksik bilgi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Kırmızı çerçeveli zorunlu alanları doldurun.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
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

  void _requestTab(int target) {
    if (target == _tabIndex) return;
    if (target < _tabIndex) {
      _tabController.animateTo(target);
      return;
    }
    for (var step = 0; step < target; step++) {
      if (!_isStepValid(step)) {
        _showIncompleteStepMessage();
        if (_tabIndex != step) _tabController.animateTo(step);
        return;
      }
    }
    _clearFieldHighlights();
    _tabController.animateTo(target);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime tempDate = _transactionDate;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'İşlem Tarihi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('d MMMM yyyy, EEEE').format(tempDate),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: _kInk,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: _kBrand,
                            onPrimary: Colors.white,
                            onSurface: _kInk,
                          ),
                          datePickerTheme: DatePickerThemeData(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.white,
                            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.white;
                              }
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.grey.shade400;
                              }
                              return _kInk;
                            }),
                            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return _kBrand;
                              }
                              return null;
                            }),
                            dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return _kBrand.withValues(alpha: 0.16);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return _kBrand.withValues(alpha: 0.08);
                              }
                              return null;
                            }),
                            todayForegroundColor: WidgetStateProperty.all(_kBrand),
                            todayBorder: BorderSide(
                              color: _kBrand.withValues(alpha: 0.35),
                              width: 1.4,
                            ),
                          ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: tempDate,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 5),
                          onDateChanged: (selected) {
                            setModalState(() => tempDate = selected);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade300),
                                  foregroundColor: Colors.grey.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                                child: const Text('Vazgeç'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(ctx, tempDate),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kBrand,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                ),
                                child: const Text(
                                  'Tarihi Seç',
                                  style: TextStyle(fontWeight: FontWeight.w700),
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
          },
        );
      },
    );

    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  List<String> get _portfolioSubTypeOptions {
    if (_portfolioKind == null) return const [];
    if (_portfolioKind == 0) {
      return const [
        'Daire',
        'Rezidans',
        'Müstakil Ev',
        'Villa',
        'Çiftlik Evi',
        'Köşk & Konak',
        'Yalı',
        'Yalı Dairesi',
        'Yazlık',
        'Arsa',
      ];
    }
    return const [
      'Apartman Dairesi',
      'Atölye',
      'Depo & Antrepo',
      'Fabrika',
      'İmalathane',
      'İş Hanı Katı & Ofisi',
      'Dükkan & Mağaza',
      'Muayenehane',
      'Plaza',
      'Plaza Katı & Ofisi',
      'Restoran & Lokanta',
      'Tamirhane',
      'Cafe & Bar',
      'Büro & Ofis',
      'Maden Ocağı',
      'Kuaför & Güzellik Merkezi',
      'Oto Yıkama & Kuaför',
      'Okul & Kurs',
      'Taksi Durağı',
      'Market',
      'Eczane & Medikal',
      'Pastane & Fırın',
      'Pazar Yeri',
      'Sağlık Merkezi',
      'Prova & Kayıt Stüdyosu',
      'Sinema & Konferans Salonu',
      'Fotoğraf Stüdyosu',
      'Yurt',
      'Akaryakıt İstasyonu',
      'Büfe',
      'Komple Bina',
      'Otopark',
      'Spor Tesisi',
      'Spa, Hamam & Sauna',
      'Çiftlik',
      'Düğün Salonu',
      'Hazır & Sanal Ofis',
      'Radyo İstasyonu & TV Kanalı',
      'Kıraathane',
      'Kır & Kahvaltı Bahçesi',
      'Rezidans Katı & Ofisi',
      'AVM',
      'Garaj',
      'Kantin',
      'Villa',
      'Radyo İstasyonu',
      'Plaza Katı',
      'Enerji Santrali',
      'Garaj & Park Yeri',
      'Arsa',
    ];
  }

  List<String> get _listingTypeOptions => const ['Kiralık', 'Satılık'];

  List<String> get _neighborhoodOptions => _quarterOptions;

  List<String> get _countryOptions =>
      _kAddressCountries.map((c) => c.name).toList(growable: false);

  String _countryCodeFromName(String name) {
    for (final c in _kAddressCountries) {
      if (c.name == name) return c.code;
    }
    return 'TR';
  }

  Future<void> _bootstrapRefAddresses() async {
    await _loadProvincesForCountry(_countryCode);
  }

  Future<void> _loadProvincesForCountry(String countryCode) async {
    if (!mounted) return;
    setState(() => _refLocationLoading = true);

    // TR/CT: country_code her zaman gönderilmeli (BAMMA aksi halde boş liste döner)
    final pr = await _contactApiRepository.getProvinces(countryCode: countryCode);

    if (!mounted) return;
    pr.fold(
      (failure) {
        setState(() {
          _refLocationLoading = false;
          _provincesModel = null;
          _provinceOptions = [];
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message.isNotEmpty
                ? failure.message
                : 'İller yüklenemedi.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      (provinces) {
        setState(() {
          _provincesModel = provinces;
          _provinceOptions =
              provinces.provinces.map((p) => p.name).toList()..sort();
          _refLocationLoading = false;
        });
      },
    );
  }

  Future<void> _loadDistrictsForProvinceName(String? provinceName) async {
    if (provinceName == null || provinceName.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _refLocationLoading = true);
    final model = _provincesModel;
    if (model == null) {
      setState(() => _refLocationLoading = false);
      return;
    }
    final p = model.getProvinceByName(provinceName.trim());
    if (p == null) {
      setState(() => _refLocationLoading = false);
      return;
    }
    final dr = await _contactApiRepository.getDistrictsByProvince(
      p.code,
      countryCode: _countryCode,
    );
    if (!mounted) return;
    dr.fold(
      (failure) {
        setState(() => _refLocationLoading = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message.isNotEmpty
                ? failure.message
                : 'İlçeler yüklenemedi.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      (detail) {
        setState(() {
          _districtsDetailCache = detail;
          _districtOptions = detail.districts.map((d) => d.name).toList()..sort();
          _quarterOptions = [];
          _refLocationLoading = false;
        });
      },
    );
  }

  Future<void> _handleCountrySelected(String countryName) async {
    final code = _countryCodeFromName(countryName);
    setState(() {
      _countryName = countryName;
      _countryCode = code;
      _province = null;
      _district = null;
      _neighborhood = null;
      _provincesModel = null;
      _districtsDetailCache = null;
      _provinceOptions = [];
      _districtOptions = [];
      _quarterOptions = [];
    });
    await _loadProvincesForCountry(code);
  }

  Future<void> _handleProvinceSelected(String value) async {
    setState(() {
      _province = value;
      _district = null;
      _neighborhood = null;
      _districtOptions = [];
      _quarterOptions = [];
    });
    await _loadDistrictsForProvinceName(value);
  }

  void _handleDistrictSelected(String value) {
    final districtModel = _districtsDetailCache == null
        ? null
        : resolveDistrictModel(_districtsDetailCache!, value);
    setState(() {
      _district = value;
      _neighborhood = null;
      _quarterOptions = districtModel == null
          ? []
          : (districtModel.quarters.map((q) => q.name).toList()..sort());
    });
  }

  String _performerLabel(OfficePersonsApiModel contact) {
    final name = contact.title.trim().isNotEmpty
        ? contact.title.trim()
        : contact.fullName.trim();
    final role = (contact.typeDescription ?? '').trim();
    if (name.isEmpty) return role;
    if (role.isEmpty) return name;
    return '$name · $role';
  }

  OfficePersonsApiModel? _findCurrentUserContact() {
    final userId = _currentUserContactNo;
    if (userId == null) return null;
    for (final contact in _officeContacts) {
      if (contact.contactNo == userId) return contact;
    }
    return _currentUserFallback;
  }

  Future<void> _loadOfficeContacts() async {
    if (!mounted) return;
    setState(() => _officeContactsLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final currentUserId = int.tryParse(prefs.getString('userID') ?? '');
    final name = (prefs.getString('userName') ?? '').trim();
    final surname = (prefs.getString('userSurname') ?? '').trim();
    final typeDesc = (prefs.getString('userTypeDescription') ?? '').trim();
    final fallback = currentUserId == null
        ? null
        : OfficePersonsApiModel(
            contactNo: currentUserId,
            title: '$name $surname'.trim(),
            name: name,
            surname: surname,
            typeDescription: typeDesc.isEmpty ? null : typeDesc,
            isCompany: false,
            isEmployee: true,
            isAgency: false,
            isCustomer: false,
          );

    final result = await _officePersonsRepository.getOfficePersons(
      page: 1,
      limit: 200,
      types: const [],
    );

    if (!mounted) return;
    result.fold(
      (_) {
        setState(() {
          _currentUserContactNo = currentUserId;
          _currentUserFallback = fallback;
          _officeContactsLoading = false;
        });
      },
      (response) {
        setState(() {
          _currentUserContactNo = currentUserId;
          _currentUserFallback = fallback;
          _officeContacts = response.contacts;
          _officeContactsLoading = false;
          if (_isPerformerMe) {
            _selectedPerformer = _findCurrentUserContact() ?? _selectedPerformer;
          }
        });
      },
    );
  }

  void _onPerformerMeChanged(bool value) {
    setState(() {
      _isPerformerMe = value;
      if (value) {
        final me = _findCurrentUserContact();
        if (me != null) {
          _selectedPerformer = me;
        }
      }
    });
  }

  void _goBackTab() {
    if (_tabIndex <= 0) return;
    _tabController.animateTo(_tabIndex - 1);
  }

  void _goForwardFromTransaction() {
    if (!_isTransactionStepValid) {
      _showIncompleteStepMessage();
      return;
    }
    _clearFieldHighlights();
    _tabController.animateTo(1);
  }

  void _goForwardFromListing() {
    if (!_isListingStepValid) {
      _showIncompleteStepMessage();
      return;
    }
    _clearFieldHighlights();
    _tabController.animateTo(2);
  }

  void _submitTransactionNotification() {
    if (!_isCustomerStepValid) {
      _showIncompleteStepMessage();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('İşlem bildirimi gönderildi.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AdminPanelInAppBar(
        title: 'Diğer İşlem Bildirimi',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TransactionStepBar(
            tabIndex: _tabIndex,
            onTap: _requestTab,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTransactionTab(),
                _buildListingTab(),
                _buildCustomerTab(),
              ],
            ),
          ),
          Material(
            elevation: 12,
            shadowColor: Colors.black26,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: _buildStickyActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kBrand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: _kBrand, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'İşlem detayları',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _LabeledField(
                  label: 'İlan Fiyatı (TRY)',
                  hasError: _fieldError(!_hasPositiveAmount(_listingPriceController)),
                  child: _CurrencyField(
                    controller: _listingPriceController,
                    hasError: _fieldError(!_hasPositiveAmount(_listingPriceController)),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'İşlem Bedeli (TRY)',
                  hasError: _fieldError(!_hasPositiveAmount(_transactionAmountController)),
                  child: _CurrencyField(
                    controller: _transactionAmountController,
                    hasError: _fieldError(!_hasPositiveAmount(_transactionAmountController)),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'İşlem Tarihi',
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _fieldDecoration(suffix: Icons.calendar_month_rounded),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_transactionDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _kInk,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _onPerformerMeChanged(!_isPerformerMe),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _isPerformerMe,
                            onChanged: (v) => _onPerformerMeChanged(v ?? false),
                            activeColor: _kBrand,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: Colors.grey.shade400, width: 1.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'İşlemi yapan benim',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'İşlemi yapan kişi',
                  hasError: _fieldError(_selectedPerformer == null),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: (_officeContactsLoading || _isPerformerMe)
                          ? null
                          : _showPerformerPicker,
                      child: InputDecorator(
                        decoration: _fieldDecoration(
                          suffix: Icons.keyboard_arrow_down_rounded,
                          hasError: _fieldError(_selectedPerformer == null),
                        ),
                        child: Row(
                          children: [
                            if (_officeContactsLoading) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(_kBrand),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                _selectedPerformer != null
                                    ? _performerLabel(_selectedPerformer!)
                                    : '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedPerformer == null
                                      ? Colors.grey.shade400
                                      : (_isPerformerMe
                                          ? Colors.grey.shade600
                                          : _kInk),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İşlem Oluştur',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bu sayfa ile yeni işlem kayıtları oluşturabilirsiniz.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hizmet Bedelleri',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Alıcı Hizmet Bedeli (KDV dahil)',
                  hasError: _fieldError(!_hasPositiveAmount(_buyerFeeController)),
                  child: _CurrencyField(
                    controller: _buyerFeeController,
                    hasError: _fieldError(!_hasPositiveAmount(_buyerFeeController)),
                    onCalculatorTap: () => _showVatCalculator(
                      targetController: _buyerFeeController,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'KDV Hariç Tutar',
                  child: _ReadOnlyAmountField(text: _formatTry(_buyerFeeExclVat)),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Satıcı Hizmet Bedeli (KDV dahil)',
                  hasError: _fieldError(!_hasPositiveAmount(_sellerFeeController)),
                  child: _CurrencyField(
                    controller: _sellerFeeController,
                    hasError: _fieldError(!_hasPositiveAmount(_sellerFeeController)),
                    onCalculatorTap: () => _showVatCalculator(
                      targetController: _sellerFeeController,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'KDV Hariç Tutar',
                  child: _ReadOnlyAmountField(text: _formatTry(_sellerFeeExclVat)),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Toplam Hizmet Bedeli (KDV dahil)',
                  child: _ReadOnlyAmountField(text: _formatTry(_totalFeeInclVat)),
                ),
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Zecorner Bedeli',
                  child: _ReadOnlyAmountField(text: _formatTry(_zecornerFee)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showVatCalculator({
    required TextEditingController targetController,
  }) async {
    final applied = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: _VatCalculatorSheet(
            initialInclVat: _parseAmount(targetController.text),
            vatRate: _kVatRate,
            formatTry: _formatTry,
            parseAmount: _parseAmount,
          ),
        );
      },
    );

    if (applied != null && mounted) {
      targetController.text = _formatFeeInput(applied);
      setState(() {});
    }
  }

  Widget _buildStickyActions() {
    const h = 52.0;
    if (_tabIndex == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          width: double.infinity,
          height: h,
          child: FilledButton(
            onPressed: _isTransactionStepValid ? _goForwardFromTransaction : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kBrand,
              disabledBackgroundColor: _kBrand.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white70,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'İleri',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          SizedBox(
            height: h,
            child: OutlinedButton(
              onPressed: _goBackTab,
              style: OutlinedButton.styleFrom(
                foregroundColor: _kInk,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text(
                'Geri Dön',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: h,
              child: FilledButton(
                onPressed: _tabIndex == 1
                    ? (_isListingStepValid ? _goForwardFromListing : null)
                    : (_isCustomerStepValid ? _submitTransactionNotification : null),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBrand,
                  disabledBackgroundColor: _kBrand.withValues(alpha: 0.35),
                  disabledForegroundColor: Colors.white70,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _tabIndex == 1 ? 'İleri' : 'İşlem Bildirimi Yap',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.article_outlined, color: _kBrand, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'İlan Bilgileri',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _LabeledField(
              label: 'İlan Başlığı',
              hasError: _fieldError(_listingTitleController.text.trim().isEmpty),
              child: TextField(
                controller: _listingTitleController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
                decoration: _fieldDecoration(
                  hasError: _fieldError(_listingTitleController.text.trim().isEmpty),
                ).copyWith(
                  hintText: 'İlan başlığını giriniz...',
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPortfolioSegment(),
            const SizedBox(height: 20),
            if (_portfolioKind != null) ...[
              _buildModernPickerField(
                label: _portfolioKind == 0 ? 'Konut Tipi Seçiniz' : 'Ticari Tipi Seçiniz',
                value: _portfolioSubType,
                placeholder: 'Seçiniz',
                options: _portfolioSubTypeOptions,
                searchable: true,
                hasError: _fieldError((_portfolioSubType ?? '').trim().isEmpty),
                onSelected: (v) => setState(() => _portfolioSubType = v),
              ),
              const SizedBox(height: 16),
            ],
            _buildModernPickerField(
              label: 'İlan Tipi',
              value: _listingType,
              placeholder: 'Seçiniz',
              options: _listingTypeOptions,
              searchable: true,
              hasError: _fieldError((_listingType ?? '').trim().isEmpty),
              onSelected: (v) => setState(() => _listingType = v),
            ),
            const SizedBox(height: 16),
            _buildModernPickerField(
              label: 'Ülke',
              value: _countryName,
              placeholder: 'Seçiniz',
              options: _countryOptions,
              searchable: false,
              hasError: _fieldError(_countryCode.trim().isEmpty),
              onSelected: (v) async => _handleCountrySelected(v),
            ),
            const SizedBox(height: 16),
            _buildModernPickerField(
              label: 'İl Seçiniz',
              value: _province,
              placeholder: 'Seçiniz',
              options: _provinceOptions,
              isLoading: _refLocationLoading,
              searchable: true,
              hasError: _fieldError((_province ?? '').trim().isEmpty),
              onSelected: (v) async => _handleProvinceSelected(v),
              onEmptyTap: () async {
                if (_refLocationLoading) return;
                await _loadProvincesForCountry(_countryCode);
                if (!mounted || _provinceOptions.isEmpty) return;
                await _showSearchablePicker(
                  title: 'İl Seçiniz',
                  options: _provinceOptions,
                  searchable: true,
                  onSelected: _handleProvinceSelected,
                );
              },
            ),
            const SizedBox(height: 16),
            _buildModernPickerField(
              label: 'İlçe Seçiniz',
              value: _district,
              placeholder: 'Seçiniz',
              options: _districtOptions,
              isLoading: _refLocationLoading,
              searchable: true,
              hasError: _fieldError((_district ?? '').trim().isEmpty),
              onSelected: (v) => _handleDistrictSelected(v),
            ),
            const SizedBox(height: 16),
            _buildModernPickerField(
              label: 'Mahalle Seçiniz',
              value: _neighborhood,
              placeholder: 'Seçiniz',
              options: _neighborhoodOptions,
              isLoading: _refLocationLoading,
              searchable: true,
              hasError: _fieldError(
                _quarterOptions.isNotEmpty &&
                    (_neighborhood ?? '').trim().isEmpty,
              ),
              onSelected: (v) => setState(() => _neighborhood = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LabeledField(
                    label: 'm² Brüt',
                    hasError: _fieldError(!_hasPositiveAmount(_grossAreaController)),
                    child: TextField(
                      controller: _grossAreaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                      decoration: _areaFieldDecoration(
                        hasError: _fieldError(!_hasPositiveAmount(_grossAreaController)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledField(
                    label: 'm² Net',
                    hasError: _fieldError(!_hasPositiveAmount(_netAreaController)),
                    child: TextField(
                      controller: _netAreaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                      decoration: _areaFieldDecoration(
                        hasError: _fieldError(!_hasPositiveAmount(_netAreaController)),
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
  }

  Widget _buildPortfolioSegment() {
    final hasError = _fieldError(_portfolioKind == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portföy Tipi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? _kBrand : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PortfolioSegmentChip(
                label: 'Konut',
                selected: _portfolioKind == 0,
                hasError: hasError,
                onTap: () => setState(() {
                  _portfolioKind = 0;
                  _portfolioSubType = null;
                  _listingType = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PortfolioSegmentChip(
                label: 'Ticari',
                selected: _portfolioKind == 1,
                hasError: hasError,
                onTap: () => setState(() {
                  _portfolioKind = 1;
                  _portfolioSubType = null;
                  _listingType = null;
                }),
              ),
            ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          const Text(
            'Bu alan zorunlu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kBrand,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernPickerField({
    required String label,
    required String? value,
    required String placeholder,
    required List<String> options,
    required FutureOr<void> Function(String)? onSelected,
    Future<void> Function()? onEmptyTap,
    bool searchable = false,
    bool isLoading = false,
    bool hasError = false,
  }) {
    return _LabeledField(
      label: label,
      hasError: hasError,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: (isLoading || onSelected == null)
              ? null
              : () async {
                  if (options.isEmpty) {
                    if (onEmptyTap != null) {
                      await onEmptyTap();
                      return;
                    }
                    await _showSearchablePicker(
                      title: label,
                      options: options,
                      searchable: searchable,
                      onSelected: onSelected,
                    );
                    return;
                  }
                  await _showSearchablePicker(
                    title: label,
                    options: options,
                    searchable: searchable,
                    onSelected: onSelected,
                  );
                },
          child: InputDecorator(
            decoration: _fieldDecoration(
              suffix: Icons.keyboard_arrow_down_rounded,
              hasError: hasError,
            ),
            child: Row(
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_kBrand),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: value == null ? Colors.grey.shade400 : _kInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPerformerPicker() async {
    if (_officeContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İşlemi yapan kişi listesi yüklenemedi.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final searchController = TextEditingController();
    List<OfficePersonsApiModel> filtered = List.of(_officeContacts);

    final selected = await showModalBottomSheet<OfficePersonsApiModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.52,
              minChildSize: 0.38,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 8, 4),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'İşlemi yapan kişi',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _kInk,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                          child: TextField(
                            controller: searchController,
                            onChanged: (query) {
                              setModalState(() {
                                final q = query.trim().toLowerCase();
                                filtered = q.isEmpty
                                    ? List.of(_officeContacts)
                                    : _officeContacts.where((c) {
                                        return _performerLabel(c).toLowerCase().contains(q) ||
                                            (c.name ?? '').toLowerCase().contains(q) ||
                                            (c.surname ?? '').toLowerCase().contains(q) ||
                                            (c.eMail ?? '').toLowerCase().contains(q);
                                      }).toList();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Ara...',
                              suffixIcon: const Icon(Icons.search_rounded, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF3F4F6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'Sonuç bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final contact = filtered[index];
                                    final isSelected =
                                        _selectedPerformer?.contactNo == contact.contactNo;
                                    final role = (contact.typeDescription ?? '').trim();
                                    final name = contact.title.trim().isNotEmpty
                                        ? contact.title.trim()
                                        : contact.fullName.trim();
                                    return ListTile(
                                      selected: isSelected,
                                      selectedTileColor: const Color(0xFFF3F4F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      title: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: _kInk,
                                              ),
                                            ),
                                            if (role.isNotEmpty)
                                              TextSpan(
                                                text: ' · $role',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      onTap: () => Navigator.pop(sheetContext, contact),
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
          },
        );
      },
    );

    searchController.dispose();

    if (selected != null) {
      setState(() => _selectedPerformer = selected);
    }
  }

  Future<void> _showSearchablePicker({
    required String title,
    required List<String> options,
    required FutureOr<void> Function(String) onSelected,
    bool searchable = false,
  }) async {
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title için seçenek bulunamadı.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final TextEditingController searchController = TextEditingController();
    List<String> filteredOptions = List.of(options);

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.46,
              minChildSize: 0.34,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 8, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _kInk,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ],
                          ),
                        ),
                        if (searchable)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                            child: TextField(
                              controller: searchController,
                              onChanged: (query) {
                                setModalState(() {
                                  final q = query.trim().toLowerCase();
                                  filteredOptions = q.isEmpty
                                      ? List.of(options)
                                      : options
                                          .where((o) => o.toLowerCase().contains(q))
                                          .toList();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Ara...',
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                filled: true,
                                fillColor: const Color(0xFFF3F4F6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                            itemCount: filteredOptions.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final item = filteredOptions[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                title: Text(
                                  item,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kInk,
                                  ),
                                ),
                                onTap: () => Navigator.pop(sheetContext, item),
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
          },
        );
      },
    );

    searchController.dispose();

    if (selected != null) {
      await onSelected(selected);
    }
  }

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlassCard(
            child: _CustomerRoleBlock(
              roleTitle: 'Alıcı',
              searchController: _buyerCustomerSearchController,
              hasError: _fieldError(
                _buyerCustomerSearchController.text.trim().isEmpty,
              ),
              onCreateCustomer: () {
                Navigator.pushNamed(context, AppRouter.addCustomer);
              },
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: _CustomerRoleBlock(
              roleTitle: 'Satıcı',
              searchController: _sellerCustomerSearchController,
              hasError: _fieldError(
                _sellerCustomerSearchController.text.trim().isEmpty,
              ),
              onCreateCustomer: () {
                Navigator.pushNamed(context, AppRouter.addCustomer);
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _areaFieldDecoration({bool hasError = false}) {
    return transactionInputDecoration(hasError: hasError, hintText: '0');
  }

  InputDecoration _fieldDecoration({IconData? suffix, bool hasError = false}) {
    return transactionInputDecoration(suffix: suffix, hasError: hasError);
  }
}

class _PortfolioSegmentChip extends StatelessWidget {
  const _PortfolioSegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? _kBrand
        : (hasError ? _kBrand : Colors.grey.shade300);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? _kBrand.withValues(alpha: 0.06)
                : (hasError ? _kErrorFill : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: selected || hasError ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? _kBrand : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerRoleBlock extends StatelessWidget {
  const _CustomerRoleBlock({
    required this.roleTitle,
    required this.searchController,
    required this.onCreateCustomer,
    this.hasError = false,
  });

  final String roleTitle;
  final TextEditingController searchController;
  final VoidCallback onCreateCustomer;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          roleTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _kInk,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Müşteri',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? _kBrand : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
          decoration: transactionInputDecoration(
            hasError: hasError,
            hintText: 'Ara',
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          const Text(
            'Bu alan zorunlu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kBrand,
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: onCreateCustomer,
          style: TextButton.styleFrom(
            foregroundColor: _kBrand,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          child: const Text('+ Yeni müşteri oluştur'),
        ),
      ],
    );
  }
}

/// Üst adım çubuğu: ince ilerleme çizgisi + iOS benzeri segment kontrol.
class _TransactionStepBar extends StatelessWidget {
  const _TransactionStepBar({
    required this.tabIndex,
    required this.onTap,
  });

  final int tabIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['İşlem', 'İlan Bilgileri', 'Müşteri'];
  static const List<IconData> _icons = [
    Icons.receipt_long_rounded,
    Icons.home_work_outlined,
    Icons.people_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Adım ${tabIndex + 1} / 3',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                _labels[tabIndex],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kBrand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StepDot(completed: tabIndex > 0, active: tabIndex == 0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: tabIndex > 0 ? _kBrand : _kSegmentTrack,
                    ),
                  ),
                ),
              ),
              _StepDot(completed: tabIndex > 1, active: tabIndex == 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: tabIndex > 1 ? _kBrand : _kSegmentTrack,
                    ),
                  ),
                ),
              ),
              _StepDot(completed: tabIndex > 2, active: tabIndex == 2),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _kSegmentTrack,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) {
                final selected = tabIndex == i;
                return Expanded(
                  child: _StepSegmentTile(
                    icon: _icons[i],
                    label: _labels[i],
                    selected: selected,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.completed, required this.active});

  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final pending = !completed && !active;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: active ? 12 : 10,
      height: active ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed || active ? _kBrand : Colors.transparent,
        border: Border.all(
          color: pending ? Colors.grey.shade400 : _kBrand,
          width: pending ? 2 : (active ? 0 : 0),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: _kBrand.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }
}

class _StepSegmentTile extends StatelessWidget {
  const _StepSegmentTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _kBrand.withValues(alpha: 0.12),
        highlightColor: _kBrand.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? _kBrand : Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? _kBrand : Colors.grey.shade600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.hasError = false,
  });

  final String label;
  final Widget child;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? _kBrand : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (hasError) ...[
          const SizedBox(height: 6),
          const Text(
            'Bu alan zorunlu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kBrand,
            ),
          ),
        ],
      ],
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({
    required this.controller,
    this.onCalculatorTap,
    this.hasError = false,
  });

  final TextEditingController controller;
  final VoidCallback? onCalculatorTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _kInk,
      ),
      decoration: transactionInputDecoration(
        hasError: hasError,
        hintText: '0',
      ).copyWith(
        suffixIcon: onCalculatorTap == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Material(
                  color: _kBrand,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onCalculatorTap,
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
        suffixIconConstraints: onCalculatorTap == null
            ? null
            : const BoxConstraints(minWidth: 48, minHeight: 40),
      ),
    );
  }
}

class _ReadOnlyAmountField extends StatelessWidget {
  const _ReadOnlyAmountField({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _VatCalculatorSheet extends StatefulWidget {
  const _VatCalculatorSheet({
    required this.initialInclVat,
    required this.vatRate,
    required this.formatTry,
    required this.parseAmount,
  });

  final double? initialInclVat;
  final double vatRate;
  final String Function(double value, {bool forceDecimals}) formatTry;
  final double? Function(String raw) parseAmount;

  @override
  State<_VatCalculatorSheet> createState() => _VatCalculatorSheetState();
}

class _VatCalculatorSheetState extends State<_VatCalculatorSheet> {
  /// 0: KDV Hesapla (hariç → dahil), 1: KDV'siz Hesapla (dahil → hariç)
  int _tab = 0;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialInclVat;
    if (initial != null && initial > 0) {
      // KDV'siz sekmesinde mevcut KDV dahil tutarı göster
      _inputController.text = initial == initial.roundToDouble()
          ? NumberFormat('#,##0', 'tr_TR').format(initial)
          : NumberFormat('#,##0.00', 'tr_TR').format(initial);
      _tab = 1;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  double get _inputValue => widget.parseAmount(_inputController.text) ?? 0;

  double get _result {
    if (_inputValue <= 0) return 0;
    if (_tab == 0) {
      return _inputValue * (1 + widget.vatRate);
    }
    return _inputValue / (1 + widget.vatRate);
  }

  /// Forma uygulanacak KDV dahil tutar
  double? get _applyValue {
    if (_inputValue <= 0) return null;
    if (_tab == 0) return _result;
    return _inputValue;
  }

  @override
  Widget build(BuildContext context) {
    final inputLabel = _tab == 0 ? 'KDV Hariç Tutar' : 'KDV Dahil Tutar';
    final resultLabel = _tab == 0 ? 'KDV Dahil Tutar' : 'KDV Hariç Tutar';

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Hesaplama Aracı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _VatCalcTab(
                      label: 'KDV Hesapla',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  Expanded(
                    child: _VatCalcTab(
                      label: "KDV'siz Hesapla",
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                inputLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _inputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
                    borderSide: const BorderSide(color: _kBrand, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                resultLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  widget.formatTry(_result, forceDecimals: true),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Kapat'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _applyValue == null
                        ? null
                        : () => Navigator.pop(context, _applyValue),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kBrand,
                      disabledBackgroundColor: _kBrand.withValues(alpha: 0.35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Uygula',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VatCalcTab extends StatelessWidget {
  const _VatCalcTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? _kBrand : Colors.grey.shade600,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 3,
            decoration: BoxDecoration(
              color: selected ? _kBrand : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
