import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/navbar/custom_bottom_navbar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/models/list/listing_model.dart';
import 'package:zecorner/infrastructure/favorite/favorite_repository.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

class FavoriteListScreen extends StatefulWidget {
  const FavoriteListScreen({super.key});

  @override
  State<FavoriteListScreen> createState() => _FavoriteListScreenState();
}

class _FavoriteListScreenState extends State<FavoriteListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 4; // Profile tab index
  
  final FavoriteRepository _favoriteRepository = FavoriteRepository();

  List<ListingModel> _favoriteListings = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadFavoriteProperties();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// GET /favorite/listings ile favori ilanları yükle
  Future<void> _loadFavoriteProperties() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    final result = await _favoriteRepository.getFavoriteListings(page: 1, limit: 50);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = failure.message;
          _favoriteListings = [];
          _favoriteIds = {};
        });
      },
      (response) {
        setState(() {
          _favoriteListings = response.listings;
          _favoriteIds = response.listings.map((l) => l.id).toSet();
          _isLoading = false;
        });
      },
    );
  }

  /// Favoriden çıkar (sadece yerel liste güncellenir; kalıcı silme için backend endpoint gerekir)
  void _toggleFavorite(String listingId, bool isFavorite) {
    if (isFavorite) {
      setState(() {
        _favoriteIds.remove(listingId);
        _favoriteListings.removeWhere((l) => l.id == listingId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilerden çıkarıldı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Favorilerim',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFavoriteProperties,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoriteListingsTab(),
                _buildFavoriteConsultantsTab(),
                _buildMessagesTab(),
                _buildNotificationsTab(),
                _buildAccountSettingsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildFavoriteListingsTab() {
    if (_isLoading) {
      return const AppStatusView.loading(
        title: 'Favoriler hazırlanıyor.',
        message: 'Favori ilanlarınız yüklenirken lütfen bekleyin.',
      );
    }

    if (_hasError && _favoriteListings.isEmpty) {
      return AppStatusView.error(
        title: 'Bir hata oluştu',
        message: _errorMessage ?? 'Favori ilanlar yüklenemedi.',
        onRetry: _loadFavoriteProperties,
      );
    }

    if (_favoriteListings.isEmpty) {
      return const AppStatusView.missing(
        title: 'Henüz favori ilan yok',
        message: 'Beğendiğiniz ilanları favorilerinize ekleyin.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteProperties,
      color: const Color(0xFFE53935),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _favoriteListings.length,
        itemBuilder: (context, index) {
          final listing = _favoriteListings[index];
          return Column(
            children: [
              _buildListingCard(listing),
              if (index < _favoriteListings.length - 1) const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  String _formatType(String type) {
    final t = type.toLowerCase();
    if (t == 'kiralik') return 'Kiralık';
    if (t == 'satilik') return 'Satılık';
    return type;
  }

  String _formatLocation(ListingModel listing) {
    final parts = <String>[];
    if (listing.provinceName.isNotEmpty) parts.add(listing.provinceName);
    if (listing.districtName.isNotEmpty) parts.add(listing.districtName);
    if (listing.quarterName.isNotEmpty) parts.add(listing.quarterName);
    return parts.isEmpty ? 'Konum belirtilmemiş' : parts.join(' / ');
  }

  String _formatPrice(ListingModel listing) {
    final price = listing.price;
    final currency = listing.currency;
    if (price >= 1000000) {
      return '₺${(price / 1000000).toStringAsFixed(1)}M';
    }
    if (price >= 1000) {
      return '₺${(price / 1000).toStringAsFixed(0)}K';
    }
    return '₺${price.toStringAsFixed(0)} ${currency.isNotEmpty ? currency : ''}'.trim();
  }

  Widget _buildListingCard(ListingModel listing) {
    final isFavorite = _favoriteIds.contains(listing.id);
    final coverUrl = ImageUtils.getCoverImageUrl(listing.coverPicture);
    final profileUrl = ImageUtils.getProfileImageUrl(listing.contactPicture ?? listing.picture);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRouter.homeIlanDetail,
          arguments: listing.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: coverUrl.isEmpty
                        ? _buildPlaceholderImage()
                        : Image.network(
                            coverUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(listing.id, isFavorite),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatType(listing.type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatPrice(listing),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(238, 46, 36, 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatLocation(listing),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(71, 85, 105, 1),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.contactTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            listing.contactTypeDescription,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                      child: profileUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white, size: 40)
                          : Image.network(
                              profileUrl,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 74,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 40),
                            ),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[300]!, Colors.grey[200]!],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: const Center(
        child: Icon(Icons.home_outlined, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildFavoriteConsultantsTab() {
    return const Center(
      child: Text(
        'Favori Danışmanlar',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMessagesTab() {
    return const Center(
      child: Text(
        'Mesajlar',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(
      child: Text(
        'Bildirimler',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAccountSettingsTab() {
    return const Center(
      child: Text(
        'Hesap Ayarları',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
