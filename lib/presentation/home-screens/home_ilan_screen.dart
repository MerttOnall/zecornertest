import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeIlanScreen extends StatefulWidget {
  const HomeIlanScreen({super.key});

  @override
  State<HomeIlanScreen> createState() => _HomeIlanScreenState();
}

class _HomeIlanScreenState extends State<HomeIlanScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedCity;
  String? selectedDistrict;
  int _currentIndex = 3;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
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
        automaticallyImplyLeading: false,
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
        actions: [
          
          // Padding(
          //   padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          //   child: ElevatedButton(
          //     onPressed: () {
          //       Navigator.pushNamed(context, '/register');
          //     },
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.red,
          //       foregroundColor: Colors.white,
          //       elevation: 0,
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //     ),
          //     child: const Text(
          //       'Hesap Oluştur',
          //       style: TextStyle(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
      drawer: const HomeSidebar(currentPage: 'Ana Sayfa'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Section
                // Container(
                //   width: double.infinity,
                //   height: MediaQuery.of(context).size.height * 0.5,
                //   decoration: BoxDecoration(
                //     image: DecorationImage(
                //       image: const AssetImage('assets/images/office-hero.jpg'),
                //       fit: BoxFit.cover,
                //       colorFilter: ColorFilter.mode(
                //         Colors.black.withOpacity(0.5),
                //         BlendMode.darken,
                //       ),
                //     ),
                //   ),
                //   child: Stack(
                //     children: [
                //       // Kırmızı overlay gradient
                //       Container(
                //         decoration: BoxDecoration(
                //           gradient: LinearGradient(
                //             begin: Alignment.topCenter,
                //             end: Alignment.bottomCenter,
                //             colors: [
                //               Colors.transparent,
                //               Colors.red.withOpacity(0.6),
                //             ],
                //           ),
                //         ),
                //       ),
                //       // İçerik
                //       Center(
                //         child: Container(
                //           padding: const EdgeInsets.symmetric(horizontal: 20),
                //           child: Column(
                //             mainAxisAlignment: MainAxisAlignment.center,
                //             children: [
                //               const Text(
                //                 "Çok Yakında\nTüm Türkiye'deyiz!",
                //                 style: TextStyle(
                //                   fontSize: 32,
                //                   height: 1.2,
                //                   fontWeight: FontWeight.bold,
                //                   color: Colors.white,
                //                 ),
                //                 textAlign: TextAlign.center,
                //               ),
                //               const SizedBox(height: 16),
                //               const Text(
                //                 "Hadi Bize Katılın!",
                //                 style: TextStyle(
                //                   fontSize: 24,
                //                   color: Colors.white,
                //                 ),
                //                 textAlign: TextAlign.center,
                //               ),
                //               const SizedBox(height: 32),
                //               ElevatedButton(
                //                 onPressed: () {},
                //                 style: ElevatedButton.styleFrom(
                //                   backgroundColor: Colors.white,
                //                   foregroundColor: Colors.red,
                //                   padding: const EdgeInsets.symmetric(
                //                     horizontal: 32,
                //                     vertical: 16,
                //                   ),
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(8),
                //                   ),
                //                 ),
                //                 child: const Text(
                //                   "Ofis Başvurusu Yap",
                //                   style: TextStyle(
                //                     fontSize: 18,
                //                     fontWeight: FontWeight.bold,
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // Ofis Özellikleri
                // Container(
                //   padding: const EdgeInsets.all(20),
                //   child: Column(
                //     children: [
                //       const Text(
                //         "Zecorner Ofis Avantajları",
                //         style: TextStyle(
                //           fontSize: 24,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.black87,
                //         ),
                //       ),
                //       const SizedBox(height: 24),
                //       ListView(
                //         shrinkWrap: true,
                //         physics: const NeverScrollableScrollPhysics(),
                //         children: [
                //           Wrap(
                //             spacing: 16,
                //             runSpacing: 16,
                //             children: [
                //               _buildFeatureCard(
                //                 "Modern Ofis Tasarımı",
                //                 Icons.business,
                //                 "Şık ve profesyonel çalışma ortamı",
                //               ),
                //               _buildFeatureCard(
                //                 "Teknolojik Altyapı",
                //                 Icons.computer,
                //                 "Yüksek hızlı internet ve son teknoloji ekipmanlar",
                //               ),
                //               _buildFeatureCard(
                //                 "Merkezi Konum",
                //                 Icons.location_on,
                //                 "Ulaşımı kolay, prestijli lokasyonlar",
                //               ),
                //             ],
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),

                const SizedBox(height: 0),
                
                // Ofis Filtreleme ve Liste Bölümü
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red,
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // İl Seçimi
                          Container(
                            width: MediaQuery.of(context).size.width > 600 
                              ? (MediaQuery.of(context).size.width - 56) / 3 
                              : (MediaQuery.of(context).size.width - 40) / 2,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: Colors.white,
                                value: selectedCity,
                                hint: const Text("İstanbul"),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: ["İstanbul", "Ankara", "İzmir"]
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedCity = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          // İlçe Seçimi
                          Container(
                            width: MediaQuery.of(context).size.width > 600 
                              ? (MediaQuery.of(context).size.width - 56) / 3 
                              : (MediaQuery.of(context).size.width - 40) / 2,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: Colors.white,
                                value: selectedDistrict,
                                hint: const Text("Kadıköy"),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: ["Kadıköy", "Beşiktaş", "Üsküdar"]
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedDistrict = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          // Filtreyi Temizle Butonu
                          SizedBox(
                            width: MediaQuery.of(context).size.width > 600 
                              ? (MediaQuery.of(context).size.width - 56) / 3 
                              : double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedCity = null;
                                  selectedDistrict = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text("Filtreyi Temizle"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Sonuç Sayısı
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Bu Bölgede 1 ofis bulundu.",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tüm Ofisler Başlığı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tüm İlanlar",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ofis Kartları
                      buildListingCard(
                        imageUrl: 'assets/logo/ilan.png',
                        status: 'Satılık',
                        title: '3+1 Satılık Daire',
                        address: 'İstanbul / Ataşehir / Barbaros Mah.',
                        area: '150 m²',
                        rooms: '3 Oda',

                        price: '2.750.000 ₺',
                        agentName: 'Nisa Karabacak',
                        agentRole: 'Gayrimenkul Danışmanı',
                        onUpdate: () {},
                      ),
                      // _buildOfficeCard(
                      //   logo: "Cadde",
                      //   location: "İstanbul / Kadıköy / Caddebostan Mah.",
                      //   phone: "+90 (216) 711-2222",
                      //   email: "infocadde@zecorner.com",
                      //   teamCount: 25,
                      // ),
                      // const SizedBox(height: 16),
                      // _buildOfficeCard(
                      //   logo: "Prestige Office",
                      //   location: "Muğla / Bodrum / Müskebi Mh.",
                      //   phone: "+90 (252) 358-5685",
                      //   email: "infoprestigeoffice@zecorner.com",
                      //   teamCount: 0,
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfa yönlendirmeleri burada yapılabilir
          switch (index) {
            case 0:
              // Ana Sayfa
              break;
            case 1:
              // Arama
              break;
            case 2:
              // İlan Ekle
              break;
            case 3:
              // Favoriler
              break;
            case 4:
              // Profil
              break;
          }
        },
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, String description) {
    return Container(
      width: MediaQuery.of(context).size.width > 600 
        ? (MediaQuery.of(context).size.width - 72) / 3 
        : (MediaQuery.of(context).size.width - 56) / 2,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeCard({
    required String logo,
    required String location,
    required String phone,
    required String email,
    required int teamCount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.homeOfficeDetail);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromRGBO(158, 158, 158, 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Alanı
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/logo/zecorner-logo1.svg',
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    logo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Bilgi Alanı
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Konum
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Telefon
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Email
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ekip Üyeleri
                  if (teamCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+$teamCount Ekip Üyesi",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
    );
  }

  Widget buildListingCard({
    required String imageUrl,
    required String status,
    required String title,
    required String address,
    required String area,
    required String rooms,
    required String price,
    required String agentName,
    required String agentRole,
    required VoidCallback onUpdate,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üstte resim ve etiket
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  'assets/logo/ilan.png'  ,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.square_foot, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(area, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Icon(Icons.meeting_room, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(rooms, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                
              ],
            ),
          ),
          // Alt kısım: Görüntülenme ve danışman
         
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  
                  radius: 20,
                  backgroundImage: AssetImage('assets/logo/46.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        agentRole,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
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