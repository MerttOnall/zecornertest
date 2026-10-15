import 'package:flutter/material.dart';

class AddSeminarScreen extends StatefulWidget {
  const AddSeminarScreen({Key? key}) : super(key: key);

  @override
  State<AddSeminarScreen> createState() => _AddSeminarScreenState();
}

class _AddSeminarScreenState extends State<AddSeminarScreen> {
  bool isFirst = false;
  final _formKey = GlobalKey<FormState>();
  String? title, slogan1, slogan2, slogan3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE53935)),
        title: const Text(
          'Seminer Oluştur',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(238, 46, 36, 1),
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  // Başlık
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Text('Seminer Oluştur',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                  ),
                  // İlk Sırada Göster Switch
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        child: Row(
                          children: [
                            Switch(
                              value: isFirst,
                              activeColor: const Color(0xFFE53935),
                              onChanged: (v) => setState(() => isFirst = v),
                            ),
                            const SizedBox(width: 8),
                            const Text('İlk Sırada Gösterim',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(width: 6),
                            Icon(Icons.info_outline,
                                color: Color.fromRGBO(238, 46, 36, 1), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Başlık ve Slogan Kartı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: const Color.fromARGB(255, 24, 24, 24)
                                .withOpacity(0.18),
                            width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.black.withOpacity(0.08),
                          highlightColor: Colors.black.withOpacity(0.04),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: const Text(
                            'Başlık ve Slogan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 18,
                              letterSpacing: 0.1,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Seminer Başlığı',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onSaved: (v) => title = v,
                                    ),
                                    const SizedBox(height: 18),
                                    const Text('Seminer Sloganı 1',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onSaved: (v) => slogan1 = v,
                                    ),
                                    const SizedBox(height: 18),
                                    const Text('Seminer Sloganı 2',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onSaved: (v) => slogan2 = v,
                                    ),
                                    const SizedBox(height: 18),
                                    const Text('Seminer Sloganı 3',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onSaved: (v) => slogan3 = v,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Eğitmenler Kartı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: const Color.fromARGB(255, 24, 24, 24)
                                .withOpacity(0.18),
                            width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.black.withOpacity(0.08),
                          highlightColor: Colors.black.withOpacity(0.04),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: const Text(
                            'Eğitmenler',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 18,
                              letterSpacing: 0.1,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni')),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni 1')),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni 2')),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni 3')),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni 4')),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _seminarTextField(
                                              'Seminer Eğitmeni 5')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Adres Kartı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: const Color.fromARGB(255, 24, 24, 24)
                                .withOpacity(0.18),
                            width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.black.withOpacity(0.08),
                          highlightColor: Colors.black.withOpacity(0.04),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: const Text(
                            'Adres',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 18,
                              letterSpacing: 0.1,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('İl',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              dropdownColor: Colors.white,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'İstanbul',
                                                    child: Text('İstanbul')),
                                                DropdownMenuItem(
                                                    value: 'Ankara',
                                                    child: Text('Ankara')),
                                                DropdownMenuItem(
                                                    value: 'İzmir',
                                                    child: Text('İzmir')),
                                              ],
                                              onChanged: (v) {},
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('İlçe',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              dropdownColor: Colors.white,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12)),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                    value: 'Üsküdar',
                                                    child: Text('Üsküdar')),
                                                DropdownMenuItem(
                                                    value: 'Kadıköy',
                                                    child: Text('Kadıköy')),
                                                DropdownMenuItem(
                                                    value: 'Çankaya',
                                                    child: Text('Çankaya')),
                                              ],
                                              onChanged: (v) {},
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Adres',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    maxLines: 2,
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
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
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
                  // Seminer Bilgileri Kartı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: const Color.fromARGB(255, 24, 24, 24)
                                .withOpacity(0.18),
                            width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.black.withOpacity(0.08),
                          highlightColor: Colors.black.withOpacity(0.04),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: const Text(
                            'Seminer Bilgileri',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 18,
                              letterSpacing: 0.1,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Seminer Organizasyon Otel Adı',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    maxLines: 2,
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
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                      'Seminer Konum Bilgisi - Yol tarifi',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    maxLines: 2,
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
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text('Tarih ve Saat',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
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
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      suffixIcon: Icon(Icons.calendar_today,
                                          color: Color(0xFFE53935)),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text('Seminer Sıralaması',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: Colors.white,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: '1', child: Text('1')),
                                      DropdownMenuItem(
                                          value: '2', child: Text('2')),
                                      DropdownMenuItem(
                                          value: '3', child: Text('3')),
                                    ],
                                    onChanged: (v) {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Seminer Görselleri Kartı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                            color: const Color.fromARGB(255, 24, 24, 24)
                                .withOpacity(0.18),
                            width: 2),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.black.withOpacity(0.08),
                          highlightColor: Colors.black.withOpacity(0.04),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          title: const Text(
                            'Seminer Görselleri',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 18,
                              letterSpacing: 0.1,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Medya yükle kutusu
                                  Center(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        // Medya yükleme işlemi
                                      },
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.07),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.camera_alt_outlined,
                                                size: 44, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              'Medya Yükleyin',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // Açıklama maddeleri
                                  const Text(
                                    '• JPEG veya PNG formatında en fazla ',
                                    style: TextStyle(
                                        color: Colors.black87, fontSize: 14),
                                  ),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      children: [
                                        TextSpan(
                                            text: '50mb',
                                            style: TextStyle(
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' büyüklüğünde görsel dosyalarınızı yükleyiniz.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      children: [
                                        TextSpan(
                                            text: '• İşaretlediğiniz görsel, '),
                                        TextSpan(
                                            text: 'Seminer kapak fotoğrafı',
                                            style: TextStyle(
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(text: ' olarak görünecektir.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      children: [
                                        TextSpan(text: '• Resimleri '),
                                        TextSpan(
                                            text: 'sürükle bırak',
                                            style: TextStyle(
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' yaparak sıralamasını değiştirebilirsiniz.'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                          color: Colors.black87, fontSize: 14),
                                      children: [
                                        TextSpan(text: '• En fazla '),
                                        TextSpan(
                                            text: '5',
                                            style: TextStyle(
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text:
                                                ' fotoğraf yükleyebilirsiniz'),
                                      ],
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
                ],
              ),
            ),
            // Kaydet Butonu
            Positioned(
              right: 18,
              bottom: 18,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.green,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Kaydet',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  if (_formKey.currentState != null) {
                    _formKey.currentState!.save();
                    // Kayıt işlemi burada yapılabilir
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seminarTextField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
