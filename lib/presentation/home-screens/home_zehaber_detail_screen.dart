import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeZehaberDetailScreen extends StatelessWidget {
  const HomeZehaberDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: SvgPicture.asset(
          'assets/logo/zecorner-logo1.svg',
          width: 140,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Haber Görseli
            Image.network(
              'https://picsum.photos/800/400',
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
            
            // Haber İçeriği
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Emlak Haberleri",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Başlık
                  const Text(
                    "Şubat 2025 Kira Artış Oranı Açıklandı! Kiracı ve Ev Sahipleri Dikkat! İşte Şubat 2025 Kira Hesaplaması",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tarih
                  Text(
                    "15 Mart 2024",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // İçerik
                  Text(
                    "Şubat 2025 kira artış oranı TÜİK tarafından açıklandı. Kiracılar ve ev sahiplerinin merakla beklediği kira artış oranı belli oldu. İşte detaylar...",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Alt başlık
                  const Text(
                    "Kira Artış Oranı Nasıl Hesaplanır?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // İçerik devamı
                  Text(
                    "Kira artış oranı, Türkiye İstatistik Kurumu tarafından açıklanan TÜFE'nin 12 aylık ortalamasına göre belirlenir. Bu oran, kiracı ve ev sahibi arasındaki sözleşme yenilenmesinde kullanılır...",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[800],
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
} 