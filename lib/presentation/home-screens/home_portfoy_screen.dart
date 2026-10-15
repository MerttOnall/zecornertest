import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomePortfoyScreen extends StatefulWidget {
  const HomePortfoyScreen({super.key});

  @override
  State<HomePortfoyScreen> createState() => _HomePortfoyScreenState();
}

class _HomePortfoyScreenState extends State<HomePortfoyScreen>
    with SingleTickerProviderStateMixin {
  String selectedType = 'Konut';
  String selectedPortfolioType = 'Daire';
  bool showDaireFeatures = false;

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
    _scaleAnim = Tween<double>(begin: 0.98, end: 1.0).animate(
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portföy Tipi (Sabit)
                        const Text(
                          "Portföy Tipi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(238, 46, 36, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              _buildTypeOption("Konut"),
                              _buildTypeOption("İş Yeri"),
                              _buildTypeOption("Arsa"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: ButtonTheme(
                              alignedDropdown: true,
                              child: DropdownButton<String>(
                                dropdownColor: Colors.white,
                                value: selectedPortfolioType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: [
                                  "Daire",
                                  "Rezidans",
                                  "Müstakil Ev",
                                  "Villa",
                                  "Çiftlik Evi",
                                  "Köşk & Konak",
                                  "Yalı",
                                  "Yalı Dairesi",
                                  "Yazlık"
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedPortfolioType = newValue!;
                                    showDaireFeatures = newValue == "Daire";
                                  });
                                },
                                hint: const Text(
                                  "Konut tipi seçiniz",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 0),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.white,
                        //     borderRadius: BorderRadius.circular(8),
                        //     border: Border.all(color: Colors.grey[300]!),
                        //   ),
                        //   child: TextFormField(
                        //     decoration: const InputDecoration(
                        //       hintText: "Konut tipi seçiniz",
                        //       border: InputBorder.none,
                        //       contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        //       suffixIcon: Icon(Icons.keyboard_arrow_down),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 24),

                        // Dropdown'lar
                        ExpansionTile(
                          title: const Text(
                            "Portföy Görselleri",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          collapsedBackgroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Görsel yükleme alanı
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Medya Yükleyin",
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Dosya formatı ve bilgiler
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text:
                                              "• JPEG veya PNG formatında en fazla ",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                        TextSpan(
                                          text: "50mb",
                                          style: TextStyle(
                                              color: Color(0xFFE53935)),
                                        ),
                                        TextSpan(
                                          text:
                                              " büyüklüğünde görsel dosyalarınızı yükleyiniz.",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: "• Resimleri ",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                        TextSpan(
                                          text: "sürükle bırak",
                                          style: TextStyle(
                                              color: Color(0xFFE53935)),
                                        ),
                                        TextSpan(
                                          text:
                                              " yaparak sıralamasını değiştirebilirsiniz.",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: const TextSpan(
                                      style: TextStyle(fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: "• En fazla ",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                        TextSpan(
                                          text: "35",
                                          style: TextStyle(
                                              color: Color(0xFFE53935)),
                                        ),
                                        TextSpan(
                                          text: " fotoğraf yükleyebilirsiniz",
                                          style:
                                              TextStyle(color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ExpansionTile(
                          title: const Text(
                            "Başlık ve Açıklama",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          collapsedBackgroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Başlık ve açıklama form alanları
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        labelText: "Portföy Başlığı",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            _buildFormatButton("Normal"),
                                            _buildFormatButton("B"),
                                            _buildFormatButton("I"),
                                            _buildFormatButton("U"),
                                            _buildFormatButton("🔗"),
                                          ],
                                        ),
                                        TextFormField(
                                          maxLines: 5,
                                          decoration: InputDecoration(
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Color.fromRGBO(238, 46, 36, 1),
                                                width: 2,
                                              ),
                                            ),
                                            hintText:
                                                "Portföy ile alakalı size ait açıklamalarınızı buraya girebilirsiniz",
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.all(16),
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
                        const SizedBox(height: 16),

                        ExpansionTile(
                          title: const Text(
                            "Adres",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          collapsedBackgroundColor: Colors.white,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // İl, İlçe, Mahalle seçimleri ve harita
                                  // İl Seçimi
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        hintText: "İl Seçiniz",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        suffixIcon: const Icon(
                                            Icons.keyboard_arrow_down),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // İlçe Seçimi
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        hintText: "İlçe Seçiniz",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        suffixIcon: const Icon(
                                            Icons.keyboard_arrow_down),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Mahalle Seçimi
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color.fromRGBO(238, 46, 36, 1),
                                            width: 2,
                                          ),
                                        ),
                                        hintText: "Mahalle Seçiniz",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16),
                                        suffixIcon: const Icon(
                                            Icons.keyboard_arrow_down),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Harita
                                  Container(
                                    height: 400,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Column(
                                      children: [
                                        // Harita/Uydu seçimi
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                  color: Colors.grey[300]!),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE53935),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  "Harita",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                child: Text(
                                                  "Uydu",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              // Tam ekran butonu
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey[300]!),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.fullscreen,
                                                  size: 20,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Harita alanı
                                        Expanded(
                                          child: Container(
                                            color: Colors.grey[200],
                                            child: Stack(
                                              children: [
                                                // Harita görüntüsü burada olacak
                                                Center(
                                                  child: Icon(
                                                    Icons.map,
                                                    size: 100,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                // Zoom butonları
                                                Positioned(
                                                  right: 16,
                                                  bottom: 16,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.1),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                            Icons.add,
                                                            size: 20),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.1),
                                                              blurRadius: 4,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Icon(
                                                            Icons.remove,
                                                            size: 20),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
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
                        const SizedBox(height: 16),

                        if (showDaireFeatures) ...[
                          ExpansionTile(
                            title: const Text("Özellikler"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    // m² (Brüt)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                              width: 2,
                                            ),
                                          ),
                                          labelText: "m² (Brüt)",
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // m² (Net)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                              width: 2,
                                            ),
                                          ),
                                          labelText: "m² (Net)",
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // Oda Sayısı
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint:
                                                      const Text("Oda Sayısı"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: [
                                                    "1+0",
                                                    "1+1",
                                                    "2+1",
                                                    "3+1",
                                                    "4+1",
                                                    "5+1",
                                                    "6+1",
                                                    "7+"
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Bina Yaşı
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text("Bina Yaşı"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: [
                                                    "0",
                                                    "1-5",
                                                    "5-10",
                                                    "10-15",
                                                    "15-20",
                                                    "20+"
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // Bulunduğu Kat
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text(
                                                      "Bulunduğu Kat"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: [
                                                    "Bodrum",
                                                    "Zemin",
                                                    "1",
                                                    "2",
                                                    "3",
                                                    "4",
                                                    "5",
                                                    "6",
                                                    "7",
                                                    "8",
                                                    "9",
                                                    "10+"
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Kat Sayısı
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint:
                                                      const Text("Kat Sayısı"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: [
                                                    "1",
                                                    "2",
                                                    "3",
                                                    "4",
                                                    "5",
                                                    "6",
                                                    "7",
                                                    "8",
                                                    "9",
                                                    "10+"
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // Isıtma
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text("Isıtma"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: [
                                                    "Doğalgaz",
                                                    "Merkezi",
                                                    "Klima",
                                                    "Soba",
                                                    "Yok"
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Banyo Sayısı
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text(
                                                      "Banyo Sayısı"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: ["1", "2", "3", "4+"]
                                                      .map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    Row(
                                      children: [
                                        // Balkon
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text("Balkon"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: ["Var", "Yok"]
                                                      .map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Eşyalı
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.grey[300]!),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: ButtonTheme(
                                                alignedDropdown: true,
                                                child: DropdownButton<String>(
                                                  dropdownColor: Colors.white,
                                                  isExpanded: true,
                                                  hint: const Text("Eşyalı"),
                                                  icon: const Icon(Icons
                                                      .keyboard_arrow_down),
                                                  items: ["Evet", "Hayır"]
                                                      .map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) {},
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Aidat (TL)
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                              width: 2,
                                            ),
                                          ),
                                          hintText:
                                              "Aidat bilinmiyor ise 0 giriniz.",
                                          labelText: "Aidat (TL)",
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Taşınmaz Numarası
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Color.fromRGBO(238, 46, 36, 1),
                                              width: 2,
                                            ),
                                          ),
                                          hintText:
                                              "Maksimum 10 karakterden oluşabilir.",
                                          labelText: "Taşınmaz Numarası",
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                        ),
                                        maxLength: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Cephe"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Batı"),
                                          _buildCheckboxItem("Doğu"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Güney"),
                                          _buildCheckboxItem("Kuzey"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("İç Özellikler"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("ADSL"),
                                          _buildCheckboxItem("Alarm (Yangın)"),
                                          _buildCheckboxItem("Amerikan Mutfak"),
                                          _buildCheckboxItem("Boyalı"),
                                          _buildCheckboxItem(
                                              "Çamaşır Makinesi"),
                                          _buildCheckboxItem("Duvar Kağıdı"),
                                          _buildCheckboxItem("Giyinme Odası"),
                                          _buildCheckboxItem(
                                              "Intercom Sistemi"),
                                          _buildCheckboxItem("Kiler"),
                                          _buildCheckboxItem("Marley"),
                                          _buildCheckboxItem(
                                              "Mutfak Doğalgazı"),
                                          _buildCheckboxItem("Seramik Zemin"),
                                          _buildCheckboxItem("Şömine"),
                                          _buildCheckboxItem("Wi-Fi"),
                                          _buildCheckboxItem("Ahşap Doğrama"),
                                          _buildCheckboxItem(
                                              "Alaturka Tuvalet"),
                                          _buildCheckboxItem("Ankastre Fırın"),
                                          _buildCheckboxItem(
                                              "Bulaşık Makinesi"),
                                          _buildCheckboxItem("Çamaşır Odası"),
                                          _buildCheckboxItem("Ebeveyn Banyosu"),
                                          _buildCheckboxItem("Gömme Dolap"),
                                          _buildCheckboxItem("Isıcam"),
                                          _buildCheckboxItem("Klima"),
                                          _buildCheckboxItem("Mobilya"),
                                          _buildCheckboxItem("Panjur/Jaluzi"),
                                          _buildCheckboxItem("Set Üstü Ocak"),
                                          _buildCheckboxItem("Teras"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Akıllı Ev"),
                                          _buildCheckboxItem(
                                              "Alüminyum Doğrama"),
                                          _buildCheckboxItem("Barbekü"),
                                          _buildCheckboxItem("Buzdolabı"),
                                          _buildCheckboxItem("Çelik Kapı"),
                                          _buildCheckboxItem("Fiber İnternet"),
                                          _buildCheckboxItem(
                                              "Görüntülü Diafon"),
                                          _buildCheckboxItem("Jakuzi"),
                                          _buildCheckboxItem("Küvet"),
                                          _buildCheckboxItem(
                                              "Mutfak (Ankastre)"),
                                          _buildCheckboxItem("Parke Zemin"),
                                          _buildCheckboxItem("Spot Aydınlatma"),
                                          _buildCheckboxItem("Termosifon"),
                                          _buildCheckboxItem(
                                              "Yüz Tanıma & Parmak İzi"),
                                          _buildCheckboxItem("Alarm (Hırsız)"),
                                          _buildCheckboxItem("Amerikan Kapı"),
                                          _buildCheckboxItem("Beyaz Eşya"),
                                          _buildCheckboxItem(
                                              "Çamaşır Kurutma Makinesi"),
                                          _buildCheckboxItem("Duşakabin"),
                                          _buildCheckboxItem("Fırın"),
                                          _buildCheckboxItem("Hilton Banyo"),
                                          _buildCheckboxItem("Kartonpiyer"),
                                          _buildCheckboxItem("Laminat Zemin"),
                                          _buildCheckboxItem(
                                              "Mutfak (Laminat)"),
                                          _buildCheckboxItem("PVC Doğrama"),
                                          _buildCheckboxItem("Şofben"),
                                          _buildCheckboxItem("Vestiyer"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Dış Özellikler"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem(
                                              "Araç Şarj İstasyonu"),
                                          _buildCheckboxItem(
                                              "Çocuk Oyun Parkı"),
                                          _buildCheckboxItem("Jeneratör"),
                                          _buildCheckboxItem(
                                              "Müstakil Havuzlu"),
                                          _buildCheckboxItem("Spor Alanı"),
                                          _buildCheckboxItem(
                                              "Yangın Merdiveni"),
                                          _buildCheckboxItem(
                                              "Apartman Görevlisi"),
                                          _buildCheckboxItem("Kamera Sistemi"),
                                          _buildCheckboxItem("Tenis Kortu"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 30), // Sütunlar arası boşluk
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Güvenlik"),
                                          _buildCheckboxItem("Hamam"),
                                          _buildCheckboxItem("Kablo TV"),
                                          _buildCheckboxItem("Sauna"),
                                          _buildCheckboxItem("Su Deposu"),
                                          _buildCheckboxItem(
                                              "Yüzme Havuzu (Açık)"),
                                          _buildCheckboxItem("Hidrofor"),
                                          _buildCheckboxItem("Ses Yalıtımı"),
                                          _buildCheckboxItem(
                                              "Yüzme Havuzu (Kapalı)"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Muhit"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem(
                                              "Alışveriş Merkezi"),
                                          _buildCheckboxItem("Belediye"),
                                          _buildCheckboxItem("Cami"),
                                          _buildCheckboxItem("Cemevi"),
                                          _buildCheckboxItem("Denize Sıfır"),
                                          _buildCheckboxItem("Eczane"),
                                          _buildCheckboxItem("Eğlence Merkezi"),
                                          _buildCheckboxItem("Fuar"),
                                          _buildCheckboxItem("Göle Sıfır"),
                                          _buildCheckboxItem("Hastane"),
                                          _buildCheckboxItem("Havra"),
                                          _buildCheckboxItem(
                                              "İlkokul-Ortaokul"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("İtfaiye"),
                                          _buildCheckboxItem("Kilise"),
                                          _buildCheckboxItem("Lise"),
                                          _buildCheckboxItem("Market"),
                                          _buildCheckboxItem("Park"),
                                          _buildCheckboxItem("Plaj"),
                                          _buildCheckboxItem("Polis Merkezi"),
                                          _buildCheckboxItem("Sağlık Ocağı"),
                                          _buildCheckboxItem("Semt Pazarı"),
                                          _buildCheckboxItem("Spor Salonu"),
                                          _buildCheckboxItem("Şehir Merkezi"),
                                          _buildCheckboxItem("Üniversite"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Ulaşım"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Anayol"),
                                          _buildCheckboxItem("Deniz Otobüsü"),
                                          _buildCheckboxItem("İskele"),
                                          _buildCheckboxItem("Minibüs"),
                                          _buildCheckboxItem("TEM"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Avrasya Tüneli"),
                                          _buildCheckboxItem("Dolmuş"),
                                          _buildCheckboxItem("Marmaray"),
                                          _buildCheckboxItem("Otobüs Durağı"),
                                          _buildCheckboxItem("Tramvay"),
                                          _buildCheckboxItem("Boğaz Köprüleri"),
                                          _buildCheckboxItem("E-5"),
                                          _buildCheckboxItem("Metro"),
                                          _buildCheckboxItem("Sahil"),
                                          _buildCheckboxItem("Tren İstasyonu"),
                                          _buildCheckboxItem("Havaalanı"),
                                          _buildCheckboxItem("Metrobüs"),
                                          _buildCheckboxItem("Teleferik"),
                                          _buildCheckboxItem("Troleybüs"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Manzara"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Boğaz"),
                                          _buildCheckboxItem("Havuz"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Deniz"),
                                          _buildCheckboxItem(
                                              "Park & Yeşil Alan"),
                                          _buildCheckboxItem("Doğa"),
                                          _buildCheckboxItem("Göl"),
                                          _buildCheckboxItem("Şehir"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Konut Tipi"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Ara Kat"),
                                          _buildCheckboxItem("Bahçeli"),
                                          _buildCheckboxItem(
                                              "Garaj / Dükkan Üstü"),
                                          _buildCheckboxItem(
                                              "Müstakil Girişli"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Ara Kat Dubleks"),
                                          _buildCheckboxItem("Çatı Dubleksi"),
                                          _buildCheckboxItem("Giriş Katı"),
                                          _buildCheckboxItem("Ters Dubleks"),
                                          _buildCheckboxItem("Bahçe Dubleksi"),
                                          _buildCheckboxItem("En Üst Kat"),
                                          _buildCheckboxItem("Kat Dubleksi"),
                                          _buildCheckboxItem("Tripleks"),
                                          _buildCheckboxItem("Bahçe Katı"),
                                          _buildCheckboxItem("Forleks"),
                                          _buildCheckboxItem("Loft"),
                                          _buildCheckboxItem("Zemin Kat"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ExpansionTile(
                            title: const Text("Engelliye ve Yaşlıya Uygun"),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sol sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Araç Park Yeri"),
                                          _buildCheckboxItem("Giriş / Rampa"),
                                          _buildCheckboxItem("Park"),
                                          _buildCheckboxItem("Yüzme Havuzu"),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    // Sağ sütun
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildCheckboxItem("Asansör"),
                                          _buildCheckboxItem("Merdiven"),
                                          _buildCheckboxItem(
                                              "Priz / Elektrik Anahtarı"),
                                          _buildCheckboxItem("Banyo"),
                                          _buildCheckboxItem("Mutfak"),
                                          _buildCheckboxItem(
                                              "Tutamak / Korkuluk"),
                                          _buildCheckboxItem("Geniş Koridor"),
                                          _buildCheckboxItem("Oda Kapısı"),
                                          _buildCheckboxItem("Tuvalet"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Kaydet Butonu - Sayfanın en altında sabit
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Portföy başarıyla kaydedildi'),
                            backgroundColor: Color.fromRGBO(238, 46, 36, 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ekle',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: 2,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildTypeOption(String type) {
    bool isSelected = selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE53935) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCheckboxItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false,
              onChanged: (value) {
                // Checkbox değeri değiştiğinde yapılacak işlemler
              },
              activeColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
