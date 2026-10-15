import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';

class HomeSssScreen extends StatefulWidget {
  const HomeSssScreen({super.key});

  @override
  State<HomeSssScreen> createState() => _HomeSssScreenState();
}

class _HomeSssScreenState extends State<HomeSssScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _expandedIndex;
  int _selectedMenuIndex = 0; // Seçili menü indeksi

  // Her kategori için ayrı SSS listeleri
  final List<Map<String, dynamic>> _menuCategories = [
    {
      'title': 'Zecorner',
      'items': [
        {
          'title': 'Zecorner Nedir?',
          'content': 'Zecorner, emlak sektöründe teknoloji odaklı çözümler sunan yenilikçi bir gayrimenkul platformudur...',
        },
        {
          'title': 'Zecorner ile Diğer Gayrimenkul Markaları Arasındaki Fark Nedir?',
          'content': 'Zecorner, teknolojik altyapısı, yenilikçi iş modeli ve sürdürülebilir büyüme stratejisi ile sektörde farklılaşır...',
        },
        {
          'title': 'Zeonline Nedir?',
          'content': 'Zeonline, Zecorner\'ın geliştirdiği dijital gayrimenkul yönetim platformudur...',
        },
        {
          'title': 'Zekampüs Nedir?',
          'content': 'Zekampüs, Zecorner bünyesindeki eğitim ve gelişim platformudur...',
        },
      ],
    },
    {
      'title': 'Gayrimenkul Danışmanlığı',
      'items': [
        {
          'title': 'Nasıl Danışman Olurum?',
          'content': 'Zecorner\'da danışman olmak için başvuru formunu doldurmanız yeterlidir...',
        },
        {
          'title': 'Danışmanlık Eğitimleri Nasıl İşliyor?',
          'content': 'Zecorner, danışmanlarına kapsamlı eğitim programları sunmaktadır...',
        },
        // Diğer danışmanlık soruları...
      ],
    },
    {
      'title': 'Franchise Broker / Ofis Sistemi',
      'items': [
        {
          'title': 'Franchise Şartları Nelerdir?',
          'content': 'Zecorner franchise sistemi için belirli kriterler ve şartlar bulunmaktadır...',
        },
        {
          'title': 'Franchise Maliyeti Ne Kadardır?',
          'content': 'Franchise maliyetleri bölgeye ve ofis tipine göre değişiklik göstermektedir...',
        },
        // Diğer franchise soruları...
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
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
              onPressed: () => Navigator.pushNamed(context, '/register'),
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
      drawer: const HomeSidebar(currentPage: 'SSS'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Üst menü
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    ...List.generate(_menuCategories.length, (index) {
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMenuIndex = index;
                                _expandedIndex = null; // Seçili açık soruyu sıfırla
                              });
                            },
                            child: _buildMenuItem(
                              _menuCategories[index]['title'],
                              isSelected: _selectedMenuIndex == index,
                            ),
                          ),
                          if (index != _menuCategories.length - 1)
                            const SizedBox(width: 24),
                        ],
                      );
                    }),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),

            // Başlık
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                children: [
                  Text(
                    _menuCategories[_selectedMenuIndex]['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sıkça sorulan sorular ve cevapları',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // SSS listesi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(
                  _menuCategories[_selectedMenuIndex]['items'].length,
                  (index) {
                    final item = _menuCategories[_selectedMenuIndex]['items'][index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          initiallyExpanded: index == _expandedIndex,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expandedIndex = expanded ? index : null;
                            });
                          },
                          title: Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _expandedIndex == index 
                                  ? Colors.red.shade50 
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _expandedIndex == index
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: _expandedIndex == index 
                                  ? Colors.red 
                                  : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Text(
                                item['content'],
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.red : Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
