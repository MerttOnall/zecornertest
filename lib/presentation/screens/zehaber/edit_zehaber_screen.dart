import 'package:flutter/material.dart';

class EditZehaberScreen extends StatefulWidget {
  const EditZehaberScreen({super.key});

  @override
  State<EditZehaberScreen> createState() => _EditZehaberScreenState();
}

class _EditZehaberScreenState extends State<EditZehaberScreen> {
  bool isActive = true;
  bool isFeatured = false;
  String selectedCategory = "Gayrimenkul Haberleri";
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
          'Haber Oluştur',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih ve Sıralama Bölümü
              _buildSectionTitle("Tarih ve Sıralama"),
              const SizedBox(height: 16),

              // Durum Switch
              Row(
                children: [
                  const Text(
                    "Durum",
                    style: TextStyle(fontSize: 16),
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
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Öne Çıkan Haberler Switch
              Row(
                children: [
                  const Text(
                    "Öne Çıkan Haberler",
                    style: TextStyle(fontSize: 16),
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
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Öne Çıkan Haberler Sıralaması
              const Text(
                "Öne Çıkan Haberler Sıralaması",
                style: TextStyle(fontSize: 16),
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
                    items: List.generate(10, (index) => (index + 1).toString())
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {},
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Yayınlanma Tarihi
              const Text(
                "Yayınlanma Tarihi",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} - ${selectedDate.hour}:${selectedDate.minute}",
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // İçerik ve Kategori Bölümü
              _buildSectionTitle("İçerik ve Kategori"),
              const SizedBox(height: 16),

              // Haber Kategorisi
              const Text(
                "Haber Kategorisi",
                style: TextStyle(fontSize: 16),
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
                      "Gayrimenkul Haberleri",
                      "Konut Projeleri",
                      "Yatırım Fırsatları"
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

              // Haber Başlığı
              const Text(
                "Haber Başlığı",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              width: 2,
                            ),
                          ),
                  hintText: "Konut Fiyat Endeksi Martta Yüzde 2, Yıllık Yüzde 32,3 Arttı!",
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

              // Haber İçeriği
              const Text(
                "Haber İçeriği",
                style: TextStyle(fontSize: 16),
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
                      child: Wrap(
                        spacing: 2,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: Colors.white,
                              value: "Normal",
                              items: ["Normal"].map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )).toList(),
                              onChanged: (value) {},
                              iconSize: 18,
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
                          IconButton(
                            icon: const Icon(Icons.format_list_bulleted),
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
                            icon: const Icon(Icons.format_list_numbered),
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
                            icon: const Icon(Icons.text_fields),
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
                      maxLines: 10,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              width: 2,
                            ),
                          ),
                        hintText: "Türkiye Cumhuriyet Merkez Bankası verilerine göre Konut Fiyat Endeksi (KFE), Mart 2025'te aylık yüzde 2, yıllık yüzde 32,3 arttı.",
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
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: "Emlak",
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
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: "Kulisi",
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

              // Görsel Yükleme Alanı
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
                    Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[600]),
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
              const SizedBox(height: 16),

              // Yüklenen Görseller
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(
                          image: NetworkImage('https://picsum.photos/80/80'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
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
                        ],
                      ),
                    );
                  },
                ),
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
                    TextSpan(text: " büyüklüğünde görsel dosyalarınızı yükleyiniz.\n"),
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
                    TextSpan(text: " yaparak sıralamasını değiştirebilirsiniz.\n"),
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

              // Kaydet Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Burada kaydetme işlemleri yapılabilir

                    // Önceki sayfaya dön
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              SizedBox(height: 20,)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
    );
  }
}
