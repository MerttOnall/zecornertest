import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/models/favorite/favorite_advisor_model.dart';
import 'package:zecorner/infrastructure/favorite/favorite_repository.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/router/app_router.dart';
import 'dart:math' as math;

class FavoriteDanismanScreen extends StatefulWidget {
  const FavoriteDanismanScreen({super.key});

  @override
  State<FavoriteDanismanScreen> createState() => _FavoriteDanismanScreenState();
}

class _FavoriteDanismanScreenState extends State<FavoriteDanismanScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late AnimationController _waveController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _waveAnimation;
  
  int _currentIndex = 4;

  final FavoriteRepository _favoriteRepository = FavoriteRepository();
  List<FavoriteAdvisorModel> _advisors = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, bool> favoriteStates = {};

  @override
  void initState() {
    super.initState();
    
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
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
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
    
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));
    
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    final result = await _favoriteRepository.getFavoriteAdvisors(page: 1, limit: 50);
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = failure.message;
          _advisors = [];
        });
      },
      (response) {
        setState(() {
          _advisors = response.advisors;
          _isLoading = false;
          for (var a in _advisors) {
            favoriteStates[a.contactNo.toString()] = true;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    _waveController.dispose();
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
          'Favorilerim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadAdvisors,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),
          
          // Main Content
          _buildConsultantsList(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEBEE),
            Color(0xFFFFCDD2),
            Color(0xFFEF9A9A),
            Color(0xFFE57373),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Rotating circles
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Pulse effect
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                top: 100,
                right: 50,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withOpacity(0.05),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Floating particles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 50.0) % MediaQuery.of(context).size.width,
                  top: 200 + (index * 80.0) % 400 + _floatingAnimation.value,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE53935).withOpacity(0.3),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Wave effect
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(_waveAnimation.value),
                size: Size(MediaQuery.of(context).size.width, 200),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsultantsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935))),
            SizedBox(height: 16),
            Text('Favori danışmanlar yükleniyor...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    if (_hasError && _advisors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Bir hata oluştu', style: TextStyle(fontSize: 16, color: Colors.grey[700]), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAdvisors,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (_advisors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Henüz favori danışman yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Beğendiğiniz danışmanları favorilerinize ekleyin', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.3),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _advisors.length,
            itemBuilder: (context, index) {
              final advisor = _advisors[index];
              return Column(
                children: [
                  _buildConsultantCard(advisor),
                  if (index < _advisors.length - 1) const SizedBox(height: 20),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildConsultantCard(FavoriteAdvisorModel advisor) {
    final consultantId = advisor.slug ?? advisor.contactNo.toString();
    final profileUrl = ImageUtils.getProfileImageUrl(advisor.picture);
    final role = advisor.typeDescription ?? advisor.professionDescription ?? 'Emlak Danışmanı';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.homeDanisman,
          arguments: {
            'consultantId': consultantId,
            'consultantName': advisor.displayName,
            'consultantTitle': role,
            'consultantEmail': advisor.eMail ?? '',
            'consultantPhone': advisor.tel ?? '',
            'consultantPicture': advisor.picture,
            'consultantOffice': advisor.connectedContactTitle ?? '',
            'consultantContactNo': advisor.contactNo,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileUrl.isEmpty
                      ? Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white, size: 40),
                        )
                      : Image.network(
                          profileUrl,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisor.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF475569),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PORTFÖY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 10),
                              SizedBox(width: 2),
                              Text('0', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              favoriteStates[advisor.contactNo.toString()] = false;
                              _advisors.removeWhere((a) => a.contactNo == advisor.contactNo);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Favorilerden çıkarıldı')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.favorite, color: Color(0xFFE53935), size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (advisor.isZecornerCadde)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          advisor.connectedContactTitle ?? 'Zecorner Cadde',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE53935).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.7 +
          20 * math.sin((x / size.width * 2 * math.pi) + animationValue);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
