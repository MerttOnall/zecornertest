import 'package:flutter/material.dart';
import 'package:zecorner/presentation/home-screens/home_danisman_screen.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeIlanDetayScreen extends StatefulWidget {
  final Map<String, dynamic> ilan;
  const HomeIlanDetayScreen({required this.ilan, super.key});

  @override
  State<HomeIlanDetayScreen> createState() => _HomeIlanDetayScreenState();
}

class _HomeIlanDetayScreenState extends State<HomeIlanDetayScreen> with SingleTickerProviderStateMixin {
  bool isFavorite = false; // Favori durumu
  int _currentIndex = 3;

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
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
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
    final List<String> images = widget.ilan['images'] != null
        ? List<String>.from(widget.ilan['images'])
        : [if (widget.ilan['image'] != null) widget.ilan['image'] as String];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
        elevation: 1,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            children: [
              // Galeri
              SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, i) => _image(images[i]),
                ),
              ),
              const SizedBox(height: 18),
              // Kart
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve fiyat
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.ilan['title'] as String? ?? 'Belirtilmedi',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 18,
                                          color: Color.fromRGBO(238, 46, 36, 1)),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.ilan['location'] as String? ?? 'Belirtilmedi',
                                        style: const TextStyle(
                                            fontSize: 15, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Favori ve Paylaş butonları
                            Row(
                              children: [
                                // Favori butonu
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isFavorite = !isFavorite;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Color(0xFFE53935) : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Paylaş butonu
                                GestureDetector(
                                  onTap: () {
                                    // Paylaşım fonksiyonu buraya eklenecek
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.share_outlined,
                                      color: Colors.red[600],
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.ilan['priceStr'] as String? ??
                              widget.ilan['price']?.toString() ??
                              '0',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(238, 46, 36, 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Temel bilgiler
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        _infoTile(Icons.meeting_room, 'Oda',
                            widget.ilan['oda']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.square_foot, 'm²',
                            widget.ilan['m2']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.calendar_today, 'Bina Yaşı',
                            widget.ilan['binaYasi']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.layers, 'Kat',
                            widget.ilan['kat']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.home_work, 'Tip',
                            widget.ilan['tip']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.whatshot, 'Isıtma',
                            widget.ilan['isitma']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.chair, 'Eşyalı',
                            widget.ilan['esyalı']?.toString() ?? 'Belirtilmedi'),
                        _infoTile(Icons.verified_user, 'Site İçi',
                            widget.ilan['siteIci']?.toString() ?? 'Belirtilmedi'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Etiketler
                    if (widget.ilan['etiketler'] != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final etiket in (widget.ilan['etiketler'] as List<String>))
                            _chip(etiket),
                        ],
                      ),
                    const SizedBox(height: 18),
                    // Açıklama
                    if (widget.ilan['aciklama'] != null) ...[
                      const Text(
                        'Açıklama',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.ilan['aciklama'] as String,
                        style: const TextStyle(
                            fontSize: 15, color: Colors.black87, height: 1.6),
                      ),
                      const SizedBox(height: 28),
                    ],
                    // GENEL ÖZELLİKLER
                    const Text(
                      'Genel Özellikler',
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _genelOzelliklerTable(),
                    const SizedBox(height: 18),
                    // İÇ ÖZELLİKLER
                    const Text(
                      'İç Özellikler',
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ozelliklerTable([
                      ['Teras', 'Panjur/Jaluzi'],
                      ['Çelik Kapı', 'Duşakabin'],
                      ['Amerikan Kapı', 'Laminat Zemin'],
                    ]),
                    const SizedBox(height: 32),
                    // MUHİT
                    const Text(
                      'Muhit',
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ozelliklerTable([
                      ['Cami', 'İlkokul-Ortaokul'],
                      ['Market', 'Semt Pazarı'],
                    ]),
                    const SizedBox(height: 32),
                    // ULAŞIM
                    const Text(
                      'Ulaşım',
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ozelliklerTable([
                      ['Anayol', 'Cadde'],
                      ['Minibüs', 'Dolmuş'],
                    ]),
                    const SizedBox(height: 32),
                    // MANZARA
                    const Text(
                      'Manzara',
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ozelliklerTable([
                      ['Deniz', 'Doğa'],
                    ]),
                    const SizedBox(height: 18),

                    emlakciKarti(
                      context: context,
                      name: (widget.ilan['owner'] as Map<String, dynamic>?)?['name'] ??
                          'Halis Arslan',
                      role: (widget.ilan['owner'] as Map<String, dynamic>?)?['role'] ??
                          'Gayrimenkul Danışmanı',
                      imageUrl:
                          (widget.ilan['owner'] as Map<String, dynamic>?)?['image'] ?? '',
                      email: (widget.ilan['owner'] as Map<String, dynamic>?)?['email'] ??
                          'halis.arslan@zecorner.com',
                      phone: (widget.ilan['owner'] as Map<String, dynamic>?)?['phone'] ??
                          '0555 555 55 55',
                      onCall: () {},
                      onMessage: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // İstersen burada sayfa geçişi ekleyebilirsin
        },
      ),
    );
  }

  Widget _image(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
      );

  Widget _infoTile(IconData icon, String label, String value) => Container(
        constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color.fromRGBO(238, 46, 36, 1), size: 16),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _chip(String label) => Chip(
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color.fromRGBO(238, 46, 36, 1))),
        backgroundColor: const Color(0xFFFDE8E7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      );

  Widget _genelOzelliklerTable() => Table(
        children: [
          TableRow(
            children: [
              _tableCell('İlan Türü'),
              _tableCell(widget.ilan['tip']?.toString() ?? 'Belirtilmedi'),
            ],
          ),
          TableRow(
            children: [
              _tableCell('İlan Durumu'),
              _tableCell(widget.ilan['durum']?.toString() ?? 'Belirtilmedi'),
            ],
          ),
          TableRow(
            children: [
              _tableCell('İlan Fiyatı'),
              _tableCell(widget.ilan['priceStr'] as String? ??
                  widget.ilan['price']?.toString() ??
                  '0'),
            ],
          ),
          TableRow(
            children: [
              _tableCell('İlan Konumu'),
              _tableCell(widget.ilan['location']?.toString() ?? 'Belirtilmedi'),
            ],
          ),
        ],
      );

  Widget _ozelliklerTable(List<List<String>> data) => Table(
        children: [
          for (final row in data)
            TableRow(
              children: [
                _tableCell(row[0]),
                _tableCell(row[1]),
              ],
            ),
        ],
      );

  Widget _tableCell(String text) => TableCell(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      );

  Widget _staticMapBox() => Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/logo/46.png',
            fit: BoxFit.cover,
          ),
        ),
      );

  // Modern ve responsive emlakçı kartı
  Widget emlakciKarti({
    required BuildContext context,
    required String name,
    required String role,
    required String imageUrl,
    String? email,
    String? phone,
    VoidCallback? onCall,
    VoidCallback? onMessage,
  }) {
    final double width = MediaQuery.of(context).size.width * 0.97;
    const mainRed = Color(0xFFEE2E24);

    return Center(
      child: Container(
        width: width > 420 ? 420 : width,
        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.13),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFDE8E7),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kırmızı banner ve avatar
            Container(
              decoration: BoxDecoration(
                color: mainRed,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.only(top: 28, bottom: 18),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: mainRed.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? ClipOval(
                            child: Image.asset(
                              'assets/logo/46.png',
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: mainRed,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.05,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (email != null && email.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: mainRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: mainRed.withOpacity(0.18), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.email, size: 18, color: mainRed),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(email,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: mainRed,
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  if (phone != null && phone.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: mainRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: mainRed.withOpacity(0.18), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 18, color: mainRed),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(phone,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: mainRed,
                                      fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.phone,
                              color: Colors.white, size: 20),
                          label: const Text('Ara',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainRed,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMessage,
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: mainRed, size: 20),
                          label: const Text('Mesaj Gönder',
                              style: TextStyle(
                                  color: mainRed, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: mainRed, width: 1.7),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/home-danisman',
                              arguments: {
                                'consultantId': 'test-danisman',
                                'consultantName': 'Test Danışman',
                                'consultantTitle': 'Emlak Danışmanı',
                                'consultantEmail': 'test@zecorner.com',
                                'consultantPhone': '+90 555 123 45 67',
                                'consultantContactNo': 40, // Test Contact No
                              }
                            );
                          },
                          icon: const Icon(Icons.person_2_outlined,
                              color: Colors.white, size: 20),
                          label: const Text('Danışman Sayfasına Git',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainRed,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Alt kırmızı şerit
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: mainRed,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Kırmızı şerit için painter
class _RedDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.25, size.height * 0.2);
    path.lineTo(size.width * 0.75, size.height * 0.8);
    path.lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
