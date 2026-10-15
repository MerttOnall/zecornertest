import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/core/location/nominatim_geocoding.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/location/ref_location_resolution.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/models/office/office_api_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/presentation/widgets/map_widget.dart';
import 'dart:io';

// Renk ve stil sabitleri (modern tasarım)
const _primaryRed = Color(0xFFE53935);
const _cardBg = Color(0xFFFAFAFA);
const _sectionTitleColor = Color(0xFF1A1A1A);
const _labelColor = Color(0xFF424242);
const _hintColor = Color(0xFF9E9E9E);
const _borderColor = Color(0xFFE0E0E0);
const _errorRed = Color(0xFFD32F2F);

class AddOfficeScreen extends StatefulWidget {
  const AddOfficeScreen({super.key});

  @override
  State<AddOfficeScreen> createState() => _AddOfficeScreenState();
}

class _AddOfficeScreenState extends State<AddOfficeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isActive = true;
  bool _isInstallationPhase = false;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _taxNoController = TextEditingController();
  final TextEditingController _taxOfficeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _commercialTitleController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _linkedInController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _responsibleAdminController = TextEditingController();
  final TextEditingController _officeYearController = TextEditingController(text: '0');
  final TextEditingController _officeDescriptionController = TextEditingController();

  String? _selectedPersonType;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  LatLng? _selectedLocation;
  String? _selectedLocationAddress;

  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  DateTime? _techFeeDate;

  final ContactApiRepository _contactApiRepository = ContactApiRepository();
  final OfficeApiRepository _officeRepository = OfficeApiRepository();

  bool _isSaving = false;

  ProvincesResponseModel? _provincesModel;
  ProvincesDetailResponseModel? _districtsDetailCache;
  List<String> _provinceOptions = [];
  List<String> _districtOptions = [];
  List<String> _quarterOptions = [];
  bool _refLocationLoading = false;

  /// Ref yüklenene kadar bölge dropdown’unda gösterilecek kısa yedek (sadece UI).
  static const List<String> _regionItemsFallback = ['Muğla', 'Kütahya', 'İstanbul', 'Ankara', 'İzmir'];

  List<String> get _regionOrProvinceItems =>
      _provinceOptions.isNotEmpty ? _provinceOptions : _regionItemsFallback;

  File? _selectedPhoto;
  File? _selectedLogo;
  final Map<String, File?> _documents = {
    'findeks': null,
    'imzaSirkusu': null,
    'vergiLevhasi': null,
    'faaliyetBelgesi': null,
    'kdvFisi': null,
    'ticaretSicil': null,
    'yetkiBelgesi': null,
    'sozlesmeBelgesi': null,
  };

  final ImagePicker _picker = ImagePicker();
  bool _showPhotoError = false;
  bool _showLogoError = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrapRefAddresses();
    });
  }

  Future<void> _loadDistrictsForProvinceName(String? provinceName) async {
    if (provinceName == null || provinceName.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _refLocationLoading = true);
    if (_provincesModel == null) {
      final pr = await _contactApiRepository.getProvinces();
      if (!mounted) return;
      pr.fold(
        (_) {
          if (mounted) setState(() => _refLocationLoading = false);
        },
        (p) => setState(() => _provincesModel = p),
      );
    }
    final p = _provincesModel?.getProvinceByName(provinceName.trim());
    if (p == null) {
      if (mounted) setState(() => _refLocationLoading = false);
      return;
    }
    final dr = await _contactApiRepository.getDistrictsByProvince(p.code);
    if (!mounted) return;
    dr.fold(
      (_) {
        if (mounted) setState(() => _refLocationLoading = false);
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

  Future<void> _bootstrapRefAddresses() async {
    if (!mounted) return;
    setState(() => _refLocationLoading = true);

    final pr = await _contactApiRepository.getProvinces();
    if (!mounted) return;

    final provinces = pr.fold<ProvincesResponseModel?>((_) => null, (r) => r);
    if (provinces == null || provinces.provinces.isEmpty) {
      setState(() {
        _refLocationLoading = false;
        _provinceOptions = [];
      });
      return;
    }

    setState(() {
      _provincesModel = provinces;
      _provinceOptions = provinces.provinces.map((p) => p.name).toList()..sort();
    });

    ProvinceModel? p = provinces.getProvinceByName(_selectedCity ?? '');
    p ??= provinces.getProvinceByName(_selectedRegion ?? '');
    p ??= provinces.getProvinceByName('Kütahya');
    if (p == null && provinces.provinces.isNotEmpty) {
      p = provinces.provinces.first;
    }
    if (p == null) {
      setState(() => _refLocationLoading = false);
      return;
    }
    final resolvedProvince = p;

    setState(() {
      _selectedCity = resolvedProvince.name;
      _selectedRegion = resolvedProvince.name;
    });

    final dr = await _contactApiRepository.getDistrictsByProvince(resolvedProvince.code);
    if (!mounted) return;

    final detail = dr.fold<ProvincesDetailResponseModel?>((_) => null, (r) => r);
    if (detail == null) {
      setState(() => _refLocationLoading = false);
      return;
    }

    setState(() {
      _districtsDetailCache = detail;
      _districtOptions = detail.districts.map((d) => d.name).toList()..sort();
    });

    DistrictModel? d;
    if (_selectedDistrict != null && _selectedDistrict!.trim().isNotEmpty) {
      d = resolveDistrictModel(detail, _selectedDistrict);
    }
    if (d == null && detail.districts.length == 1) {
      d = detail.districts.first;
    }

    final quarters = d == null ? <String>[] : (d.quarters.map((q) => q.name).toList()..sort());

    setState(() {
      _selectedDistrict = d?.name;
      _quarterOptions = quarters;
      if (_selectedNeighborhood != null &&
          quarters.isNotEmpty &&
          !quarters.any((x) => x.toLowerCase() == _selectedNeighborhood!.toLowerCase())) {
        _selectedNeighborhood = null;
      }
      _refLocationLoading = false;
    });
  }

  Future<({int? provinceCode, int? districtCode, int? quarterCode})> _resolveLocationCodes() async {
    const empty = (provinceCode: null, districtCode: null, quarterCode: null);
    final city = _selectedCity?.trim();
    final districtName = _selectedDistrict?.trim();
    final quarterName = _selectedNeighborhood?.trim();
    if (city == null || city.isEmpty) return empty;

    ProvincesResponseModel? provinces = _provincesModel;
    if (provinces == null) {
      final pr = await _contactApiRepository.getProvinces();
      provinces = pr.fold<ProvincesResponseModel?>((_) => null, (r) => r);
    }
    if (provinces == null) return empty;

    final province = provinces.getProvinceByName(city);
    if (province == null) return empty;

    final cacheProvince = _provincesModel?.getProvinceByName(city);
    final useCache = _districtsDetailCache != null &&
        cacheProvince != null &&
        cacheProvince.code == province.code;

    ProvincesDetailResponseModel? detail = useCache ? _districtsDetailCache : null;
    if (detail == null) {
      final dr = await _contactApiRepository.getDistrictsByProvince(province.code);
      detail = dr.fold<ProvincesDetailResponseModel?>((_) => null, (r) => r);
    }
    if (detail == null) {
      return (provinceCode: province.code, districtCode: null, quarterCode: null);
    }

    int? dCode;
    int? qCode;
    if (districtName != null && districtName.isNotEmpty) {
      final dModel = resolveDistrictModel(detail, districtName);
      dCode = dModel?.code;
      if (dModel != null && quarterName != null && quarterName.isNotEmpty) {
        final q = findQuarterInDistrict(dModel, quarterName);
        qCode = q?.code;
      }
    }

    return (provinceCode: province.code, districtCode: dCode, quarterCode: qCode);
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffixIcon, bool isDense = true}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
      labelStyle: const TextStyle(color: _labelColor, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isDense ? 14 : 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryRed, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorRed, width: 2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorRed, width: 2)),
      suffixIcon: suffixIcon,
    );
  }

  /// Şirket ünvanları rakam, nokta, tire vb. içerebilir; sadece harf kuralı kaldırıldı.
  String? _validateCompanyName(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return 'Bu alan zorunludur';
    if (t.length < 2) return 'En az 2 karakter olmalıdır';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Telefon numarası zorunludur';
    if (value.length != 10) return 'Telefon numarası 10 haneli olmalıdır';
    if (!value.startsWith('5')) return 'Telefon numarası 5 ile başlamalıdır';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'E-posta adresi zorunludur';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Geçerli bir e-posta adresi giriniz';
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) return 'Bu alan zorunludur';
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) return 'Lütfen bir seçim yapınız';
    return null;
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
      if (image != null) setState(() { _selectedPhoto = File(image.path); _showPhotoError = false; });
    } catch (_) {}
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500, imageQuality: 80);
      if (image != null) setState(() { _selectedLogo = File(image.path); _showLogoError = false; });
    } catch (_) {}
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
      if (result != null && result.files.single.path != null) setState(() => _documents[documentType] = File(result.files.single.path!));
    } catch (_) {}
  }

  Future<void> _selectDate(BuildContext context, bool isContractStart, bool isContractEnd, bool isTechFee) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Tarih seçiniz',
      cancelText: 'İptal',
      confirmText: 'Tamam',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _sectionTitleColor,
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isContractStart) _contractStartDate = picked;
      if (isContractEnd) _contractEndDate = picked;
      if (isTechFee) _techFeeDate = picked;
    });
  }

  Future<void> _getAddressFromPosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String?>[
          place.street,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).cast<String>().toList();
        setState(() => _selectedLocationAddress = parts.isEmpty ? 'Seçilen konum' : parts.join(', '));
      }
    } catch (_) {
      if (mounted) setState(() => _selectedLocationAddress = 'Adres alınamadı');
    }
  }

  Future<void> _getPositionFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        setState(() => _selectedLocation = LatLng(loc.latitude, loc.longitude));
        await _getAddressFromPosition(_selectedLocation!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedLocation ??= const LatLng(39.4167, 29.9833);
          _selectedLocationAddress = address;
        });
      }
    }
  }

  String? _composeLocationQuery() {
    final parts = <String>[
      if (_selectedNeighborhood != null && _selectedNeighborhood!.trim().isNotEmpty)
        _selectedNeighborhood!.trim(),
      if (_selectedDistrict != null && _selectedDistrict!.trim().isNotEmpty)
        _selectedDistrict!.trim(),
      if (_selectedCity != null && _selectedCity!.trim().isNotEmpty) _selectedCity!.trim(),
      'Türkiye',
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  Future<void> _syncMapWithSelectedLocation() async {
    final fallbackAddress = _composeLocationQuery();
    if (fallbackAddress == null || fallbackAddress.trim().isEmpty) return;
    await _getPositionFromAddress(fallbackAddress);
  }

  Future<void> _openMapPicker() async {
    final typedAddress = _addressController.text.trim();
    if (typedAddress.isNotEmpty) {
      await _getPositionFromAddress(typedAddress);
    } else {
      await _syncMapWithSelectedLocation();
    }
    if (!mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MapLocationPicker(
          initialPosition: _selectedLocation,
          selectedAddress: _selectedLocationAddress,
          onLocationSelected: (LatLng p) async {
            if (!mounted) return;
            setState(() => _selectedLocation = p);
            await _getAddressFromPosition(p);
          },
        ),
      ),
    );
  }

  int _officeContactTypeCode() {
    if (_selectedPersonType == 'Broker') return 102;
    return 101;
  }

  String _failureMessage(Failure f) {
    if (f is AuthFailure) return 'Oturum: ${f.message}';
    if (f is NetworkFailure) return 'Ağ: ${f.message}';
    if (f is ServerFailure) return f.message;
    return f.message;
  }

  Future<void> _saveOffice() async {
    setState(() {
      _showPhotoError = _selectedPhoto == null;
      _showLogoError = _selectedLogo == null;
    });
    final formValid = _formKey.currentState!.validate();
    if (!formValid || _showPhotoError || _showLogoError) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurunuz'), backgroundColor: _errorRed));
      return;
    }

    final codes = await _resolveLocationCodes();
    if (!mounted) return;
    if (codes.provinceCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İl bilgisi ref veride bulunamadı. Lütfen listeden geçerli bir il seçin.'),
          backgroundColor: _errorRed,
        ),
      );
      return;
    }
    if (_selectedDistrict != null &&
        _selectedDistrict!.trim().isNotEmpty &&
        codes.districtCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlçe kodu bulunamadı. İl/ilçe seçimini ref listesine uygun yapın.'),
          backgroundColor: _errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final uploadResult = await _contactApiRepository.uploadFile(_selectedPhoto!, 'PICTURE');
    String? pictureId;
    uploadResult.fold(
      (f) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_failureMessage(f)), backgroundColor: _errorRed),
          );
        }
      },
      (id) => pictureId = id.trim().isEmpty ? null : id,
    );
    if (pictureId == null) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final company = _companyNameController.text.trim();
    final slug = company.toLowerCase().replaceAll(RegExp(r'\s+'), '-');

    final office = OfficeApiModel(
      contactNo: 0,
      title: company,
      name: null,
      surname: null,
      type: _officeContactTypeCode(),
      taxNo: _taxNoController.text.trim(),
      taxOffice: _taxOfficeController.text.trim(),
      nationality: 'TR',
      sex: null,
      eMail: _emailController.text.trim(),
      tel: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
      status: _isActive ? 1 : 0,
      updatedAt: null,
      createdAt: nowIso,
      source: null,
      typeDescription: _selectedPersonType ?? 'Zecorner Ofis',
      isCompany: true,
      isEmployee: false,
      isAgency: true,
      picture: pictureId,
      marketingCommunicationPermission: false,
      address: _addressController.text.trim(),
      district: _selectedDistrict,
      postCode: null,
      city: _selectedCity,
      country: 'TR',
      addressSource: null,
      provinceCode: codes.provinceCode,
      provinceName: _selectedCity,
      districtCode: codes.districtCode,
      districtName: _selectedDistrict,
      quarterCode: codes.quarterCode,
      quarterName: _selectedNeighborhood,
      connectedContact: null,
      connectedContactTitle: null,
      connectedContactType: null,
      connectedContactDescription: null,
      isCustomer: false,
      slug: slug,
      tradeName: _commercialTitleController.text.trim().isEmpty
          ? null
          : _commercialTitleController.text.trim(),
      detailRef: null,
    );

    final createResult = await _officeRepository.createOffice(office);

    if (!mounted) return;
    setState(() => _isSaving = false);

    createResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(failure)), backgroundColor: _errorRed),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ofis başarıyla kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxNoController.dispose();
    _taxOfficeController.dispose();
    _addressController.dispose();
    _commercialTitleController.dispose();
    _billingAddressController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    _responsibleAdminController.dispose();
    _officeYearController.dispose();
    _officeDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: const SizedBox(),
        title: const Text('Yeni Ofis Ekle', style: TextStyle(color: _sectionTitleColor, fontSize: 20, fontWeight: FontWeight.bold)),
        titleSpacing: 20,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: _primaryRed, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fullWidthButton('Tüzel Kişi'),
                    const SizedBox(height: 20),
                    _switchRow('Durum', _isActive, (v) => setState(() => _isActive = v), _isActive ? 'Aktif' : 'Pasif', _isActive ? Colors.green : Colors.red),
                    const SizedBox(height: 16),
                    _switchRow('Kurulum Aşamasında', _isInstallationPhase, (v) => setState(() => _isInstallationPhase = v), _isInstallationPhase ? 'Evet' : 'Hayır', _primaryRed),
                    const SizedBox(height: 24),
                    _label('Ofis Türü *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'Seçiniz',
                      value: _selectedPersonType,
                      items: const ['Ofis Yöneticisi', 'Zecorner Ofis', 'Broker', 'Danışman', 'Yönetici'],
                      onChanged: (v) => setState(() => _selectedPersonType = v),
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 20),
                    _label('Ofis Bölgesi *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'Seçiniz',
                      value: _selectedRegion,
                      items: _regionOrProvinceItems,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          _selectedRegion = v;
                          _selectedCity = v;
                          _selectedDistrict = null;
                          _selectedNeighborhood = null;
                          _districtOptions = [];
                          _quarterOptions = [];
                        });
                        await _loadDistrictsForProvinceName(v);
                        await _syncMapWithSelectedLocation();
                      },
                      validator: _validateDropdown,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Şirket Bilgileri'),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fileField('Fotoğraf *', _selectedPhoto, 'Dosya seçiniz', _pickPhoto, _showPhotoError),
                    const SizedBox(height: 16),
                    _fileField('Logo *', _selectedLogo, 'Dosya seçiniz', _pickLogo, _showLogoError),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _decoration('Telefon *', hint: '+90 (555) 000-0000'),
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoration('E-posta *', hint: 'ornek@email.com'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: _decoration('Şirket Adı *'),
                      validator: _validateCompanyName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxNoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _decoration('Vergi No *'),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxOfficeController,
                      decoration: _decoration('Vergi Daire *'),
                      validator: _validateRequired,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Sosyal Medya'),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(controller: _linkedInController, decoration: _decoration('LinkedIn', hint: 'linkedin.com/...')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _twitterController, decoration: _decoration('X (Twitter)', hint: 'x.com/...')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _instagramController, decoration: _decoration('Instagram', hint: 'instagram.com/...')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _facebookController, decoration: _decoration('Facebook', hint: 'facebook.com/...')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _whatsappController, decoration: _decoration('WhatsApp', hint: '+90 (555) 000-0000')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Detay Bilgileri'),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(controller: _commercialTitleController, decoration: _decoration('Ticari Ünvan')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _billingAddressController, maxLines: 2, decoration: _decoration('Fatura Adresi', isDense: false)),
                    const SizedBox(height: 16),
                    _dateField('Sözleşme Başlangıç Tarihi', _contractStartDate, () => _selectDate(context, true, false, false)),
                    const SizedBox(height: 16),
                    _dateField('Sözleşme Bitiş Tarihi', _contractEndDate, () => _selectDate(context, false, true, false)),
                    const SizedBox(height: 16),
                    _dateField('Teknoloji Bedeli Ne Zaman alınacak', _techFeeDate, () => _selectDate(context, false, false, true)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _responsibleAdminController,
                      decoration: _decoration('Sorumlu Sistem Yöneticisi', hint: 'Ara', suffixIcon: const Icon(Icons.search, color: _hintColor, size: 22)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _officeYearController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration('Ofis Yılı'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Adres Bilgileri'),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_refLocationLoading) ...[
                      const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                    ],
                    _label('İl Seçiniz *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'İl Seçiniz',
                      value: _selectedCity,
                      items: _provinceOptions.isNotEmpty ? _provinceOptions : _regionOrProvinceItems,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() {
                          _selectedCity = v;
                          _selectedRegion = v;
                          _selectedDistrict = null;
                          _selectedNeighborhood = null;
                          _districtOptions = [];
                          _quarterOptions = [];
                        });
                        await _loadDistrictsForProvinceName(v);
                        await _syncMapWithSelectedLocation();
                      },
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    _label('İlçe Seçiniz *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'İlçe Seçiniz',
                      value: _selectedDistrict,
                      items: _districtOptions,
                      onChanged: _selectedCity != null && _districtOptions.isNotEmpty
                          ? (v) {
                              setState(() {
                                _selectedDistrict = v;
                                _selectedNeighborhood = null;
                                final d = v == null || _districtsDetailCache == null
                                    ? null
                                    : resolveDistrictModel(_districtsDetailCache!, v);
                                _quarterOptions = d == null
                                    ? []
                                    : (d.quarters.map((q) => q.name).toList()..sort());
                              });
                              _syncMapWithSelectedLocation();
                            }
                          : null,
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    _label(_quarterOptions.isEmpty ? 'Mahalle Seçiniz' : 'Mahalle Seçiniz *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'Mahalle Seçiniz',
                      value: _selectedNeighborhood,
                      items: _quarterOptions,
                      onChanged: _selectedDistrict != null && _quarterOptions.isNotEmpty
                          ? (v) {
                              setState(() => _selectedNeighborhood = v);
                              _syncMapWithSelectedLocation();
                            }
                          : null,
                      validator: _quarterOptions.isEmpty ? null : _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      onChanged: (value) {
                        if (value.trim().isNotEmpty) {
                          final captured = value;
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            if (_addressController.text == captured && mounted) {
                              _getPositionFromAddress(captured.trim());
                            }
                          });
                        }
                      },
                      decoration: _decoration('Ofis Adresi *', isDense: false),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    _label('Ofis açıklaması'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _officeDescriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: _decoration(
                        'Kısa açıklama (isteğe bağlı)',
                        hint: 'Ofisinizi tanıtan bir metin ekleyebilirsiniz…',
                        isDense: false,
                      ).copyWith(counterStyle: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    _label('Harita konumu'),
                    const SizedBox(height: 8),
                    _buildMapSection(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Belgeler'),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _docField('Findeks Notu', 'findeks'),
                    _docField('Şirket İmza Sirküsü', 'imzaSirkusu'),
                    _docField('Vergi Levhası', 'vergiLevhasi'),
                    _docField('Faaliyet Belgesi', 'faaliyetBelgesi'),
                    _docField('Son Üç Aya Ait KDV Tahakkuk Fişi', 'kdvFisi'),
                    _docField('Ticaret Sicil Gazetesi', 'ticaretSicil'),
                    _docField('Taşınmaz Yetki Belgesi', 'yetkiBelgesi'),
                    _docField('Sözleşme Belgesi', 'sozlesmeBelgesi'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveOffice(),
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryRed, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _sectionTitleColor)),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: _borderColor),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))]),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor));
  }

  Widget _fullWidthButton(String text) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(color: _primaryRed, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged, String statusText, Color statusColor) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor))),
        Switch.adaptive(value: value, onChanged: onChanged, activeColor: _primaryRed),
        const SizedBox(width: 8),
        Text(statusText, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMapSection() {
    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedLocation != null
            ? Center(
                child: MapDisplayWidget(
                  position: _selectedLocation,
                  address: _selectedLocationAddress,
                  onTap: _openMapPicker,
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Harita konumu',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedLocationAddress ?? 'Konumu seçmek veya adres yazdıktan sonra güncellemek için dokunun',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _dropdown({required String hint, required String? value, required List<String> items, required ValueChanged<String?>? onChanged, String? Function(String?)? validator}) {
    final outline = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor));
    final errorOutline = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _errorRed, width: 2));
    return DropdownButtonFormField<String>(
      value: items.isEmpty ? null : (items.contains(value) ? value : null),
      hint: Text(hint, style: const TextStyle(color: _hintColor, fontSize: 14)),
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(borderSide: const BorderSide(color: _primaryRed, width: 2)),
        errorBorder: errorOutline,
        focusedErrorBorder: errorOutline,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: _hintColor),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _fileField(String label, File? file, String placeholder, VoidCallback onTap, [bool showError = false]) {
    final hasFile = file != null;
    final borderColor = (showError && !hasFile) ? _errorRed : _borderColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor, width: (showError && !hasFile) ? 2 : 1)),
        child: Row(
          children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor)), const SizedBox(height: 4), Text(hasFile ? file.path.split('/').last : placeholder, style: TextStyle(fontSize: 13, color: hasFile ? _labelColor : _hintColor), maxLines: 1, overflow: TextOverflow.ellipsis)])),
            Icon(hasFile ? Icons.check_circle : Icons.add_circle_outline, color: hasFile ? Colors.green : _primaryRed, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    String hint = 'Tarih seçiniz';
    if (label.contains('Başlangıç')) hint = 'Başlangıç tarihi seçiniz';
    if (label.contains('Bitiş')) hint = 'Bitiş tarihi seçiniz';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(label, hint: hint, suffixIcon: const Icon(Icons.calendar_today, color: _hintColor, size: 20)),
        child: Text(date != null ? DateFormat('dd.MM.yyyy').format(date) : '', style: TextStyle(color: date != null ? _labelColor : _hintColor, fontSize: 14)),
      ),
    );
  }

  Widget _docField(String title, String documentType) {
    final file = _documents[documentType];
    final hasFile = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _pickDocument(documentType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor)), const SizedBox(height: 4), Text(hasFile ? file.path.split('/').last : 'Dosya seçiniz', style: TextStyle(fontSize: 13, color: hasFile ? _labelColor : _hintColor), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              Icon(hasFile ? Icons.check_circle : Icons.description_outlined, color: hasFile ? Colors.green : _primaryRed, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
