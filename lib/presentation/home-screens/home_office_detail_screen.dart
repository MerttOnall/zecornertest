import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/models/office/office_model.dart';
import 'package:zecorner/infrastructure/office/office_repo.dart';
import 'package:zecorner/models/list/listing_model.dart';
import 'package:zecorner/models/list/media_model.dart';
import 'package:zecorner/models/list/property_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';

class HomeOfficeDetailScreen extends StatefulWidget {
  final OfficeModel? office;
  
  const HomeOfficeDetailScreen({super.key, this.office});

  @override
  State<HomeOfficeDetailScreen> createState() => _HomeOfficeDetailScreenState();
}

class _HomeOfficeDetailScreenState extends State<HomeOfficeDetailScreen> with SingleTickerProviderStateMixin {
  final OfficeRepository _officeRepo = OfficeRepository();
  
  List<ListingModel> _listings = [];
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoadingListings = true;
  bool _isLoadingTeam = true;
  String? _errorMessageListings;
  String? _errorMessageTeam;
  int _listingsCount = 0;
  int _satilikCount = 0;
  int _kiralikCount = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.office == null) return;
    // Web'deki gibi 225 kullanılıyor; officeId aynı olmalı (get-offices cevabındaki office_id)
    debugPrint('Ofis detay API id: ${widget.office!.officeId}');
    await Future.wait([
      _loadListings(),
      _loadTeam(),
    ]);
  }

  Future<void> _loadListings() async {
    if (widget.office == null) return;
    
    setState(() {
      _isLoadingListings = true;
      _errorMessageListings = null;
    });

    final result = await _officeRepo.getOfficeListings(
      officeId: widget.office!.officeId,
      page: 1,
      pageSize: 10,
    );

    await result.fold(
      (failure) async {
        setState(() {
          _isLoadingListings = false;
          _errorMessageListings = failure.message;
        });
      },
      (listingsResponse) async {
        List<ListingModel> list = listingsResponse.listings;
        final totalCount = listingsResponse.totalCount;
        if (totalCount > list.length) {
          final fullResult = await _officeRepo.getOfficeListings(
            officeId: widget.office!.officeId,
            page: 1,
            pageSize: totalCount,
          );
          fullResult.fold(
            (_) {},
            (fullResponse) => list = fullResponse.listings,
          );
        }
        final satilik = list.where((l) => (l.type.toLowerCase().contains('sat') || l.type == 'satilik')).length;
        final kiralik = list.where((l) => l.type.toLowerCase().contains('kira') || l.type == 'kiralik').length;
        setState(() {
          _listings = list;
          _listingsCount = totalCount;
          _satilikCount = satilik;
          _kiralikCount = kiralik;
          _isLoadingListings = false;
          if (listingsResponse.teamMembers.isNotEmpty) {
            _teamMembers = listingsResponse.teamMembers;
            _isLoadingTeam = false;
          }
        });
      },
    );
  }

  Future<void> _loadTeam() async {
    if (widget.office == null) return;
    
    setState(() {
      _isLoadingTeam = true;
      _errorMessageTeam = null;
    });

    final result = await _officeRepo.getOfficeTeam(
      officeId: widget.office!.officeId,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingTeam = false;
          _errorMessageTeam = failure.message;
          _applyOfficeMembersFallback();
        });
      },
      (teamMembers) {
        setState(() {
          _isLoadingTeam = false;
          if (teamMembers.isNotEmpty) {
            _teamMembers = teamMembers;
          } else {
            _applyOfficeMembersFallback();
          }
        });
      },
    );
  }

  /// API'den ekip gelmezse ofis modelindeki officeMembers kullan
  void _applyOfficeMembersFallback() {
    if (widget.office == null || widget.office!.officeMembers.isEmpty) return;
    if (_teamMembers.isNotEmpty) return;
    final list = widget.office!.officeMembers.map((m) {
      final parts = m.memberTitle.split(' ');
      final name = parts.isNotEmpty ? parts.first : '';
      final surname = parts.length > 1 ? parts.skip(1).join(' ') : '';
      return <String, dynamic>{
        'name': name,
        'surname': surname,
        'title': m.memberTitle,
        'type_description': m.memberTypeDescription,
        'profession_description': m.memberTypeDescription,
        'picture': m.memberPicture,
      };
    }).toList();
    setState(() => _teamMembers = list);
  }

  void _shareOffice() {
    if (widget.office == null) return;
    final o = widget.office!;
    final lines = <String>[
      '🏢 ${o.officeTitle}',
      o.officeAddress,
      '',
      if (o.officeEmail.isNotEmpty) '📧 ${o.officeEmail}',
      if (o.officePhone.isNotEmpty && o.officePhone != 'Belirtilmedi') '📞 ${o.officePhone}',
      '',
      'Zecorner - Ofis detayı',
    ];
    Share.share(lines.join('\n'), subject: '${o.officeTitle} - Zecorner');
  }

  Future<void> _openOfficeInMaps() async {
    if (widget.office == null) return;
    final query = Uri.encodeComponent(widget.office!.officeAddress);
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: SvgPicture.asset(
          'assets/logo/zecorner-logo1.svg',
          width: 140,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.red),
            onPressed: _shareOffice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ofis logosu - en üstte şık kart
            if (widget.office != null) _buildOfficeLogoSection(),
            if (widget.office != null) const SizedBox(height: 8),
            // Başlık ve Adres
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.office?.officeTitle ?? "Ofis Bilgisi",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.office?.officeAddress ?? "Adres bilgisi bulunamadı",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 87, 87, 87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // İstatistikler (Yıl + Satılık/Kiralık Portföy)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStat("1", "YIL"),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildPortfolioStat(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // E-posta ve Telefon (şık kırmızı butonlar)
            if (widget.office != null) _buildContactButtons(),
            if (widget.office != null) const SizedBox(height: 16),

            // Konum ve Haritada Aç
            if (widget.office != null && widget.office!.officeAddress.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Konum',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.office!.officeAddress,
                      style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openOfficeInMaps,
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text('Haritada Aç'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[700],
                          side: BorderSide(color: Colors.red[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Sekmeler
            Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: "İlanlarımız ($_listingsCount)"),
                      Tab(text: "Ekibimiz (${_displayTeamMembers.length})"),
                    ],
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.red,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // İlanlar Sekmesi
                      _buildListingsTab(),
                      // Ekip Sekmesi
                      _buildTeamTab(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  static const Color _accentRed = Color.fromRGBO(238, 46, 36, 1);

  /// En üstte ofis logosu - beyaz kart, ince kırmızı çerçeve
  Widget _buildOfficeLogoSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentRed.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildOfficeLogo(widget.office!.officeLogo),
      ),
    );
  }

  Widget _buildOfficeLogo(String? s3Id) {
    if (!ImageUtils.isValidS3Id(s3Id)) {
      return SizedBox(
        width: 140,
        height: 72,
        child: Icon(
          Icons.business_rounded,
          size: 48,
          color: Colors.grey[400],
        ),
      );
    }
    final imageUrl = ImageUtils.getS3FileUrl(s3Id);
    return Container(
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 88, minWidth: 100, minHeight: 50),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 140,
            height: 72,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_accentRed),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: 140,
            height: 72,
            child: Icon(Icons.business_rounded, size: 48, color: Colors.grey[400]),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioStat() {
    final hasBreakdown = _satilikCount > 0 || _kiralikCount > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBreakdown) ...[
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _accentRed,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$_satilikCount ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: 'Satılık, '),
                TextSpan(
                  text: '$_kiralikCount ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: 'Kiralık'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '($_listingsCount Portföy)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _accentRed.withOpacity(0.9),
            ),
          ),
        ] else ...[
          Text(
            '$_listingsCount',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            'PORTFÖY',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactButtons() {
    final office = widget.office!;
    final hasEmail = office.officeEmail.isNotEmpty;
    final hasPhone = office.officePhone.isNotEmpty && office.officePhone != 'Belirtilmedi';
    if (!hasEmail && !hasPhone) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (hasEmail)
            _buildContactButton(
              icon: Icons.email_outlined,
              label: office.officeEmail,
              onTap: () => _launchEmail(office.officeEmail),
            ),
          if (hasEmail && hasPhone) const SizedBox(height: 12),
          if (hasPhone)
            _buildContactButton(
              icon: Icons.phone_outlined,
              label: office.officePhone,
              onTap: () => _launchPhone(office.officePhone),
            ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _accentRed,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _buildComingSoonEmptyState({required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 44,
                color: _accentRed,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Çok yakında',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsTab() {
    if (_isLoadingListings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessageListings != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hata: $_errorMessageListings',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadListings,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_listings.isEmpty) {
      return _buildComingSoonEmptyState(
        subtitle: 'İlanlarımız çok yakında burada olacak.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listings.length,
      itemBuilder: (context, index) {
        final listing = _listings[index];
        return _buildListingCard(listing);
      },
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    // Cover image bul
    final coverMedia = listing.medias.firstWhere(
      (media) => media.isCover,
      orElse: () => listing.medias.isNotEmpty ? listing.medias.first : MediaModel(
        type: 'image',
        isCover: false,
      ),
    );

    final imageUrl = coverMedia.standart != null
        ? ImageUtils.getS3FileUrl(coverMedia.standart)
        : coverMedia.hd != null
            ? ImageUtils.getS3FileUrl(coverMedia.hd)
            : coverMedia.thumbnail != null
                ? ImageUtils.getS3FileUrl(coverMedia.thumbnail)
                : null;

    // Type badge text
    final typeText = listing.type == 'satilik' ? 'SATILIK' : 'KİRALIK';

    // Location text
    final locationText = '${listing.provinceName} / ${listing.districtName}${listing.quarterName.isNotEmpty ? ' / ${listing.quarterName}' : ''}';

    // Price format
    final priceText = '₺${_formatPrice(listing.price)}';

    // Properties (m2, oda sayısı vb.)
    final m2Property = listing.propertiesShortList.firstWhere(
      (p) => p.code == 'm2' || p.code == 'metrekare',
      orElse: () => PropertyModel(code: '', value: '', valueId: ''),
    );
    final roomProperty = listing.propertiesShortList.firstWhere(
      (p) => p.code == 'oda-sayisi' || p.code == 'oda',
      orElse: () => PropertyModel(code: '', value: '', valueId: ''),
    );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.homeListingDetail,
          arguments: listing, // ListingModel objesini direkt geçir
        );
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      typeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (m2Property.value.isNotEmpty || roomProperty.value.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (m2Property.value.isNotEmpty)
                          _buildFeature(Icons.square_foot, "${m2Property.value} m2"),
                        if (m2Property.value.isNotEmpty && roomProperty.value.isNotEmpty)
                          const SizedBox(width: 16),
                        if (roomProperty.value.isNotEmpty)
                          _buildFeature(Icons.king_bed, roomProperty.value),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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

  /// Gösterilecek ekip listesi: API cevabı veya ofis modelindeki officeMembers
  List<Map<String, dynamic>> get _displayTeamMembers {
    if (_teamMembers.isNotEmpty) return _teamMembers;
    if (widget.office == null || widget.office!.officeMembers.isEmpty) return [];
    return widget.office!.officeMembers.map((m) {
      final parts = m.memberTitle.split(' ');
      return <String, dynamic>{
        'name': parts.isNotEmpty ? parts.first : '',
        'surname': parts.length > 1 ? parts.skip(1).join(' ') : '',
        'title': m.memberTitle,
        'type_description': m.memberTypeDescription,
        'profession_description': m.memberTypeDescription,
        'picture': m.memberPicture,
      };
    }).toList();
  }

  Widget _buildTeamTab() {
    if (_isLoadingTeam) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessageTeam != null && _displayTeamMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hata: $_errorMessageTeam',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeam,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_displayTeamMembers.isEmpty) {
      return _buildComingSoonEmptyState(
        subtitle: 'Ekibimiz çok yakında burada olacak.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _displayTeamMembers.length,
      itemBuilder: (context, index) {
        final member = _displayTeamMembers[index];
        return _buildTeamMemberCard(member);
      },
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? '';
    final surname = member['surname'] ?? '';
    final fullName = '$name $surname'.trim();
    final title = member['title'] ?? fullName;
    // API: type_description ve profession_description (örn. Gayrimenkul Danışmanı, Broker)
    final profession = member['profession_description'] ?? member['type_description'] ?? '';
    final picture = member['picture'] as String?;

    return Card(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundImage: picture != null
                ? NetworkImage(ImageUtils.getS3FileUrl(picture))
                : null,
            child: picture == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            profession,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(0)}.${((price % 1000000) / 1000).toStringAsFixed(0).padLeft(3, '0')}.000';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}.${(price % 1000).toStringAsFixed(0).padLeft(3, '0')}';
    }
    return price.toString();
  }
}
