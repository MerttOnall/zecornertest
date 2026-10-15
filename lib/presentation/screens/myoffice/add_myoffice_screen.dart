import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/contact/contact_api_model.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/infrastructure/provinces/provinces_repository.dart';
import 'package:zecorner/infrastructure/provinces/provinces_detail_repo.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/models/contact/ref_country_model.dart';

// Phone number formatter
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer('+90 ');

    for (int i = 0; i < text.length && i < 10; i++) {
      if (i == 0) {
        buffer.write('(');
      }
      buffer.write(text[i]);
      if (i == 2) {
        buffer.write(') ');
      } else if (i == 5) {
        buffer.write('-');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class MyaddOfficeScreen extends StatefulWidget {
  const MyaddOfficeScreen({super.key});

  @override
  State<MyaddOfficeScreen> createState() => _MyaddOfficeScreenState();
}

class _MyaddOfficeScreenState extends State<MyaddOfficeScreen> {
  static const Color _brand = Color(0xFFEE2E24);
  static const Color _ink = Color(0xFF1C2430);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _fill = Color(0xFFF5F6F8);
  static const Color _line = Color(0xFFE6E9EF);
  static const Color _page = Color(0xFFF3F4F7);

  // Repository
  final ContactApiRepository _contactRepository = ContactApiRepository();
  final ProvincesRepository _provincesRepository = ProvincesRepository();
  final ProvincesDetailRepository _provincesDetailRepository =
      ProvincesDetailRepository();

  // State variables
  bool _isActive = false; // Durum switch
  bool _isDanismanOzellesir = false; // Danışman Özelleştir switch
  bool _kampanyaIzni = false; // Kampanya izni checkbox
  bool _isSaving = false; // Saving state
  bool _isYabanciUyruk = false; // Yabancı Uyruk checkbox

  String? _selectedPersonType;
  String? _selectedDanismanSeviye;
  String? _selectedCustomRate; // Özel danışman oranı
  String? _selectedUyruk;
  String? _selectedCountry;
  String? _selectedCity;
  int? _selectedCityCode; // İl kodu (API için)
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  String? _selectedMeslek;
  String? _selectedMeslekCode; // API için kod
  String? _selectedEgitimDurumu;
  String? _selectedEgitimCode; // API için kod
  String? _selectedDogumYeri; // Doğum Yeri
  int? _selectedDogumYeriCode; // Doğum Yeri kodu
  String? _selectedCinsiyet; // Cinsiyet
  String? _selectedMedeniDurum; // Medeni Durum
  String? _selectedBeden; // Beden

  // Ülke, İl, İlçe, Mahalle listeleri
  List<RefCountryModel> _countries = [];
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  List<QuarterModel> _quarters = [];
  bool _isLoadingCountries = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingQuarters = false;
  String? _selectedCountryCode; // Ülke kodu (API için)

  // File variables
  File? _fotografFile;
  String? _fotografFileName;
  File? _diplomaFile;
  String? _diplomaFileName;
  File? _adliSicilFile;
  String? _adliSicilFileName;
  File? _meslekiBelgeFile;
  String? _meslekiBelgeFileName;
  File? _tasinmazBelgeFile;
  String? _tasinmazBelgeFileName;

  // Controllers
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tcController = TextEditingController();
  final TextEditingController _dogumTarihiController = TextEditingController();
  final TextEditingController _adresController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _deneyimController = TextEditingController();
  final TextEditingController _gecmisIsController = TextEditingController();
  final TextEditingController _referansController = TextEditingController();
  final TextEditingController _nerdenDuyduController = TextEditingController();
  final TextEditingController _hakkimdaController = TextEditingController(); // Hakkımda

  // Data lists — web Ofise Bağlı Kişiler sırası
  static const List<String> _preferredPersonTypeOrder = [
    'Broker',
    'Gayrimenkul Danışmanı',
    'Takım Lideri',
    'Ofis Asistanı',
    'Broker Asistanı',
    'Gayrimenkul Danışmanı (Eğitim Aşamasında)',
    'Gayrimenkul Danışmanı Asistanı',
    'Ofis Direktörü',
    'Saha Direktörü',
  ];
  static const Map<String, int> _fallbackTypeCodes = {
    'Broker': 10,
    'Gayrimenkul Danışmanı': 11,
    'Ofis Asistanı': 12,
    'Takım Lideri': 13,
    'Saha Direktörü': 19,
  };

  List<String> _personTypes = List.from(_preferredPersonTypeOrder);
  final Map<String, int> _personTypeMapping = Map.from(_fallbackTypeCodes);

  final List<String> _danismanSeviyeleri = [
    "Seviye 1 (%55)",
  ];

  final List<String> _meslekler = [
    "Mühendis",
    "Doktor",
    "Öğretmen",
    "Diğer",
  ];

  final List<String> _egitimDurumlari = [
    "İlkokul",
    "Ortaokul",
    "Lise",
    "Ön Lisans",
    "Lisans",
    "Yüksek Lisans",
    "Doktora",
  ];

  final List<String> _cinsiyetler = [
    "Erkek",
    "Kadın",
    "Belirtmek İstemiyorum",
  ];

  final List<String> _medeniDurumlar = [
    "Bekar",
    "Evli",
    "Boşanmış",
    "Dul",
  ];

  final List<String> _bedenler = [
    "XS",
    "S",
    "M",
    "L",
    "XL",
    "XXL",
    "XXXL",
  ];

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _tcController.dispose();
    _dogumTarihiController.dispose();
    _adresController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _xController.dispose();
    _linkedinController.dispose();
    _deneyimController.dispose();
    _gecmisIsController.dispose();
    _referansController.dispose();
    _nerdenDuyduController.dispose();
    _hakkimdaController.dispose();
    super.dispose();
  }

  // Fotoğraf kaynağı seçimi (kamera / galeri)
  void _showPhotoSourceBottomSheet() {
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
                    'Profil Fotoğrafı Seç',
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
                      color: const Color(0xFFEE2E24).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFFEE2E24),
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
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE2E24).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFFEE2E24),
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
                    _pickImageFromSource(ImageSource.camera);
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

  // Seçilen kaynaktan fotoğraf al
  Future<void> _pickImageFromSource(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _fotografFile = File(image.path);
        _fotografFileName = image.name;
      });
    }
  }

  // Pick file
  Future<void> _pickFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      setState(() {
        switch (fileType) {
          case 'diploma':
            _diplomaFile = file;
            _diplomaFileName = fileName;
            break;
          case 'adliSicil':
            _adliSicilFile = file;
            _adliSicilFileName = fileName;
            break;
          case 'meslekiBelge':
            _meslekiBelgeFile = file;
            _meslekiBelgeFileName = fileName;
            break;
          case 'tasinmazBelge':
            _tasinmazBelgeFile = file;
            _tasinmazBelgeFileName = fileName;
            break;
        }
      });
    }
  }

  // Remove file
  void _removeFile(String fileType) {
    setState(() {
      switch (fileType) {
        case 'fotograf':
          _fotografFile = null;
          _fotografFileName = null;
          break;
        case 'diploma':
          _diplomaFile = null;
          _diplomaFileName = null;
          break;
        case 'adliSicil':
          _adliSicilFile = null;
          _adliSicilFileName = null;
          break;
        case 'meslekiBelge':
          _meslekiBelgeFile = null;
          _meslekiBelgeFileName = null;
          break;
        case 'tasinmazBelge':
          _tasinmazBelgeFile = null;
          _tasinmazBelgeFileName = null;
          break;
      }
    });
  }

  // Get all form data for API submission
  Map<String, dynamic> getFormData() {
    return {
      'status': _isActive ? 1 : 0,
      'personType': _selectedPersonType,
      'advisorCustomize': _isDanismanOzellesir,
      'advisorLevel': _selectedDanismanSeviye,
      'firstName': _adController.text,
      'lastName': _soyadController.text,
      'phone': _telefonController.text,
      'email': _emailController.text,
      'tcNo': _tcController.text,
      'birthDate': _dogumTarihiController.text,
      'nationality': _selectedUyruk,
      'country': _selectedCountry,
      'city': _selectedCity,
      'district': _selectedDistrict,
      'neighborhood': _selectedNeighborhood,
      'address': _adresController.text,
      'instagram': _instagramController.text,
      'facebook': _facebookController.text,
      'x': _xController.text,
      'linkedin': _linkedinController.text,
      'profession': _selectedMeslek,
      'experience': _deneyimController.text,
      'education': _selectedEgitimDurumu,
      'workHistory': _gecmisIsController.text,
      'aboutMe': _hakkimdaController.text,
      'references': _referansController.text,
      'howDidYouHear': _nerdenDuyduController.text,
      'campaignConsent': _kampanyaIzni,
      'birthPlace': _selectedDogumYeri,
      'birthPlaceCode': _selectedDogumYeriCode,
      'sex': _selectedCinsiyet,
      'maritalStatus': _selectedMedeniDurum,
      'size': _selectedBeden,
      'isForeignNationality': _isYabanciUyruk,
    };
  }

  // Get all files for upload
  Map<String, File?> getFiles() {
    return {
      'photo': _fotografFile,
      'diploma': _diplomaFile,
      'criminalRecord': _adliSicilFile,
      'professionalCertificate': _meslekiBelgeFile,
      'realEstateAuthorization': _tasinmazBelgeFile,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _loadPersonTypes();
  }

  Future<void> _loadPersonTypes() async {
    final result = await _contactRepository.getContactTypes();
    result.fold(
      (failure) {
        print('❌ Kişi türleri yüklenemedi: ${failure.message}');
      },
      (response) {
        final active = response.contactTypes
            .where((t) => t.status == null || t.status == 1)
            .toList();

        final names = <String>[];
        final mapping = <String, int>{};

        for (final name in _preferredPersonTypeOrder) {
          ContactTypeModel? found;
          for (final type in active) {
            if (type.description.trim().toLowerCase() == name.toLowerCase()) {
              found = type;
              break;
            }
          }
          if (found != null) {
            names.add(found.description);
            mapping[found.description] = found.code;
          } else if (_fallbackTypeCodes.containsKey(name)) {
            names.add(name);
            mapping[name] = _fallbackTypeCodes[name]!;
          }
        }

        if (names.isEmpty) return;

        if (mounted) {
          setState(() {
            _personTypes = names;
            _personTypeMapping
              ..clear()
              ..addAll(mapping);
          });
        }
      },
    );
  }

  // Load countries
  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);

    print('🌍 Ülkeler yükleniyor...');
    final result = await _contactRepository.getCountries();

    result.fold(
      (failure) {
        print('❌ Ülkeler yüklenemedi: ${failure.message}');
        setState(() => _isLoadingCountries = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ülkeler yüklenemedi: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (countriesResponse) {
        print('✅ ${countriesResponse.countries.length} ülke yüklendi');
        setState(() {
          _countries = countriesResponse.countries;
          _isLoadingCountries = false;
        });
      },
    );
  }

  // Load provinces
  Future<void> _loadProvinces() async {
    setState(() => _isLoadingProvinces = true);

    print('🔄 İller yükleniyor...');
    final result =
        await _provincesRepository.getProvincesSortedAlphabetically();

    result.fold(
      (failure) {
        print('❌ İller yüklenemedi: ${failure.message}');
        setState(() => _isLoadingProvinces = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İller yüklenemedi: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (provinces) {
        print('✅ ${provinces.length} il yüklendi');
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
      },
    );
  }

  // Load districts for selected province
  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _quarters = [];
      _selectedDistrict = null;
      _selectedNeighborhood = null;
    });

    final result =
        await _provincesDetailRepository.getProvinceDetails(provinceCode);

    result.fold(
      (failure) {
        print('❌ İlçeler yüklenemedi: ${failure.message}');
        _showError('İlçeler yüklenemedi');
        setState(() => _isLoadingDistricts = false);
      },
      (details) {
        setState(() {
          _districts = details.districts;
          _isLoadingDistricts = false;
        });
      },
    );
  }

  // Load quarters for selected district
  Future<void> _loadQuarters(DistrictModel district) async {
    setState(() {
      _isLoadingQuarters = true;
      _quarters = [];
      _selectedNeighborhood = null;
    });

    setState(() {
      _quarters = district.quarters;
      _isLoadingQuarters = false;
    });
  }

  // Save form with API integration
  Future<void> _saveForm() async {
    // Validation - Zorunlu alanlar
    if (_selectedPersonType == null) {
      _showError('Lütfen kişi türü seçin');
      return;
    }

    if (!_personTypeMapping.containsKey(_selectedPersonType)) {
      _showError('Seçilen kişi türü için kod bulunamadı. Lütfen tekrar deneyin.');
      return;
    }

    if (_adController.text.trim().isEmpty) {
      _showError('Lütfen ad giriniz');
      return;
    }

    if (_soyadController.text.trim().isEmpty) {
      _showError('Lütfen soyad giriniz');
      return;
    }

    if (_telefonController.text.trim().isEmpty) {
      _showError('Lütfen telefon numarası giriniz');
      return;
    }

    // Telefon numarasını kontrol et (sadece rakamları al)
    final phoneDigits =
        _telefonController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length != 10) {
      _showError('Geçerli bir telefon numarası giriniz (10 haneli)');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Lütfen e-posta adresi giriniz');
      return;
    }

    // E-posta formatını kontrol et
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showError('Geçerli bir e-posta adresi giriniz');
      return;
    }

    // Fotoğraf zorunlu
    if (_fotografFile == null) {
      _showError('Lütfen fotoğraf yükleyiniz');
      return;
    }

    // T.C. Kimlik No zorunlu
    if (_tcController.text.trim().isEmpty) {
      _showError('Lütfen T.C. Kimlik No giriniz');
      return;
    }
    if (_tcController.text.trim().length != 11) {
      _showError('T.C. Kimlik No 11 haneli olmalıdır');
      return;
    }

    // Doğum Tarihi zorunlu
    if (_dogumTarihiController.text.trim().isEmpty) {
      _showError('Lütfen doğum tarihi seçiniz');
      return;
    }

    // Doğum Yeri zorunlu
    if (_selectedDogumYeri == null) {
      _showError('Lütfen doğum yeri seçiniz');
      return;
    }

    // Cinsiyet zorunlu
    if (_selectedCinsiyet == null) {
      _showError('Lütfen cinsiyet seçiniz');
      return;
    }

    // Medeni Durum zorunlu
    if (_selectedMedeniDurum == null) {
      _showError('Lütfen medeni durum seçiniz');
      return;
    }

    // Beden zorunlu
    if (_selectedBeden == null) {
      _showError('Lütfen beden seçiniz');
      return;
    }

    // Adres Bilgileri - İl zorunlu
    if (_selectedCity == null) {
      _showError('Lütfen il seçiniz');
      return;
    }

    // İlçe zorunlu
    if (_selectedDistrict == null) {
      _showError('Lütfen ilçe seçiniz');
      return;
    }

    // Mahalle zorunlu
    if (_selectedNeighborhood == null) {
      _showError('Lütfen mahalle seçiniz');
      return;
    }

    // Adres zorunlu
    if (_adresController.text.trim().isEmpty) {
      _showError('Lütfen adres giriniz');
      return;
    }

    // Eğitim Durumu zorunlu
    if (_selectedEgitimDurumu == null) {
      _showError('Lütfen eğitim durumu seçiniz');
      return;
    }

    // Hakkımda zorunlu
    if (_hakkimdaController.text.trim().isEmpty) {
      _showError('Lütfen hakkımda bilgisi giriniz');
      return;
    }

    // Diploma zorunlu
    if (_diplomaFile == null) {
      _showError('Lütfen diploma yükleyiniz');
      return;
    }

    // Adli Sicil Kaydı zorunlu
    if (_adliSicilFile == null) {
      _showError('Lütfen adli sicil kaydı yükleyiniz');
      return;
    }

    // Mesleki Yeterlilik Belgesi zorunlu
    if (_meslekiBelgeFile == null) {
      _showError('Lütfen mesleki yeterlilik belgesi yükleyiniz');
      return;
    }

    // Show loading
    setState(() => _isSaving = true);

    try {
      // 1. Dosyaları yükle
      String? pictureId;
      List<Map<String, dynamic>> attachments = [];

      if (_fotografFile != null) {
        final result =
            await _contactRepository.uploadFile(_fotografFile!, 'PICTURE');
        result.fold(
          (failure) => _showError('Fotoğraf yüklenemedi: ${failure.message}'),
          (fileId) => pictureId = fileId,
        );
      }

      if (_diplomaFile != null) {
        final result =
            await _contactRepository.uploadFile(_diplomaFile!, 'DIPLOMA');
        result.fold(
          (failure) => print('Diploma yüklenemedi: ${failure.message}'),
          (fileId) =>
              attachments.add({'type': 'DIPLOMA', 'attachment': fileId}),
        );
      }

      if (_adliSicilFile != null) {
        final result = await _contactRepository.uploadFile(
            _adliSicilFile!, 'CRIMINAL_RECORD');
        result.fold(
          (failure) => print('Adli sicil yüklenemedi: ${failure.message}'),
          (fileId) => attachments
              .add({'type': 'CRIMINAL_RECORD', 'attachment': fileId}),
        );
      }

      if (_meslekiBelgeFile != null) {
        final result = await _contactRepository.uploadFile(
            _meslekiBelgeFile!, 'PROFESSIONAL_CERTIFICATE');
        result.fold(
          (failure) => print('Mesleki belge yüklenemedi: ${failure.message}'),
          (fileId) => attachments
              .add({'type': 'PROFESSIONAL_CERTIFICATE', 'attachment': fileId}),
        );
      }

      if (_tasinmazBelgeFile != null) {
        final result = await _contactRepository.uploadFile(
            _tasinmazBelgeFile!, 'REAL_ESTATE_LICENSE');
        result.fold(
          (failure) =>
              print('Taşınmaz belgesi yüklenemedi: ${failure.message}'),
          (fileId) => attachments
              .add({'type': 'REAL_ESTATE_LICENSE', 'attachment': fileId}),
        );
      }

      // 2. Contact modeli oluştur
      // Telefon numarasını temizle (sadece rakamları gönder)
      final cleanPhone =
          _telefonController.text.replaceAll(RegExp(r'[^\d]'), '');

      // Cinsiyet kodunu belirle
      int? cinsiyetCode;
      if (_selectedCinsiyet != null) {
        switch (_selectedCinsiyet) {
          case 'Erkek':
            cinsiyetCode = 1;
            break;
          case 'Kadın':
            cinsiyetCode = 2;
            break;
          case 'Belirtmek İstemiyorum':
            cinsiyetCode = 0;
            break;
        }
      }

      final contactData = ContactApiModel(
        contactNo: 0, // Yeni kayıt
        title: '${_adController.text.trim()} ${_soyadController.text.trim()}',
        name: _adController.text.trim(),
        surname: _soyadController.text.trim(),
        type: _personTypeMapping[_selectedPersonType]!.toString(),
        tcIdNumber: _tcController.text.trim().isNotEmpty
            ? _tcController.text.trim()
            : null,
        nationality: _isYabanciUyruk ? 'OTHER' : 'TR',
        sex: cinsiyetCode,
        eMail: _emailController.text.trim(),
        tel: cleanPhone,
        status: _isActive ? 1 : 0,
        createdAt: DateTime.now().toIso8601String(),
        typeDescription: _selectedPersonType!,
        isCompany: false,
        isEmployee: true,
        isAgency: _selectedPersonType == 'Broker',
        birthday: _dogumTarihiController.text.trim().isNotEmpty
            ? _dogumTarihiController.text.trim()
            : null,
        professionCode: _selectedMeslekCode,
        professionDescription: _selectedMeslek,
        educationCode: _selectedEgitimCode,
        educationDescription: _selectedEgitimDurumu,
        whereYouHeardUs: _nerdenDuyduController.text.trim().isNotEmpty
            ? _nerdenDuyduController.text.trim()
            : null,
        sectoralExperience: _deneyimController.text.trim().isNotEmpty
            ? int.tryParse(_deneyimController.text.trim())
            : null,
        picture: pictureId,
        marketingCommunicationPermission: _kampanyaIzni,
        address: _adresController.text.trim().isNotEmpty
            ? _adresController.text.trim()
            : null,
        country: _selectedCountryCode ?? 'TR',
        provinceCode: _selectedCityCode?.toString(),
        provinceName: _selectedCity,
        districtCode: _selectedDistrict != null && _districts.isNotEmpty
            ? _districts
                .firstWhere((d) => d.name == _selectedDistrict,
                    orElse: () => _districts.first)
                .code
                .toString()
            : null,
        districtName: _selectedDistrict,
        quarterCode: _selectedNeighborhood != null && _quarters.isNotEmpty
            ? _quarters
                .firstWhere((q) => q.name == _selectedNeighborhood,
                    orElse: () => _quarters.first)
                .code
                .toString()
            : null,
        quarterName: _selectedNeighborhood,
        instagram: _instagramController.text.trim().isNotEmpty
            ? _instagramController.text.trim()
            : null,
        facebook: _facebookController.text.trim().isNotEmpty
            ? _facebookController.text.trim()
            : null,
        twitter: _xController.text.trim().isNotEmpty
            ? _xController.text.trim()
            : null,
        linkedin: _linkedinController.text.trim().isNotEmpty
            ? _linkedinController.text.trim()
            : null,
        pastExperience: _gecmisIsController.text.trim().isNotEmpty
            ? _gecmisIsController.text.trim()
            : null,
        coverLetter: null, // Ön Yazı kaldırıldı
        references: _referansController.text.trim().isNotEmpty
            ? _referansController.text.trim()
            : null,
        aboutMe: _hakkimdaController.text.trim().isNotEmpty
            ? _hakkimdaController.text.trim()
            : null,
        birthPlaceCode: _selectedDogumYeriCode,
        birthPlaceName: _selectedDogumYeri,
        maritalStatus: _selectedMedeniDurum,
        size: _selectedBeden,
        isForeignNationality: _isYabanciUyruk,
        isCustomer: false,
        slug: '${_adController.text.trim()}-${_soyadController.text.trim()}'
            .toLowerCase()
            .replaceAll(' ', '-'),
      );

      // 3. API'ye gönder
      final result = await _contactRepository.createContact(contactData);

      setState(() => _isSaving = false);

      result.fold(
        (failure) {
          _showError('Kişi eklenemedi: ${failure.message}');
        },
        (contact) {
          _showSuccess('Kişi başarıyla eklendi!');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pop(true); // Refresh için true döndür
            }
          });
        },
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Beklenmeyen hata: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEE2E24),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPersonTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
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
                    'Kişi Türü',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: ListView.builder(
                itemCount: _personTypes.length,
                itemBuilder: (context, index) {
                  final type = _personTypes[index];
                  final isSelected = _selectedPersonType == type;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPersonType = type;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[50] : Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.red[700],
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

  void _showGenericModal({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = selectedValue == item;
                  return InkWell(
                    onTap: () {
                      onSelect(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[50] : Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color:
                                  isSelected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.red[700],
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

  // Özel danışman oranı modal
  void _showCustomRateModal() {
    // %55 - %60 arası oranlar
    final List<String> customRates =
        List.generate(6, (index) => '%${55 + index}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
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
                      setState(() {
                        _selectedCustomRate = rate;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red[50] : Colors.white,
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
                              color:
                                  isSelected ? Colors.red[700] : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.red[700],
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

  Widget _fieldLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text.rich(
        TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A4352),
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: _brand, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    const radius = BorderRadius.all(Radius.circular(14));
    const idle = BorderSide(color: _line);
    const focus = BorderSide(color: _brand, width: 1.4);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fill,
      hintStyle: const TextStyle(
        color: Color(0xFFB0B7C3),
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(fontSize: 12, height: 1.2),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isRequired: isRequired),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _brand,
          decoration: _inputDecoration(hint: hint),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required VoidCallback onTap,
    bool isRequired = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isRequired: isRequired),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: enabled ? _fill : const Color(0xFFEEF0F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? "Seçiniz",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: !enabled || value == null
                          ? const Color(0xFFB0B7C3)
                          : _ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? _ink : const Color(0xFFC5CAD3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadField({
    required String label,
    required String fileType,
    String? fileName,
    VoidCallback? onTap,
    bool isRequired = false,
  }) {
    final hasFile = fileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, isRequired: isRequired),
        Container(
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                hasFile
                    ? Icons.insert_drive_file_outlined
                    : Icons.upload_file_outlined,
                size: 20,
                color: hasFile ? _brand : _muted,
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Text(
                    fileName ?? "Dosya seçiniz",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: hasFile ? _ink : const Color(0xFFB0B7C3),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasFile)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _brand, size: 20),
                  onPressed: () => _removeFile(fileType),
                ),
              IconButton(
                icon: Icon(
                  hasFile ? Icons.edit_outlined : Icons.add_rounded,
                  color: _brand,
                ),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusChoice(bool active, String label, Color color) {
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
            borderRadius: BorderRadius.circular(11),
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
            color: const Color(0xFF1C2430).withOpacity(0.045),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Yeni Kişi Ekle",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                onPressed: _isSaving ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Kaydet",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C2430).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kayıt durumu",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _muted,
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

              const SizedBox(height: 14),

              _section(
                title: "Kişi türü",
                icon: Icons.badge_outlined,
                children: [
                  _buildDropdown(
                    label: "Kişi Türü",
                    value: _selectedPersonType,
                    onTap: _showPersonTypeModal,
                    isRequired: true,
                  ),
                ],
              ),

              if (_selectedPersonType == "Gayrimenkul Danışmanı" ||
                  _selectedPersonType == "Takım Lideri")
                _section(
                  title: "Danışman seviyesi",
                  icon: Icons.workspace_premium_outlined,
                  children: [
                // Danışman Özelleştir Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Danışman Özelleştir",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDanismanOzellesir,
                        onChanged: (value) {
                          setState(() => _isDanismanOzellesir = value);
                        },
                        activeColor: _brand,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  label: "Danışman Başlangıç Seviyesi",
                  value: _selectedDanismanSeviye,
                  enabled: !_isDanismanOzellesir,
                  onTap: () {
                    _showGenericModal(
                      title: "Danışman Başlangıç Seviyesi",
                      items: _danismanSeviyeleri,
                      selectedValue: _selectedDanismanSeviye,
                      onSelect: (value) {
                        setState(() => _selectedDanismanSeviye = value);
                      },
                    );
                  },
                ),
                if (_isDanismanOzellesir) ...[
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: "Özel Danışman Başlangıç Oranı",
                    value: _selectedCustomRate,
                    onTap: _showCustomRateModal,
                  ),
                ],
                  ],
                ),

              _section(
                title: "Kişisel bilgiler",
                icon: Icons.person_outline_rounded,
                children: [

              _buildTextField(
                label: "Ad",
                controller: _adController,
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Soyad",
                controller: _soyadController,
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Cep Telefonu",
                controller: _telefonController,
                keyboardType: TextInputType.phone,
                isRequired: true,
                hint: "+90 (555) 000-0000",
                inputFormatters: [
                  PhoneNumberFormatter(),
                  LengthLimitingTextInputFormatter(19),
                ],
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "E-posta",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                hint: "ornek@email.com",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-posta adresi gerekli';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi giriniz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildFileUploadField(
                label: "Fotoğraf",
                fileType: "fotograf",
                fileName: _fotografFileName,
        onTap: _showPhotoSourceBottomSheet,
                isRequired: true,
              ),

              // Fotoğraf uyarı metni
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 2),
                child: Text(
                  "Yüksek çözünürlüklü, profesyonel çekim, net ışıklandırma ve beyaz/açık renk arka plan kullanılmalıdır",
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: _muted,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "T.C. Kimlik No",
                controller: _tcController,
                keyboardType: TextInputType.number,
                isRequired: true,
                hint: "12345678901",
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length != 11) {
                    return 'T.C. Kimlik No 11 haneli olmalıdır';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Yabancı Uyruk Checkbox
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isYabanciUyruk,
                      onChanged: (value) {
                        setState(() => _isYabanciUyruk = value ?? false);
                      },
                      activeColor: const Color(0xFFEE2E24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Yabancı Uyruk",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel("Doğum Tarihi (Gün-Ay-Yıl)", isRequired: true),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(1990),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              primaryColor: const Color(0xFFEE2E24),
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFEE2E24),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                              dialogBackgroundColor: Colors.white,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _dogumTarihiController.text =
                              '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: _muted,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _dogumTarihiController.text.isEmpty
                                  ? "GG/AA/YYYY"
                                  : _dogumTarihiController.text,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _dogumTarihiController.text.isEmpty
                                    ? const Color(0xFFB0B7C3)
                                    : _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Doğum Yeri - zorunlu
              _buildDropdown(
                label: "Doğum Yeri",
                value: _selectedDogumYeri,
                isRequired: true,
                onTap: () {
                  if (_isLoadingProvinces) {
                    _showError('İller yükleniyor, lütfen bekleyin');
                    return;
                  }
                  if (_provinces.isEmpty) {
                    _loadProvinces();
                    _showError('İller yükleniyor, lütfen bekleyin');
                    return;
                  }
                  _showGenericModal(
                    title: "Doğum Yeri",
                    items: _provinces.map((p) => p.name).toList(),
                    selectedValue: _selectedDogumYeri,
                    onSelect: (value) {
                      final province =
                          _provinces.firstWhere((p) => p.name == value);
                      setState(() {
                        _selectedDogumYeri = value;
                        _selectedDogumYeriCode = province.code;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Cinsiyet - zorunlu
              _buildDropdown(
                label: "Cinsiyet",
                value: _selectedCinsiyet,
                isRequired: true,
                onTap: () {
                  _showGenericModal(
                    title: "Cinsiyet",
                    items: _cinsiyetler,
                    selectedValue: _selectedCinsiyet,
                    onSelect: (value) {
                      setState(() => _selectedCinsiyet = value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Medeni Durum - zorunlu
              _buildDropdown(
                label: "Medeni Durum",
                value: _selectedMedeniDurum,
                isRequired: true,
                onTap: () {
                  _showGenericModal(
                    title: "Medeni Durum",
                    items: _medeniDurumlar,
                    selectedValue: _selectedMedeniDurum,
                    onSelect: (value) {
                      setState(() => _selectedMedeniDurum = value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Beden - zorunlu
              _buildDropdown(
                label: "Beden",
                value: _selectedBeden,
                isRequired: true,
                onTap: () {
                  _showGenericModal(
                    title: "Beden",
                    items: _bedenler,
                    selectedValue: _selectedBeden,
                    onSelect: (value) {
                      setState(() => _selectedBeden = value);
                    },
                  );
                },
              ),

              ],
              ),

              _section(
                title: "Adres bilgileri",
                icon: Icons.location_on_outlined,
                children: [

              _buildDropdown(
                label: "Ülke",
                value: _selectedCountry,
                onTap: () {
                  if (_isLoadingCountries) {
                    _showError('Ülkeler yükleniyor, lütfen bekleyin');
                    return;
                  }
                  if (_countries.isEmpty) {
                    _showError('Ülkeler bulunamadı');
                    return;
                  }
                  _showGenericModal(
                    title: "Ülke",
                    items: _countries.map((c) => c.name).toList(),
                    selectedValue: _selectedCountry,
                    onSelect: (value) {
                      final country =
                          _countries.firstWhere((c) => c.name == value);
                      setState(() {
                        _selectedCountry = value;
                        _selectedCountryCode = country.code;
                        // Ülke değiştiğinde il, ilçe, mahalle sıfırla
                        _selectedCity = null;
                        _selectedCityCode = null;
                        _selectedDistrict = null;
                        _selectedNeighborhood = null;
                        _provinces = [];
                        _districts = [];
                        _quarters = [];
                      });
                      // Türkiye seçildiyse illeri yükle
                      if (country.code == 'TR') {
                        _loadProvinces();
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: "İl",
                value: _selectedCity,
                isRequired: true,
                onTap: () {
                  if (_selectedCountryCode == null) {
                    _showError('Önce ülke seçiniz');
                    return;
                  }
                  // Türkiye dışında bir ülke seçildiyse il seçimi yapılamaz
                  if (_selectedCountryCode != 'TR') {
                    _showError('Sadece Türkiye için il seçimi yapılabilir');
                    return;
                  }
                  if (_isLoadingProvinces) {
                    _showError('İller yükleniyor, lütfen bekleyin');
                    return;
                  }
                  if (_provinces.isEmpty) {
                    _showError('İller bulunamadı');
                    return;
                  }
                  _showGenericModal(
                    title: "İl",
                    items: _provinces.map((p) => p.name).toList(),
                    selectedValue: _selectedCity,
                    onSelect: (value) {
                      final province =
                          _provinces.firstWhere((p) => p.name == value);
                      setState(() {
                        _selectedCity = value;
                        _selectedCityCode = province.code;
                      });
                      _loadDistricts(province.code);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: "İlçe",
                value: _selectedDistrict,
                isRequired: true,
                onTap: () {
                  if (_selectedCityCode == null) {
                    _showError('Önce il seçiniz');
                    return;
                  }
                  if (_isLoadingDistricts) {
                    _showError('İlçeler yükleniyor, lütfen bekleyin');
                    return;
                  }
                  if (_districts.isEmpty) {
                    _showError('İlçeler bulunamadı');
                    return;
                  }
                  _showGenericModal(
                    title: "İlçe",
                    items: _districts.map((d) => d.name).toList(),
                    selectedValue: _selectedDistrict,
                    onSelect: (value) {
                      final district =
                          _districts.firstWhere((d) => d.name == value);
                      setState(() => _selectedDistrict = value);
                      _loadQuarters(district);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: "Mahalle",
                value: _selectedNeighborhood,
                isRequired: true,
                onTap: () {
                  if (_selectedDistrict == null) {
                    _showError('Önce ilçe seçiniz');
                    return;
                  }
                  if (_isLoadingQuarters) {
                    _showError('Mahalleler yükleniyor, lütfen bekleyin');
                    return;
                  }
                  if (_quarters.isEmpty) {
                    _showError('Mahalleler bulunamadı');
                    return;
                  }
                  _showGenericModal(
                    title: "Mahalle",
                    items: _quarters.map((q) => q.name).toList(),
                    selectedValue: _selectedNeighborhood,
                    onSelect: (value) {
                      setState(() => _selectedNeighborhood = value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Adres",
                controller: _adresController,
                maxLines: 4,
                isRequired: true,
              ),

              ],
              ),

              _section(
                title: "Sosyal medya",
                icon: Icons.share_outlined,
                children: [

              _buildTextField(
                label: "Instagram",
                controller: _instagramController,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Facebook",
                controller: _facebookController,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "X",
                controller: _xController,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Linkedin",
                controller: _linkedinController,
              ),

              ],
              ),

              _section(
                title: "Meslek ve eğitim",
                icon: Icons.school_outlined,
                children: [

              _buildDropdown(
                label: "Meslek",
                value: _selectedMeslek,
                onTap: () {
                  _showGenericModal(
                    title: "Meslek",
                    items: _meslekler,
                    selectedValue: _selectedMeslek,
                    onSelect: (value) {
                      setState(() => _selectedMeslek = value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Deneyimi",
                controller: _deneyimController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              _buildDropdown(
                label: "Eğitim Durumu",
                value: _selectedEgitimDurumu,
                isRequired: true,
                onTap: () {
                  _showGenericModal(
                    title: "Eğitim Durumu",
                    items: _egitimDurumlari,
                    selectedValue: _selectedEgitimDurumu,
                    onSelect: (value) {
                      setState(() => _selectedEgitimDurumu = value);
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Geçmiş İş Tecrübeleri",
                controller: _gecmisIsController,
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Hakkımda",
                controller: _hakkimdaController,
                maxLines: 5,
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Referanslar",
                controller: _referansController,
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                label: "Firmamızı nereden duydunuz?",
                controller: _nerdenDuyduController,
              ),

              ],
              ),

              _section(
                title: "Belgeler",
                icon: Icons.folder_open_outlined,
                children: [

              _buildFileUploadField(
                label: "Diploma",
                fileType: "diploma",
                fileName: _diplomaFileName,
                onTap: () => _pickFile('diploma'),
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildFileUploadField(
                label: "Adli Sicil Kaydı",
                fileType: "adliSicil",
                fileName: _adliSicilFileName,
                onTap: () => _pickFile('adliSicil'),
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildFileUploadField(
                label: "Mesleki Yeterlilik Belgesi",
                fileType: "meslekiBelge",
                fileName: _meslekiBelgeFileName,
                onTap: () => _pickFile('meslekiBelge'),
                isRequired: true,
              ),

              const SizedBox(height: 16),

              _buildFileUploadField(
                label: "Taşınmaz Ticari Yetki Belgesi",
                fileType: "tasinmazBelge",
                fileName: _tasinmazBelgeFileName,
                onTap: () => _pickFile('tasinmazBelge'),
              ),

              const SizedBox(height: 24),

              // Kampanya iletişim izni
              Row(
                children: [
                  Checkbox(
                    value: _kampanyaIzni,
                    onChanged: (value) {
                      setState(() => _kampanyaIzni = value ?? false);
                    },
                    activeColor: const Color(0xFFEE2E24),
                  ),
                  const Expanded(
                    child: Text(
                      "Kampanya iletişim izni verilsin.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
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
