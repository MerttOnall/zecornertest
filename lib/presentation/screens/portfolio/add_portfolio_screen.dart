import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:zecorner/models/portfolio/property_attribute.dart';
import 'package:zecorner/models/portfolio/category.dart';
import 'package:zecorner/models/portfolio/category_listing_type.dart';
import 'package:zecorner/models/portfolio/portfolio_form_data.dart';
import 'package:zecorner/models/province/province.dart';
import 'package:zecorner/services/portfolio_service.dart';
import 'package:zecorner/core/config/env_api.dart';
import 'package:zecorner/infrastructure/listing/listing_api_repository.dart';
import 'package:zecorner/core/network/dio_client.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:zecorner/core/location/nominatim_geocoding.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:zecorner/services/eids_verification_service.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/events/portfolio_change_notifier.dart';

class AddPortfolioScreen extends StatefulWidget {
  const AddPortfolioScreen({super.key});

  @override
  State<AddPortfolioScreen> createState() => _AddPortfolioScreenState();
}

class _AddPortfolioScreenState extends State<AddPortfolioScreen> {
  String selectedType = 'Konut';
  String selectedPortfolioType = 'Daire';
  bool showDaireFeatures = true;
  
  // Konut type mapping to API codes
  final Map<String, String> konutTypeMapping = {
    'Daire': 'konut-daire',
    'Rezidans': 'konut-rezidans',
    'Müstakil Ev': 'konut-mustakil-ev',
    'Villa': 'konut-villa',
    'Çiftlik Evi': 'konut-ciftlik-evi',
    'Köşk & Konak': 'konut-kosk-konak',
    'Yalı': 'konut-yali',
    'Yalı Dairesi': 'konut-yali-dairesi',
    'Yazlık': 'konut-yazlik',
    'Arsa': 'konut-arsa',
  };

  // Ticari type mapping to API codes
  final Map<String, String> ticariTypeMapping = {
    'Apartman Dairesi': 'is-yeri-apartman-dairesi',
    'Atölye': 'is-yeri-atolye',
    'Depo & Antrepo': 'is-yeri-depo-antrepo',
    'Fabrika': 'is-yeri-fabrika',
    'İmalathane': 'is-yeri-imalathane',
    'İş Hanı Katı & Ofisi': 'is-yeri-is-hani-kati-ofisi',
    'Dükkan & Mağaza': 'is-yeri-dukkan-magaza',
    'Muayenehane': 'is-yeri-muayenehane',
    'Plaza': 'is-yeri-plaza',
    'Plaza Katı & Ofisi': 'is-yeri-plaza-kati-ofisi',
    'Restoran & Lokanta': 'is-yeri-restoran-lokanta',
    'Tamirhane': 'is-yeri-tamirhane',
    'Cafe & Bar': 'is-yeri-cafe-bar',
    'Büro & Ofis': 'is-yeri-buro-ofis',
    'Maden Ocağı': 'is-yeri-maden-ocagi',
    'Kuaför & Güzellik Merkezi': 'is-yeri-kuafor-guzellik-merkezi',
    'Oto Yıkama & Kuaför': 'is-yeri-oto-yikama-kuafor',
    'Okul & Kurs': 'is-yeri-okul-kurs',
    'Taksi Durağı': 'is-yeri-taksi-duragi',
    'Market': 'is-yeri-market',
    'Eczane & Medikal': 'is-yeri-eczane-medikal',
    'Pastane & Fırın': 'is-yeri-pastane-firin',
    'Pazar Yeri': 'is-yeri-pazar-yeri',
    'Sağlık Merkezi': 'is-yeri-saglik-merkezi',
    'Prova & Kayıt Stüdyosu': 'is-yeri-prova-kayit-studyosu',
    'Sinema & Konferans Salonu': 'is-yeri-sinema-konferans-salonu',
    'Fotoğraf Stüdyosu': 'is-yeri-fotograf-studyosu',
    'Yurt': 'is-yeri-yurt',
    'Akaryakıt İstasyonu': 'is-yeri-akaryakit-istasyonu',
    'Büfe': 'is-yeri-bufe',
    'Komple Bina': 'is-yeri-komple-bina',
    'Otopark': 'is-yeri-otopark',
    'Spor Tesisi': 'is-yeri-spor-tesisi',
    'Spa, Hamam & Sauna': 'is-yeri-spa-hamam-sauna',
    'Çiftlik': 'is-yeri-ciftlik',
    'Düğün Salonu': 'is-yeri-dugun-salonu',
    'Hazır & Sanal Ofis': 'is-yeri-hazir-sanal-ofis',
    'Radyo İstasyonu & TV Kanalı': 'is-yeri-radyo-istasyonu-tv-kanali',
    'Kıraathane': 'is-yeri-kiraathane',
    'Kır & Kahvaltı Bahçesi': 'is-yeri-kir-kahvalti-bahcesi',
    'Rezidans Katı & Ofisi': 'is-yeri-rezidans-kati-ofisi',
    'AVM': 'is-yeri-avm',
    'Garaj': 'is-yeri-garaj',
    'Kantin': 'is-yeri-kantin',
    'Villa': 'is-yeri-villa',
    'Radyo İstasyonu': 'is-yeri-radyo-istasyonu',
    'Plaza Katı': 'is-yeri-plaza-kati',
    'Enerji Santrali': 'is-yeri-enerji-santrali',
    'Garaj & Park Yeri': 'is-yeri-garaj-park-yeri',
    'Arsa': 'is-yeri-arsa',
  };

  // Get current type mapping based on selected type (Konut/Ticari)
  Map<String, String> get portfolioTypeMapping {
    return selectedType == 'Konut' ? konutTypeMapping : ticariTypeMapping;
  }

  // Get list of portfolio types for current selection
  List<String> get portfolioTypeList {
    return portfolioTypeMapping.keys.toList();
  }
  
  // Check if selected portfolio type is Arsa (Land)
  bool get isArsaSelected {
    return selectedPortfolioType == 'Arsa';
  }
  
  // Image picker variables
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isLoading = false;

  // File picker variables
  PlatformFile? _selectedAuthorizationFile;
  bool _isPickingFile = false;

  // Form data
  final PortfolioFormData _formData = PortfolioFormData();
  
  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _m2BrutController = TextEditingController();
  final TextEditingController _m2NetController = TextEditingController();
  final TextEditingController _acikAlanM2Controller = TextEditingController();
  final TextEditingController _kapaliAlanM2Controller = TextEditingController();
  final TextEditingController _araziM2Controller = TextEditingController();
  final TextEditingController _salonSayisiController = TextEditingController();
  final TextEditingController _binaAdediController = TextEditingController();
  final TextEditingController _masaSayisiController = TextEditingController();
  final TextEditingController _derslikSayisiController =
      TextEditingController();
  final TextEditingController _pompaSayisiController = TextEditingController();
  final TextEditingController _aracKapasitesiController =
      TextEditingController();
  final TextEditingController _kisiKapasitesiController =
      TextEditingController();
  final TextEditingController _aidatController = TextEditingController();
  final TextEditingController _tasinmazController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // Currency selection
  String? _selectedCurrency;

  // Ticari controllers
  final TextEditingController _m2Controller =
      TextEditingController(); // Ticari için tek m2 alanı
  final TextEditingController _girisYuksekligiController =
      TextEditingController();
  final TextEditingController _bolumOdaSayisiController =
      TextEditingController();
  final TextEditingController _banyoSayisiNumberController =
      TextEditingController(); // Ticari için number olarak gelen banyo-sayisi
  final TextEditingController _bulunduguKatNumberController =
      TextEditingController(); // Ticari için number olarak gelen bulundugu-kat
  final TextEditingController _binaninYasiNumberController =
      TextEditingController(); // Ticari için number olarak gelen binanin-yasi
  final TextEditingController _katSayisiNumberController =
      TextEditingController(); // Ticari için number olarak gelen kat-sayisi

  // API Data
  PropertyAttributesResponse? _propertyAttributes;
  PropertyAttributesResponse?
      _listingProperties; // Properties based on listing type (Kiralık/Satılık)
  // ignore: unused_field
  List<Category>? _categories; // TODO: Will be used for category dropdown
  List<CategoryListingType>? _categoryListingTypes;
  List<Province>? _provinces;
  List<Province>? _districts;
  List<Province>? _neighborhoods;
  bool _isLoadingData = false;
  bool _isLoadingListingProperties = false;

  // Selected values
  CategoryListingType? _selectedListingType;

  // Dynamic listing properties values (depozito, krediye-uygun, tapu-durumu, etc.)
  final Map<String, dynamic> _listingPropertyValues = {};
  final Map<String, TextEditingController> _listingPropertyControllers = {};
  
  // Selected location
  Province? _selectedProvince;
  Province? _selectedDistrict;
  Province? _selectedNeighborhood;

  // Map state
  final MapController _mapController = MapController();
  LatLng _mapCenter = LatLng(39.9334, 32.8597); // Ankara default
  double _mapZoom = 10.0;
  bool _isSatelliteView = false;
  LatLng? _selectedLocation;
  Marker? _locationMarker;

  int _currentStep = 0;
  int _maxReachedStep = 0;
  static const _brandColor = Color.fromRGBO(238, 46, 36, 1);
  static const _surfaceColor = Color(0xFFF4F6FA);
  static const _cardRadius = 16.0;


  // Service
  final PortfolioService _portfolioService = PortfolioService();
  final EidsVerificationService _eidsVerificationService =
      EidsVerificationService();
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _m2BrutController.dispose();
    _m2NetController.dispose();
    _acikAlanM2Controller.dispose();
    _kapaliAlanM2Controller.dispose();
    _araziM2Controller.dispose();
    _salonSayisiController.dispose();
    _binaAdediController.dispose();
    _masaSayisiController.dispose();
    _derslikSayisiController.dispose();
    _pompaSayisiController.dispose();
    _aracKapasitesiController.dispose();
    _kisiKapasitesiController.dispose();
    _aidatController.dispose();
    _tasinmazController.dispose();
    _priceController.dispose();

    // Dispose Ticari controllers
    _m2Controller.dispose();
    _girisYuksekligiController.dispose();
    _bolumOdaSayisiController.dispose();
    _banyoSayisiNumberController.dispose();
    _bulunduguKatNumberController.dispose();
    _binaninYasiNumberController.dispose();
    _katSayisiNumberController.dispose();

    // Dispose dynamic listing property controllers
    for (var controller in _listingPropertyControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load provinces
      final provinces = await _portfolioService.getProvinces();

      if (mounted) {
      setState(() {
          _provinces = provinces;
      });
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
      if (mounted) {
        setState(() {
          _provinces = [];
        });
      }
    }

    // Load default property attributes for "Daire" - separate try-catch
    try {
      debugPrint('🔵 [API] Loading property attributes for type: konut-daire');
      final attributes =
          await _portfolioService.getPropertyAttributes('konut-daire');
      debugPrint('✅ [API] Property attributes loaded successfully');
      debugPrint('✅ [API] Properties count: ${attributes.properties.length}');

      if (mounted) {
      setState(() {
          _propertyAttributes = attributes;
        });
        _mergePropertyOwnerOptionsFromAttributes();
      }
    } catch (e) {
      debugPrint('Error loading property attributes: $e');
    }

    // Load listing types for "Daire" - separate try-catch
    try {
      debugPrint(
          '🔵 [API] Loading category listing types for category: konut-daire');
      final listingTypes =
          await _portfolioService.getCategoryListingTypes('konut-daire');
      debugPrint('✅ [API] Category listing types loaded successfully');
      debugPrint('✅ [API] Listing types count: ${listingTypes.length}');

      if (mounted) {
      setState(() {
          _categoryListingTypes = listingTypes;
        });
      }
    } catch (e) {
      debugPrint('Error loading listing types: $e');
    }

    // Gayrimenkul Sahibi seçenekleri — GET /refDictionary
    setState(() => _isLoadingPropertyOwnerOptions = true);
    try {
      debugPrint('🔵 [API] Loading property owner dictionary');
      final ownerOptions = await _portfolioService.getPropertyOwnerOptions();
      debugPrint('✅ [API] Property owner options: ${ownerOptions.length}');
      if (mounted) {
        setState(() {
          _propertyOwnerOptions = ownerOptions;
          _selectedPropertyOwner ??= _defaultTcCitizenOwnerCode();
          _formData.gayrimenkulSahibi = _selectedPropertyOwner;
          _isLoadingPropertyOwnerOptions = false;
        });
        _mergePropertyOwnerOptionsFromAttributes();
        _ensurePropertyOwnerSelection();
      }
    } catch (e) {
      debugPrint('Error loading property owner options: $e');
      if (mounted) {
        setState(() => _isLoadingPropertyOwnerOptions = false);
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadPropertyAttributes(String type) async {
    try {
      debugPrint('🔵 [API] Loading property attributes for type: $type');
      
      final attributes = await _portfolioService.getPropertyAttributes(type);
      
      debugPrint('✅ [API] Property attributes loaded successfully');
      debugPrint('✅ [API] Properties count: ${attributes.properties.length}');
      
      if (mounted) {
        setState(() {
          _propertyAttributes = attributes;
        });
        _mergePropertyOwnerOptionsFromAttributes();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API ERROR] Failed to load property attributes');
      debugPrint('❌ [API ERROR] Error: $e');
      debugPrint('❌ [API ERROR] Stack trace: $stackTrace');
      
      _showErrorMessage('Özellikler yüklenirken hata oluştu');
    }
  }

  // Handle portfolio type change
  Future<void> _onPortfolioTypeChanged(String? newValue) async {
    if (newValue == null || newValue == selectedPortfolioType) return;
    
    setState(() {
      selectedPortfolioType = newValue;
      showDaireFeatures = true; // Her konut tipi için özellikler gösterilecek
      _selectedListingType =
          null; // Reset listing type when portfolio type changes
      _categoryListingTypes = null; // Clear previous listing types
      _listingProperties =
          null; // Reset listing properties when portfolio type changes
      _propertyAttributes = null; // Clear previous properties to show loading
      _isLoadingData = true; // Show loading indicator

      // Clear listing property values and controllers
      _listingPropertyValues.clear();
      for (var controller in _listingPropertyControllers.values) {
        controller.dispose();
      }
      _listingPropertyControllers.clear();
    });

    // Get API code for selected type
    final apiCode = portfolioTypeMapping[newValue];
    if (apiCode != null) {
      try {
        // Load property attributes and listing types in parallel
        await Future.wait([
          _loadPropertyAttributes(apiCode),
          _loadCategoryListingTypes(apiCode),
        ]);
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingData = false; // Hide loading indicator
          });
        }
      }
    }
  }

  // Load category listing types
  Future<void> _loadCategoryListingTypes(String category) async {
    try {
      debugPrint(
          '🔵 [API] Loading category listing types for category: $category');

      final listingTypes =
          await _portfolioService.getCategoryListingTypes(category);

      debugPrint('✅ [API] Category listing types loaded successfully');
      debugPrint('✅ [API] Listing types count: ${listingTypes.length}');

      if (mounted) {
        setState(() {
          _categoryListingTypes = listingTypes;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API ERROR] Failed to load category listing types');
      debugPrint('❌ [API ERROR] Error: $e');
      debugPrint('❌ [API ERROR] Stack trace: $stackTrace');

      // Hata durumunda boş liste set et ki "yükleniyor" durumunda kalmasın
      if (mounted) {
        setState(() {
          _categoryListingTypes = [];
        });
      }
    }
  }

  // Load listing properties based on category and listing type (e.g., depozito-tl for rentals)
  Future<void> _loadListingProperties(
      String category, String listingType) async {
    setState(() {
      _isLoadingListingProperties = true;
      _listingProperties = null; // Reset previous data
    });

    try {
      debugPrint(
          '🔵 [API] Loading listing properties for category: $category, listingType: $listingType');

      final properties =
          await _portfolioService.getListingProperties(category, listingType);

      debugPrint('✅ [API] Listing properties loaded successfully');
      debugPrint('✅ [API] Properties count: ${properties.properties.length}');

      if (mounted) {
        setState(() {
          _listingProperties = properties;
          _isLoadingListingProperties = false;
        });
        _mergePropertyOwnerOptionsFromAttributes();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [API ERROR] Failed to load listing properties');
      debugPrint('❌ [API ERROR] Error: $e');
      debugPrint('❌ [API ERROR] Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _listingProperties = null;
          _isLoadingListingProperties = false;
        });
      }
    }
  }

  // Get property by code
  PropertyAttribute? _getPropertyByCode(String code) {
    if (_propertyAttributes == null) return null;
    try {
      return _propertyAttributes!.properties
          .firstWhere((prop) => prop.propertyCode == code);
    } catch (e) {
      return null;
    }
  }

  Future<void> _savePortfolio() async {
    // Update form data from controllers
    _formData.title = _titleController.text;
    _formData.description = _descriptionController.text;
    _formData.m2Brut = _m2BrutController.text;
    _formData.m2Net = _m2NetController.text;
    _formData.acikAlanM2 =
        _acikAlanM2Controller.text.isEmpty ? null : _acikAlanM2Controller.text;
    _formData.kapaliAlanM2 = _kapaliAlanM2Controller.text.isEmpty
        ? null
        : _kapaliAlanM2Controller.text;
    _formData.araziM2 =
        _araziM2Controller.text.isEmpty ? null : _araziM2Controller.text;
    _formData.salonSayisi = _salonSayisiController.text.isEmpty
        ? null
        : _salonSayisiController.text;
    _formData.binaAdedi =
        _binaAdediController.text.isEmpty ? null : _binaAdediController.text;
    _formData.masaSayisi =
        _masaSayisiController.text.isEmpty ? null : _masaSayisiController.text;
    _formData.derslikSayisi = _derslikSayisiController.text.isEmpty
        ? null
        : _derslikSayisiController.text;
    _formData.pompaSayisi = _pompaSayisiController.text.isEmpty
        ? null
        : _pompaSayisiController.text;
    _formData.aracKapasitesi = _aracKapasitesiController.text.isEmpty
        ? null
        : _aracKapasitesiController.text;
    _formData.kisiKapasitesi = _kisiKapasitesiController.text.isEmpty
        ? null
        : _kisiKapasitesiController.text;

    // Ticari number fields (bazı kategorilerde number, bazılarında select olabilir)
    if (_banyoSayisiNumberController.text.isNotEmpty) {
      _formData.banyoSayisi = _banyoSayisiNumberController.text;
    }
    if (_bulunduguKatNumberController.text.isNotEmpty) {
      _formData.bulunduguKat = _bulunduguKatNumberController.text;
    }
    if (_binaninYasiNumberController.text.isNotEmpty) {
      _formData.binaYasi = _binaninYasiNumberController.text;
    }
    if (_katSayisiNumberController.text.isNotEmpty) {
      _formData.katSayisi = _katSayisiNumberController.text;
    }

    _formData.aidatTl = _aidatController.text;
    _formData.tasinmazNumarasi = _tasinmazController.text;
    _formData.images = _selectedImages;
    
    // Update location from selected dropdowns (Web API code kullanıyor)
    _formData.provinceId = _selectedProvince?.code;
    _formData.districtId = _selectedDistrict?.code;
    _formData.neighborhoodId = _selectedNeighborhood?.code;

    // Validate
    final errors = _formData.getValidationErrors();
    if (errors.isNotEmpty) {
      _showErrorMessage(errors.first);
      return;
    }
    if (!_validatePropertyOwnerSelection()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formData.gayrimenkulSahibi = _selectedPropertyOwner;

      if (_isEidsExemptOwnerSelected) {
        final confirmed = await _showEidsExemptConfirmDialog();
        if (!confirmed) return;
      } else {
        // Web: get-user-info → get-contact → eids-validate-tasinmaz
        // { FirmaKod, Kullanicikodu(eids), VergiNo(ofis tax_no), TasinmazId }
        _eidsTasinmazData = null;
        final eidsResult = await _eidsVerificationService.verifyTasinmaz(
          tasinmazIdRaw: _tasinmazController.text,
        );
        final shouldContinue = await eidsResult.fold(
          (failure) async {
            if (failure is ValidationFailure) {
              // "Sizin EIDS'niz bulunmamakta." / taşınmaz no / vergi no eksik
              await _showEidsMissingDialog(failure.message);
            } else {
              _showErrorMessage(failure.message);
            }
            return false;
          },
          (result) async {
            if (result.ok) {
              final data = result.tasinmaz;
              _eidsTasinmazData = data;
              debugPrint(
                '✅ EIDS doğrulandı: ${data?.summary} '
                '(ilanSuresi=${data?.ilanSuresi?.toIso8601String()})',
              );
              if (data != null && data.isExpired) {
                await _showEidsMissingDialog(
                  'EIDS yetkiniz yok',
                  detail:
                      'Bu taşınmaz için EIDS yetki süresi ${_formatEidsDate(data.ilanSuresi!)} tarihinde dolmuştur.',
                );
                return false;
              }
              return true;
            }
            await _showEidsMissingDialog(
              result.message ?? 'EIDS yetkiniz yok',
              detail: result.detail,
            );
            return false;
          },
        );
        if (!shouldContinue) return;
      }

      // Get portfolio type from mapping
      final apiCode = portfolioTypeMapping[selectedPortfolioType];
      if (apiCode == null) {
        _showErrorMessage('Portföy tipi seçilmedi');
        return;
      }

      // Ensure categoryId is set
      if (_formData.categoryId == null && _selectedListingType != null) {
        _formData.categoryId = _selectedListingType!.id;
      }
      
      if (_formData.categoryId == null) {
        _showErrorMessage('İlan tipi seçilmedi');
        return;
      }

      // Prepare form data including location and other fields
      final apiFormData = _formData.toApiFormat();
      if (_selectedPropertyOwner != null) {
        apiFormData['gayrimenkul-sahibi'] = _selectedPropertyOwner;
      }

      // Add listing property values (depozito-tl, krediye-uygun, tapu-durumu, etc.)
      _listingPropertyValues.forEach((key, value) {
        if (value != null) {
          apiFormData[key] = value;
        }
      });

      // Add listing property controller values (number fields)
      _listingPropertyControllers.forEach((key, controller) {
        if (controller.text.isNotEmpty) {
          apiFormData[key] = controller.text;
        }
      });

      // Add price and currency
      if (_priceController.text.isNotEmpty) {
        apiFormData['price'] = _priceController.text;
      }
      if (_selectedCurrency != null) {
        apiFormData['currency'] = _selectedCurrency;
      }
      
      // Add location data (BAMMA adres: kod + isim, uavt_address ile uyum)
      if (_formData.provinceId != null) {
        apiFormData['province_id'] = _formData.provinceId!;
        apiFormData['province_name'] = _selectedProvince?.name ?? '';
      }
      if (_formData.districtId != null) {
        apiFormData['district_id'] = _formData.districtId!;
        apiFormData['district_name'] = _selectedDistrict?.name ?? '';
      }
      if (_formData.neighborhoodId != null) {
        apiFormData['neighborhood_id'] = _formData.neighborhoodId!;
        apiFormData['neighborhood_name'] = _selectedNeighborhood?.name ?? '';
      }
      if (_formData.latitude != null) {
        apiFormData['latitude'] = _formData.latitude!;
      }
      if (_formData.longitude != null) {
        apiFormData['longitude'] = _formData.longitude!;
      }
      
      // Convert authorization file from PlatformFile to File if exists
      File? authorizationFile;
      if (_selectedAuthorizationFile != null && _selectedAuthorizationFile!.path != null) {
        authorizationFile = File(_selectedAuthorizationFile!.path!);
      }

      final propertyRowIds = <String, String>{};
      if (_propertyAttributes != null) {
        PortfolioService.collectPropertyRowIds(
          _propertyAttributes!.properties,
          propertyRowIds,
        );
      }
      if (_listingProperties != null) {
        PortfolioService.collectPropertyRowIds(
          _listingProperties!.properties,
          propertyRowIds,
        );
      }

      final portfolioId = await _portfolioService.createPortfolio(
          title: _formData.title!,
          description: _formData.description!,
          portfolioType: apiCode, // Use mapped API code
          categoryId: _formData.categoryId!,
          formData: apiFormData,
          propertyRowIdsByCode: propertyRowIds,
          images: _formData.images,
          authorizationFile: authorizationFile,
        );

        if (portfolioId != null && mounted) {
          debugPrint('✅ Portfolio created with ID: $portfolioId');
          
          // Step 2: Create listing automatically after portfolio creation
          try {
            await _createListingAfterPortfolio(portfolioId);
            final eids = _eidsTasinmazData;
            _showSuccessMessage(
              eids == null
                  ? 'Portföy ve ilan başarıyla eklendi'
                  : 'Portföy ve ilan başarıyla eklendi · EIDS doğrulandı (${eids.summary})',
            );
          } catch (e) {
            debugPrint('⚠️ Portfolio created but listing creation failed: $e');
            _showSuccessMessage('Portföy eklendi ancak ilan oluşturulamadı: ${e.toString()}');
          }

          // Portföyüm vb. liste ekranları otomatik yenilensin.
          PortfolioChangeNotifier.notifyChanged();
          Navigator.pop(context, true);
        } else {
          _showErrorMessage('Portföy oluşturulamadı');
        }
    } catch (e) {
      debugPrint('❌ Error saving portfolio: $e');
      _showErrorMessage('Portföy eklenirken hata oluştu: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create listing after portfolio creation
  Future<void> _createListingAfterPortfolio(String portfolioId) async {
    try {
      debugPrint('🔄 Creating listing for portfolio: $portfolioId');
      
      // Get listing type (kiralik/satilik)
      final listingType = _formData.listingType;
      if (listingType == null || listingType.isEmpty) {
        debugPrint('⚠️ Listing type not set, skipping listing creation');
        return;
      }

      // Prepare listing properties — BAMMA `listing.property` satırı:
      //   id           → property_value (ref seçenek/satır id'si)
      //   value        → number_value (SAYISAL; metin gönderilirse
      //                  "invalid input syntax for type integer" 500 verir)
      //   string_value → string_value
      // realEstate ile aynı sözleşme (PortfolioService._bammaPropertyRow).
      final properties = <Map<String, dynamic>>[];

      // Ref ağacından satır id'leri (number/text alanları için)
      final rowIds = <String, String>{};
      if (_listingProperties != null) {
        PortfolioService.collectPropertyRowIds(
          _listingProperties!.properties,
          rowIds,
        );
      }

      // Select alanları (krediye-uygun, tapu-durumu vb.) → seçeneğin id'si
      _listingPropertyValues.forEach((key, value) {
        if (value == null || _listingPropertyControllers.containsKey(key)) {
          return;
        }
        final selectedCode = value.toString().trim();
        if (selectedCode.isEmpty) return;

        final optionId = _listingOptionIdForCode(key, selectedCode);
        if (optionId == null) {
          debugPrint(
            '⚠️ Listing select "$key"="$selectedCode" için seçenek id bulunamadı; string_value ile gönderiliyor',
          );
          properties.add({
            'code': key,
            'id': rowIds[key],
            'value': null,
            'string_value': selectedCode,
          });
          return;
        }
        properties.add({
          'code': key,
          'id': optionId,
          'value': null,
          'string_value': null,
        });
      });

      // Number / textbox alanları
      _listingPropertyControllers.forEach((key, controller) {
        final text = controller.text.trim();
        if (text.isEmpty) return;

        final n = num.tryParse(text.replaceAll(',', '.'));
        if (n != null) {
          properties.add({
            'code': key,
            'id': rowIds[key],
            'value': n % 1 == 0 ? n.toInt() : n.toDouble(),
            'string_value': null,
          });
        } else {
          properties.add({
            'code': key,
            'id': rowIds[key],
            'value': null,
            'string_value': text,
          });
        }
      });

      // Validate price
      if (_priceController.text.isEmpty) {
        debugPrint('⚠️ Price is empty, skipping listing creation');
        throw Exception('Fiyat girilmedi, ilan oluşturulamadı');
      }

      double price;
      try {
        price = double.parse(_priceController.text);
      } catch (e) {
        debugPrint('⚠️ Invalid price format: ${_priceController.text}');
        throw Exception('Geçersiz fiyat formatı');
      }

      // Prepare listing data
      final listingData = <String, dynamic>{
        'real_estate': portfolioId,
        'type': listingType, // "kiralik" or "satilik"
        'title': _formData.title!,
        'description': _formData.description!,
        'price': price,
        'currency': _selectedCurrency ?? 'TL',
        'internal': _showOnlyZeOnline, // Use switch value: true = only Ze-Online, false = everywhere
        'properties': properties,
      };

      debugPrint('📋 Listing Data: $listingData');

      // Create listing
      final repository = ListingApiRepository(dio: DioClient().dio);
      final result = await repository.createListing(listingData);

      result.fold(
        (failure) {
          debugPrint('❌ Listing creation failed: ${failure.message}');
          throw Exception('İlan oluşturulamadı: ${failure.message}');
        },
        (response) {
          debugPrint('✅ Listing created successfully');
          debugPrint('📋 Response: $response');
        },
      );
    } catch (e) {
      debugPrint('❌ Error creating listing: $e');
      rethrow;
    }
  }

  /// `refListingProperties` (yoksa `refRealEstateProperties`) ağacında
  /// [propertyCode] select alanının [optionCode] seçeneğinin ref id'si.
  String? _listingOptionIdForCode(String propertyCode, String optionCode) {
    for (final tree in [_listingProperties, _propertyAttributes]) {
      final attr = PortfolioService.findPropertyAttribute(tree, propertyCode);
      if (attr == null) continue;
      for (final v in attr.values) {
        if (v.code?.trim() == optionCode) {
          final id = v.id?.toString().trim();
          if (id != null && id.isNotEmpty) return id;
        }
      }
    }
    return null;
  }

  // Modern kamera fonksiyonu - İzin kontrolü ile
  Future<void> _pickImageFromCamera() async {
    if (_isLoading || _selectedImages.length >= 35) {
      if (_selectedImages.length >= 35) {
        _showErrorMessage('Maksimum 35 fotoğraf ekleyebilirsiniz');
      }
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('📷 Kamera açılıyor...');

      // Modern image_picker ile yüksek kaliteli fotoğraf çek
      // İzin kontrolü yapmıyoruz, sistem otomatik olarak isteyecek
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Daha iyi kalite
        maxWidth: 2048, // Daha yüksek çözünürlük
        maxHeight: 2048,
        preferredCameraDevice: CameraDevice.rear, // Arka kamera tercih edilir
      );

      if (pickedFile != null && mounted) {
        await _processImageFile(pickedFile);
          } else {
        debugPrint('📷 Fotoğraf çekme iptal edildi');
      }
    } catch (e) {
      debugPrint('❌ Kamera hatası: $e');
      _showErrorMessage(
          'Kamera açılırken bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Modern galeri fonksiyonu - Çoklu seçim ile
  Future<void> _pickMultipleImagesFromGallery() async {
    if (_isLoading || _selectedImages.length >= 35) {
      if (_selectedImages.length >= 35) {
        _showErrorMessage('Maksimum 35 fotoğraf ekleyebilirsiniz');
      }
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('🖼️ Galeri açılıyor...');

      // Çoklu fotoğraf seçimi
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        int remainingSlots = 35 - _selectedImages.length;
        int filesToProcess = pickedFiles.length > remainingSlots
            ? remainingSlots
            : pickedFiles.length;

        int successCount = 0;
        int failCount = 0;

        for (int i = 0; i < filesToProcess; i++) {
          try {
            await _processImageFile(pickedFiles[i]);
            successCount++;
          } catch (e) {
            debugPrint('❌ Fotoğraf işlenirken hata: $e');
            failCount++;
          }
        }

        if (pickedFiles.length > remainingSlots) {
          _showErrorMessage(
              'Sadece $remainingSlots fotoğraf eklendi. Maksimum 35 fotoğraf limitine ulaşıldı.');
        } else if (successCount > 0) {
          _showSuccessMessage(
              '$successCount fotoğraf başarıyla eklendi! (${_selectedImages.length}/35)');
        }

        if (failCount > 0) {
          _showErrorMessage('$failCount fotoğraf eklenemedi');
        }
      } else {
        debugPrint('🖼️ Fotoğraf seçme iptal edildi');
      }
    } catch (e) {
      debugPrint('❌ Galeri hatası: $e');
      _showErrorMessage(
          'Galeri açılırken bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fotoğraf dosyasını işle ve ekle
  Future<void> _processImageFile(XFile pickedFile) async {
    final file = File(pickedFile.path);

    if (!await file.exists()) {
      throw Exception('Fotoğraf dosyası bulunamadı');
    }

    final fileSize = await file.length();

    if (fileSize == 0) {
      throw Exception('Fotoğraf dosyası boş');
    }

    if (fileSize > 50 * 1024 * 1024) {
      throw Exception(
          'Fotoğraf dosyası çok büyük (max 50MB). Mevcut boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
    }

    if (mounted) {
      setState(() {
        _selectedImages.add(file);
      });
      debugPrint(
          '✅ Fotoğraf eklendi: ${file.path} (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB)');
    }
  }

  // Modern izin dialog'u - Kırmızı-beyaz tema

  // Çoklu fotoğraf seçimi (galeriden)

  // Remove image
  // Modern fotoğraf silme - Onay dialog'u ile (Kırmızı-beyaz tema)
  void _removeImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE53935),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Başlık
              const Text(
                'Fotoğrafı Sil',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Mesaj
              const Text(
                'Bu fotoğrafı silmek istediğinizden emin misiniz?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (mounted && index < _selectedImages.length) {
      setState(() {
                            _selectedImages.removeAt(index);
                          });
                          _showSuccessMessage('Fotoğraf kaldırıldı');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // Fotoğraf önizleme - Tam ekran görüntüleme
  void _showImagePreview(int index) {
    if (index < 0 || index >= _selectedImages.length) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Fotoğraf
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  _selectedImages[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Kapat butonu
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: const CircleBorder(),
                ),
              ),
            ),
            // Fotoğraf bilgisi
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fotoğraf ${index + 1} / ${_selectedImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (index == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Kapak Fotoğrafı',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  // Modern dosya seçme - Yetki Belgesi için
  Future<void> _pickAuthorizationFile() async {
    if (_isPickingFile) return;
    
    try {
      setState(() {
        _isPickingFile = true;
      });

      debugPrint('📄 Dosya seçici açılıyor...');

      // Dosya seçici - PDF, DOC, DOCX, XLS, XLSX, JPG, PNG formatları
      // İzin kontrolü yapmıyoruz, sistem otomatik olarak isteyecek
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final filePath = platformFile.path!;
        final file = File(filePath);
          
          if (await file.exists()) {
            final fileSize = await file.length();
            
          // Maksimum 10MB kontrolü
          if (fileSize > 10 * 1024 * 1024) {
            _showErrorMessage('Dosya çok büyük (max 10MB). Mevcut boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
            return;
          }
          
          if (mounted) {
              setState(() {
              _selectedAuthorizationFile = platformFile;
            });
            
            final fileName = platformFile.name;
            final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
            _showSuccessMessage('Dosya seçildi: $fileName (${fileSizeMB}MB)');
            debugPrint('✅ Dosya seçildi: $fileName (${fileSizeMB}MB)');
          }
        } else {
          _showErrorMessage('Dosya bulunamadı');
        }
        } else {
        debugPrint('📄 Dosya seçme iptal edildi');
      }
    } catch (e) {
      debugPrint('❌ Dosya seçme hatası: $e');
      _showErrorMessage('Dosya seçilirken bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  // Dosya silme
  void _removeAuthorizationFile() {
    if (_selectedAuthorizationFile == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFE53935),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              // Başlık
              const Text(
                'Dosyayı Kaldır',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE53935),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Mesaj
              Text(
                '${_selectedAuthorizationFile!.name} dosyasını kaldırmak istediğinizden emin misiniz?',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (mounted) {
      setState(() {
                            _selectedAuthorizationFile = null;
                          });
                          _showSuccessMessage('Dosya kaldırıldı');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Kaldır',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // Dosya ikonu getir
  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_outlined;
    
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.doc':
      case '.docx':
        return Icons.description_outlined;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart_outlined;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // Dosya formatı getir
  String _getFileFormat(String? fileName) {
    if (fileName == null) return '';
    return path.extension(fileName).toUpperCase().replaceAll('.', '');
  }

  // Fotoğraf sırasını değiştir dialog
  // Modern fotoğraf sıralama bottom sheet - Kırmızı-beyaz tema
  void _showImageReorderDialog(int currentIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Başlık
                  Text(
                    'Fotoğraf Sırası Değiştir',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currentIndex + 1}. fotoğraf',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Fotoğraf önizleme
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE53935),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(
                        _selectedImages[currentIndex],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Butonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (currentIndex > 0)
                        _buildReorderOption(
                          icon: Icons.arrow_back_rounded,
                          label: 'Öne Al',
                          onTap: () {
                            Navigator.pop(context);
                            _moveImageForward(currentIndex);
                          },
                        ),
                      if (currentIndex > 0)
                        _buildReorderOption(
                          icon: Icons.first_page_rounded,
                          label: 'En Öne',
                          onTap: () {
                            Navigator.pop(context);
                            _moveImageToFirst(currentIndex);
                          },
                        ),
                      if (currentIndex < _selectedImages.length - 1)
                        _buildReorderOption(
                          icon: Icons.arrow_forward_rounded,
                          label: 'Arkaya Al',
                          onTap: () {
                            Navigator.pop(context);
                            _moveImageBackward(currentIndex);
                          },
                        ),
                      if (currentIndex < _selectedImages.length - 1)
                        _buildReorderOption(
                          icon: Icons.last_page_rounded,
                          label: 'En Arkaya',
                          onTap: () {
                            Navigator.pop(context);
                            _moveImageToLast(currentIndex);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern sıralama butonu - Kırmızı-beyaz tema
  Widget _buildReorderOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(16),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                  color: const Color(0xFFE53935),
                  size: 24,
              ),
            ),
              const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  // Fotoğraf sıralama fonksiyonları
  void _moveImageForward(int index) {
    if (index > 0) {
      setState(() {
        final File temp = _selectedImages[index];
        _selectedImages[index] = _selectedImages[index - 1];
        _selectedImages[index - 1] = temp;
      });
      _showSuccessMessage('Fotoğraf öne alındı');
    }
  }

  void _moveImageBackward(int index) {
    if (index < _selectedImages.length - 1) {
      setState(() {
        final File temp = _selectedImages[index];
        _selectedImages[index] = _selectedImages[index + 1];
        _selectedImages[index + 1] = temp;
      });
      _showSuccessMessage('Fotoğraf arkaya alındı');
    }
  }

  void _moveImageToFirst(int index) {
    if (index > 0) {
      setState(() {
        final File temp = _selectedImages.removeAt(index);
        _selectedImages.insert(0, temp);
      });
      _showSuccessMessage('Fotoğraf en öne alındı');
    }
  }

  void _moveImageToLast(int index) {
    if (index < _selectedImages.length - 1) {
      setState(() {
        final File temp = _selectedImages.removeAt(index);
        _selectedImages.add(temp);
      });
      _showSuccessMessage('Fotoğraf en arkaya alındı');
    }
  }

  // Message helpers
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _showEidsExemptConfirmDialog() async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Portföy Oluştur',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEidsExemptWarningBox(),
            const SizedBox(height: 16),
            const Text(
              'Portföy oluşturmak istediğinize emin misiniz?',
              style: TextStyle(fontSize: 15, color: Color(0xFF334155)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Hayır',
              style: TextStyle(color: _brandColor, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Evet'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildEidsExemptWarningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _brandColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _eidsExemptWarningMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF991B1B),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZeOnlineToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Sadece Ze-Online\'da göster',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      'Açıkken ilan yalnızca Ze-Online\'da görünür; kapalıyken tüm kanallarda yayınlanır.',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _showOnlyZeOnline,
            activeTrackColor: _brandColor.withValues(alpha: 0.35),
            activeThumbColor: _brandColor,
            onChanged: (value) => setState(() => _showOnlyZeOnline = value),
          ),
        ],
      ),
    );
  }

  Future<void> _showPropertyOwnerPicker() async {
    if (_propertyOwnerOptions.isEmpty) return;
    MapEntry<String, String>? selectedEntry;
    if (_selectedPropertyOwner != null) {
      for (final option in _propertyOwnerOptions) {
        if (option.key == _selectedPropertyOwner) {
          selectedEntry = option;
          break;
        }
      }
    }
    await _showMobileOptionPicker<MapEntry<String, String>>(
      title: 'Gayrimenkul Sahibi',
      items: _propertyOwnerOptions,
      itemLabel: (v) => v.value,
      itemSubtitle: (v) => _propertyOwnerEidsHint(v.key),
      selected: selectedEntry,
      isSameItem: (a, b) => a.key == b.key,
      searchable: true,
      onSelected: (value) {
        setState(() {
          _selectedPropertyOwner = value.key;
          _formData.gayrimenkulSahibi = value.key;
        });
      },
    );
  }

  Widget _buildPropertyOwnerSection() {
    if (_isLoadingPropertyOwnerOptions && _propertyOwnerOptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Gayrimenkul sahibi seçenekleri yükleniyor...',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMobilePickerTile(
          label: 'Gayrimenkul Sahibi',
          value: _propertyOwnerLabel(_selectedPropertyOwner),
          hint: 'Gayrimenkul sahibi seçiniz',
          onTap: _showPropertyOwnerPicker,
          leadingIcon: Icons.person_outline,
        ),
        if (_isEidsExemptOwnerSelected) ...[
          const SizedBox(height: 12),
          _buildEidsExemptWarningBox(),
        ] else if (_isTcCitizenOwner(_selectedPropertyOwner)) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Bu seçimde taşınmaz numarası ile EİDS doğrulaması yapılır.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _showEidsMissingDialog(String message, {String? detail}) async {
    if (!mounted) return;
    final hasDetail = detail != null && detail.trim().isNotEmpty;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'EIDS Uyarısı',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
            ),
            if (hasDetail) ...[
              const SizedBox(height: 10),
              Text(
                detail.trim(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Tamam',
              style: TextStyle(color: _brandColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEidsDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  /// Son başarılı EIDS doğrulamasının `data` alanı (il/ilçe/mahalle/ada/parsel/ilanSuresi).
  EidsTasinmazData? _eidsTasinmazData;

  // Toggle state for "Sadece Ze-Online'da göster"
  bool _showOnlyZeOnline = false;

  // Gayrimenkul Sahibi — GET /refDictionary (web: /api/get-dictionary/)
  List<MapEntry<String, String>> _propertyOwnerOptions = const [];
  String? _selectedPropertyOwner;
  bool _isLoadingPropertyOwnerOptions = false;

  static const _eidsExemptWarningMessage =
      'Bu ilan EİDS\'den muaf olacaktır. Bütün sorumluluk ve cezai işlemler size aittir.';

  /// EİDS kuralı (web ile aynı): yalnızca **"T.C. vatandaşı"** için taşınmaz
  /// numarası ile EİDS doğrulaması yapılır. **"T.C. vatandaşı değil"**,
  /// "Banka / Vakıf / Dernek / Sendika" ve "Kamu Kurumu" EİDS'den muaftır.
  ///
  /// Hem seçenek kodu hem etiketi kontrol edilir; sunucu kodu farklı gelse de
  /// ("tc-vatandasi", "T.C. vatandaşı" vb.) doğru sınıflanır.
  bool _isTcCitizenOwner(String? code) {
    if (code == null || code.isEmpty) return false;
    final candidates = <String>[code];
    for (final option in _propertyOwnerOptions) {
      if (option.key == code) {
        candidates.add(option.value);
        break;
      }
    }
    for (final raw in candidates) {
      final n = _foldOwnerText(raw);
      if (n.isEmpty) continue;
      // "T.C. vatandaşı değil" → muaf
      if (n.contains('degil') ||
          n.contains('noncitizen') ||
          n.contains('notcitizen')) {
        return false;
      }
      if (n.contains('tcvatandasi') ||
          n.contains('turkvatandasi') ||
          n.contains('tccitizen') ||
          n.contains('turkishcitizen')) {
        return true;
      }
    }
    return false;
  }

  /// Türkçe karakterleri sadeleştirip harf/rakam dışını atar:
  /// "T.C. vatandaşı değil" → "tcvatandasidegil"
  static String _foldOwnerText(String s) {
    const map = {
      'ı': 'i', 'İ': 'i', 'ş': 's', 'Ş': 's', 'ğ': 'g', 'Ğ': 'g',
      'ü': 'u', 'Ü': 'u', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
    };
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Seçenek EİDS'den muaf mı? (T.C. vatandaşı dışındaki tüm seçenekler)
  bool _isEidsExemptOwner(String? code) =>
      code != null && code.isNotEmpty && !_isTcCitizenOwner(code);

  bool get _isEidsExemptOwnerSelected =>
      _isEidsExemptOwner(_selectedPropertyOwner);

  /// Dropdown alt satırı: seçeneğin EİDS durumu.
  String _propertyOwnerEidsHint(String code) => _isEidsExemptOwner(code)
      ? 'EİDS\'den muaf — taşınmaz doğrulaması yapılmaz'
      : 'EİDS doğrulaması gerekir — taşınmaz numarası zorunlu';

  String? _propertyOwnerLabel(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final option in _propertyOwnerOptions) {
      if (option.key == code) {
        return option.value == option.key
            ? PortfolioService.formatPropertyOwnerOptionLabel(code)
            : option.value;
      }
    }
    return PortfolioService.formatPropertyOwnerOptionLabel(code);
  }

  String? _defaultTcCitizenOwnerCode() {
    for (final option in _propertyOwnerOptions) {
      if (_isTcCitizenOwner(option.key)) return option.key;
    }
    return _propertyOwnerOptions.isNotEmpty
        ? _propertyOwnerOptions.first.key
        : null;
  }

  void _ensurePropertyOwnerSelection() {
    if (_selectedPropertyOwner == null && _formData.gayrimenkulSahibi != null) {
      _selectedPropertyOwner = _formData.gayrimenkulSahibi;
    }
    if (_selectedPropertyOwner == null && _propertyOwnerOptions.isNotEmpty) {
      _selectedPropertyOwner = _defaultTcCitizenOwnerCode();
    }
    _formData.gayrimenkulSahibi = _selectedPropertyOwner;
  }

  void _mergePropertyOwnerOptionsFromAttributes() {
    final fromRealEstate = PortfolioService.extractSelectPropertyOptions(
      _propertyAttributes,
      'gayrimenkul-sahibi',
    );
    final fromListing = PortfolioService.extractSelectPropertyOptions(
      _listingProperties,
      'gayrimenkul-sahibi',
    );
    final merged =
        fromRealEstate.isNotEmpty ? fromRealEstate : fromListing;
    if (merged.isEmpty) return;

    final preservedSelection =
        _selectedPropertyOwner ?? _formData.gayrimenkulSahibi;

    setState(() {
      _propertyOwnerOptions = merged;
      if (preservedSelection != null &&
          merged.any((e) => e.key == preservedSelection)) {
        _selectedPropertyOwner = preservedSelection;
      } else {
        _selectedPropertyOwner = _defaultTcCitizenOwnerCode();
      }
      _formData.gayrimenkulSahibi = _selectedPropertyOwner;
    });
  }

  bool _validatePropertyOwnerSelection() {
    _ensurePropertyOwnerSelection();
    if (_selectedPropertyOwner == null || _selectedPropertyOwner!.isEmpty) {
      _showErrorMessage('Gayrimenkul sahibi seçilmelidir');
      return false;
    }
    if (_propertyOwnerOptions.isNotEmpty &&
        !_propertyOwnerOptions.any((e) => e.key == _selectedPropertyOwner)) {
      _showErrorMessage('Geçerli bir gayrimenkul sahibi seçiniz');
      return false;
    }
    return true;
  }

  // Mevcut Yetki Belgesi İndirme
  // TODO: RealEstateModel'de authorizationCertificate field'ı eklendiğinde bu metodu aktif et
  // void _downloadExistingAuthorizationFile() {
  //   if (_currentPortfolio?.authorizationCertificate == null || 
  //       _currentPortfolio!.authorizationCertificate!.isEmpty) {
  //     _showErrorMessage('Yetki belgesi bulunamadı');
  //     return;
  //   }
  //   
  //   // TODO: Yetki belgesi indirme API çağrısı
  //   _showSuccessMessage('Yetki belgesi indiriliyor...');
  // }

  @override
  Widget build(BuildContext context) {
    final stepTitles = _getStepTitles();
    final safeStep = _currentStep.clamp(0, stepTitles.length - 1);
    if (safeStep != _currentStep ||
        _maxReachedStep >= stepTitles.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentStep = _currentStep.clamp(0, stepTitles.length - 1);
            if (_maxReachedStep >= stepTitles.length) {
              _maxReachedStep = stepTitles.length - 1;
            }
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AdminPanelAppBar(
        title: "Portföy Oluştur",
        onMenuPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            _buildStepProgressBar(stepTitles),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _buildStepCard(
                      child: _buildCurrentStepContent(stepTitles),
                    ),
                  ),
                ),
              ),
            ),
            _buildStepNavigation(stepTitles.length),
          ],
        ),
      ),
    );
  }


  List<String> _getStepTitles() {
    final titles = <String>[
      'Portföy Tipi',
      'Yetki Belgesi',
      'Portföy Görselleri',
      'Başlık ve Açıklama',
      'Adres',
    ];
    if (showDaireFeatures && !isArsaSelected) {
      titles.add('Özellikler');
      if (selectedType == 'Konut' && !isArsaSelected) {
        titles.addAll([
          'Cephe',
          'İç Özellikler',
          'Dış Özellikler',
          'Muhit',
          'Ulaşım',
          'Manzara',
          'Konut Tipi',
          'Engelliye ve Yaşlıya Uygun',
        ]);
      } else if (selectedType == 'Ticari' && !isArsaSelected) {
        if (_propertyAttributes != null) {
          for (final property in _propertyAttributes!.properties) {
            if (property.control == 'checkbox' &&
                property.propertyCode != 'realEstateProperties') {
              titles.add(_formatPropertyLabel(property.propertyCode));
            }
          }
        }
      }
    }
    return titles;
  }

  void _resetSteps() {
    _currentStep = 0;
    _maxReachedStep = 0;
  }

  void _goToStep(int step) {
    final titles = _getStepTitles();
    if (step < 0 || step >= titles.length) return;
    if (step > _maxReachedStep) return;
    setState(() => _currentStep = step);
  }

  bool _validateCurrentStep() {
    final titles = _getStepTitles();
    if (_currentStep >= titles.length) return true;
    final title = titles[_currentStep];

    switch (title) {
      case 'Portföy Tipi':
        if (!_validatePropertyOwnerSelection()) return false;
        if (selectedPortfolioType.isEmpty) {
          _showErrorMessage('Portföy tipi seçilmelidir');
          return false;
        }
        if (!isArsaSelected &&
            (_categoryListingTypes == null ||
                _categoryListingTypes!.isEmpty ||
                _selectedListingType == null)) {
          _showErrorMessage('İlan tipi seçilmelidir');
          return false;
        }
        return true;
      case 'Yetki Belgesi':
        return true;
      case 'Portföy Görselleri':
        if (_selectedImages.isEmpty) {
          _showErrorMessage('En az 1 fotoğraf eklenmelidir');
          return false;
        }
        return true;
      case 'Başlık ve Açıklama':
        if (_titleController.text.trim().isEmpty) {
          _showErrorMessage('Başlık girilmelidir');
          return false;
        }
        if (_descriptionController.text.trim().isEmpty) {
          _showErrorMessage('Açıklama girilmelidir');
          return false;
        }
        return true;
      case 'Adres':
        if (_selectedProvince == null) {
          _showErrorMessage('İl seçilmelidir');
          return false;
        }
        if (_selectedDistrict == null) {
          _showErrorMessage('İlçe seçilmelidir');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _goToNextStep() {
    if (!_validateCurrentStep()) return;
    final titles = _getStepTitles();
    if (_currentStep < titles.length - 1) {
      setState(() {
        _currentStep++;
        if (_currentStep > _maxReachedStep) {
          _maxReachedStep = _currentStep;
        }
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Widget _buildFieldLabel(String label, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
            letterSpacing: 0.1,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  Widget _buildStepCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMobilePickerTile({
    required String label,
    String? value,
    required String hint,
    VoidCallback? onTap,
    bool enabled = true,
    IconData leadingIcon = Icons.touch_app_outlined,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    final displayText = hasValue ? value : hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1 : 0.65,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  color: hasValue
                      ? _brandColor.withValues(alpha: 0.04)
                      : const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasValue
                        ? _brandColor.withValues(alpha: 0.25)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasValue
                              ? _brandColor.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          leadingIcon,
                          size: 18,
                          color: hasValue ? _brandColor : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                            color: hasValue
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.unfold_more_rounded,
                        color: enabled ? _brandColor : Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMobileOptionPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    T? selected,
    required ValueChanged<T> onSelected,
    bool searchable = false,
    bool Function(T a, T b)? isSameItem,
    String? Function(T)? itemSubtitle,
  }) async {
    if (items.isEmpty) return;

    List<T> filtered = List.from(items);
    final searchController = TextEditingController();
    final useSearch = searchable || items.length > 8;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildModernOptionSheet<T>(
              title: title,
              items: filtered,
              itemLabel: itemLabel,
              itemSubtitle: itemSubtitle,
              selected: selected,
              isSameItem: isSameItem,
              searchController: useSearch ? searchController : null,
              onSearchChanged: useSearch
                  ? (q) {
                      setModalState(() {
                        final query = q.trim().toLowerCase();
                        filtered = items
                            .where((item) =>
                                itemLabel(item).toLowerCase().contains(query))
                            .toList();
                      });
                    }
                  : null,
              onItemSelected: (item) {
                Navigator.of(ctx).pop();
                onSelected(item);
              },
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  Widget _buildModernOptionSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    T? selected,
    TextEditingController? searchController,
    ValueChanged<String>? onSearchChanged,
    required ValueChanged<T> onItemSelected,
    bool Function(T a, T b)? isSameItem,
    String? Function(T)? itemSubtitle,
  }) {
    final maxH = MediaQuery.of(context).size.height * 0.72;
    final compare = isSameItem ?? (a, b) => a == b;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if (searchController != null && onSearchChanged != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                    filled: true,
                    fillColor: _surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final label = itemLabel(item);
                  final subtitle = itemSubtitle?.call(item);
                  final hasSubtitle =
                      subtitle != null && subtitle.trim().isNotEmpty;
                  final isSelected =
                      selected != null && compare(item, selected as T);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onItemSelected(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brandColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _brandColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? _brandColor : const Color(0xFF334155),
                                      ),
                                    ),
                                    if (hasSubtitle) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle.trim(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: _brandColor, size: 20),
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
  }

  Future<void> _showPortfolioTypePicker() async {
    await _showMobileOptionPicker<String>(
      title: selectedType == 'Konut' ? 'Konut Tipi Seçin' : 'Ticari Tip Seçin',
      items: portfolioTypeList,
      itemLabel: (v) => v,
      selected: selectedPortfolioType,
      searchable: true,
      onSelected: (value) => _onPortfolioTypeChanged(value),
    );
  }

  Future<void> _showListingTypePicker() async {
    if (_categoryListingTypes == null || _categoryListingTypes!.isEmpty) return;
    await _showMobileOptionPicker<CategoryListingType>(
      title: 'İlan Tipi Seçin',
      items: _categoryListingTypes!,
      itemLabel: (v) => v.label,
      selected: _selectedListingType,
      isSameItem: (a, b) => a.id == b.id,
      onSelected: (newValue) {
        setState(() {
          _selectedListingType = newValue;
          _listingPropertyValues.clear();
          for (var controller in _listingPropertyControllers.values) {
            controller.dispose();
          }
          _listingPropertyControllers.clear();
          _formData.categoryId = newValue.id;
          _formData.listingType = newValue.listingType;
          final apiCode = portfolioTypeMapping[selectedPortfolioType];
          if (apiCode != null) {
            _loadListingProperties(apiCode, newValue.listingType);
          }
        });
      },
    );
  }

  Future<void> _showCurrencyPicker() async {
    const currencies = ['TL', 'USD', 'EUR'];
    await _showMobileOptionPicker<String>(
      title: 'Para Birimi Seçin',
      items: currencies,
      itemLabel: (v) => v,
      selected: _selectedCurrency,
      onSelected: (value) => setState(() => _selectedCurrency = value),
    );
  }

  Widget _buildStepProgressBar(List<String> titles) {
    final progress = titles.isEmpty
        ? 0.0
        : (_currentStep + 1) / titles.length;
    final currentTitle = titles[_currentStep.clamp(0, titles.length - 1)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Adım ${_currentStep + 1} / ${titles.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _brandColor,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  currentTitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFEEF1F6),
              valueColor: const AlwaysStoppedAnimation<Color>(_brandColor),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(titles.length, (index) {
                final isCompleted = index < _currentStep;
                final isActive = index == _currentStep;
                final isReachable = index <= _maxReachedStep;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isReachable && index != _currentStep
                          ? () => _goToStep(index)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: isActive ? 38 : 34,
                        height: isActive ? 38 : 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isCompleted || isActive
                              ? LinearGradient(
                                  colors: [
                                    _brandColor,
                                    _brandColor.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isCompleted || isActive ? null : Colors.white,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? _brandColor
                                : Colors.grey.shade300,
                            width: isActive ? 0 : 1.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _brandColor.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: isActive ? 14 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (index < titles.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 16,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: index < _currentStep
                              ? _brandColor
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNavigation(int totalSteps) {
    final isLastStep = _currentStep >= totalSteps - 1;
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _goToPreviousStep,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _brandColor.withValues(alpha: 0.35)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 18, color: _brandColor),
                          SizedBox(width: 6),
                          Text(
                            'Geri',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _brandColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: isLastStep ? Colors.green : _brandColor,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              shadowColor: (isLastStep ? Colors.green : _brandColor).withValues(alpha: 0.35),
              child: InkWell(
                onTap: _isLoading ? null : (isLastStep ? _savePortfolio : _goToNextStep),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: isLastStep
                          ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                          : [_brandColor, const Color(0xFFD42820)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLastStep ? Colors.green : _brandColor).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading && isLastStep)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else ...[
                          Icon(
                            isLastStep
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isLastStep
                                ? 'Kaydet'
                                : 'İleri',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(List<String> titles) {
    final title = titles[_currentStep.clamp(0, titles.length - 1)];
    switch (title) {
      case 'Portföy Tipi':
        return _buildPortfoyTipiStepContent();
      case 'Yetki Belgesi':
        return _buildYetkiBelgesiStepContent();
      case 'Portföy Görselleri':
        return _buildGorsellerStepContent();
      case 'Başlık ve Açıklama':
        return _buildBaslikAciklamaStepContent();
      case 'Adres':
        return _buildAdresStepContent();
      case 'Özellikler':
        return _buildOzelliklerStepContent();
      case 'Cephe':
        return _buildCheckboxStepContent(
            'Cephe', _buildDynamicCheckboxGroup('cephe', _formData.cephe));
      case 'İç Özellikler':
        return _buildCheckboxStepContent(
            'İç Özellikler',
            _buildDynamicCheckboxGroup(
                'ic-ozellikler', _formData.icOzellikler));
      case 'Dış Özellikler':
        return _buildCheckboxStepContent(
            'Dış Özellikler',
            _buildDynamicCheckboxGroup(
                'dis-ozellikler', _formData.disOzellikler));
      case 'Muhit':
        return _buildCheckboxStepContent(
            'Muhit', _buildDynamicCheckboxGroup('muhit', _formData.muhit));
      case 'Ulaşım':
        return _buildCheckboxStepContent(
            'Ulaşım', _buildDynamicCheckboxGroup('ulasim', _formData.ulasim));
      case 'Manzara':
        return _buildCheckboxStepContent(
            'Manzara',
            _buildDynamicCheckboxGroup('manzara', _formData.manzara));
      case 'Konut Tipi':
        return _buildCheckboxStepContent(
            'Konut Tipi',
            _buildDynamicCheckboxGroup('konut-tipi', _formData.konutTipi));
      case 'Engelliye ve Yaşlıya Uygun':
        return _buildCheckboxStepContent(
            'Engelliye ve Yaşlıya Uygun',
            _buildDynamicCheckboxGroup('engelliye-ve-yasliya-uygun',
                _formData.engelliyeVeYasliyaUygun));
      default:
        return _buildTicariCheckboxStepContent(title);
    }
  }

  Widget _buildStepTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandColor, _brandColor.withValues(alpha: 0.4)],
            ),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxStepContent(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(title, subtitle: 'İstediğiniz özellikleri seçin (opsiyonel)'),
        const SizedBox(height: 20),
        content,
      ],
    );
  }

  Widget _buildTicariCheckboxStepContent(String title) {
    if (_propertyAttributes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: _brandColor),
        ),
      );
    }
    for (final property in _propertyAttributes!.properties) {
      if (property.control == 'checkbox' &&
          property.propertyCode != 'realEstateProperties' &&
          _formatPropertyLabel(property.propertyCode) == title) {
        final selectedList = _getOrCreateCheckboxList(property.propertyCode);
        return _buildCheckboxStepContent(
          title,
          _buildApiCheckboxGroup(property, selectedList),
        );
      }
    }
    return const SizedBox.shrink();
  }
  Widget _buildPortfoyTipiStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Portföy Tipi',
          subtitle: 'Emlak kategorisini ve alt tipini seçin',
        ),
        const SizedBox(height: 20),
        _buildZeOnlineToggle(),
        const SizedBox(height: 20),
        _buildPropertyOwnerSection(),
        _buildFieldLabel('Kategori'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF1F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(child: _buildTypeOption("Konut")),
              Expanded(child: _buildTypeOption("Ticari")),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildMobilePickerTile(
          label: selectedType == 'Konut' ? 'Konut Tipi' : 'Ticari Tip',
          value: selectedPortfolioType,
          hint: selectedType == 'Konut' ? 'Konut tipi seçiniz' : 'Ticari tip seçiniz',
          onTap: _showPortfolioTypePicker,
          leadingIcon: Icons.home_work_outlined,
        ),
        if (!isArsaSelected &&
            _categoryListingTypes != null &&
            _categoryListingTypes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildMobilePickerTile(
            label: 'İlan Tipi',
            value: _selectedListingType?.label,
            hint: 'İlan tipi seçiniz',
            onTap: _showListingTypePicker,
            leadingIcon: Icons.sell_outlined,
          ),
        ],
        if (_categoryListingTypes != null && _categoryListingTypes!.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'İlan tipi bulunamadı',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_categoryListingTypes == null && selectedPortfolioType.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _brandColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'İlan tipleri yükleniyor...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
        _buildListingPropertiesForm(),
      ],
    );
  }

  Widget _buildYetkiBelgesiStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Yetki Belgesi',
          subtitle: 'Portföy yetki belgenizi yükleyin (opsiyonel)',
        ),
        const SizedBox(height: 20),
        _buildAuthorizationFilePicker(),
      ],
    );
  }

  Widget _buildAuthorizationFilePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPickingFile ? null : _pickAuthorizationFile,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedAuthorizationFile != null
                  ? const Color(0xFFE53935).withOpacity(0.3)
                  : Colors.grey[300]!,
              width: _selectedAuthorizationFile != null ? 2 : 1.5,
            ),
            boxShadow: _selectedAuthorizationFile != null
                ? [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: _isPickingFile
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Dosya yükleniyor...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : _selectedAuthorizationFile == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.folder_outlined,
                              color: Color(0xFFE53935),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Dosya seçiniz",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getFileIcon(_selectedAuthorizationFile!.name),
                              color: const Color(0xFFE53935),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedAuthorizationFile!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getFileFormat(_selectedAuthorizationFile!.name),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(_selectedAuthorizationFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _removeAuthorizationFile,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
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

  Widget _buildGorsellerStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Portföy Görselleri',
          subtitle: 'Kapak fotoğrafı dahil en az 1 görsel ekleyin',
        ),
        const SizedBox(height: 20),
        _buildImageUploadSection(),
      ],
    );
  }

  Widget _buildBaslikAciklamaStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Başlık ve Açıklama',
          subtitle: 'Portföyünüzü öne çıkaracak bilgileri girin',
        ),
        const SizedBox(height: 20),
        _buildTitleDescriptionPriceSection(),
      ],
    );
  }

  Widget _buildAdresStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Adres',
          subtitle: 'Konum bilgilerini seçin ve haritada işaretleyin',
        ),
        const SizedBox(height: 20),
        _buildMobilePickerTile(
          label: 'İl',
          value: _selectedProvince?.name,
          hint: _provinces == null
              ? 'İller yükleniyor...'
              : (_provinces!.isEmpty ? 'İller yüklenemedi' : 'İl seçiniz'),
          onTap: (_provinces != null && _provinces!.isNotEmpty) ? _showProvincePicker : null,
          enabled: _provinces != null && _provinces!.isNotEmpty,
          leadingIcon: Icons.location_city_outlined,
        ),
        const SizedBox(height: 16),
        _buildMobilePickerTile(
          label: 'İlçe',
          value: _selectedDistrict?.name,
          hint: _selectedProvince == null
              ? 'Önce il seçiniz'
              : (_districts == null
                  ? 'İlçeler yükleniyor...'
                  : (_districts!.isEmpty ? 'İlçe bulunamadı' : 'İlçe seçiniz')),
          onTap: (_selectedProvince != null && _districts != null && _districts!.isNotEmpty)
              ? _showDistrictPicker
              : null,
          enabled: _selectedProvince != null && _districts != null && _districts!.isNotEmpty,
          leadingIcon: Icons.map_outlined,
        ),
        const SizedBox(height: 16),
        _buildMobilePickerTile(
          label: 'Mahalle',
          value: _selectedNeighborhood?.name,
          hint: _selectedDistrict == null
              ? 'Önce ilçe seçiniz'
              : (_neighborhoods == null
                  ? 'Mahalleler yükleniyor...'
                  : (_neighborhoods!.isEmpty ? 'Mahalle bulunamadı' : 'Mahalle seçiniz')),
          onTap: (_selectedDistrict != null && _neighborhoods != null && _neighborhoods!.isNotEmpty)
              ? _showNeighborhoodPicker
              : null,
          enabled: _selectedDistrict != null && _neighborhoods != null && _neighborhoods!.isNotEmpty,
          leadingIcon: Icons.place_outlined,
        ),
        const SizedBox(height: 20),
        _buildMapWidget(),
      ],
    );
  }

  Widget _buildOzelliklerStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle(
          'Özellikler',
          subtitle: 'Portföyün teknik ve fiziksel özelliklerini doldurun',
        ),
        const SizedBox(height: 20),
        _buildRealEstatePropertiesForm(),
      ],
    );
  }
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern büyük medya yükleme alanı
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading
                ? null
                : (_selectedImages.length < 35
                    ? _pickMultipleImagesFromGallery
                    : null),
            borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
              height: 300,
        decoration: BoxDecoration(
                color: _selectedImages.length < 35 &&
                        !_isLoading
                    ? Colors.grey[50]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
            border: Border.all(
                  color: _selectedImages.length < 35 &&
                          !_isLoading
                      ? Colors.grey[300]!
                      : Colors.grey[200]!,
                  width: 2,
              style: BorderStyle.solid,
        ),
                boxShadow: _selectedImages.length <
                            35 &&
                        !_isLoading
                    ? [
                        BoxShadow(
                          color: Colors.grey
                              .withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: _isLoading 
            ? const Center(
        child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<
                                        Color>(
                                    Color(0xFFE53935)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Fotoğraf yükleniyor...',
                      style: TextStyle(
                              color: Color.fromRGBO(
                                  238, 46, 36, 1),
                        fontSize: 14,
                              fontWeight:
                                  FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _selectedImages.isEmpty
              ? Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
                              size: 64,
              color: Colors.grey[400],
            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 24,
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                              ),
                              child: const Text(
              "Medya Yükleyin",
              style: TextStyle(
                                  color: Colors.black87,
                        fontSize: 16,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                    ),
                  ],
                )
                      : Stack(
                  children: [
                            // İlk fotoğrafı göster
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                      8),
                              child: Image.file(
                                _selectedImages[0],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context,
                                    error, stackTrace) {
                                  return Container(
                                    color: Colors
                                        .grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error,
                                        color:
                                            Colors.red,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Kapak fotoğrafı badge
                              Positioned(
                              top: 12,
                              left: 12,
                                child: Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                      0xFFE53935),
                                  borderRadius:
                                      BorderRadius
                                          .circular(4),
                                ),
                                child: const Text(
                                  'Kapak Fotoğrafı',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    fontWeight:
                                        FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                                    ),
                                  ),
                                ),
        const SizedBox(height: 24),

        // Kurallar listesi
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, height: 1.6),
            children: [
              TextSpan(
                text:
                    "• JPEG veya PNG formatında en fazla ",
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: "50mb",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    " büyüklüğünde görsel dosyalarınızı yükleyiniz.",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, height: 1.6),
                                children: [
              TextSpan(
                text: "• İşaretlediğiniz görsel, ",
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: "Portföy kapak fotoğrafı",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: " olarak görünecektir.",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, height: 1.6),
            children: [
              TextSpan(
                text: "• Resimleri ",
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: "sürükle bırak",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    " yaparak sıralamasını değiştirebilirsiniz.",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, height: 1.6),
            children: [
              TextSpan(
                text: "• En fazla ",
                style: TextStyle(color: Colors.black87),
              ),
              TextSpan(
                text: "35 fotoğraf",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: " yükleyebilirsiniz",
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Modern fotoğraf yükleme butonları
        Row(
        children: [
          Expanded(
              child: Material(
                color: _isLoading
                    ? Colors.grey[300]
                    : const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : _pickImageFromCamera,
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: _isLoading
                              ? Colors.grey[600]
                              : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fotoğraf Çek',
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.grey[600]
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Material(
                color: _isLoading
                    ? Colors.grey[300]
                    : Colors.blue,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : _pickMultipleImagesFromGallery,
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: _isLoading
                              ? Colors.grey[600]
                              : Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Galeriden Seç',
                          style: TextStyle(
                            color: _isLoading
                                ? Colors.grey[600]
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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

        // Seçilen fotoğraflar listesi
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 24),
        Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "Yüklenen Fotoğraflar (${_selectedImages.length}/35)",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(238, 46, 36, 1),
              ),
            ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            // İkon
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(
                                        0xFFE53935)
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons
                                    .delete_sweep_outlined,
                                color:
                                    Color(0xFFE53935),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Başlık
                            const Text(
                              'Tüm Fotoğrafları Sil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    Color(0xFFE53935),
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Mesaj
                            Text(
                              'Tüm fotoğrafları silmek istediğinizden emin misiniz? (${_selectedImages.length} fotoğraf)',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Butonlar
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(
                                                context)
                                            .pop(),
                                    style:
                                        OutlinedButton
                                            .styleFrom(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical:
                                                  14),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    12),
                                        side:
                                            const BorderSide(
                                          color: Colors
                                              .grey,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'İptal',
                                      style: TextStyle(
                                        color: Colors
                                            .black87,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(
                                              context)
                                          .pop();
                                      if (mounted) {
                  setState(() {
                                          _selectedImages
                                              .clear();
                                        });
                                        _showSuccessMessage(
                                            'Tüm fotoğraflar temizlendi');
                                      }
                                    },
                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      backgroundColor:
                                          const Color(
                                              0xFFE53935),
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical:
                                                  14),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Tümünü Sil',
                                      style: TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Tümünü Temizle',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
          const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                  padding:
                      const EdgeInsets.only(right: 8),
                child: Draggable<int>(
                  data: index,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(
                                  0xFFE53935),
                              width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.3),
                            blurRadius: 8,
                              offset:
                                  const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey[300]!),
                      color: Colors.grey[200],
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      color: Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  child: DragTarget<int>(
                    onAccept: (draggedIndex) {
                      if (draggedIndex != index) {
                        setState(() {
                            final File draggedImage =
                                _selectedImages
                                    .removeAt(
                                        draggedIndex);
                            _selectedImages.insert(
                                index, draggedImage);
                          });
                          _showSuccessMessage(
                              'Fotoğraf sırası değiştirildi');
                        }
                      },
                      builder: (context, candidateData,
                          rejectedData) {
                        final bool isTarget =
                            candidateData.isNotEmpty;
                        return GestureDetector(
                          onTap: () =>
                              _showImagePreview(index),
                            onLongPress: () {
                            _showImageReorderDialog(
                                index);
                            },
                          child: Stack(
                            children: [
                              Container(
                              width: 80,
                              height: 80,
                                decoration:
                                    BoxDecoration(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                border: Border.all(
                                  color: isTarget 
                                    ? Colors.green
                                    : index == 0 
                                            ? const Color(
                                                0xFFE53935)
                                            : Colors.grey[
                                                300]!,
                                    width: isTarget
                                        ? 3
                                        : (index == 0
                                            ? 3
                                            : 1),
                                  ),
                                  color: isTarget
                                      ? Colors.green
                                          .withOpacity(
                                              0.1)
                                      : null,
                              ),
                              child: ClipRRect(
                                  borderRadius:
                                      BorderRadius
                                          .circular(8),
                                child: Image.file(
                                    _selectedImages[
                                        index],
                                  fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error,
                                            stackTrace) {
                                    return Container(
                                        color: Colors
                                            .grey[300],
                                        child:
                                            const Icon(
                                        Icons.error,
                                          color: Colors
                                              .red,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (index == 0)
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            horizontal:
                                                6,
                                            vertical:
                                                2),
                                    decoration:
                                        BoxDecoration(
                                      color: const Color(
                                          0xFFE53935),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                                  4),
                                ),
                                child: const Text(
                                  'Ana',
                                  style: TextStyle(
                                        color: Colors
                                            .white,
                                    fontSize: 10,
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                                  onTap: () =>
                                      _removeImage(
                                          index),
                              child: Container(
                                    padding:
                                        const EdgeInsets
                                            .all(4),
                                    decoration:
                                        const BoxDecoration(
                                  color: Colors.red,
                                      shape: BoxShape
                                          .circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                      color:
                                          Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                            ],
                          ),
                      );
                    },
                  ),
                ),
              );
            },
                ),
              ),
            ],
      ],
    );
  }
  Widget _buildTitleDescriptionPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portföy Başlığı
        Row(
          children: [
            const Text(
              "Portföy Başlığı",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.grey[300]!),
        ),
        child: TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromRGBO(238, 46, 36, 1),
                width: 2,
              ),
            ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: Colors.grey[300]!),
              ),
            border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
          ),
        ),
        ),
        const SizedBox(height: 24),

        // Portföy Açıklaması
        Row(
          children: [
            const Text(
              "Portföy Açıklaması",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: Colors.grey[300]!),
        ),
        child: TextFormField(
          controller: _descriptionController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 5,
          maxLines: 14,
          textCapitalization:
              TextCapitalization.sentences,
          decoration: InputDecoration(
            alignLabelWithHint: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color.fromRGBO(238, 46, 36, 1),
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            hintText:
                'Portföy açıklamanızı buraya yazın…',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.4,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        ),
        const SizedBox(height: 16),
        // Para Birimi ve Fiyat
        Row(
          children: [
            Expanded(
              child: _buildMobilePickerTile(
                label: 'Para Birimi',
                value: _selectedCurrency,
                hint: 'Para birimi seçin',
                onTap: _showCurrencyPicker,
                leadingIcon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Fiyat'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFBFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _brandColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        hintText: 'Fiyat',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type) {
    bool isSelected = selectedType == type;
    return InkWell(
      onTap: () async {
        if (selectedType == type) return; // Already selected

          setState(() {
            selectedType = type;
          // Reset to first item of new type
          selectedPortfolioType =
              type == 'Konut' ? 'Daire' : 'Apartman Dairesi';
          showDaireFeatures = true;

          // Reset API data
          _selectedListingType = null;
          _categoryListingTypes = null;
          _listingProperties = null;
          _propertyAttributes = null;
          _isLoadingData = true; // Show loading indicator

          // Clear listing property values and controllers
          _listingPropertyValues.clear();
          for (var controller in _listingPropertyControllers.values) {
            controller.dispose();
          }
          _listingPropertyControllers.clear();
        });

        // Load data for new type
        final apiCode = portfolioTypeMapping[selectedPortfolioType];
        if (apiCode != null) {
          try {
            await Future.wait([
              _loadPropertyAttributes(apiCode),
              _loadCategoryListingTypes(apiCode),
            ]);
          } finally {
            if (mounted) {
              setState(() {
                _isLoadingData = false; // Hide loading indicator
              });
            }
          }
        }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
          color:
              isSelected ? const Color.fromRGBO(238, 46, 36, 1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : const Color.fromRGBO(238, 46, 36, 1),
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Property ExpansionTile with red title
  Widget _buildPropertyExpansionTile({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color.fromRGBO(238, 46, 36, 1),
          ),
        ),
        trailing: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey[600],
        ),
        collapsedBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        children: children,
      ),
    );
  }

  Widget _buildCheckboxItem(
      String label, String code, List<String> selectedList) {
    final isSelected = selectedList.contains(code);
    return InkWell(
      onTap: () {
                setState(() {
          if (isSelected) {
                    selectedList.remove(code);
          } else {
            selectedList.add(code);
                  }
                });
              },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFFE53935) : Colors.grey[400]!,
                  width: 1.5,
                ),
                color:
                    isSelected ? const Color(0xFFE53935) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.black87 : Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Build all dynamic checkbox groups from API (for Ticari categories)
  List<Widget> _buildDynamicCheckboxGroups() {
    if (_propertyAttributes == null) return [];

    final List<Widget> widgets = [];

    // Find all checkbox groups in the API response (excluding realEstateProperties group)
    for (final property in _propertyAttributes!.properties) {
      if (property.control == 'checkbox' &&
          property.propertyCode != 'realEstateProperties') {
        // Get or create a list to store selected values for this group
        final selectedList = _getOrCreateCheckboxList(property.propertyCode);

        widgets.add(
          _buildPropertyExpansionTile(
            title: _formatPropertyLabel(property.propertyCode),
            children: [_buildApiCheckboxGroup(property, selectedList)],
          ),
        );
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  // Get or create checkbox list for dynamic groups
  List<String> _getOrCreateCheckboxList(String propertyCode) {
    switch (propertyCode) {
      case 'kullanim-amaci':
        return _formData.kullanimAmaci;
      case 'genel-ozellikler':
        return _formData.genelOzellikler;
      case 'yakinlik':
        return _formData.yakinlik;
      case 'alt-yapi':
        return _formData.altYapi;
      case 'cephe':
        return _formData.cephe;
      case 'manzara':
        return _formData.manzara;
      case 'detay-bilgisi':
        return _formData.detayBilgisi;
      case 'maden-tipi':
        return _formData.madenTipi;
      case 'ozellikler':
        return _formData.ozellikler;
      case 'ek-hizmet':
        return _formData.ekHizmet;
      case 'bina-ozellikleri':
        return _formData.binaOzellikleri;
      case 'altyapi':
        return _formData.altyapi;
      case 'ofis-ozellikleri':
        return _formData.ofisOzellikleri;
      case 'hizmetler':
        return _formData.hizmetler;
      case 'dis-cephe-ozellikleri':
        return _formData.disCepheOzellikleri;
      case 'konut-ozellikleri':
        return _formData.konutOzellikleri;
      case 'cevre-ozellikleri':
        return _formData.cevreOzellikleri;
      case 'ic-dekorasyon':
        return _formData.icDekorasyon;
      case 'ic-ozellikler':
        return _formData.icOzellikler;
      case 'dis-ozellikler':
        return _formData.disOzellikler;
      case 'muhit':
        return _formData.muhit;
      case 'ulasim':
        return _formData.ulasim;
      case 'konut-tipi':
        return _formData.konutTipi;
      case 'engelliye-ve-yasliya-uygun':
        return _formData.engelliyeVeYasliyaUygun;
      default:
        // For unknown groups, return an empty list (values won't be saved)
        return [];
    }
  }

  // Build checkbox group directly from API property
  Widget _buildApiCheckboxGroup(
      PropertyAttribute property, List<String> selectedList) {
    if (property.values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Seçenek bulunamadı')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: property.values.map((value) {
          final code = value.code ?? '';
          final isSelected = selectedList.contains(code);

          return FilterChip(
            label: Text(
              _formatSelectOptionLabel(code),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  if (!selectedList.contains(code)) {
                    selectedList.add(code);
                  }
      } else {
                  selectedList.remove(code);
                }
              });
            },
            selectedColor: const Color(0xFFE53935),
            checkmarkColor: Colors.white,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color(0xFFE53935) : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Dynamic checkbox group builder - 4 sütunlu grid (web tasarımına uygun)
  Widget _buildDynamicCheckboxGroup(
      String propertyCode, List<String> selectedList) {
    final property = _getPropertyByCode(propertyCode);
    if (property == null || property.values.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                ),
              ),
              SizedBox(width: 8),
              Text('Özellikler yükleniyor...',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final values = property.values.where((v) => v.code != null).toList();

    // Sort values alphabetically by label
    values.sort((a, b) =>
        _formatCheckboxLabel(a.code!).compareTo(_formatCheckboxLabel(b.code!)));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive: 4 sütun geniş ekranda, 2 sütun dar ekranda
          final isWideScreen = constraints.maxWidth > 600;
          final columnCount = isWideScreen ? 4 : 2;

          // Group values into rows
          final List<List<PropertyValue>> rows = [];
          for (int i = 0; i < values.length; i += columnCount) {
            final end = (i + columnCount > values.length)
                ? values.length
                : i + columnCount;
            rows.add(values.sublist(i, end));
          }

          return Column(
            children: rows.map((rowValues) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    for (int i = 0; i < columnCount; i++)
          Expanded(
                        child: i < rowValues.length
                            ? _buildCheckboxItem(
                                _formatCheckboxLabel(rowValues[i].code!),
                                rowValues[i].code!,
                        selectedList,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // Format checkbox label (convert code to readable text)
  String _formatCheckboxLabel(String code) {
    // Remove property prefix and format
    String label = code
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return label;
  }

  // Build all realEstateProperties fields
  Widget _buildRealEstatePropertiesForm() {
    // Arsa seçildiğinde özellikler gösterilmez
    if (isArsaSelected) {
      return const SizedBox.shrink();
    }
    
    if (_propertyAttributes == null || _isLoadingData) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        ),
      );
    }

    // Find realEstateProperties group
    final realEstateGroup = _propertyAttributes!.properties.firstWhere(
      (attr) => attr.propertyCode == 'realEstateProperties',
      orElse: () => PropertyAttribute(
        propertyCode: '',
        control: '',
        values: [],
      ),
    );

    if (realEstateGroup.properties == null ||
        realEstateGroup.properties!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Özellik bulunamadı'),
      );
    }

    final properties = realEstateGroup.properties!;
    final List<Widget> widgets = [];

    for (int i = 0; i < properties.length; i++) {
      final property = properties[i];
      
      // For select fields, check if we should display them in a row
      if (property.control == 'select' &&
          i + 1 < properties.length &&
          properties[i + 1].control == 'select') {
        // Display two selects in a row
        widgets.add(
          Row(
            children: [
              Expanded(child: _buildDynamicPropertyWidget(property)),
              const SizedBox(width: 16),
              Expanded(child: _buildDynamicPropertyWidget(properties[i + 1])),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 16));
        i++; // Skip the next property as we've already displayed it
      } else {
        widgets.add(_buildDynamicPropertyWidget(property));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widgets,
      ),
    );
  }

  // Build listing properties form (based on Kiralık/Satılık selection)
  Widget _buildListingPropertiesForm() {
    // Arsa seçildiğinde özellikler gösterilmez
    if (isArsaSelected) {
      return const SizedBox.shrink();
    }
    
    // Don't show anything if no listing type is selected
    if (_selectedListingType == null) {
      return const SizedBox.shrink();
    }

    // Show loading indicator while fetching
    if (_isLoadingListingProperties) {
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        ),
      );
    }

    // No listing properties loaded yet or empty
    if (_listingProperties == null) {
      return const SizedBox.shrink();
    }

    // Find realEstateProperties group in listing properties
    final realEstateGroup = _listingProperties!.properties.firstWhere(
      (attr) => attr.propertyCode == 'realEstateProperties',
      orElse: () => PropertyAttribute(
        propertyCode: '',
        control: '',
        values: [],
      ),
    );

    if (realEstateGroup.properties == null ||
        realEstateGroup.properties!.isEmpty) {
      return const SizedBox.shrink();
    }

    final properties = realEstateGroup.properties!;
    final List<Widget> widgets = [];

    // Add a title for listing type specific properties
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedListingType!.label} Özellikleri',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );

    for (int i = 0; i < properties.length; i++) {
      final property = properties[i];

      // For select fields, check if we should display them in a row
      if (property.control == 'select' &&
          i + 1 < properties.length &&
          properties[i + 1].control == 'select') {
        widgets.add(
          Row(
            children: [
              Expanded(child: _buildDynamicListingPropertyWidget(property)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildDynamicListingPropertyWidget(properties[i + 1])),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 16));
        i++; // Skip the next property as we've already displayed it
      } else {
        widgets.add(_buildDynamicListingPropertyWidget(property));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  // Build dynamic listing property widget
  Widget _buildDynamicListingPropertyWidget(PropertyAttribute property) {
    if (property.propertyCode == 'gayrimenkul-sahibi') {
      return const SizedBox.shrink();
    }
    switch (property.control) {
      case 'number':
        return _buildListingNumberField(property);
      case 'select':
        return _buildListingSelectField(property);
      case 'textbox':
        return _buildListingTextField(property);
      default:
        return const SizedBox.shrink();
    }
  }

  // Listing number field with dynamic controller
  Widget _buildListingNumberField(PropertyAttribute property) {
    String label = _formatPropertyLabel(property.propertyCode);

    // Get or create controller for this property
    if (!_listingPropertyControllers.containsKey(property.propertyCode)) {
      _listingPropertyControllers[property.propertyCode] =
          TextEditingController();
    }
    final controller = _listingPropertyControllers[property.propertyCode]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              hintText: _getHintTextForProperty(property.propertyCode),
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  // Get hint text for listing properties
  String _getHintTextForProperty(String propertyCode) {
    switch (propertyCode) {
      case 'depozito-tl':
        return 'Depozito tutarını TL olarak girin';
      default:
        return 'Değer girin';
    }
  }

  // Listing select field
  Widget _buildListingSelectField(PropertyAttribute property) {
    String label = _formatPropertyLabel(property.propertyCode);

    // Get the current value for this property
    final currentValue =
        _listingPropertyValues[property.propertyCode] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items: property.values.map((value) {
              return DropdownMenuItem<String>(
                value: value.code,
                child: Text(
                  _formatSelectOptionLabel(value.code ?? ''),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _listingPropertyValues[property.propertyCode] = value;
              });
            },
            hint: Text(
              'Seçiniz',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // Listing text field
  Widget _buildListingTextField(PropertyAttribute property) {
    String label = _formatPropertyLabel(property.propertyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              hintText: 'Metin girin',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              // Store in form data
            },
          ),
        ),
      ],
    );
  }

  // Build dynamic property widget based on control type
  Widget _buildDynamicPropertyWidget(PropertyAttribute property) {
    if (property.propertyCode == 'gayrimenkul-sahibi') {
      return const SizedBox.shrink();
    }
    switch (property.control) {
      case 'number':
        return _buildNumberField(property);
      case 'select':
        return _buildSelectField(property);
      case 'textbox':
        return _buildTextField(property);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNumberField(PropertyAttribute property) {
    TextEditingController? controller;
    String? hintText;
    
    // Map property codes to controllers and hints
    switch (property.propertyCode) {
      // Konut properties
      case 'm2-brut':
        controller = _m2BrutController;
        break;
      case 'm2-net':
        controller = _m2NetController;
        break;
      case 'acik-alan-m2':
        controller = _acikAlanM2Controller;
        break;
      case 'kapali-alan-m2':
        controller = _kapaliAlanM2Controller;
        break;
      case 'arazi-m2':
        controller = _araziM2Controller;
        break;
      case 'salon-sayisi':
        controller = _salonSayisiController;
        break;
      case 'bina-adedi':
        controller = _binaAdediController;
        break;
      case 'masa-sayisi':
        controller = _masaSayisiController;
        break;
      case 'derslik-sayisi':
        controller = _derslikSayisiController;
        break;
      case 'pompa-sayisi':
        controller = _pompaSayisiController;
        break;
      case 'arac-kapasitesi':
        controller = _aracKapasitesiController;
        break;
      case 'kisi-kapasitesi':
        controller = _kisiKapasitesiController;
        break;
      case 'aidat-tl':
        controller = _aidatController;
        hintText = 'Aidat bilinmiyor ise 0 giriniz.';
        break;

      // Ticari properties
      case 'm2':
        controller = _m2Controller;
        break;
      case 'giris-yuksekligi-m':
        controller = _girisYuksekligiController;
        break;
      case 'bolum-oda-sayisi':
        controller = _bolumOdaSayisiController;
        break;
      case 'banyo-sayisi':
        controller = _banyoSayisiNumberController;
        break;
      case 'bulundugu-kat':
        controller = _bulunduguKatNumberController;
        break;
      case 'binanin-yasi':
        controller = _binaninYasiNumberController;
        break;
      case 'kat-sayisi':
        controller = _katSayisiNumberController;
        break;
    }

    if (controller == null) return const SizedBox.shrink();

    String label = _formatPropertyLabel(property.propertyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(238, 46, 36, 1),
              width: 2,
            ),
          ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
          border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
      ),
        ),
      ],
    );
  }

  Widget _buildTextField(PropertyAttribute property) {
    TextEditingController? controller;
    String? hintText;
    int? maxLength;
    
    if (property.propertyCode == 'tasinmaz-numarasi') {
      controller = _tasinmazController;
      hintText = 'Maksimum 10 karakterden oluşabilir.';
      maxLength = 10;
    }

    if (controller == null) return const SizedBox.shrink();

    String label = _formatPropertyLabel(property.propertyCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
            maxLength: maxLength,
        keyboardType: property.propertyCode == 'tasinmaz-numarasi'
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: property.propertyCode == 'tasinmaz-numarasi'
            ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color.fromRGBO(238, 46, 36, 1),
              width: 2,
            ),
          ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
          border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              counterText: '', // Hide counter text
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildSelectField(PropertyAttribute property) {
    String label = _formatPropertyLabel(property.propertyCode);
    
    // Get current value from formData
    String? selectedValue;
    switch (property.propertyCode) {
      case 'oda-sayisi':
        selectedValue = _formData.odaSayisi;
        break;
      case 'bina-yasi':
        selectedValue = _formData.binaYasi;
        break;
      case 'bulundugu-kat':
        selectedValue = _formData.bulunduguKat;
        break;
      case 'kat-sayisi':
        selectedValue = _formData.katSayisi;
        break;
      case 'isitma':
        selectedValue = _formData.isitma;
        break;
      case 'yapi-tipi':
        selectedValue = _formData.yapiTipi;
        break;
      case 'banyo-sayisi':
        selectedValue = _formData.banyoSayisi;
        break;
      case 'balkon':
        selectedValue = _formData.balkon;
        break;
      case 'asansor':
        selectedValue = _formData.asansor;
        break;
      case 'asansor-sayisi':
        selectedValue = _formData.asansorSayisi;
        break;
      case 'otopark':
        selectedValue = _formData.otopark;
        break;
      case 'esyali':
        selectedValue = _formData.esyali;
        break;
      case 'yapinin-durumu':
        selectedValue = _formData.yapininDurumu;
        break;
      case 'zemin-etudu':
        selectedValue = _formData.zeminEtudu;
        break;
      case 'alkol-ruhsati':
        selectedValue = _formData.alkolRuhsati;
        break;
      case 'ruhsat-durumu':
        selectedValue = _formData.ruhsatDurumu;
        break;
      case 'bina-tipi':
        selectedValue = _formData.binaTipi;
        break;
      case 'turu':
        selectedValue = _formData.turu;
        break;
      case 'kiralama-suresi':
        selectedValue = _formData.kiralamaSuresi;
        break;
      case 'sekreter':
        selectedValue = _formData.sekreter;
        break;
      case 'kiracili':
        selectedValue = _formData.kiracili;
        break;
      case 'tapu-durumu':
        selectedValue = _formData.tapuDurumu;
        break;
      case 'krediye-uygunluk':
        selectedValue = _formData.krediyeUygunluk;
        break;
      case 'tipi':
        selectedValue = _formData.tipi;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            dropdownColor: Colors.white,
            isExpanded: true,
            value: selectedValue,
                hint: Text(
                  'Seçiniz',
                  style: TextStyle(color: Colors.grey[400]),
                ),
            icon: const Icon(Icons.keyboard_arrow_down),
                items:
                    property.values.where((v) => v.code != null).map((value) {
              return DropdownMenuItem<String>(
                value: value.code!,
                    child: Text(
                      _formatPropertyLabel(value.code!),
                      style: const TextStyle(fontSize: 14),
                    ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue == null) return;
              setState(() {
                switch (property.propertyCode) {
                  case 'oda-sayisi':
                    _formData.odaSayisi = newValue;
                    break;
                  case 'bina-yasi':
                    _formData.binaYasi = newValue;
                    break;
                  case 'bulundugu-kat':
                    _formData.bulunduguKat = newValue;
                    break;
                  case 'kat-sayisi':
                    _formData.katSayisi = newValue;
                    break;
                  case 'isitma':
                    _formData.isitma = newValue;
                    break;
                      case 'yapi-tipi':
                        _formData.yapiTipi = newValue;
                        break;
                  case 'banyo-sayisi':
                    _formData.banyoSayisi = newValue;
                    break;
                  case 'balkon':
                    _formData.balkon = newValue;
                    break;
                  case 'asansor':
                    _formData.asansor = newValue;
                    break;
                      case 'asansor-sayisi':
                        _formData.asansorSayisi = newValue;
                        break;
                  case 'otopark':
                    _formData.otopark = newValue;
                    break;
                  case 'esyali':
                    _formData.esyali = newValue;
                    break;
                      case 'yapinin-durumu':
                        _formData.yapininDurumu = newValue;
                        break;
                      case 'zemin-etudu':
                        _formData.zeminEtudu = newValue;
                        break;
                      case 'alkol-ruhsati':
                        _formData.alkolRuhsati = newValue;
                        break;
                      case 'ruhsat-durumu':
                        _formData.ruhsatDurumu = newValue;
                        break;
                      case 'bina-tipi':
                        _formData.binaTipi = newValue;
                        break;
                      case 'turu':
                        _formData.turu = newValue;
                        break;
                      case 'kiralama-suresi':
                        _formData.kiralamaSuresi = newValue;
                        break;
                      case 'sekreter':
                        _formData.sekreter = newValue;
                        break;
                      case 'kiracili':
                        _formData.kiracili = newValue;
                        break;
                      case 'tapu-durumu':
                        _formData.tapuDurumu = newValue;
                        break;
                      case 'krediye-uygunluk':
                        _formData.krediyeUygunluk = newValue;
                        break;
                      case 'tipi':
                        _formData.tipi = newValue;
                        break;
                }
              });
            },
                padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
        ),
      ],
    );
  }

  String _formatPropertyLabel(String code) {
    // Convert property code to readable label
    final Map<String, String> labelMappings = {
      // Konut properties
      'm2-brut': 'm² (Brüt)',
      'm2-net': 'm² (Net)',
      'acik-alan-m2': 'Açık Alan (m²)',
      'kapali-alan-m2': 'Kapalı Alan (m²)',
      'arazi-m2': 'Arazı (m²)',
      'salon-sayisi': 'Salon Sayısı',
      'bina-adedi': 'Bina Adedi',
      'masa-sayisi': 'Masa Sayısı',
      'derslik-sayisi': 'Derslik Sayısı',
      'pompa-sayisi': 'Pompa Sayısı',
      'arac-kapasitesi': 'Araç Kapasitesi',
      'kisi-kapasitesi': 'Kişi Kapasitesi',
      'oda-sayisi': 'Oda Sayısı',
      'asansor-sayisi': 'Asansör Sayısı',
      'alkol-ruhsati': 'Alkol Ruhsatı',
      'ruhsat-durumu': 'Ruhsat Durumu',
      'bina-tipi': 'Bina Tipi',
      'turu': 'Türü',
      'kiralama-suresi': 'Kiralama Süresi',
      'sekreter': 'Sekreter',
      'kiracili': 'Kiracılı',
      'krediye-uygunluk': 'Krediye Uygunluk',
      'tapu-durumu': 'Tapu Durumu',
      'gayrimenkul-sahibi': 'Gayrimenkul Sahibi',
      'tipi': 'Tipi',
      'bina-yasi': 'Bina Yaşı',
      'bulundugu-kat': 'Bulunduğu Kat',
      'kat-sayisi': 'Kat Sayısı',
      'isitma': 'Isıtma',
      'yapi-tipi': 'Yapı Tipi',
      'banyo-sayisi': 'Banyo Sayısı',
      'balkon': 'Balkon',
      'asansor': 'Asansör',
      'otopark': 'Otopark',
      'esyali': 'Eşyalı',
      'aidat-tl': 'Aidat (TL)',
      'tasinmaz-numarasi': 'Taşınmaz Numarası',

      // New checkbox groups
      'dis-cephe-ozellikleri': 'Dış Cephe Özellikleri',
      'konut-ozellikleri': 'Konut Özellikleri',
      'cevre-ozellikleri': 'Çevre Özellikleri',
      'ic-dekorasyon': 'İç Dekorasyon',

      // Ticari properties
      'm2': 'm²',
      'bolum-oda-sayisi': 'Bölüm/Oda Sayısı',
      'oda-bolum-sayisi': 'Oda / Bölüm Sayısı',
      'giris-yuksekligi': 'Giriş Yüksekliği (m)',
      'giris-yuksekligi-m': 'Giriş Yüksekliği (m)',
      'binanin-yasi': 'Binanın Yaşı',
      'yapinin-durumu': 'Yapının Durumu',
      'zemin-etudu': 'Zemin Etüdü',
      'binadaki-kat-sayisi': 'Binadaki Kat Sayısı',

      // Ticari checkbox groups
      'kullanim-amaci': 'Kullanım Amacı',
      'genel-ozellikler': 'Genel Özellikler',
      'yakinlik': 'Yakınlık',
      'alt-yapi': 'Alt Yapı',
      'detay-bilgisi': 'Detay Bilgisi',
      'maden-tipi': 'Maden Tipi',
      'ozellikler': 'Özellikler',
      'ek-hizmet': 'Ek Hizmet',
      'bina-ozellikleri': 'Bina Özellikleri',
      'altyapi': 'Altyapı',
      'ofis-ozellikleri': 'Ofis Özellikleri',
      'hizmetler': 'Hizmetler',
      'cephe': 'Cephe',

      // Listing properties
      'depozito-tl': 'Depozito (TL)',
      'krediye-uygun': 'Krediye Uygun',
      
      // Value label mappings
      'oda-sayisi-studyo-10': 'Stüdyo (1+0)',
      'oda-sayisi-11': '1+1',
      'oda-sayisi-151': '1.5+1',
      'oda-sayisi-20': '2+0',
      'oda-sayisi-21': '2+1',
      'oda-sayisi-251': '2.5+1',
      'oda-sayisi-22': '2+2',
      'oda-sayisi-30': '3+0',
      'oda-sayisi-31': '3+1',
      'oda-sayisi-351': '3.5+1',
      'oda-sayisi-32': '3+2',
      'oda-sayisi-33': '3+3',
      'oda-sayisi-40': '4+0',
      'oda-sayisi-41': '4+1',
      'oda-sayisi-451': '4.5+1',
      'oda-sayisi-452': '4.5+2',
      'oda-sayisi-42': '4+2',
      'oda-sayisi-43': '4+3',
      'oda-sayisi-44': '4+4',
      'oda-sayisi-51': '5+1',
      'oda-sayisi-551': '5.5+1',
      'oda-sayisi-52': '5+2',
      'oda-sayisi-53': '5+3',
      'oda-sayisi-54': '5+4',
      'oda-sayisi-61': '6+1',
      'oda-sayisi-62': '6+2',
      'oda-sayisi-651': '6.5+1',
      'oda-sayisi-63': '6+3',
      'oda-sayisi-64': '6+4',
      'oda-sayisi-71': '7+1',
      'oda-sayisi-72': '7+2',
      'oda-sayisi-73': '7+3',
      'oda-sayisi-81': '8+1',
      'oda-sayisi-82': '8+2',
      'oda-sayisi-83': '8+3',
      'oda-sayisi-84': '8+4',
      'oda-sayisi-91': '9+1',
      'oda-sayisi-92': '9+2',
      'oda-sayisi-93': '9+3',
      'oda-sayisi-94': '9+4',
      'oda-sayisi-95': '9+5',
      'oda-sayisi-96': '9+6',
      'oda-sayisi-101': '10+1',
      'oda-sayisi-102': '10+2',
      'oda-sayisi-10-uzeri': '10+',
      'oda-sayisi-5-ve-uzeri': '5 ve Üzeri',
      'oda-sayisi-yok': 'Yok',
      
      'bina-yasi-0': '0 (Sıfır Bina)',
      'bina-yasi-1': '1',
      'bina-yasi-2': '2',
      'bina-yasi-3': '3',
      'bina-yasi-4': '4',
      'bina-yasi-5-10-arasi': '5-10 Arası',
      'bina-yasi-11-15-arasi': '11-15 Arası',
      'bina-yasi-16-20-arasi': '16-20 Arası',
      'bina-yasi-21-25-arasi': '21-25 Arası',
      'bina-yasi-26-30-arasi': '26-30 Arası',
      'bina-yasi-31-ve-uzeri': '31 ve Üzeri',
      'bina-yasi-30-uzeri': '30 ve Üzeri',
      'binanin-yasi-30-uzeri': '30 ve Üzeri',
      
      'balkon-var': 'Var',
      'balkon-yok': 'Yok',
      'asansor-var': 'Var',
      'asansor-yok': 'Yok',
      'asansor-sayisi-yok': 'Yok',
      'asansor-sayisi-1': '1',
      'asansor-sayisi-2': '2',
      'asansor-sayisi-3': '3',
      'asansor-sayisi-4': '4',
      'asansor-sayisi-5-ve-uzeri': '5 ve Üzeri',
      'esyali-evet': 'Evet',
      'esyali-hayir': 'Hayır',
      
      'otopark-acik-otopark': 'Açık Otopark',
      'otopark-kapali-otopark': 'Kapalı Otopark',
      'otopark-acik-kapali-otopark': 'Açık + Kapalı Otopark',
      'otopark-yok': 'Yok',
      
      'banyo-sayisi-yok': 'Yok',
      'banyo-sayisi-1': '1',
      'banyo-sayisi-2': '2',
      'banyo-sayisi-3': '3',
      'banyo-sayisi-4': '4',
      'banyo-sayisi-5': '5',
      'banyo-sayisi-6': '6',
      'banyo-sayisi-6-uzeri': '6+',
    };

    // Check direct mapping first
    if (labelMappings.containsKey(code)) {
      return labelMappings[code]!;
    }

    // For codes starting with specific patterns, do smart formatting
    if (code.startsWith('bulundugu-kat-')) {
      String kat = code.replaceFirst('bulundugu-kat-', '');
      if (kat == 'bodrum-kat') return 'Bodrum Kat';
      if (kat == 'bodrum-kati') return 'Bodrum Katı';
      if (kat == 'zemin-kat') return 'Zemin Kat';
      if (kat == 'bahce-kati') return 'Bahçe Katı';
      if (kat == 'giris-kati') return 'Giriş Katı';
      if (kat == 'yuksek-giris') return 'Yüksek Giriş';
      if (kat == 'mustakil') return 'Müstakil';
      if (kat == 'villa-tipi') return 'Villa Tipi';
      if (kat == 'cati-kati') return 'Çatı Katı';
      if (kat == 'alisveris-merkezinde') return 'Alışveriş Merkezinde';
      if (kat.startsWith('giris-alti-kot-')) {
        String kotNum = kat.replaceFirst('giris-alti-kot-', '');
        return 'Giriş Altı Kot $kotNum';
      }
      if (kat == '10-ve-uzeri') return '10 ve Üzeri';
      if (kat == '30-ve-uzeri') return '30 ve Üzeri';
      if (kat == '50-ve-uzeri') return '50 ve Üzeri';
      return kat; // Just the number
    }

    if (code.startsWith('kat-sayisi-')) {
      String kat = code.replaceFirst('kat-sayisi-', '');
      if (kat == '10-ve-uzeri') return '10 ve Üzeri';
      if (kat == '30-ve-uzeri') return '30 ve Üzeri';
      return kat;
    }

    if (code.startsWith('isitma-')) {
      String isitma = code.replaceFirst('isitma-', '');
      final isitmaMappings = {
        'yok': 'Yok',
        'soba': 'Soba',
        'dogalgaz-sobasi': 'Doğalgaz Sobası',
        'kat-kaloriferi': 'Kat Kaloriferi',
        'merkezi': 'Merkezi',
        'merkezi-pay-olcer': 'Merkezi (Pay Ölçer)',
        'kombi-dogalgaz': 'Kombi (Doğalgaz)',
        'kombi-elektrik': 'Kombi (Elektrik)',
        'kombi': 'Kombi',
        'dogalgaz-merkezi': 'Doğalgaz Merkezi',
        'merkezi-sistem': 'Merkezi Sistem',
        'fuel-oil-komur': 'Fuel Oil & Kömür',
        'yerden-isitma': 'Yerden Isıtma',
        'klima': 'Klima',
        'fancoil-unitesi': 'Fancoil Ünitesi',
        'gunes-enerjisi': 'Güneş Enerjisi',
        'elektrikli-radyator': 'Elektrikli Radyatör',
        'jeotermal': 'Jeotermal',
        'somine': 'Şömine',
        'vrv': 'VRV',
        'isi-pompasi': 'Isı Pompası',
      };
      return isitmaMappings[isitma] ?? isitma;
    }

    // Default: capitalize first letter of each word
    return code.split('-').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  // Format select option labels for listing properties (krediye-uygun, tapu-durumu, etc.)
  String _formatSelectOptionLabel(String code) {
    final Map<String, String> optionMappings = {
      // Krediye Uygun options
      'krediye-uygun-evet': 'Evet',
      'krediye-uygun-hayir': 'Hayır',

      // Tapu Durumu options
      'tapu-durumu-kat-mulkiyetli': 'Kat Mülkiyetli',
      'tapu-durumu-kat-irtifakli': 'Kat İrtifaklı',
      'tapu-durumu-hisseli-tapu': 'Hisseli Tapu',
      'tapu-durumu-mustakil-tapulu': 'Müstakil Tapulu',
      'tapu-durumu-arsa-tapulu': 'Arsa Tapulu',
      'tapu-durumu-kooperatif-hisseli-tapu': 'Kooperatif Hisseli Tapu',
      'tapu-durumu-yurt-disi-tapulu': 'Yurt Dışı Tapulu',
      'tapu-durumu-tapu-kaydi-yok': 'Tapu Kaydı Yok',
      'tapu-durumu-bilinmiyor': 'Bilinmiyor',

      // Gayrimenkul Sahibi options
      'tc-vatandasi': 'T.C. vatandaşı',
      'tc-vatandasi-degil': 'T.C. vatandaşı değil',
      'banka-vakif-dernek-sendika': 'Banka / Vakıf / Dernek / Sendika',
      'kamu-kurumu': 'Kamu Kurumu',

      // Yapının Durumu options (Konut & Ticari)
      'yapinin-durumu-sifir': 'Sıfır',
      'yapinin-durumu-ikinci-el': 'İkinci El',
      'yapinin-durumu-insa-halinde': 'İnşa Halinde',
      'yapinin-durumu-yapim-asamasinda': 'Yapım Aşamasında',
      'yapinin-durumu-tarihi-eser': 'Tarihi Eser',

      // Zemin Etüdü options
      'zemin-etudu-var': 'Var',
      'zemin-etudu-yok': 'Yok',

      // Yapı Tipi options
      'yapi-tipi-ahsap': 'Ahşap',
      'yapi-tipi-kutuk': 'Kütük',
      'yapi-tipi-betonarme': 'Betonarme',
      'yapi-tipi-celik': 'Çelik',
      'yapi-tipi-prefabrik': 'Prefabrik',
      'yapi-tipi-yari-kagir': 'Yarı Kâgir',
      'yapi-tipi-tam-kagir': 'Tam Kâgir',
      'yapi-tipi-tam-kagir-tas-ev': 'Tam Kâgir Taş Ev',
      'yapi-tipi-diger': 'Diğer',

      // Ticari - Asansör Sayısı options
      'asansor-sayisi-yok': 'Yok',
      'asansor-sayisi-1': '1',
      'asansor-sayisi-2': '2',
      'asansor-sayisi-3': '3',
      'asansor-sayisi-4': '4',
      'asansor-sayisi-5-ve-uzeri': '5 ve Üzeri',

      // Ticari - Binanın Yaşı options
      'binanin-yasi-0': '0 (Sıfır Bina)',
      'binanin-yasi-1': '1',
      'binanin-yasi-2': '2',
      'binanin-yasi-3': '3',
      'binanin-yasi-4': '4',
      'binanin-yasi-5-10-arasi': '5-10 Arası',
      'binanin-yasi-11-15-arasi': '11-15 Arası',
      'binanin-yasi-16-20-arasi': '16-20 Arası',
      'binanin-yasi-21-25-arasi': '21-25 Arası',
      'binanin-yasi-26-30-arasi': '26-30 Arası',
      'binanin-yasi-30-uzeri': '30 ve Üzeri',

      // Ticari - Isıtma ek options
      'isitma-dogalgaz-kombi': 'Doğalgaz Kombi',
      'isitma-kombi': 'Kombi',
      'isitma-vav': 'VAV',

      // Ticari - Kat Sayısı options
      'kat-sayisi-10-ve-uzeri': '10 ve Üzeri',

      // Ticari - Select options
      'alkol-ruhsati-var': 'Var',
      'alkol-ruhsati-yok': 'Yok',
      'ruhsat-durumu-var': 'Var',
      'ruhsat-durumu-yok': 'Yok',
      'bina-tipi-apartman': 'Apartman',
      'bina-tipi-is-hani': 'İş Hanı',
      'bina-tipi-mustakil': 'Müstakil',
      'bina-tipi-plaza': 'Plaza',
      'bina-tipi-villa': 'Villa',

      // Ticari - Select options
      'turu-acik': 'Açık',
      'turu-kapali': 'Kapalı',
      'turu-acik-kapali': 'Açık + Kapalı',
      'kiralama-suresi-saatlik': 'Saatlik',
      'kiralama-suresi-gunluk': 'Günlük',
      'kiralama-suresi-haftalik': 'Haftalık',
      'kiralama-suresi-aylik': 'Aylık',
      'kiralama-suresi-yillik': 'Yıllık',
      'sekreter-var': 'Var',
      'sekreter-yok': 'Yok',
      'kiracili-evet': 'Evet',
      'kiracili-hayir': 'Hayır',
      'krediye-uygunluk-evet': 'Evet',
      'krediye-uygunluk-hayir': 'Hayır',
      'krediye-uygunluk-bilinmiyor': 'Bilinmiyor',
      'tipi-biyokutle-biyogaz-enerji-santralleri':
          'Biyokütle & Biyogaz Enerji Santralleri',
      'tipi-gunes-enerjisi-santralleri': 'Güneş Enerjisi Santralleri',
      'tipi-hidroelektrik-santraller': 'Hidroelektrik Santraller',
      'tipi-jeotermal': 'Jeotermal',
      'tipi-ruzgar-enerjisi-santralleri': 'Rüzgar Enerjisi Santralleri',
      'tipi-termik-santraller': 'Termik Santraller',
      'yapinin-durumu-diger': 'Diğer',
      'isitma-dogalgaz': 'Doğalgaz',
      'isitma-fan-coil-sistem': 'Fan Coil Sistem',
      'isitma-merkezi-sistem': 'Merkezi Sistem',

      // Ticari - Detay Bilgisi checkbox values
      'alarm': 'Alarm',
      'asansor': 'Asansör',
      'asma-kat': 'Asma Kat',
      'avm-ici': 'AVM İçi',
      'bahce': 'Bahçe',
      'beyaz-esya': 'Beyaz Eşya',
      'bogaz-manzarasi': 'Boğaz Manzarası',
      'bodrum': 'Bodrum',
      'buro': 'Büro',
      'deniz-manzarasi': 'Deniz Manzarası',
      'esyali': 'Eşyalı',
      'guvenlik': 'Güvenlik',
      'icki-ruhsati': 'İçki Ruhsatı',
      'jenerator': 'Jeneratör',
      'kapali-garaj': 'Kapalı Garaj',
      'mobilya': 'Mobilya',
      'muzik-sistemi': 'Müzik Sistemi',
      'oto-sanayi-sitesinde': 'Oto Sanayi Sitesinde',
      'su-deposu': 'Su Deposu',
      'wc': 'WC',
      'wireless': 'Wireless',
      'yangin-merdiveni': 'Yangın Merdiveni',
      'yuk-asansoru': 'Yük Asansörü',
      'sahne': 'Sahne',
      'celik-kapi': 'Çelik Kapı',
      'parke-zemin': 'Parke Zemin',
      'bekleme-odasi': 'Bekleme Odası',
      'ekipman': 'Ekipman',
      'kamera-sistemi': 'Kamera Sistemi',
      'sauna': 'Sauna',
      'solaryum': 'Solaryum',
      'tv': 'TV',
      '7-24': '7/24',
      'bekleme-salonu': 'Bekleme Salonu',
      'kuyu': 'Kuyu',
      'ruhsatli': 'Ruhsatlı',
      'yikama-ekipmanlari': 'Yıkama Ekipmanları',
      'kantin': 'Kantin',
      'revir': 'Revir',
      'teras': 'Teras',
      'depo': 'Depo',
      'raf-sistemi': 'Raf Sistemi',
      'cctv-sistemi': 'CCTV Sistemi',
      'giris-kati': 'Giriş Katı',
      'hali': 'Halı',
      'kafeterya': 'Kafeterya',
      'ofis-malzemeleri': 'Ofis Malzemeleri',
      'personel-gecis-sistemi': 'Personel Geçiş Sistemi',
      'tuvalet': 'Tuvalet',
      'yangin-alarm-sistemi': 'Yangın Alarm Sistemi',
      'ses-yalitimi': 'Ses Yalıtımı',
      'dolap-raf': 'Dolap/Raf',
      'lavabo': 'Lavabo',
      'banka': 'Banka',
      'poliklinik': 'Poliklinik',
      'saglik-merkezi-hastane': 'Sağlık Merkezi/Hastane',
      'sinema-konferans-salonu': 'Sinema & Konferans Salonu',
      'spor-tesisi': 'Spor Tesisi',
      'yurt': 'Yurt',
      'bayan-wc': 'Bayan WC',
      'bay-wc': 'Bay WC',
      'magaza': 'Mağaza',
      'yaglama': 'Yağlama',
      'hava-su-kompresoru': 'Hava/Su Kompresörü',
      'elektrikli-bariyer': 'Elektrikli Bariyer',
      'cocuk-oyun-bolumu': 'Çocuk Oyun Bölümü',
      'dus': 'Duş',
      'erkek-tuvaleti': 'Erkek Tuvaleti',
      'havalandirma-sistemi': 'Havalandırma Sistemi',
      'havuz': 'Havuz',
      'isik-sistemi': 'Işık Sistemi',
      'kadin-tuvaleti': 'Kadın Tuvaleti',
      'kafe-bar': 'Kafe & Bar',
      'kilitli-dolap': 'Kilitli Dolap',
      'kondisyon-aletleri': 'Kondisyon Aletleri',
      'masaj-odasi': 'Masaj Odası',
      'ses-sistemi': 'Ses Sistemi',
      'soyunma-odasi': 'Soyunma Odası',
      'fotokopi-yazici': 'Fotokopi & Yazıcı',
      'ofis-gerecleri': 'Ofis Gereçleri',
      'sifreli-giris': 'Şifreli Giriş',
      'telefon-faks': 'Telefon & Faks',
      'toplanti-odasi': 'Toplantı Odası',
      'wi-fi-internet': 'Wi-Fi & İnternet',
      'icecek-hizmeti': 'İçecek Hizmeti',
      'posta-kargo-takip': 'Posta & Kargo Takip',
      'resepsiyonist': 'Resepsiyonist',
      'temizlik-hizmeti': 'Temizlik Hizmeti',

      // Ticari - Kullanım Amacı checkbox values
      'anaokulu': 'Anaokulu',
      'atolye': 'Atölye',
      'ayakkabici-lostra': 'Ayakkabıcı/Lostra',
      'buro-ofis': 'Büro & Ofis',
      'bufe': 'Büfe',
      'cafe-bar': 'Cafe & Bar',
      'cay-ocagi': 'Çay Ocağı',
      'dershane-kurs': 'Dershane/Kurs',
      'eczane-medikal': 'Eczane/Medikal',
      'hirdavatci-nalbur': 'Hırdavatçı/Nalbur',
      'imalathane': 'İmalathane',
      'internet-oyun-cafe': 'İnternet Oyun Cafe',
      'kuafor-guzellik-merkezi': 'Kuaför/Güzellik Merkezi',
      'market': 'Market',
      'muayenehane': 'Muayenehane',
      'oto-kuafor-yikama': 'Oto Kuaför/Yıkama',
      'otomotiv': 'Otomotiv',
      'oyun-cafe': 'Oyun Cafe',
      'oyuncakci': 'Oyuncakçı',
      'pastane-firin': 'Pastane/Fırın',
      'prova-kayit-studyosu': 'Prova/Kayıt Stüdyosu',
      'restoran-lokanta': 'Restoran/Lokanta',
      'su-bayi': 'Su Bayii',
      'tamirhane': 'Tamirhane',
      'tekel-bayi': 'Tekel Bayii',
      'zuccaciyeci': 'Züccaciyeci',

      // Ticari - Genel Özellikler checkbox values
      'cam-giydirme': 'Cam Giydirme',
      'guvenlik-kamerasi': 'Güvenlik Kamerası',
      'yangin-alarmi': 'Yangın Alarmı',
      'hirsiz-alarmi': 'Hırsız Alarmı',
      'hidrofor': 'Hidrofor',
      'acik-otopark': 'Açık Otopark',
      'kapali-otopark': 'Kapalı Otopark',
      'mutfak': 'Mutfak',

      // Ticari - Alt Yapı checkbox values
      'adsl': 'ADSL',
      'wi-fi': 'Wi-Fi',
      'kablo-tv': 'Kablo TV',
      'uydu': 'Uydu',
      'intercom': 'İntercom',
      'telefon-hatti': 'Telefon Hattı',
      'faks-telefon-hatti': 'Faks/Telefon Hattı',
      'sanayi-elektrigi': 'Sanayi Elektriği',

      // Ticari - Maden Tipi checkbox values
      'altin': 'Altın',
      'andezit': 'Andezit',
      'bakir': 'Bakır',
      'barit': 'Barit',
      'bazalt': 'Bazalt',
      'demir': 'Demir',
      'granit': 'Granit',
      'gumus': 'Gümüş',
      'kalker': 'Kalker',
      'kalsit': 'Kalsit',
      'kayrak': 'Kayrak',
      'kil': 'Kil',
      'komur': 'Kömür',
      'krom': 'Krom',
      'kum': 'Kum',
      'kursun': 'Kurşun',
      'kuvars': 'Kuvars',
      'mangan': 'Mangan',
      'mermer': 'Mermer',
      'nikel': 'Nikel',
      'olivin': 'Olivin',
      'petrol': 'Petrol',
      'pomza': 'Pomza',
      'silis': 'Silis',
      'tas': 'Taş',
      'traverten': 'Traverten',
      'tuz': 'Tuz',

      // Ticari - Özellikler checkbox values
      'elektrik': 'Elektrik',
      'su': 'Su',
      'yol': 'Yol',

      // Ticari - Cephe checkbox values
      'kuzey': 'Kuzey',
      'guney': 'Güney',
      'dogu': 'Doğu',
      'bati': 'Batı',

      // İç Özellikler - Yeni değerler
      'amerikan-mutfak': 'Amerikan Mutfak',
      'ankastre-mutfak': 'Ankastre Mutfak',
      'hazir-mutfak': 'Hazır Mutfak',
      'aritma-sistemi': 'Arıtma Sistemi',
      'hilton-lavabo': 'Hilton Lavabo',
      'parke': 'Parke',
      'laminant-parke': 'Laminant Parke',
      'hali-doseme': 'Halı Döşeme',
      'pvc-kaplama': 'PVC Kaplama',

      // Dış Cephe Özellikleri
      'siding-kaplama': 'Siding Kaplama',
      'btb-kaplama': 'BTB Kaplama',
      'tas-kaplama': 'Taş Kaplama',
      'mermer-kaplama': 'Mermer Kaplama',
      'ahsap-kaplama': 'Ahşap Kaplama',
      'boyali': 'Boyalı',

      // Konut Özellikleri
      'su-yalitimi': 'Su Yalıtımı',
      'mustakil-iskele': 'Müstakil İskele',
      'yuzme-havuzu': 'Yüzme Havuzu',

      // Çevre Özellikleri
      'saglik-ocagi': 'Sağlık Ocağı',
      'veteriner': 'Veteriner',
      'restoran': 'Restoran',
      'internet-cafe': 'İnternet Cafe',

      // Yakınlık (Ticari)
      'hastane': 'Hastane',
      'havaalani': 'Havalimanı',
      'toplu-tasima': 'Toplu Taşıma',

      // İç Dekorasyon
      'dogu-mimarisi': 'Doğu Mimarisi',
      'turk-mimarisi': 'Türk Mimarisi',
      'bati-mimarisi': 'Batı Mimarisi',
      'altin-varak-tavan': 'Altın Varak Tavan',
      'asma-tavan': 'Asma Tavan',
      'yuksek-tavan': 'Yüksek Tavan',

      // Manzara
      'yayla': 'Yayla',
    };

    // Check direct mapping first
    if (optionMappings.containsKey(code)) {
      return optionMappings[code]!;
    }

    // Default: use the property label formatter
    return _formatPropertyLabel(code);
  }

  // Build province dropdown
  Widget _buildProvinceDropdown() {
    final hasData = _provinces != null && _provinces!.isNotEmpty;
    final label = _provinces == null
        ? 'İller yükleniyor...'
        : (!hasData
            ? 'İller yüklenemedi'
            : (_selectedProvince?.name ?? 'İl Seçiniz'));
    return _buildAddressPickerTile(
      label: label,
      enabled: hasData,
      onTap: hasData ? _showProvincePicker : null,
    );
  }

  // Build district dropdown
  Widget _buildDistrictDropdown() {
    String label;
    bool enabled = false;

    if (_selectedProvince == null) {
      label = 'İlçe Seçiniz';
    } else if (_districts == null) {
      label = 'İlçeler yükleniyor...';
    } else if (_districts!.isEmpty) {
      label = 'İlçe bulunamadı';
    } else {
      label = _selectedDistrict?.name ?? 'İlçe Seçiniz';
      enabled = true;
    }

    return _buildAddressPickerTile(
      label: label,
      enabled: enabled,
      onTap: enabled ? _showDistrictPicker : null,
    );
  }

  // Build neighborhood dropdown
  Widget _buildNeighborhoodDropdown() {
    String label;
    bool enabled = false;

    if (_selectedDistrict == null) {
      label = 'Mahalle Seçiniz';
    } else if (_neighborhoods == null) {
      label = 'Mahalleler yükleniyor...';
    } else if (_neighborhoods!.isEmpty) {
      label = 'Mahalle bulunamadı';
    } else {
      label = _selectedNeighborhood?.name ?? 'Mahalle Seçiniz';
      enabled = true;
    }

    return _buildAddressPickerTile(
      label: label,
      enabled: enabled,
      onTap: enabled ? _showNeighborhoodPicker : null,
    );
  }

  // Ortak adres seçim kutusu (eşit boy, mobil uyumlu)
  Widget _buildAddressPickerTile({
    required String label,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.7,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled ? Colors.black87 : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showProvincePicker() async {
    if (_provinces == null || _provinces!.isEmpty) return;

    List<Province> filtered = List.from(_provinces!);
    final textController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildSearchableBottomSheet<Province>(
              title: 'İl Seçiniz',
              textController: textController,
              items: filtered,
              itemLabel: (p) => p.name,
              onSearchChanged: (q) {
                setModalState(() {
                  final query = q.trim().toLowerCase();
                  filtered = _provinces!
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();
                });
              },
              onItemSelected: (province) async {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedProvince = province;
                  _selectedDistrict = null;
                  _selectedNeighborhood = null;
                  _districts = null;
                  _neighborhoods = null;
                  _formData.provinceId = province.code;
                });
                await _loadDistricts(province.code);
                await _updateMapLocation();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showDistrictPicker() async {
    if (_districts == null || _districts!.isEmpty) return;

    List<Province> filtered = List.from(_districts!);
    final textController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildSearchableBottomSheet<Province>(
              title: 'İlçe Seçiniz',
              textController: textController,
              items: filtered,
              itemLabel: (p) => p.name,
              onSearchChanged: (q) {
                setModalState(() {
                  final query = q.trim().toLowerCase();
                  filtered = _districts!
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();
                });
              },
              onItemSelected: (district) async {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedDistrict = district;
                  _selectedNeighborhood = null;
                  _neighborhoods = null;
                  _formData.districtId = district.code;
                });
                _loadNeighborhoodsFromDistrict(district);
                await _updateMapLocation();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showNeighborhoodPicker() async {
    if (_neighborhoods == null || _neighborhoods!.isEmpty) return;

    List<Province> filtered = List.from(_neighborhoods!);
    final textController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _buildSearchableBottomSheet<Province>(
              title: 'Mahalle Seçiniz',
              textController: textController,
              items: filtered,
              itemLabel: (p) => p.name,
              onSearchChanged: (q) {
                setModalState(() {
                  final query = q.trim().toLowerCase();
                  filtered = _neighborhoods!
                      .where((p) => p.name.toLowerCase().contains(query))
                      .toList();
                });
              },
              onItemSelected: (neighborhood) async {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedNeighborhood = neighborhood;
                  _formData.neighborhoodId = neighborhood.code;
                });
                await _updateMapLocation();
              },
            );
          },
        );
      },
    );
  }

  // Genel amaçlı aramalı bottom sheet helper
  Widget _buildSearchableBottomSheet<T>({
    required String title,
    required TextEditingController textController,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<String> onSearchChanged,
    required ValueChanged<T> onItemSelected,
  }) {
    final maxH = MediaQuery.of(context).size.height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: textController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final label = itemLabel(item);
                  return ListTile(
                    title: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => onItemSelected(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Load districts for selected province
  Future<void> _loadDistricts(String provinceCode) async {
    try {
      debugPrint('🔵 Loading districts for province code: $provinceCode');

      final districts = await _portfolioService.getDistricts(provinceCode);

      // Debug: İlk ilçenin quarters array'ini kontrol et
      if (districts.isNotEmpty) {
        final firstDistrict = districts.first;
        debugPrint(
            '🔵 First district: ${firstDistrict.name} (code: ${firstDistrict.code})');
        debugPrint(
            '🔵 First district quarters: ${firstDistrict.quarters?.length ?? 0} items');
        if (firstDistrict.quarters != null &&
            firstDistrict.quarters!.isNotEmpty) {
          debugPrint(
              '🔵 First quarter: ${firstDistrict.quarters!.first.name} (code: ${firstDistrict.quarters!.first.code})');
        }
      }
      
      if (mounted) {
        setState(() {
          _districts = districts;
          _selectedDistrict = null;
          _selectedNeighborhood = null;
          _neighborhoods = null;
        });
      }
      
      debugPrint('✅ Loaded ${districts.length} districts');
    } catch (e) {
      debugPrint('❌ Error loading districts: $e');
      _showErrorMessage('İlçeler yüklenirken hata oluştu');
    }
  }

  // Load neighborhoods from selected district (quarters already in district object from API)
  void _loadNeighborhoodsFromDistrict(Province district) {
    try {
      debugPrint(
          '🔵 Loading neighborhoods from district: ${district.name} (code: ${district.code})');
      debugPrint(
          '🔵 District quarters: ${district.quarters?.length ?? 0} items');

      // Mahalleler ilçeler gelirken zaten quarters array'i içinde geliyor
      // District objesinden quarters array'ini al
      final neighborhoods = district.quarters ?? [];

      debugPrint('🔵 Neighborhoods count: ${neighborhoods.length}');
      if (neighborhoods.isNotEmpty) {
        debugPrint(
            '🔵 First neighborhood: ${neighborhoods.first.name} (code: ${neighborhoods.first.code})');
      }
      
      if (mounted) {
        setState(() {
          _neighborhoods = neighborhoods;
          _selectedNeighborhood = null;
        });
      }
      
      debugPrint(
          '✅ Loaded ${neighborhoods.length} neighborhoods from district quarters');

      if (neighborhoods.isEmpty) {
        debugPrint('⚠️ No quarters found in district object');
        debugPrint(
            '⚠️ District object: code=${district.code}, name=${district.name}');
      }
    } catch (e) {
      debugPrint('❌ Error loading neighborhoods from district: $e');
      _showErrorMessage('Mahalleler yüklenirken hata oluştu');
    }
  }

  // Update map location based on selected province/district/neighborhood
  Future<void> _updateMapLocation() async {
    try {
      String address = '';
      if (_selectedNeighborhood != null &&
          _selectedDistrict != null &&
          _selectedProvince != null) {
        address =
            '${_selectedNeighborhood!.name}, ${_selectedDistrict!.name}, ${_selectedProvince!.name}, Türkiye';
      } else if (_selectedDistrict != null && _selectedProvince != null) {
        address =
            '${_selectedDistrict!.name}, ${_selectedProvince!.name}, Türkiye';
      } else if (_selectedProvince != null) {
        address = '${_selectedProvince!.name}, Türkiye';
      } else {
        return;
      }

      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final newCenter = LatLng(location.latitude, location.longitude);

        setState(() {
          _mapCenter = newCenter;
          _selectedLocation = newCenter;
          _formData.latitude = location.latitude;
          _formData.longitude = location.longitude;
          _locationMarker = Marker(
            point: newCenter,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE53935),
              size: 40,
            ),
          );
        });

        // Animate map to new location
        _mapController.move(
            newCenter,
            _selectedNeighborhood != null
                ? 15.0
                : _selectedDistrict != null
                    ? 13.0
                    : 11.0);
      }
    } catch (e) {
      debugPrint('❌ Error updating map location: $e');
    }
  }

  // Build map widget
  Widget _buildMapWidget() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Harita/Uydu seçimi
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSatelliteView = false;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isSatelliteView
                          ? Colors.transparent
                          : const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Harita",
                      style: TextStyle(
                        color:
                            _isSatelliteView ? Colors.grey[600] : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSatelliteView = true;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isSatelliteView
                          ? const Color(0xFFE53935)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Uydu",
                      style: TextStyle(
                        color:
                            _isSatelliteView ? Colors.white : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Tam ekran butonu
                GestureDetector(
                  onTap: () {
                    _showFullScreenMap();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.fullscreen,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Harita alanı
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? _mapCenter,
                  initialZoom: _mapZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                      _formData.latitude = point.latitude;
                      _formData.longitude = point.longitude;
                      _locationMarker = Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 40,
                        ),
                      );
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView
                        ? EnvApi.mapRasterSatelliteTileUrlTemplate
                        : EnvApi.mapRasterTileUrlTemplate,
                    userAgentPackageName: 'com.zecorner.app',
                    maxZoom: 19,
                  ),
                  if (_locationMarker != null)
                    MarkerLayer(
                      markers: [_locationMarker!],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show fullscreen map
  void _showFullScreenMap() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: _mapZoom,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _selectedLocation = point;
                      _formData.latitude = point.latitude;
                      _formData.longitude = point.longitude;
                      _locationMarker = Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFE53935),
                          size: 40,
                        ),
                      );
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView
                        ? EnvApi.mapRasterSatelliteTileUrlTemplate
                        : EnvApi.mapRasterTileUrlTemplate,
                    userAgentPackageName: 'com.zecorner.app',
                    maxZoom: 19,
                  ),
                  if (_locationMarker != null)
                    MarkerLayer(
                      markers: [_locationMarker!],
                    ),
                ],
              ),
              // Close button
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
              // Map type selector
              Positioned(
                top: 40,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSatelliteView = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSatelliteView
                                ? Colors.transparent
                                : const Color(0xFFE53935),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Harita",
                            style: TextStyle(
                              color: _isSatelliteView
                                  ? Colors.grey[600]
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSatelliteView = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isSatelliteView
                                ? const Color(0xFFE53935)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Uydu",
                            style: TextStyle(
                              color: _isSatelliteView
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zoom controls
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _mapController.move(_mapController.camera.center,
                                  _mapController.camera.zoom + 1);
                            },
                          ),
                          Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              _mapController.move(_mapController.camera.center,
                                  _mapController.camera.zoom - 1);
                            },
                          ),
                        ],
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
