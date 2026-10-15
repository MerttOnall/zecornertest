import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeProfileKvkkScreen extends StatefulWidget {
  const HomeProfileKvkkScreen({super.key});

  @override
  State<HomeProfileKvkkScreen> createState() => _HomeProfileKvkkScreenState();
}

class _HomeProfileKvkkScreenState extends State<HomeProfileKvkkScreen> with SingleTickerProviderStateMixin {
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

  void _openPdf(BuildContext context, String assetPath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.white,
            foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
            elevation: 1,
          ),
          body: SfPdfViewer.asset(assetPath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('KVKK Bilgilendirme'),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromRGBO(238, 46, 36, 1),
        elevation: 1,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "KVKK Aydınlatma ve Açık Rıza Metinleri",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromRGBO(238, 46, 36, 1)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Aşağıdaki dökümanları inceleyerek kişisel verilerin korunması ve işlenmesi hakkında detaylı bilgi alabilirsiniz.",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                _buildPdfTile(
                  context,
                  title: "KVKK Aydınlatma Metni (PDF)",
                  assetPath: "assets/pdfs/KİŞİSEL VERİLERİN KORUNMASINA İLİŞKİN AYDINLATMA METNİ.pdf",
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(currentIndex: 4, onTap: (index) {}),
    );
  }

  Widget _buildPdfTile(BuildContext context, {required String title, required String assetPath}) {
    return InkWell(
      onTap: () => _openPdf(context, assetPath, title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFF2B8B5), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.13),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Color.fromRGBO(238, 46, 36, 1), size: 32),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color.fromRGBO(238, 46, 36, 1)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
