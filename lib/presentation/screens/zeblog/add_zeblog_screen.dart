import 'package:flutter/material.dart';

class AddZeblogScreen extends StatefulWidget {
  const AddZeblogScreen({super.key});

  @override
  State<AddZeblogScreen> createState() => _AddZeblogScreenState();
}

class _AddZeblogScreenState extends State<AddZeblogScreen> {
  bool isActive = true;
  bool isFeatured = false;
  String selectedCategory = "Gayrimenkul Danışmanlığı";
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Blog Ekle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.home, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "ZeOnline",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
                  Text(
                    "Blog",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
                  Text(
                    "Blog Detay",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[600]),
                  const Text(
                    "Blog Ekle",
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
            // Form Alanları
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Durum ve Sıralama Bölümü
                  _buildSectionTitle("Durum ve Sıralama"),
                  const SizedBox(height: 16),

                  // Durum Switch
                  Row(
                    children: [
                      const Text(
                        "Durum",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Öne Çıkan Bloglar Switch
                  Row(
                    children: [
                      const Text(
                        "Öne Çıkan Bloglar",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isFeatured,
                        onChanged: (value) {
                          setState(() {
                            isFeatured = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Öne Çıkan Bloglar Sıralaması
                  const Text(
                    "Öne Çıkan Bloglar Sıralaması",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: "1",
                        isExpanded: true,
                        items:
                            List.generate(10, (index) => (index + 1).toString())
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                        onChanged: (value) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // İçerik ve Kategori Bölümü
                  _buildSectionTitle("İçerik ve Kategori"),
                  const SizedBox(height: 16),

                  // Blog Kategorisi
                  const Text(
                    "Blog Kategorisi",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.white,
                        value: selectedCategory,
                        isExpanded: true,
                        items: [
                          "Gayrimenkul Danışmanlığı",
                          "Emlak Sektörü",
                          "Yatırım Tavsiyeleri"
                        ]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Blog Başlığı
                  const Text(
                    "Blog Başlığı",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue:
                        "Şufa Hakkı (Önalım Hakkı) Nedir? Gayrimenkul Alım-Satımında Bilinmesi Gerekenler",
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(238, 46, 36, 1),
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Blog İçeriği
                  const Text(
                    "Blog İçeriği",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Araç Çubuğu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  value: "Normal",
                                  items: ["Normal"]
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (value) {},
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_bold),
                                onPressed: () {},
                                color: Colors.grey[700],
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic),
                                onPressed: () {},
                                color: Colors.grey[700],
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_underline),
                                onPressed: () {},
                                color: Colors.grey[700],
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () {},
                                color: Colors.grey[700],
                                iconSize: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // İçerik Alanı
                        TextFormField(
                          maxLines: 6,
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(238, 46, 36, 1),
                                width: 2,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Yazar Bilgileri Bölümü
                  _buildSectionTitle("Yazar Bilgileri"),
                  const SizedBox(height: 16),

                  // Yazar Adı
                  const Text(
                    "Yazar Adı",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: "Nisa",
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(238, 46, 36, 1),
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Yazar Soyadı
                  const Text(
                    "Yazar Soyadı",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: "Karabacak",
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(238, 46, 36, 1),
                          width: 2,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Haber Görselleri Bölümü
                  _buildSectionTitle("Haber Görselleri"),
                  const SizedBox(height: 16),

                  // Görsel Yükleme Alanları
                  Row(
                    children: [
                      // Medya Yükleme Alanı
                      Container(
                        width: 146,
                        height: 190,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 40, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                "Medya Yükleyin",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Yüklenmiş Görsel
                      Container(
                        width: 146,
                        height: 190,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                          image: const DecorationImage(
                            image:
                                NetworkImage('https://picsum.photos/146/190'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bilgilendirme Metinleri
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(text: "• JPEG veya PNG formatında en fazla "),
                        TextSpan(
                          text: "50mb",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                            text:
                                " büyüklüğünde görsel dosyalarınızı yükleyiniz.\n"),
                        TextSpan(text: "• İşaretlediğiniz görsel, "),
                        TextSpan(
                          text: "Haber kapak fotoğrafı",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(text: " olarak görünecektir.\n"),
                        TextSpan(text: "• Resimleri "),
                        TextSpan(
                          text: "sürükle bırak",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                            text:
                                " yaparak sıralamasını değiştirebilirsiniz.\n"),
                        TextSpan(text: "• En fazla "),
                        TextSpan(
                          text: "10",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(text: " fotoğraf yükleyebilirsiniz"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Kaydet",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }
}
