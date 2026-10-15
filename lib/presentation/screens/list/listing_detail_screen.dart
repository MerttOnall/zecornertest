import 'package:flutter/material.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key});

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
          "İlan Detayı",
          style: TextStyle(
            color: Color.fromRGBO(238, 46, 36, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlan Durumu ve Görüntülenme
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    "Yeni Kiralık İlan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "İptal Edildi",
                      style: TextStyle(
                        color: Color.fromRGBO(238, 46, 36, 1),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.remove_red_eye_outlined, 
                          size: 14, 
                          color: Colors.grey[600]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "2 görüntülenme",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fotoğraf Galerisi
            Container(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView(
                    children: [
                      Image.network(
                        'https://picsum.photos/800/600',
                        fit: BoxFit.cover,
                      ),
                      Image.network(
                        'https://picsum.photos/800/601',
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                  // Fotoğraf sayısı indikatörü
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "1/2",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // İlan Bilgileri
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fiyat ve Portföy No
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "KİRALIK",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          "Portföy No: 117921",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Konum
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, 
                          size: 16, 
                          color: Colors.grey[600]
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "İstanbul / Bağcılar / 100. Yıl Mh.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fiyat
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          "₺",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "15.000",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Genel Özellikler
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Genel Özellikler",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPropertySection([
                          _buildPropertyItem("m² (Brüt)", "120"),
                          _buildPropertyItem("m² (Net)", "100"),
                          _buildPropertyItem("Oda Sayısı", "1.5+1"),
                          _buildPropertyItem("Bina Yaşı", "1"),
                          _buildPropertyItem("Bulunduğu Kat", "13"),
                          _buildPropertyItem("Kat Sayısı", "26"),
                          _buildPropertyItem("Isıtma", "Kat Kaloriferi"),
                          _buildPropertyItem("Banyo Sayısı", "2"),
                          _buildPropertyItem("Balkon", "Yok"),
                        ]),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Diğer Özellikler
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Diğer Özellikler",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPropertySection([
                          _buildPropertyItem("Otopark", "Açık Otopark"),
                          _buildPropertyItem("Eşyalı", "Hayır"),
                          _buildPropertyItem("Aidat (TL)", "5000"),
                          _buildPropertyItem("Cephe", "Doğu"),
                          _buildPropertyItem("Dış Özellikler", "Apartman Görevlisi"),
                          _buildPropertyItem("Muhit", "Cami"),
                          _buildPropertyItem("Ulaşım", "Boğaz Köprüleri"),
                          _buildPropertyItem("Manzara", "Doğa"),
                          _buildPropertyItem("Engelliye ve Yaşlıya Uygun", "Bariyersiz"),
                        ]),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // İç Özellikler
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "İç Özellikler",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPropertySection([
                          _buildPropertyItem("Ahşap Doğrama", "Var"),
                          _buildPropertyItem("Akıllı Ev", "Var"),
                          _buildPropertyItem("Barbekü", "Var"),
                          _buildPropertyItem("Çelik Kapı", "Var"),
                        ]),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Konut Tipi
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Konut Tipi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPropertySection([
                          _buildPropertyItem("Bahçe Dubleksi", "Var"),
                          _buildPropertyItem("Ara Kat Dubleks", "Var"),
                        ]),
                      ],
                    ),
                  ),

                  // Depozito bilgisi
                  const Divider(height: 1),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Depozito (TL)",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          "15000",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySection(List<Widget> items) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
      children: items,
    );
  }

  Widget _buildPropertyItem(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 