// Bu dosya '/system-settings' route'u ile açılır.
// Admin paneldeki 'Sistem Ayarları' menüsüne tıklanınca bu ekran açılır.
// Route tanımı: AppRouter.routes içinde '/system-settings': (context) => const SystemSettingsScreen()
//
// Eğer başka bir yerde route eklemesi gerekiyorsa, AppRouter ve main.dart dosyalarını kontrol edin.
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/infrastructure/featured_listing/featured_listing_repository.dart';
import 'package:zecorner/models/featured_listing/featured_listing_model.dart';
import 'package:zecorner/models/featured_listing/featured_listing_create_request.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/listing_repository.dart';
import 'package:zecorner/models/list/listing_model.dart';
import 'package:zecorner/presentation/screens/systemsettings/modern_date_range_picker.dart';
import 'package:intl/intl.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // API Repository
  late final FeaturedListingRepository _repository;

  // İlanlar state olarak tutulacak
  List<FeaturedListingModel> _ilanlar = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = FeaturedListingRepository(dio: Dio());
    _loadFeaturedListings();
  }

  Future<void> _loadFeaturedListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getFeaturedListings();

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
        _showErrorSnackBar(failure.message);
      },
      (response) {
        setState(() {
          _isLoading = false;
          _ilanlar = response.featuredListings;
        });
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, FeaturedListingModel ilan) async {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red[600],
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'İlanı Sil',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Bu öne çıkan ilanı silmek istediğinize emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Listing info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${ilan.listingNo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ilan.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  // İptal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sil
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[600]!, Colors.red[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            Navigator.of(context).pop();
                            final result = await _repository.deleteFeaturedListing(ilan.id);
                            result.fold(
                              (failure) {
                                _showErrorSnackBar(failure.message);
                              },
                              (success) {
                                _showSuccessSnackBar('İlan başarıyla silindi');
                                _loadFeaturedListings();
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Sil',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Sistem Ayarları');
        },
      ),
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: "Sistem Ayarları",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => _AddFeaturedListingModal(
                      repository: _repository,
                      onSuccess: () {
                        _loadFeaturedListings();
                      },
                    ),
                  );
                },
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Yeni Öne Çıkan İlan Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.red[600],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadFeaturedListings,
                                icon: Icon(Icons.refresh),
                                label: Text('Tekrar Dene'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _ilanlar.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox,
                                      size: 64, color: Colors.grey[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    'Henüz öne çıkan ilan yok',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadFeaturedListings,
                              color: Colors.red[600],
              child: ListView.builder(
                itemCount: _ilanlar.length,
                itemBuilder: (context, i) {
                  final ilan = _ilanlar[i];
                                  final imageUrl = ilan.coverPicure != null &&
                                          ImageUtils.isValidS3Id(
                                              ilan.coverPicure)
                                      ? ImageUtils.getCoverImageUrl(
                                          ilan.coverPicure)
                                      : (ilan.picture != null &&
                                              ImageUtils.isValidS3Id(
                                                  ilan.picture)
                                          ? ImageUtils.getCoverImageUrl(
                                              ilan.picture)
                                          : null);

                  return Container(
                    margin: EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                            children: [
                              // Görsel
                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: imageUrl != null
                                                    ? Image.network(
                                                        imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Container(
                                                            width: 60,
                                                            height: 60,
                                                            color:
                                                                Colors.grey[300],
                                                            child: Icon(
                                                                Icons.image,
                                                                color: Colors
                                                                    .grey[500]),
                                                          );
                                                        },
                                                      )
                                                    : Container(
                                                        width: 60,
                                                        height: 60,
                                                        color: Colors.grey[300],
                                                        child: Icon(Icons.image,
                                                            color: Colors
                                                                .grey[500]),
                                ),
                              ),
                              SizedBox(width: 14),
                              // Bilgiler
                              Expanded(
                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                      children: [
                                        Text(
                                                          ilan.title,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                                          "#${ilan.listingNo}",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                                    Text(
                                                        "Danışman: ${ilan.contactTitle}",
                                                        style: TextStyle(
                                                            fontSize: 13)),
                                                    Text(
                                                        "İl: ${ilan.provinceName}  İlçe: ${ilan.districtName}",
                                                        style: TextStyle(
                                                            fontSize: 13)),
                                                    Text(
                                                        "Tip: ${ilan.realEstateType}",
                                                        style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[700])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                                        // Sil butonu
                        Positioned(
                          top: 8,
                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                          child: IconButton(
                                              icon: Icon(Icons.delete_outline,
                                                  color: Colors.red[600], size: 22),
                                              onPressed: () => _showDeleteConfirmation(context, ilan),
                                              padding: EdgeInsets.all(8),
                                              constraints: BoxConstraints(),
                                            ),
                          ),
                        ),
                        // Sıra No
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                            ),
                            child: Text(
                                              ilan.position.toString(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[700]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                              ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavbar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }
}

// Modal for adding featured listing
class _AddFeaturedListingModal extends StatefulWidget {
  final FeaturedListingRepository repository;
  final VoidCallback onSuccess;

  const _AddFeaturedListingModal({
    required this.repository,
    required this.onSuccess,
  });

  @override
  State<_AddFeaturedListingModal> createState() =>
      _AddFeaturedListingModalState();
}

class _AddFeaturedListingModalState extends State<_AddFeaturedListingModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _siraNoController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchText = '';
  ListingModel? _selectedListing;
  List<ListingModel> _allListings = [];
  bool _isSubmitting = false;

  final ListingRepository _listingRepository = ListingRepository();

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.red[600]),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _siraNoController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    final result = await _listingRepository.getListings(
      page: 1,
      limit: 100, // Get more listings for search
    );

    result.fold(
      (failure) {
        setState(() {
          _allListings = [];
        });
      },
      (response) {
        setState(() {
          _allListings = response.listings;
        });
      },
    );
  }

  List<ListingModel> get _filteredListings {
    if (_searchText.isEmpty) return [];
    return _allListings
        .where((listing) =>
            listing.title.toLowerCase().contains(_searchText.toLowerCase()) ||
            listing.listingNo.toString().contains(_searchText))
        .toList();
  }

  String get _dateText {
    if (_startDate == null && _endDate == null) {
      return "Tarih aralığı seçiniz";
    }
    if (_startDate != null && _endDate == null) {
      return "${_formatDate(_startDate!)} - ?";
    }
    if (_startDate != null && _endDate != null) {
      return "${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}";
    }
    return "Tarih aralığı seçiniz";
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
  }

  Future<void> _showModernDateRangePicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernDateRangePicker(
        startDate: _startDate,
        endDate: _endDate,
        onDateRangeSelected: (start, end, startTime, endTime) {
          setState(() {
            _startDate = start;
            _endDate = end;
            // Store times if needed, or use them directly when creating the request
            print('Start Time: ${startTime.hour}:${startTime.minute}');
            print('End Time: ${endTime.hour}:${endTime.minute}');
          });
        },
      ),
    );
  }

  Future<void> _submitFeaturedListing() async {
    if (_selectedListing == null) {
      _showErrorSnackBar('Lütfen bir ilan seçin');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showErrorSnackBar('Lütfen tarih aralığı seçin');
      return;
    }

    final position = int.tryParse(_siraNoController.text);
    if (position == null || position < 0 || position > 99) {
      _showErrorSnackBar('Lütfen 0-99 arası geçerli bir sıra numarası girin');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final request = FeaturedListingCreateRequest(
      listingId: _selectedListing!.id,
      startDate: _startDate!.toIso8601String(),
      endDate: _endDate!.toIso8601String(),
      position: position,
    );

    final result = await widget.repository.createFeaturedListing(request);

    setState(() {
      _isSubmitting = false;
    });

    result.fold(
      (failure) {
        _showErrorSnackBar(failure.message);
      },
      (success) {
        _showSuccessSnackBar('Öne çıkan ilan başarıyla eklendi');
        widget.onSuccess();
        Navigator.of(context).pop();
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
      color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Modern Header with Gradient
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[700]!, Colors.red[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.star, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                  Text(
                    "Yeni Öne Çıkan İlan Ekle",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                  ),
                ],
              ),
          ),
          
          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              
              // İlan Section with modern label
              _buildSectionLabel("İlan", Icons.home_work),
              SizedBox(height: 12),
              if (_selectedListing == null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                      hintText: "İlan ara...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.red[400]),
                    filled: true,
                      fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                    ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                if (_searchText.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _filteredListings.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'İlan bulunamadı',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                      shrinkWrap: true,
                            itemCount: _filteredListings.length,
                      itemBuilder: (context, i) {
                              final listing = _filteredListings[i];
                              final imageUrl = ImageUtils.isValidS3Id(listing.coverPicture)
                                  ? ImageUtils.getCoverImageUrl(listing.coverPicture)
                                  : (listing.picture != null &&
                                          ImageUtils.isValidS3Id(listing.picture!)
                                      ? ImageUtils.getCoverImageUrl(listing.picture!)
                                      : null);

                        return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[300],
                                              child: Icon(Icons.image,
                                                  color: Colors.grey[500]),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.image,
                                              color: Colors.grey[500]),
                                        ),
                          ),
                          title: Row(
                            children: [
                                    Expanded(
                                      child: Text(
                                        listing.title,
                                        style:
                                            TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                      "#${listing.listingNo}",
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                                subtitle: Text(listing.contactTitle),
                          onTap: () {
                            setState(() {
                                    _selectedListing = listing;
                              _searchText = '';
                              _searchController.clear();
                            });
                          },
                        );
                      },
                    ),
                  ),
              ] else ...[
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[50]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red[200]!, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Image with badge
                        Stack(
                          children: [
                            ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red[300]!, Colors.red[100]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(Icons.image, color: Colors.white, size: 30),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green[500],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(Icons.check, color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[600],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "#${_selectedListing!.listingNo}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                        Text(
                                _selectedListing!.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 12, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _selectedListing!.contactTitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
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
                        // Remove button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.red[700], size: 20),
                      onPressed: () {
                        setState(() {
                                _selectedListing = null;
                        });
                      },
                            padding: EdgeInsets.all(6),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              // Tarih Section
              _buildSectionLabel("Tarih", Icons.calendar_month),
              SizedBox(height: 12),
              GestureDetector(
                onTap: _showModernDateRangePicker,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _startDate != null && _endDate != null 
                          ? Colors.red[200]! 
                          : Colors.grey[200]!,
                      width: _startDate != null && _endDate != null ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: _dateText,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Icon(
                          Icons.date_range,
                          color: _startDate != null && _endDate != null 
                              ? Colors.red[400] 
                              : Colors.grey[400],
                        ),
                        suffixIcon: _startDate != null && _endDate != null
                            ? Icon(Icons.check_circle, color: Colors.green[500])
                            : Icon(Icons.calendar_today, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                      ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ),
              ),
              
              SizedBox(height: 24),
              
              // Sıra No Section
              _buildSectionLabel("Sıra No", Icons.format_list_numbered),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                controller: _siraNoController,
                decoration: InputDecoration(
                  hintText: "0-99",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.pin, color: Colors.red[400]),
                  filled: true,
                    fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                  ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                keyboardType: TextInputType.number,
              ),
              ),
              
              SizedBox(height: 32),
              
              // Ekle Button with modern gradient
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _selectedListing != null &&
                          _startDate != null &&
                          _endDate != null
                      ? LinearGradient(
                          colors: [Colors.red[600]!, Colors.red[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _selectedListing == null ||
                          _startDate == null ||
                          _endDate == null
                      ? Colors.grey[300]
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedListing != null &&
                          _startDate != null &&
                          _endDate != null
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ||
                            _selectedListing == null ||
                            _startDate == null ||
                            _endDate == null
                        ? null
                        : _submitFeaturedListing,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isSubmitting
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Ekle",
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
            ],
          ),
        ),
                  ),
                ),
              ),
              SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
