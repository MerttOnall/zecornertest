import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'dart:async';

class TransactionApproveScreen extends StatefulWidget {
  const TransactionApproveScreen({super.key});

  @override
  State<TransactionApproveScreen> createState() => _TransactionApproveScreenState();
}

class _TransactionApproveScreenState extends State<TransactionApproveScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final MyListingsRepository _listingsRepository = MyListingsRepository();
  
  List<ListingPanelModel> _listings = [];
  List<ListingPanelModel> _filteredListings = [];
  bool _isLoading = false;
  bool _accessChecked = false;
  bool _isBroker = false;
  String? _errorMessage;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _checkBrokerAccess();
  }

  Future<void> _checkBrokerAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? const <String>[];
    final typeDescription = prefs.getString('userTypeDescription');
    final allowed = AuthCubit.isBrokerRank(
      roleCodes: roles,
      typeDescription: typeDescription,
    );
    if (!mounted) return;
    setState(() {
      _accessChecked = true;
      _isBroker = allowed;
    });
    if (allowed) _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Kapanış onayı bekleyen ilanları yükle
      final result = await _listingsRepository.getMyListings(
        page: 1,
        pageSize: 100,
        state: 'CLOSURE_APPROVAL', // Kapanış onayı bekleyen ilanlar
        office: '',
        contact: 'all',
        sortOrder: 'asc',
        sortColumn: 'created_at',
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
            _listings = [];
            _filteredListings = [];
          });
        },
        (response) {
          setState(() {
            _isLoading = false;
            _listings = response.listings;
            _filteredListings = response.listings;
          });
          _applyFilters();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Listeler yüklenirken hata oluştu: $e';
        _listings = [];
        _filteredListings = [];
      });
    }
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Filtreler API'de uygulanıyor, sadece arama filtresini client-side yapıyoruz
    setState(() {
      _filteredListings = _listings.where((listing) {
        // Arama filtresi (client-side)
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          return listing.title.toLowerCase().contains(query) ||
                 listing.fullLocation.toLowerCase().contains(query) ||
                 listing.listingNo.toString().contains(query);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _approveListing(ListingPanelModel listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Onay'),
        content: Text('${listing.title} ilanının kapanış onayını vermek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Onayla', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await _listingsRepository.approveClosureListing(listing.id);
    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      },
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        _loadListings();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: RoleSidebar(currentPage: 'İşlem Bildirim Onayları'),
      appBar: AdminPanelAppBar(
        title: 'İşlem Bildirim Onayları',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: !_accessChecked
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            )
          : !_isBroker
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Bu sayfa yalnızca broker rütbesine açıktır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C2430),
                      ),
                    ),
                  ),
                )
              : Column(
        children: [
          // Arama çubuğu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Arayın...',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFFE53935),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadListings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                              ),
                              child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _filteredListings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Onay bekleyen işlem bulunamadı',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadListings,
                            color: const Color(0xFFE53935),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _filteredListings.length,
                              itemBuilder: (context, index) {
                                final listing = _filteredListings[index];
                                return _buildListingCard(listing);
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminNavbar(currentIndex: 0, onTap: null),
    );
  }

  Widget _buildListingCard(ListingPanelModel listing) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.pushNamed(
          context,
          '/zeonline/transaction-approvals/detail',
          arguments: listing,
        );
        if (!mounted || updated == null) return;
        if (updated is String && updated.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updated),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        }
        if (updated == true || updated is String) _loadListings();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Görsel
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildListingImage(listing),
              ),
              // Kiralık/Satılık Etiketi
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.displayType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // İçerik
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarih
                Text(
                  _formatDate(listing.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // Başlık
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),

                // Konum
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        listing.fullLocation,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Özellikler
                Row(
                  children: [
                    // Alan
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.square_foot, size: 18, color: const Color(0xFFE53935)),
                          const SizedBox(width: 6),
                          Text(
                            '${listing.area} m²',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Oda Sayısı
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.bed, size: 18, color: const Color(0xFFE53935)),
                          const SizedBox(width: 6),
                          Text(
                            listing.rooms != 'N/A' ? listing.rooms : 'Bilgi Yok',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Fiyat
                Text(
                  listing.formattedPrice,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 12),

                // Görüntülenme Sayısı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 16, color: const Color(0xFFE53935)),
                      const SizedBox(width: 6),
                      Text(
                        '${listing.viewCount} kez görüntülendi',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Onay Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _approveListing(listing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kapama Onayı Bekliyor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Danışman Bilgileri
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.contactTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.contactTypeDescription,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (listing.connectedContactTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          listing.connectedContactTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildListingImage(ListingPanelModel listing) {
    // cover_picure ID'sinden resim URL'sini oluştur
    final imageUrl = ImageUtils.getCoverImageUrl(listing.coverPicture);
    
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Resim yüklenemedi: $imageUrl, Hata: $error');
          return Container(
            height: 220,
            color: Colors.grey.shade200,
            child: Icon(Icons.home, size: 64, color: Colors.grey.shade400),
          );
        },
      );
    } else {
      // Resim ID yoksa placeholder göster
      return Container(
        height: 220,
        color: Colors.grey.shade200,
        child: Icon(Icons.home, size: 64, color: Colors.grey.shade400),
      );
    }
  }
}

