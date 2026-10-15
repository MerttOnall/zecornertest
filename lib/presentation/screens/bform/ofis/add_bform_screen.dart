import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/models/contact/ref_education_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:dio/dio.dart';

class AddBformScreen extends StatefulWidget {
  const AddBformScreen({super.key});

  @override
  State<AddBformScreen> createState() => _AddBformScreenState();
}

class _AddBformScreenState extends State<AddBformScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContactApiRepository _contactRepository = ContactApiRepository();
  final BformApiRepository _bformRepository = BformApiRepository(dio: Dio());

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Dropdown values (storing descriptions, will convert to UUIDs)
  String? _selectedEducation; // Education description
  String? _selectedProfession; // Profession description
  String? _selectedProvince; // Province name
  String? _selectedDistrict; // District name

  // Checkboxes
  bool _acceptTerms = false;
  bool _acceptKvkk = false;

  // Reference data
  List<RefEducationModel> _educations = [];
  List<RefProfessionModel> _professions = [];
  List<ProvinceModel> _provinces = [];
  List<DistrictModel> _districts = [];
  bool _isLoadingRefData = true;
  bool _isLoadingDistricts = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _phoneController = TextEditingController(text: '+90 ');
    _emailController = TextEditingController();
    _loadReferenceData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    try {
      setState(() {
        _isLoadingRefData = true;
      });

      final results = await Future.wait([
        _contactRepository.getEducations(),
        _contactRepository.getProfessions(),
        _contactRepository.getProvinces(),
      ]);

      if (mounted) {
        setState(() {
          // Educations
          if (results[0].isRight()) {
            final educationsResult = results[0].fold<RefEducationResponseModel?>(
              (l) => null,
              (r) => r as RefEducationResponseModel,
            );
            if (educationsResult != null) {
              _educations = educationsResult.educations;
            }
          }

          // Professions
          if (results[1].isRight()) {
            final professionsResult = results[1].fold<RefProfessionResponseModel?>(
              (l) => null,
              (r) => r as RefProfessionResponseModel,
            );
            if (professionsResult != null) {
              _professions = professionsResult.professions;
            }
          }

          // Provinces
          if (results[2].isRight()) {
            final provincesResult = results[2].fold<ProvincesResponseModel?>(
              (l) => null,
              (r) => r as ProvincesResponseModel,
            );
            if (provincesResult != null) {
              _provinces = provincesResult.provinces;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDistrictsForProvince(String provinceName) async {
    try {
      setState(() {
        _isLoadingDistricts = true;
      });

      final province = _provinces.firstWhere(
        (p) => p.name == provinceName,
        orElse: () => ProvinceModel(code: 0, name: ''),
      );

      if (province.code != 0) {
        final result = await _contactRepository.getDistrictsByProvince(province.code);

        if (mounted) {
          result.fold(
            (failure) {
              setState(() {
                _isLoadingDistricts = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('İlçeler yüklenirken hata oluştu: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (response) {
              setState(() {
                _districts = response.districts;
                _isLoadingDistricts = false;
              });
            },
          );
        }
      } else {
        setState(() {
          _isLoadingDistricts = false;
        });
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Adınızı giriniz';
    }
    if (value.trim().length < 2) {
      return 'Ad en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Soyadınızı giriniz';
    }
    if (value.trim().length < 2) {
      return 'Soyad en az 2 karakter olmalıdır';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numaranızı giriniz';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Geçerli bir telefon numarası giriniz';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresinizi giriniz';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName seçiniz';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yasal Uyarılar ve Kullanım Koşulları\'nı kabul etmelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_acceptKvkk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KVKK Aydınlatma Metni\'ni kabul etmelisiniz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert dropdown selections to UUIDs/codes and descriptions
      String? educationUuid;
      String? educationDescription;
      if (_selectedEducation != null && _selectedEducation!.isNotEmpty) {
        try {
          final education = _educations.firstWhere(
            (e) => e.description == _selectedEducation,
          );
          educationUuid = education.code; // code is the UUID
          educationDescription = education.description;
        } catch (e) {
          print('⚠️ Education not found: $_selectedEducation');
        }
      }

      String? professionUuid;
      String? professionDescription;
      if (_selectedProfession != null && _selectedProfession!.isNotEmpty) {
        try {
          final profession = _professions.firstWhere(
            (p) => p.description == _selectedProfession,
          );
          professionUuid = profession.code; // code is the UUID
          professionDescription = profession.description;
        } catch (e) {
          print('⚠️ Profession not found: $_selectedProfession');
        }
      }

      // Get province and district codes
      int? provinceCode;
      if (_selectedProvince != null && _selectedProvince!.isNotEmpty) {
        final province = _provinces.firstWhere(
          (p) => p.name == _selectedProvince,
          orElse: () => ProvinceModel(code: 0, name: ''),
        );
        provinceCode = province.code != 0 ? province.code : null;
      }

      int? districtCode;
      if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty && _districts.isNotEmpty) {
        final district = _districts.firstWhere(
          (d) => d.name == _selectedDistrict,
          orElse: () => DistrictModel(code: 0, name: '', quarters: []),
        );
        districtCode = district.code != 0 ? district.code : null;
      }

      // Telefon numarasını API formatına çevir: +90 (XXX) XXX XXXX
      // API'deki kayıtlı veriler bu formatta: "+90 (532) 731 5229"
      String phoneText = _phoneController.text.trim();
      
      // Sadece rakamları al, doğrulama için
      String digitsOnly = phoneText.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.startsWith('90') && digitsOnly.length > 2) {
        digitsOnly = digitsOnly.substring(2);
      }
      
      // Phone validation - should be 10 digits (without country code)
      if (digitsOnly.length != 10) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telefon numarası 10 haneli olmalıdır (örn: 5551234567)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // API formatı: +90 (XXX) XXX XXXX (tire yerine boşluk)
      final formattedPhone = '+90 (${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6, 10)}';

      print('📞 Phone: $formattedPhone');
      print('📧 Email: ${_emailController.text.trim()}');
      print('👤 Name: ${_nameController.text.trim()}');
      print('👤 Surname: ${_surnameController.text.trim()}');
      print('🎓 Education UUID: $educationUuid');
      print('💼 Profession UUID: $professionUuid');
      print('🏙️ Province Code: $provinceCode');
      print('📍 District Code: $districtCode');

      // Call API
      final result = await _bformRepository.createBform(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phone: formattedPhone,
        education: educationUuid,
        educationDescription: educationDescription,
        profession: professionUuid,
        professionDescription: professionDescription,
        provinceCode: provinceCode,
        districtCode: districtCode,
        formType: 'office',
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          },
          (bform) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Başvuru başarıyla oluşturuldu'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Return true to indicate success
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bir hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onMapPressed() {
    // TODO: Map functionality will be added here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Harita özelliği yakında eklenecek'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelAppBar(
        title: "Başvuru Formu Ekle",
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: _isLoadingRefData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 100, // Bottom padding for buttons
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Zecorner Ofis/Broker Başvuru Formu",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form fields
                    _buildFormField(
                      label: 'Adınız',
                      controller: _nameController,
                      hintText: 'Adınızı giriniz',
                      icon: Icons.person_outline,
                      validator: _validateName,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\s]')),
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'Soyadınız',
                      controller: _surnameController,
                      hintText: 'Soyadınızı giriniz',
                      icon: Icons.person_outline,
                      validator: _validateSurname,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZğüşıöçĞÜŞİÖÇ\s]')),
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildPhoneField(),
                    const SizedBox(height: 16),

                    _buildFormField(
                      label: 'E-posta Adresiniz',
                      controller: _emailController,
                      hintText: 'ornek@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        LengthLimitingTextInputFormatter(100),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'Eğitim Durunuz',
                      value: _selectedEducation,
                      items: _educations.map((e) => e.description).toList(),
                      onChanged: (v) => setState(() => _selectedEducation = v),
                      icon: Icons.school_outlined,
                      validator: null, // Opsiyonel alan
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'Mesleğiniz',
                      value: _selectedProfession,
                      items: _professions.map((p) => p.description).toList(),
                      onChanged: (v) => setState(() => _selectedProfession = v),
                      icon: Icons.work_outline,
                      validator: null, // Opsiyonel alan
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'İl',
                      value: _selectedProvince,
                      items: _provinces.map((p) => p.name).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedProvince = v;
                          _selectedDistrict = null;
                          _districts = [];
                        });
                        if (v != null) {
                          _loadDistrictsForProvince(v);
                        }
                      },
                      icon: Icons.location_city_outlined,
                      validator: (value) => _validateDropdown(value, 'İl'),
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      label: 'İlçe',
                      value: _selectedDistrict,
                      items: _districts.map((d) => d.name).toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v),
                      icon: Icons.location_on_outlined,
                      validator: (value) => _validateDropdown(value, 'İlçe'),
                      enabled: _selectedProvince != null && !_isLoadingDistricts,
                    ),
                    const SizedBox(height: 20),

                    // Checkboxes
                    _buildCheckbox(
                      value: _acceptTerms,
                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      title: 'Yasal Uyarılar ve Kullanım Koşulları',
                      subtitle: "'nı okudum ve kabul ediyorum.",
                    ),
                    const SizedBox(height: 12),

                    _buildCheckbox(
                      value: _acceptKvkk,
                      onChanged: (v) => setState(() => _acceptKvkk = v ?? false),
                      title: 'KVKK Aydınlatma Metni',
                      subtitle: "'ni okudum ve kabul ediyorum.",
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Harita Button - Modern outline style
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                    color: Colors.white,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _onMapPressed,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Harita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Oluştur Button - Modern gradient with icon
              Expanded(
                flex: 2,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE53935),
                        Color(0xFFD32F2F),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _onSubmit,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Oluştur',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: inputFormatters,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.grey[500],
                size: 20,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telefon Numaranız',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()\-]')),
              LengthLimitingTextInputFormatter(19),
            ],
            onChanged: (value) {
              _formatPhoneNumber(value);
            },
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
            decoration: InputDecoration(
              hintText: '+90 (555) 000-0000',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Colors.grey,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _formatPhoneNumber(String value) {
    // Sadece rakamları al
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // Eğer 90 ile başlıyorsa, onu kaldır (çünkü +90 zaten var)
    if (digitsOnly.startsWith('90') && digitsOnly.length > 2) {
      digitsOnly = digitsOnly.substring(2);
    }
    
    // Maksimum 10 rakam
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }
    
    // Eğer hiç rakam yoksa, sadece +90 göster
    if (digitsOnly.isEmpty) {
      if (_phoneController.text != '+90 ') {
        _phoneController.value = const TextEditingValue(
          text: '+90 ',
          selection: TextSelection.collapsed(offset: 4),
        );
      }
      return;
    }
    
    // Format: +90 (555) 000-0000
    final buffer = StringBuffer('+90 ');
    
    // İlk 3 rakam (alan kodu)
    buffer.write('(');
    for (int i = 0; i < digitsOnly.length && i < 3; i++) {
      buffer.write(digitsOnly[i]);
    }
    buffer.write(')');
    
    if (digitsOnly.length > 3) {
      buffer.write(' ');
      // Sonraki 3 rakam
      for (int i = 3; i < digitsOnly.length && i < 6; i++) {
        buffer.write(digitsOnly[i]);
      }
    }
    
    if (digitsOnly.length > 6) {
      buffer.write('-');
      // Son 4 rakam
      for (int i = 6; i < digitsOnly.length && i < 10; i++) {
        buffer.write(digitsOnly[i]);
      }
    }
    
    final formatted = buffer.toString();
    
    // Eğer formatlanmış text mevcut text'ten farklıysa güncelle
    if (_phoneController.text != formatted) {
      // Cursor pozisyonunu hesapla - rakam sayısına göre
      int newCursorPosition = formatted.length;
      
      // Eğer karakter eklendiyse, sona koy
      // Eğer karakter silindiyse, uygun pozisyona koy
      if (digitsOnly.length <= 3) {
        newCursorPosition = 4 + 1 + digitsOnly.length; // +90 (XXX
      } else if (digitsOnly.length <= 6) {
        newCursorPosition = 4 + 1 + 3 + 1 + 1 + (digitsOnly.length - 3); // +90 (XXX) XXX
      } else {
        newCursorPosition = 4 + 1 + 3 + 1 + 1 + 3 + 1 + (digitsOnly.length - 6); // +90 (XXX) XXX-XXXX
      }
      
      // Cursor pozisyonunu sınırla
      newCursorPosition = newCursorPosition.clamp(0, formatted.length);
      
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? const Color(0xFF2C3E50) : Colors.grey[400],
                  ),
                ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: 'Seçiniz',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.grey[500],
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            dropdownColor: Colors.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[500],
            ),
            style: TextStyle(
              fontSize: 16,
              color: enabled ? const Color(0xFF2C3E50) : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE53935),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: subtitle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
