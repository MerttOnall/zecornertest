import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as dtp;
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/customer/customer_api_repository.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/customer/customer_api_model.dart';
import 'package:zecorner/models/realestate/search_realestate_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/realestate/search_realestate_repo.dart';
import 'package:zecorner/core/utils/image_utils.dart';

// Telefon numarası formatter. Ülke kodu alanın ön eki olarak durur;
// buraya yalnızca 10 haneli numara yazılır: (555) 000-0000
class PhoneNumberFormatter extends TextInputFormatter {
  static String localDigits(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }
    return digits;
  }

  static String formatLocal(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 10; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 2) {
        buffer.write(') ');
      } else if (i == 5) {
        buffer.write('-');
      }
    }
    return buffer.toString();
  }

  static int _offsetForDigits(String formatted, int count) {
    if (count <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final code = formatted.codeUnitAt(i);
      if (code >= 48 && code <= 57) {
        seen++;
        if (seen == count) {
          var end = i + 1;
          if (end < formatted.length && formatted[end] == ')') end++;
          if (end < formatted.length && formatted[end] == ' ') end++;
          return end;
        }
      }
    }
    return formatted.length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = localDigits(oldValue.text);
    var digits = localDigits(newValue.text);
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    var cursorDigits = localDigits(newValue.text.substring(0, cursor)).length;
    final deleting = newValue.text.length < oldValue.text.length;

    // Parantez, boşluk veya tire silinince hane yerinde kalsın diye
    // imlecin önündeki rakamı sil.
    if (deleting && digits == oldDigits && digits.isNotEmpty) {
      final removeAt = cursorDigits > 0 ? cursorDigits - 1 : digits.length - 1;
      digits = digits.substring(0, removeAt) + digits.substring(removeAt + 1);
      cursorDigits = removeAt;
    }

    if (cursorDigits > digits.length) cursorDigits = digits.length;

    final formatted = formatLocal(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _offsetForDigits(formatted, cursorDigits),
      ),
    );
  }
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final CustomerApiRepository _customerRepository = CustomerApiRepository();
  final ContactApiRepository _contactApiRepository = ContactApiRepository();
  final ScrollController _scrollController = ScrollController();
  
  bool _isActive = true;
  bool _isLoading = false;
  List<RefCountryModel> _countries = [];
  List<RefProfessionModel> _professions = [];
  
  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _tcNumberController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _taxNumberController;
  late TextEditingController _taxOfficeController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _twitterController;
  late TextEditingController _linkedinController;
  late TextEditingController _howDidYouHearController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;
  late TextEditingController _monthlyIncomeController;
  late TextEditingController _numberOfChildrenController;
  late TextEditingController _birthDateController;
  
  // Dropdown values
  String? _selectedCustomerType;
  String? _selectedNationality = 'Türkiye';
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedExpertise;
  String? _selectedEducation;
  String? _selectedMaritalStatus;
  File? _selectedProfileImage;
  
  // Mülkler arama için
  late TextEditingController _propertiesSearchController;
  late TextEditingController _interestedListingsController;
  late FocusNode _propertiesFocusNode;
  OverlayEntry? _propertiesOverlayEntry;
  Timer? _searchTimer;
  List<SearchRealEstateModel> _searchResults = [];
  bool _isSearchingProperties = false;
  SearchRealEstateModel? _selectedProperty;
  
  // Müşteri Tipi için
  final List<String> _allCustomerTypes = [
    'Alıcı',
    'Alıcı & Satıcı',
    'Potansiyel',
    'Potansiyel Alıcı',
    'Potansiyel Satıcı',
    'Satıcı',
  ];
  
  final ImagePicker _imagePicker = ImagePicker();
  final SearchRealEstateRepository _searchRealEstateRepository = SearchRealEstateRepository();

  static const Color _brand = Color(0xFFEE2E24);
  static const Color _ink = Color(0xFF1C2430);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _icon = Color(0xFF7C8698);
  static const Color _line = Color(0xFFE6E9EF);
  static const Color _fill = Color(0xFFF5F6F8);
  static const Color _page = Color(0xFFF3F4F7);

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _tcNumberController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _taxNumberController = TextEditingController();
    _taxOfficeController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _twitterController = TextEditingController();
    _linkedinController = TextEditingController();
    _howDidYouHearController = TextEditingController();
    _notesController = TextEditingController();
    _tagsController = TextEditingController();
    _monthlyIncomeController = TextEditingController();
    _numberOfChildrenController = TextEditingController();
    _birthDateController = TextEditingController();
    _propertiesSearchController = TextEditingController();
    _interestedListingsController = TextEditingController();
    _propertiesFocusNode = FocusNode();
    
    _propertiesFocusNode.addListener(() {
      setState(() {});
    });
    
    _propertiesSearchController.addListener(_onPropertiesSearchChanged);
    _loadCountries();
    _loadProfessions();
    _monthlyIncomeController.text = '0';
    _numberOfChildrenController.text = '0';
  }

  Future<void> _loadCountries() async {
    try {
      final result = await _contactApiRepository.getCountries();
      if (mounted) {
        result.fold(
          (failure) {
            setState(() {
              _countries = [
                RefCountryModel(code: 'TR', name: 'Türkiye'),
                RefCountryModel(code: 'US', name: 'Amerika'),
                RefCountryModel(code: 'DE', name: 'Almanya'),
              ];
            });
          },
          (response) {
            setState(() => _countries = response.countries);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _countries = [
            RefCountryModel(code: 'TR', name: 'Türkiye'),
            RefCountryModel(code: 'US', name: 'Amerika'),
            RefCountryModel(code: 'DE', name: 'Almanya'),
          ];
        });
      }
    }
  }

  Future<void> _loadProfessions() async {
    try {
      final result = await _contactApiRepository.getProfessions();
      if (mounted) {
        result.fold(
          (failure) => setState(() => _professions = []),
          (response) => setState(() => _professions = response.professions),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _professions = []);
    }
  }

  String _getNationalityCode() {
    if (_selectedNationality == null) return 'TR';
    try {
      return _countries.firstWhere((c) => c.name == _selectedNationality).code;
    } catch (_) {
      return 'TR';
    }
  }

  Profession? _getSelectedProfession() {
    if (_selectedExpertise == null) return null;
    try {
      final p = _professions.firstWhere((x) => x.description == _selectedExpertise);
      return Profession(id: p.code, code: p.code, description: p.description);
    } catch (_) {
      return Profession(id: null, code: null, description: _selectedExpertise);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _tcNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _taxNumberController.dispose();
    _taxOfficeController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _howDidYouHearController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _monthlyIncomeController.dispose();
    _numberOfChildrenController.dispose();
    _birthDateController.dispose();
    _propertiesSearchController.dispose();
    _interestedListingsController.dispose();
    _propertiesFocusNode.dispose();
    _searchTimer?.cancel();
    _removePropertiesOverlay();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _formatDateForApi(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _pickBirthDate() async {
    final initial = _selectedBirthDate ?? DateTime(1990, 1, 1);
    dtp.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(1900, 1, 1),
      maxTime: DateTime.now(),
      currentTime: initial,
      locale: dtp.LocaleType.tr,
      theme: const dtp.DatePickerTheme(
        headerColor: Color.fromRGBO(238, 46, 36, 1),
        backgroundColor: Color.fromRGBO(238, 46, 36, 1),
        itemStyle: TextStyle(color: Colors.white),
        doneStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        cancelStyle: TextStyle(color: Colors.white),
      ),
      onConfirm: (picked) {
        setState(() {
          _selectedBirthDate = picked;
          _birthDateController.text = _formatDateForDisplay(picked);
        });
      },
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Fotoğraf Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 46, 36, 1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Galeriden Seç',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 46, 36, 1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Kamera ile Çek',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf başarıyla seçildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera açılırken bir hata oluştu: $e'
                : 'Fotoğraf seçilirken bir hata oluştu: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPropertiesSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _searchProperties();
    });
  }

  Future<void> _searchProperties() async {
    final query = _propertiesSearchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingProperties = false;
      });
      _updatePropertiesOverlay();
      return;
    }

    setState(() {
      _isSearchingProperties = true;
    });

    final result = await _searchRealEstateRepository.searchRealEstatesForCustomer(
      query: query,
      size: 20,
    );

    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isSearchingProperties = false;
            _searchResults = [];
          });
          _updatePropertiesOverlay();
        }
      },
      (response) {
        if (mounted) {
          setState(() {
            _isSearchingProperties = false;
            _searchResults = response.realEstates;
          });
          _updatePropertiesOverlay();
        }
      },
    );
  }

  void _removePropertiesOverlay() {
    _propertiesOverlayEntry?.remove();
    _propertiesOverlayEntry = null;
  }

  void _updatePropertiesOverlay() {
    if (mounted) setState(() {});
  }

  Widget _buildPropertyThumbnail(String thumbnail) {
    if (thumbnail.isEmpty) {
      return Icon(
        Icons.home,
        color: Colors.grey[400],
        size: 24,
      );
    }

    String imageUrl;
    if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
      imageUrl = thumbnail;
    } else if (ImageUtils.isValidS3Id(thumbnail)) {
      imageUrl = ImageUtils.getCoverImageUrl(thumbnail);
    } else {
      return Icon(
        Icons.home,
        color: Colors.grey[400],
        size: 24,
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(238, 46, 36, 1),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.home,
            color: Colors.grey[400],
            size: 24,
          );
        },
      ),
    );
  }

  /// Mülk arama sonuçları listesi - form içinde gösterilir, overlay kullanılmaz (kaydırma/klavye ile ayrılmaz).
  Widget _buildPropertiesListInline() {
    final query = _propertiesSearchController.text.trim();
    final hasResults = _searchResults.isNotEmpty;
    final showEmpty = query.isNotEmpty && !_isSearchingProperties && !hasResults;
    final showList = _propertiesFocusNode.hasFocus || query.isNotEmpty;

    if (!showList) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
        child: _isSearchingProperties
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(238, 46, 36, 1),
                  ),
                ),
              )
            : showEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Sonuç bulunamadı',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : hasResults
                    ? ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final property = _searchResults[index];
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedProperty = property;
                                _propertiesSearchController.text = property.title;
                              });
                              _propertiesFocusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: _buildPropertyThumbnail(property.thumbnail),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      property.title.isNotEmpty
                                          ? property.title
                                          : 'Başlıksız Mülk',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
    );
  }

  void _showSelectionModal({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
    bool showSearch = false,
  }) {
    TextEditingController searchController = TextEditingController();
    List<String> filteredItems = List.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: _muted),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    if (showSearch)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          controller: searchController,
                          cursorColor: _brand,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ara...',
                            hintStyle: const TextStyle(color: Color(0xFFB4BCC8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: _brand),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _brand,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setModalState(() {
                              if (value.isEmpty) {
                                filteredItems = List.from(items);
                              } else {
                                filteredItems = items
                                    .where((item) => item.toLowerCase().contains(value.toLowerCase()))
                                    .toList();
                              }
                            });
                          },
                        ),
                      ),
                    Flexible(
                      child: filteredItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Sonuç bulunamadı',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = selectedValue == item;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Material(
                                    color: isSelected
                                        ? const Color(0xFFFFF1F0)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        onSelected(item);
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: isSelected ? _brand : _ink,
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_rounded,
                                                color: _brand,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createCustomer() async {
    // Önce müşteri tipi kontrolü
    if (_selectedCustomerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen müşteri tipini seçiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Form validasyonu
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldurunuz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customerTypeCode =
          CustomerApiModel.typeCodeForLabel(_selectedCustomerType) ?? 201;
      
      // Ülke kodu sadece ekranda. Kayıt, kişi formundaki gibi 10 haneli numara.
      final phoneFormatted = PhoneNumberFormatter.localDigits(_phoneController.text);
      
      // Profil fotoğrafı upload et (eğer seçildiyse)
      String? uploadedPictureId;
      if (_selectedProfileImage != null) {
        final uploadResult = await _customerRepository.uploadProfilePicture(_selectedProfileImage!);
        uploadResult.fold(
          (failure) {
            uploadedPictureId = null;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profil fotoğrafı yüklenemedi: ${failure.message}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          (pictureId) {
            uploadedPictureId = pictureId;
          },
        );
      }
      
      final newCustomer = CustomerApiModel(
        contactNo: 0, // Backend will assign
        title: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        name: _firstNameController.text.trim(),
        surname: _lastNameController.text.trim(),
        type: customerTypeCode,
        typeDescription: _selectedCustomerType!,
        tcIdNumber: _tcNumberController.text.trim().isEmpty ? null : _tcNumberController.text.trim(),
        taxNo: _taxNumberController.text.trim().isEmpty ? '' : _taxNumberController.text.trim(),
        taxOffice: _taxOfficeController.text.trim().isEmpty ? '' : _taxOfficeController.text.trim(),
        nationality: _getNationalityCode(),
        sex: _selectedGender == 'Erkek'
            ? 'M'
            : _selectedGender == 'Kadın'
                ? 'F'
                : null,
        eMail: _emailController.text.trim(),
        tel: phoneFormatted,
        status: _isActive ? 1 : 0,
        updatedAt: '',
        source: null,
        detail: CustomerDetail(
          id: '',
          birthday: _selectedBirthDate != null ? _formatDateForApi(_selectedBirthDate!) : null,
          profession: _getSelectedProfession(),
          education: _selectedEducation != null
              ? Education(
                  id: null,
                  code: null,
                  description: _selectedEducation,
                )
              : null,
          socialMedia: SocialMedia(
            instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
            facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
            x: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
            linkedin: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
          ),
          whereYouHeardUs: _howDidYouHearController.text.trim().isEmpty ? '' : _howDidYouHearController.text.trim(),
          coverLetter: _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
          sectoralExperience: null,
          picture: uploadedPictureId,
          reference: null,
          areasOfExpertise: null,
          marketingCommunicationPermission: false,
          rating: null,
          logo: null,
          detail: CustomerDetailInfo(
            tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim().split(',').map((e) => e.trim()).toList(),
            childrenAmount: int.tryParse(_numberOfChildrenController.text.trim()) ?? 0,
            monthlySalary: () {
              final raw = _monthlyIncomeController.text.trim();
              if (raw.isEmpty || raw == '0') return null;
              return raw;
            }(),
            maritalStatus: _selectedMaritalStatus,
          ),
        ),
        connectedContact: null,
        createdAt: '',
      );

      print('🔄 Creating new customer...');
      
      final result = await _customerRepository.createCustomer(newCustomer);
      
      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  failure.message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: const Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Müşteri başarıyla oluşturuldu!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true);
          }
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _fieldLabel(String label) {
    final isRequired = label.contains('*');
    final text = label.replaceAll('*', '').trim();
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A4352),
            letterSpacing: 0.1,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: _brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hint,
    Widget? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
    String? suffixText,
    TextStyle? suffixStyle,
    bool alignLabelWithHint = false,
  }) {
    const radius = BorderRadius.all(Radius.circular(14));
    const idle = BorderSide(color: Color(0xFFE8EBF0));
    const focus = BorderSide(color: _brand, width: 1.4);
    return InputDecoration(
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: _fill,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: prefixIcon,
      prefixText: prefixText,
      prefixStyle: prefixText == null
          ? null
          : const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: suffixStyle,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B7C3),
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 1.25),
      counterStyle: const TextStyle(fontSize: 11, color: _muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const OutlineInputBorder(borderRadius: radius, borderSide: idle),
      enabledBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: idle),
      focusedBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: focus),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _brand),
      ),
      focusedErrorBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: focus),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    int maxLines = 1,
    int? minLines,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? prefixIcon,
    String? prefixText,
    Widget? suffixIcon,
    String? suffixText,
    TextStyle? suffixStyle,
    bool alignLabelWithHint = false,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
            height: 1.3,
          ),
          cursorColor: _brand,
          decoration: _fieldDecoration(
            hint: hint,
            prefixIcon: prefixIcon,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            suffixText: suffixText,
            suffixStyle: suffixStyle,
            alignLabelWithHint: alignLabelWithHint,
          ),
        ),
      ],
    );
  }

  Widget _pair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _section({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final body = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      body.add(children[i]);
      if (i != children.length - 1) {
        body.add(const SizedBox(height: 14));
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2430).withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF4F3), Color(0xFFFFE4E1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: _brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...body,
        ],
      ),
    );
  }

  Widget _statusChoice({
    required bool active,
    required String label,
    required Color color,
  }) {
    final selected = _isActive == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isActive = active),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1C2430).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? color : const Color(0xFFC5CAD3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C2430).withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 108,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE4E1),
                    Color(0xFFFFF6F5),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImageSourceBottomSheet,
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: _brand.withOpacity(0.16),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF1F0),
                            ),
                            child: ClipOval(
                              child: _selectedProfileImage != null
                                  ? Image.file(
                                      _selectedProfileImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      size: 40,
                                      color: _brand,
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 4,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _brand,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yeni müşteri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fotoğraf eklemek için dokunun',
                  style: TextStyle(
                    fontSize: 13,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _statusChoice(
                        active: true,
                        label: 'Aktif',
                        color: const Color(0xFF128A52),
                      ),
                      _statusChoice(
                        active: false,
                        label: 'Pasif',
                        color: const Color(0xFF5C6570),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        TextFormField(
          key: ValueKey('$label-${value ?? ''}'),
          initialValue: value,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _brand,
          decoration: _fieldDecoration(
            hint: value == null ? hint : null,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      resizeToAvoidBottomInset: true,
      appBar: AdminPanelInAppBar(
        title: "Müşteri Ekle",
        onBackPressed: () => Navigator.pop(context),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEFF3))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4B43), Color(0xFFE11D18)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _brand.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Müşteriyi kaydet",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              _section(
                title: 'Müşteri bilgileri',
                subtitle: 'İletişim ve kimlik',
                icon: Icons.person_outline_rounded,
                children: [
                  _buildDropdownField(
                    label: "Müşteri Tipi",
                    hint: "Lütfen müşteri tipini seçin",
                    value: _selectedCustomerType,
                    onTap: () {
                      _showSelectionModal(
                        title: "Müşteri Tipi",
                        items: _allCustomerTypes,
                        selectedValue: _selectedCustomerType,
                        showSearch: true,
                        onSelected: (val) {
                          setState(() {
                            _selectedCustomerType = val;
                          });
                        },
                      );
                    },
                  ),
                  _pair(
                    _textField(
                      controller: _firstNameController,
                      label: "Müşteri Adı *",
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri adı gerekli';
                        }
                        return null;
                      },
                    ),
                    _textField(
                      controller: _lastNameController,
                      label: "Müşteri Soyadı *",
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Müşteri soyadı gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  _pair(
                    _textField(
                      controller: _tcNumberController,
                      label: "TC Kimlik No",
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    _textField(
                      controller: _emailController,
                      label: "E-posta Adresi *",
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'E-posta gerekli';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta giriniz';
                        }
                        return null;
                      },
                    ),
                  ),
                  _textField(
                    controller: _phoneController,
                    label: "Telefon Numarası *",
                    hint: "(555) 000-0000",
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneNumberFormatter()],
                    prefixText: "+90 ",
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: _icon,
                      size: 20,
                    ),
                    validator: (value) {
                      final digits = PhoneNumberFormatter.localDigits(value ?? '');
                      if (digits.isEmpty) {
                        return 'Telefon numarası gerekli';
                      }
                      if (digits.length != 10) {
                        return 'Telefon numarası 10 haneli olmalıdır';
                      }
                      return null;
                    },
                  ),
                  _buildDropdownField(
                    label: "Vatandaşlık",
                    hint: "Lütfen vatandaşlık seçin",
                    value: _selectedNationality,
                    onTap: () {
                      final items = _countries.isEmpty
                          ? ['Türkiye', 'Amerika', 'Almanya']
                          : _countries.map((c) => c.name).toList();
                      _showSelectionModal(
                        title: "Vatandaşlık",
                        items: items,
                        selectedValue: _selectedNationality,
                        showSearch: items.length > 5,
                        onSelected: (val) {
                          setState(() {
                            _selectedNationality = val;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              _section(
                title: 'Kimlik ve vergi',
                subtitle: 'Resmi bilgiler',
                icon: Icons.badge_outlined,
                children: [
                  _pair(
                    _textField(
                      controller: _taxNumberController,
                      label: "Vergi No",
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (value.trim().length != 10) {
                          return 'Vergi numarası tam 10 rakam olmalıdır';
                        }
                        return null;
                      },
                    ),
                    _textField(
                      controller: _taxOfficeController,
                      label: "Vergi Dairesi",
                    ),
                  ),
                  _pair(
                    _buildDropdownField(
                      label: "Cinsiyet",
                      hint: "Lütfen cinsiyet seçin",
                      value: _selectedGender,
                      onTap: () {
                        _showSelectionModal(
                          title: "Cinsiyet",
                          items: ['Kadın', 'Erkek'],
                          selectedValue: _selectedGender,
                          onSelected: (val) {
                            setState(() {
                              _selectedGender = val;
                            });
                          },
                        );
                      },
                    ),
                    _textField(
                      controller: _birthDateController,
                      label: "Doğum Tarihi",
                      hint: "GG/AA/YYYY",
                      readOnly: true,
                      onTap: _pickBirthDate,
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _icon,
                      ),
                    ),
                  ),
                  _buildDropdownField(
                    label: "Uzmanlık",
                    hint: "Lütfen uzmanlık alanı seçin",
                    value: _selectedExpertise,
                    onTap: () {
                      final items = _professions.isEmpty
                          ? [
                              'Eğitim',
                              'Sağlık',
                              'Teknoloji',
                              'Hukuk',
                              'Finans',
                              'Akademisyen'
                            ]
                          : _professions.map((p) => p.description).toList();
                      _showSelectionModal(
                        title: "Uzmanlık",
                        items: items,
                        selectedValue: _selectedExpertise,
                        showSearch: true,
                        onSelected: (val) {
                          setState(() {
                            _selectedExpertise = val;
                          });
                        },
                      );
                    },
                  ),
                  _buildDropdownField(
                    label: "Eğitim",
                    hint: "Lütfen eğitim seçin",
                    value: _selectedEducation,
                    onTap: () {
                      _showSelectionModal(
                        title: "Eğitim",
                        items: ['Lise', 'Üniversite', 'Yüksek Lisans', 'Doktora'],
                        selectedValue: _selectedEducation,
                        onSelected: (val) {
                          setState(() {
                            _selectedEducation = val;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              _section(
                title: 'Sosyal medya',
                subtitle: 'İsteğe bağlı',
                icon: Icons.share_outlined,
                children: [
                  _pair(
                    _textField(
                      controller: _instagramController,
                      label: "Instagram",
                      hint: "kullanici_adi",
                    ),
                    _textField(
                      controller: _facebookController,
                      label: "Facebook",
                      hint: "profil",
                    ),
                  ),
                  _pair(
                    _textField(
                      controller: _twitterController,
                      label: "X",
                      hint: "kullanici_adi",
                    ),
                    _textField(
                      controller: _linkedinController,
                      label: "Linkedin",
                      hint: "profil",
                    ),
                  ),
                ],
              ),
              _section(
                title: 'İlan ve notlar',
                subtitle: 'Takip ve notlar',
                icon: Icons.home_work_outlined,
                children: [
                  _textField(
                    controller: _interestedListingsController,
                    label: "İlgilendiği İlanlar",
                    hint: "Ara",
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _icon,
                      size: 22,
                    ),
                  ),
                  Column(
                    children: [
                      _textField(
                        controller: _propertiesSearchController,
                        focusNode: _propertiesFocusNode,
                        label: "Mülkler",
                        hint: "Ara",
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _icon,
                          size: 22,
                        ),
                      ),
                      _buildPropertiesListInline(),
                    ],
                  ),
                  _textField(
                    controller: _howDidYouHearController,
                    label: "Bizi Nereden Duydunuz?",
                  ),
                  _textField(
                    controller: _notesController,
                    label: "Not",
                    hint: "Müşteri hakkında kısa bir not",
                    maxLines: 6,
                    minLines: 4,
                    alignLabelWithHint: true,
                  ),
                  _textField(
                    controller: _tagsController,
                    label: "Etiket Ekle",
                    hint: "Etiket yazın",
                    prefixIcon: const Icon(
                      Icons.help_outline,
                      color: _icon,
                      size: 20,
                    ),
                    suffixIcon: const Icon(
                      Icons.undo,
                      color: _icon,
                      size: 20,
                    ),
                  ),
                ],
              ),
              _section(
                title: 'Ek bilgiler',
                subtitle: 'Gelir ve aile',
                icon: Icons.insights_outlined,
                children: [
                  _pair(
                    _textField(
                      controller: _monthlyIncomeController,
                      label: "Aylık Geliri (Ortalama)",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      suffixText: "₺",
                      suffixStyle: const TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildDropdownField(
                      label: "Medeni Durumu",
                      hint: "Lütfen medeni durumu seçin",
                      value: _selectedMaritalStatus,
                      onTap: () {
                        _showSelectionModal(
                          title: "Medeni Durumu",
                          items: ['Bekar', 'Evli', 'Boşanmış'],
                          selectedValue: _selectedMaritalStatus,
                          onSelected: (val) {
                            setState(() {
                              _selectedMaritalStatus = val;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  _textField(
                    controller: _numberOfChildrenController,
                    label: "Çocuk Sayısı",
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
