import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/presentation/screens/persons/persons_screen.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/contact/contact_api_model.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/models/contact/ref_education_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/core/value_objects/string_field.dart';
import 'package:zecorner/models/forms/person_edit_form_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

class EditPersonScreen extends StatefulWidget {
  const EditPersonScreen({super.key});

  @override
  State<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends State<EditPersonScreen> {
  bool _isRealPerson = true;
  Person? _person;

  // Repository
  final ContactApiRepository _contactRepository = ContactApiRepository();

  // Form model
  late PersonEditFormModel _formModel;

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

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // File picker variables
  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  PlatformFile? _diplomaFile;
  PlatformFile? _criminalRecordFile;
  PlatformFile? _professionalCertificateFile;
  PlatformFile? _realEstatePermitFile;

  // File upload state
  String? _profileImageId;
  String? _diplomaFileId;
  String? _criminalRecordFileId;
  String? _professionalCertificateFileId;
  String? _realEstatePermitFileId;
  final Map<String, String> _loadedDocTypes = {};
  List<Map<String, dynamic>> _loadedAttachments = [];
  String? _loadedProfessionCode;
  String? _loadedEducationCode;
  bool _isUploadingFile = false;

  // Connected person autocomplete
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchingContacts = false;
  int? _connectedOfficeContactNo;

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
  /// Kayıtlı uyruk kodu. Alan kaldırıldı; kayıt silinmesin diye saklanır.
  String? _loadedNationality;
  String? _addressCountryCode;
  bool _personBound = false;

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

    // Initialize form model
    _formModel = PersonEditFormModel.empty();

    // Initialize filtered contact types
    _filteredContactTypes = [];

    // Load reference data
    _loadReferenceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_personBound) return;
    _personBound = true;
    _person = ModalRoute.of(context)?.settings.arguments as Person?;
    if (_person == null) return;
    _fillFromListPerson(_person!);
    _loadFullContact();
  }

  void _fillFromListPerson(Person person) {
    _firstNameController.text = person.firstName;
    _lastNameController.text = person.lastName;
    _emailController.text = person.email;
    _phoneController.text = _formatPhoneForDisplay(person.phone);
    _tcNumberController.text = person.tcNumber;
    _birthDateController.text = _parseBirthDate(person.birthDate);
    _loadedAttachments = person.attachments ?? [];
    _applyExistingDocuments(_loadedAttachments);
    _addressController.text = person.address;
    _experienceController.text = person.experience;
    _connectedPersonController.text = person.companyName;
    _connectedOfficeContactNo = person.connectedContactNo;
    final nat = person.nationality.trim().toUpperCase();
    _loadedNationality = nat.isEmpty ? null : nat;
    _isForeignNational = nat.isNotEmpty && nat != 'TR';

    _formModel = PersonEditFormModel(
      firstName: StringField(person.firstName),
      lastName: StringField(person.lastName),
      email: StringField(person.email),
      phone: StringField(person.phone),
      tcNumber: StringField(person.tcNumber),
      birthDate: StringField(_parseBirthDate(person.birthDate)),
      address: StringField(person.address),
      experience: StringField(person.experience),
      instagram: StringField(''),
      facebook: StringField(''),
      twitter: StringField(''),
      linkedin: StringField(''),
      connectedPerson: StringField(person.companyName),
      pastExperience: StringField(''),
      coverLetter: StringField(''),
      references: StringField(''),
      companyInfo: StringField(''),
      selectedPersonType: person.personType.trim().isEmpty ? null : person.personType,
      selectedConsultantLevel: null,
      selectedProfession: person.profession.trim().isEmpty ? null : person.profession,
      selectedEducation: person.education.trim().isEmpty ? null : person.education,
      selectedCity: person.city.trim().isEmpty ? null : person.city,
      selectedDistrict: person.district.trim().isEmpty ? null : person.district,
      selectedNeighborhood: null,
      isActive: person.isActive,
      campaignConsent: true,
      isCustomConsultant: false,
    );
    if (_countries.isNotEmpty) _assignCountrySelectionsFromPerson();
  }

  Future<void> _loadFullContact() async {
    final id = int.tryParse(_person?.id ?? '');
    if (id == null || id <= 0) return;
    final result = await _contactRepository.getContactById(id);
    if (!mounted) return;
    result.fold((_) {}, (contact) {
      if (!mounted) return;
      setState(() {
        try {
          _applyContact(contact);
        } catch (_) {}
        final birth = _parseBirthDate(contact.birthday);
        if (birth.isNotEmpty) _birthDateController.text = birth;
        _loadedAttachments = contact.detailAttachments ?? _loadedAttachments;
        _applyExistingDocuments(_loadedAttachments);
      });
      _alignSelections();
      _restoreAddressCascade();
    });
  }

  void _setText(TextEditingController controller, String? value) {
    final text = value?.trim() ?? '';
    if (text.isNotEmpty) controller.text = text;
  }

  String? _keep(String? incoming, String? current) {
    final next = incoming?.trim() ?? '';
    return next.isNotEmpty ? next : current;
  }

  void _applyContact(ContactApiModel contact) {
    _setText(_firstNameController, contact.name);
    _setText(_lastNameController, contact.surname);
    _setText(_emailController, contact.eMail);
    _setText(_phoneController, _formatPhoneForDisplay(contact.tel));
    _setText(_tcNumberController, contact.tcIdNumber);
    final birth = _parseBirthDate(contact.birthday);
    if (birth.isNotEmpty) _birthDateController.text = birth;
    _setText(_addressController, contact.address);
    _setText(_experienceController, contact.sectoralExperience?.toString());
    _setText(_instagramController, contact.instagram);
    _setText(_facebookController, contact.facebook);
    _setText(_twitterController, contact.twitter);
    _setText(_linkedinController, contact.linkedin);
    _setText(_connectedPersonController, contact.connectedContactTitle);
    if (contact.connectedContact != null && contact.connectedContact! > 0) {
      _connectedOfficeContactNo = contact.connectedContact;
    }
    _setText(_pastExperienceController, contact.pastExperience);
    _setText(_coverLetterController, contact.coverLetter ?? contact.aboutMe);
    _setText(_referencesController, contact.references);
    _setText(_companyInfoController, contact.whereYouHeardUs);
    _setText(_postCodeController, contact.postCode);
    if ((contact.picture ?? '').trim().isNotEmpty) {
      _profileImageId = contact.picture;
    }
    _applyExistingDocuments(contact.detailAttachments);

    _addressCountryCode = contact.country;
    final nat = contact.nationality.trim().toUpperCase();
    _loadedNationality = nat.isEmpty ? _loadedNationality : nat;
    _isForeignNational = contact.isForeignNationality ??
        (nat.isNotEmpty && nat != 'TR');
    _selectedGender = contact.sex == 1 ? 'M' : contact.sex == 2 ? 'F' : null;
    _selectedMaritalStatus = _maritalLabel(contact.maritalStatus);
    _selectedBodySize = _bodySizeLabel(contact.size);
    _selectedBirthPlace = contact.birthPlaceName ??
        (contact.birthPlaceCode != null ? contact.birthPlaceCode.toString() : _selectedBirthPlace);
    _loadedProfessionCode = contact.professionCode ?? _loadedProfessionCode;
    _loadedEducationCode = contact.educationCode ?? _loadedEducationCode;

    _formModel = PersonEditFormModel(
      firstName: StringField(contact.name),
      lastName: StringField(contact.surname),
      email: StringField(contact.eMail),
      phone: StringField(contact.tel),
      tcNumber: StringField(contact.tcIdNumber ?? ''),
      birthDate: StringField(_parseBirthDate(contact.birthday)),
      address: StringField(contact.address ?? ''),
      experience: StringField(contact.sectoralExperience?.toString() ?? ''),
      instagram: StringField(contact.instagram ?? ''),
      facebook: StringField(contact.facebook ?? ''),
      twitter: StringField(contact.twitter ?? ''),
      linkedin: StringField(contact.linkedin ?? ''),
      connectedPerson: StringField(contact.connectedContactTitle ?? ''),
      pastExperience: StringField(contact.pastExperience ?? ''),
      coverLetter: StringField(contact.coverLetter ?? contact.aboutMe ?? ''),
      references: StringField(contact.references ?? ''),
      companyInfo: StringField(contact.whereYouHeardUs ?? ''),
      selectedPersonType: contact.typeDescription.trim().isEmpty
          ? _formModel.selectedPersonType
          : contact.typeDescription,
      selectedConsultantLevel: null,
      selectedProfession:
          _keep(contact.professionDescription, _formModel.selectedProfession),
      selectedEducation:
          _keep(contact.educationDescription, _formModel.selectedEducation),
      selectedCity: _keep(contact.provinceName ?? contact.city, _formModel.selectedCity),
      selectedDistrict:
          _keep(contact.districtName ?? contact.district, _formModel.selectedDistrict),
      selectedNeighborhood:
          _keep(contact.quarterName, _formModel.selectedNeighborhood),
      isActive: contact.status == 1,
      campaignConsent: contact.marketingCommunicationPermission,
      isCustomConsultant: false,
    );
    if (_countries.isNotEmpty) _assignCountrySelectionsFromPerson(overwrite: true);
  }

  /// Kayıtlı belgeler dosya seçiciyi doldurur. Yeni yükleme aynı yuvanın üstüne yazar.
  void _applyExistingDocuments(List<Map<String, dynamic>>? attachments) {
    if (attachments == null || attachments.isEmpty) return;
    for (final att in attachments.reversed) {
      final label = [
        att['type'],
        att['type_description'],
        att['description'],
      ].where((part) => part != null).join(' ');
      final id = _attachmentFileId(att);
      if (label.trim().isEmpty || id.isEmpty) continue;
      if (label.toUpperCase() == 'PICTURE' &&
          (_profileImageId == null || _profileImageId!.isEmpty)) {
        _profileImageId = id;
        continue;
      }
      final slot = _slotForAttachmentType(label);
      if (slot == null) continue;
      final current = _fileIdFor(slot);
      if (current != null && current.isNotEmpty) continue;
      _loadedDocTypes[slot] = (att['type'] ?? label).toString();
      switch (slot) {
        case 'diploma':
          _diplomaFileId = id;
          break;
        case 'criminal_record':
          _criminalRecordFileId = id;
          break;
        case 'professional_certificate':
          _professionalCertificateFileId = id;
          break;
        case 'real_estate_permit':
          _realEstatePermitFileId = id;
          break;
      }
    }
  }

  String _attachmentFileId(Map<String, dynamic> att) {
    final raw = att['attachment'] ??
        att['s3Id'] ??
        att['s3_id'] ??
        att['fileId'] ??
        att['file_id'] ??
        att['url'] ??
        att['path'];
    final file = raw?.toString().trim() ?? '';
    if (file.isNotEmpty && file != 'null') return file;
    final rowId = att['id']?.toString().trim() ?? '';
    if (rowId.length >= 8 && _slotForAttachmentType(rowId) == null) return rowId;
    return '';
  }

  String? _slotForAttachmentType(String raw) {
    final type = raw
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
    if (type.contains('GRADUATION') ||
        type.contains('DIPLOMA') ||
        type.contains('MEZUNIYET')) {
      return 'diploma';
    }
    if (type.contains('CRIMINAL') ||
        type.contains('ADLI SICIL') ||
        type.contains('SABIKA')) {
      return 'criminal_record';
    }
    if (type.contains('PROFESSIONAL') ||
        type.contains('COMPOTENCE') ||
        type.contains('COMPETENCE') ||
        type.contains('YETERLILIK') ||
        type.contains('MESLEKI')) {
      return 'professional_certificate';
    }
    if (type.contains('REAL_ESTATE') ||
        type.contains('AUTHORIZATION') ||
        type.contains('PERMIT') ||
        type.contains('TASINMAZ') ||
        type.contains('TICARI YETKI')) {
      return 'real_estate_permit';
    }
    return null;
  }

  String? _fileIdFor(String slot) {
    switch (slot) {
      case 'diploma':
        return _diplomaFileId;
      case 'criminal_record':
        return _criminalRecordFileId;
      case 'professional_certificate':
        return _professionalCertificateFileId;
      case 'real_estate_permit':
        return _realEstatePermitFileId;
      default:
        return null;
    }
  }

  bool _hasDocument(String slot, PlatformFile? file) {
    if (file != null) return true;
    final id = _fileIdFor(slot);
    if (id != null && id.isNotEmpty) return true;
    for (final att in _loadedAttachments.reversed) {
      final label = [
        att['type'],
        att['type_description'],
        att['description'],
      ].where((part) => part != null).join(' ');
      if (_slotForAttachmentType(label) != slot) continue;
      if (_attachmentFileId(att).isNotEmpty) return true;
    }
    return false;
  }

  String? _maritalLabel(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'single':
      case 'bekar':
        return 'Bekar';
      case 'married':
      case 'evli':
        return 'Evli';
      case 'divorced':
      case 'boşanmış':
      case 'bosanmis':
        return 'Boşanmış';
      case 'widowed':
      case 'widow':
      case 'dul':
        return 'Dul';
      default:
        if (raw == 'Bekar' || raw == 'Evli' || raw == 'Boşanmış' || raw == 'Dul') {
          return raw;
        }
        return null;
    }
  }

  String? _bodySizeLabel(String? raw) {
    const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
    final up = raw?.trim().toUpperCase();
    return sizes.contains(up) ? up : null;
  }

  /// Alanın başında zaten `+90` var. Kontrolde 10 hane durur.
  String _formatPhoneForDisplay(String tel) {
    final trimmed = tel.trim();
    if (trimmed.isEmpty || trimmed == '0') return '';
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('90') && digits.length > 10) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length >= 11) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) digits = digits.substring(0, 10);
    return digits;
  }

  String? _provinceNameFor(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || _provinces.isEmpty) return raw;
    for (final province in _provinces) {
      if (province.name.toLowerCase() == value.toLowerCase() ||
          province.code.toString() == value) {
        return province.name;
      }
    }
    return raw;
  }

  String? _resolveProfession() {
    final label = _formModel.selectedProfession?.trim();
    final code = _loadedProfessionCode?.trim();
    for (final item in _professions) {
      final sameLabel = label != null &&
          label.isNotEmpty &&
          item.description.trim().toLowerCase() == label.toLowerCase();
      final sameCode = code != null &&
          code.isNotEmpty &&
          (item.code == code || item.id == code);
      if (sameLabel || sameCode) return item.description;
    }
    if (label != null && label.isNotEmpty) {
      if (_professions.isNotEmpty) {
        _professions = [
          RefProfessionModel(
            id: code ?? label,
            code: code ?? label,
            description: label,
          ),
          ..._professions,
        ];
      }
      return label;
    }
    return _formModel.selectedProfession;
  }

  String? _resolveEducation() {
    final label = _formModel.selectedEducation?.trim();
    final code = _loadedEducationCode?.trim();
    for (final item in _educations) {
      final sameLabel = label != null &&
          label.isNotEmpty &&
          item.description.trim().toLowerCase() == label.toLowerCase();
      final sameCode = code != null &&
          code.isNotEmpty &&
          (item.code == code || item.id == code);
      if (sameLabel || sameCode) return item.description;
    }
    if (label != null && label.isNotEmpty) {
      if (_educations.isNotEmpty) {
        _educations = [
          RefEducationModel(
            id: code ?? label,
            code: code ?? label,
            description: label,
          ),
          ..._educations,
        ];
      }
      return label;
    }
    return _formModel.selectedEducation;
  }

  String? _resolvePersonType() {
    final label = _formModel.selectedPersonType?.trim();
    if (label == null || label.isEmpty || _contactTypes.isEmpty) {
      return _formModel.selectedPersonType;
    }
    for (final type in _contactTypes) {
      if (type.description.trim().toLowerCase() == label.toLowerCase() ||
          type.code.toString() == label) {
        return type.description;
      }
    }
    return _formModel.selectedPersonType;
  }

  void _alignSelections() {
    final profession = _resolveProfession();
    final education = _resolveEducation();
    final personType = _resolvePersonType();
    final city = _provinceNameFor(_formModel.selectedCity);
    final birth = _provinceNameFor(_selectedBirthPlace);
    if (!mounted) return;
    setState(() {
      _formModel = PersonEditFormModel(
        firstName: _formModel.firstName,
        lastName: _formModel.lastName,
        email: _formModel.email,
        phone: _formModel.phone,
        tcNumber: _formModel.tcNumber,
        birthDate: _formModel.birthDate,
        address: _formModel.address,
        experience: _formModel.experience,
        instagram: _formModel.instagram,
        facebook: _formModel.facebook,
        twitter: _formModel.twitter,
        linkedin: _formModel.linkedin,
        connectedPerson: _formModel.connectedPerson,
        pastExperience: _formModel.pastExperience,
        coverLetter: _formModel.coverLetter,
        references: _formModel.references,
        companyInfo: _formModel.companyInfo,
        selectedPersonType: personType ?? _formModel.selectedPersonType,
        selectedConsultantLevel: _formModel.selectedConsultantLevel,
        selectedProfession: profession ?? _formModel.selectedProfession,
        selectedEducation: education ?? _formModel.selectedEducation,
        selectedCity: city ?? _formModel.selectedCity,
        selectedDistrict: _formModel.selectedDistrict,
        selectedNeighborhood: _formModel.selectedNeighborhood,
        isActive: _formModel.isActive,
        campaignConsent: _formModel.campaignConsent,
        isCustomConsultant: _formModel.isCustomConsultant,
      );
      if (birth != null) _selectedBirthPlace = birth;
    });
  }

  Future<void> _restoreAddressCascade() async {
    final city = _formModel.selectedCity;
    if (city == null || city.isEmpty || _provinces.isEmpty) return;
    ProvinceModel? province;
    for (final item in _provinces) {
      if (item.name.toLowerCase() == city.toLowerCase() ||
          item.code.toString() == city) {
        province = item;
        break;
      }
    }
    if (province == null) return;
    await _loadDistrictsByProvince(province.code, restoreAddress: true);
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
    _personTypeSearchController.dispose();
    super.dispose();
  }

  // Parse birth date from various formats to GG/AA/YYYY
  String _parseBirthDate(String? dateString) {
    final raw = dateString?.trim() ?? '';
    if (raw.isEmpty || raw == 'null') return '';

    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    if (iso != null) {
      return '${iso.group(3)}/${iso.group(2)}/${iso.group(1)}';
    }

    final dotted = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})').firstMatch(raw);
    if (dotted != null) {
      final day = dotted.group(1)!.padLeft(2, '0');
      final month = dotted.group(2)!.padLeft(2, '0');
      return '$day/$month/${dotted.group(3)}';
    }

    return '';
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
              // Kişi ekleme / web ile aynı: status yoksa da aktif kabul et
              final allTypes = contactTypesResult.contactTypes;
              _contactTypes = allTypes
                  .where((type) => type.status == null || type.status == 1)
                  .toList();
              if (_contactTypes.isEmpty) {
                _contactTypes = allTypes;
              }
              _filteredContactTypes = _contactTypes;
              
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
              _assignCountrySelectionsFromPerson();
            }
          }

          _isLoadingRefData = false;
        });
        _alignSelections();
        if (mounted) _restoreAddressCascade();
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

  /// Referans ülkeler yüklendikten sonra adres ülkesi ve uyruk seçimlerini doldurur.
  void _assignCountrySelectionsFromPerson({bool overwrite = false}) {
    if (_countries.isEmpty) return;
    if (!overwrite && _selectedAddressCountry != null) return;
    final turkeyList = _countries.where((c) =>
        c.name == 'Türkiye Cumhuriyeti' || c.name == 'Türkiye').toList();
    final turkeyName = turkeyList.isNotEmpty ? turkeyList.first.name : null;

    String? nameForIso(String? code) {
      if (code == null || code.isEmpty) return null;
      final u = code.trim().toUpperCase();
      for (final c in _countries) {
        if (c.code.trim().toUpperCase() == u) return c.name;
      }
      return null;
    }

    _selectedAddressCountry = nameForIso(_addressCountryCode ?? _person?.country) ??
        turkeyName ??
        (_countries.isNotEmpty ? _countries.first.name : null);
  }

  // Load districts by province
  // [restoreAddress]: true = kişi adresi yükleniyor, district/quarter sıfırlama
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
              final wantedDistrict = _formModel.selectedDistrict;
              if (wantedDistrict != null && wantedDistrict.isNotEmpty) {
                DistrictModel? district;
                for (final item in _districts) {
                  if (item.name.toLowerCase() == wantedDistrict.toLowerCase() ||
                      item.code.toString() == wantedDistrict) {
                    district = item;
                    break;
                  }
                }
                if (district != null) {
                  if (district.name != wantedDistrict) {
                    _formModel = _formModel.copyWith(selectedDistrict: district.name);
                  }
                  _quarters = district.quarters;
                  final wantedQuarter = _formModel.selectedNeighborhood;
                  if (wantedQuarter != null && wantedQuarter.isNotEmpty) {
                    for (final quarter in _quarters) {
                      if (quarter.name.toLowerCase() == wantedQuarter.toLowerCase() ||
                          quarter.code.toString() == wantedQuarter) {
                        if (quarter.name != wantedQuarter) {
                          _formModel = _formModel.copyWith(selectedNeighborhood: quarter.name);
                        }
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

  // Check if files exist from API
  void _checkExistingFiles() {
    // API'den gelen dosya bilgilerini kontrol et
    // Şimdilik boş bırakıyoruz, API'den dosya bilgileri gelirse burada kontrol edilecek
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
              }
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_getFileTypeName(fileType)} başarıyla yüklendi'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
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
            content: Text('Dosya yüklenemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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
  Future<void> _showPersonTypeDropdown() async {
    if (_contactTypes.isEmpty) {
      await _loadReferenceData();
    }

    if (!mounted) return;

    setState(() {
      _isPersonTypeDropdownOpen = true;
      _filteredContactTypes = _contactTypes;
      _personTypeSearchController.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var visible = List<ContactTypeModel>.from(_contactTypes);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _personTypeSearchController,
                      decoration: InputDecoration(
                        hintText: "Ara...",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
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
                      onChanged: (query) {
                        setModalState(() {
                          if (query.isEmpty) {
                            visible = List<ContactTypeModel>.from(_contactTypes);
                          } else {
                            final q = query.toLowerCase();
                            visible = _contactTypes
                                .where((type) =>
                                    type.description.toLowerCase().contains(q))
                                .toList();
                          }
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
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
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final type = visible[index];
                              final isSelected =
                                  _formModel.selectedPersonType ==
                                      type.description;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _formModel = _formModel.copyWith(
                                      selectedPersonType: type.description,
                                    );
                                    _personTypeError = null;
                                    _isPersonTypeDropdownOpen = false;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE53935)
                                            .withOpacity(0.1)
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
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isPersonTypeDropdownOpen = false;
        });
      }
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
        _coverLetterError = 'Hakkımda  alanı boş bırakılamaz.';
      });
      isValid = false;
    }

    // 19. Validate criminal record (ZORUNLU)
    if (!_hasDocument('criminal_record', _criminalRecordFile)) {
      setState(() {
        _criminalRecordError = 'Adli sicil kaydı zorunludur.';
      });
      isValid = false;
    }

    // 20. Validate professional certificate (ZORUNLU)
    if (!_hasDocument('professional_certificate', _professionalCertificateFile)) {
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
          break;
        case 'criminal_record':
          _criminalRecordFile = null;
          _criminalRecordFileId = null;
          break;
        case 'professional_certificate':
          _professionalCertificateFile = null;
          _professionalCertificateFileId = null;
          break;
        case 'real_estate_permit':
          _realEstatePermitFile = null;
          _realEstatePermitFileId = null;
          break;
      }
      _loadedDocTypes.remove(documentType);
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
      if (_contactTypes.isEmpty) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kişi türleri yüklenemedi. Sayfayı kapatıp tekrar açın.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ContactTypeModel selectedContactType;
      try {
        selectedContactType = _contactTypes.firstWhere(
          (type) => type.description == _formModel.selectedPersonType,
        );
      } catch (_) {
        selectedContactType = _contactTypes.first;
      }

      RefProfessionModel? selectedProfession;
      if (_formModel.selectedProfession != null) {
        try {
          selectedProfession = _professions.firstWhere(
            (prof) => prof.description == _formModel.selectedProfession,
          );
        } catch (_) {
          selectedProfession =
              _professions.isNotEmpty ? _professions.first : null;
        }
      }

      RefEducationModel? selectedEducation;
      if (_formModel.selectedEducation != null) {
        try {
          selectedEducation = _educations.firstWhere(
            (edu) => edu.description == _formModel.selectedEducation,
          );
        } catch (_) {
          selectedEducation =
              _educations.isNotEmpty ? _educations.first : null;
        }
      }

      ProvinceModel? addrProvince;
      if (_formModel.selectedCity != null && _provinces.isNotEmpty) {
        try {
          addrProvince = _provinces
              .firstWhere((p) => p.name == _formModel.selectedCity);
        } catch (_) {}
      }
      DistrictModel? addrDistrict;
      if (_formModel.selectedDistrict != null && _districts.isNotEmpty) {
        try {
          addrDistrict = _districts
              .firstWhere((d) => d.name == _formModel.selectedDistrict);
        } catch (_) {}
      }
      QuarterModel? addrQuarter;
      if (_formModel.selectedNeighborhood != null && _quarters.isNotEmpty) {
        try {
          addrQuarter = _quarters
              .firstWhere((q) => q.name == _formModel.selectedNeighborhood);
        } catch (_) {}
      }
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

      final storedNationality = _loadedNationality?.trim().toUpperCase();
      final nationalityIso = _isForeignNational
          ? ((storedNationality != null &&
                  storedNationality.isNotEmpty &&
                  storedNationality != 'TR')
              ? storedNationality
              : countryIso)
          : 'TR';

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
        nationality: nationalityIso,
        sex: _selectedGender == 'M' ? 1 : _selectedGender == 'F' ? 2 : null,
        eMail: _emailController.text,
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
        professionCode: selectedProfession?.code,
        professionDescription: _formModel.selectedProfession ?? 'Diğer',
        educationCode: selectedEducation?.code,
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
        district: _formModel.selectedDistrict,
        city: _formModel.selectedCity,
        country: countryIso,
        postCode: _postCodeController.text.isEmpty ? null : _postCodeController.text,
        addressSource: null,
        provinceCode: addrProvince?.code.toString(),
        provinceName: _formModel.selectedCity,
        districtCode: addrDistrict?.code.toString(),
        districtName: _formModel.selectedDistrict,
        quarterCode: addrQuarter?.code.toString(),
        quarterName: _formModel.selectedNeighborhood,
        connectedContact: _connectedOfficeContactNo,
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
          'id': _loadedDocTypes['diploma'] ?? 'GRADUATION_DOCUMENT',
          's3Id': _diplomaFileId,
        });
      }
      if (_criminalRecordFileId != null && _criminalRecordFileId!.isNotEmpty) {
        files.add({
          'id': _loadedDocTypes['criminal_record'] ?? 'CRIMINAL_RECORD',
          's3Id': _criminalRecordFileId,
        });
      }
      if (_professionalCertificateFileId != null && _professionalCertificateFileId!.isNotEmpty) {
        files.add({
          'id': _loadedDocTypes['professional_certificate'] ??
              'PROFESSIONAL_COMPOTENCE_CERTIFICATE',
          's3Id': _professionalCertificateFileId,
        });
      }
      if (_realEstatePermitFileId != null && _realEstatePermitFileId!.isNotEmpty) {
        files.add({
          'id': _loadedDocTypes['real_estate_permit'] ??
              'REAL_ESTATE_TRADE_AUTHORIZATION_CERTIFICATE',
          's3Id': _realEstatePermitFileId,
        });
      }

      // Next.js save-contact: files + mevcut detail (toUpdateJson) birlikte; handler birleştirir
      final requestBody = contact.toUpdateJson();
      if (files.isNotEmpty) {
        requestBody['files'] = files;
        requestBody.putIfAbsent('detail', () => <String, dynamic>{});
      }

      // Update contact - Use real person ID with custom request body
      final result = await _contactRepository.updateContactWithBody(
        int.tryParse(_person?.id ?? '0') ?? 0,
        requestBody,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        if (result.isRight()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kişi başarıyla güncellendi!'),
              backgroundColor: Color(0xFFE53935),
            ),
          );

          // Navigate back after a short delay (klavyeyi kapat, sonra listeye dön)
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            }
          });
        } else {
          final failure = result.fold((l) => l, (r) => null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure?.message ?? 'Kişi güncellenemedi'),
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
            content: Text('Kişi güncelleme sırasında hata oluştu: $e'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: "Kişi Düzenle",
        onBackPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.pop(context);
        },
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                          value: _formModel.isActive,
                          onChanged: (value) {
                            setState(() {
                              _formModel = _formModel.copyWith(isActive: value);
                            });
                          },
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
                    //         Border.all(color: Colors.grey[200]!, width: 1.5),
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
                    //           Border.all(color: Colors.grey[200]!, width: 1.5),
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
                    // Fotoğraf
                    const Text("Fotoğraf *", 
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _isUploadingFile ? null : _pickProfileImage,
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
                        child: Row(
                          children: [
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
                          style: TextStyle(
                            color: Colors.red[600],
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Bu kayıt için ofis numarası alınamadı. Başka bir sonuç seçin.',
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                        ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _birthPlaceError != null ? Colors.red : Colors.grey[200]!, 
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
                          isExpanded: true,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _cityError != null ? Colors.red : Colors.grey[200]!, 
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
                          isExpanded: true,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _districtError != null ? Colors.red : Colors.grey[200]!, 
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
                                isExpanded: true,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _neighborhoodError != null ? Colors.red : Colors.grey[200]!, 
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
                                isExpanded: true,
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

                    const SizedBox(height: 24),
                    // Sosyal Medya
                    const Text(
                      "Sosyal Medya (Opsiyonel)",
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
                                value: _professions.any((p) =>
                                        p.description == _formModel.selectedProfession)
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
                                value: _educations.any((e) =>
                                        e.description == _formModel.selectedEducation)
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
                    if (_coverLetterError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 16),
                        child: Text(
                          _coverLetterError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

                    const SizedBox(height: 20),
                    // Firmamızı nereden duydunuz? (Opsiyonel)
                    TextFormField(
                      controller: _companyInfoController,
                      decoration: _buildModernInputDecoration(
                        labelText: "Firmamızı nereden duyduğunuzu yazınız",
                        hintText: "Firmamızı nereden duyduğunuzu yazınız",
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
                    _hasDocument('diploma', _diplomaFile)
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
                                        _diplomaFile?.name ?? 'Mevcut diploma yüklü',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _diplomaFile == null
                                            ? 'Kayıtlı belge'
                                            : _formatFileSize(_diplomaFile!.size),
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
                    _hasDocument('criminal_record', _criminalRecordFile)
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
                                        _criminalRecordFile?.name ??
                                            'Mevcut adli sicil kaydı yüklü',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _criminalRecordFile == null
                                            ? 'Kayıtlı belge'
                                            : _formatFileSize(
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50))),
                    const SizedBox(height: 8),
                    _hasDocument(
                        'professional_certificate', _professionalCertificateFile)
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
                                        _professionalCertificateFile?.name ??
                                            'Mevcut mesleki yeterlilik belgesi yüklü',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _professionalCertificateFile == null
                                            ? 'Kayıtlı belge'
                                            : _formatFileSize(
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
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    _hasDocument('real_estate_permit', _realEstatePermitFile)
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
                                        _realEstatePermitFile?.name ??
                                            'Mevcut yetki belgesi yüklü',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _realEstatePermitFile == null
                                            ? 'Kayıtlı belge'
                                            : _formatFileSize(
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
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Düzenle Butonu
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
                        onPressed: _updatePerson,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Düzenle",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
  }
}
