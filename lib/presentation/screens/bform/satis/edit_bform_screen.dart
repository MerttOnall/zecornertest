import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/contact/ref_education_model.dart';
import 'package:zecorner/models/contact/ref_profession_model.dart';
import 'package:zecorner/models/province/provinces_model.dart';
import 'package:zecorner/models/province/provinces_detail_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';

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

class EditBformScreen extends StatefulWidget {
  const EditBformScreen({super.key});

  @override
  State<EditBformScreen> createState() => _EditBformScreenState();
}

class _EditBformScreenState extends State<EditBformScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContactApiRepository _contactRepository = ContactApiRepository();

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Dropdown values
  String? _selectedEducation;
  String? _selectedProfession;
  String? _selectedProvince;
  String? _selectedDistrict;

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

  // Bform data
  BformApiModel? _bform;
  bool _isFormPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _surnameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadReferenceData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bform == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is BformApiModel) {
        _bform = args;
        // Reference data yüklendikten sonra formu doldur
        if (!_isLoadingRefData && !_isFormPopulated) {
          _populateForm(_bform!);
        }
      }
    }
  }

  void _populateForm(BformApiModel bform) {
    if (_isFormPopulated) return; // Zaten doldurulduysa tekrar doldurma
    
    _nameController.text = bform.name;
    _surnameController.text = bform.surname;
    _phoneController.text = _formatPhoneForDisplay(bform.phone);
    _emailController.text = bform.mail;
    
    // Parse districtText to get province and district
    // Format: "İl, İlçe, Mahalle" or similar
    if (bform.districtText.isNotEmpty) {
      final parts = bform.districtText.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        final provinceName = parts[0];
        final districtName = parts[1];
        
        // Provinces listesi yüklendiyse eşleştir
        if (_provinces.isNotEmpty) {
          final matchedProvince = _provinces.firstWhere(
            (p) => p.name == provinceName,
            orElse: () => ProvinceModel(code: 0, name: ''),
          );
          if (matchedProvince.name == provinceName) {
            _selectedProvince = provinceName;
            // Districts yüklendikten sonra district'i set edeceğiz
            _loadDistrictsForProvince(provinceName).then((_) {
              if (_districts.isNotEmpty && mounted) {
                final matchedDistrict = _districts.firstWhere(
                  (d) => d.name == districtName,
                  orElse: () => DistrictModel(code: 0, name: '', quarters: []),
                );
                if (matchedDistrict.name == districtName) {
                  setState(() {
                    _selectedDistrict = districtName;
                  });
                }
              }
            });
          }
        } else {
          // Provinces henüz yüklenmediyse, sadece isimleri kaydet
          _selectedProvince = provinceName;
          _selectedDistrict = districtName;
        }
      } else if (parts.length == 1) {
        _selectedProvince = parts[0];
      }
    }

    // Set checkboxes to true (assuming they were accepted when form was created)
    _acceptTerms = true;
    _acceptKvkk = true;

    _isFormPopulated = true;
    setState(() {});
    
    // Load districts if province is set and provinces are loaded
    if (_selectedProvince != null && _provinces.isNotEmpty) {
      _loadDistrictsForProvince(_selectedProvince!);
    }
  }

  String _formatPhoneForDisplay(String phone) {
    if (phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return phone;
    final withoutCountry = digits.length == 12 && digits.startsWith('90')
        ? digits.substring(2)
        : digits.length == 11 && digits.startsWith('0')
            ? digits.substring(1)
            : digits.length >= 10
                ? digits.substring(digits.length - 10)
                : digits;
    if (withoutCountry.length == 10) {
      return '+90 (${withoutCountry.substring(0, 3)}) ${withoutCountry.substring(3, 6)}-${withoutCountry.substring(6)}';
    }
    return phone;
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

        // Bform varsa formu doldur
        if (_bform != null) {
          _populateForm(_bform!);
        } else {
          // Bform henüz yüklenmediyse, didChangeDependencies'den gelecek
          // Ama yine de province varsa districts'i yükle
          if (_selectedProvince != null && _provinces.isNotEmpty) {
            _loadDistrictsForProvince(_selectedProvince!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRefData = false;
        });
      }
    }
  }

  Future<void> _loadDistrictsForProvince(String provinceName) async {
    try {
      final province = _provinces.firstWhere(
        (p) => p.name == provinceName,
        orElse: () => _provinces.first,
      );

      // Eğer province bulunamadıysa, işlemi durdur
      if (province.name != provinceName) {
        return;
      }

      setState(() {
        _isLoadingDistricts = true;
        // Sadece district'i temizle, province'i koru
        if (_selectedProvince != provinceName) {
          _districts = [];
          _selectedDistrict = null;
        }
      });

      final result = await _contactRepository.getDistrictsByProvince(province.code);

      if (mounted) {
        result.fold(
          (failure) {
            setState(() {
              _isLoadingDistricts = false;
            });
          },
          (response) {
            setState(() {
              _districts = response.districts;
              _isLoadingDistricts = false;
              
              // Try to restore selected district from bform
              if (_bform != null && _bform!.districtText.isNotEmpty) {
                final parts = _bform!.districtText.split(',').map((e) => e.trim()).toList();
                if (parts.length >= 2 && parts[0] == provinceName) {
                  final districtName = parts[1];
                  final foundDistrict = _districts.firstWhere(
                    (d) => d.name == districtName,
                    orElse: () => DistrictModel(code: 0, name: '', quarters: []),
                  );
                  if (foundDistrict.name.isNotEmpty) {
                    _selectedDistrict = districtName;
                  }
                }
              }
            });
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad alanı zorunludur';
    }
    return null;
  }

  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Soyad alanı zorunludur';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '+90 ') {
      return 'Telefon numarası zorunludur';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Geçerli bir telefon numarası giriniz';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta adresi zorunludur';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Geçerli bir e-posta adresi giriniz';
    }
    return null;
  }

  String? _validateDropdown(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName seçimi zorunludur';
    }
    return null;
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms || !_acceptKvkk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen kullanım koşullarını ve KVKK metnini kabul ediniz'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }

      // TODO: Implement API call to update bform
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başvuru başarıyla güncellendi!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelAppBar(
        title: "Başvuru Formu Düzenle",
        onMenuPressed: () => Navigator.of(context).pop(),
      ),
      body: _isLoadingRefData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                        "Zecorner Satış Talepleri Başvuru Formu",
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

                    _buildFormField(
                      label: 'Telefon Numaranız',
                      controller: _phoneController,
                      hintText: '+90 (555) 000-0000',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      inputFormatters: [
                        PhoneNumberFormatter(),
                        LengthLimitingTextInputFormatter(19),
                      ],
                    ),
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
                      label: 'Eğitim Durumunuz',
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

                    // Submit button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE53935),
                            Color(0xFFD32F2F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Güncelle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator,
            isExpanded: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? const Color(0xFF2C3E50) : Colors.grey,
            ),
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
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
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

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        activeColor: const Color(0xFFE53935),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            children: [
              TextSpan(
                text: title,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: subtitle,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
