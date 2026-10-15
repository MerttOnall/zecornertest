import 'package:flutter/material.dart';

class AddSssScreen extends StatefulWidget {
  const AddSssScreen({Key? key}) : super(key: key);

  @override
  State<AddSssScreen> createState() => _AddSssScreenState();
}

class _AddSssScreenState extends State<AddSssScreen> {
  bool status = true;
  int selectedLang = 0; // 0: Türkçe, 1: English
  String? selectedCategory;
  String? selectedOrder;
  final _formKey = GlobalKey<FormState>();

  final List<String> categories = [
    'Zecorner',
    'Gayrimenkul Danışmanlığı',
    'Franchise Broker / Ofis Sistemi',
  ];
  final List<String> orders = ['1', '2', '3', '4', '5'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık ve çarpı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SSS Oluştur', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Durum switch
                      Row(
                        children: [
                          Switch(
                            value: status,
                            onChanged: (v) => setState(() => status = v),
                            activeColor: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          const Text('Durum', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline, color: Colors.red, size: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Dil sekmeleri
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => selectedLang = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: selectedLang == 0 ? Colors.red : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Türkçe',
                                      style: TextStyle(
                                        color: selectedLang == 0 ? Colors.white : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => selectedLang = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: selectedLang == 1 ? Colors.red : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'English',
                                      style: TextStyle(
                                        color: selectedLang == 1 ? Colors.white : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      // SSS Soru Başlığı
                      const Text('SSS Soru Başlığı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: TextFormField(
                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              width: 2,
                            ),
                          ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // SSS Kategorisi
                      const Text('SSS Kategorisi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          hint: const Text('Kategori seçin'),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => selectedCategory = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // SSS Sıralaması
                      const Text('SSS Sıralaması', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: DropdownButtonFormField<String>(
                          value: selectedOrder,
                          hint: const Text('Sıralama seçin'),
                          items: orders.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                          onChanged: (v) => setState(() => selectedOrder = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // SSS Soru Cevabı (zengin metin editörü placeholder)
                      const Text('SSS Soru Cevabı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              // Zengin editör toolbarı (placeholder)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: const [
                                    Text('Normal', style: TextStyle(fontWeight: FontWeight.w500)),
                                    SizedBox(width: 10),
                                    Icon(Icons.format_bold, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.format_italic, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.format_underline, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.link, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.format_list_bulleted, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.format_list_numbered, size: 20),
                                    SizedBox(width: 6),
                                    Icon(Icons.format_clear, size: 20),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              TextFormField(
                                maxLines: 6,
                                minLines: 4,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(238, 46, 36, 1),
                              width: 2,
                            ),
                          ),
                                  hintText: 'SSS cevabını girin...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Kaydet butonu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          child: const Text('Kaydet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 