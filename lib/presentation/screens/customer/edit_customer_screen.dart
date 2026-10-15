import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zecorner/models/customer/customer_api_model.dart';
import 'package:zecorner/models/realestate/search_realestate_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/infrastructure/customer/customer_api_repository.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/realestate/search_realestate_repo.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';

class EditCustomerScreen extends StatefulWidget {
  const EditCustomerScreen({super.key});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  bool _isActive = true;
  bool _isLoading = false;
  CustomerApiModel? _customer;
  String? _selectedCustomerType;
  String? _selectedNationality;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedExpertise;
  String? _selectedEducation;
  String? _selectedMaritalStatus;
  File? _selectedProfileImage;
  
  // Mülkler arama için
  late TextEditingController _propertiesSearchController;
  late FocusNode _propertiesFocusNode;
  OverlayEntry? _propertiesOverlayEntry;
  Timer? _searchTimer;
  List<SearchRealEstateModel> _searchResults = [];
  bool _isSearchingProperties = false;
  SearchRealEstateModel? _selectedProperty;
  
  // Müşteri Tipi için
  final TextEditingController _customerTypeSearchController = TextEditingController();
  final List<String> _allCustomerTypes = [
    'Alıcı',
    'Alıcı & Satıcı',
    'Potansiyel',
    'Potansiyel Alıcı',
    'Potansiyel Satıcı',
    'Satıcı',
  ];
  List<String> _filteredCustomerTypes = [];
  
  final CustomerApiRepository _customerRepository = CustomerApiRepository();
  final ContactApiRepository _contactApiRepository = ContactApiRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final SearchRealEstateRepository _searchRealEstateRepository = SearchRealEstateRepository();
  
  // Countries for nationality dropdown
  List<RefCountryModel> _countries = [];
  bool _isLoadingCountries = false;

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
    _propertiesFocusNode = FocusNode();
    
    _propertiesFocusNode.addListener(() {
      setState(() {});
    });
    
    _propertiesSearchController.addListener(_onPropertiesSearchChanged);
    
    // Müşteri Tipi için
    _filteredCustomerTypes = List.from(_allCustomerTypes);
    _customerTypeSearchController.addListener(_onCustomerTypeSearchChanged);
    
    // Load countries from API
    _loadCountries();
  }
  
  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
    });
    
    try {
      final result = await _contactApiRepository.getCountries();
      
      if (mounted) {
        result.fold(
          (failure) {
            setState(() {
              _isLoadingCountries = false;
              // Fallback to default countries if API fails
              _countries = [
                RefCountryModel(code: 'TR', name: 'Türkiye'),
                RefCountryModel(code: 'US', name: 'Amerika'),
                RefCountryModel(code: 'DE', name: 'Almanya'),
              ];
            });
          },
          (countriesResponse) {
            setState(() {
              _countries = countriesResponse.countries;
              _isLoadingCountries = false;
            });
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
          // Fallback to default countries if error occurs
          _countries = [
            RefCountryModel(code: 'TR', name: 'Türkiye'),
            RefCountryModel(code: 'US', name: 'Amerika'),
            RefCountryModel(code: 'DE', name: 'Almanya'),
          ];
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customer == null) {
      _customer = ModalRoute.of(context)?.settings.arguments as CustomerApiModel?;
      if (_customer != null) {
        _firstNameController.text = _customer!.name;
        _lastNameController.text = _customer!.surname;
        _tcNumberController.text = _customer!.tcIdNumber ?? '';
        _emailController.text = _customer!.eMail;
        _phoneController.text = _customer!.tel;
        _taxNumberController.text = _customer!.taxNo;
        _taxOfficeController.text = _customer!.taxOffice;
        _instagramController.text = _customer!.detail.socialMedia?.instagram ?? '';
        _facebookController.text = _customer!.detail.socialMedia?.facebook ?? '';
        _twitterController.text = _customer!.detail.socialMedia?.x ?? '';
        _linkedinController.text = _customer!.detail.socialMedia?.linkedin ?? '';
        _howDidYouHearController.text = _customer!.detail.whereYouHeardUs;
        _notesController.text = _customer!.detail.coverLetter;
        _tagsController.text = _customer!.detail.detail?.tags?.join(', ') ?? '';
        _monthlyIncomeController.text = _customer!.detail.detail?.monthlySalary ?? '';
        _numberOfChildrenController.text =
            _customer!.detail.detail != null ? _customer!.detail.detail!.childrenAmount.toString() : '0';

        // Cinsiyet
        if (_customer!.sex == 'M') {
          _selectedGender = 'Erkek';
        } else if (_customer!.sex == 'F') {
          _selectedGender = 'Kadın';
        } else {
          _selectedGender = null;
        }

        // Doğum tarihi
        final birthdayRaw = _customer!.detail.birthday;
        if (birthdayRaw != null && birthdayRaw.isNotEmpty) {
          DateTime? parsed;
          try {
            parsed = DateTime.tryParse(birthdayRaw);
          } catch (_) {
            parsed = null;
          }
          // Eğer backend farklı format döndürdüyse, burada ek parse eklenebilir.
          if (parsed != null) {
            _selectedBirthDate = parsed;
            _birthDateController.text = _formatDateForDisplay(parsed);
          }
        }
        
        // Müşteri tipini dropdown değerlerine göre ayarla
        final typeDesc = _customer!.typeDescription;
        if (typeDesc.isNotEmpty && _allCustomerTypes.contains(typeDesc)) {
          _selectedCustomerType = typeDesc;
        } else if (_customer!.type == 201) {
          _selectedCustomerType = 'Alıcı';
        } else if (_customer!.type == 202) {
          _selectedCustomerType = 'Satıcı';
        } else {
          _selectedCustomerType = null;
        }
        
        _selectedNationality = _customer!.nationality;
        
        // Uzmanlık ve Eğitim için dropdown'da var mı kontrol et
        final expertiseList = ['Eğitim', 'Sağlık', 'Teknoloji', 'Hukuk', 'Finans', 'Akademisyen'];
        if (_customer!.detail.profession?.description != null && 
            expertiseList.contains(_customer!.detail.profession!.description)) {
          _selectedExpertise = _customer!.detail.profession!.description;
        } else {
          _selectedExpertise = null;
        }
        
        final educationList = ['Lise', 'Üniversite', 'Yüksek Lisans', 'Doktora'];
        if (_customer!.detail.education?.description != null && 
            educationList.contains(_customer!.detail.education!.description)) {
          _selectedEducation = _customer!.detail.education!.description;
        } else {
          _selectedEducation = null;
        }
        
        _selectedMaritalStatus = _customer!.detail.detail?.maritalStatus;
        _isActive = _customer!.status == 1;
      }
    }
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Doğum Tarihi Seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );
    if (picked == null) return;
    setState(() {
      _selectedBirthDate = picked;
      _birthDateController.text = _formatDateForDisplay(picked);
    });
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
                      color: const Color.fromRGBO(238, 46, 36, 1).withValues(alpha: 0.1),
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
                      color: const Color.fromRGBO(238, 46, 36, 1).withValues(alpha: 0.1),
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

  void _onCustomerTypeSearchChanged() {
    final query = _customerTypeSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomerTypes = List.from(_allCustomerTypes);
      } else {
        _filteredCustomerTypes = _allCustomerTypes
            .where((type) => type.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _showCustomerTypeModal() {
    _customerTypeSearchController.clear();
    _filteredCustomerTypes = List.from(_allCustomerTypes);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Müşteri Tipi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _customerTypeSearchController,
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(238, 46, 36, 1),
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _onCustomerTypeSearchChanged();
                        });
                      },
                    ),
                  ),
                  // Customer Type List
                  Expanded(
                    child: _filteredCustomerTypes.isEmpty
                        ? const Center(
                            child: Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredCustomerTypes.length,
                            itemBuilder: (context, index) {
                              final type = _filteredCustomerTypes[index];
                              final isSelected = _selectedCustomerType == type;
                              
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCustomerType = type;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: index < _filteredCustomerTypes.length - 1 ? 1 : 0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? const Color.fromRGBO(238, 46, 36, 1)
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check,
                                          color: Color.fromRGBO(238, 46, 36, 1),
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
            );
          },
        );
      },
    );
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

  /// Mülk arama sonuçları - form içinde gösterilir, overlay kullanılmaz (inputtan ayrılmaz).
  Widget _buildPropertiesListInline() {
    final query = _propertiesSearchController.text.trim();
    final hasResults = _searchResults.isNotEmpty;
    final showEmpty = query.isNotEmpty && !_isSearchingProperties && !hasResults;
    final showList = _propertiesFocusNode.hasFocus || query.isNotEmpty;

    if (!showList) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
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
      ),
    );
  }

  Widget _buildPropertyThumbnail(String thumbnail) {
    // Eğer thumbnail boşsa, default icon göster
    if (thumbnail.isEmpty) {
      return Icon(
        Icons.home,
        color: Colors.grey[400],
        size: 24,
      );
    }

    // Eğer thumbnail zaten tam URL ise (http veya https ile başlıyorsa), direkt kullan
    String imageUrl;
    if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
      imageUrl = thumbnail;
    } else if (ImageUtils.isValidS3Id(thumbnail)) {
      // S3 ID ise, ImageUtils ile URL oluştur
      imageUrl = ImageUtils.getCoverImageUrl(thumbnail);
    } else {
      // Geçersiz format, default icon göster
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

  Future<void> _updateCustomer() async {
    if (_customer == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Müşteri tipi null ise uyar
      if (_selectedCustomerType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen müşteri tipini seçiniz'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Müşteri tipi kodunu belirle
      int customerTypeCode;
      switch (_selectedCustomerType) {
        case 'Alıcı':
          customerTypeCode = 201;
          break;
        case 'Satıcı':
          customerTypeCode = 202;
          break;
        case 'Potansiyel':
        case 'Potansiyel Alıcı':
        case 'Potansiyel Satıcı':
          customerTypeCode = 203;
          break;
        case 'Alıcı & Satıcı':
          customerTypeCode = 204; // Varsayılan kod, backend'e göre ayarlanabilir
          break;
        default:
          customerTypeCode = 201; // Varsayılan
      }
      
      // Profil fotoğrafı upload et (eğer yeni fotoğraf seçildiyse)
      String? uploadedPictureId;
      if (_selectedProfileImage != null) {
        final uploadResult = await _customerRepository.uploadProfilePicture(_selectedProfileImage!);
        uploadResult.fold(
          (failure) {
            // Upload başarısız olursa, mevcut picture'ı koru
            uploadedPictureId = _customer!.detail.picture;
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
      } else {
        // Yeni fotoğraf seçilmediyse, mevcut picture'ı koru
        uploadedPictureId = _customer!.detail.picture;
      }
      
      final updatedCustomer = CustomerApiModel(
        contactNo: _customer!.contactNo,
        title: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        name: _firstNameController.text.trim(),
        surname: _lastNameController.text.trim(),
        type: customerTypeCode,
        typeDescription: _selectedCustomerType!,
        tcIdNumber: _tcNumberController.text.trim().isEmpty ? null : _tcNumberController.text.trim(),
        taxNo: _taxNumberController.text.trim(),
        taxOffice: _taxOfficeController.text.trim(),
        nationality: _selectedNationality ?? 'TR',
        sex: _selectedGender == 'Erkek'
            ? 'M'
            : _selectedGender == 'Kadın'
                ? 'F'
                : null,
        eMail: _emailController.text.trim(),
        tel: _phoneController.text.trim(),
        status: _isActive ? 1 : 0,
        updatedAt: _customer!.updatedAt,
        source: _customer!.source,
        detail: CustomerDetail(
          id: _customer!.detail.id,
          birthday: _selectedBirthDate != null ? _formatDateForApi(_selectedBirthDate!) : (_customer!.detail.birthday ?? ''),
          profession: Profession(
            id: _customer!.detail.profession?.id,
            code: _customer!.detail.profession?.code,
            description: _selectedExpertise,
          ),
          education: Education(
            id: _customer!.detail.education?.id,
            code: _customer!.detail.education?.code,
            description: _selectedEducation,
          ),
          socialMedia: SocialMedia(
            instagram: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
            facebook: _facebookController.text.trim().isEmpty ? null : _facebookController.text.trim(),
            x: _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim(),
            linkedin: _linkedinController.text.trim().isEmpty ? null : _linkedinController.text.trim(),
          ),
          whereYouHeardUs: _howDidYouHearController.text.trim(),
          coverLetter: _notesController.text.trim(),
          sectoralExperience: _customer!.detail.sectoralExperience,
          picture: uploadedPictureId,
          reference: _customer!.detail.reference,
          areasOfExpertise: _customer!.detail.areasOfExpertise,
          marketingCommunicationPermission: _customer!.detail.marketingCommunicationPermission,
          rating: _customer!.detail.rating,
          logo: _customer!.detail.logo,
          detail: CustomerDetailInfo(
            tags: _tagsController.text.trim().isEmpty ? null : _tagsController.text.trim().split(',').map((e) => e.trim()).toList(),
            childrenAmount: int.tryParse(_numberOfChildrenController.text.trim()) ?? 0,
            monthlySalary: _monthlyIncomeController.text.trim().isEmpty ? 'N/A' : _monthlyIncomeController.text.trim(),
            maritalStatus: _selectedMaritalStatus,
          ),
        ),
        connectedContact: _customer!.connectedContact,
        createdAt: _customer!.createdAt,
      );

      print('🔄 Updating customer: ${_customer!.contactNo}');
      
      final result = await _customerRepository.updateCustomer(_customer!.contactNo, updatedCustomer);
      
      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Müşteri başarıyla güncellendi!'),
                backgroundColor: Colors.green,
              ),
            );
            // Başarılı güncelleme sonrası true döndür ki parent sayfa refresh yapsın
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

  @override
  void dispose() {
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
    _propertiesFocusNode.dispose();
    _searchTimer?.cancel();
    _removePropertiesOverlay();
    _customerTypeSearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Tasarım yardımcıları (davranış değişmez; yalnızca görünüm)
  // ---------------------------------------------------------------------------

  static const Color _brand = Color.fromRGBO(238, 46, 36, 1);
  static const Color _pageBg = Color(0xFFF4F5F7);
  static const Color _fieldFill = Color(0xFFF8F9FB);
  static const Color _border = Color(0xFFE3E6EA);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);

  OutlineInputBorder _outline(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _decoration(
    String label, {
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
    String? suffixText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: _brand,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: _textMuted) : null,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: _brand, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: _fieldFill,
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: _outline(_border),
      enabledBorder: _outline(_border),
      focusedBorder: _outline(_brand, 1.6),
      errorBorder: _outline(Colors.red.shade300),
      focusedErrorBorder: _outline(Colors.red.shade400, 1.6),
    );
  }

  static const TextStyle _inputText = TextStyle(
    fontSize: 15,
    color: _textPrimary,
    fontWeight: FontWeight.w500,
  );

  List<Widget> _withGaps(List<Widget> children, {double gap = 14}) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) out.add(SizedBox(height: gap));
    }
    return out;
  }

  Widget _twoColumns(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._withGaps(children),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    DropdownButtonBuilder? selectedItemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textMuted),
      style: _inputText,
      decoration: _decoration(label, icon: icon),
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey[400], fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      items: items,
      selectedItemBuilder: selectedItemBuilder,
      onChanged: onChanged,
    );
  }

  String get _initials {
    final f = _firstNameController.text.trim();
    final l = _lastNameController.text.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    return (a + b).toUpperCase();
  }

  Widget _buildAvatar() {
    const double size = 96;
    Widget inner;
    if (_selectedProfileImage != null) {
      inner = ClipOval(
        child: Image.file(
          _selectedProfileImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_customer?.detail.picture != null &&
        _customer!.detail.picture!.isNotEmpty) {
      inner = ClipOval(
        child: Image.network(
          _customer!.detail.picture!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _avatarFallback(),
        ),
      );
    } else {
      inner = _avatarFallback();
    }

    return GestureDetector(
      onTap: _showImageSourceBottomSheet,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size + 8,
              height: size + 8,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: _brand.withValues(alpha: 0.35), width: 2),
              ),
              child: ClipOval(child: inner),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _brand.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final initials = _initials;
    return Container(
      color: _brand.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: initials.isNotEmpty
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: _brand,
              ),
            )
          : const Icon(Icons.person_outline_rounded, size: 40, color: _brand),
    );
  }

  Widget _buildHeaderCard() {
    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 12),
          Text(
            fullName.isNotEmpty ? fullName : 'Müşteri',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fotoğrafı değiştirmek için dokunun',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isActive ? const Color(0xFF22C55E) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Müşteri Durumu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        _isActive ? 'Aktif' : 'Pasif',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                  activeTrackColor: const Color(0xFF22C55E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTypePicker() {
    final hasValue = _selectedCustomerType != null;
    return InkWell(
      onTap: _showCustomerTypeModal,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: !hasValue,
        decoration: _decoration(
          'Müşteri Tipi',
          icon: Icons.badge_outlined,
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _textMuted,
          ),
        ),
        child: Text(
          hasValue ? _selectedCustomerType! : 'Lütfen müşteri tipi seçin',
          style: hasValue
              ? _inputText
              : TextStyle(color: Colors.grey[400], fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNationalityField() {
    if (_isLoadingCountries) {
      return InputDecorator(
        decoration: _decoration('Vatandaşlık', icon: Icons.flag_outlined),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _brand),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Yükleniyor...',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return _dropdown<String>(
      label: 'Vatandaşlık',
      icon: Icons.flag_outlined,
      value: _selectedNationality,
      hint: 'Lütfen vatandaşlık seçin',
      items: _countries.map((RefCountryModel country) {
        return DropdownMenuItem<String>(
          value: country.code,
          child: Text(
            country.name,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return _countries.map((RefCountryModel country) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              country.name,
              style: _inputText,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList();
      },
      onChanged: (value) {
        setState(() => _selectedNationality = value);
      },
    );
  }

  Widget _buildSelectedPropertyChip() {
    final p = _selectedProperty;
    if (p == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: _buildPropertyThumbnail(p.thumbnail),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seçili Mülk',
                  style: TextStyle(fontSize: 11, color: _textMuted),
                ),
                Text(
                  p.title.isNotEmpty ? p.title : 'Başlıksız Mülk',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: _brand, size: 20),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _updateCustomer,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            disabledBackgroundColor: _brand.withValues(alpha: 0.6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Güncelle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AdminPanelInAppBar(
        title: "Müşteri Düzenle",
        onBackPressed: () => Navigator.pop(context),
      ),
      bottomNavigationBar: _buildSaveBar(),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),

            // --- Temel Bilgiler -------------------------------------------
            _section(
              title: 'Temel Bilgiler',
              icon: Icons.person_outline_rounded,
              subtitle: 'Müşteri tipi ve ad-soyad',
              children: [
                _buildCustomerTypePicker(),
                _twoColumns(
                  TextFormField(
                    controller: _firstNameController,
                    style: _inputText,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: _decoration(
                      'Müşteri Adı',
                      icon: Icons.person_outline,
                    ),
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    style: _inputText,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: _decoration(
                      'Müşteri Soyadı',
                      icon: Icons.person_outline,
                    ),
                  ),
                ),
              ],
            ),

            // --- Kimlik & İletişim ----------------------------------------
            _section(
              title: 'Kimlik ve İletişim',
              icon: Icons.contact_phone_outlined,
              children: [
                _twoColumns(
                  TextFormField(
                    controller: _tcNumberController,
                    style: _inputText,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(
                      'TC Kimlik No',
                      icon: Icons.credit_card_outlined,
                    ),
                  ),
                  TextFormField(
                    controller: _emailController,
                    style: _inputText,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(
                      'E-posta Adresi',
                      icon: Icons.alternate_email_rounded,
                    ),
                  ),
                ),
                _twoColumns(
                  TextFormField(
                    controller: _phoneController,
                    style: _inputText,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(
                      'Telefon Numarası',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  _buildNationalityField(),
                ),
              ],
            ),

            // --- Vergi Bilgileri ------------------------------------------
            _section(
              title: 'Vergi Bilgileri',
              icon: Icons.receipt_long_outlined,
              children: [
                _twoColumns(
                  TextFormField(
                    controller: _taxNumberController,
                    style: _inputText,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(
                      'Vergi No',
                      icon: Icons.numbers_rounded,
                    ),
                  ),
                  TextFormField(
                    controller: _taxOfficeController,
                    style: _inputText,
                    decoration: _decoration(
                      'Vergi Dairesi',
                      icon: Icons.account_balance_outlined,
                    ),
                  ),
                ),
              ],
            ),

            // --- Kişisel Bilgiler -----------------------------------------
            _section(
              title: 'Kişisel Bilgiler',
              icon: Icons.info_outline_rounded,
              children: [
                _twoColumns(
                  _dropdown<String>(
                    label: 'Cinsiyet',
                    icon: Icons.wc_rounded,
                    value: _selectedGender,
                    hint: 'Lütfen cinsiyet seçin',
                    items: const [
                      DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                      DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                  ),
                  TextFormField(
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    style: _inputText,
                    decoration: _decoration(
                      'Doğum Tarihi',
                      hint: 'GG/AA/YYYY',
                      icon: Icons.cake_outlined,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: _brand,
                      ),
                    ),
                  ),
                ),
                _twoColumns(
                  _dropdown<String>(
                    label: 'Uzmanlık',
                    icon: Icons.work_outline_rounded,
                    value: _selectedExpertise,
                    hint: 'Lütfen uzmanlık alanı seçin',
                    items: const [
                      DropdownMenuItem(value: 'Eğitim', child: Text('Eğitim')),
                      DropdownMenuItem(value: 'Sağlık', child: Text('Sağlık')),
                      DropdownMenuItem(
                        value: 'Teknoloji',
                        child: Text('Teknoloji'),
                      ),
                      DropdownMenuItem(value: 'Hukuk', child: Text('Hukuk')),
                      DropdownMenuItem(value: 'Finans', child: Text('Finans')),
                      DropdownMenuItem(
                        value: 'Akademisyen',
                        child: Text('Akademisyen'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedExpertise = value);
                    },
                  ),
                  _dropdown<String>(
                    label: 'Eğitim',
                    icon: Icons.school_outlined,
                    value: _selectedEducation,
                    hint: 'Lütfen eğitim seçin',
                    items: const [
                      DropdownMenuItem(value: 'Lise', child: Text('Lise')),
                      DropdownMenuItem(
                        value: 'Üniversite',
                        child: Text('Üniversite'),
                      ),
                      DropdownMenuItem(
                        value: 'Yüksek Lisans',
                        child: Text('Yüksek Lisans'),
                      ),
                      DropdownMenuItem(
                        value: 'Doktora',
                        child: Text('Doktora'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedEducation = value);
                    },
                  ),
                ),
                _twoColumns(
                  _dropdown<String>(
                    label: 'Medeni Durumu',
                    icon: Icons.favorite_border_rounded,
                    value: _selectedMaritalStatus,
                    hint: 'Lütfen medeni durum seçin',
                    items: const [
                      DropdownMenuItem(value: 'Bekar', child: Text('Bekar')),
                      DropdownMenuItem(value: 'Evli', child: Text('Evli')),
                      DropdownMenuItem(
                        value: 'Boşanmış',
                        child: Text('Boşanmış'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMaritalStatus = value);
                    },
                  ),
                  TextFormField(
                    controller: _numberOfChildrenController,
                    style: _inputText,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration(
                      'Çocuk Sayısı',
                      icon: Icons.child_care_rounded,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _monthlyIncomeController,
                  style: _inputText,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(
                    'Aylık Geliri (Ortalama)',
                    icon: Icons.payments_outlined,
                    suffixText: '₺',
                  ),
                ),
              ],
            ),

            // --- Sosyal Medya ---------------------------------------------
            _section(
              title: 'Sosyal Medya',
              icon: Icons.share_outlined,
              subtitle: 'Opsiyonel',
              children: [
                _twoColumns(
                  TextFormField(
                    controller: _instagramController,
                    style: _inputText,
                    decoration: _decoration(
                      'Instagram',
                      icon: Icons.camera_alt_outlined,
                    ),
                  ),
                  TextFormField(
                    controller: _facebookController,
                    style: _inputText,
                    decoration: _decoration(
                      'Facebook',
                      icon: Icons.facebook_rounded,
                    ),
                  ),
                ),
                _twoColumns(
                  TextFormField(
                    controller: _twitterController,
                    style: _inputText,
                    decoration: _decoration('X', icon: Icons.close_rounded),
                  ),
                  TextFormField(
                    controller: _linkedinController,
                    style: _inputText,
                    decoration: _decoration(
                      'Linkedin',
                      icon: Icons.business_center_outlined,
                    ),
                  ),
                ),
              ],
            ),

            // --- İlanlar & Mülkler ----------------------------------------
            _section(
              title: 'İlanlar ve Mülkler',
              icon: Icons.home_work_outlined,
              children: [
                TextFormField(
                  style: _inputText,
                  decoration: _decoration(
                    'İlgilendiği İlanlar',
                    hint: 'Ara',
                    icon: Icons.search_rounded,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _propertiesSearchController,
                      focusNode: _propertiesFocusNode,
                      style: _inputText,
                      decoration: _decoration(
                        'Mülkler',
                        hint: 'Ara',
                        icon: Icons.apartment_rounded,
                        suffixIcon: _selectedProperty != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: _brand,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedProperty = null;
                                    _propertiesSearchController.clear();
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                    _buildPropertiesListInline(),
                    if (_selectedProperty != null) ...[
                      const SizedBox(height: 10),
                      _buildSelectedPropertyChip(),
                    ],
                  ],
                ),
              ],
            ),

            // --- Ek Bilgiler ----------------------------------------------
            _section(
              title: 'Ek Bilgiler',
              icon: Icons.notes_rounded,
              children: [
                TextFormField(
                  controller: _howDidYouHearController,
                  style: _inputText,
                  decoration: _decoration(
                    'Bizi Nereden Duydunuz?',
                    icon: Icons.campaign_outlined,
                  ),
                ),
                TextFormField(
                  controller: _tagsController,
                  style: _inputText,
                  decoration: _decoration(
                    'Etiket Ekle',
                    hint: 'Virgülle ayırın',
                    icon: Icons.sell_outlined,
                  ),
                ),
                TextFormField(
                  controller: _notesController,
                  style: _inputText,
                  maxLines: 6,
                  minLines: 4,
                  decoration: _decoration(
                    'Not',
                    hint: 'Müşteri hakkında notlar...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

