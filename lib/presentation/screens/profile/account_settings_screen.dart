import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:ui';
import '../../../core/utils/image_utils.dart';
import '../../../infrastructure/contact/contact_api_repository.dart';
import '../../../models/contact/ref_profession_model.dart';
import '../../../models/users/user_profile_model.dart';
import '../../../services/user_profile_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;

  int _currentIndex = 4; // Profile tab index

  // Services
  final UserProfileService _userProfileService = UserProfileService();

  // User profile data
  UserProfileModel? _userProfile;
  bool _isLoading = false;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _ttbsController = TextEditingController();

  // Dropdown values
  String _selectedCity = 'İSTANBUL';
  String _selectedDistrict = 'Ataşehir';
  String _selectedNeighborhood = 'Barbaros Mah.';
  String _selectedDiploma = 'Lisans';

  final ContactApiRepository _contactRepository = ContactApiRepository();
  List<RefProfessionModel> _professions = [];
  String? _selectedProfessionCode;

  // Document upload states
  bool _isDiplomaUploaded = false;
  bool _isCriminalRecordUploaded = false;
  bool _isProfessionalCertificateUploaded = false;
  bool _isRealEstatePermitUploaded = false;
  bool _isIdFrontUploaded = false;
  bool _isIdBackUploaded = false;
  bool _isContractUploaded = false;

  // Document file references
  File? _diplomaFile;
  File? _criminalRecordFile;
  File? _professionalCertificateFile;
  File? _realEstatePermitFile;
  File? _idFrontFile;
  File? _idBackFile;
  File? _contractFile;

  String? _diplomaFileId;
  String? _criminalRecordFileId;
  String? _professionalCertificateFileId;
  String? _realEstatePermitFileId;
  String? _idFrontFileId;
  String? _idBackFileId;
  String? _contractFileId;

  List<Map<String, dynamic>> _existingAttachments = [];

  // Privacy settings
  bool _allowCompanyContact = false;

  // Selected profile image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Cities and districts data
  final List<String> _cities = [
    'İSTANBUL',
    'ANKARA',
    'İZMİR',
    'BURSA',
    'ANTALYA',
    'ADANA',
    'KONYA',
    'GAZİANTEP',
  ];

  final Map<String, List<String>> _districts = {
    'İSTANBUL': [
      'Ataşehir',
      'Kadıköy',
      'Beşiktaş',
      'Şişli',
      'Üsküdar',
      'Maltepe'
    ],
    'ANKARA': ['Çankaya', 'Keçiören', 'Yenimahalle', 'Mamak', 'Altındağ'],
    'İZMİR': ['Konak', 'Bornova', 'Karşıyaka', 'Buca', 'Çiğli'],
  };

  final Map<String, List<String>> _neighborhoods = {
    'Ataşehir': ['Barbaros Mah.', 'Küçükbakkalköy Mah.', 'Ferhatpaşa Mah.'],
    'Kadıköy': ['Moda Mah.', 'Fenerbahçe Mah.', 'Göztepe Mah.'],
    'Beşiktaş': ['Levent Mah.', 'Etiler Mah.', 'Ortaköy Mah.'],
  };

  final List<String> _diplomaOptions = [
    'Lise',
    'Ön Lisans',
    'Lisans',
    'Yüksek Lisans',
    'Doktora',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // Animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Animations
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _professionController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _linkedinController.dispose();
    _ttbsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bilgileri Güncelle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            )
          : Stack(
              children: [
                // Animated Background
                _buildAnimatedBackground(),

                // Main Content
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Profile Section
                  _buildProfileSection(),

                  const SizedBox(height: 24),

                  // Personal Information Section
                  _buildPersonalInfoSection(),

                  const SizedBox(height: 24),

                  // Contact Information Section
                  _buildContactInfoSection(),

                  const SizedBox(height: 24),

                  // About Section
                  _buildAboutSection(),

                  const SizedBox(height: 24),

                  // Social Media Section
                  _buildSocialMediaSection(),

                  const SizedBox(height: 24),

                  _buildDocumentsSection(),

                  const SizedBox(height: 24),

                  // Education Section
                  _buildEducationSection(),

                  const SizedBox(height: 24),

                  // Privacy & Security Section
                  _buildPrivacySection(),

                  const SizedBox(height: 32),

                  // Update Button
                  _buildUpdateButton(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBFB),
            Color(0xFFFFF5F5),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Rotating circles
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 150.0) % MediaQuery.of(context).size.width,
                  top: 50 + (index * 200.0) % 600,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value + (index * 0.5),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE53935).withOpacity(0.05),
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Floating particles
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 80.0) % MediaQuery.of(context).size.width,
                  top: 150 + (index * 100.0) % 500 + _floatingAnimation.value,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withOpacity(0.1),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Kişisel Bilgileriniz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Profile Picture
          Stack(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              )
                            : _userProfile != null &&
                                    _userProfile!.detail.picture != null &&
                                    ImageUtils.isValidS3Id(
                                        _userProfile!.detail.picture)
                                ? Image.network(
                                    ImageUtils.getS3FileUrl(
                                        _userProfile!.detail.picture),
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFFE53935)),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Image.asset(
                                    'assets/images/profile.jpg',
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ),
                  );
                },
              ),

              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _pickImageFromGallery,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            '${_nameController.text} ${_surnameController.text}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            (_userProfile?.typeDescription.trim().isNotEmpty ?? false)
                ? _userProfile!.typeDescription
                : _professionController.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kişisel Bilgileriniz',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Name and Surname Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _nameController,
                  label: 'Adınız',
                  hint: 'Adınızı girin',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _surnameController,
                  label: 'Soyadınız',
                  hint: 'Soyadınızı girin',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Meslek (web: dropdown)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    'Meslek',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Color.fromRGBO(238, 46, 36, 1),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_professions.isNotEmpty)
                _buildDropdown(
                  value: _professionDropdownValue(),
                  items: _professionLabels(),
                  isRequired: true,
                  label: 'Meslek',
                  onChanged: (value) {
                    if (value == null) return;
                    RefProfessionModel? match;
                    for (final p in _professions) {
                      if (p.description == value) {
                        match = p;
                        break;
                      }
                    }
                    setState(() {
                      _selectedProfessionCode = match?.code;
                      _professionController.text = value;
                    });
                  },
                )
              else
                _buildTextField(
                  controller: _professionController,
                  label: 'Meslek',
                  hint: 'Mesleğinizi girin',
                  isRequired: false,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İletişim Bilgileriniz',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Phone Number
          _buildTextField(
            controller: _phoneController,
            label: 'Telefon Numaranız',
            hint: '+90 (___) ___-____',
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          // City and District Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'İl',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Color.fromRGBO(238, 46, 36, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _cities.contains(_selectedCity) ? _selectedCity : _cities.first,
                      items: _cities,
                      isRequired: true,
                      label: 'İl',
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value!;
                          _selectedDistrict = _districts[value]?.first ?? '';
                          _selectedNeighborhood =
                              _neighborhoods[_selectedDistrict]?.first ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'İlçe',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(
                            color: Color.fromRGBO(238, 46, 36, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: (_districts[_selectedCity] ?? []).contains(_selectedDistrict) 
                          ? _selectedDistrict 
                          : (_districts[_selectedCity] ?? []).isNotEmpty 
                              ? (_districts[_selectedCity] ?? []).first 
                              : '',
                      items: _districts[_selectedCity] ?? [],
                      isRequired: true,
                      label: 'İlçe',
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value!;
                          _selectedNeighborhood =
                              _neighborhoods[value]?.first ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Neighborhood
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Mahalle',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Color.fromRGBO(238, 46, 36, 1),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: (_neighborhoods[_selectedDistrict] ?? []).contains(_selectedNeighborhood) 
                    ? _selectedNeighborhood 
                    : (_neighborhoods[_selectedDistrict] ?? []).isNotEmpty 
                        ? (_neighborhoods[_selectedDistrict] ?? []).first 
                        : '',
                items: _neighborhoods[_selectedDistrict] ?? [],
                isRequired: true,
                label: 'Mahalle',
                onChanged: (value) {
                  setState(() {
                    _selectedNeighborhood = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Address
          _buildTextField(
            controller: _addressController,
            label: 'Adresiniz',
            hint: 'Detaylı adresinizi girin',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danışman Bilgileri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Mobil için sade açıklama alanı (web toolbar kaldırıldı)
          _buildTextField(
            controller: _aboutController,
            label: 'Hakkımda',
            hint: 'Kendiniz hakkında kısa bir açıklama yazın...',
            maxLines: 6,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sosyal Medya Hesapları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Facebook Profile
          _buildSocialMediaField(
            controller: _facebookController,
            label: 'Facebook Profili',
            hint: 'Facebook profil linkinizi girin',
            icon: Icons.facebook,
            color: const Color(0xFF1877F2),
          ),

          const SizedBox(height: 16),

          // Instagram Profile
          _buildSocialMediaField(
            controller: _instagramController,
            label: 'Instagram Profili',
            hint: 'Instagram profil linkinizi girin',
            icon: Icons.camera_alt,
            color: const Color(0xFFE4405F),
          ),

          const SizedBox(height: 16),

          // X Profile
          _buildSocialMediaField(
            controller: _xController,
            label: 'X Profili',
            hint: 'X (Twitter) profil linkinizi girin',
            icon: Icons.close,
            color: const Color(0xFF000000),
          ),

          const SizedBox(height: 16),

          // LinkedIn Profile
          _buildSocialMediaField(
            controller: _linkedinController,
            label: 'LinkedIn Profili',
            hint: 'LinkedIn profil linkinizi girin',
            icon: Icons.work,
            color: const Color(0xFF0A66C2),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: color,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Eğitim Bilgileri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Diploma Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Diploma',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Color.fromRGBO(238, 46, 36, 1),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _diplomaOptions.contains(_selectedDiploma) ? _selectedDiploma : _diplomaOptions.first,
                  isExpanded: true,
                  underline: Container(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  dropdownColor: Colors.white,
                  items: _diplomaOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDiploma = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Belgeler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _ttbsController,
            label: 'TTBS Numarası',
            hint: 'TTBS numaranızı girin',
            keyboardType: TextInputType.number,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Nüfus Cüzdanı Ön',
            isUploaded: _isIdFrontUploaded,
            onTap: () => _selectFile('id_front'),
            onRemove: () => _removeFile('id_front'),
            uploadedFile: _idFrontFile,
            existingFileId: _idFrontFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Nüfus Cüzdanı Arka',
            isUploaded: _isIdBackUploaded,
            onTap: () => _selectFile('id_back'),
            onRemove: () => _removeFile('id_back'),
            uploadedFile: _idBackFile,
            existingFileId: _idBackFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Sözleşme',
            isUploaded: _isContractUploaded,
            onTap: () => _selectFile('contract'),
            onRemove: () => _removeFile('contract'),
            uploadedFile: _contractFile,
            existingFileId: _contractFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Diploma',
            isUploaded: _isDiplomaUploaded,
            onTap: () => _selectFile('diploma'),
            onRemove: () => _removeFile('diploma'),
            uploadedFile: _diplomaFile,
            existingFileId: _diplomaFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Adli Sicil Kaydı',
            isUploaded: _isCriminalRecordUploaded,
            onTap: () => _selectFile('criminal_record'),
            onRemove: () => _removeFile('criminal_record'),
            uploadedFile: _criminalRecordFile,
            existingFileId: _criminalRecordFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Mesleki Yeterlilik Belgesi',
            isUploaded: _isProfessionalCertificateUploaded,
            onTap: () => _selectFile('professional_certificate'),
            onRemove: () => _removeFile('professional_certificate'),
            uploadedFile: _professionalCertificateFile,
            existingFileId: _professionalCertificateFileId,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(
            title: 'Taşınmaz Ticari Yetki Belgesi',
            isUploaded: _isRealEstatePermitUploaded,
            onTap: () => _selectFile('real_estate_permit'),
            onRemove: () => _removeFile('real_estate_permit'),
            uploadedFile: _realEstatePermitFile,
            existingFileId: _realEstatePermitFileId,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadSection({
    required String title,
    required bool isUploaded,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    File? uploadedFile,
    String? existingFileId,
    bool isRequired = true,
  }) {
    final hasExisting =
        existingFileId != null && existingFileId.trim().isNotEmpty;
    final hasAny = isUploaded || hasExisting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAny ? Colors.green : Colors.grey[300]!,
              width: hasAny ? 2 : 1,
              style: BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasAny ? Icons.check_circle : Icons.cloud_upload_outlined,
                  size: 40,
                  color: hasAny ? Colors.green : Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  hasAny ? 'Dosya yüklendi' : 'Dosya seçiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasAny ? Colors.green : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUploaded && uploadedFile != null) ...[
                  Text(
                    uploadedFile.path.split('/').last,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'PDF, JPG, PNG (Max 5MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (hasAny) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.attach_file,
                size: 16,
                color: Color(0xFFE53935),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: hasExisting
                      ? () => _downloadDocument(existingFileId)
                      : null,
                  child: Text(
                    uploadedFile?.path.split('/').last ?? 'Belgeyi indir',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red[400],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _selectFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Check file size (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorMessage('Dosya boyutu 5MB\'dan büyük olamaz!');
          return;
        }

        setState(() {
          switch (documentType) {
            case 'diploma':
              _isDiplomaUploaded = true;
              _diplomaFile = file;
              break;
            case 'criminal_record':
              _isCriminalRecordUploaded = true;
              _criminalRecordFile = file;
              break;
            case 'professional_certificate':
              _isProfessionalCertificateUploaded = true;
              _professionalCertificateFile = file;
              break;
            case 'real_estate_permit':
              _isRealEstatePermitUploaded = true;
              _realEstatePermitFile = file;
              break;
            case 'id_front':
              _isIdFrontUploaded = true;
              _idFrontFile = file;
              break;
            case 'id_back':
              _isIdBackUploaded = true;
              _idBackFile = file;
              break;
            case 'contract':
              _isContractUploaded = true;
              _contractFile = file;
              break;
          }
        });

        await _uploadPickedDocument(documentType, file);

        // Show success message
        _showSuccessMessage(
            '${_getDocumentName(documentType)} başarıyla yüklendi!');
      }
    } catch (e) {
      _showErrorMessage('Dosya seçilirken bir hata oluştu: ${e.toString()}');
    }
  }

  void _removeFile(String documentType) {
    setState(() {
      switch (documentType) {
        case 'diploma':
          _isDiplomaUploaded = false;
          _diplomaFile = null;
          _diplomaFileId = null;
          break;
        case 'criminal_record':
          _isCriminalRecordUploaded = false;
          _criminalRecordFile = null;
          _criminalRecordFileId = null;
          break;
        case 'professional_certificate':
          _isProfessionalCertificateUploaded = false;
          _professionalCertificateFile = null;
          _professionalCertificateFileId = null;
          break;
        case 'real_estate_permit':
          _isRealEstatePermitUploaded = false;
          _realEstatePermitFile = null;
          _realEstatePermitFileId = null;
          break;
        case 'id_front':
          _isIdFrontUploaded = false;
          _idFrontFile = null;
          _idFrontFileId = null;
          break;
        case 'id_back':
          _isIdBackUploaded = false;
          _idBackFile = null;
          _idBackFileId = null;
          break;
        case 'contract':
          _isContractUploaded = false;
          _contractFile = null;
          _contractFileId = null;
          break;
      }
    });

    // Show removal message
    _showSuccessMessage('${_getDocumentName(documentType)} kaldırıldı!');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _getDocumentName(String documentType) {
    switch (documentType) {
      case 'diploma':
        return 'Diploma';
      case 'criminal_record':
        return 'Adli Sicil Kaydı';
      case 'professional_certificate':
        return 'Mesleki Yeterlilik Belgesi';
      case 'real_estate_permit':
        return 'Taşınmaz Ticari Yetki Belgesi';
      case 'id_front':
        return 'Nüfus Cüzdanı Ön';
      case 'id_back':
        return 'Nüfus Cüzdanı Arka';
      case 'contract':
        return 'Sözleşme';
      default:
        return 'Belge';
    }
  }

  String _professionDropdownValue() {
    final labels = _professionLabels();
    if (labels.isEmpty) return _professionController.text;
    final byCode = _professions.where((p) => p.code == _selectedProfessionCode);
    if (byCode.isNotEmpty) return byCode.first.description;
    final current = _professionController.text.trim();
    if (labels.contains(current)) return current;
    return labels.first;
  }

  List<String> _professionLabels() {
    final labels = _professions.map((p) => p.description).toList();
    final current = _professionController.text.trim();
    if (current.isNotEmpty && !labels.contains(current)) {
      labels.insert(0, current);
    }
    return labels;
  }

  List<Map<String, dynamic>> _parseAttachments(dynamic raw) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is Map) {
        list.add(Map<String, dynamic>.from(item));
      }
    }
    return list;
  }

  String? _attachmentIdFor(String documentType) {
    for (final item in _existingAttachments) {
      final type = (item['type'] ?? item['id'] ?? '').toString().toUpperCase();
      if (!_matchesAttachmentType(type, documentType)) continue;
      final id = item['attachment'] ??
          item['s3Id'] ??
          item['fileId'] ??
          item['file_id'];
      final value = id?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  bool _matchesAttachmentType(String type, String documentType) {
    switch (documentType) {
      case 'id_front':
        return type.contains('IDENTITY_FRONT') ||
            type.contains('ID_FRONT') ||
            type.contains('ID_CARD_FRONT') ||
            type.contains('NUFUS_ON');
      case 'id_back':
        return type.contains('IDENTITY_BACK') ||
            type.contains('ID_BACK') ||
            type.contains('ID_CARD_BACK') ||
            type.contains('NUFUS_ARKA');
      case 'contract':
        return type.contains('CONTRACT') ||
            type.contains('SOZLESME') ||
            type.contains('AGREEMENT');
      case 'diploma':
        return type.contains('DIPLOMA');
      case 'criminal_record':
        return type.contains('CRIMINAL');
      case 'professional_certificate':
        return type.contains('PROFESSIONAL');
      case 'real_estate_permit':
        return type.contains('REAL_ESTATE') || type.contains('PERMIT');
      default:
        return false;
    }
  }

  String _attachmentTypeFor(String documentType) {
    switch (documentType) {
      case 'id_front':
        return 'IDENTITY_FRONT';
      case 'id_back':
        return 'IDENTITY_BACK';
      case 'contract':
        return 'CONTRACT';
      case 'diploma':
        return 'DIPLOMA';
      case 'criminal_record':
        return 'CRIMINAL_RECORD';
      case 'professional_certificate':
        return 'PROFESSIONAL_CERTIFICATE';
      case 'real_estate_permit':
        return 'REAL_ESTATE_PERMIT';
      default:
        return documentType.toUpperCase();
    }
  }

  void _applyExistingDocumentIds() {
    _idFrontFileId = _attachmentIdFor('id_front');
    _idBackFileId = _attachmentIdFor('id_back');
    _contractFileId = _attachmentIdFor('contract');
    _diplomaFileId = _attachmentIdFor('diploma');
    _criminalRecordFileId = _attachmentIdFor('criminal_record');
    _professionalCertificateFileId =
        _attachmentIdFor('professional_certificate');
    _realEstatePermitFileId = _attachmentIdFor('real_estate_permit');

    _isIdFrontUploaded = _idFrontFileId != null;
    _isIdBackUploaded = _idBackFileId != null;
    _isContractUploaded = _contractFileId != null;
    _isDiplomaUploaded = _diplomaFileId != null;
    _isCriminalRecordUploaded = _criminalRecordFileId != null;
    _isProfessionalCertificateUploaded =
        _professionalCertificateFileId != null;
    _isRealEstatePermitUploaded = _realEstatePermitFileId != null;
  }

  Future<void> _uploadPickedDocument(String documentType, File file) async {
    final result = await _contactRepository.uploadFile(file, documentType);
    if (!mounted) return;
    result.fold((failure) {
      _showErrorMessage(failure.message);
    }, (fileId) {
      setState(() {
        switch (documentType) {
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
          case 'id_front':
            _idFrontFileId = fileId;
            break;
          case 'id_back':
            _idBackFileId = fileId;
            break;
          case 'contract':
            _contractFileId = fileId;
            break;
        }
      });
    });
  }

  Future<void> _downloadDocument(String s3Id) async {
    final url = Uri.parse(ImageUtils.getS3FileUrl(s3Id));
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showErrorMessage('Belge açılamadı');
    }
  }

  List<Map<String, dynamic>> _buildAttachmentsPayload() {
    final byType = <String, Map<String, dynamic>>{};
    for (final item in _existingAttachments) {
      final type = (item['type'] ?? item['id'] ?? '').toString();
      if (type.isEmpty) continue;
      byType[type.toUpperCase()] = Map<String, dynamic>.from(item);
    }

    void upsert(String documentType, String? fileId) {
      if (fileId == null || fileId.isEmpty) {
        byType.removeWhere(
          (key, _) => _matchesAttachmentType(key, documentType),
        );
        return;
      }
      final type = _attachmentTypeFor(documentType);
      byType.removeWhere(
        (key, _) => _matchesAttachmentType(key, documentType),
      );
      byType[type] = {
        'type': type,
        'attachment': fileId,
      };
    }

    upsert('id_front', _idFrontFileId);
    upsert('id_back', _idBackFileId);
    upsert('contract', _contractFileId);
    upsert('diploma', _diplomaFileId);
    upsert('criminal_record', _criminalRecordFileId);
    upsert('professional_certificate', _professionalCertificateFileId);
    upsert('real_estate_permit', _realEstatePermitFileId);
    return byType.values.toList();
  }

  Widget _buildPrivacySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gizlilik ve Güvenlik',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Company Contact Permission
          Row(
            children: [
              Checkbox(
                value: _allowCompanyContact,
                onChanged: (value) {
                  setState(() {
                    _allowCompanyContact = value!;
                  });
                },
                activeColor: const Color(0xFFE53935),
              ),
              const Expanded(
                child: Text(
                  'Kampanyalar için iletişim izni veriyorum.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Password Reset
          InkWell(
            onTap: _showPasswordResetDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Text(
                'Şifrenizi sıfırlamak için tıklayınız.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(238, 46, 36, 1),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    String? Function(String?)? customValidator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Color.fromRGBO(238, 46, 36, 1),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: customValidator ??
              (value) {
                if (isRequired && (value == null || value.trim().isEmpty)) {
                  return '$label alanı zorunludur';
                }

                // Email validation
                if (keyboardType == TextInputType.emailAddress &&
                    value != null &&
                    value.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                }

                // Phone validation
                if (keyboardType == TextInputType.phone &&
                    value != null &&
                    value.isNotEmpty) {
                  if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                    return 'Geçerli bir telefon numarası girin';
                  }
                }

                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromRGBO(238, 46, 36, 1),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    String? label,
  }) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      value: items.contains(value) ? value : (items.isNotEmpty ? items.first : null),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return '${label ?? 'Bu alan'} zorunludur';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromRGBO(238, 46, 36, 1),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          _updateProfile();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: const Text(
          'Bilgileri Güncelle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userFuture = _userProfileService.getUserInfo();
      final professionsFuture = _contactRepository.getProfessions();
      final userProfile = await userFuture;
      final professionsResult = await professionsFuture;
      if (!mounted) return;
      setState(() {
        _userProfile = userProfile;
        professionsResult.fold((_) {}, (res) {
          _professions = res.professions;
        });
        _populateFormFields(userProfile);
      });
    } catch (e) {
      _showErrorMessage('Kullanıcı bilgileri yüklenirken hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// API'den gelen HTML (örn. <p>deneme</p>) içeriği mobil input için düz metne çevirir
  String _stripHtmlToPlainText(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  void _populateFormFields(UserProfileModel userProfile) {
    _nameController.text = userProfile.name;
    _surnameController.text = userProfile.surname;
    _phoneController.text = userProfile.tel;
    _professionController.text = userProfile.detail.profession?.description ??
        userProfile.typeDescription;
    _selectedProfessionCode = userProfile.detail.profession?.code;
    _addressController.text = userProfile.address.address;
    _aboutController.text = _stripHtmlToPlainText(userProfile.detail.coverLetter ?? '');

    // Sosyal medya bilgileri
    _facebookController.text = userProfile.detail.socialMedia?.facebook ?? '';
    _instagramController.text = userProfile.detail.socialMedia?.instagram ?? '';
    _xController.text = userProfile.detail.socialMedia?.x ?? '';
    _linkedinController.text = userProfile.detail.socialMedia?.linkedin ?? '';
    _ttbsController.text = userProfile.eids ?? '';

    _existingAttachments = _parseAttachments(userProfile.attachments);
    final nested = userProfile.detail.detail;
    if (nested is Map && nested['attachments'] != null) {
      _existingAttachments = [
        ..._existingAttachments,
        ..._parseAttachments(nested['attachments']),
      ];
    }
    _applyExistingDocumentIds();

    // Adres bilgileri
    if (userProfile.address.uavtAddress != null) {
      _selectedCity = userProfile.address.uavtAddress!.provinceName.toUpperCase();
      _selectedDistrict = userProfile.address.uavtAddress!.districtName;
      _selectedNeighborhood = userProfile.address.uavtAddress!.quarterName;
    }

    // Eğitim bilgileri
    _selectedDiploma = userProfile.detail.education?.description ?? 'Lisans';

    // İletişim izni
    _allowCompanyContact = userProfile.detail.marketingCommunicationPermission;
  }

  Future<void> _updateProfile() async {
    if (_userProfile == null) {
      _showErrorMessage('Kullanıcı bilgileri yüklenemedi!');
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Lütfen tüm zorunlu alanları doldurun!');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        );
      },
    );

    try {
      // Güncellenmiş profil bilgilerini oluştur
      final updatedProfile = _createUpdatedProfile();
      
      // Profil güncelleme işlemini gerçekleştir
      final result = await _userProfileService.updateUserProfile(
        updatedProfile: updatedProfile,
        updatedBy: _userProfile!.email,
        reason: 'Profil bilgileri güncellendi',
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (result.isSuccess) {
        _showSuccessMessage('Profil bilgileriniz başarıyla güncellendi!');
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop();
        });
      } else {
        _showErrorMessage(result.message);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorMessage('Profil güncelleme işlemi sırasında hata oluştu: $e');
    }
  }

  UserProfileModel _createUpdatedProfile() {
    if (_userProfile == null) {
      throw Exception('Kullanıcı profili bulunamadı');
    }

    // Güncellenmiş sosyal medya bilgileri
    final updatedSocialMedia = UserSocialMediaModel(
      facebook: _facebookController.text.isNotEmpty ? _facebookController.text : null,
      instagram: _instagramController.text.isNotEmpty ? _instagramController.text : null,
      x: _xController.text.isNotEmpty ? _xController.text : null,
      linkedin: _linkedinController.text.isNotEmpty ? _linkedinController.text : null,
    );

    // Güncellenmiş eğitim bilgileri
    final updatedEducation = UserEducationModel(
      id: _userProfile!.detail.education?.id ?? '',
      code: _getEducationCode(_selectedDiploma),
      description: _selectedDiploma,
    );

    // Güncellenmiş meslek bilgileri
    final updatedProfession = UserProfessionModel(
      id: _userProfile!.detail.profession?.id ?? '',
      code: _selectedProfessionCode ??
          _userProfile!.detail.profession?.code ??
          'ACADEMIC',
      description: _professionController.text,
    );

    // Güncellenmiş detay bilgileri
    final updatedDetail = UserDetailModel(
      id: _userProfile!.detail.id,
      birthday: _userProfile!.detail.birthday,
      profession: updatedProfession,
      education: updatedEducation,
      socialMedia: updatedSocialMedia,
      whereYouHeardUs: _userProfile!.detail.whereYouHeardUs,
      coverLetter: _aboutController.text.trim().isEmpty
          ? ''
          : '<p>${_aboutController.text.trim()}</p>',
      sectoralExperience: _userProfile!.detail.sectoralExperience,
      picture: _userProfile!.detail.picture,
      reference: _userProfile!.detail.reference,
      areasOfExpertise: _userProfile!.detail.areasOfExpertise,
      marketingCommunicationPermission: _allowCompanyContact,
      rating: _userProfile!.detail.rating,
      logo: _userProfile!.detail.logo,
      detail: _userProfile!.detail.detail,
    );

    // Güncellenmiş adres bilgileri
    final updatedAddress = UserAddressModel(
      id: _userProfile!.address.id,
      address: _addressController.text,
      district: _userProfile!.address.district,
      city: _userProfile!.address.city,
      countryCode: _userProfile!.address.countryCode,
      countryName: _userProfile!.address.countryName,
      source: _userProfile!.address.source,
      lat: _userProfile!.address.lat,
      lon: _userProfile!.address.lon,
      uavtAddress: _userProfile!.address.uavtAddress,
    );

    // Güncellenmiş profil modeli
    return UserProfileModel(
      contactNo: _userProfile!.contactNo,
      title: '${_nameController.text} ${_surnameController.text}',
      name: _nameController.text,
      surname: _surnameController.text,
      type: _userProfile!.type,
      typeDescription: _userProfile!.typeDescription,
      isCompany: _userProfile!.isCompany,
      isEmployee: _userProfile!.isEmployee,
      isAgency: _userProfile!.isAgency,
      tcIdNumber: _userProfile!.tcIdNumber,
      taxNo: _userProfile!.taxNo,
      taxOffice: _userProfile!.taxOffice,
      nationality: _userProfile!.nationality,
      sex: _userProfile!.sex,
      email: _userProfile!.email,
      tel: _phoneController.text,
      status: _userProfile!.status,
      updatedAt: DateTime.now().toIso8601String(),
      source: _userProfile!.source,
      detail: updatedDetail,
      attachments: _buildAttachmentsPayload(),
      address: updatedAddress,
      connectedContact: _userProfile!.connectedContact,
      connectedContactTitle: _userProfile!.connectedContactTitle,
      connectedContactType: _userProfile!.connectedContactType,
      connectedContactDescription: _userProfile!.connectedContactDescription,
      connectedContactPicture: _userProfile!.connectedContactPicture,
      connectedContactLogo: _userProfile!.connectedContactLogo,
      isCustomer: _userProfile!.isCustomer,
      slug: _userProfile!.slug,
      connectedContactSlug: _userProfile!.connectedContactSlug,
      startingRate: _userProfile!.startingRate,
      advisorLevel: _userProfile!.advisorLevel,
      officeRegion: _userProfile!.officeRegion,
      roles: _userProfile!.roles,
      permissions: _userProfile!.permissions,
      eids: _ttbsController.text.trim().isEmpty
          ? _userProfile!.eids
          : _ttbsController.text.trim(),
      isAdmin: _userProfile!.isAdmin,
    );
  }

  String _getEducationCode(String education) {
    switch (education) {
      case 'Lise':
        return 'HIGH_SCHOOL';
      case 'Ön Lisans':
        return 'ASSOCIATE';
      case 'Lisans':
        return 'BACHELOR';
      case 'Yüksek Lisans':
        return 'MASTER';
      case 'Doktora':
        return 'POST_GRADUATE';
      default:
        return 'BACHELOR';
    }
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Color.fromRGBO(238, 46, 36, 1),
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Şifre Sıfırlama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Şifrenizi sıfırlayabilmek için mail adresinize bir mail göndereceğiz, buradaki bağlantıyı kullanarak şifrenizi sıfırlayabilirsiniz. Şifrenizi sıfırlamak istiyor musunuz?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Hayır',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromRGBO(238, 46, 36, 1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Confirm Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _sendPasswordResetEmail();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sıfırla',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
      },
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_userProfile == null) {
      _showErrorMessage('Kullanıcı bilgileri yüklenemedi!');
      return;
    }

    try {
      final result = await _userProfileService.requestPasswordReset(
        email: _userProfile!.email,
        contactNo: _userProfile!.contactNo.toString(),
      );

      if (result.isSuccess) {
        _showSuccessMessage('Şifre sıfırlama maili gönderildi!');
      } else {
        _showErrorMessage(result.message);
      }
    } catch (e) {
      _showErrorMessage('Şifre sıfırlama isteği gönderilirken hata oluştu: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_userProfile == null) {
      _showErrorMessage('Kullanıcı bilgileri yüklenemedi!');
      return;
    }

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
        });

        // Profil resmini güncelle
        final result = await _userProfileService.updateProfilePicture(
          contactNo: _userProfile!.contactNo.toString(),
          picturePath: pickedFile.path,
          updatedBy: _userProfile!.email,
          reason: 'Profil resmi güncellendi',
        );

        if (result.isSuccess) {
          _showSuccessMessage('Profil fotoğrafı başarıyla güncellendi!');
        } else {
          _showErrorMessage(result.message);
        }
      }
    } catch (e) {
      _showErrorMessage('Fotoğraf seçilirken bir hata oluştu: $e');
    }
  }
}