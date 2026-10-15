import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/listing_repository.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/models/list/listing_model.dart';
import 'package:zecorner/models/list/property_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/map_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/router/app_router.dart';

class PortfolioApproveDetailScreen extends StatefulWidget {
  final String listingId;
  final int? initialContactNo;

  const PortfolioApproveDetailScreen({
    super.key,
    required this.listingId,
    this.initialContactNo,
  });

  @override
  State<PortfolioApproveDetailScreen> createState() =>
      _PortfolioApproveDetailScreenState();
}

class _PortfolioApproveDetailScreenState
    extends State<PortfolioApproveDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ListingRepository _repository = ListingRepository();
  final MyListingsRepository _myListingsRepository = MyListingsRepository();
  final PageController _pageController = PageController();
  final ScrollController _thumbScrollController = ScrollController();

  ListingModel? _listing;
  List<String> _images = [];
  List<ListingModel> _otherListings = [];
  int _selectedImageIndex = 0;
  bool _isLoading = true;
  bool _isLoadingOthers = false;
  bool _isProcessingAction = false;
  bool _isBroker = false;
  bool _brokerRoleChecked = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBrokerRole());
  }

  Future<void> _loadBrokerRole() async {
    final authCubit = context.read<AuthCubit>();
    final codes = await authCubit.getUserRoleCodes();
    if (!mounted) return;
    final allowed = codes.contains('role_office_broker') && !authCubit.isAdmin;
    if (!allowed) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isBroker = true;
      _brokerRoleChecked = true;
    });
  }

  bool _canShowApprovalActions(ListingModel listing) {
    if (!_isBroker) return false;
    return listing.state.toUpperCase() == 'WAITING_FOR_APPROVAL';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getListingDetail(widget.listingId);
    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (listing) {
        if (!mounted) return;
        setState(() {
          _listing = listing;
          _images = _buildImageList(listing);
          _isLoading = false;
        });
        _loadOtherListings(listing);
      },
    );
  }

  int _resolveContactNo(ListingModel listing) {
    if (listing.contactNo > 0) return listing.contactNo;
    if (widget.initialContactNo != null && widget.initialContactNo! > 0) {
      return widget.initialContactNo!;
    }
    return 0;
  }

  Future<void> _loadOtherListings(ListingModel listing) async {
    final contactNo = _resolveContactNo(listing);
    if (contactNo <= 0) return;

    setState(() => _isLoadingOthers = true);

    final result = await _repository.getConsultantOtherListings(
      contactNo: contactNo,
      excludedListingId: listing.id,
      pageSize: 4,
      state: 'LIVE',
    );

    if (!mounted) return;
    result.fold(
      (_) async {
        // Son çare: genel listing listesinden aynı danışmanı filtrele
        final fallback = await _fetchOtherListingsFallback(contactNo, listing.id);
        if (!mounted) return;
        setState(() {
          _otherListings = fallback;
          _isLoadingOthers = false;
        });
      },
      (response) => setState(() {
        _otherListings = response.listings;
        _isLoadingOthers = false;
      }),
    );
  }

  Future<List<ListingModel>> _fetchOtherListingsFallback(
    int contactNo,
    String excludedListingId,
  ) async {
    final others = <ListingModel>[];
    for (int page = 1; page <= 3; page++) {
      final result = await _repository.getListings(page: page, limit: 50);
      final shouldStop = result.fold(
        (_) => true,
        (response) {
          for (final item in response.listings) {
            if (item.id != excludedListingId && item.contactNo == contactNo) {
              others.add(item);
              if (others.length >= 4) return true;
            }
          }
          return response.listings.isEmpty;
        },
      );
      if (shouldStop) break;
    }
    return others;
  }

  List<String> _buildImageList(ListingModel listing) {
    final imageList = <String>[];

    if (listing.medias.isNotEmpty) {
      for (final media in listing.medias) {
        if (media.type == 'image' &&
            ImageUtils.isValidS3Id(media.standart)) {
          imageList.add(ImageUtils.getCoverImageUrl(media.standart!));
        }
      }
    }

    if (imageList.isEmpty && ImageUtils.isValidS3Id(listing.coverPicture)) {
      imageList.add(ImageUtils.getCoverImageUrl(listing.coverPicture));
    }

    if (imageList.isEmpty) {
      imageList.add('');
    }

    return imageList;
  }

  String _formatPrice(ListingModel listing) {
    if (listing.price <= 0) return 'Fiyat Görüşülür';
    final formatted = listing.price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    final symbol =
        listing.currency == 'TRY' || listing.currency == 'TL' ? '₺' : '';
    return '$symbol$formatted';
  }

  String _location(ListingModel listing) {
    return [
      listing.provinceName,
      listing.districtName,
      listing.quarterName,
    ].where((s) => s.isNotEmpty).join(' / ');
  }

  String _displayType(String type) {
    switch (type.toLowerCase()) {
      case 'kiralik':
        return 'KİRALIK';
      case 'satilik':
        return 'SATILIK';
      default:
        return type.toUpperCase();
    }
  }

  String _displayState(String state) {
    switch (state.toUpperCase()) {
      case 'WAITING_FOR_APPROVAL':
        return 'Onay Bekliyor';
      case 'LIVE':
        return 'Yayında';
      case 'REJECTED':
        return 'Reddedildi';
      case 'CHANGE_REQUIRED':
        return 'Düzenleme İsteniyor';
      default:
        return state;
    }
  }

  String _stripHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    return html_parser.parse(html).body?.text.trim() ?? '';
  }

  String _propertyLabel(String code) {
    switch (code) {
      case 'm2-brut':
        return 'm² (Brüt)';
      case 'm2-net':
        return 'm² (Net)';
      case 'oda-sayisi':
        return 'Oda Sayısı';
      case 'bina-yasi':
        return 'Bina Yaşı';
      case 'bulundugu-kat':
        return 'Bulunduğu Kat';
      case 'kat-sayisi':
        return 'Kat Sayısı';
      case 'isitma':
        return 'Isıtma';
      case 'banyo-sayisi':
        return 'Banyo Sayısı';
      case 'balkon':
        return 'Balkon';
      case 'asansor':
        return 'Asansör';
      case 'otopark':
        return 'Otopark';
      case 'esyali':
        return 'Eşyalı';
      case 'aidat-tl':
        return 'Aidat (TL)';
      case 'depozito-tl':
        return 'Depozito (TL)';
      case 'krediye-uygun':
        return 'Krediye Uygun';
      case 'tapu-durumu':
        return 'Tapu Durumu';
      default:
        return code.replaceAll('-', ' ');
    }
  }

  String _propertyValue(PropertyModel property) {
    final code = property.code.toLowerCase();

    if (property.numberValue != null &&
        (code.contains('m2') || code == 'aidat-tl' || code == 'depozito-tl')) {
      if (code == 'aidat-tl' && property.numberValue == 0) return 'Yok';
      return property.numberValue.toString();
    }

    if (property.stringValue != null && property.stringValue!.isNotEmpty) {
      return property.stringValue!;
    }

    final value = property.value;
    if (value.isEmpty || value == code) return '-';

    if (value.startsWith('oda-sayisi-')) {
      final n = value.replaceAll('oda-sayisi-', '');
      if (n.length == 2) return '${n[0]}+${n[1]}';
      return n;
    }
    if (value.startsWith('bina-yasi-')) {
      return value.replaceAll('bina-yasi-', '').replaceAll('-', ' ');
    }
    if (value.startsWith('bulundugu-kat-')) {
      return value.replaceAll('bulundugu-kat-', '');
    }
    if (value.startsWith('kat-sayisi-')) {
      return value.replaceAll('kat-sayisi-', '');
    }
    if (value.startsWith('banyo-sayisi-')) {
      return value.replaceAll('banyo-sayisi-', '');
    }
    if (value.contains('-')) {
      final parts = value.split('-');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ').replaceAll('_', ' ');
      }
    }

    return value;
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openListing(ListingModel other) {
    Navigator.pushNamed(
      context,
      AppRouter.portfolioApproveDetail,
      arguments: {
        'listingId': other.id,
        'contactNo': other.contactNo,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return const RoleSidebar(currentPage: 'Portföy Onay');
        },
      ),
      appBar: AdminPanelAppBar(
        title: 'Portföy Onay Detayı',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      bottomNavigationBar: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is AuthAuthenticated) {
            final authCubit = context.read<AuthCubit>();
            return FutureBuilder<List<String>>(
              future: authCubit.getUserRoleCodes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userRoleCodes = snapshot.data ?? [];

                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_office_broker') ||
                    userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_form_applications') ||
                    userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else if (userRoleCodes.contains('role_sale_applications') ||
                    userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: -1);
                } else {
                  return const FrancahiseNavbar(currentIndex: -1);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: -1);
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFE53935)),
              ),
            )
          : _errorMessage != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final listing = _listing!;
    final description = _stripHtml(
      listing.realEstateDescription?.isNotEmpty == true
          ? listing.realEstateDescription
          : listing.description,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) => setState(() => _selectedImageIndex = index),
              itemBuilder: (context, index) => _buildMainImage(_images[index]),
            ),
          ),
          if (_images.length > 1)
            SizedBox(
              height: 72,
              child: ListView.separated(
                controller: _thumbScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedImageIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE53935)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildThumbImage(_images[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_brokerRoleChecked && _canShowApprovalActions(listing))
                  _buildListingOperationsBar(listing),
                if (_brokerRoleChecked && _canShowApprovalActions(listing))
                  const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _displayType(listing.type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _displayState(listing.state),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPrice(listing),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                    Text(
                      'Portföy No: ${listing.listingNo}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _location(listing),
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildContactCard(listing),
                const SizedBox(height: 24),
                const Text(
                  'Genel Özellikler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 12),
                _buildPropertiesGrid(listing),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'İlan Açıklaması',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
                if (listing.connectedContactTitle.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.connectedContactTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bu portföy, Ticaret Bakanlığı EİDS sistemi üzerinden yetkilendirilmiştir.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (listing.lat != null && listing.lon != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Konum',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MapDisplayWidget(
                      position: LatLng(listing.lat!, listing.lon!),
                      address: _location(listing),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Danışmanın Diğer İlanları',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 14),
                _buildOtherListings(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesGrid(ListingModel listing) {
    final entries = listing.properties.entries.toList();
    if (entries.isEmpty) {
      return Text('Özellik bilgisi bulunamadı', style: TextStyle(color: Colors.grey[600]));
    }

    return Column(
      children: entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.square_foot, size: 18, color: Colors.red[400]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _propertyLabel(entry.key),
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
              Text(
                _propertyValue(entry.value),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactCard(ListingModel listing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage: ImageUtils.isValidS3Id(listing.contactPicture)
                    ? NetworkImage(
                        ImageUtils.getCoverImageUrl(listing.contactPicture!),
                      )
                    : null,
                child: !ImageUtils.isValidS3Id(listing.contactPicture)
                    ? Icon(Icons.person, color: Colors.grey[600])
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.contactTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (listing.contactTypeDescription.isNotEmpty)
                      Text(
                        listing.contactTypeDescription,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (listing.contactEmail.isNotEmpty)
            _contactButton(
              icon: Icons.email_outlined,
              label: listing.contactEmail,
              onTap: () => _launchEmail(listing.contactEmail),
            ),
          if (listing.contactTel != null && listing.contactTel!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _contactButton(
              icon: Icons.phone_outlined,
              label: listing.contactTel!,
              onTap: () => _launchPhone(listing.contactTel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1F2937),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherListings() {
    if (_isLoadingOthers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFFE53935)),
          ),
        ),
      );
    }

    if (_otherListings.isEmpty) {
      return Text(
        'Danışmana ait başka ilan bulunamadı',
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    return SizedBox(
      height: 340,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _otherListings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return _buildOtherListingCard(_otherListings[index]);
        },
      ),
    );
  }

  String? _otherListingCoverUrl(ListingModel listing) {
    if (listing.medias.isNotEmpty) {
      final cover = listing.medias.firstWhere(
        (m) => m.isCover && m.type == 'image',
        orElse: () => listing.medias.first,
      );
      if (ImageUtils.isValidS3Id(cover.standart)) {
        return ImageUtils.getCoverImageUrl(cover.standart!);
      }
      if (ImageUtils.isValidS3Id(cover.thumbnail)) {
        return ImageUtils.getCoverImageUrl(cover.thumbnail!);
      }
    }
    if (ImageUtils.isValidS3Id(listing.coverPicture)) {
      return ImageUtils.getCoverImageUrl(listing.coverPicture);
    }
    if (ImageUtils.isValidS3Id(listing.picture)) {
      return ImageUtils.getCoverImageUrl(listing.picture!);
    }
    return null;
  }

  Widget _buildOtherListingCard(ListingModel other) {
    final imageUrl = _otherListingCoverUrl(other);
    final location = [
      other.districtName,
      other.provinceName,
    ].where((s) => s.isNotEmpty).join(', ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openListing(other),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 280,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 148,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _otherListingImagePlaceholder(),
                            )
                          : _otherListingImagePlaceholder(),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _displayType(other.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        other.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.35,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatPrice(other),
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              other.contactTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Text(
                  other.contactTypeDescription.isNotEmpty
                      ? other.contactTypeDescription
                      : 'Danışman',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListingOperationsBar(ListingModel listing) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFFE53935),
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  'İlan İşlemleri',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _isProcessingAction
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(Color(0xFFE53935)),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOperationButton(
                        label: 'İlanı Onayla',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF22C55E),
                        onPressed: () => _showApproveDialog(listing),
                      ),
                      const SizedBox(height: 10),
                      _buildOperationButton(
                        label: 'İlanı Reddet',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFE53935),
                        onPressed: () => _showRejectDialog(listing),
                      ),
                      const SizedBox(height: 10),
                      _buildOperationButton(
                        label: 'Düzenleme Talep Et',
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFF3B82F6),
                        onPressed: () => _showEditRequestDialog(listing),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessingAction ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<String?> _showMobileListingActionSheet({
    required String title,
    required String message,
    bool requireMessage = false,
    String messageHint = 'Düzenleme mesajı',
    String confirmLabel = 'Onayla',
    Color confirmColor = const Color(0xFFE53935),
  }) async {
    final messageController = TextEditingController();

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Material(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => Navigator.pop(sheetContext),
                            borderRadius: BorderRadius.circular(8),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.45,
                          ),
                        ),
                        if (requireMessage) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: messageController,
                            maxLines: 4,
                            minLines: 3,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: messageHint,
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = messageController.text.trim();
                              if (requireMessage && text.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      messageHint == 'Düzenleme mesajı'
                                          ? 'Lütfen düzenleme mesajını yazın.'
                                          : 'Lütfen reddetme nedenini yazın.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              Navigator.pop(
                                sheetContext,
                                requireMessage ? text : '',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text(
                            'Vazgeç',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
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

    messageController.dispose();
    return result;
  }

  Future<void> _showApproveDialog(ListingModel listing) async {
    final confirmed = await _showMobileListingActionSheet(
      title: 'İlanı Onayla',
      message:
          'Bu ilanı onaylamak istediğinize emin misiniz?\nOnaylanan ilan yayına çıkacaktır.',
      confirmLabel: 'Onayla',
      confirmColor: const Color(0xFF22C55E),
    );

    if (confirmed == null || !mounted) return;
    await _handleApprove(listing);
  }

  Future<void> _showRejectDialog(ListingModel listing) async {
    final message = await _showMobileListingActionSheet(
      title: 'İlanı Reddet',
      message: 'Bu işlemi gerçekleştirmek istediğinize emin misiniz?',
      requireMessage: true,
      messageHint: 'Reddetme nedeni',
      confirmLabel: 'Reddet',
    );

    if (message == null || !mounted) return;
    await _handleReject(listing, message);
  }

  Future<void> _showEditRequestDialog(ListingModel listing) async {
    final message = await _showMobileListingActionSheet(
      title: 'İlanı Düzenlemeye Gönder',
      message: 'Bu işlemi gerçekleştirmek istediğinize emin misiniz?',
      requireMessage: true,
      messageHint: 'Düzenleme mesajı',
      confirmLabel: 'Onayla',
    );

    if (message == null || !mounted) return;
    await _handleEditRequest(listing, message);
  }

  Future<void> _handleApprove(ListingModel listing) async {
    setState(() => _isProcessingAction = true);
    final result = await _myListingsRepository.approveListing(listing.id);
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    result.fold(
      (failure) => _showSnack(failure.message, Colors.red),
      (apiMessage) {
        _showSnack(apiMessage, const Color(0xFF22C55E));
        Navigator.pop(context, true);
      },
    );
  }

  Future<void> _handleReject(ListingModel listing, String message) async {
    setState(() => _isProcessingAction = true);
    final result = await _myListingsRepository.rejectListing(
      listing.id,
      message: message,
    );
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    result.fold(
      (failure) => _showSnack(failure.message, Colors.red),
      (apiMessage) {
        _showSnack(apiMessage, const Color(0xFFE53935));
        Navigator.pop(context, true);
      },
    );
  }

  Future<void> _handleEditRequest(ListingModel listing, String message) async {
    setState(() => _isProcessingAction = true);
    final result = await _myListingsRepository.requestListingEdit(
      listing.id,
      message: message,
    );
    if (!mounted) return;
    setState(() => _isProcessingAction = false);

    result.fold(
      (failure) => _showSnack(failure.message, Colors.red),
      (apiMessage) {
        _showSnack(
          apiMessage.isNotEmpty
              ? apiMessage
              : 'İlan durumu başarılı bir şekilde danışmana iletildi',
          const Color(0xFF3B82F6),
        );
        Navigator.pop(context, true);
      },
    );
  }

  Widget _otherListingImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.home_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildMainImage(String url) {
    if (url.isEmpty) return ImageUtils.getNoImageWidget(size: 80);
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => ImageUtils.getFailedImageWidget(size: 80),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return ImageUtils.getLoadingWidget();
      },
    );
  }

  Widget _buildThumbImage(String url) {
    if (url.isEmpty) {
      return SizedBox(
        width: 70,
        height: 52,
        child: ImageUtils.getNoImageWidget(size: 30),
      );
    }
    return Image.network(
      url,
      width: 70,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ImageUtils.getFailedImageWidget(size: 30),
    );
  }
}
