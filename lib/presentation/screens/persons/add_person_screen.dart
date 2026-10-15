import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/contact/contact_api_model.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/models/contact/ref_education_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:zecorner/core/config/env_api.dart';

class AddPersonScreen extends StatefulWidget {
  const AddPersonScreen({super.key});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen>
    with TickerProviderStateMixin {
  bool _isRealPerson = true;
  bool _isCustomConsultant = false;
  bool _statusActive = true;
  String? _selectedAddressCountry;
  /// Uyruk alanı (API nationality); adres ülkesinden bağımsız
  String? _selectedNationality;
  String? _selectedConsultantLevel;
  String? _selectedCustomRate; // Özel danışman başlangıç oranı (%55-%60)
  static const List<String> _danismanSeviyeleri = [
    'Seviye 1 (%55)',
    'Seviye 2 (%56)',
    'Seviye 3 (%57)',
  ];
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  String? _selectedProfession;
  String? _selectedEducation;
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;
  bool _acceptKvkk = false;
  
  // Gender, marital status, body size, birth place
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedBodySize;
  String? _selectedBirthPlace;
  bool _isForeignNational = false;
  
  // Reference data
  List<ContactTypeModel> _contactTypes = [];
  List<RefProfessionModel> _professions = [];
  List<RefEducationModel> _educations = [];
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<QuarterModel> _quarters = [];
  List<RefCountryModel> _countries = [];
  bool _isLoadingRefData = true;
  bool _isLoadingDistricts = false;
  bool _isLoadingQuarters = false;
  
  // File upload state
  String? _profileImageId;
  String? _diplomaFileId;
  String? _criminalRecordFileId;
  String? _professionalCertificateFileId;
  String? _realEstatePermitFileId;
  bool _isUploadingFile = false;
  
  // Connected person autocomplete
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingContacts = false;
  /// Bağlı ofis: sadece listeden seçimde set edilir; serbest yazımda null (yanlışlıkla metin ID gitmesin)
  int? _connectedOfficeContactNo;
  
  // Person type search
  final TextEditingController _personTypeSearchController = TextEditingController();
  List<ContactTypeModel> _filteredContactTypes = [];
  bool _isPersonTypeDropdownOpen = false;
  
  // Form validation errors (ZORUNLU ALANLAR)
  String? _personTypeError;
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;
  String? _profileImageError;
  String? _tcNumberError;
  String? _birthDateError;
  String? _birthPlaceError;
  String? _genderError;
  String? _maritalStatusError;
  String? _bodySizeError;
  String? _cityError;
  String? _districtError;
  String? _neighborhoodError;
  String? _addressError;
  String? _educationError;
  String? _coverLetterError;
  String? _criminalRecordError;
  String? _professionalCertificateError;

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _connectedPersonController =
      TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _companyInfoController = TextEditingController();
  final TextEditingController _pastExperienceController = TextEditingController();
  final TextEditingController _coverLetterController = TextEditingController();
  final TextEditingController _referencesController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();

  // Image picker variables
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Document picker variables
  PlatformFile? _diplomaFile;
  PlatformFile? _criminalRecordFile;
  PlatformFile? _professionalCertificateFile;
  PlatformFile? _realEstatePermitFile;

  // API repositories
  late ContactApiRepository _contactApiRepository;
  bool _isLoading = false;
  
  // Contact Types
  String? _selectedContactType;
  
  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _floatingAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
    
    // Initialize API repositories
    _contactApiRepository = ContactApiRepository();
    
    // Initialize filtered contact types
    _filteredContactTypes = [];
    
    // Load reference data
    _loadReferenceData();
  }

  @override
  void dispose() {
    // Dispose animation controller
    _animationController.dispose();
    // Dispose scroll controller
    _scrollController.dispose();
    // Dispose text controllers
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _connectedPersonController.dispose();
    _tcController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _experienceController.dispose();
    _companyInfoController.dispose();
    _pastExperienceController.dispose();
    _coverLetterController.dispose();
    _referencesController.dispose();
    _postCodeController.dispose();
    _personTypeSearchController.dispose();
    super.dispose();
  }

  // Image picker method
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _profileImageError = null;
        });

        // Upload image to API
        await _uploadFile(File(pickedFile.path), 'profile_image');
      }
    } catch (e) {
      _showMessage('Fotoğraf seçilirken bir hata oluştu!', isError: true);
    }
  }

  // Upload file to API
  Future<void> _uploadFile(File file, String fileType) async {
    try {
      setState(() {
        _isUploadingFile = true;
      });

      final result = await _contactApiRepository.uploadFile(file, fileType);
      
      if (mounted) {
        if (result.isRight()) {
          final fileId = result.fold((l) => null, (r) => r);
          if (fileId != null) {
            setState(() {
              switch (fileType) {
                case 'profile_image':
                  _profileImageId = fileId;
                  break;
                case 'diploma':
                  _diplomaFileId = fileId;
                  break;
                case 'criminal_record':
                  _criminalRecordFileId = fileId;
                  break;
                case 'professional_certificate':
                  _professionalCertificateFileId = fileId;
                  break;
                case 'real_estate_permit':
                  _realEstatePermitFileId = fileId;
                  break;
              }
            });
            
            _showMessage('${_getFileTypeName(fileType)} başarıyla yüklendi', isError: false);
          }
        } else {
          final failure = result.fold((l) => l, (r) => null);
          _showMessage(failure?.message ?? 'Dosya yüklenemedi', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Dosya yükleme hatası: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  // Get file type name for display
  String _getFileTypeName(String fileType) {
    switch (fileType) {
      case 'profile_image':
        return 'Profil fotoğrafı';
      case 'diploma':
        return 'Diploma';
      case 'criminal_record':
        return 'Adli sicil kaydı';
      case 'professional_certificate':
        return 'Mesleki yeterlilik belgesi';
      case 'real_estate_permit':
        return 'Taşınmaz ticari yetki belgesi';
      default:
        return 'Dosya';
    }
  }

  // Show modern date picker
  Future<void> _showModernDatePicker() async {
    await initializeDateFormatting('tr_TR', null);

    const monthNames = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    DateTime clampBirthMonth(DateTime date) {
      final now = DateTime.now();
      final minMonth = DateTime(1900, 1, 1);
      final maxMonth = DateTime(now.year, now.month, 1);
      final candidate = DateTime(date.year, date.month, 1);
      if (candidate.isBefore(minMonth)) return minMonth;
      if (candidate.isAfter(maxMonth)) return maxMonth;
      return candidate;
    }

    DateTime shiftBirthMonth(DateTime from, int delta) {
      final monthIndex = from.year * 12 + (from.month - 1) + delta;
      final year = monthIndex ~/ 12;
      final month = monthIndex % 12 + 1;
      return clampBirthMonth(DateTime(year, month, 1));
    }

    DateTime? selectedDate;
    DateTime initialFocusedDay = clampBirthMonth(
      DateTime.now().subtract(const Duration(days: 365 * 18)),
    );

    // Mevcut tarihi parse et
    if (_birthDateController.text.isNotEmpty) {
      try {
        final parts = _birthDateController.text.split('/');
        if (parts.length == 3) {
          selectedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          initialFocusedDay = clampBirthMonth(selectedDate);
        }
      } catch (e) {
        // Parse hatası, varsayılan tarihi kullan
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        DateTime? modalSelectedDate = selectedDate;
        DateTime modalFocusedDay = initialFocusedDay;
        // 0: gün takvimi, 1: yıl ızgarası, 2: ay ızgarası
        var pickerView = 0;
        var yearAligned = false;
        final selectedYearKey = GlobalKey();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();
            final focusedMonth = DateTime(
              modalFocusedDay.year,
              modalFocusedDay.month,
              1,
            );
            final canGoPrev = focusedMonth.isAfter(DateTime(1900, 1, 1));
            final canGoNext = focusedMonth.isBefore(DateTime(now.year, now.month, 1));

            Widget yearCell(int year) {
              final isSelected = year == modalFocusedDay.year;
              return Material(
                color: isSelected
                    ? const Color(0xFFE53935)
                    : const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  key: isSelected ? selectedYearKey : null,
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setModalState(() {
                      modalFocusedDay = clampBirthMonth(
                        DateTime(year, modalFocusedDay.month, 1),
                      );
                      pickerView = 2;
                    });
                  },
                  child: Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget buildYearPicker() {
              final currentYear = now.year;
              final firstDecade = (currentYear ~/ 10) * 10;
              final decades = <int>[
                for (var decade = firstDecade; decade >= 1900; decade -= 10)
                  decade,
              ];

              if (!yearAligned) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final yearContext = selectedYearKey.currentContext;
                  if (yearContext == null) return;
                  Scrollable.ensureVisible(
                    yearContext,
                    alignment: 0.3,
                    duration: const Duration(milliseconds: 250),
                  );
                  yearAligned = true;
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  children: [
                    for (final decade in decades)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                '$decade – ${(decade + 9) > currentYear ? currentYear : decade + 9}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            GridView.count(
                              crossAxisCount: 4,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.7,
                              children: [
                                for (var year = decade;
                                    year <= decade + 9 && year <= currentYear;
                                    year++)
                                  yearCell(year),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }

            Widget buildMonthPicker() {
              return GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.1,
                children: [
                  for (var month = 1; month <= 12; month++)
                    Builder(
                      builder: (context) {
                        final enabled = !DateTime(modalFocusedDay.year, month, 1)
                            .isAfter(DateTime(now.year, now.month, 1));
                        final isSelected = month == modalFocusedDay.month && enabled;
                        return Material(
                          color: isSelected
                              ? const Color(0xFFE53935)
                              : const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: enabled
                                ? () {
                                    setModalState(() {
                                      modalFocusedDay = DateTime(
                                        modalFocusedDay.year,
                                        month,
                                        1,
                                      );
                                      pickerView = 0;
                                    });
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                monthNames[month - 1],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: !enabled
                                      ? Colors.grey[400]
                                      : isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            }

            final headerTitle = pickerView == 1
                ? 'Yıl Seçin'
                : pickerView == 2
                    ? '${modalFocusedDay.year}'
                    : '${monthNames[modalFocusedDay.month - 1]} ${modalFocusedDay.year}';

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Doğum Tarihi Seçiniz",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "İptal",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            if (modalSelectedDate != null) {
                              setState(() {
                                _birthDateController.text =
                                    '${modalSelectedDate!.day.toString().padLeft(2, '0')}/${modalSelectedDate!.month.toString().padLeft(2, '0')}/${modalSelectedDate!.year}';
                                _birthDateError = null;
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Tamam",
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: pickerView == 0 && !canGoPrev
                              ? null
                              : () {
                                  setModalState(() {
                                    if (pickerView == 2) {
                                      pickerView = 1;
                                      yearAligned = false;
                                    } else if (pickerView == 1) {
                                      pickerView = 0;
                                    } else {
                                      modalFocusedDay = shiftBirthMonth(
                                        modalFocusedDay,
                                        -1,
                                      );
                                    }
                                  });
                                },
                          icon: Icon(
                            pickerView == 0
                                ? Icons.chevron_left
                                : Icons.arrow_back,
                            color: pickerView == 0 && !canGoPrev
                                ? Colors.grey[300]
                                : const Color(0xFFE53935),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setModalState(() {
                                if (pickerView == 0) {
                                  pickerView = 1;
                                  yearAligned = false;
                                } else if (pickerView == 2) {
                                  pickerView = 1;
                                  yearAligned = false;
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  if (pickerView == 2)
                                    Text(
                                      'Ay Seçin',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        headerTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      if (pickerView != 1) ...[
                                        const SizedBox(width: 2),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Color(0xFFE53935),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: pickerView == 0 && canGoNext
                              ? () {
                                  setModalState(() {
                                    modalFocusedDay = shiftBirthMonth(
                                      modalFocusedDay,
                                      1,
                                    );
                                  });
                                }
                              : null,
                          icon: Icon(
                            Icons.chevron_right,
                            color: pickerView == 0
                                ? (canGoNext
                                    ? const Color(0xFFE53935)
                                    : Colors.grey[300])
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pickerView == 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Yıl için başlığa dokunun',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Expanded(
                    child: pickerView == 1
                        ? buildYearPicker()
                        : pickerView == 2
                            ? buildMonthPicker()
                            : TableCalendar(
                                locale: 'tr_TR',
                                firstDay: DateTime(1900),
                                lastDay: DateTime.now(),
                                focusedDay: modalFocusedDay,
                                headerVisible: false,
                                selectedDayPredicate: (day) {
                                  return isSameDay(modalSelectedDate, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  setModalState(() {
                                    modalSelectedDate = selectedDay;
                                    modalFocusedDay = focusedDay;
                                  });
                                },
                                calendarFormat: CalendarFormat.month,
                                onPageChanged: (focusedDay) {
                                  setModalState(() {
                                    modalFocusedDay = focusedDay;
                                  });
                                },
                                calendarStyle: CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                  ),
                                  weekendTextStyle: const TextStyle(
                                    color: Color(0xFFE53935),
                                  ),
                                  outsideDaysVisible: false,
                                ),
                                daysOfWeekStyle: const DaysOfWeekStyle(
                                  weekendStyle: TextStyle(
                                    color: Color(0xFFE53935),
                                  ),
                                ),
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

  /// Arama sonucu map'inden sayısal kişi/ofis no (BAMMA contact_no bekliyor; metin gönderilmemeli)
  int? _contactNoFromSearchResult(Map<String, dynamic> contact) {
    for (final key in ['contact_no', 'contactNo', 'pk', 'id']) {
      final v = contact[key];
      if (v == null) continue;
      if (v is int && v > 0) return v;
      final s = v.toString().trim();
      final p = int.tryParse(s);
      if (p != null && p > 0) return p;
    }
    return null;
  }

  // Search contacts for autocomplete (Bağlı Ofis için)
  Future<void> _searchContacts(String query) async {
    if (query.length < 1) {
      setState(() {
        _searchResults = [];
        _isSearchingContacts = false;
      });
      return;
    }

    try {
      setState(() {
        _isSearchingContacts = true;
      });

      // Contact types'dan sadece ofis tiplerinin kodlarını bul
      List<int> officeTypeCodes = [];
      if (_contactTypes.isNotEmpty) {
        officeTypeCodes = _contactTypes
            .where((type) {
              final desc = type.description.toLowerCase();
              return (desc.contains('zecorner') && desc.contains('ofis')) ||
                     (desc.contains('merkez') && desc.contains('ofis')) ||
                     (desc.contains('broker') && desc.contains('ofis')) ||
                     (type.isAgency == true && type.isCompany == true);
            })
            .map((type) => type.code)
            .toList();
      }

      final result = await _contactApiRepository.searchContacts(
        query,
        size: 10,
        typeCodes: officeTypeCodes.isNotEmpty ? officeTypeCodes : null,
      );
      
      if (mounted) {
        if (result.isRight()) {
          final contacts = result.fold((l) => null, (r) => r);
          if (contacts != null) {
            final filteredContacts = contacts.where((contact) {
              final typeDescription = contact['type_description']?.toString().toLowerCase() ?? '';
              
              if (typeDescription.contains('zecorner') && typeDescription.contains('ofis')) {
                return true;
              }
              
              if (typeDescription.contains('broker ofis') || typeDescription.contains('merkez ofis')) {
                return true;
              }
              
              if (typeDescription == 'broker' || 
                  typeDescription.contains('asistanı') ||
                  (typeDescription.contains('danışmanı') && !typeDescription.contains('ofis')) ||
                  (typeDescription.contains('danışman') && !typeDescription.contains('broker ofis') && !typeDescription.contains('merkez ofis') && !typeDescription.contains('zecorner'))) {
                return false;
              }
              
              return false;
            }).toList();

            setState(() {
              _searchResults = filteredContacts;
              _isSearchingContacts = false;
            });
          }
        } else {
          setState(() {
            _searchResults = [];
            _isSearchingContacts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearchingContacts = false;
        });
      }
    }
  }


  // Document picker methods
  Future<void> _pickDocument(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          _showMessage('Dosya boyutu 10MB\'dan büyük olamaz!', isError: true);
          return;
        }

        setState(() {
          switch (documentType) {
            case 'diploma':
              _diplomaFile = file;
              break;
            case 'criminal_record':
              _criminalRecordFile = file;
              _criminalRecordError = null;
              break;
            case 'professional_certificate':
              _professionalCertificateFile = file;
              _professionalCertificateError = null;
              break;
            case 'real_estate_permit':
              _realEstatePermitFile = file;
              break;
          }
        });

        // Upload file to API
        await _uploadFile(File(file.path!), documentType);
      }
    } catch (e) {
      _showMessage('Dosya seçilirken bir hata oluştu!', isError: true);
    }
  }

  // Remove document method
  void _removeDocument(String documentType) {
    setState(() {
      switch (documentType) {
        case 'diploma':
          _diplomaFile = null;
          break;
        case 'criminal_record':
          _criminalRecordFile = null;
          break;
        case 'professional_certificate':
          _professionalCertificateFile = null;
          break;
        case 'real_estate_permit':
          _realEstatePermitFile = null;
          break;
      }
    });
    _showMessage('Dosya kaldırıldı!', isError: false);
  }

  // Load reference data from API
  Future<void> _loadReferenceData() async {
    try {
      setState(() {
        _isLoadingRefData = true;
      });

      // Load all reference data in parallel
      final results = await Future.wait([
        _contactApiRepository.getContactTypes(),
        _contactApiRepository.getProfessions(),
        _contactApiRepository.getEducations(),
        _contactApiRepository.getProvinces(),
        _contactApiRepository.getCountries(),
      ]);

      if (mounted) {
        setState(() {
          // Contact types
          if (results[0].isRight()) {
            final contactTypesResult = results[0].fold<RefContactTypeResponseModel?>((l) => null, (r) => r as RefContactTypeResponseModel);
            if (contactTypesResult != null) {
              // Aktif olanları göster; status yoksa veya 1 ise dahil et (web ile aynı liste)
              _contactTypes = contactTypesResult.contactTypes
                  .where((type) => type.status == null || type.status == 1)
                  .toList();
              _filteredContactTypes = _contactTypes;
            }
          }

          // Professions
          if (results[1].isRight()) {
            final professionsResult = results[1].fold<RefProfessionResponseModel?>((l) => null, (r) => r as RefProfessionResponseModel);
            if (professionsResult != null) {
              _professions = professionsResult.professions;
            }
          }

          // Educations
          if (results[2].isRight()) {
            final educationsResult = results[2].fold<RefEducationResponseModel?>((l) => null, (r) => r as RefEducationResponseModel);
            if (educationsResult != null) {
              _educations = educationsResult.educations;
            }
          }

          // Provinces
          if (results[3].isRight()) {
            final provincesResult = results[3].fold<ProvincesResponseModel?>((l) => null, (r) => r as ProvincesResponseModel);
            if (provincesResult != null) {
              _provinces = provincesResult.provinces;
            }
          }

          // Countries
          if (results[4].isRight()) {
            final countriesResult = results[4].fold<RefCountryResponseModel?>((l) => null, (r) => r as RefCountryResponseModel);
            if (countriesResult != null) {
              _countries = countriesResult.countries;
              final turkeyList = _countries.where((c) =>
                  c.name == 'Türkiye Cumhuriyeti' || c.name == 'Türkiye').toList();
              if (turkeyList.isNotEmpty) {
                if (_selectedAddressCountry == null) {
                  _selectedAddressCountry = turkeyList.first.name;
                }
                if (_selectedNationality == null) {
                  _selectedNationality = turkeyList.first.name;
                }
              }
            }
          }

          _isLoadingRefData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRefData = false;
        });
        _showMessage('Referans verileri yüklenirken hata oluştu: $e', isError: true);
      }
    }
  }

  // Load districts by province
  Future<void> _loadDistrictsByProvince(int provinceCode) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
        _districts = [];
        _quarters = [];
        _selectedDistrict = null;
        _selectedNeighborhood = null;
      });

      final result = await _contactApiRepository.getDistrictsByProvince(provinceCode);
      
      if (mounted) {
        if (result.isRight()) {
          final districtsResult = result.fold((l) => null, (r) => r);
          if (districtsResult != null) {
            setState(() {
              _districts = districtsResult.districts;
              _isLoadingDistricts = false;
            });
          }
        } else {
          setState(() {
            _isLoadingDistricts = false;
          });
          _showMessage('İlçeler yüklenirken hata oluştu', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
        _showMessage('İlçeler yüklenirken hata oluştu: $e', isError: true);
      }
    }
  }

  // Filter person types by search query
  void _filterPersonTypes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContactTypes = _contactTypes;
      } else {
        _filteredContactTypes = _contactTypes
            .where((type) => type.description
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Show person type dropdown with search
  void _showPersonTypeDropdown() {
    setState(() {
      _isPersonTypeDropdownOpen = true;
      _filteredContactTypes = _contactTypes;
      _personTypeSearchController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    "Kişi Türü Seçiniz",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isPersonTypeDropdownOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _personTypeSearchController,
                decoration: InputDecoration(
                  hintText: "Ara...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE53935),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _filterPersonTypes,
              ),
            ),
            // List
            Expanded(
              child: _filteredContactTypes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          "Sonuç bulunamadı",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredContactTypes.length,
                      itemBuilder: (context, index) {
                        final type = _filteredContactTypes[index];
                        final isSelected = _selectedContactType == type.description;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedContactType = type.description;
                              _personTypeError = null;
                            });
                            Navigator.pop(context);
                            setState(() {
                              _isPersonTypeDropdownOpen = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE53935).withOpacity(0.1)
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    type.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected
                                          ? const Color(0xFFE53935)
                                          : Colors.black,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    color: Color(0xFFE53935),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _isPersonTypeDropdownOpen = false;
      });
    });
  }

  /// Kişi türü "Gayrimenkul Danışmanı" ise true (web ile aynı - sadece bu türde danışman seviye alanları gösterilir)
  bool get _isGayrimenkulDanismani {
    final t = _selectedContactType?.toLowerCase() ?? '';
    return t.contains('gayrimenkul') && t.contains('danışman');
  }

  /// Özel danışman başlangıç oranı modalı (%55-%60)
  void _showCustomRateModal() {
    final customRates = List.generate(6, (index) => '%${55 + index}');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Özel Danışman Başlangıç Oranı',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customRates.length,
                itemBuilder: (context, index) {
                  final rate = customRates[index];
                  final isSelected = _selectedCustomRate == rate;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCustomRate = rate);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE53935).withOpacity(0.1)
                            : Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFFE53935)
                                  : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Color(0xFFE53935),
                              size: 20,
                            ),
                        ],
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
  }

  // Show message helper
  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Modern input decoration helper
  InputDecoration _buildModernInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
    bool isRequired = false,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$labelText *' : labelText,
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon != null
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: Icon(prefixIcon, color: const Color(0xFFE53935), size: 20),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : Colors.grey[200]!, 
          width: 1.5
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : Colors.grey[200]!, 
          width: 1.5
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : const Color.fromRGBO(238, 46, 36, 1), 
          width: 2
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: TextStyle(
        color: errorText != null ? Colors.red : Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: errorText != null ? Colors.red : const Color.fromRGBO(238, 46, 36, 1),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Modern dropdown decoration helper
  InputDecoration _buildModernDropdownDecoration({
    required String labelText,
    IconData? prefixIcon,
    bool isRequired = false,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$labelText *' : labelText,
      prefixIcon: prefixIcon != null
          ? Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(prefixIcon, color: const Color(0xFFE53935), size: 20),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : Colors.grey[200]!, 
          width: 1.5
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : Colors.grey[200]!, 
          width: 1.5
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: errorText != null ? Colors.red : const Color.fromRGBO(238, 46, 36, 1), 
          width: 2
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: TextStyle(
        color: errorText != null ? Colors.red : Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: errorText != null ? Colors.red : const Color.fromRGBO(238, 46, 36, 1),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 1,
    );
  }


  // Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Validate form fields (SADECE ZORUNLU ALANLAR - Edit sayfası ile aynı)
  bool _validateForm() {
    bool isValid = true;
    
    setState(() {
      // Reset errors
      _personTypeError = null;
      _firstNameError = null;
      _lastNameError = null;
      _phoneError = null;
      _emailError = null;
      _profileImageError = null;
      _tcNumberError = null;
      _birthDateError = null;
      _birthPlaceError = null;
      _genderError = null;
      _maritalStatusError = null;
      _bodySizeError = null;
      _cityError = null;
      _districtError = null;
      _neighborhoodError = null;
      _addressError = null;
      _educationError = null;
      _coverLetterError = null;
      _criminalRecordError = null;
      _professionalCertificateError = null;
    });

    // 1. Validate person type (ZORUNLU)
    if (_selectedContactType == null || _selectedContactType!.isEmpty) {
      setState(() {
        _personTypeError = 'Kişi türü seçimi zorunludur';
      });
      isValid = false;
    }

    // 2. Validate first name (ZORUNLU)
    if (_nameController.text.isEmpty) {
      setState(() {
        _firstNameError = 'Ad alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (_nameController.text.trim().length < 2) {
      setState(() {
        _firstNameError = 'Ad en az 2 karakter olmalıdır.';
      });
      isValid = false;
    }

    // 3. Validate last name (ZORUNLU)
    if (_surnameController.text.isEmpty) {
      setState(() {
        _lastNameError = 'Soyad alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (_surnameController.text.trim().length < 2) {
      setState(() {
        _lastNameError = 'Soyad en az 2 karakter olmalıdır.';
      });
      isValid = false;
    }

    // 4. Validate phone (ZORUNLU)
    if (_phoneController.text.isEmpty) {
      setState(() {
        _phoneError = 'Cep telefonu alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (_phoneController.text.replaceAll(' ', '').length != 10) {
      setState(() {
        _phoneError = 'Geçerli bir telefon numarası giriniz (10 haneli).';
      });
      isValid = false;
    }

    // 5. Validate email (ZORUNLU)
    if (_emailController.text.isEmpty) {
      setState(() {
        _emailError = 'E-posta alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      setState(() {
        _emailError = 'Geçerli bir e-posta adresi giriniz.';
      });
      isValid = false;
    }

    // 6. Validate profile image (ZORUNLU — önizleme yetmez; sunucu s3Id ister)
    if (_selectedImage == null && _profileImageId == null) {
      setState(() {
        _profileImageError = 'Fotoğraf seçimi zorunludur.';
      });
      isValid = false;
    } else if (_selectedImage != null &&
        (_profileImageId == null || _profileImageId!.isEmpty)) {
      setState(() {
        _profileImageError =
            'Profil fotoğrafı sunucuya yüklenmedi. Önce yüklemenin tamamlanmasını bekleyin veya fotoğrafı tekrar seçin.';
      });
      isValid = false;
    }

    // 7. Validate T.C. Kimlik No (ZORUNLU - yabancı uyruk değilse)
    if (!_isForeignNational) {
      if (_tcController.text.isEmpty) {
        setState(() {
          _tcNumberError = 'T.C. Kimlik No alanı boş bırakılamaz.';
        });
        isValid = false;
      } else if (_tcController.text.length != 11) {
        setState(() {
          _tcNumberError = 'T.C. Kimlik No 11 haneli olmalıdır.';
        });
        isValid = false;
      }
    }

    // 8. Validate birth date (ZORUNLU)
    if (_birthDateController.text.isEmpty) {
      setState(() {
        _birthDateError = 'Doğum tarihi alanı boş bırakılamaz.';
      });
      isValid = false;
    }

    // 9. Validate birth place (ZORUNLU)
    if (_selectedBirthPlace == null || _selectedBirthPlace!.isEmpty) {
      setState(() {
        _birthPlaceError = 'Doğum yeri seçimi zorunludur.';
      });
      isValid = false;
    }

    // 10. Validate gender (ZORUNLU)
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() {
        _genderError = 'Cinsiyet seçimi zorunludur.';
      });
      isValid = false;
    }

    // 11. Validate marital status (ZORUNLU)
    if (_selectedMaritalStatus == null || _selectedMaritalStatus!.isEmpty) {
      setState(() {
        _maritalStatusError = 'Medeni durum seçimi zorunludur.';
      });
      isValid = false;
    }

    // 12. Validate body size (ZORUNLU)
    if (_selectedBodySize == null || _selectedBodySize!.isEmpty) {
      setState(() {
        _bodySizeError = 'Beden seçimi zorunludur.';
      });
      isValid = false;
    }

    // 13. Validate city (ZORUNLU)
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      setState(() {
        _cityError = 'İl seçimi zorunludur.';
      });
      isValid = false;
    }

    // 14. Validate district (ZORUNLU)
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      setState(() {
        _districtError = 'İlçe seçimi zorunludur.';
      });
      isValid = false;
    }

    // 15. Validate neighborhood (ZORUNLU)
    if (_selectedNeighborhood == null || _selectedNeighborhood!.isEmpty) {
      setState(() {
        _neighborhoodError = 'Mahalle seçimi zorunludur.';
      });
      isValid = false;
    }

    // 16. Validate address (ZORUNLU)
    if (_addressController.text.isEmpty) {
      setState(() {
        _addressError = 'Adres alanı boş bırakılamaz.';
      });
      isValid = false;
    }

    // 17. Validate education (ZORUNLU)
    if (_selectedEducation == null || _selectedEducation!.isEmpty) {
      setState(() {
        _educationError = 'Eğitim durumu seçimi zorunludur.';
      });
      isValid = false;
    }

    // 18. Validate cover letter (ZORUNLU)
    if (_coverLetterController.text.isEmpty) {
      setState(() {
        _coverLetterError = 'Hakkımda alanı boş bırakılamaz.';
      });
      isValid = false;
    }

    // 19. Validate criminal record (ZORUNLU)
    if (_criminalRecordFile == null && _criminalRecordFileId == null) {
      setState(() {
        _criminalRecordError = 'Adli sicil kaydı zorunludur.';
      });
      isValid = false;
    }

    // 20. Validate professional certificate (ZORUNLU)
    if (_professionalCertificateFile == null && _professionalCertificateFileId == null) {
      setState(() {
        _professionalCertificateError = 'Mesleki yeterlilik belgesi zorunludur.';
      });
      isValid = false;
    }

    return isValid;
  }

  String? _contactSaveErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
      final err = data['error'];
      if (err is String && err.isNotEmpty) return err;
      final result = data['result'];
      if (result is Map) {
        final d = result['description'];
        if (d is String && d.isNotEmpty) return d;
        final c = result['code'];
        if (c is String && c.isNotEmpty) return c;
      }
      final desc = data['description'];
      if (desc is String && desc.isNotEmpty) return desc;
    }
    return null;
  }

  // Form validation and API call
  void _saveForm() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final customOk = _validateForm();
    if (!formOk || !customOk) {
      if (!customOk && _profileImageError != null) {
        _showMessage(_profileImageError!, isError: true);
      } else if (!formOk) {
        _showMessage('Lütfen formdaki hatalı alanları düzeltin.', isError: true);
      } else {
        _showMessage(
            'Eksik zorunlu alanlar var. Sayfadaki kırmızı uyarıları kontrol edin.',
            isError: true);
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }
    
    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Get selected contact type code
      final selectedContactType = _contactTypes.firstWhere(
        (type) => type.description == _selectedContactType,
        orElse: () => _contactTypes.first,
      );

      // Get selected profession code
      RefProfessionModel? selectedProfession;
      if (_selectedProfession != null) {
        try {
          selectedProfession = _professions.firstWhere(
            (prof) => prof.description == _selectedProfession,
          );
        } catch (e) {
          selectedProfession = _professions.isNotEmpty ? _professions.first : null;
        }
      }

      // Get selected education code
      RefEducationModel? selectedEducation;
      if (_selectedEducation != null) {
        try {
          selectedEducation = _educations.firstWhere(
            (edu) => edu.description == _selectedEducation,
          );
        } catch (e) {
          selectedEducation = _educations.isNotEmpty ? _educations.first : null;
        }
      }

      // Get selected province for codes
      ProvinceModel? selectedProvince;
      if (_selectedCity != null) {
        try {
          selectedProvince = _provinces.firstWhere(
            (prov) => prov.name == _selectedCity,
          );
        } catch (e) {
          selectedProvince = _provinces.isNotEmpty ? _provinces.first : null;
        }
      }

      // Get selected district for codes
      DistrictModel? selectedDistrict;
      if (_selectedDistrict != null && _districts.isNotEmpty) {
        try {
          selectedDistrict = _districts.firstWhere(
            (dist) => dist.name == _selectedDistrict,
            orElse: () => _districts.first,
          );
        } catch (e) {
          selectedDistrict = _districts.isNotEmpty ? _districts.first : null;
        }
      }

      // Get selected quarter for codes
      QuarterModel? selectedQuarter;
      if (_selectedNeighborhood != null && _quarters.isNotEmpty) {
        try {
          selectedQuarter = _quarters.firstWhere(
            (q) => q.name == _selectedNeighborhood,
            orElse: () => _quarters.first,
          );
        } catch (e) {
          selectedQuarter = _quarters.isNotEmpty ? _quarters.first : null;
        }
      }

      // Doğum yeri kodu: adres ili ile karıştırma
      ProvinceModel? birthPlaceProvince;
      if (_selectedBirthPlace != null) {
        for (final p in _provinces) {
          if (p.name == _selectedBirthPlace) {
            birthPlaceProvince = p;
            break;
          }
        }
      }

      RefCountryModel? addressCountry;
      if (_selectedAddressCountry != null) {
        for (final c in _countries) {
          if (c.name == _selectedAddressCountry) {
            addressCountry = c;
            break;
          }
        }
      }
      final countryIso =
          (addressCountry != null && addressCountry.code.isNotEmpty)
              ? addressCountry.code
              : 'TR';

      RefCountryModel? nationalityCountry;
      if (_selectedNationality != null) {
        for (final c in _countries) {
          if (c.name == _selectedNationality) {
            nationalityCountry = c;
            break;
          }
        }
      }
      final nationalityIso =
          (nationalityCountry != null && nationalityCountry.code.isNotEmpty)
              ? nationalityCountry.code
              : countryIso;

      // Create ContactApiModel from form data (edit'teki gibi)
      final contact = ContactApiModel(
        contactNo: 0,
        title: '${_nameController.text.trim()} ${_surnameController.text.trim()}',
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        type: selectedContactType.code.toString(),
        typeDescription: _selectedContactType ?? 'Müşteri',
        isCompany: false,
        isEmployee: selectedContactType.isEmployee,
        isAgency: selectedContactType.isAgency,
        tcIdNumber: _tcController.text.trim().isEmpty ? null : _tcController.text.trim(),
        taxNo: null,
        taxOffice: null,
        nationality: nationalityIso,
        sex: _selectedGender == 'M' ? 1 : _selectedGender == 'F' ? 2 : null,
        eMail: _emailController.text.trim(),
        tel: _phoneController.text.replaceAll(' ', ''),
        status: _statusActive ? 1 : 0,
        updatedAt: '',
        createdAt: '',
        source: _companyInfoController.text.trim().isEmpty ? null : _companyInfoController.text.trim(),
        birthday: _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
        professionCode: selectedProfession?.code,
        professionDescription: _selectedProfession,
        educationCode: selectedEducation?.code,
        educationDescription: _selectedEducation,
        whereYouHeardUs: _companyInfoController.text.trim().isEmpty ? null : _companyInfoController.text.trim(),
        sectoralExperience: _experienceController.text.trim().isEmpty ? null : int.tryParse(_experienceController.text.trim()),
        picture: _profileImageId,
        marketingCommunicationPermission: _acceptKvkk,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        district: _selectedDistrict,
        city: _selectedCity,
        country: countryIso,
        postCode: null,
        addressSource: null,
        provinceCode: selectedProvince?.code.toString(),
        provinceName: _selectedCity,
        districtCode: selectedDistrict?.code.toString(),
        districtName: _selectedDistrict,
        quarterCode: selectedQuarter?.code.toString(),
        quarterName: _selectedNeighborhood,
        connectedContact: _connectedOfficeContactNo,
        connectedContactTitle: _connectedPersonController.text.trim().isEmpty ? null : _connectedPersonController.text.trim(),
        connectedContactType: null,
        connectedContactDescription: null,
        isCustomer: selectedContactType.isCustomer,
        slug: '',
        instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
        facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
        twitter: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
        linkedin: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
        pastExperience: _pastExperienceController.text.trim().isEmpty ? null : _pastExperienceController.text.trim(),
        coverLetter: _coverLetterController.text.trim().isEmpty ? null : _coverLetterController.text.trim(),
        references: _referencesController.text.trim().isEmpty ? null : _referencesController.text.trim(),
        aboutMe: _coverLetterController.text.trim().isEmpty ? null : _coverLetterController.text.trim(),
        birthPlaceCode: birthPlaceProvince?.code,
        birthPlaceName: _selectedBirthPlace,
        maritalStatus: _selectedMaritalStatus,
        size: _selectedBodySize,
        isForeignNationality: _isForeignNational,
      );

      // Web'deki gibi files array'i oluştur
      List<Map<String, dynamic>> files = [];
      if (_profileImageId != null && _profileImageId!.isNotEmpty) {
        files.add({
          'id': 'PICTURE',
          's3Id': _profileImageId,
        });
      }
      if (_diplomaFileId != null && _diplomaFileId!.isNotEmpty) {
        files.add({
          'id': 'DIPLOMA',
          's3Id': _diplomaFileId,
        });
      }
      if (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty) {
        files.add({
          'id': 'CRIMINAL_RECORD',
          's3Id': _criminalRecordFileId,
        });
      }
      if (_professionalCertificateFileId != null && _professionalCertificateFileId!.isNotEmpty) {
        files.add({
          'id': 'PROFESSIONAL_CERTIFICATE',
          's3Id': _professionalCertificateFileId,
        });
      }
      if (_realEstatePermitFileId != null && _realEstatePermitFileId!.isNotEmpty) {
        files.add({
          'id': 'REAL_ESTATE_PERMIT',
          's3Id': _realEstatePermitFileId,
        });
      }

      // Next.js save-contact: files[{id,s3Id}] gönderilir; handler detail.picture / attachments birleştirir
      final requestBody = contact.toJson();
      if (files.isNotEmpty) {
        requestBody['files'] = files;
        // Next.js handler: requestBody.detail.attachments — detail yoksa sunucu hata verir
        requestBody.putIfAbsent('detail', () => <String, dynamic>{});
      }

      // Gayrimenkul Danışmanı ise advisor_level ve starting_rate (yüzde) ekle
      if (_isGayrimenkulDanismani) {
        if (requestBody['detail'] == null) {
          requestBody['detail'] = <String, dynamic>{};
        }
        int? advisorLevel;
        int? startingRate;
        if (_isCustomConsultant && _selectedCustomRate != null) {
          final match = RegExp(r'%(\d+)').firstMatch(_selectedCustomRate!);
          if (match != null) {
            startingRate = int.tryParse(match.group(1) ?? '');
            advisorLevel = startingRate != null ? (startingRate - 54).clamp(1, 3) : null;
          }
        } else if (_selectedConsultantLevel != null) {
          if (_selectedConsultantLevel == _danismanSeviyeleri[0]) {
            advisorLevel = 1;
            startingRate = 55;
          } else if (_selectedConsultantLevel == _danismanSeviyeleri[1]) {
            advisorLevel = 2;
            startingRate = 56;
          } else if (_selectedConsultantLevel == _danismanSeviyeleri[2]) {
            advisorLevel = 3;
            startingRate = 57;
          }
        }
        if (advisorLevel != null) {
          requestBody['detail']['advisor_level'] = advisorLevel;
        }
        if (startingRate != null) {
          requestBody['detail']['starting_rate'] = startingRate;
        }
      }

      // Call API - Manuel request body ile POST yap
      // createContact metodu ContactApiModel alıyor ve toJson() kullanıyor
      // Ancak biz files ve attachments işlemini yaptık, o yüzden requestBody'yi kullanacağız
      // ContactApiModel'in toJson() metodunu kullanıp, sonra files ve attachments'ı ekleyip, manuel POST yapacağız
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString('userJWT');
      final apiKey = dotenv.env["X_API_KEY"];
      final appId = dotenv.env["X_APP_ID"];

      if (token == null || apiKey == null || appId == null) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Oturum bilgileri bulunamadı', isError: true);
        return;
      }

      final baseUrl = (dotenv.env['BASE_URL'] ?? '${EnvApi.origin}').trim();
      final contactPath =
          (dotenv.env['PCONTACTS'] ?? '/api/zecorner/contact').trim();
      final createUri = Uri.parse('$baseUrl$contactPath').replace(
        queryParameters: const {'type': 'save'},
      );

      final headers = <String, String>{
        'X-SESSION': token,
        'X-API-KEY': apiKey,
        'X-APP-ID': appId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final userId = pref.getString('userID');
      if (userId != null && userId.isNotEmpty) {
        headers['X-UR-ID'] = userId;
      }

      print('🔄 Contact Create Request:');
      print('📋 URL: $createUri');
      print('📋 Request Body: $requestBody');

      try {
        final response = await _contactApiRepository.dioClient.dio.post(
          createUri.toString(),
          data: requestBody,
          options: Options(headers: headers),
        );

        print('✅ RESPONSE: ${response.statusCode}');
        print('📥 Data: ${response.data}');

        final ok =
            response.statusCode == 201 || response.statusCode == 200;
        final data = response.data;

        if (ok) {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            String msg = 'Kişi başarıyla kaydedildi!';
            if (data is Map && data['result'] is Map) {
              final r = data['result'] as Map;
              if (r['description'] is String &&
                  (r['description'] as String).isNotEmpty) {
                msg = r['description'] as String;
              }
            }
            _showMessage(msg, isError: false);
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _showMessage(
            _contactSaveErrorMessage(data) ?? 'Kişi kaydedilemedi',
            isError: true,
          );
        }
      } on DioException catch (e) {
        setState(() {
          _isLoading = false;
        });
        final errBody = e.response?.data;
        _showMessage(
          _contactSaveErrorMessage(errBody) ??
              'Bağlantı hatası: ${e.message}',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Beklenmeyen hata: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelAppBar(
        title: "Yeni Kişi Ekle",
        onMenuPressed: () => Navigator.pop(context),
        useBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gerçek Kişi Butonu
              InkWell(
                onTap: () => setState(() => _isRealPerson = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color:
                        _isRealPerson ? const Color(0xFFE53935) : Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Text(
                    "Gerçek Kişi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isRealPerson ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Durum Switch
                    Row(
                      children: [
                        const Text("Durum", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
                        const Spacer(),
                        Switch(
                          value: _statusActive,
                          onChanged: (value) => setState(() => _statusActive = value),
                          activeColor: const Color(0xFFE53935),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Kişi Türü Dropdown
                    const Text("Kişi Türü *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isLoadingRefData ? null : _showPersonTypeDropdown,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _personTypeError != null ? Colors.red : Colors.grey[200]!, 
                            width: 1.5
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: _isLoadingRefData
                            ? const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedContactType ?? 
                                      (_personTypeError ?? "Seçiniz"),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedContactType != null
                                            ? Colors.black
                                            : (_personTypeError != null
                                                ? Colors.red
                                                : Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _isPersonTypeDropdownOpen
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Danışman Seviye Bilgileri - Sadece "Gayrimenkul Danışmanı" kişi türü seçiliyken (web ile aynı)
                    if (_isGayrimenkulDanismani) ...[
                      const Text(
                        "Danışman Seviye Bilgileri",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Danışmanı Özelleştir Switch
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.grey[200]!, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Text("Danışmanı Özelleştir",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2C3E50))),
                            const Spacer(),
                            Switch(
                              value: _isCustomConsultant,
                              onChanged: (value) {
                                setState(() => _isCustomConsultant = value);
                              },
                              activeColor: const Color(0xFFE53935),
                            ),
                          ],
                        ),
                      ),
                      // Danışman Başlangıç Seviyesi - Özelleştir kapalıyken (yüzdeliklerle)
                      if (!_isCustomConsultant) ...[
                        const SizedBox(height: 16),
                        const Text("Danışman Başlangıç Seviyesi",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.grey[200]!, width: 1.5),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              value: _selectedConsultantLevel,
                              hint: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text("Seçiniz",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 1),
                              items: _danismanSeviyeleri
                                  .map((level) => DropdownMenuItem(
                                        value: level,
                                        child: Text(level,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() =>
                                    _selectedConsultantLevel = value);
                              },
                            ),
                          ),
                        ),
                      ],
                      // Özel Danışman Başlangıç Oranı - Özelleştir açıkken (yüzde seçimi)
                      if (_isCustomConsultant) ...[
                        const SizedBox(height: 16),
                        const Text("Özel Danışman Başlangıç Oranı",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showCustomRateModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey[200]!, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCustomRate ?? "Seçiniz",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedCustomRate == null
                                        ? Colors.grey
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 24),
                    // Kişisel Bilgiler
                    const Text(
                      "Kişisel Bilgiler",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ad
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Ad *",
                        prefixIcon: Icons.person_outline,
                        isRequired: true,
                        errorText: _firstNameError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      onChanged: (value) {
                        if (value.isNotEmpty && _firstNameError != null) {
                          setState(() {
                            _firstNameError = null;
                          });
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZığüşöçİĞÜŞÖÇ\s]')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Soyad
                    TextFormField(
                      controller: _surnameController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Soyad *",
                        prefixIcon: Icons.person_outline,
                        isRequired: true,
                        errorText: _lastNameError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      onChanged: (value) {
                        if (value.isNotEmpty && _lastNameError != null) {
                          setState(() {
                            _lastNameError = null;
                          });
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-ZığüşöçİĞÜŞÖÇ\s]')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Cep Telefonu
                    TextFormField(
                      controller: _phoneController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Cep Telefonu *",
                        prefixIcon: Icons.phone_outlined,
                        prefixText: "+90 ",
                        isRequired: true,
                        errorText: _phoneError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        if (value.isNotEmpty && value.length >= 10 && _phoneError != null) {
                          setState(() {
                            _phoneError = null;
                          });
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          String newText = newValue.text;
                          if (newText.length <= 3) {
                            return newValue;
                          } else if (newText.length <= 6) {
                            return newValue.copyWith(
                              text:
                                  '${newText.substring(0, 3)} ${newText.substring(3)}',
                              selection: TextSelection.collapsed(
                                  offset: newText.length + 1),
                            );
                          } else if (newText.length <= 8) {
                            return newValue.copyWith(
                              text:
                                  '${newText.substring(0, 3)} ${newText.substring(3, 6)} ${newText.substring(6)}',
                              selection: TextSelection.collapsed(
                                  offset: newText.length + 2),
                            );
                          } else {
                            return newValue.copyWith(
                              text:
                                  '${newText.substring(0, 3)} ${newText.substring(3, 6)} ${newText.substring(6, 8)} ${newText.substring(8)}',
                              selection: TextSelection.collapsed(
                                  offset: newText.length + 3),
                            );
                          }
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      decoration: _buildModernInputDecoration(
                        labelText: "E-posta *",
                        prefixIcon: Icons.email_outlined,
                        isRequired: true,
                        errorText: _emailError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        if (value.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value) && _emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    // Fotoğraf * — Seçilen fotoğraf bu alanda gösterilir
                    const Text("Fotoğraf *", 
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isUploadingFile ? null : _pickImageFromGallery,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _profileImageError != null ? Colors.red : Colors.grey[200]!,
                            width: 1.5,
                          ),
                        ),
                        child: (_selectedImage != null || _profileImageId != null)
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: 180,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.person, size: 64, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedImage != null
                                              ? _selectedImage!.path.split('/').last
                                              : "Profil fotoğrafı yüklendi",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        "Değiştir",
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isUploadingFile ? "Yükleniyor..." : "Dosya seçiniz",
                                      style: TextStyle(
                                        color: _isUploadingFile ? Colors.grey[600] : Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (_isUploadingFile)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(2),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFE53935),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE53935).withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE53935).withOpacity(0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    if (!_isUploadingFile)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          "Yüksek çözünürlüklü, profesyonel çekim, net ışıklandırma ve beyaz/açık renk arka plan kullanılmalıdır",
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    // Bağlı Ofis
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Bağlı Ofis",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _connectedPersonController,
                          decoration: InputDecoration(
                            labelText: "Bağlı Ofis",
                            hintText: "Ara...",
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: Icon(Icons.business_outlined, color: const Color(0xFFE53935), size: 20),
                            ),
                            suffixIcon: _isSearchingContacts
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color.fromRGBO(238, 46, 36, 1), width: 2),
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          cursorColor: const Color(0xFFE53935),
                          onChanged: (value) {
                            setState(() {
                              _connectedOfficeContactNo = null;
                            });
                            _searchContacts(value);
                          },
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final contact = _searchResults[index];
                                final title = contact['title']?.toString() ?? '';
                                final typeDescription = contact['type_description']?.toString() ?? '';
                                final email = contact['e_mail']?.toString() ?? '';
                                final contactNoInt = _contactNoFromSearchResult(contact);

                                return ListTile(
                                  title: Text(
                                    title,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (typeDescription.isNotEmpty)
                                        Text(
                                          typeDescription,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      if (email.isNotEmpty)
                                        Text(
                                          email,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _connectedPersonController.text = title;
                                      _connectedOfficeContactNo = contactNoInt;
                                      _searchResults = [];
                                    });
                                    if (contactNoInt == null && mounted) {
                                      _showMessage(
                                        'Bu kayıt için ofis numarası alınamadı. Başka bir sonuç seçin.',
                                        isError: true,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // T.C. Kimlik No
                    TextFormField(
                      controller: _tcController,
                      decoration: _buildModernInputDecoration(
                        labelText: "T.C. Kimlik No *",
                        prefixIcon: Icons.verified_user_outlined,
                        isRequired: true,
                        errorText: _tcNumberError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty && value.length == 11 && _tcNumberError != null) {
                          setState(() {
                            _tcNumberError = null;
                          });
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // Yabancı Uyruk Checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _isForeignNational,
                            onChanged: (value) {
                              setState(() {
                                _isForeignNational = value ?? false;
                                if (_isForeignNational) {
                                  _tcController.clear();
                                }
                              });
                            },
                            activeColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Yabancı Uyruk",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    // Doğum Tarihi
                    TextFormField(
                      controller: _birthDateController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Doğum Tarihi (Gün-Ay-Yıl) *",
                        hintText: "GG/AA/YYYY",
                        prefixIcon: Icons.calendar_today_outlined,
                        isRequired: true,
                        errorText: _birthDateError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      readOnly: true,
                      onTap: () async {
                        await _showModernDatePicker();
                      },
                    ),

                    const SizedBox(height: 20),
                    // Doğum Yeri
                    const Text("Doğum Yeri *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        decoration: _buildModernDropdownDecoration(
                          labelText: "Doğum Yeri",
                          prefixIcon: Icons.location_on_outlined,
                          isRequired: true,
                          errorText: _birthPlaceError,
                        ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: const Color(0xFFE53935),
                          value: _selectedBirthPlace != null && 
                                 _provinces.any((p) => p.name == _selectedBirthPlace) 
                                 ? _selectedBirthPlace 
                                 : null,
                          items: _isLoadingRefData
                              ? []
                              : _provinces.map((ProvinceModel province) {
                                  return DropdownMenuItem<String>(
                                    value: province.name,
                                    child: Text(province.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                          onChanged: _isLoadingRefData
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedBirthPlace = value;
                                    _birthPlaceError = null;
                                  });
                                },
                        ),
                      ),

                    const SizedBox(height: 20),
                    // Cinsiyet
                    const Text("Cinsiyet *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _genderError != null ? Colors.red : Colors.grey[200]!, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          value: _selectedGender,
                          hint: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _genderError ?? "Seçiniz",
                              style: TextStyle(
                                color: _genderError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                          items: const [
                            DropdownMenuItem(
                              value: 'M',
                              child: Text('Erkek', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'F',
                              child: Text('Kadın', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                              _genderError = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Medeni Durum
                    const Text("Medeni Durum *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _maritalStatusError != null ? Colors.red : Colors.grey[200]!, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          value: _selectedMaritalStatus,
                          hint: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _maritalStatusError ?? "Seçiniz",
                              style: TextStyle(
                                color: _maritalStatusError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                          items: const [
                            DropdownMenuItem(
                              value: 'Bekar',
                              child: Text('Bekar', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'Evli',
                              child: Text('Evli', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'Boşanmış',
                              child: Text('Boşanmış', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'Dul',
                              child: Text('Dul', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedMaritalStatus = value;
                              _maritalStatusError = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Beden
                    const Text("Beden *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _bodySizeError != null ? Colors.red : Colors.grey[200]!, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          value: _selectedBodySize,
                          hint: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _bodySizeError ?? "Seçiniz",
                              style: TextStyle(
                                color: _bodySizeError != null ? Colors.red : Colors.grey,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                          items: const [
                            DropdownMenuItem(
                              value: 'XS',
                              child: Text('XS', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'S',
                              child: Text('S', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'M',
                              child: Text('M', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'L',
                              child: Text('L', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'XL',
                              child: Text('XL', style: TextStyle(fontSize: 14)),
                            ),
                            DropdownMenuItem(
                              value: 'XXL',
                              child: Text('XXL', style: TextStyle(fontSize: 14)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedBodySize = value;
                              _bodySizeError = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Uyruk (Opsiyonel)
                    const Text("Uyruk (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _isLoadingRefData
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : DropdownButton<String>(
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                value: _selectedNationality != null &&
                                        _countries.any((c) => c.name == _selectedNationality)
                                    ? _selectedNationality
                                    : null,
                                hint: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "Seçiniz",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                                items: _countries.map((RefCountryModel country) {
                                  return DropdownMenuItem<String>(
                                    value: country.name,
                                    child: Text(country.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedNationality = value),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Adres Bilgileri
                    const Text(
                      "Adres Bilgileri",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ülke (Opsiyonel)
                    const Text("Ülke (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _isLoadingRefData
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : DropdownButton<String>(
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                value: _selectedAddressCountry != null &&
                                        _countries.any((c) => c.name == _selectedAddressCountry)
                                    ? _selectedAddressCountry
                                    : null,
                                hint: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "Seçiniz",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                                items: _countries.map((RefCountryModel country) {
                                  return DropdownMenuItem<String>(
                                    value: country.name,
                                    child: Text(country.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedAddressCountry = value),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // İl
                    const Text("İl *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        decoration: _buildModernDropdownDecoration(
                          labelText: "İl",
                          prefixIcon: Icons.location_city_outlined,
                          isRequired: true,
                          errorText: _cityError,
                        ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: const Color(0xFFE53935),
                          value: _selectedCity != null && 
                                 _provinces.any((p) => p.name == _selectedCity) 
                                 ? _selectedCity 
                                 : null,
                          items: _isLoadingRefData
                              ? []
                              : _provinces.map((ProvinceModel province) {
                                  return DropdownMenuItem<String>(
                                    value: province.name,
                                    child: Text(province.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                          onChanged: _isLoadingRefData
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCity = value;
                                    _cityError = null;
                                    _selectedDistrict = null;
                                    _selectedNeighborhood = null;
                                    _districts = [];
                                    _quarters = [];
                                  });
                                  
                                  if (value != null) {
                                    final selectedProvince = _provinces.firstWhere(
                                      (province) => province.name == value,
                                      orElse: () => _provinces.first,
                                    );
                                    _loadDistrictsByProvince(selectedProvince.code);
                                  }
                                },
                        ),
                      ),

                    const SizedBox(height: 20),
                    // İlçe
                    const Text("İlçe *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isLoadingDistricts
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text("İlçeler yükleniyor...", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                decoration: _buildModernDropdownDecoration(
                                  labelText: "İlçe",
                                  prefixIcon: Icons.location_on_outlined,
                                  isRequired: true,
                                  errorText: _districtError,
                                ),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFFE53935),
                                value: _selectedDistrict != null && 
                                       _districts.any((d) => d.name == _selectedDistrict) 
                                       ? _selectedDistrict 
                                       : null,
                                items: _districts.map((DistrictModel district) {
                                  return DropdownMenuItem<String>(
                                    value: district.name,
                                    child: Text(district.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDistrict = value;
                                    _districtError = null;
                                    _selectedNeighborhood = null;
                                    // Web API: quarters district objesi içinde geliyor, ayrı API çağrısı yok
                                    if (value != null) {
                                      final selectedDistrict = _districts.firstWhere(
                                        (district) => district.name == value,
                                        orElse: () => _districts.first,
                                      );
                                      _quarters = selectedDistrict.quarters;
                                      _isLoadingQuarters = false;
                                    } else {
                                      _quarters = [];
                                    }
                                  });
                                },
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),
                    // Mahalle
                    const Text("Mahalle *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isLoadingQuarters
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Mahalleler yükleniyor...", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                decoration: _buildModernDropdownDecoration(
                                  labelText: "Mahalle",
                                  prefixIcon: Icons.place_outlined,
                                  isRequired: true,
                                  errorText: _neighborhoodError,
                                ),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFFE53935),
                                value: _selectedNeighborhood != null && 
                                       _quarters.any((q) => q.name == _selectedNeighborhood) 
                                       ? _selectedNeighborhood 
                                       : null,
                                items: _quarters.map((QuarterModel quarter) {
                                  return DropdownMenuItem<String>(
                                    value: quarter.name,
                                    child: Text(quarter.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNeighborhood = value;
                                    _neighborhoodError = null;
                                  });
                                },
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),
                    // Adres
                    TextFormField(
                      controller: _addressController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Adres *",
                        prefixIcon: Icons.home_outlined,
                        isRequired: true,
                        errorText: _addressError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      maxLines: 3,
                      onChanged: (value) {
                        if (value.isNotEmpty && _addressError != null) {
                          setState(() {
                            _addressError = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),
                    // Sosyal Medya
                    const Text(
                      "Sosyal Medya",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Instagram
                    TextFormField(
                      controller: _instagramController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Instagram (Opsiyonel)",
                        prefixIcon: Icons.camera_alt_outlined,
                        prefixText: "@",
                      ),
                      cursorColor: const Color(0xFFE53935),
                    ),

                    const SizedBox(height: 20),
                    // Facebook
                    TextFormField(
                      controller: _facebookController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Facebook (Opsiyonel)",
                        prefixIcon: Icons.facebook_outlined,
                      ),
                      cursorColor: const Color(0xFFE53935),
                    ),

                    const SizedBox(height: 20),
                    // X (Twitter)
                    TextFormField(
                      controller: _twitterController,
                      decoration: _buildModernInputDecoration(
                        labelText: "X (Opsiyonel)",
                        prefixIcon: Icons.alternate_email_outlined,
                        prefixText: "@",
                      ),
                      cursorColor: const Color(0xFFE53935),
                    ),

                    const SizedBox(height: 20),
                    // LinkedIn
                    TextFormField(
                      controller: _linkedinController,
                      decoration: _buildModernInputDecoration(
                        labelText: "LinkedIn (Opsiyonel)",
                        prefixIcon: Icons.work_outline,
                      ),
                      cursorColor: const Color(0xFFE53935),
                    ),

                    const SizedBox(height: 24),
                    // Meslek ve Eğitim
                    const Text(
                      "Meslek ve Eğitim",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Meslek (Opsiyonel)
                    const Text("Meslek (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey[200]!, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _isLoadingRefData
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : DropdownButton<String>(
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                value: _selectedProfession,
                                hint: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "Meslek Seçiniz",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 1),
                                items: _professions
                                    .map((profession) => DropdownMenuItem(
                                          value: profession.description,
                                          child: Text(profession.description,
                                              style: const TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedProfession = value);
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Deneyimi (Opsiyonel)
                    TextFormField(
                      controller: _experienceController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Deneyimi (Opsiyonel)",
                        prefixIcon: Icons.work_history_outlined,
                        suffixText: "yıl",
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Eğitim Durumu
                    const Text("Eğitim Durumu *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _educationError != null ? Colors.red : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: _isLoadingRefData
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : DropdownButton<String>(
                                dropdownColor: Colors.white,
                                isExpanded: true,
                                value: _selectedEducation,
                                hint: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    _educationError ?? "Eğitim Durumu Seçiniz",
                                    style: TextStyle(
                                      color: _educationError != null ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 1),
                                items: _educations
                                    .map((education) => DropdownMenuItem(
                                          value: education.description,
                                          child: Text(education.description,
                                              style: const TextStyle(fontSize: 14)),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedEducation = value;
                                    _educationError = null;
                                  });
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Geçmiş İş Tecrübeleri (Opsiyonel)
                    TextFormField(
                      controller: _pastExperienceController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Geçmiş İş Tecrübeleri (Opsiyonel)",
                        hintText: "Geçmiş iş tecrübelerinizi yazınız",
                      ),
                      cursorColor: const Color(0xFFE53935),
                      maxLines: 4,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 20),
                    // Hakkımda
                    TextFormField(
                      controller: _coverLetterController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Hakkımda",
                        hintText: "Kendinizi tanıtan bir ön yazı yazınız",
                        isRequired: true,
                        errorText: _coverLetterError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      maxLines: 4,
                      maxLength: 300,
                      onChanged: (value) {
                        if (value.isNotEmpty && _coverLetterError != null) {
                          setState(() => _coverLetterError = null);
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    // Referanslar (Opsiyonel)
                    TextFormField(
                      controller: _referencesController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Referanslar (Opsiyonel)",
                        hintText: "Referanslarınızı yazınız",
                      ),
                      cursorColor: const Color(0xFFE53935),
                      maxLines: 3,
                      maxLength: 300,
                    ),

                    const SizedBox(height: 24),
                    const Text("Firmamızı nereden duydunuz? (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyInfoController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Firmamızı nereden duyduğunuzu yazınız",
                        prefixIcon: Icons.info_outline,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),
                    // Belgeler
                    const Text(
                      "Belgeler",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Diploma
                    const Text("Diploma (Opsiyonel)", style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    _diplomaFile != null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _diplomaFile!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatFileSize(_diplomaFile!.size),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeDocument('diploma'),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () => _pickDocument('diploma'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.upload_file_outlined,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Dosya seçiniz",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE53935).withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFFE53935),
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                    // Adli Sicil Kaydı
                    const Text("Adli Sicil Kaydı *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    _criminalRecordFile != null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _criminalRecordFile!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatFileSize(
                                            _criminalRecordFile!.size),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _removeDocument('criminal_record');
                                      _criminalRecordError = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () => _pickDocument('criminal_record'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _criminalRecordError != null ? Colors.red : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.upload_file_outlined,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                    "Dosya seçiniz",
                                      style: TextStyle(
                                        color: _criminalRecordError != null ? Colors.red : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  if (_criminalRecordError != null)
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE53935).withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    // Mesleki Yeterlilik Belgesi
                    const Text("Mesleki Yeterlilik Belgesi *",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    _professionalCertificateFile != null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _professionalCertificateFile!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatFileSize(
                                            _professionalCertificateFile!.size),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _removeDocument('professional_certificate');
                                      _professionalCertificateError = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () =>
                                _pickDocument('professional_certificate'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _professionalCertificateError != null ? Colors.red : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.upload_file_outlined,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                    "Dosya seçiniz",
                                      style: TextStyle(
                                        color: _professionalCertificateError != null ? Colors.red : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  if (_professionalCertificateError != null)
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFE53935).withOpacity(0.5),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    // Taşınmaz Ticari Yetki Belgesi
                    const Text("Taşınmaz Ticari Yetki Belgesi (Opsiyonel)",
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    _realEstatePermitFile != null
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: const Color(0xFFE53935),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _realEstatePermitFile!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatFileSize(
                                            _realEstatePermitFile!.size),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _removeDocument('real_estate_permit'),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          )
                        : InkWell(
                            onTap: () => _pickDocument('real_estate_permit'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.upload_file_outlined,
                                    color: const Color(0xFFE53935),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Dosya seçiniz",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE53935).withOpacity(0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Color(0xFFE53935),
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 32),

                    _buildAnimatedCheckbox(
                      value: _acceptKvkk,
                      onChanged: (v) =>
                          setState(() => _acceptKvkk = v ?? false),
                      subtitle: "Kampanya iletişim izni verilsin.",
                      isRequired: false,
                    ),
                    const SizedBox(height: 24),
                    // Kaydet Butonu
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                            : const Text(
                                "Kaydet",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
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
      bottomNavigationBar: AdminNavbar(
        currentIndex: 2, // Add person is the 3rd tab (index 2)
        onTap: (index) {},
      ),
    );
  }

  Widget _buildAnimatedCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String subtitle,
    bool isRequired = false,
  }) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatingAnimation.value * 0.05, 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
          border: Border.all(
            color: (!value && isRequired) ? Colors.red : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          activeColor: const Color(0xFFE53935),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: '* ',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                TextSpan(
                  text: subtitle,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
