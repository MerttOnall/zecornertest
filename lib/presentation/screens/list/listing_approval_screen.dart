import 'package:flutter/material.dart';
import 'dart:async';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/screens/list/aproval_edit_screen.dart';

// Mock listing data model
class MockListingData {
  final String id;
  final String title;
  final String location;
  final String price;
  final String area;
  final String rooms;
  final int viewCount;
  final String status;
  final Color statusColor;

  MockListingData({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.area,
    required this.rooms,
    required this.viewCount,
    required this.status,
    required this.statusColor,
  });
}

class ListingApprovalScreen extends StatefulWidget {
  const ListingApprovalScreen({super.key});

  @override
  State<ListingApprovalScreen> createState() => _ListingApprovalScreenState();
}

class _ListingApprovalScreenState extends State<ListingApprovalScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  
  // Mock listings data
  List<MockListingData> mockListings = [
    MockListingData(
      id: 'listing_0',
      title: '3+1 Satılık Daire',
      location: 'İstanbul / Ataşehir / Barbaros Mah.',
      price: '2.750.000 ₺',
      area: '150 m²',
      rooms: '3 Oda',
      viewCount: 124,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_1',
      title: '2+1 Kiralık Daire',
      location: 'İstanbul / Kadıköy / Fenerbahçe Mah.',
      price: '8.500 ₺',
      area: '90 m²',
      rooms: '2 Oda',
      viewCount: 89,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_2',
      title: '4+1 Satılık Villa',
      location: 'Antalya / Belek / Acisu Mah.',
      price: '4.250.000 ₺',
      area: '280 m²',
      rooms: '4 Oda',
      viewCount: 203,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_3',
      title: '1+1 Kiralık Stüdyo',
      location: 'İstanbul / Beşiktaş / Etiler Mah.',
      price: '12.000 ₺',
      area: '55 m²',
      rooms: '1 Oda',
      viewCount: 67,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_4',
      title: '3+1 Satılık Daire',
      location: 'Ankara / Çankaya / Kızılay Mah.',
      price: '1.850.000 ₺',
      area: '125 m²',
      rooms: '3 Oda',
      viewCount: 156,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_5',
      title: '2+1 Kiralık Daire',
      location: 'İzmir / Karşıyaka / Bostanlı Mah.',
      price: '6.200 ₺',
      area: '85 m²',
      rooms: '2 Oda',
      viewCount: 92,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_6',
      title: '5+2 Satılık Müstakil Ev',
      location: 'Bursa / Nilüfer / Görükle Mah.',
      price: '3.100.000 ₺',
      area: '220 m²',
      rooms: '5 Oda',
      viewCount: 178,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_7',
      title: '1+1 Satılık Daire',
      location: 'İstanbul / Şişli / Mecidiyeköy Mah.',
      price: '1.950.000 ₺',
      area: '65 m²',
      rooms: '1 Oda',
      viewCount: 134,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_8',
      title: '3+1 Kiralık Daire',
      location: 'Adana / Seyhan / Reşatbey Mah.',
      price: '4.800 ₺',
      area: '110 m²',
      rooms: '3 Oda',
      viewCount: 73,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
    MockListingData(
      id: 'listing_9',
      title: '2+1 Satılık Daire',
      location: 'Trabzon / Ortahisar / Çarşı Mah.',
      price: '1.450.000 ₺',
      area: '95 m²',
      rooms: '2 Oda',
      viewCount: 98,
      status: 'Onay Bekliyor',
      statusColor: Colors.orange,
    ),
  ];

  // Filtre ve arama durumları
  String _selectedType = '';
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
              return RoleSidebar(currentPage: 'İlanlarım');
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
            title: "İlan Onay",
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
      body: AnimatedBackgroundWidget(
          child: GestureDetector(
            onTap: () {
              if (_isDrawerOpen) {
                _scaffoldKey.currentState?.closeDrawer();
              }
            },
            child: AbsorbPointer(
              absorbing: _isDrawerOpen,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatefulBuilder(
                              builder: (context, setChipState) {
                                String selectedType = _selectedType;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Satılık'),
                                      selected: selectedType == 'Satılık',
                                      selectedColor: const Color(0xFFE53935),
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: selectedType == 'Satılık' ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: selectedType == 'Satılık' ? const Color(0xFFE53935) : Colors.grey.shade300, width: 1.2),
                                      onSelected: (v) {
                                        setState(() => _selectedType = 'Satılık');
                                        setChipState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Kiralık'),
                                      selected: selectedType == 'Kiralık',
                                      selectedColor: const Color(0xFFE53935),
                                      backgroundColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: selectedType == 'Kiralık' ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      side: BorderSide(color: selectedType == 'Kiralık' ? const Color(0xFFE53935) : Colors.grey.shade300, width: 1.2),
                                      onSelected: (v) {
                                        setState(() => _selectedType = 'Kiralık');
                                        setChipState(() {});
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedType = '';
                                  _searchText = '';
                                  _searchController.clear();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                elevation: 0,
                                minimumSize: const Size(0, 38),
                              ),
                              child: const Text('Filtreyi Temizle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE53935), width: 1.2),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) {
                              _searchTimer?.cancel();
                              _searchTimer = Timer(const Duration(milliseconds: 300), () {
                                setState(() => _searchText = v);
                              });
                            },
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Arayın...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchText = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final filteredListings = mockListings.where((listing) {
                          final matchesType = _selectedType.isEmpty || listing.title.contains(_selectedType);
                          final query = _searchText.trim().toLowerCase();
                          final matchesSearch = query.isEmpty ||
                              listing.title.toLowerCase().contains(query) ||
                              listing.location.toLowerCase().contains(query) ||
                              listing.price.toLowerCase().contains(query);
                          return matchesType && matchesSearch;
                        }).toList();
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            final listing = filteredListings[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                            child: InkWell(
                              onTap: () => _navigateToApprovalEdit(listing.id),
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image Section with enhanced styling
                                  Container(
                                    height: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Main Image
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            height: 220,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    'https://picsum.photos/800/600?random=$index'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            // Dark overlay for better text readability
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        // Status Badge
                                        Positioned(
                                          right: 16,
                                          top: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  listing.statusColor,
                                                  listing.statusColor.withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: listing.statusColor.withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  listing.status,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Property Type Badge
                                        Positioned(
                                          left: 16,
                                          top: 16,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              listing.title.contains('Kiralık') ? 'KİRALIK' : 'SATILIK',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Content Section
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title and Price Row
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    listing.title,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF1A1A1A),
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFE53935).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(
                                                          Icons.location_on_rounded,
                                                          size: 14,
                                                          color: const Color(0xFFE53935),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          listing.location,
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFE53935),
                                                    Color(0xFFD32F2F),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFE53935).withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                listing.price,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Features Section
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: _buildModernFeature(
                                                  Icons.square_foot_rounded, 
                                                  listing.area,
                                                  'Alan'
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 24,
                                                color: Colors.grey[300],
                                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              Expanded(
                                                child: _buildModernFeature(
                                                  Icons.meeting_room_rounded, 
                                                  listing.rooms,
                                                  'Oda'
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Action Button
                                        Container(
                                          width: double.infinity,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFE53935).withOpacity(0.1),
                                                const Color(0xFFE53935).withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFE53935).withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.assignment_rounded,
                                                size: 18,
                                                color: const Color(0xFFE53935),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Detaylar ve Onay İşlemleri",
                                                style: TextStyle(
                                                  color: Color(0xFFE53935),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 14,
                                                color: const Color(0xFFE53935),
                                              ),
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
                        );
                          },
                        );
                      },
                    ),
                  ),
                ],
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

  Widget _buildModernFeature(IconData icon, String text, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Navigate to approval edit screen
  void _navigateToApprovalEdit(String listingId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApprovalEditScreen(listingId: listingId),
      ),
    );

    // Handle result from approval screen
    if (result != null) {
      if (result['action'] == 'approved') {
        _showUpdateMessage('İlan başarıyla onaylandı!', Colors.green);
      } else if (result['action'] == 'rejected') {
        _showUpdateMessage('İlan reddedildi!', Colors.red);
      }
    }
  }

  void _showUpdateMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
