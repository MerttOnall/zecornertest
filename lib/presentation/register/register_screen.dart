import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zecorner/widgets/custom_text_field.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'dart:math' as math;

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.8,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _education;
  String? _profession;
  String? _city;
  String? _district;
  bool _acceptTerms = false;
  bool _acceptKvkk = false;

  // Animation controllers
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _waveAnimation;

  final List<String> _educationOptions = [
    'Lise',
    'Ön Lisans',
    'Lisans',
    'Yüksek Lisans',
    'Doktora'
  ];
  final List<String> _professionOptions = [
    'Gayrimenkul Danışmanı',
    'Broker',
    'Ofis Yöneticisi',
    'Diğer'
  ];
  final List<String> _cityOptions = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya'
  ];
  final List<String> _districtOptions = [
    'Kadıköy',
    'Beşiktaş',
    'Çankaya',
    'Konak',
    'Osmangazi'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
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
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
    // Initialize animations
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
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Form validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad alanı zorunludur';
    }
    if (value.trim().length < 2) {
      return 'Ad en az 2 karakter olmalıdır';
    }
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(value)) {
      return 'Ad sadece harf içerebilir';
    }
    return null;
  }

  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Soyad alanı zorunludur';
    }
    if (value.trim().length < 2) {
      return 'Soyad en az 2 karakter olmalıdır';
    }
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$').hasMatch(value)) {
      return 'Soyad sadece harf içerebilir';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası zorunludur';
    }
    // Remove all non-numeric characters
    String phoneOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (phoneOnly.length != 10) {
      return 'Telefon numarası 10 haneli olmalıdır';
    }
    if (!phoneOnly.startsWith('5')) {
      return 'Geçerli bir cep telefonu numarası giriniz';
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

  // Phone formatter
  List<TextInputFormatter> _phoneInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(10),
      TextInputFormatter.withFunction((oldValue, newValue) {
        String text = newValue.text;
        if (text.length >= 4) {
          if (text.length <= 7) {
            text = '${text.substring(0, 3)} ${text.substring(3)}';
          } else {
            text = '${text.substring(0, 3)} ${text.substring(3, 6)} ${text.substring(6)}';
          }
        }
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE53935), // Kırmızı
              Color(0xFFD32F2F), // Koyu kırmızı
              Color(0xFFB71C1C), // Çok koyu kırmızı
              Color(0xFF8E0000), // En koyu kırmızı
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            // Sağ üst büyük daire
            Positioned(
              right: -120,
              top: -120,
              child: AnimatedBuilder(
                animation: Listenable.merge([_rotationController, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            
            // Sol alt orta daire
            Positioned(
              left: -80,
              bottom: -80,
              child: AnimatedBuilder(
                animation: Listenable.merge([_rotationController, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotationController.value * 1.5 * math.pi,
                    child: Transform.scale(
                      scale: _pulseAnimation.value * 0.8,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            
            // Orta dalga efekti
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 150,
              top: MediaQuery.of(context).size.height / 3,
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(300, 100),
                    painter: WavePainter(_waveAnimation.value),
                  );
                },
              ),
            ),
            
            // Küçük yüzen parçacıklar
            ...List.generate(8, (index) {
              return Positioned(
                left: (index * 50.0) % MediaQuery.of(context).size.width,
                top: (index * 80.0) % MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_floatingAnimation.value + index) * 10,
                        math.cos(_floatingAnimation.value + index) * 10,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 6 + (index % 3) * 2,
                    height: 6 + (index % 3) * 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            
            // Logo with floating animation
            Positioned(
              top: 80,
              left: MediaQuery.of(context).size.width / 4,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value * 0.5),
                    child: child,
                  );
                },
              child: SvgPicture.asset(
                  'assets/logo/zecorner-logo2.svg',
                height: 45,
                width: 45,
                ),
              ),
            ),
            
            // Register form with enhanced design
            Align(
              alignment: const Alignment(0, 0.50),
              child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: AnimatedBuilder(
                    animation: _floatingAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatingAnimation.value * 0.3),
                        child: child,
                      );
                    },
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                        maxWidth: 400,
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                  ),
                  child: Card(
                        color: Colors.white.withOpacity(0.98),
                        elevation: 25,
                        shadowColor: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.98),
                                Colors.white.withOpacity(0.95),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 28.0),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [
                                            Color(0xFFE53935),
                                            Color(0xFFD32F2F),
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          "Zecorner Ofis/Broker\nBaşvuru Formu",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Form fields in grid layout
                                    _buildFormField(
                                      label: 'Adınız *',
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
                                      label: 'Soyadınız *',
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
                                      label: 'Telefon Numaranız *',
                                      controller: _phoneController,
                                      hintText: '5XX XXX XXXX',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: _validatePhone,
                                      inputFormatters: _phoneInputFormatters(),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    _buildFormField(
                                      label: 'E-posta Adresiniz *',
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
                                      label: 'Eğitim Durumunuz *',
                                      value: _education,
                                      items: _educationOptions,
                                      onChanged: (v) => setState(() => _education = v),
                                      icon: Icons.school_outlined,
                                      validator: (value) => _validateDropdown(value, 'Eğitim durumu'),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    _buildDropdownField(
                                      label: 'Mesleğiniz *',
                                      value: _profession,
                                      items: _professionOptions,
                                      onChanged: (v) => setState(() => _profession = v),
                                      icon: Icons.work_outline,
                                      validator: (value) => _validateDropdown(value, 'Meslek'),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    _buildDropdownField(
                                      label: 'İl *',
                                      value: _city,
                                      items: _cityOptions,
                                      onChanged: (v) => setState(() {
                                        _city = v;
                                        _district = null; // Reset district when city changes
                                      }),
                                      icon: Icons.location_city_outlined,
                                      validator: (value) => _validateDropdown(value, 'İl'),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    _buildDropdownField(
                                      label: 'İlçe *',
                                      value: _district,
                                      items: _city != null ? _districtOptions : [],
                                      onChanged: (v) => setState(() => _district = v),
                                      icon: Icons.location_on_outlined,
                                      validator: (value) => _validateDropdown(value, 'İlçe'),
                                      enabled: _city != null,
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Checkbox fields
                                    _buildAnimatedCheckbox(
                                      value: _acceptTerms,
                                      onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                      title: 'Yasal Uyarılar ve Kullanım Koşulları',
                                      subtitle: "'nı okudum ve kabul ediyorum.",
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    _buildAnimatedCheckbox(
                                      value: _acceptKvkk,
                                      onChanged: (v) => setState(() => _acceptKvkk = v ?? false),
                                      title: 'KVKK Aydınlatma Metni',
                                      subtitle: "'ni okudum ve kabul ediyorum.",
                                      isRequired: true,
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // Enhanced submit button
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
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            if (!_acceptTerms || !_acceptKvkk) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Lütfen kullanım koşullarını ve KVKK metnini kabul ediniz'),
                                                  backgroundColor: Color.fromRGBO(238, 46, 36, 1),
                                                ),
                                              );
                                              return;
                                            }
                                            
                                            // Show success message
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Başvurunuz başarıyla gönderildi!'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            
                                            // Navigate back or to success page
                                            Navigator.of(context).pop();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Başvuru Gönder',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedLabel(label),
        const SizedBox(height: 8),
        _buildEnhancedTextField(
          controller: controller,
          hintText: hintText,
          icon: icon,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          inputFormatters: inputFormatters,
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
        _buildAnimatedLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
                color: Colors.grey[400],
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: enabled ? const Color(0xFFE53935) : Colors.grey,
                size: 20,
              ),
              filled: true,
              fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[200]!,
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
                  width: 1,
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
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLabel(String text) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_floatingAnimation.value * 0.1, 0),
          child: child,
        );
      },
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
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
            color: Colors.grey[400],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFE53935),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
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
              width: 1,
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
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          activeColor: const Color(0xFFE53935),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: '* ',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: Color.fromRGBO(238, 46, 36, 1),
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
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

// Custom painter for wave effect
class WavePainter extends CustomPainter {
  final double animationValue;
  
  WavePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = size.height / 2 + 
          math.sin((x / size.width * 2 * math.pi) + animationValue) * 20;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
