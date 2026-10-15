import 'package:flutter/material.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';

class SssScreen extends StatefulWidget {
  const SssScreen({Key? key}) : super(key: key);

  @override
  State<SssScreen> createState() => _SssScreenState();
}

class _SssScreenState extends State<SssScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  bool _isFilterExpanded = false;
  String _selectedStatus = 'Hepsi';
  String _selectedLanguage = 'Türkçe';
  bool _isActive = true;
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final sssList = [
      {
        'title': 'Zecorner Nedir?',
        'category': 'Zecorner',
        'categoryDesc': 'Broker ya da danışman olmak için web sitemizden form doldurarak Zecorner dünyasına katılma fırsatı yakalayın.',
        'order': 1,
        'status': true,
        'lang': 'TR',
        'date': '28/10/2024',
        'time': '02:27',
        'note': 'Zecorner, Türkiye\'nin en teknolojik gayrimenkul markasıdır. Yenilikçi iş modeli, adil paylaşım sistemi ve kapsamlı teknolojik altyapısıyla hem girişimcilere hem de gayrimenkul danışmanlarına benzersiz fırsatlar sunar.',
      },
      {
        'title': 'Zecorner Gayrimenkul Danışmanlığı Avantajları Nedir?',
        'category': 'Gayrimenkul Danışmanlığı',
        'categoryDesc': 'Gayrimenkul danışmanlığı ile müşterilere profesyonel hizmet sunabilir, yüksek kazanç fırsatları elde edebilirsiniz.',
        'order': 1,
        'status': true,
        'lang': 'TR',
        'date': '28/10/2024',
        'time': '02:30',
        'note': 'Zecorner danışmanları, eğitim ve teknoloji desteğiyle sektörde öne çıkar. Geniş portföy ve güçlü marka desteği ile avantajlısınız.',
      },
      {
        'title': 'Zecorner Franchise Sistemi Nasıl Çalışır?',
        'category': 'Franchise Broker / Ofis Sistemi',
        'categoryDesc': 'Zecorner franchise sistemi ile kendi ofisinizi açabilir, markanın tüm avantajlarından yararlanabilirsiniz.',
        'order': 1,
        'status': true,
        'lang': 'TR',
        'date': '14/11/2024',
        'time': '14:14',
        'note': 'Franchise sistemi, girişimcilere düşük maliyetle kendi işini kurma ve Zecorner\'ın teknolojik altyapısını kullanma imkanı sunar.',
      },
      {
        'title': 'Zecorner\'da Nasıl Gayrimenkul Danışmanı Olunur?',
        'category': 'Gayrimenkul Danışmanlığı',
        'categoryDesc': 'Başvuru formunu doldurarak Zecorner danışmanı olma sürecini başlatabilirsiniz.',
        'order': 2,
        'status': true,
        'lang': 'TR',
        'date': '28/10/2024',
        'time': '02:30',
        'note': 'Başvuru sonrası eğitim ve oryantasyon süreciyle kısa sürede aktif danışman olabilirsiniz.',
      },
      {
        'title': 'Zecorner Bayisi Olmak İçin Ne Kadar Sermaye Gerekir?',
        'category': 'Franchise Broker / Ofis Sistemi',
        'categoryDesc': 'Zecorner bayiliği için gerekli sermaye ve başvuru koşulları hakkında detaylı bilgiye web sitemizden ulaşabilirsiniz.',
        'order': 2,
        'status': true,
        'lang': 'TR',
        'date': '14/11/2024',
        'time': '11:15',
        'note': 'Bayilik başvurusu için gerekli yatırım miktarı ve süreçler şeffaf şekilde paylaşılır.',
      },
    ];

    int _getActiveFilterCount() {
      int count = 0;
      if (_selectedStatus != 'Hepsi') count++;
      if (_selectedLanguage != 'Türkçe') count++;
      if (_searchText.isNotEmpty) count++;
      return count;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'SSS');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: 'Sıkça Sorulan Sorular',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arama ve Filtre Bölümü
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Arama Kutusu
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchText = value),
                            decoration: InputDecoration(
                              hintText: 'SSS arayın...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.grey[100],
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                          ),
                        ),
                        
                        // Filtreleme Expansion Tile
                        ExpansionTile(
                          title: Row(
                            children: [
                              const Icon(Icons.filter_list, color: Color.fromRGBO(238, 46, 36, 1), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Filtreler',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_getActiveFilterCount() > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53935),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _getActiveFilterCount().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            _isFilterExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFFE53935),
                          ),
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _isFilterExpanded = expanded;
                            });
                          },
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          decoration: InputDecoration(
                                            labelText: 'Durum',
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          value: _selectedStatus,
                                          items: const [
                                            DropdownMenuItem(value: 'Hepsi', child: Text('Hepsi')),
                                            DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                                            DropdownMenuItem(value: 'Pasif', child: Text('Pasif')),
                                          ],
                                          onChanged: (value) => setState(() => _selectedStatus = value!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Dil Seçimi
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            TextButton(
                                              onPressed: () => setState(() => _selectedLanguage = 'Türkçe'),
                                              child: Text(
                                                'Türkçe',
                                                style: TextStyle(
                                                  color: _selectedLanguage == 'Türkçe' 
                                                      ? const Color(0xFFE53935) 
                                                      : Colors.black54,
                                                  fontWeight: _selectedLanguage == 'Türkçe' 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () => setState(() => _selectedLanguage = 'İngilizce'),
                                              child: Text(
                                                'İngilizce',
                                                style: TextStyle(
                                                  color: _selectedLanguage == 'İngilizce' 
                                                      ? const Color(0xFFE53935) 
                                                      : Colors.black54,
                                                  fontWeight: _selectedLanguage == 'İngilizce' 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Radio(
                                            value: true,
                                            groupValue: _isActive,
                                            onChanged: (value) => setState(() => _isActive = value!),
                                            activeColor: const Color(0xFFE53935),
                                          ),
                                          const Text('Aktif', style: TextStyle(fontWeight: FontWeight.w500)),
                                          const SizedBox(width: 8),
                                          Radio(
                                            value: false,
                                            groupValue: _isActive,
                                            onChanged: (value) => setState(() => _isActive = value!),
                                            activeColor: const Color(0xFFE53935),
                                          ),
                                          const Text('Pasif', style: TextStyle(fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE53935),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _selectedStatus = 'Hepsi';
                                            _selectedLanguage = 'Türkçe';
                                            _isActive = true;
                                            _searchText = '';
                                          });
                                        },
                                        child: const Text(
                                          'Temizle',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Yeni SSS Oluştur Butonu
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, AppRouter.addSss);
                              },
                              icon: const Icon(Icons.add, color: Colors.white, size: 20),
                              label: const Text(
                                'Yeni SSS Oluştur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  // SSS Listesi
                  ...sssList.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.editSss);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Üst satır: başlık, tarih/saat
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s['title'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: Color(0xFF22223B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    s['date'] as String,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s['time'] as String,
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Alt satır: kategori, sıralama, durum, dil
                              Row(
                                children: [
                                  // Kategori chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      s['category'] as String,
                                      style: const TextStyle(
                                        color: Color.fromRGBO(238, 46, 36, 1),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  // Sıralama badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      (s['order']).toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  // Durum
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (s['status'] as bool) ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Icon(
                                      (s['status'] as bool) ? Icons.check_circle : Icons.cancel,
                                      color: (s['status'] as bool) ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  // Dil badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      s['lang'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AdminNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}

class SssDetailPopup extends StatelessWidget {
  final Map<String, dynamic> sss;
  const SssDetailPopup({Key? key, required this.sss}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık ve çarpı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SSS Kategori Bilgileri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
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
                        child: const Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Soru başlığı ve durum
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      sss['title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Icon(
                    (sss['status'] ?? false) ? Icons.check_circle : Icons.cancel,
                    color: (sss['status'] ?? false) ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 10),
              // Oluşturulma Tarihi
              const Text('Oluşturulma Tarihi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(sss['date']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(sss['time']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              // SSS Kategorisi
              const Text('SSS Kategorisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sss['category']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1976D2)),
                    ),
                    if ((sss['categoryDesc']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        sss['categoryDesc']?.toString() ?? '',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1976D2)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Dil & Sıralama (karttakiyle aynı badge ve değerlerle)
              const Text('Dil & Sıralama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      sss['lang']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      sss['order']?.toString() ?? '',
                      style: const TextStyle(color: Color.fromRGBO(238, 46, 36, 1), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Notlar
              const Text('Notlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Text(
                  sss['note']?.toString() ?? '',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
