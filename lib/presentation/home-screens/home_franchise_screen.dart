import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zecorner/presentation/widgets/home_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';

class HomeFranchiseScreen extends StatefulWidget {
  const HomeFranchiseScreen({super.key});

  @override
  State<HomeFranchiseScreen> createState() => _HomeFranchiseScreenState();
}

class _HomeFranchiseScreenState extends State<HomeFranchiseScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;
  bool _kvkkAccepted = false;
  int _currentIndex = 4;

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
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: SvgPicture.asset(
          "assets/logo/zecorner-logo1.svg",
          width: 140,
        ),
        centerTitle: true,
      ),
      drawer: const HomeSidebar(currentPage: 'Franchise'),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Bilgi Bölümü
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 32,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: 'Zecorner ',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: 'ile\nEmlak Ofisinizi Açın!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Türkiye'nin En Teknolojik Gayrimenkul Markasının Bir Parçası Olun, Emlak Sektöründe Adınız Konuşulsun.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildFeatureItem(
                        "Marka Gücümüzle Öne Çıkın:",
                        "Türkiye'nin en teknolojik gayrimenkul markasıyla güven kazanın.",
                      ),
                      _buildFeatureItem(
                        "Eğitim ve Sürekli Destek:",
                        "İş kurulumundan operasyonel süreçlere kadar her ayrıntıda yanınızdayız.",
                      ),
                      _buildFeatureItem(
                        "Daha Yüksek Kazanç Potansiyeli:",
                        "Daha makul franchise ücretleri, satışlardan daha fazla kazanç oranı ile gelirlerinizi ofisinizi büyütmek için harcayın.",
                      ),
                      _buildFeatureItem(
                        "Başarı Yolculuğunuza Başlayın:",
                        "Hayalini kurduğunuz kariyer bir buton kadar uzağınızda. Formu doldurun Ayrıntılı bilgi için sizi arayalım.",
                      ),
                    ],
                  ),
                ),

                // Form Bölümü
                Container(
                  color: Colors.red,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Zecorner ailesine katılarak kendi işinizi kurmak ve güçlü bir markanın desteğini almak için başvurunuzu tamamlayın. Başvurunuzu değerlendirip sizinle en kısa sürede iletişime geçeceğiz.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Zecorner Ofis/Broker Başvuru Formu",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Column(
                                children: [
                                  _buildTextField(
                                    "Adınız",
                                    TextInputType.name,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    "Soyadınız",
                                    TextInputType.name,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    "Telefon Numaranız",
                                    TextInputType.phone,
                                    hintText: "+90 (555) 000-0000",
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    "E-posta Adresiniz",
                                    TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    "Eğitim Durumunuz",
                                    [
                                      "Lise",
                                      "Üniversite",
                                      "Yüksek Lisans",
                                      "Doktora"
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    "Mesleğiniz",
                                    ["Emlak Danışmanı", "İşletmeci", "Diğer"],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    "İl",
                                    ["İstanbul", "Ankara", "İzmir"],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    "İlçe",
                                    ["Kadıköy", "Beşiktaş", "Üsküdar"],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildCheckbox(
                                    "Yasal Uyarılar ve Kullanım Koşulları",
                                    _termsAccepted,
                                    (value) =>
                                        setState(() => _termsAccepted = value!),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCheckbox(
                                    "KVKK Aydınlatma Metni",
                                    _kvkkAccepted,
                                    (value) =>
                                        setState(() => _kvkkAccepted = value!),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _termsAccepted && _kvkkAccepted
                                          ? () {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                // Form gönderme işlemi
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        disabledBackgroundColor: Colors.grey,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Hemen Başvur",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Avantajlar Bölümü
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      const Text(
                        "Zecorner Franchise Avantajları",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 800 ? 3 : 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.47,
                        children: [
                          _buildAdvantageCard(
                            "Güçlü Marka Desteği",
                            Icons.trending_up,
                            "Türkiye'nin en teknolojik gayrimenkul markasının gücüyle işinizi büyütün.",
                          ),
                          _buildAdvantageCard(
                            "Kapsamlı Eğitim",
                            Icons.school,
                            "Sektörün en kapsamlı eğitim programıyla başarıya ulaşın.",
                          ),
                          _buildAdvantageCard(
                            "Teknolojik Altyapı",
                            Icons.computer,
                            "Modern CRM sistemleri ve dijital pazarlama araçlarıyla rekabette öne çıkın.",
                          ),
                          _buildAdvantageCard(
                            "Sürekli Destek",
                            Icons.support_agent,
                            "Operasyonel süreçlerde 7/24 destek alın.",
                          ),
                          _buildAdvantageCard(
                            "Yüksek Kazanç",
                            Icons.attach_money,
                            "Düşük franchise bedeli ve yüksek kar marjı ile kazancınızı artırın.",
                          ),
                          _buildAdvantageCard(
                            "Hazır Müşteri Portföyü",
                            Icons.people,
                            "Mevcut müşteri ağımızdan faydalanın.",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Süreç Bölümü
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                  child: Column(
                    children: [
                      const Text(
                        "Franchise Süreci",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      _buildProcessTimeline(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Sayfa yönlendirmeleri burada yapılabilir
          switch (index) {
            case 0:
              // Ana Sayfa
              break;
            case 1:
              // Arama
              break;
            case 2:
              // İlan Ekle
              break;
            case 3:
              // Favoriler
              break;
            case 4:
              // Profil
              break;
          }
        },
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_forward, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, height: 1.5),
                children: [
                  TextSpan(
                    text: "$title ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade600,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextInputType keyboardType,
      {String? hintText}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextFormField(
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9363E), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            errorStyle: const TextStyle(height: 0.7),
            labelStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontWeight: FontWeight.w600,
                fontSize: 16),
            floatingLabelStyle: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            hintStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          style: const TextStyle(
              fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bu alan zorunludur';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: double.infinity,
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD9363E), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            errorStyle: const TextStyle(height: 0.7),
            labelStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontWeight: FontWeight.w600,
                fontSize: 16),
            floatingLabelStyle: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            hintStyle: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          style: const TextStyle(
              fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
          dropdownColor: Colors.white,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            );
          }).toList(),
          onChanged: (String? newValue) {},
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen bir seçim yapın';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.red,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text.rich(
              TextSpan(
                text: "$label'",
                style: const TextStyle(color: Colors.black87),
                children: const [
                  TextSpan(
                    text: "nı okudum ve kabul ediyorum.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvantageCard(String title, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessTimeline() {
    return Column(
      children: [
        _buildProcessStep(
          "1",
          "Başvuru",
          "Online başvuru formunu doldurun.",
          isFirst: true,
        ),
        _buildProcessStep(
          "2",
          "Değerlendirme",
          "Başvurunuz 48 saat içinde değerlendirilir.",
        ),
        _buildProcessStep(
          "3",
          "Görüşme",
          "Size uygun görüşme şekli ile ön görüşme sağlanır.",
        ),
        _buildProcessStep(
          "4",
          "Sözleşme",
          "Anlaşma sağlanması durumunda franchise sözleşmesi imzalanır.",
        ),
        _buildProcessStep(
          "5",
          "Eğitim",
          "Kapsamlı eğitim programına başlarsınız.",
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildProcessStep(String number, String title, String description,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (!isLast)
                  Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 8),
                    height: 40,
                    width: 2,
                    color: Colors.red.withOpacity(0.2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
