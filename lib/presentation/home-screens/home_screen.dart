import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:zecorner/presentation/widgets/home_sidebar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;
  late final ScrollController _listingsScrollController;
  Timer? _listingsScrollTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    );

    _listingsScrollController = ScrollController();

    // İlanlar için otomatik kaydırma
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListingsAutoScroll();
    });
  }

  void _startListingsAutoScroll() {
    _listingsScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_listingsScrollController.hasClients) {
        final currentPosition = _listingsScrollController.offset;
        final maxScroll = _listingsScrollController.position.maxScrollExtent;

        if (currentPosition >= maxScroll) {
          _listingsScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        } else {
          _listingsScrollController.animateTo(
            currentPosition + 235, // 220 (kart genişliği) + 15 (margin)
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _listingsScrollController.dispose();
    _listingsScrollTimer?.cancel();
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
          icon: const Icon(Icons.menu, color: Colors.red, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Giriş Yap',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: ElevatedButton(
              onPressed: () {
                // Navigator.pushNamed(context, '/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Hesap Oluştur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: const HomeSidebar(currentPage: 'Ana Sayfa'),
      body: Stack(
        children: [
          // Animasyonlu arka plan desenleri
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withOpacity(0.1),
                      Colors.red.withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),
          ),
          // Yüzen daire
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            left: -150,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * _floatingAnimation.value),
                  child: child,
                );
              },
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withOpacity(0.05),
                      Colors.red.withOpacity(0.01),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          // Küçük yüzen şekiller
          ...List.generate(5, (index) {
            final random = math.Random();
            final size = random.nextDouble() * 50 + 20;
            final initialX =
                random.nextDouble() * MediaQuery.of(context).size.width;
            final initialY =
                random.nextDouble() * MediaQuery.of(context).size.height;

            return Positioned(
              left: initialX,
              top: initialY,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      10 *
                          math.sin(
                              (index + 1) * _floatingAnimation.value * math.pi),
                      15 *
                          math.cos(
                              (index + 1) * _floatingAnimation.value * math.pi),
                    ),
                    child: Transform.rotate(
                      angle: _rotationController.value * math.pi * (index + 1),
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withOpacity(0.05),
                              Colors.red.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              index.isEven ? size / 2 : 5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          // Mevcut dalga deseni
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, 200),
                  painter: WavePatternPainter(
                    waveOffset: _floatingAnimation.value,
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                // Carousel Slider
                CarouselSlider(
                  options: CarouselOptions(
                    height: 400,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                  ),
                  items: [
                    _buildCarouselItem(
                      title: "Gayrimenkulde\nYeni Ortağınız",
                      imagePath: "assets/images/hero-bg.jpg",
                      buttonText: "Zecorner\nOfisi Açmak İstiyorum",
                    ),
                    // Diğer carousel öğeleri buraya eklenebilir
                  ],
                ),

                const SizedBox(height: 30),

                // Hizmetlerimiz bölümünden önce eklenecek
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/logo/indir.png',
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Eşsiz Bir Deneyim, Birlikte Büyüyen Ekip!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Gayrimenkul sektörüne yeni bir bakış açısı kazandırma içgörüsüyle yola çıktık. Tecrübeli kadroları bir araya getirerek sektörün tüm paydaşlarını dinledik. Emeğin karşılığının adil dağıtıldığı bir paylaşım modeli oluşturduk. Gayrimenkul sektöründe zirveye giden bu yolculuğumuza, fark yaratmak isteyen cesur ortaklarımızı davet ediyoruz.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Aramıza Katıl",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Ofislerimiz",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Zecorner, kendi ofis ortamınızı özgürce yaratma fırsatı sunar. Yenilikçi tasarım anlayışımız ve verimliliği ön planda tutan yaklaşımımızla, herkesin kendini rahat ve motive hissedebileceği bir çalışma atmosferi oluşturmanızı destekliyoruz.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Öne Çıkan Hizmetler
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hizmetlerimiz",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildServiceCard("Franchise", Icons.store),
                          _buildServiceCard("Danışmanlık", Icons.people),
                          _buildServiceCard("Eğitim", Icons.school),
                          _buildServiceCard("Destek", Icons.headset_mic),
                        ],
                      ),
                    ],
                  ),
                ),

                // Hizmetler Detay
                Container(
                  color: Colors.grey[50],
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Animasyonlu arka plan desenleri
                      Positioned(
                        top: -50,
                        right: -30,
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: -_rotationController.value * math.pi,
                              child: Container(
                                width: 300,
                                height: 300,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.2, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(150),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // İçerik
                      Column(
                        children: [
                          const Text(
                            "Neler Sunuyoruz?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildServiceDetail(
                                icon: Icons.store,
                                title: "Franchise",
                                description:
                                    "Gayrimenkul sektöründe kendi işinizin sahibi olun. Zecorner franchise sistemi ile başarılı bir iş modeline sahip olun.",
                              ),
                              _buildServiceDetail(
                                icon: Icons.people,
                                title: "Danışmanlık",
                                description:
                                    "Uzman ekibimizle gayrimenkul yatırımlarınızda doğru kararlar alın.",
                              ),
                              _buildServiceDetail(
                                icon: Icons.school,
                                title: "Eğitim",
                                description:
                                    "Sektörde fark yaratacak eğitimlerle kendinizi geliştirin.",
                              ),
                              _buildServiceDetail(
                                icon: Icons.headset_mic,
                                title: "Destek",
                                description:
                                    "7/24 teknik destek ve operasyonel süreçlerde tam destek.",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Hakkımızda Bölümü
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const Text(
                        "Hakkımızda",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Zecorner, gayrimenkul sektöründe yenilikçi ve güvenilir çözümler sunan öncü bir markadır. Modern yaklaşımımız ve profesyonel ekibimizle müşterilerimize en iyi hizmeti sunmayı hedefliyoruz.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Ekibimiz Bölümü
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Stack(
                    children: [
                      // Animasyonlu arka plan desenleri
                      Positioned(
                        bottom: -30,
                        left: -20,
                        child: AnimatedBuilder(
                          animation: _floatingAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                10 *
                                    math.sin(
                                        _floatingAnimation.value * math.pi),
                              ),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.04),
                                      Colors.transparent,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Küçük yüzen şekiller
                      ...List.generate(3, (index) {
                        final random = math.Random();
                        final size = random.nextDouble() * 30 + 10;
                        final initialX = random.nextDouble() *
                            MediaQuery.of(context).size.width;

                        return Positioned(
                          left: initialX,
                          top: random.nextDouble() * 200,
                          child: AnimatedBuilder(
                            animation: _floatingAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  5 *
                                      math.sin((index + 1) *
                                          _floatingAnimation.value *
                                          math.pi),
                                  8 *
                                      math.cos((index + 1) *
                                          _floatingAnimation.value *
                                          math.pi),
                                ),
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.withOpacity(0.05),
                                        Colors.red.withOpacity(0.02),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        index.isEven ? size / 2 : 4),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      // Mevcut içerik
                      Column(
                        children: [
                          const Text(
                            "Ekibimiz",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                final team = [
                                  {
                                    'name': 'Halis Arslan',
                                    'role': 'Kurucu & CEO',
                                    'image':
                                        'assets/logo/46.png',
                                  },
                                  {
                                    'name': 'Halis Arslan',
                                    'role': 'Franchise Müdürü',
                                    'image':
                                        'assets/logo/46.png',
                                  },
                                  {
                                    'name': 'Halis Arslan',
                                    'role': 'Eğitim Direktörü',
                                    'image':
                                        'assets/logo/46.png',
                                  },
                                  {
                                    'name': 'Halis Arslan',
                                    'role': 'Operasyon Müdürü',
                                    'image':
                                        'assets/logo/46.png',
                                  },
                                ];

                                return Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 15),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(75),
                                        child: Image.asset(
                                          team[index]['image']!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        team[index]['name']!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        team[index]['role']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // İlanlar Bölümü
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Öne Çıkan İlanlar",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Tümünü Gör",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          controller: _listingsScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            // Her ilan için farklı görsel ve bilgiler
                            final listings = [
                              {
                                'image':
                                    'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
                                'type': 'Satılık',
                                'title': '4+1 Villa',
                                'location': 'Çankaya, Ankara',
                                'price': '₺5.250.000'
                              },
                              {
                                'image':
                                    'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9',
                                'type': 'Kiralık',
                                'title': '2+1 Residence',
                                'location': 'Batıkent, Ankara',
                                'price': '₺12.000'
                              },
                              {
                                'image':
                                    'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c',
                                'type': 'Satılık',
                                'title': '3+1 Bahçeli Daire',
                                'location': 'Eryaman, Ankara',
                                'price': '₺3.150.000'
                              },
                              {
                                'image':
                                    'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b',
                                'type': 'Satılık',
                                'title': '5+2 Müstakil',
                                'location': 'Yaşamkent, Ankara',
                                'price': '₺7.850.000'
                              },
                              {
                                'image':
                                    'https://images.unsplash.com/photo-1600585154526-990dced4db0d',
                                'type': 'Kiralık',
                                'title': '3+1 Lüks Daire',
                                'location': 'Çayyolu, Ankara',
                                'price': '₺15.000'
                              },
                            ];

                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      listings[index]['image']!,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      // Yükleme ve hata durumları için
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 140,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.red),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 140,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.error_outline,
                                              color: Colors.red),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            listings[index]['type']!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          listings[index]['title']!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          listings[index]['location']!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          listings[index]['price']!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Bize Katılın Bölümü
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.red,
                  child: Column(
                    children: [
                      const Text(
                        "Bize Katılın!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          "Başvur",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildCarouselItem({
    required String title,
    required String imagePath,
    required String buttonText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    "assets/logo/zecorner-logo1.svg",
                    width: 120,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      "Başvur",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: Colors.red),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetail({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
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

// Güncellenmiş WavePatternPainter
class WavePatternPainter extends CustomPainter {
  final double waveOffset;

  WavePatternPainter({required this.waveOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    // Animasyonlu dalgalar
    for (var i = 0; i <= size.width; i++) {
      path.lineTo(
        i.toDouble(),
        size.height * 0.8 +
            math.sin((i / size.width * 4 * math.pi) +
                    (waveOffset * 2 * math.pi)) *
                10,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, paint);

    // İkinci dalga
    final path2 = Path();
    path2.moveTo(0, size.height);

    for (var i = 0; i <= size.width; i++) {
      path2.lineTo(
        i.toDouble(),
        size.height * 0.85 +
            math.cos((i / size.width * 3 * math.pi) -
                    (waveOffset * 2 * math.pi)) *
                8,
      );
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, paint..color = Colors.red.withOpacity(0.01));
  }

  @override
  bool shouldRepaint(covariant WavePatternPainter oldDelegate) =>
      oldDelegate.waveOffset != waveOffset;
}
