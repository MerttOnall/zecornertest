import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/core/location/nominatim_geocoding.dart';
import 'package:zecorner/presentation/widgets/map_widget.dart';
import 'package:zecorner/infrastructure/office/office_api_repository.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/office/office_api_model.dart';
import 'package:zecorner/core/location/ref_location_resolution.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';

// Add ekranı ile aynı tasarım sabitleri
const _primaryRed = Color(0xFFE53935);
const _cardBg = Color(0xFFFAFAFA);
const _sectionTitleColor = Color(0xFF1A1A1A);
const _labelColor = Color(0xFF424242);
const _hintColor = Color(0xFF9E9E9E);
const _borderColor = Color(0xFFE0E0E0);
const _errorRed = Color(0xFFD32F2F);

// Import the OfficePerson model from myoffice_screen
class OfficePerson {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String office;
  final String personNo;
  final String userType;
  final String status;
  final int? statusCode;
  final String registrationDate;
  final String personCount;
  final bool isActive;
  final String? address;
  final String? city;
  final String? district;
  final String? tradeName;
  final String? detailRef;

  OfficePerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.office,
    required this.personNo,
    required this.userType,
    required this.status,
    this.statusCode,
    required this.registrationDate,
    required this.personCount,
    required this.isActive,
    this.address,
    this.city,
    this.district,
    this.tradeName,
    this.detailRef,
  });

  String get fullName => '$firstName $lastName';
}

class EditOfficeScreen extends StatefulWidget {
  const EditOfficeScreen({super.key});

  @override
  State<EditOfficeScreen> createState() => _EditOfficeScreenState();
}

class _EditOfficeScreenState extends State<EditOfficeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isActive = true;
  bool _isInstallationPhase = false;
  bool _controllersInitialized = false;
  OfficePerson? officeData;
  bool _isLoading = false;
  final OfficeApiRepository _officeRepository = OfficeApiRepository();
  final ContactApiRepository _contactApiRepository = ContactApiRepository();

  late final TextEditingController _companyNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxNoController;
  late final TextEditingController _taxOfficeController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _commercialTitleController;
  late final TextEditingController _billingAddressController;
  late final TextEditingController _linkedInController;
  late final TextEditingController _twitterController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _responsibleAdminController;
  late final TextEditingController _officeYearController;

  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  DateTime? _techFeeDate;
  
  String? _selectedPersonType;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  
  // Harita değişkenleri
  LatLng? _selectedLocation;
  String? _selectedLocationAddress;

  // Dosya yolları - add missing file handling
  File? _selectedPhoto;
  File? _selectedLogo;
  Map<String, File?> _documents = {
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

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }
    if (value.length < 2) {
      return 'En az 2 karakter olmalıdır';
    }
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞIÖÇ\s]+$').hasMatch(value)) {
      return 'Sadece harfler kullanılabilir';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası zorunludur';
    }
    if (value.length != 10) {
      return 'Telefon numarası 10 haneli olmalıdır';
    }
    if (!value.startsWith('5')) {
      return 'Telefon numarası 5 ile başlamalıdır';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi zorunludur';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }
    return null;
  }

  String? _validateDropdown(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen bir seçim yapınız';
    }
    return null;
  }

  // Add image picker methods
  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
      if (image != null) setState(() => _selectedPhoto = File(image.path));
    } catch (_) {}
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) setState(() => _selectedLogo = File(image.path));
    } catch (_) {}
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _documents[documentType] = File(result.files.single.path!));
      }
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
            datePickerTheme: const DatePickerThemeData(
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

  void _addMarker(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  Future<void> _getAddressFromPosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          _selectedLocationAddress = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocationAddress = 'Adres alınamadı';
      });
    }
  }

  Future<void> _getPositionFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations[0];
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });
        await _getAddressFromPosition(_selectedLocation!);
      }
    } catch (e) {
      // Adres bulunamazsa varsayılan konum kullan
      setState(() {
        _selectedLocation = const LatLng(39.4167, 29.9833); // Kütahya
        _selectedLocationAddress = address;
      });
    }
  }



  Future<void> _selectLocation() async {
    // Önce mevcut adres alanındaki bilgilere göre haritayı güncelle
    if (_addressController.text.isNotEmpty) {
      await _getPositionFromAddress(_addressController.text);
    }
    
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialPosition: _selectedLocation,
          selectedAddress: _selectedLocationAddress,
          onLocationSelected: (LatLng position) {
            setState(() {
              _selectedLocation = position;
              _addMarker(position);
            });
            _getAddressFromPosition(position);
          },
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _addMarker(result);
      });
      await _getAddressFromPosition(result);
    }
  }

  // API'den konum güncelleme fonksiyonu
  Future<void> updateLocationFromAPI(double latitude, double longitude, String address) async {
    setState(() {
      _selectedLocation = LatLng(latitude, longitude);
      _selectedLocationAddress = address;
    });
  }


  /// Ref API ile aynı isimler — sabit liste kaldırıldı (VM eşlemesi için şart).
  ProvincesResponseModel? _provincesModel;
  ProvincesDetailResponseModel? _districtsDetailCache;
  List<String> _provinceOptions = [];
  List<String> _districtOptions = [];
  List<String> _quarterOptions = [];
  bool _refLocationLoading = false;

  List<String> get _regionOrProvinceItems =>
      _provinceOptions.isNotEmpty ? _provinceOptions : _regionItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is OfficePerson) {
      officeData = args;
      _initializeControllers();
    } else {
      _initializeWithDefaults();
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrapRefAddresses();
    });
  }

  void _initializeControllers() {
    if (officeData != null) {
      _companyNameController = TextEditingController(text: officeData!.office);
      _emailController = TextEditingController(text: officeData!.email);
      _phoneController = TextEditingController(text: "5555555555"); // Only digits for validation
      _taxNoController = TextEditingController(text: "2904803367");
      _taxOfficeController = TextEditingController(text: "Vergi Dairesi");
      _addressController = TextEditingController(text: officeData!.address ?? "Adres bilgisi yok");
      _descriptionController = TextEditingController(text: "Modern ve teknolojik altyapıya sahip ofisimizde, alanında uzman ekibimizle emlak ihtiyaçlarınıza çözüm üretiyoruz. Güvenilir ve profesyonel hizmet anlayışımızla yanınızdayız.");
      _commercialTitleController = TextEditingController(text: officeData!.tradeName ?? '');
      _billingAddressController = TextEditingController();
      _linkedInController = TextEditingController();
      _twitterController = TextEditingController();
      _instagramController = TextEditingController();
      _facebookController = TextEditingController();
      _whatsappController = TextEditingController();
      _responsibleAdminController = TextEditingController();
      _officeYearController = TextEditingController(text: '0');

      // Dropdown değerlerini güvenli şekilde ayarla
      _selectedPersonType = ["Ofis Yöneticisi", "Zecorner Ofis", "Broker", "Danışman", "Yönetici"].contains(officeData!.userType) 
          ? officeData!.userType 
          : "Zecorner Ofis";
      final cityHint = officeData!.city?.trim();
      _selectedRegion = (cityHint != null && cityHint.isNotEmpty) ? cityHint : "Kütahya";
      _selectedCity = (cityHint != null && cityHint.isNotEmpty) ? cityHint : "Kütahya";
      _selectedDistrict = officeData!.district?.trim().isNotEmpty == true ? officeData!.district!.trim() : null;
      _selectedNeighborhood = null;
      _isActive = officeData!.isActive;
      
      // Adres bilgisine göre harita konumunu güncelle
      if (officeData!.address != null && officeData!.address!.isNotEmpty) {
        _getPositionFromAddress(officeData!.address!);
      } else {
        // Varsayılan konum
        _selectedLocation = const LatLng(39.4167, 29.9833);
        _selectedLocationAddress = "Kütahya, Türkiye";
      }
    }
  }

  void _initializeWithDefaults() {
    _companyNameController = TextEditingController(text: "DveB Emlak Ofisi");
    _emailController = TextEditingController(text: "info@dveb.com.tr");
    _phoneController = TextEditingController(text: "5555555555"); // Only digits for validation
    _taxNoController = TextEditingController(text: "1234567890");
    _taxOfficeController = TextEditingController(text: "Kütahya Vergi Dairesi");
    _addressController = TextEditingController(text: "Dumlupınar Üniversitesi Kampüsü Merkez/Kütahya");
    _descriptionController = TextEditingController(text: "Modern ve teknolojik altyapıya sahip ofisimizde, alanında uzman ekibimizle emlak ihtiyaçlarınıza çözüm üretiyoruz. Güvenilir ve profesyonel hizmet anlayışımızla yanınızdayız.");
    _commercialTitleController = TextEditingController();
    _billingAddressController = TextEditingController();
    _linkedInController = TextEditingController();
    _twitterController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _whatsappController = TextEditingController();
    _responsibleAdminController = TextEditingController();
    _officeYearController = TextEditingController(text: '0');

    _selectedPersonType = "Zecorner Ofis";
    _selectedRegion = "Kütahya";
    _selectedCity = "Kütahya";
    _selectedDistrict = "Merkez";
    _selectedNeighborhood = null;
    
    // Harita için varsayılan konum (Kütahya)
    _selectedLocation = const LatLng(39.4167, 29.9833);
    _selectedLocationAddress = "Kütahya, Türkiye";
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
    p ??= provinces.getProvinceByName(officeData?.city ?? '');
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

    final wantDistrict = _selectedDistrict ?? officeData?.district;
    DistrictModel? d;
    if (wantDistrict != null && wantDistrict.trim().isNotEmpty) {
      d = resolveDistrictModel(detail, wantDistrict);
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

  static const List<String> _personTypeItems = [
    "Ofis Yöneticisi",
    "Zecorner Ofis",
    "Broker",
    "Danışman",
    "Yönetici",
  ];

  static const List<String> _regionItems = ["Muğla", "Kütahya", "İstanbul", "Ankara", "İzmir"];

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _sectionTitleColor));
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
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

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
    String? Function(String?)? validator,
  }) {
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

  Widget _fileFieldOptional(String label, File? file, String placeholder, VoidCallback onTap) {
    final hasFile = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor)),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? file.path.split('/').last : placeholder,
                    style: TextStyle(fontSize: 13, color: hasFile ? _labelColor : _hintColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
    if (label.contains('Teknoloji')) hint = 'Tarih seçiniz';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(label, hint: hint, suffixIcon: const Icon(Icons.calendar_today, color: _hintColor, size: 20)),
        child: Text(
          date != null ? DateFormat('dd.MM.yyyy').format(date) : '',
          style: TextStyle(color: date != null ? _labelColor : _hintColor, fontSize: 14),
        ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _labelColor)),
                    const SizedBox(height: 4),
                    Text(
                      hasFile ? file.path.split('/').last : 'Dosya seçiniz',
                      style: TextStyle(fontSize: 13, color: hasFile ? _labelColor : _hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(hasFile ? Icons.check_circle : Icons.description_outlined, color: hasFile ? Colors.green : _primaryRed, size: 24),
            ],
          ),
        ),
      ),
    );
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
        title: const Text('Ofis Düzenle', style: TextStyle(color: _sectionTitleColor, fontSize: 20, fontWeight: FontWeight.bold)),
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
                    _switchRow('Durum', _isActive, (v) => setState(() => _isActive = v), _isActive ? 'Aktif' : 'Pasif', _isActive ? Colors.green : _hintColor),
                    const SizedBox(height: 16),
                    _switchRow(
                      'Kurulum Aşamasında',
                      _isInstallationPhase,
                      (v) => setState(() => _isInstallationPhase = v),
                      _isInstallationPhase ? 'Evet' : 'Hayır',
                      _primaryRed,
                    ),
                    const SizedBox(height: 24),
                    _label('Ofis türü *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'Seçiniz',
                      value: _selectedPersonType,
                      items: _personTypeItems,
                      onChanged: (v) => setState(() => _selectedPersonType = v),
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 20),
                    _label('Ofis bölgesi *'),
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
                      },
                      validator: _validateDropdown,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Şirket Bilgileri'),
              const SizedBox(height: 12),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fileFieldOptional('Fotoğraf', _selectedPhoto, 'Dosya seçiniz', _pickPhoto),
                    const SizedBox(height: 16),
                    _fileFieldOptional('Logo', _selectedLogo, 'Dosya seçiniz', _pickLogo),
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
                      decoration: _decoration('Şirket adı *'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxNoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _decoration('Vergi no *'),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxOfficeController,
                      decoration: _decoration('Vergi daire *'),
                      validator: _validateRequired,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Sosyal Medya'),
              const SizedBox(height: 12),
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
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration('WhatsApp', hint: '+90 (555) 000-0000'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Detay Bilgileri'),
              const SizedBox(height: 12),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(controller: _commercialTitleController, decoration: _decoration('Ticari ünvan')),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _billingAddressController,
                      maxLines: 2,
                      decoration: _decoration('Fatura adresi', isDense: false),
                    ),
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
                      decoration: _decoration('Ofis yılı'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Adres Bilgileri'),
              const SizedBox(height: 12),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_refLocationLoading) ...[
                      const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                    ],
                    _label('İl *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'İl seçiniz',
                      value: _selectedCity,
                      items: _provinceOptions.isNotEmpty ? _provinceOptions : _regionOrProvinceItems,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          _selectedCity = value;
                          _selectedRegion = value;
                          _selectedDistrict = null;
                          _selectedNeighborhood = null;
                          _districtOptions = [];
                          _quarterOptions = [];
                        });
                        await _loadDistrictsForProvinceName(value);
                      },
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    _label('İlçe *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'İlçe seçiniz',
                      value: _selectedDistrict,
                      items: _districtOptions,
                      onChanged: _selectedCity != null && _districtOptions.isNotEmpty
                          ? (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _selectedNeighborhood = null;
                                final d = value == null ? null : _districtsDetailCache?.getDistrictByName(value);
                                _quarterOptions = d == null
                                    ? []
                                    : (d.quarters.map((q) => q.name).toList()..sort());
                              });
                            }
                          : null,
                      validator: _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    _label(_quarterOptions.isEmpty ? 'Mahalle' : 'Mahalle *'),
                    const SizedBox(height: 8),
                    _dropdown(
                      hint: 'Mahalle seçiniz',
                      value: _selectedNeighborhood,
                      items: _quarterOptions,
                      onChanged: _selectedDistrict != null && _quarterOptions.isNotEmpty
                          ? (value) => setState(() => _selectedNeighborhood = value)
                          : null,
                      validator: _quarterOptions.isEmpty ? null : _validateDropdown,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            if (_addressController.text == value) {
                              _getPositionFromAddress(value);
                            }
                          });
                        }
                      },
                      decoration: _decoration('Ofis adresi *', isDense: false),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 20),
                    _label('Ofis açıklaması'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: _decoration(
                        'Ofis hakkında açıklama yazınız',
                        hint: 'Ofisinizin özelliklerini, konumunu ve sunduğu hizmetleri açıklayınız...',
                        isDense: false,
                      ).copyWith(counterStyle: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ofis açıklaması zorunludur';
                        if (value.length < 20) return 'Açıklama en az 20 karakter olmalıdır';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _label('Harita konumu'),
                    const SizedBox(height: 8),
                    _buildMapSection(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Belgeler'),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              _sectionCard(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kayıt tarihi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            officeData?.registrationDate.replaceAll('\n', ' ') ?? '28/05/2024',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _sectionTitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateOffice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Ofis bilgilerini güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return GestureDetector(
      onTap: () async {
        // Harita kartına tıklandığında adres bilgilerine göre haritayı güncelle
        if (_addressController.text.isNotEmpty) {
          await _getPositionFromAddress(_addressController.text);
        }
        _selectLocation();
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: _selectedLocation != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MapDisplayWidget(
                  position: _selectedLocation,
                  address: _selectedLocationAddress,
                  onTap: () async {
                    if (_addressController.text.isNotEmpty) {
                      await _getPositionFromAddress(_addressController.text);
                    }
                    _selectLocation();
                  },
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Harita Konumu",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedLocationAddress ?? "Konum seçmek için tıklayın",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// BAMMA VM_DETAIL; adres için sayısal il/ilçe/mahalle kodları şart — ref API ile eşlenir.
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

  int _officeContactTypeCode() {
    if (_selectedPersonType == 'Broker') return 102;
    return 101;
  }

  // Update office API call
  Future<void> _updateOffice() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldurunuz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (officeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ofis bilgileri yüklenemedi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final codes = await _resolveLocationCodes();
      if (codes.provinceCode == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İl bilgisi ref veride bulunamadı. Lütfen listeden geçerli bir il seçin.'),
              backgroundColor: _errorRed,
            ),
          );
        }
        return;
      }
      if (_selectedDistrict != null &&
          _selectedDistrict!.trim().isNotEmpty &&
          codes.districtCode == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İlçe kodu bulunamadı. İl/ilçe seçimini ref listesine uygun yapın.'),
              backgroundColor: _errorRed,
            ),
          );
        }
        return;
      }

      // Ofis modelini oluştur
      final updatedOffice = OfficeApiModel(
        contactNo: int.parse(officeData!.personNo),
        title: _companyNameController.text.trim(),
        name: null, // Office için name/surname null
        surname: null,
        type: _officeContactTypeCode(),
        tcIdNumber: null,
        taxNo: _taxNoController.text.trim(),
        taxOffice: _taxOfficeController.text.trim(),
        nationality: 'TR',
        sex: null,
        eMail: _emailController.text.trim(),
        tel: _phoneController.text.replaceAll(' ', ''),
        status: _isActive ? 1 : 0,
        updatedAt: DateTime.now().toIso8601String(),
        createdAt: officeData!.registrationDate,
        source: null,
        typeDescription: _selectedPersonType ?? 'Zecorner Ofis',
        isCompany: true,
        isEmployee: false,
        isAgency: true,
        birthday: null,
        professionCode: null,
        professionDescription: null,
        educationCode: null,
        educationDescription: null,
        whereYouHeardUs: null,
        sectoralExperience: null,
        picture: null,
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
        slug: officeData!.office.toLowerCase().replaceAll(' ', '-'),
        tradeName: _commercialTitleController.text.trim().isEmpty
            ? null
            : _commercialTitleController.text.trim(),
        detailRef: officeData!.detailRef,
      );

      final result = await _officeRepository.updateOffice(
        int.parse(officeData!.personNo),
        updatedOffice,
      );

      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ofis bilgileri başarıyla güncellendi!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxNoController.dispose();
    _taxOfficeController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _commercialTitleController.dispose();
    _billingAddressController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    _responsibleAdminController.dispose();
    _officeYearController.dispose();
    super.dispose();
  }
}

