import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen>
    with SingleTickerProviderStateMixin {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "İletişim",
          style: TextStyle(
            color: Color.fromRGBO(238, 46, 36, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hero Bölümü
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    image: DecorationImage(
                      image: const AssetImage('assets/images/pattern.png'),
                      fit: BoxFit.cover,
                      opacity: 0.03,
                      colorFilter: ColorFilter.mode(
                        Colors.red.shade900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      SvgPicture.asset(
                        'assets/logo/zecorner-logo1.svg',
                        width: 180,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Size Nasıl Yardımcı Olabiliriz?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // İletişim Kartları
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Telefon Kartı
                      _buildContactCard(
                        icon: Icons.phone_outlined,
                        title: "Bizi Arayın",
                        subtitle: "Pazartesi - Cuma 09.00 - 18.00 arasında hizmetinizdeyiz",
                        actionText: "+90 (850) 123 45 67",
                        onTap: () => _launchUrl('tel:+908501234567'),
                      ),

                      const SizedBox(height: 16),

                      // Email Kartı
                      _buildContactCard(
                        icon: Icons.email_outlined,
                        title: "E-posta Gönderin",
                        subtitle: "Size en kısa sürede dönüş yapacağız",
                        actionText: "info@zecorner.com",
                        onTap: () => _launchUrl('mailto:info@zecorner.com'),
                      ),

                      const SizedBox(height: 16),

                      // Adres Kartı
                      _buildContactCard(
                        icon: Icons.location_on_outlined,
                        title: "Ofisimizi Ziyaret Edin",
                        subtitle: "Barbaros Mah. Halk Caddesi No:1    Ataşehir / İstanbul",
                        actionText: "Haritada Göster",
                        onTap: () =>
                            _launchUrl('https://maps.google.com/?q=zecorner'),
                      ),

                      const SizedBox(height: 32),

                      // Sosyal Medya Bölümü
                      const Text(
                        "Sosyal Medyada Bizi Takip Edin",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            'assets/logo/face.svg',
                            () => _launchUrl('https://www.facebook.com/zecorner.turkiye'),
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            'assets/logo/insta.svg',
                            () => _launchUrl('https://www.instagram.com/zecornertr/'),
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            'assets/logo/linkedin.svg',
                            () => _launchUrl(
                                'https://www.linkedin.com/company/zecorner?trk=public_jobs_topcard_logo'),
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            'assets/logo/x.svg',
                            () => _launchUrl(
                                'https://x.com/zecornerr?s=21&t=frTDZvAoazqRxd3v96ANTg'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          CustomBottomNavbar(currentIndex: 4, onTap: (index) {}),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(238, 46, 36, 1),
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

  Widget _buildSocialButton(String iconPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFFE53935),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    } else {
      throw Exception('Could not launch $url');
    }
  }

}
