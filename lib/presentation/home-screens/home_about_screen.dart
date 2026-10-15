import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeAboutScreen extends StatefulWidget {
  const HomeAboutScreen({super.key});

  @override
  State<HomeAboutScreen> createState() => _HomeAboutScreenState();
}

class _HomeAboutScreenState extends State<HomeAboutScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.99, end: 1.0).animate(
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
      drawer: const HomeSidebar(currentPage: 'Hakkımızda'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.red.shade600,
                        Colors.red.shade800,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Hakkımızda",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // İçerik
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContentSection(
                        "Zecorner, emlak sektöründe gerek yenilikçi iş modelleri gerekse teknolojik alt yapısı ile sektördeki rakiplerinden ayrışacak iddialı ve cesur bir yaklaşımın sonucu olarak ortaya çıkan bir fikirdi.",
                      ),
                      const SizedBox(height: 24),
                      _buildContentSection(
                        "İşte bu vizyon ile Ziya Eren önderliğinde 2023 yılında Zecorner'ın temelleri atıldı. Bu süreçte geleneksel gayrimenkul ofisi iş modelinin çok ötesinde bir iş modeli kurmak için hem yerli hem yabancı sektör dinamikleri derinlemesine analiz edilerek sektörün ihtiyaçlarının tespiti, en verimli müşteri ve portföy yönetim yöntemleri, tüm paydaşların daha fazla kazanmasına odaklı gelir modelleri ve daha verimli çalışmanın yöntemleri tanımlandı ve tasarlandı. Tasarlanan tüm model ve iş süreçleri sürdürülebilirlik, büyüme odaklılık, verimlilik, ölçümlenebilirlik ve şeffaflık ilkeleri üzerinde şekillendirildi.",
                      ),
                      const SizedBox(height: 24),
                      _buildContentSection(
                        "Bu noktada saydığımız tüm unsurların kusursuz akışı ve yönetimi için olmazsa olmaz diğer bir gereksinim ise teknolojik alt yapıydı. Bu noktada dışarıda var olan hazır sistemler üzerinde gitmektense, Zecorner yine cesur bir kararla kendi teknolojik alt yapısını kurma yoluna gitti. Kurduğu dijital platform üzerinde bir gayrimenkul ofisinin ve danışmanın isteyeceği tüm bileşenleri içeren, tüm danışmanların iş yükünü azaltarak onlara zaman kazandıran, yeni ihtiyaçlara göre ve teknolojik dönüşüme hızlı şekilde çözüm üretebilecek bir alt yapı hazırlandı.",
                      ),
                      const SizedBox(height: 24),
                      _buildContentSection(
                        "Zecorner, hızlı ve planlı bir şekilde ülke geneline yayılarak 2 sene içerisinde 100 ofise ulaşma hedefiyle çalışmalarına devam ediyor.",
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

  Widget _buildContentSection(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.grey[800],
        ),
      ),
    );
  }
} 