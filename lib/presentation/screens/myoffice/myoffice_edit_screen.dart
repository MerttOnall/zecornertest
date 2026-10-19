import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/presentation/screens/myoffice/myoffice_screen.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/office_persons/office_persons_api_repository.dart';
import 'package:zecorner/models/contact/contact_api_model.dart';
import 'package:zecorner/models/office_persons/office_persons_api_model.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/models/contact/ref_education_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/core/value_objects/string_field.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/models/forms/person_edit_form_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

class MyOfficeEditScreen extends StatefulWidget {
  const MyOfficeEditScreen({super.key});

  @override
  State<MyOfficeEditScreen> createState() => _MyOfficeEditScreenState();
}

class _MyOfficeEditScreenState extends State<MyOfficeEditScreen> {
  static const Color _brand = Color(0xFFEE2E24);
  static const Color _ink = Color(0xFF1C2430);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _icon = Color(0xFF7C8698);
  static const Color _fill = Color(0xFFF5F6F8);
  static const Color _line = Color(0xFFE6E9EF);
  static const Color _page = Color(0xFFF3F4F7);

  bool _isRealPerson = true;
  OfficePerson? _person;
  bool _hasLoadedPerson = false;
  late final OfficePersonsApiRepository _officePersonsRepository;

  // Repository
  final ContactApiRepository _contactRepository = ContactApiRepository();

  // Form model
  late PersonEditFormModel _formModel;

  // Kişinin sunucudaki tür kodu. Liste eşleşmezse kayıt bunu kullanır.
  String? _existingTypeCode;

  static const Map<String, int> _fallbackTypeCodes = {
    'Broker': 10,
    'Gayrimenkul Danışmanı': 11,
    'Ofis Asistanı': 12,
    'Takım Lideri': 13,
    'Broker Aday': 14,
    'Gayrimenkul Danışman Adayı': 15,
    'Saha Direktörü': 19,
    'Admin': 3,
    'Super Admin': 301,
  };

  // Reference data
  List<ContactTypeModel> _contactTypes = [];
  List<RefProfessionModel> _professions = [];
  List<RefEducationModel> _educations = [];
  bool _isLoadingRefData = true;

  // Location data
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<QuarterModel> _quarters = [];
  List<RefCountryModel> _countries = [];
  bool _isLoadingDistricts = false;
  bool _isLoadingQuarters = false;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _tcNumberController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _experienceController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;
  late TextEditingController _twitterController;
  late TextEditingController _linkedinController;
  late TextEditingController _connectedPersonController;
  late TextEditingController _pastExperienceController;
  late TextEditingController _coverLetterController;
  late TextEditingController _referencesController;
  late TextEditingController _companyInfoController;
  late TextEditingController _postCodeController;
  late TextEditingController _invoiceTitleController;
  late TextEditingController _invoiceTaxOfficeController;
  late TextEditingController _invoiceTaxNumberController;
  late TextEditingController _invoiceCountryController;
  late TextEditingController _invoiceCityController;
  late TextEditingController _invoiceDistrictController;
  late TextEditingController _invoiceQuarterController;
  late TextEditingController _invoiceAddressController;
  late TextEditingController _ttbsController;
  bool _companyEmail = true;
  String? _loadedProfessionCode;
  String? _loadedEducationCode;
  Map<String, dynamic>? _preservedNestedDetail;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // File picker variables
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  PlatformFile? _diplomaFile;
  PlatformFile? _criminalRecordFile;
  PlatformFile? _professionalCertificateFile;
  PlatformFile? _realEstatePermitFile;
  PlatformFile? _identityFrontFile;
  PlatformFile? _identityBackFile;
  PlatformFile? _taxPlateFile;

  // File upload state
  String? _profileImageId;
  String? _diplomaFileId;
  String? _criminalRecordFileId;
  String? _professionalCertificateFileId;
  String? _realEstatePermitFileId;
  String? _identityFrontFileId;
  String? _identityBackFileId;
  String? _taxPlateFileId;
  bool _isUploadingFile = false;

  // Mevcut belgeler (API'den yüklenen - güncellemede korunacak)
  List<Map<String, dynamic>> _existingDetailAttachments = [];

  // Connected person autocomplete
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingContacts = false;
  String? _selectedConnectedPersonId;

  // Gender selection
  String? _selectedGender;

  // Foreign national
  bool _isForeignNational = false;

  // Birth place, marital status, body size
  String? _selectedBirthPlace;
  String? _selectedMaritalStatus;
  String? _selectedBodySize;

  // Adres Bilgileri - Ülke (Türkiye varsayılan)
  String? _selectedAddressCountry;

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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _tcNumberController = TextEditingController();
    _birthDateController = TextEditingController();
    _addressController = TextEditingController();
    _experienceController = TextEditingController();
    _instagramController = TextEditingController();
    _facebookController = TextEditingController();
    _twitterController = TextEditingController();
    _linkedinController = TextEditingController();
    _connectedPersonController = TextEditingController();
    _pastExperienceController = TextEditingController();
    _coverLetterController = TextEditingController();
    _referencesController = TextEditingController();
    _companyInfoController = TextEditingController();
    _postCodeController = TextEditingController();
    _invoiceTitleController = TextEditingController();
    _invoiceTaxOfficeController = TextEditingController();
    _invoiceTaxNumberController = TextEditingController();
    _invoiceCountryController = TextEditingController();
    _invoiceCityController = TextEditingController();
    _invoiceDistrictController = TextEditingController();
    _invoiceQuarterController = TextEditingController();
    _invoiceAddressController = TextEditingController();
    _ttbsController = TextEditingController();

    // Initialize form model
    _formModel = PersonEditFormModel.empty();

    // Initialize filtered contact types
    _filteredContactTypes = [];

    // Initialize office persons repository
    _officePersonsRepository = OfficePersonsApiRepository();

    // Load reference data
    _loadReferenceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_person == null) {
      _person = ModalRoute.of(context)?.settings.arguments as OfficePerson?;
    }
    if (_person != null && !_hasLoadedPerson) {
      _hasLoadedPerson = true;
      // Önce argümanlardan minimal doldur (ekran hemen gösterilsin)
      _populateFromOfficePerson(_person!);
      // Arka planda API'den tam veriyi yükle
      _loadPersonDataFromApi();
    }
  }

  /// OfficePerson argümanlarından formu doldur - minimal veri
  void _populateFromOfficePerson(OfficePerson person) {
    _firstNameController.text = person.firstName;
    _lastNameController.text = person.lastName;
    _setEmailField(person.email);
    _connectedPersonController.text = person.office;
    _experienceController.text = person.personCount;
    _formModel = _formModel.copyWith(
      selectedPersonType: person.userType,
      isActive: person.isActive,
    );
    setState(() {});
  }

  /// API'den tam veriyi yükle - önce Contact API (edit_person ile aynı)
  Future<void> _loadPersonDataFromApi() async {
    if (_person == null) return;
    final contactNo = int.tryParse(_person!.id);
    if (contactNo == null) return;

    final contactResult = await _contactRepository.getContactById(contactNo);

    if (contactResult.isRight()) {
      if (!mounted) return;
      contactResult.fold((_) {}, (data) => _applyContactApiData(data));
      return;
    }

    // Contact API başarısız olursa officeContacts dene
    final officeResult = await _officePersonsRepository.getPersonById(contactNo);

    if (!mounted) return;

    officeResult.fold(
      (_) {},
      (data) => _applyOfficePersonApiData(data),
    );
  }

  void _applyContactApiData(ContactApiModel person) {
    _firstNameController.text = person.name;
    _lastNameController.text = person.surname;
    _setEmailField(person.eMail);
    _phoneController.text = _formatPhoneForDisplay(person.tel);
    _tcNumberController.text = person.tcIdNumber ?? '';
    _birthDateController.text = _formatBirthDateForDisplay(person.birthday);
    _addressController.text = person.address ?? '';
    _experienceController.text = person.sectoralExperience?.toString() ?? _person!.personCount;
    _connectedPersonController.text = person.connectedContactTitle ?? _person!.office;
    _instagramController.text = person.instagram ?? '';
    _facebookController.text = person.facebook ?? '';
    _twitterController.text = person.twitter ?? '';
    _linkedinController.text = person.linkedin ?? '';
    _pastExperienceController.text = person.pastExperience ?? '';
    _coverLetterController.text = person.coverLetter ?? person.aboutMe ?? '';
    _referencesController.text = person.references ?? '';
    _companyInfoController.text = person.whereYouHeardUs ?? '';
    _postCodeController.text = person.postCode ?? '';
    _profileImageId = person.picture;
    _existingDetailAttachments = person.detailAttachments ?? [];

    _selectedGender = person.sex == 1 ? 'M' : person.sex == 2 ? 'F' : null;
    _selectedBirthPlace = person.birthPlaceName ?? person.birthPlaceCode?.toString();
    _selectedMaritalStatus = _maritalLabel(person.maritalStatus);
    _selectedBodySize = _bodySizeLabel(person.size);
    _isForeignNational = person.isForeignNationality ?? false;
    _loadedProfessionCode = person.professionCode;
    _loadedEducationCode = person.educationCode;
    _preservedNestedDetail = person.preservedNestedDetail;
    _selectedConnectedPersonId = person.connectedContact?.toString();
    if (person.country != null && _countries.isNotEmpty) {
      try {
        _selectedAddressCountry = _countries.firstWhere((c) => c.code == person.country).name;
      } catch (_) {
        _selectedAddressCountry = _countries.any((c) => c.name.contains('Türkiye'))
            ? _countries.firstWhere((c) => c.name.contains('Türkiye')).name
            : _countries.first.name;
      }
    }

    _formModel = PersonEditFormModel(
      firstName: StringField(person.name),
      lastName: StringField(person.surname),
      email: StringField(person.eMail),
      phone: StringField(person.tel),
      tcNumber: StringField(person.tcIdNumber ?? ''),
      birthDate: StringField(_formatBirthDateForDisplay(person.birthday)),
      address: StringField(person.address ?? ''),
      experience: StringField(person.sectoralExperience?.toString() ?? ''),
      instagram: StringField(person.instagram ?? ''),
      facebook: StringField(person.facebook ?? ''),
      twitter: StringField(person.twitter ?? ''),
      linkedin: StringField(person.linkedin ?? ''),
      connectedPerson: StringField(person.connectedContactTitle ?? ''),
      pastExperience: StringField(person.pastExperience ?? ''),
      coverLetter: StringField(person.coverLetter ?? person.aboutMe ?? ''),
      references: StringField(person.references ?? ''),
      companyInfo: StringField(person.whereYouHeardUs ?? ''),
      selectedPersonType: person.typeDescription,
      selectedConsultantLevel: null,
      selectedProfession: person.professionDescription,
      selectedEducation: person.educationDescription,
      selectedCity: person.provinceName ?? person.city,
      selectedDistrict: person.districtName ?? person.district,
      selectedNeighborhood: person.quarterName ?? person.quarterCode,
      isActive: person.status == 1,
      campaignConsent: person.marketingCommunicationPermission,
      isCustomConsultant: false,
    );
    _rememberTypeCode(person.type);
    _syncLookups();
    _syncLocationLabels();

    // Mevcut belgelerden file ID'leri çıkar
    for (final att in _existingDetailAttachments) {
      final type = (att['type'] ?? '')
          .toString()
          .toUpperCase()
          .replaceAll('İ', 'I')
          .replaceAll('İ', 'I')
          .replaceAll('Ş', 'S')
          .replaceAll('Ğ', 'G')
          .replaceAll('Ü', 'U')
          .replaceAll('Ö', 'O')
          .replaceAll('Ç', 'C');
      final label = [
        att['type'],
        att['id'],
        att['type_description'],
        att['description'],
      ].where((part) => part != null).join(' ');
      final s3Id = att['attachment'] ?? att['s3Id'] ?? att['fileId'];
      if (s3Id != null && s3Id.toString().isNotEmpty) {
        if (type.contains('IDENTITY_DOCUMENT_FRONT') ||
            type.contains('IDENTITY_FRONT')) {
          _identityFrontFileId = s3Id.toString();
        } else if (type.contains('IDENTITY_DOCUMENT_BACK') ||
            type.contains('IDENTITY_BACK')) {
          _identityBackFileId = s3Id.toString();
        } else if (type == 'IDENTITY_DOCUMENT' && _identityFrontFileId == null) {
          _identityFrontFileId = s3Id.toString();
        } else if (type.contains('TAX_PLATE') || type.contains('VERGI')) {
          _taxPlateFileId = s3Id.toString();
        } else if (type.contains('DIPLOMA') ||
            type.contains('GRADUATION') ||
            type.contains('MEZUN')) {
          _diplomaFileId = s3Id.toString();
        } else if (type.contains('CRIMINAL') || type.contains('ADLI SICIL')) {
          _criminalRecordFileId = s3Id.toString();
        } else if (_isProfessionalCertificate(label)) {
          _professionalCertificateFileId = s3Id.toString();
        } else if (type.contains('REAL_ESTATE') ||
            type.contains('AUTHORIZATION') ||
            type.contains('PERMIT') ||
            type.contains('TASINMAZ')) {
          _realEstatePermitFileId = s3Id.toString();
        }
      }
    }
    _fillInvoiceFields();

    if (mounted) setState(() {});
  }

  void _applyOfficePersonApiData(OfficePersonsApiModel person) {
    _firstNameController.text = person.name ?? _person!.firstName;
    _lastNameController.text = person.surname ?? _person!.lastName;
    _setEmailField(person.eMail ?? _person!.email);
    _phoneController.text = _formatPhoneForDisplay(person.tel ?? '');
    _tcNumberController.text = person.tcIdNumber ?? '';
    _birthDateController.text = _formatBirthDateForDisplay(person.birthday);
    _addressController.text = person.address ?? '';
    _experienceController.text = person.sectoralExperience?.toString() ?? _person!.personCount;
    _connectedPersonController.text = person.connectedContactTitle ?? _person!.office;
    _profileImageId = person.picture;

    _formModel = _formModel.copyWith(
      selectedPersonType: person.typeDescription ?? _person!.userType,
      selectedProfession: person.professionDescription ?? 'Diğer',
      selectedEducation: person.educationDescription ?? 'Üniversite',
      selectedCity: person.city,
      selectedDistrict: person.district,
      selectedNeighborhood: null,
      isActive: person.status == 1,
      campaignConsent: person.marketingCommunicationPermission ?? true,
    );
    _rememberTypeCode(person.type?.toString());

    if (mounted) setState(() {});
  }

  static const String _companyEmailDomain = '@zecorner.com';

  void _setEmailField(String email) {
    final value = email.trim();
    if (value.toLowerCase().endsWith(_companyEmailDomain)) {
      _companyEmail = true;
      _emailController.text =
          value.substring(0, value.length - _companyEmailDomain.length);
    } else if (value.contains('@')) {
      _companyEmail = false;
      _emailController.text = value;
    } else {
      _companyEmail = true;
      _emailController.text = value;
    }
  }

  String _emailForSave() {
    final raw = _emailController.text.trim();
    if (raw.isEmpty) return '';
    if (raw.contains('@') || !_companyEmail) return raw;
    return '$raw$_companyEmailDomain';
  }

  String _subscriberDigits(String tel) {
    var digits = tel.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length > 10) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length >= 11) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    return digits;
  }

  String _formatPhoneForDisplay(String tel) {
    if (tel.trim().isEmpty || tel.trim() == '0') return '';
    final digits = _subscriberDigits(tel);
    if (digits.isEmpty) return '';
    final area = digits.substring(0, digits.length < 3 ? digits.length : 3);
    if (digits.length <= 3) return '+90 ($area';
    final midEnd = digits.length < 6 ? digits.length : 6;
    final mid = digits.substring(3, midEnd);
    if (digits.length <= 6) return '+90 ($area) $mid';
    return '+90 ($area) $mid-${digits.substring(6)}';
  }

  String? _maritalLabel(String? raw) {
    switch (raw) {
      case 'single':
      case 'Bekar':
        return 'Bekar';
      case 'married':
      case 'Evli':
        return 'Evli';
      case 'divorced':
      case 'Boşanmış':
        return 'Boşanmış';
      case 'widowed':
      case 'Dul':
        return 'Dul';
      default:
        return null;
    }
  }

  String? _maritalApi(String? label) {
    switch (label) {
      case 'Bekar':
        return 'single';
      case 'Evli':
        return 'married';
      case 'Boşanmış':
        return 'divorced';
      case 'Dul':
        return 'widowed';
      default:
        return label;
    }
  }

  String? _bodySizeLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    final value = raw.trim().toUpperCase();
    return sizes.contains(value) ? value : null;
  }

  void _syncLookups() {
    if (_professions.isNotEmpty) {
      for (final profession in _professions) {
        if (profession.description == _formModel.selectedProfession ||
            profession.code == _loadedProfessionCode ||
            profession.id == _loadedProfessionCode) {
          _formModel = _formModel.copyWith(selectedProfession: profession.description);
          break;
        }
      }
    }
    if (_educations.isNotEmpty) {
      for (final education in _educations) {
        if (education.description == _formModel.selectedEducation ||
            education.code == _loadedEducationCode ||
            education.id == _loadedEducationCode) {
          _formModel = _formModel.copyWith(selectedEducation: education.description);
          break;
        }
      }
    }
  }

  bool _sameLabel(String a, String b) =>
      a.trim().toUpperCase() == b.trim().toUpperCase();

  ProvinceModel? _matchedProvince() {
    final raw = _formModel.selectedCity;
    if (raw == null || raw.isEmpty) return null;
    for (final province in _provinces) {
      if (_sameLabel(province.name, raw) || province.code.toString() == raw) {
        return province;
      }
    }
    return null;
  }

  DistrictModel? _matchedDistrict() {
    final raw = _formModel.selectedDistrict;
    if (raw == null || raw.isEmpty) return null;
    for (final district in _districts) {
      if (_sameLabel(district.name, raw) || district.code.toString() == raw) {
        return district;
      }
    }
    return null;
  }

  QuarterModel? _matchedQuarter() {
    final raw = _formModel.selectedNeighborhood;
    if (raw == null || raw.isEmpty) return null;
    for (final quarter in _quarters) {
      if (_sameLabel(quarter.name, raw) || quarter.code.toString() == raw) {
        return quarter;
      }
    }
    return null;
  }

  ProvinceModel? _matchedBirthProvince() {
    final raw = _selectedBirthPlace;
    if (raw == null || raw.isEmpty) return null;
    for (final province in _provinces) {
      if (_sameLabel(province.name, raw) || province.code.toString() == raw) {
        return province;
      }
    }
    return null;
  }

  String _nestedText(String key) {
    return _preservedNestedDetail?[key]?.toString().trim() ?? '';
  }

  String _labelForProvince(String raw) {
    if (raw.isEmpty) return '';
    for (final province in _provinces) {
      if (province.code.toString() == raw || _sameLabel(province.name, raw)) {
        return province.name;
      }
    }
    return raw;
  }

  String _codeForProvince(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    for (final province in _provinces) {
      if (_sameLabel(province.name, trimmed) || province.code.toString() == trimmed) {
        return province.code.toString();
      }
    }
    return trimmed;
  }

  String _labelForCountry(String raw) {
    if (raw.isEmpty) return '';
    for (final country in _countries) {
      if (country.code.toUpperCase() == raw.toUpperCase() ||
          _sameLabel(country.name, raw)) {
        return country.name;
      }
    }
    return raw;
  }

  String _codeForCountry(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    for (final country in _countries) {
      if (_sameLabel(country.name, trimmed) ||
          country.code.toUpperCase() == trimmed.toUpperCase()) {
        return country.code;
      }
    }
    return trimmed;
  }

  void _fillInvoiceFields() {
    _invoiceTitleController.text = _nestedText('invoice_title');
    _invoiceTaxOfficeController.text = _nestedText('invoice_tax_office');
    _invoiceTaxNumberController.text = _nestedText('invoice_tax_number');
    _invoiceCountryController.text = _labelForCountry(_nestedText('invoice_country'));
    _invoiceCityController.text = _labelForProvince(_nestedText('invoice_city'));
    _invoiceDistrictController.text = _nestedText('invoice_district');
    _invoiceQuarterController.text = _nestedText('invoice_quarter');
    _invoiceAddressController.text = _nestedText('invoice_address');
    _ttbsController.text = _nestedText('ttbs_number');
  }

  void _stampInvoiceIntoNested() {
    final nested = Map<String, dynamic>.from(_preservedNestedDetail ?? {});
    void put(String key, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        nested.remove(key);
      } else {
        nested[key] = trimmed;
      }
    }

    put('invoice_title', _invoiceTitleController.text);
    put('invoice_tax_office', _invoiceTaxOfficeController.text);
    put('invoice_tax_number', _invoiceTaxNumberController.text);
    put('invoice_country', _codeForCountry(_invoiceCountryController.text));
    put('invoice_city', _codeForProvince(_invoiceCityController.text));
    put('invoice_district', _invoiceDistrictController.text);
    put('invoice_quarter', _invoiceQuarterController.text);
    put('invoice_address', _invoiceAddressController.text);
    put('ttbs_number', _ttbsController.text);
    _preservedNestedDetail = nested;
  }

  void _syncLocationLabels() {
    final cityRaw = _formModel.selectedCity;
    if (cityRaw != null && cityRaw.isNotEmpty && _provinces.isNotEmpty) {
      for (final province in _provinces) {
        if (province.name == cityRaw || province.code.toString() == cityRaw) {
          if (_formModel.selectedCity != province.name) {
            _formModel = _formModel.copyWith(selectedCity: province.name);
          }
          _loadDistrictsByProvince(province.code, restoreAddress: true);
          break;
        }
      }
    }
    final birth = _selectedBirthPlace;
    if (birth != null && birth.isNotEmpty && _provinces.isNotEmpty) {
      for (final province in _provinces) {
        if (province.name == birth || province.code.toString() == birth) {
          _selectedBirthPlace = province.name;
          break;
        }
      }
    }
    final rawCity = _nestedText('invoice_city');
    if (_invoiceCityController.text.trim().isEmpty ||
        _invoiceCityController.text.trim() == rawCity) {
      _invoiceCityController.text = _labelForProvince(rawCity);
    }
    final rawCountry = _nestedText('invoice_country');
    if (_invoiceCountryController.text.trim().isEmpty ||
        _invoiceCountryController.text.trim() == rawCountry) {
      _invoiceCountryController.text = _labelForCountry(rawCountry);
    }
  }

  Widget _buildProfilePreview(double size) {
    if (_profileImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.file(_profileImage!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    final id = _profileImageId;
    if (id == null || id.isEmpty) {
      return const SizedBox.shrink();
    }
    final url = id.startsWith('http') ? id : ImageUtils.getProfileImageUrl(id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFF3F4F6),
          child: Icon(Icons.person, color: Colors.grey, size: size * 0.55),
        ),
      ),
    );
  }

  String _formatBirthDateForDisplay(String? birthday) {
    if (birthday == null || birthday.isEmpty) return '';
    try {
      if (birthday.contains('/')) return birthday;
      final dt = DateTime.tryParse(birthday);
      if (dt != null) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (_) {}
    return birthday;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _tcNumberController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _connectedPersonController.dispose();
    _pastExperienceController.dispose();
    _coverLetterController.dispose();
    _referencesController.dispose();
    _companyInfoController.dispose();
    _postCodeController.dispose();
    _invoiceTitleController.dispose();
    _invoiceTaxOfficeController.dispose();
    _invoiceTaxNumberController.dispose();
    _invoiceCountryController.dispose();
    _invoiceCityController.dispose();
    _invoiceDistrictController.dispose();
    _invoiceQuarterController.dispose();
    _invoiceAddressController.dispose();
    _ttbsController.dispose();
    _personTypeSearchController.dispose();
    super.dispose();
  }

  // Load reference data from API
  Future<void> _loadReferenceData() async {
    try {
      setState(() {
        _isLoadingRefData = true;
      });

      // Load all reference data in parallel
      final results = await Future.wait([
        _contactRepository.getContactTypes(),
        _contactRepository.getProfessions(),
        _contactRepository.getEducations(),
        _contactRepository.getProvinces(), // Use refProvinces endpoint
        _contactRepository.getCountries(), // Load countries
      ]);

      if (mounted) {
        setState(() {
          // Contact types
          if (results[0].isRight()) {
            final contactTypesResult = results[0].fold<RefContactTypeResponseModel?>((l) => null, (r) => r as RefContactTypeResponseModel);
            if (contactTypesResult != null) {
              // Sadece aktif olanları filtrele (status == 1)
              _contactTypes = contactTypesResult.contactTypes
                  .where((type) =>
                      type.code != 0 &&
                      (type.status == null || type.status == 1))
                  .toList();
              _filteredContactTypes = _contactTypes; // Initialize filtered list
              
              // Debug: Ofis tiplerini yazdır
              final officeTypes = _contactTypes
                  .where((type) => 
                      type.description.toLowerCase().contains('ofis') ||
                      type.description.toLowerCase().contains('broker') ||
                      type.description.toLowerCase().contains('merkez') ||
                      type.isAgency == true ||
                      type.isCompany == true)
                  .toList();
              
              print('🏢 Ofis Tipleri ve Kodları:');
              for (final type in officeTypes) {
                print('  - Code: ${type.code}, Description: ${type.description}, isAgency: ${type.isAgency}, isCompany: ${type.isCompany}');
              }
              print('🏢 Toplam ${officeTypes.length} ofis tipi bulundu');
              print('🏢 Ofis Type Kodları: ${officeTypes.map((t) => t.code).toList()}');
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

          // Provinces (using refProvinces endpoint)
          if (results[3].isRight()) {
            final provincesResult = results[3].fold<ProvincesResponseModel?>((l) => null, (r) => r as ProvincesResponseModel);
            if (provincesResult != null) {
              _provinces = provincesResult.provinces;
              // Debug: Print first few province names to check format
              if (_provinces.isNotEmpty) {
                print('First 5 provinces: ${_provinces.take(5).map((p) => p.name).toList()}');
              }
            }
          }

          // Countries
          if (results[4].isRight()) {
            final countriesResult = results[4].fold<RefCountryResponseModel?>((l) => null, (r) => r as RefCountryResponseModel);
            if (countriesResult != null) {
              _countries = countriesResult.countries;
              // Türkiye varsayılan olarak seç (Adres Bilgileri için)
              _selectedAddressCountry = _countries.any((c) => c.name.contains('Türkiye'))
                  ? _countries.firstWhere((c) => c.name.contains('Türkiye')).name
                  : (_countries.isNotEmpty ? _countries.first.name : null);
            }
          }

          _syncLookups();
          _isLoadingRefData = false;
        });
        if (mounted) {
          _syncLocationLabels();
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRefData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referans verileri yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load districts by province
  Future<void> _loadDistrictsByProvince(int provinceCode, {bool restoreAddress = false}) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
        _districts = [];
        _quarters = [];
        if (!restoreAddress) {
          _formModel = _formModel.copyWith(selectedDistrict: null);
          _formModel = _formModel.copyWith(selectedNeighborhood: null);
        }
      });

      final result = await _contactRepository.getDistrictsByProvince(provinceCode);
      
      if (mounted) {
        if (result.isRight()) {
          final districtsResult = result.fold((l) => null, (r) => r);
          if (districtsResult != null) {
            setState(() {
              _districts = districtsResult.districts;
              _isLoadingDistricts = false;
              // Kişi ilçe seçiliyse mahalleleri district.quarters'tan al (web API)
              if (_formModel.selectedDistrict != null && _formModel.selectedDistrict!.isNotEmpty) {
                DistrictModel? district;
                for (final item in _districts) {
                  if (_sameLabel(item.name, _formModel.selectedDistrict!) ||
                      item.code.toString() == _formModel.selectedDistrict) {
                    district = item;
                    break;
                  }
                }
                if (district != null) {
                  _formModel = _formModel.copyWith(selectedDistrict: district.name);
                  _quarters = district.quarters;
                  final rawQuarter = _formModel.selectedNeighborhood;
                  if (rawQuarter != null && rawQuarter.isNotEmpty) {
                    for (final quarter in _quarters) {
                      if (_sameLabel(quarter.name, rawQuarter) || quarter.code.toString() == rawQuarter) {
                        _formModel = _formModel.copyWith(selectedNeighborhood: quarter.name);
                        break;
                      }
                    }
                  }
                }
              }
            });
          }
        } else {
          setState(() {
            _isLoadingDistricts = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İlçeler yüklenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlçeler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Upload file to API
  Future<void> _uploadFile(File file, String fileType) async {
    try {
      setState(() {
        _isUploadingFile = true;
      });

      final result = await _contactRepository.uploadFile(file, fileType);
      
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
                case 'identity_front':
                  _identityFrontFileId = fileId;
                  break;
                case 'identity_back':
                  _identityBackFileId = fileId;
                  break;
                case 'tax_plate':
                  _taxPlateFileId = fileId;
                  break;
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_getFileTypeName(fileType)} başarıyla yüklendi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final failure = result.fold((l) => l, (r) => null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure?.message ?? 'Dosya yüklenemedi'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya yükleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      case 'identity_front':
        return 'Nüfus cüzdanı ön';
      case 'identity_back':
        return 'Nüfus cüzdanı arka';
      case 'tax_plate':
        return 'Vergi levhası';
      default:
        return 'Dosya';
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
                  bottom: BorderSide(color: _line),
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
                        final isSelected =
                            _formModel.selectedPersonType == type.description;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _formModel = _formModel.copyWith(
                                selectedPersonType: type.description,
                              );
                              _rememberTypeCode(type.code.toString());
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
                                  color: _line,
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

  // Show modern date picker
  Future<void> _showModernDatePicker() async {
    await initializeDateFormatting('tr_TR', null);
    
    DateTime? selectedDate;
    DateTime initialFocusedDay = DateTime.now().subtract(const Duration(days: 365 * 18));
    
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
          initialFocusedDay = selectedDate;
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
        
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
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
                      bottom: BorderSide(color: _line),
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
                            _birthDateError = null; // Clear error when date is selected
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
                // Calendar
                Expanded(
                  child: TableCalendar(
                    locale: 'tr_TR',
                    firstDay: DateTime(1900),
                    lastDay: DateTime.now(),
                    focusedDay: modalFocusedDay,
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
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color(0xFFE53935),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color(0xFFE53935),
                      ),
                    ),
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
          ),
        );
      },
    );
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

      // Contact types'dan sadece ofis tiplerinin kodlarını bul (kişileri hariç tut)
      List<int> officeTypeCodes = [];
      if (_contactTypes.isNotEmpty) {
        officeTypeCodes = _contactTypes
            .where((type) {
              final desc = type.description.toLowerCase();
              // Sadece gerçek ofis tiplerini al (kişi tiplerini hariç tut)
              return (desc.contains('zecorner') && desc.contains('ofis')) ||
                     (desc.contains('merkez') && desc.contains('ofis')) ||
                     (desc.contains('broker') && desc.contains('ofis')) ||
                     (type.isAgency == true && type.isCompany == true); // Hem agency hem company olanlar ofis
            })
            .map((type) => type.code)
            .toList();
      }

      // Web API'ye uygun arama yap
      final result = await _contactRepository.searchContacts(
        query,
        size: 10,
        typeCodes: officeTypeCodes.isNotEmpty ? officeTypeCodes : null,
      );
      
      if (mounted) {
        if (result.isRight()) {
          final contacts = result.fold((l) => null, (r) => r);
          if (contacts != null) {
            // Response'u filtrele - SADECE ofisleri göster, kişileri hariç tut
            final filteredContacts = contacts.where((contact) {
              final typeDescription = contact['type_description']?.toString().toLowerCase() ?? '';
              
              // Sadece gerçek ofis tiplerini göster:
              // - "ZECorner Broker Ofis" ✓
              // - "ZECorner Merkez Ofis" ✓
              // - "Broker Ofis" ✓
              // - "Merkez Ofis" ✓
              
              // Kişi tiplerini hariç tut:
              // - "Broker" (sadece broker, ofis değil) ✗
              // - "Ofis Asistanı" (kişi) ✗
              // - "Gayrimenkul Danışmanı" (kişi) ✗
              
              // ZECorner ofis tipleri
              if (typeDescription.contains('zecorner') && typeDescription.contains('ofis')) {
                return true; // "ZECorner Broker Ofis" veya "ZECorner Merkez Ofis"
              }
              
              // Diğer ofis tipleri
              if (typeDescription.contains('broker ofis') || typeDescription.contains('merkez ofis')) {
                return true;
              }
              
              // Kişi tiplerini hariç tut
              if (typeDescription == 'broker' || 
                  typeDescription.contains('asistanı') ||
                  (typeDescription.contains('danışmanı') && !typeDescription.contains('ofis')) ||
                  (typeDescription.contains('danışman') && !typeDescription.contains('broker ofis') && !typeDescription.contains('merkez ofis') && !typeDescription.contains('zecorner'))) {
                return false;
              }
              
              // Diğer durumlar için false döndür (sadece yukarıdaki ofis tipleri kabul edilir)
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

  // Validate form fields (SADECE ZORUNLU ALANLAR - Add sayfası ile aynı)
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
    if (_formModel.selectedPersonType == null || _formModel.selectedPersonType!.isEmpty) {
      setState(() {
        _personTypeError = 'Kişi türü seçimi zorunludur';
      });
      isValid = false;
    }

    // 2. Validate first name (ZORUNLU)
    if (_firstNameController.text.isEmpty) {
      setState(() {
        _firstNameError = 'Ad alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (_firstNameController.text.trim().length < 2) {
      setState(() {
        _firstNameError = 'Ad en az 2 karakter olmalıdır.';
      });
      isValid = false;
    }

    // 3. Validate last name (ZORUNLU)
    if (_lastNameController.text.isEmpty) {
      setState(() {
        _lastNameError = 'Soyad alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (_lastNameController.text.trim().length < 2) {
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
    } else if (_subscriberDigits(_phoneController.text).length != 10) {
      setState(() {
        _phoneError = 'Geçerli bir telefon numarası giriniz (10 haneli).';
      });
      isValid = false;
    }

    // 5. Validate email (ZORUNLU)
    if (_emailForSave().isEmpty) {
      setState(() {
        _emailError = 'E-posta alanı boş bırakılamaz.';
      });
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailForSave())) {
      setState(() {
        _emailError = 'Geçerli bir e-posta adresi giriniz.';
      });
      isValid = false;
    }

    // 6. Validate profile image (ZORUNLU)
    if (_profileImage == null && _profileImageId == null) {
      setState(() {
        _profileImageError = 'Fotoğraf seçimi zorunludur.';
      });
      isValid = false;
    }

    // 7. Validate T.C. Kimlik No (ZORUNLU - yabancı uyruk değilse)
    if (!_isForeignNational) {
      if (_tcNumberController.text.isEmpty) {
        setState(() {
          _tcNumberError = 'T.C. Kimlik No alanı boş bırakılamaz.';
        });
        isValid = false;
      } else if (_tcNumberController.text.length != 11) {
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
    if (_formModel.selectedCity == null || _formModel.selectedCity!.isEmpty) {
      setState(() {
        _cityError = 'İl seçimi zorunludur.';
      });
      isValid = false;
    }

    // 14. Validate district (ZORUNLU)
    if (_formModel.selectedDistrict == null || _formModel.selectedDistrict!.isEmpty) {
      setState(() {
        _districtError = 'İlçe seçimi zorunludur.';
      });
      isValid = false;
    }

    // 15. Validate neighborhood (ZORUNLU)
    if (_formModel.selectedNeighborhood == null || _formModel.selectedNeighborhood!.isEmpty) {
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
    if (_formModel.selectedEducation == null || _formModel.selectedEducation!.isEmpty) {
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

    // 19. Validate criminal record (ZORUNLU - yeni dosya veya mevcut belge)
    final hasCriminalRecord = _criminalRecordFile != null ||
        (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty) ||
        _existingDetailAttachments.any((a) =>
            (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('CRIMINAL'));
    if (!hasCriminalRecord) {
      setState(() {
        _criminalRecordError = 'Adli sicil kaydı zorunludur.';
      });
      isValid = false;
    }

    // 20. Validate professional certificate (ZORUNLU - yeni dosya veya mevcut belge)
    final hasProfCert = _professionalCertificateFile != null ||
        (_professionalCertificateFileId != null && _professionalCertificateFileId!.isNotEmpty) ||
        _existingDetailAttachments.any((a) => _isProfessionalCertificate(
          [
            a['type'],
            a['id'],
            a['type_description'],
            a['description'],
          ].where((part) => part != null).join(' '),
        ));
    if (!hasProfCert) {
      setState(() {
        _professionalCertificateError = 'Mesleki yeterlilik belgesi zorunludur.';
      });
      isValid = false;
    }

    return isValid;
  }

  // File picker methods
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _profileImageError = null; // Clear error when image is selected
        });
        
        // Upload image to API
        await _uploadFile(File(image.path), 'profile_image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dosya boyutu 10MB\'dan büyük olamaz!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          switch (documentType) {
            case 'diploma':
              _diplomaFile = file;
              break;
            case 'criminal_record':
              _criminalRecordFile = file;
              _criminalRecordError = null; // Clear error when file is selected
              break;
            case 'professional_certificate':
              _professionalCertificateFile = file;
              _professionalCertificateError = null; // Clear error when file is selected
              break;
            case 'real_estate_permit':
              _realEstatePermitFile = file;
              break;
            case 'identity_front':
              _identityFrontFile = file;
              break;
            case 'identity_back':
              _identityBackFile = file;
              break;
            case 'tax_plate':
              _taxPlateFile = file;
              break;
          }
        });

        // Upload file to API
        await _uploadFile(File(file.path!), documentType);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dosya seçilirken bir hata oluştu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeDocument(String documentType) {
    setState(() {
      switch (documentType) {
        case 'diploma':
          _diplomaFile = null;
          _diplomaFileId = null;
          // Remove from existing attachments
          _existingDetailAttachments.removeWhere((a) =>
              (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('DIPLOMA'));
          break;
        case 'criminal_record':
          _criminalRecordFile = null;
          _criminalRecordFileId = null;
          // Remove from existing attachments
          _existingDetailAttachments.removeWhere((a) =>
              (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('CRIMINAL'));
          break;
        case 'professional_certificate':
          _professionalCertificateFile = null;
          _professionalCertificateFileId = null;
          // Remove from existing attachments
          _existingDetailAttachments.removeWhere((a) =>
              (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('PROFESSIONAL'));
          break;
        case 'real_estate_permit':
          _realEstatePermitFile = null;
          _realEstatePermitFileId = null;
          // Remove from existing attachments
          _existingDetailAttachments.removeWhere((a) {
            final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
            return type.contains('REAL_ESTATE') || type.contains('PERMIT');
          });
          break;
        case 'identity_front':
          _identityFrontFile = null;
          _identityFrontFileId = null;
          _existingDetailAttachments.removeWhere((a) {
            final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
            return type == 'IDENTITY_DOCUMENT_FRONT' || type == 'IDENTITY_DOCUMENT';
          });
          break;
        case 'identity_back':
          _identityBackFile = null;
          _identityBackFileId = null;
          _existingDetailAttachments.removeWhere((a) {
            final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
            return type == 'IDENTITY_DOCUMENT_BACK';
          });
          break;
        case 'tax_plate':
          _taxPlateFile = null;
          _taxPlateFileId = null;
          _existingDetailAttachments.removeWhere((a) {
            final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
            return type == 'TAX_PLATE';
          });
          break;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosya kaldırıldı!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Web kaydı `PROFESSIONAL_COMPOTENCE_CERTIFICATE` ya da Türkçe açıklama olabilir.
  bool _isProfessionalCertificate(String raw) {
    final type = raw
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('İ', 'I');
    return type.contains('PROFESSIONAL') ||
        type.contains('COMPOTENCE') ||
        type.contains('COMPETENCE') ||
        type.contains('YETERLILIK') ||
        type.contains('MESLEKI');
  }

  // Helper: Check if document exists (new file or existing file ID)
  bool _hasDocument(String documentType) {
    switch (documentType) {
      case 'diploma':
        return _diplomaFile != null || 
               (_diplomaFileId != null && _diplomaFileId!.isNotEmpty) ||
               _existingDetailAttachments.any((a) {
                 final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
                 return type.contains('DIPLOMA') || type.contains('GRADUATION');
               });
      case 'criminal_record':
        return _criminalRecordFile != null || 
               (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty) ||
               _existingDetailAttachments.any((a) =>
                   (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('CRIMINAL'));
      case 'professional_certificate':
        return _professionalCertificateFile != null || 
               (_professionalCertificateFileId != null && _professionalCertificateFileId!.isNotEmpty) ||
               _existingDetailAttachments.any((a) => _isProfessionalCertificate(
                 [
                   a['type'],
                   a['id'],
                   a['type_description'],
                   a['description'],
                 ].where((part) => part != null).join(' '),
               ));
      case 'real_estate_permit':
        return _realEstatePermitFile != null || 
               (_realEstatePermitFileId != null && _realEstatePermitFileId!.isNotEmpty) ||
               _existingDetailAttachments.any((a) =>
                   (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('REAL_ESTATE') ||
                   (a['type'] ?? a['id'] ?? '').toString().toUpperCase().contains('PERMIT'));
      case 'identity_front':
        return _identityFrontFile != null ||
            (_identityFrontFileId != null && _identityFrontFileId!.isNotEmpty);
      case 'identity_back':
        return _identityBackFile != null ||
            (_identityBackFileId != null && _identityBackFileId!.isNotEmpty);
      case 'tax_plate':
        return _taxPlateFile != null ||
            (_taxPlateFileId != null && _taxPlateFileId!.isNotEmpty);
      default:
        return false;
    }
  }

  // Helper: Get document file ID (from file ID or existing attachments)
  String? _getDocumentFileId(String documentType) {
    // First check if there's a file ID set
    String? fileId;
    switch (documentType) {
      case 'diploma':
        fileId = _diplomaFileId;
        break;
      case 'criminal_record':
        fileId = _criminalRecordFileId;
        break;
      case 'professional_certificate':
        fileId = _professionalCertificateFileId;
        break;
      case 'real_estate_permit':
        fileId = _realEstatePermitFileId;
        break;
      case 'identity_front':
        fileId = _identityFrontFileId;
        break;
      case 'identity_back':
        fileId = _identityBackFileId;
        break;
      case 'tax_plate':
        fileId = _taxPlateFileId;
        break;
    }
    
    // If file ID exists, return it
    if (fileId != null && fileId.isNotEmpty) {
      return fileId;
    }
    
    // Otherwise, check existing attachments
    String typePattern = '';
    switch (documentType) {
      case 'diploma':
        typePattern = 'DIPLOMA';
        break;
      case 'criminal_record':
        typePattern = 'CRIMINAL';
        break;
      case 'professional_certificate':
        typePattern = 'PROFESSIONAL';
        break;
      case 'real_estate_permit':
        typePattern = 'REAL_ESTATE';
        break;
      case 'identity_front':
        typePattern = 'IDENTITY_DOCUMENT_FRONT';
        break;
      case 'identity_back':
        typePattern = 'IDENTITY_DOCUMENT_BACK';
        break;
      case 'tax_plate':
        typePattern = 'TAX_PLATE';
        break;
    }
    
    if (typePattern.isNotEmpty) {
      try {
        final attachment = _existingDetailAttachments.firstWhere((a) {
          final type = (a['type'] ?? a['id'] ?? '').toString().toUpperCase();
          if (documentType == 'diploma') {
            return type.contains('DIPLOMA') || type.contains('GRADUATION');
          }
          if (documentType == 'professional_certificate') {
            return _isProfessionalCertificate(type);
          }
          return type.contains(typePattern) ||
              (documentType == 'real_estate_permit' &&
                  (type.contains('PERMIT') || type.contains('AUTHORIZATION')));
        });
        return attachment['attachment'] ?? attachment['s3Id'] ?? attachment['fileId']?.toString();
      } catch (_) {
        return null;
      }
    }
    
    return null;
  }

  Widget _optionalDocField(String label, String documentType) {
    final fileId = _getDocumentFileId(documentType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A4352),
          ),
        ),
        const SizedBox(height: 8),
        if (fileId != null && fileId.isNotEmpty)
          _buildExistingDocument(documentType, fileId)
        else
          OutlinedButton.icon(
            onPressed: () => _pickDocument(documentType),
            icon: const Icon(Icons.upload_file_outlined, color: Color(0xFFE53935)),
            label: const Text("Dosya seçiniz"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3A4352),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
      ],
    );
  }

  // Helper: Build existing document display widget
  Widget _buildExistingDocument(String documentType, String fileId, {String? errorText}) {
    final documentName = documentType == 'diploma'
        ? 'Diploma'
        : documentType == 'criminal_record'
            ? 'Adli Sicil Kaydı'
            : documentType == 'professional_certificate'
                ? 'Mesleki Yeterlilik Belgesi'
                : documentType == 'identity_front'
                    ? 'Nüfus Cüzdanı Ön'
                    : documentType == 'identity_back'
                        ? 'Nüfus Cüzdanı Arka'
                        : documentType == 'tax_plate'
                            ? 'Vergi Levhası'
                            : 'Taşınmaz Ticari Yetki Belgesi';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null ? Colors.red : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description,
            color: errorText != null ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mevcut $documentName yüklü',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: errorText != null ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  'Görüntülemek için tıklayın',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: Color(0xFFE53935)),
            onPressed: () {
              // Open document URL in browser or PDF viewer
              final url = ImageUtils.getS3FileUrl(fileId);
              if (url.isNotEmpty) {
                // TODO: Implement PDF viewer or web view
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Belge URL: $url'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            tooltip: 'Görüntüle',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _removeDocument(documentType);
                if (documentType == 'criminal_record') {
                  _criminalRecordError = null;
                } else if (documentType == 'professional_certificate') {
                  _professionalCertificateError = null;
                }
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
            tooltip: 'Kaldır',
          ),
        ],
      ),
    );
  }

  void _rememberTypeCode(String? raw) {
    final text = raw?.trim() ?? '';
    if (RegExp(r'^\d+$').hasMatch(text) && text != '0') {
      _existingTypeCode = text;
    }
  }

  String? _resolveTypeCode() {
    final selected = _formModel.selectedPersonType?.trim() ?? '';
    if (selected.isNotEmpty) {
      for (final type in _contactTypes) {
        if (type.code != 0 &&
            type.description.trim().toLowerCase() == selected.toLowerCase()) {
          return type.code.toString();
        }
      }
      for (final entry in _fallbackTypeCodes.entries) {
        if (entry.key.toLowerCase() == selected.toLowerCase()) {
          return entry.value.toString();
        }
      }
    }
    return _existingTypeCode;
  }

  String _editErrorMessage(String? raw) {
    final text = raw?.trim() ?? '';
    final lower = text.toLowerCase();
    if (lower.contains('contact_type_code_fk')) {
      return 'Kişi türü kaydedilemedi. Türü listeden tekrar seçip deneyin.';
    }
    if (text.isEmpty ||
        text.length > 180 ||
        lower.contains('datanode') ||
        lower.contains('dioexception') ||
        lower.contains('foreign key')) {
      return 'Kişi güncellenemedi. Zorunlu alanları kontrol edip tekrar deneyin.';
    }
    return text;
  }

  // Update person method
  Future<void> _updatePerson() async {
    // Form validation
    if (!_formKey.currentState!.validate() || !_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldurunuz'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE53935),
        ),
      ),
    );

    try {
      final typeCode = _resolveTypeCode();
      if (typeCode == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kişi türü geçersiz. Listeden tekrar seçip deneyin.'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
        return;
      }
      ContactTypeModel? matchedType;
      for (final type in _contactTypes) {
        if (type.code.toString() == typeCode) {
          matchedType = type;
          break;
        }
      }
      final selectedContactType = matchedType ??
          ContactTypeModel(
            code: int.parse(typeCode),
            description: _formModel.selectedPersonType ?? '',
            isCompany: false,
            isEmployee: true,
            isAgency: false,
            isCustomer: false,
            isAdmin: false,
            isAgencyEmployee: false,
          );

      final selectedProfession = _professions.isEmpty
          ? RefProfessionModel(code: '0', description: _formModel.selectedProfession ?? 'Diğer')
          : _professions.firstWhere(
              (prof) => prof.description == _formModel.selectedProfession,
              orElse: () => _professions.first,
            );

      final selectedEducation = _educations.isEmpty
          ? RefEducationModel(code: '0', description: _formModel.selectedEducation ?? 'Üniversite')
          : _educations.firstWhere(
              (edu) => edu.description == _formModel.selectedEducation,
              orElse: () => _educations.first,
            );

      _stampInvoiceIntoNested();
      // Create ContactApiModel from form data
      final contact = ContactApiModel(
        contactNo: 0,
        title: '${_firstNameController.text} ${_lastNameController.text}',
        name: _firstNameController.text,
        surname: _lastNameController.text,
        type: selectedContactType.code.toString(),
        typeDescription: _formModel.selectedPersonType ?? 'Müşteri',
        isCompany: false,
        isEmployee: selectedContactType.isEmployee,
        isAgency: selectedContactType.isAgency,
        tcIdNumber:
            _tcNumberController.text.isEmpty ? null : _tcNumberController.text,
        taxNo: null,
        taxOffice: null,
        nationality: 'TR',
        sex: _selectedGender == 'M' ? 1 : _selectedGender == 'F' ? 2 : null,
        eMail: _emailForSave(),
        tel: _phoneController.text,
        status: _formModel.isActive ? 1 : 0,
        updatedAt: DateTime.now().toIso8601String(),
        createdAt: DateTime.now().toIso8601String(),
        source: _companyInfoController.text.isEmpty
            ? null
            : _companyInfoController.text,
        birthday: _birthDateController.text.isEmpty
            ? null
            : _birthDateController.text,
        professionCode: selectedProfession.code,
        professionDescription: _formModel.selectedProfession ?? 'Diğer',
        educationCode: selectedEducation.code,
        educationDescription: _formModel.selectedEducation ?? 'Üniversite',
        whereYouHeardUs: _companyInfoController.text.isEmpty
            ? null
            : _companyInfoController.text,
        sectoralExperience: _experienceController.text.isEmpty
            ? null
            : int.tryParse(_experienceController.text),
        picture: _profileImageId,
        marketingCommunicationPermission: _formModel.campaignConsent,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        district: _matchedDistrict()?.code.toString() ?? _formModel.selectedDistrict,
        city: _matchedProvince()?.code.toString() ?? _formModel.selectedCity,
        country: 'TR',
        postCode: _postCodeController.text.isEmpty ? null : _postCodeController.text,
        addressSource: null,
        provinceCode: _matchedProvince()?.code.toString(),
        provinceName: _formModel.selectedCity,
        districtCode: _matchedDistrict()?.code.toString(),
        districtName: _formModel.selectedDistrict,
        quarterCode: _matchedQuarter()?.code.toString(),
        quarterName: _formModel.selectedNeighborhood,
        connectedContact: _selectedConnectedPersonId != null 
            ? int.tryParse(_selectedConnectedPersonId!) 
            : null,
        connectedContactTitle: _connectedPersonController.text.isEmpty
            ? null
            : _connectedPersonController.text,
        connectedContactType: null,
        connectedContactDescription: null,
        isCustomer: selectedContactType.isCustomer,
        slug: '',
        instagram: _instagramController.text.isEmpty ? null : _instagramController.text,
        facebook: _facebookController.text.isEmpty ? null : _facebookController.text,
        twitter: _twitterController.text.isEmpty ? null : _twitterController.text,
        linkedin: _linkedinController.text.isEmpty ? null : _linkedinController.text,
        pastExperience: _pastExperienceController.text.isEmpty ? null : _pastExperienceController.text,
        coverLetter: _coverLetterController.text.isEmpty ? null : _coverLetterController.text,
        references: _referencesController.text.isEmpty ? null : _referencesController.text,
        aboutMe: _coverLetterController.text.isEmpty ? null : _coverLetterController.text,
        birthPlaceCode: _matchedBirthProvince()?.code,
        birthPlaceName: _selectedBirthPlace,
        maritalStatus: _maritalApi(_selectedMaritalStatus),
        size: _selectedBodySize,
        isForeignNationality: _isForeignNational,
        preservedNestedDetail: _preservedNestedDetail,
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
          'id': 'GRADUATION_DOCUMENT',
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
          'id': 'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
          's3Id': _professionalCertificateFileId,
        });
      }
      if (_realEstatePermitFileId != null && _realEstatePermitFileId!.isNotEmpty) {
        files.add({
          'id': 'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
          's3Id': _realEstatePermitFileId,
        });
      }
      if (_identityFrontFileId != null && _identityFrontFileId!.isNotEmpty) {
        files.add({
          'id': 'IDENTITY_DOCUMENT_FRONT',
          's3Id': _identityFrontFileId,
        });
      }
      if (_identityBackFileId != null && _identityBackFileId!.isNotEmpty) {
        files.add({
          'id': 'IDENTITY_DOCUMENT_BACK',
          's3Id': _identityBackFileId,
        });
      }
      if (_taxPlateFileId != null && _taxPlateFileId!.isNotEmpty) {
        files.add({
          'id': 'TAX_PLATE',
          's3Id': _taxPlateFileId,
        });
      }

      // Web'deki gibi request body oluştur
      final requestBody = contact.toUpdateJson();
      
      // Files array'ini ekle
      if (files.isNotEmpty) {
        requestBody['files'] = files;
      }

      // Web'deki gibi attachments ve picture/logo işle
      List<Map<String, dynamic>> attachments = [];
      String? picture;
      String? logo;

      if (files.isNotEmpty) {
        for (var file in files) {
          final s3Id = file['s3Id'] as String?;
          final id = file['id'] as String?;
          
          if (s3Id != null && id != null) {
            if (id == 'PICTURE') {
              picture = s3Id;
            } else if (id == 'LOGO') {
              logo = s3Id;
            } else {
              attachments.add({
                'type': id,
                'attachment': s3Id,
              });
            }
          }
        }
      }

      // Detail objesini güncelle
      if (requestBody['detail'] == null) {
        requestBody['detail'] = <String, dynamic>{};
      }
      
      // Attachments: mevcut belgeleri koru, yeni yüklenen türleri değiştir
      final newUploadTypes = attachments.map((a) => (a['type'] ?? '').toString().toUpperCase()).toSet();
      final filteredExisting = _existingDetailAttachments.where((e) {
        final t = (e['type'] ?? e['id'] ?? '').toString().toUpperCase();
        if (t == 'IDENTITY_DOCUMENT' &&
            _identityFrontFileId != null &&
            _identityFrontFileId!.isNotEmpty) {
          return false;
        }
        if (_isProfessionalCertificate(t) &&
            newUploadTypes.any(_isProfessionalCertificate)) {
          return false;
        }
        if ((t.contains('DIPLOMA') || t.contains('GRADUATION')) &&
            newUploadTypes.any((n) =>
                n.contains('DIPLOMA') || n.contains('GRADUATION'))) {
          return false;
        }
        if ((t.contains('REAL_ESTATE') ||
                t.contains('PERMIT') ||
                t.contains('AUTHORIZATION')) &&
            newUploadTypes.any((n) =>
                n.contains('REAL_ESTATE') ||
                n.contains('PERMIT') ||
                n.contains('AUTHORIZATION'))) {
          return false;
        }
        if ((t.contains('TAX_PLATE') || t.contains('VERGI')) &&
            newUploadTypes.any((n) => n.contains('TAX_PLATE') || n.contains('VERGI'))) {
          return false;
        }
        return !newUploadTypes.contains(t);
      }).map((e) => Map<String, dynamic>.from(e)).toList();
      requestBody['detail']['attachments'] = [...filteredExisting, ...attachments];

      // Picture ve logo'yu ekle
      if (picture != null) {
        requestBody['detail']['picture'] = picture;
      }
      if (logo != null) {
        requestBody['detail']['logo'] = logo;
      }

      // Files array'ini sil (web'deki gibi)
      requestBody.remove('files');

      // Update contact - Use real person ID with custom request body
      final result = await _contactRepository.updateContactWithBody(
        int.tryParse(_person?.id ?? '0') ?? 0,
        requestBody,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        if (result.isRight()) {
          Navigator.of(context).pop(true);
        } else {
          final failure = result.fold((l) => l, (r) => null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _editErrorMessage(failure?.message),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editErrorMessage(e.toString()),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods - Static code mappings removed, now using API data

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
    const radius = BorderRadius.all(Radius.circular(14));
    final idle = BorderSide(color: errorText != null ? _brand : _line);
    const focus = BorderSide(color: _brand, width: 1.4);
    return InputDecoration(
      labelText: isRequired ? '$labelText *' : labelText,
      hintText: hintText,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixIcon: prefixIcon != null
          ? Container(
              margin: const EdgeInsets.only(left: 5),
              child: Icon(prefixIcon, color: _icon, size: 20),
            )
          : null,
      filled: true,
      fillColor: _fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: radius, borderSide: idle),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: idle),
      focusedBorder: const OutlineInputBorder(borderRadius: radius, borderSide: focus),
      errorBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: _brand),
      ),
      focusedErrorBorder:
          const OutlineInputBorder(borderRadius: radius, borderSide: focus),
      labelStyle: TextStyle(
        color: errorText != null ? _brand : const Color(0xFF3A4352),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: errorText != null ? _brand : _ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB0B7C3),
        fontSize: 14,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: _brand,
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
          ? Icon(prefixIcon, color: _icon, size: 20)
          : null,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      labelStyle: TextStyle(
        color: errorText != null ? _brand : const Color(0xFF3A4352),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: errorText != null ? _brand : _ink,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        color: _brand,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _statusChoice(bool active, String label, Color color) {
    final selected = _formModel.isActive == active;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _formModel = _formModel.copyWith(isActive: active);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _ink.withOpacity(0.06),
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

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AdminPanelInAppBar(
        title: "Kişi Düzenle",
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
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updatePerson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Düzenle",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRealPerson ? "Gerçek kişi" : "Tüzel kişi",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Kayıt durumu",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _fill,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _statusChoice(true, "Aktif", const Color(0xFF128A52)),
                                _statusChoice(false, "Pasif", const Color(0xFF5C6570)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _section(
                      title: "Kişi türü",
                      icon: Icons.badge_outlined,
                      children: [
                    InkWell(
                      onTap: _isLoadingRefData ? null : _showPersonTypeDropdown,
                      child: Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _personTypeError != null ? Colors.red : _line, 
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
                                      _formModel.selectedPersonType ?? 
                                      (_personTypeError ?? "Seçiniz"),
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: _formModel.selectedPersonType != null
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
                    if (_personTypeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _personTypeError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    // // Danışman Seviye Bilgileri
                    // const Text(
                    //   "Danışman Seviye Bilgileri",
                    //   style: TextStyle(
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.bold,
                    //     color: Color(0xFF2C3E50),
                    //   ),
                    // ),
                    // const SizedBox(height: 16),
                    // // Danışmanı Özelleştir Switch
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //       horizontal: 16, vertical: 2),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(16),
                    //     border:
                    //         Border.all(color: _line, width: 1.5),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       const Text("Danışmanı Özelleştir",
                    //           style: TextStyle(
                    //               fontSize: 16,
                    //               fontWeight: FontWeight.w500,
                    //               color: Color(0xFF2C3E50))),
                    //       const Spacer(),
                    //       Switch(
                    //         value: _formModel.isCustomConsultant,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             _formModel = _formModel.copyWith(
                    //                 isCustomConsultant: value);
                    //           });
                    //         },
                    //         activeColor: const Color(0xFFE53935),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // if (_formModel.isCustomConsultant) ...[
                    //   const SizedBox(height: 16),
                    //   // Danışman Başlangıç Seviyesi Dropdown
                    //   const Text("Danışman Başlangıç Seviyesi (Opsiyonel)",
                    //       style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w600,
                    //           color: Color(0xFF2C3E50))),
                    //   const SizedBox(height: 8),
                    //   Container(
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(16),
                    //       border:
                    //           Border.all(color: _line, width: 1.5),
                    //     ),
                    //     child: DropdownButtonHideUnderline(
                    //       child: DropdownButton<String>(
                    //         dropdownColor: Colors.white,
                    //         isExpanded: true,
                    //         value: _formModel.selectedConsultantLevel,
                    //         hint: const Padding(
                    //           padding: EdgeInsets.only(left: 8),
                    //           child: Text("Seçiniz",
                    //               style: TextStyle(color: Colors.grey)),
                    //         ),
                    //         padding: const EdgeInsets.symmetric(
                    //             horizontal: 20, vertical: 1),
                    //         items: ["Seviye 1", "Seviye 2", "Seviye 3"]
                    //             .map((level) => DropdownMenuItem(
                    //                   value: level,
                    //                   child: Text(level,
                    //                       style: const TextStyle(fontSize: 14)),
                    //                 ))
                    //             .toList(),
                    //         onChanged: (value) {
                    //           setState(() {
                    //             _formModel = _formModel.copyWith(
                    //                 selectedConsultantLevel: value);
                    //           });
                    //         },
                    //       ),
                    //     ),
                    //   ),
                    // ],
                    ],
                    ),
                    _section(
                      title: "Kişisel bilgiler",
                      icon: Icons.person_outline_rounded,
                      children: [
                    // Ad
                    TextFormField(
                      controller: _firstNameController,
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
                      controller: _lastNameController,
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
                        hintText: "+90 (555) 000-0000",
                        prefixIcon: Icons.phone_outlined,
                        isRequired: true,
                        errorText: _phoneError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        if (_subscriberDigits(value).length == 10 && _phoneError != null) {
                          setState(() {
                            _phoneError = null;
                          });
                        }
                      },
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final text = _formatPhoneForDisplay(newValue.text);
                          return TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(offset: text.length),
                          );
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
                        suffixText: _companyEmail ? _companyEmailDomain : null,
                        isRequired: true,
                        errorText: _emailError,
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        final usesOwnDomain = value.contains('@');
                        if (usesOwnDomain != !_companyEmail) {
                          setState(() => _companyEmail = !usesOwnDomain);
                        }
                        if (_emailForSave().isNotEmpty &&
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailForSave()) &&
                            _emailError != null) {
                          setState(() {
                            _emailError = null;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    if (_profileImage != null ||
                        (_profileImageId != null && _profileImageId!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(child: _buildProfilePreview(88)),
                      ),
                    // Fotoğraf
                    const Text("Fotoğraf *", 
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isUploadingFile ? null : _pickProfileImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _fill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _profileImageError != null ? _brand : _line,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Fotoğraf önizlemesi: seçilen dosya veya yüklenen S3 görseli
                            if (_profileImage != null ||
                                (_profileImageId != null && _profileImageId!.isNotEmpty))
                              _buildProfilePreview(56)
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 24),
                              ),
                            if (_profileImage != null ||
                                (_profileImageId != null && _profileImageId!.isNotEmpty))
                              const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isUploadingFile
                                    ? "Yükleniyor..."
                                    : _profileImage != null || (_profileImageId != null && _profileImageId!.isNotEmpty)
                                        ? "Profil fotoğrafı seçildi"
                                        : "Fotoğraf ekleyin",
                                style: TextStyle(
                                  color: _isUploadingFile || (_profileImage == null && (_profileImageId == null || _profileImageId!.isEmpty))
                                      ? Colors.grey[600]
                                      : Colors.black,
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
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFFE53935),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_profileImageError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _profileImageError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (!_isUploadingFile)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          "Yüksek çözünürlüklü, profesyonel çekim, net ışıklandırma ve beyaz/açık renk arka plan kullanılmalıdır",
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Bağlı Kişi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Bağlı Ofis",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3A4352))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _connectedPersonController,
                          decoration: InputDecoration(
                            labelText: "Bağlı Ofis",
                            hintText: "Ara...",
                            prefixIcon: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: Icon(Icons.business_outlined, color: _icon, size: 20),
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
                            fillColor: _fill,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              borderSide: const BorderSide(color: _brand, width: 1.4),
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
                          onChanged: _searchContacts,
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
                                // Web API response formatına göre: title, type_description, e_mail, contact_no
                                final title = contact['title']?.toString() ?? '';
                                final typeDescription = contact['type_description']?.toString() ?? '';
                                final email = contact['e_mail']?.toString() ?? '';
                                final contactNo = contact['contact_no']?.toString() ?? contact['contact_no']?.toString() ?? '';
                                
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
                                      _selectedConnectedPersonId = contactNo;
                                      _searchResults = [];
                                    });
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
                      controller: _tcNumberController,
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
                                  _tcNumberController.clear();
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _birthPlaceError != null ? Colors.red : _line, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
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
                    ),
                    if (_birthPlaceError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _birthPlaceError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ),

                    const SizedBox(height: 20),
                    // Cinsiyet
                    const Text("Cinsiyet *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _genderError != null ? Colors.red : _line, 
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
                    if (_genderError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _genderError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    // Medeni Durum
                    const Text("Medeni Durum *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _maritalStatusError != null ? Colors.red : _line, 
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
                    if (_maritalStatusError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _maritalStatusError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    // Beden
                    const Text("Beden *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _bodySizeError != null ? Colors.red : _line, 
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
                    if (_bodySizeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _bodySizeError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    ],
                    ),
                    _section(
                      title: "Adres bilgileri",
                      icon: Icons.location_on_outlined,
                      children: [
                    // Ülke (Opsiyonel)
                    const Text("Ülke (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _line, 
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
                                value: _selectedAddressCountry != null && _countries.any((c) => c.name == _selectedAddressCountry)
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
                                onChanged: (value) {
                                  setState(() => _selectedAddressCountry = value);
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // İl
                    const Text("İl *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _cityError != null ? Colors.red : _line, 
                          width: 1.5
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          decoration: _buildModernDropdownDecoration(
                            labelText: "İl",
                            prefixIcon: Icons.location_city_outlined,
                            isRequired: true,
                            errorText: _cityError,
                          ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: const Color(0xFFE53935),
                          value: _formModel.selectedCity != null && 
                                 _provinces.any((p) => p.name == _formModel.selectedCity) 
                                 ? _formModel.selectedCity 
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
                                    _formModel = _formModel.copyWith(selectedCity: value);
                                    _cityError = null;
                                    // Reset district and quarter when city changes
                                    _formModel = _formModel.copyWith(selectedDistrict: null);
                                    _formModel = _formModel.copyWith(selectedNeighborhood: null);
                                    _districts = [];
                                    _quarters = [];
                                  });
                                  
                                  // Load districts for selected province
                                  if (value != null && _provinces.isNotEmpty) {
                                    final selectedProvince = _provinces.firstWhere(
                                      (province) => province.name == value,
                                      orElse: () => _provinces.first,
                                    );
                                    _loadDistrictsByProvince(selectedProvince.code);
                                  }
                                },
                        ),
                      ),
                    ),
                    if (_cityError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _cityError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // İlçe
                    const Text("İlçe *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _districtError != null ? Colors.red : _line, 
                          width: 1.5
                        ),
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
                                value: _formModel.selectedDistrict != null && 
                                       _districts.any((d) => d.name == _formModel.selectedDistrict) 
                                       ? _formModel.selectedDistrict 
                                       : null,
                                items: _districts.map((DistrictModel district) {
                                  return DropdownMenuItem<String>(
                                    value: district.name,
                                    child: Text(district.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _formModel = _formModel.copyWith(selectedDistrict: value);
                                    _districtError = null;
                                    _formModel = _formModel.copyWith(selectedNeighborhood: null);
                                    // Web API: quarters district objesi içinde geliyor, ayrı API çağrısı yok
                                    if (value != null && _districts.isNotEmpty) {
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
                    if (_districtError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _districtError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),
                    // Mahalle
                    const Text("Mahalle *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _neighborhoodError != null ? Colors.red : _line, 
                          width: 1.5
                        ),
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
                                value: _formModel.selectedNeighborhood != null && 
                                       _quarters.any((q) => q.name == _formModel.selectedNeighborhood) 
                                       ? _formModel.selectedNeighborhood 
                                       : null,
                                items: _quarters.map((QuarterModel quarter) {
                                  return DropdownMenuItem<String>(
                                    value: quarter.name,
                                    child: Text(quarter.name, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _formModel = _formModel.copyWith(selectedNeighborhood: value);
                                    _neighborhoodError = null;
                                  });
                                },
                              ),
                            ),
                    ),
                    if (_neighborhoodError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _neighborhoodError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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

                    ],
                    ),
                    _section(
                      title: "Fatura Bilgileri",
                      icon: Icons.receipt_long_outlined,
                      children: [
                        TextFormField(
                          controller: _invoiceTitleController,
                          decoration: _buildModernInputDecoration(labelText: "Fatura Ünvanı"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceTaxOfficeController,
                          decoration: _buildModernInputDecoration(labelText: "Vergi Dairesi"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceTaxNumberController,
                          keyboardType: TextInputType.number,
                          decoration: _buildModernInputDecoration(labelText: "Vergi Numarası"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceCountryController,
                          decoration: _buildModernInputDecoration(labelText: "Fatura Ülkesi"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceCityController,
                          decoration: _buildModernInputDecoration(labelText: "Fatura İli"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceDistrictController,
                          decoration: _buildModernInputDecoration(labelText: "Fatura İlçesi"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceQuarterController,
                          decoration: _buildModernInputDecoration(labelText: "Fatura Mahallesi"),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _invoiceAddressController,
                          maxLines: 3,
                          decoration: _buildModernInputDecoration(labelText: "Fatura Adresi"),
                        ),
                      ],
                    ),
                    _section(
                      title: "Sosyal medya",
                      icon: Icons.share_outlined,
                      children: [
                    // Instagram
                    TextFormField(
                      controller: _instagramController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Instagram (Opsiyonel)",
                        prefixIcon: Icons.camera_alt_outlined,
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

                    ],
                    ),
                    _section(
                      title: "Meslek ve eğitim",
                      icon: Icons.school_outlined,
                      children: [
                    // Meslek (Opsiyonel)
                    const Text("Meslek (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _line, 
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
                                value: _professions.any((p) => p.description == _formModel.selectedProfession)
                                    ? _formModel.selectedProfession
                                    : null,
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
                                  setState(() {
                                    _formModel = _formModel.copyWith(
                                        selectedProfession: value);
                                  });
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Deneyimi
                    TextFormField(
                      controller: _experienceController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Deneyimi (Yıl) (Opsiyonel)",
                        prefixIcon: Icons.work_history_outlined,
                        suffixText: "yıl",
                      ),
                      cursorColor: const Color(0xFFE53935),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final int? years = int.tryParse(value);
                          if (years == null || years < 0 || years > 50) {
                            return 'Geçerli bir deneyim yılı giriniz (0-50)';
                          }
                        }
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // Eğitim Durumu
                    const Text("Eğitim Durumu *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _educationError != null ? Colors.red : _line, 
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
                                value: _educations.any((e) => e.description == _formModel.selectedEducation)
                                    ? _formModel.selectedEducation
                                    : null,
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
                                    _formModel =
                                        _formModel.copyWith(selectedEducation: value);
                                    _educationError = null;
                                  });
                                },
                              ),
                      ),
                    ),
                    if (_educationError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _educationError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Geçmiş İş Tecrübeleri - Convert to simple text field
                    const Text("Geçmiş İş Tecrübeleri (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pastExperienceController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _fill,
                        hintText: "Geçmiş iş tecrübelerinizi yazınız",
                        hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontSize: 14),
                        contentPadding: const EdgeInsets.all(16),
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
                          borderSide: const BorderSide(color: _brand, width: 1.4),
                        ),
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 24),
                    // Hakkımda 
                    const Text("Hakkımda ", 
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _coverLetterError != null ? _brand : _line,
                        ),
                      ),
                      child: TextFormField(
                        controller: _coverLetterController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Kendinizi tanıtan bir ön yazı yazınız",
                          contentPadding: const EdgeInsets.all(16),
                          errorText: _coverLetterError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        maxLines: 4,
                        maxLength: 300,
                        onChanged: (value) {
                          if (value.isNotEmpty && _coverLetterError != null) {
                            setState(() {
                              _coverLetterError = null;
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Referanslar - Convert to simple text field
                    const Text("Referanslar (Opsiyonel)", style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: TextFormField(
                        controller: _referencesController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Referanslarınızı yazınız",
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 3,
                        maxLength: 300,
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text("Firmamızı nereden duydunuz? (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: TextFormField(
                        controller: _companyInfoController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Firmamızı nereden duyduğunuzu yazınız",
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 3,
                        maxLength: 200,
                      ),
                    ),

                    ],
                    ),
                    _section(
                      title: "Belgeler",
                      icon: Icons.folder_open_outlined,
                      children: [
                    TextFormField(
                      controller: _ttbsController,
                      decoration: _buildModernInputDecoration(labelText: "TTBS Numarası"),
                    ),
                    const SizedBox(height: 20),
                    _optionalDocField("Nüfus Cüzdanı Ön", "identity_front"),
                    const SizedBox(height: 20),
                    _optionalDocField("Nüfus Cüzdanı Arka", "identity_back"),
                    const SizedBox(height: 20),
                    _optionalDocField("Vergi Levhası", "tax_plate"),
                    const SizedBox(height: 20),
                    // Diploma
                    const Text("Diploma (Opsiyonel)", style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    _hasDocument('diploma')
                        ? (_diplomaFile != null
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
                            : (_getDocumentFileId('diploma') != null
                                ? _buildExistingDocument('diploma', _getDocumentFileId('diploma')!)
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
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )))
                        : InkWell(
                            onTap: () => _pickDocument('diploma'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _fill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _line),
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
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                    // Adli Sicil Kaydı
                    const Text("Adli Sicil Kaydı *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    _hasDocument('criminal_record')
                        ? (_criminalRecordFile != null
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
                            : (_getDocumentFileId('criminal_record') != null
                                ? _buildExistingDocument('criminal_record', _getDocumentFileId('criminal_record')!, errorText: _criminalRecordError)
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
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )))
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
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    if (_criminalRecordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _criminalRecordError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                    // Mesleki Yeterlilik Belgesi
                    const Text("Mesleki Yeterlilik Belgesi *",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    _hasDocument('professional_certificate')
                        ? (_professionalCertificateFile != null
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
                            : (_getDocumentFileId('professional_certificate') != null
                                ? _buildExistingDocument('professional_certificate', _getDocumentFileId('professional_certificate')!, errorText: _professionalCertificateError)
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
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )))
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
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    if (_professionalCertificateError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _professionalCertificateError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                    // Taşınmaz Ticari Yetki Belgesi
                    const Text("Taşınmaz Ticari Yetki Belgesi (Opsiyonel)",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352))),
                    const SizedBox(height: 8),
                    _hasDocument('real_estate_permit')
                        ? (_realEstatePermitFile != null
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
                            : (_getDocumentFileId('real_estate_permit') != null
                                ? _buildExistingDocument('real_estate_permit', _getDocumentFileId('real_estate_permit')!)
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
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )))
                        : InkWell(
                            onTap: () => _pickDocument('real_estate_permit'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _fill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _line),
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
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 32),
                    // Kampanya İletişim İzni
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _formModel.campaignConsent,
                            onChanged: (value) {
                              setState(() {
                                _formModel = _formModel.copyWith(
                                    campaignConsent: value ?? false);
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
                          "Kampanya iletişim izni verilsin.",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A4352)),
                        ),
                      ],
                    ),

                    ],
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
