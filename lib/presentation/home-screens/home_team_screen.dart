import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:zecorner/presentation/home-screens/home_franchise_screen.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'dart:ui';

class HomeTeamScreen extends StatefulWidget {
  const HomeTeamScreen({super.key});

  @override
  State<HomeTeamScreen> createState() => _HomeTeamScreenState();
}

class _HomeTeamScreenState extends State<HomeTeamScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _teamMembers = [
    {
      'name': 'Halis Arslan',
      'title': 'Genel Koordinatör',
      'email': 'halis.arslan@zecorner.com',
      'image': 'assets/logo/46.png', // Geçici olarak logo kullanıyoruz
      'isFounder': false,
    },
    {
      'name': 'Ahmet Yılmaz',
      'title': 'Satış Müdürü',
      'email': 'ahmet.yilmaz@zecorner.com',
      'image': 'assets/logo/46.png',
      'isFounder': false,
    },
    {
      'name': 'Mehmet Demir',
      'title': 'Operasyon Müdürü',
      'email': 'mehmet.demir@zecorner.com',
      'image': 'assets/logo/46.png',
      'isFounder': false,
    },
  ];

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
      ),
      drawer: const HomeSidebar(currentPage: 'Ekibimiz'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Hero Bölümü (modern, gradientli, animasyonlu)
                _ModernTeamHero(),
                // Yönetim Bölümü
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                  child: Column(
                    children: [
                      const Text(
                        'Yönetim',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = MediaQuery.of(context).size.width < 700;
                          final double sliderHeight = isMobile
                              ? (MediaQuery.of(context).size.height * 0.60).clamp(420, 520)
                              : 480;
                          return CarouselSlider.builder(
                            itemCount: _teamMembers.length,
                            options: CarouselOptions(
                              height: sliderHeight,
                              viewportFraction: isMobile ? 0.88 : 0.5,
                              enlargeCenterPage: true,
                              autoPlay: true,
                              autoPlayInterval: const Duration(seconds: 3),
                              autoPlayAnimationDuration: const Duration(milliseconds: 2000),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              enableInfiniteScroll: true,
                              scrollDirection: Axis.horizontal,
                              padEnds: true,
                            ),
                            itemBuilder: (context, index, realIndex) {
                              return _ModernTeamMemberCard(_teamMembers[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Ekip Üyeleri
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    children: [
                      const Text(
                        'Franchaise Satış Departmanı',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = MediaQuery.of(context).size.width < 700;
                          final nonFounders = _teamMembers.where((m) => !m['isFounder']).toList();
                          if (isMobile) {
                            // Mobilde slider
                            final double sliderHeight = (MediaQuery.of(context).size.height * 0.60).clamp(420, 520);
                            return CarouselSlider.builder(
                              itemCount: nonFounders.length,
                              options: CarouselOptions(
                                height: sliderHeight,
                                viewportFraction: 0.88,
                                enlargeCenterPage: true,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration: const Duration(milliseconds: 2000),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                enableInfiniteScroll: true,
                                scrollDirection: Axis.horizontal,
                                padEnds: true,
                              ),
                              itemBuilder: (context, index, realIndex) {
                                return _ModernTeamMemberCard(nonFounders[index]);
                              },
                            );
                          } else {
                            // Geniş ekranda grid
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 39,
                                crossAxisSpacing: 24,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: nonFounders.length,
                              itemBuilder: (context, index) {
                                return _ModernTeamMemberCard(nonFounders[index]);
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(currentIndex: 4, onTap: (index) {}),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst kısım - Fotoğraf ve gradient overlay
          AspectRatio(
            aspectRatio: 1.2,
            child: Stack(
              children: [
                // Fotoğraf
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    image: DecorationImage(
                      image: AssetImage('assets/logo/46.png'), // Geçici logo
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.red.shade900.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                // Logo badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/logo/zecorner-logo1.svg',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alt kısım - Bilgiler
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İsim
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 12),
                
                // Unvan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.red.shade100,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    member['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // Email butonu
                if (member['email'] != null)
                  TextButton(
                    onPressed: () {
                      // Email işlemi
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'halis.arslan@zecorner.com',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTeamHero extends StatefulWidget {
  @override
  State<_ModernTeamHero> createState() => _ModernTeamHeroState();
}

class _ModernTeamHeroState extends State<_ModernTeamHero> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 260,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/logo/ekipfoto.png',
                fit: BoxFit.cover,
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.2),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0, 0.7, 1],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(color: Colors.transparent),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Center(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Çok Yakında Tüm Türkiye'deyiz",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                        letterSpacing: -1,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const HomeFranchiseScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return child;
                          },
                        ),
                      );
                          
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(238, 46, 36, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Başvuru Yap', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernTeamMemberCard extends StatefulWidget {
  final Map<String, dynamic> member;
  const _ModernTeamMemberCard(this.member);

  @override
  State<_ModernTeamMemberCard> createState() => _ModernTeamMemberCardState();
}

class _ModernTeamMemberCardState extends State<_ModernTeamMemberCard> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 1.0,
      upperBound: 1.03,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hover) {
    setState(() => _hovering = hover);
    if (hover) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) => _onHover(true),
        onTapUp: (_) => _onHover(false),
        onTapCancel: () => _onHover(false),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(_hovering ? 0.18 : 0.10),
                  blurRadius: _hovering ? 32 : 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst kısım - Fotoğraf ve gradient overlay
                Container(
                  height: 230,
                  child: Stack(
                    children: [
                      // Fotoğraf
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          image: DecorationImage(
                            image: AssetImage(member['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.red.shade900.withOpacity(0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Logo badge
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.0),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/logo/zecorner-logo1.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Alt kısım - Bilgiler
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // İsim
                      Text(
                        member['name'],
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Unvan
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.red.shade100,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          member['title'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email butonu
                      if (member['email'] != null)
                        TextButton(
                          onPressed: () {
                            // Email işlemi
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                member['email'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
      ),
    );
  }
}
