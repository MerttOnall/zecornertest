import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_in_appbar.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/infrastructure/contact/contact_search_repository.dart';
import 'package:zecorner/models/contact/contact_search_model.dart';
import 'dart:async';

// Modal widget'ı - ana widget'ın state'ini dinler
class _ListingPickerModal extends StatefulWidget {
  final List<ListingPanelModel> listings;
  final bool isLoading;
  final String? errorMessage;
  final ListingPanelModel? selectedListing;
  final TextEditingController searchController;
  final Function(ListingPanelModel) onSelect;
  final VoidCallback onRefresh;

  const _ListingPickerModal({
    required this.listings,
    required this.isLoading,
    this.errorMessage,
    this.selectedListing,
    required this.searchController,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  State<_ListingPickerModal> createState() => _ListingPickerModalState();
}

class _ListingPickerModalState extends State<_ListingPickerModal> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<ListingPanelModel> get _filteredListings {
    final query = widget.searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.listings;

    return widget.listings.where((listing) {
      return listing.title.toLowerCase().contains(query) ||
          listing.listingNo.toString().contains(query);
    }).toList();
  }

  String _getListingDisplayText(ListingPanelModel listing) {
    return '${listing.title} - ${listing.listingNo}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'İlan Seçiniz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: widget.searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'İlan ara...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          
          // List
          Expanded(
            child: widget.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE53935),
                    ),
                  )
                : widget.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton.icon(
                                onPressed: widget.onRefresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredListings.isEmpty
                    ? Center(
                        child: Text(
                          'Seçenek Bulunamadı',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _filteredListings.length,
                        itemBuilder: (context, index) {
                          final listing = _filteredListings[index];
                          final isSelected = widget.selectedListing?.id == listing.id;
                          
                          return InkWell(
                            onTap: () => widget.onSelect(listing),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE53935).withOpacity(0.08)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE53935).withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getListingDisplayText(listing),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFE53935),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class TransactionNotificationScreen extends StatefulWidget {
  const TransactionNotificationScreen({Key? key}) : super(key: key);

  @override
  State<TransactionNotificationScreen> createState() => _TransactionNotificationScreenState();
}

class _TransactionNotificationScreenState extends State<TransactionNotificationScreen> {
  ListingPanelModel? _selectedListing;
  ListingPreSale? _preSale;
  bool _preSaleLoading = false;
  int _preSaleToken = 0;
  String? _selectedClosingType;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _closingTypeSearchController = TextEditingController();
  final MyListingsRepository _repository = MyListingsRepository();
  final ContactSearchRepository _contactRepository = ContactSearchRepository();
  
  List<ListingPanelModel> _listings = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ValueNotifier<List<ListingPanelModel>> _listingsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);

  // Kapanış tipleri
  final List<String> _closingTypes = [
    'Süresi Dolmuş',
    'Kiralandı',
    'İptal Edildi',
  ];

  // Komisyon alanları (sadece "Kiralandı" seçildiğinde)
  ContactSearchModel? _selectedTenant; // Kiralayan
  final TextEditingController _tenantSearchController = TextEditingController();
  final TextEditingController _rentalValueController = TextEditingController();
  final TextEditingController _lessorCommissionRateController = TextEditingController();
  final TextEditingController _lessorCommissionAmountController = TextEditingController();
  final TextEditingController _tenantCommissionRateController = TextEditingController();
  final TextEditingController _tenantCommissionAmountController = TextEditingController();
  
  // Hesaplanan değerler (read-only)
  double _lessorCommissionExcludingVAT = 0;
  double _tenantCommissionExcludingVAT = 0;
  double _totalCommissionIncludingVAT = 0;
  double _totalCommissionExcludingVAT = 0;
  
  Timer? _tenantSearchTimer;
  List<ContactSearchModel> _tenantSearchResults = [];
  bool _isSearchingTenant = false;
  bool _showTenantSearchResults = false;

  static const double _vatRate = 0.20; // KDV %20

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    await _loadListingsWithCallback(null);
  }

  Future<void> _loadListingsWithCallback(VoidCallback? onLoaded) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _isLoadingNotifier.value = true;

    final contact = await MyListingsRepository.contactQueryForSession();
    final result = await _repository.getMyListings(
      page: 1, // Web'de page=1 kullanılıyor
      pageSize: 1000, // Tüm ilanları çekmek için büyük bir sayı
      state: 'LIVE', // Web API'de state=LIVE kullanılıyor, sadece aktif ilanları göster
      contact: contact,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
          _listings = [];
        });
        _listingsNotifier.value = [];
        _isLoadingNotifier.value = false;
        onLoaded?.call();
      },
      (response) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _listings = MyListingsRepository.keepSessionListings(
            response.listings,
            contact,
          );
        });
        _listingsNotifier.value = _listings;
        _isLoadingNotifier.value = false;
        onLoaded?.call();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _closingTypeSearchController.dispose();
    _tenantSearchController.dispose();
    _rentalValueController.dispose();
    _lessorCommissionRateController.dispose();
    _lessorCommissionAmountController.dispose();
    _tenantCommissionRateController.dispose();
    _tenantCommissionAmountController.dispose();
    _tenantSearchTimer?.cancel();
    _listingsNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  bool get _hasCustomerOwner => _preSale?.hasOwner == true;

  Future<void> _loadPreSale(String listingId) async {
    final token = ++_preSaleToken;
    setState(() {
      _preSaleLoading = true;
      _preSale = null;
    });

    final preSale = await _repository.getPreSale(listingId);
    if (!mounted || token != _preSaleToken) return;
    setState(() {
      _preSale = preSale;
      _preSaleLoading = false;
    });
  }

  String _getListingDisplayText(ListingPanelModel listing) {
    return '${listing.title} - ${listing.listingNo}';
  }

  void _showListingPicker() {
    _searchController.clear();

    // Veriler henüz yüklenmediyse veya önceki yükleme hata verdiyse tekrar dene
    if ((_listings.isEmpty || _errorMessage != null) && !_isLoading) {
      _loadListings();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<List<ListingPanelModel>>(
            valueListenable: _listingsNotifier,
            builder: (context, listings, _) {
              return _ListingPickerModal(
                listings: listings,
                isLoading: isLoading,
                errorMessage: _errorMessage,
                selectedListing: _selectedListing,
                searchController: _searchController,
                onSelect: (listing) {
                  setState(() {
                    _selectedListing = listing;
                    _preSale = null;
                    _preSaleLoading = true;
                  });
                  Navigator.pop(context);
                  _loadPreSale(listing.id);
                },
                onRefresh: _loadListings,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminPanelInAppBar(
        title: 'İşlem Bildirimi',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              
              // İlan Seçiniz Dropdown
              _buildSectionTitle('İlan Seçiniz'),
              const SizedBox(height: 12),
              _buildListingDropdown(),
              if (_selectedListing == null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 6),
                  child: Text(
                    'Kapatmak istediğiniz ilanı seçiniz',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              // Mülk sahibi: web preSale.owner ile aynı kutu
              if (_selectedListing != null && _preSaleLoading) ...[
                const SizedBox(height: 24),
                const LinearProgressIndicator(
                  color: Color(0xFFE53935),
                  backgroundColor: Color(0xFFFEE2E2),
                  minHeight: 3,
                ),
              ],
              if (_selectedListing != null &&
                  !_preSaleLoading &&
                  !_hasCustomerOwner) ...[
                const SizedBox(height: 24),
                _buildCustomerWarningCard(),
              ],
              if (_selectedListing != null &&
                  !_preSaleLoading &&
                  _hasCustomerOwner) ...[
                const SizedBox(height: 24),
                _buildOwnerCard(),
              ],
              
              // Kapanış Tipi Dropdown (sadece ilan seçildiyse)
              if (_selectedListing != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Kapanış Tipi'),
                const SizedBox(height: 12),
                _buildClosingTypeDropdown(),
                if (_selectedClosingType == null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 6),
                    child: Text(
                      'Kapanış tipini seçiniz',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
              
              // Komisyon alanları (sadece "Kiralandı" seçildiğinde)
              if (_selectedClosingType == 'Kiralandı') ...[
                const SizedBox(height: 24),
                _buildCommissionInfoCard(),
                const SizedBox(height: 24),
                _buildCommissionFields(),
              ],
              
              // İlanı Kapat Butonu
              if (_selectedListing != null && 
                  _selectedClosingType != null &&
                  (_selectedClosingType != 'Kiralandı' || 
                   (_selectedTenant != null && _rentalValueController.text.isNotEmpty))) ...[
                const SizedBox(height: 32),
                _buildCloseListingButton(),
              ],
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red.shade700,
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFE53935),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lütfen mülkün sahibini müşteriler kısmından tanımlayız.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/customers');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Müşterilerime Git',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    final preSale = _preSale;
    final title = (preSale?.ownerTitle ?? '').trim();
    final type = (preSale?.ownerTypeDescription ?? '').trim();
    final picture = ImageUtils.getS3FileUrl(preSale?.ownerPicture);
    final initials = _ownerInitials(title);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFEE2E2),
            backgroundImage: picture.isNotEmpty ? NetworkImage(picture) : null,
            child: picture.isEmpty
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Mülk sahibi' : title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ownerInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MS';
    String letter(String value) =>
        value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return letter(parts.first);
    return letter(parts.first) + letter(parts.last);
  }

  Widget _buildClosingTypeDropdown() {
    return GestureDetector(
      onTap: _showClosingTypePicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedClosingType ?? 'Kapanış tipini seçiniz',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedClosingType != null 
                        ? const Color(0xFF1F2937) 
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClosingTypePicker() {
    _closingTypeSearchController.clear();
    List<String> filteredTypes = List.from(_closingTypes);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Kapanış Tipi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _closingTypeSearchController,
                      autofocus: false,
                      onChanged: (value) {
                        setModalState(() {
                          if (value.isEmpty) {
                            filteredTypes = List.from(_closingTypes);
                          } else {
                            filteredTypes = _closingTypes
                                .where((type) => 
                                    type.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Ara...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                
                // List
                Expanded(
                  child: filteredTypes.isEmpty
                      ? Center(
                          child: Text(
                            'Seçenek Bulunamadı',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: filteredTypes.length,
                          itemBuilder: (context, index) {
                            final type = filteredTypes[index];
                            final isSelected = _selectedClosingType == type;
                            
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedClosingType = type;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE53935).withOpacity(0.08)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE53935).withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFFE53935)
                                              : const Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseListingButton() {
    return ElevatedButton(
      onPressed: () {
        // İlanı kapat işlemi
        _closeListing();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      child: const Text(
        'İlanı Kapat',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Future<void> _closeListing() async {
    if (_selectedListing == null || _selectedClosingType == null) {
      return;
    }

    // "Kiralandı" seçildiyse validasyonlar
    if (_selectedClosingType == 'Kiralandı') {
      if (_selectedTenant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen kiralayan seçiniz'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }
      if (_rentalValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen kiralama değerini giriniz'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
        return;
      }
    }

    // TODO: API çağrısı yapılacak
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('İlan başarıyla kapatıldı: ${_selectedListing!.title}'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );

    // Formu temizle
    setState(() {
      _selectedListing = null;
      _preSale = null;
      _preSaleLoading = false;
      _selectedClosingType = null;
      _selectedTenant = null;
      _tenantSearchController.clear();
      _rentalValueController.clear();
      _lessorCommissionRateController.clear();
      _lessorCommissionAmountController.clear();
      _tenantCommissionRateController.clear();
      _tenantCommissionAmountController.clear();
      _lessorCommissionExcludingVAT = 0;
      _tenantCommissionExcludingVAT = 0;
      _totalCommissionIncludingVAT = 0;
      _totalCommissionExcludingVAT = 0;
    });
  }

  Widget _buildCommissionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Kiralama Komisyonları Hakkında Bilgilendirme',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'Eğer Kapanış Tipi '),
                TextSpan(
                  text: '"Kiralandı"',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' olarak seçildiyse:\n'),
                const TextSpan(text: 'Kiraya veren ve kiracıdan alınacak komisyon oranlarını '),
                TextSpan(
                  text: 'KDV dahil',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' olacak şekilde giriniz.\n\n'),
                TextSpan(
                  text: 'Kiraya Veren Komisyonu:\n',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: 'Komisyon oranını veya tutarını '),
                TextSpan(
                  text: 'KDV dahil',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' olarak giriniz.\n'),
                const TextSpan(text: '• Komisyon Oranı girildikten sonra, yanında bulunan '),
                WidgetSpan(
                  child: Icon(Icons.calculate_rounded, size: 16, color: Colors.grey.shade700),
                ),
                const TextSpan(text: ' simgesi ile Komisyon Tutarı hesaplanabilir.\n'),
                const TextSpan(text: '• Komisyon Tutarı girildikten sonra, yanında bulunan '),
                WidgetSpan(
                  child: Icon(Icons.calculate_rounded, size: 16, color: Colors.grey.shade700),
                ),
                const TextSpan(text: ' simgesi ile Komisyon Oranı hesaplanabilir.\n\n'),
                TextSpan(
                  text: 'Kiracı Komisyonu:\n',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: 'Komisyon oranını veya tutarını '),
                TextSpan(
                  text: 'KDV dahil',
                  style: TextStyle(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' olarak giriniz.\n'),
                const TextSpan(text: '• Komisyon Oranı girildikten sonra, yanında bulunan '),
                WidgetSpan(
                  child: Icon(Icons.calculate_rounded, size: 16, color: Colors.grey.shade700),
                ),
                const TextSpan(text: ' simgesi ile Komisyon Tutarı hesaplanabilir.\n'),
                const TextSpan(text: '• Komisyon Tutarı girildikten sonra, yanında bulunan '),
                WidgetSpan(
                  child: Icon(Icons.calculate_rounded, size: 16, color: Colors.grey.shade700),
                ),
                const TextSpan(text: ' simgesi ile Komisyon Oranı hesaplanabilir.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kiralayan
        _buildSectionTitle('Kiralayan'),
        const SizedBox(height: 12),
        _buildTenantSearchField(),
        const SizedBox(height: 24),
        
        // Kiralama Değeri
        _buildSectionTitle('Kiralama Değeri'),
        const SizedBox(height: 12),
        _buildRentalValueField(),
        const SizedBox(height: 24),
        
        // Kiraya Veren Komisyon
        _buildSectionTitle('Kiraya Veren Komisyon Oran'),
        const SizedBox(height: 12),
        _buildLessorCommissionFields(),
        const SizedBox(height: 8),
        _buildLessorCommissionAmountField(),
        const SizedBox(height: 8),
        _buildLessorCommissionExcludingVATField(),
        const SizedBox(height: 24),
        
        // Kiracı Komisyon
        _buildSectionTitle('Kiracı Komisyon Oranı'),
        const SizedBox(height: 12),
        _buildTenantCommissionFields(),
        const SizedBox(height: 8),
        _buildTenantCommissionAmountField(),
        const SizedBox(height: 8),
        _buildTenantCommissionExcludingVATField(),
        const SizedBox(height: 24),
        
        // Toplam Komisyon
        _buildSectionTitle('Toplam Komisyon'),
        const SizedBox(height: 12),
        _buildTotalCommissionFields(),
      ],
    );
  }

  Widget _buildTenantSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arama alanı
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _tenantSearchController,
            onChanged: _performTenantSearch,
            onTap: () {
              if (_tenantSearchController.text.isNotEmpty) {
                setState(() {
                  _showTenantSearchResults = true;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Ara',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              suffixIcon: _tenantSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey.shade400,
                      ),
                      onPressed: () {
                        setState(() {
                          _tenantSearchController.clear();
                          _selectedTenant = null;
                          _tenantSearchResults = [];
                          _showTenantSearchResults = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        
        // Arama sonuçları
        if (_showTenantSearchResults)
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: _isSearchingTenant
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    ),
                  )
                : _tenantSearchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _tenantSearchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final contact = _tenantSearchResults[index];
                          final isSelected = _selectedTenant?.contactNo == contact.contactNo;
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectTenant(contact),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFFE53935).withOpacity(0.05)
                                      : Colors.transparent,
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFE53935),
                                      child: contact.picture != null
                                          ? ClipOval(
                                              child: Image.network(
                                                contact.picture!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Text(
                                                    contact.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Text(
                                              contact.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    // İsim ve detaylar
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            contact.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (contact.email.isNotEmpty)
                                            Text(
                                              contact.email,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (contact.typeDescription.isNotEmpty)
                                            Text(
                                              contact.typeDescription,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        
        // Seçili kişi kartı
        if (_selectedTenant != null && !_showTenantSearchResults) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE53935),
                  child: _selectedTenant!.picture != null
                      ? ClipOval(
                          child: Image.network(
                            _selectedTenant!.picture!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                _selectedTenant!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          _selectedTenant!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // İsim ve detaylar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTenant!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_selectedTenant!.email.isNotEmpty)
                        Text(
                          _selectedTenant!.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (_selectedTenant!.typeDescription.isNotEmpty)
                        Text(
                          _selectedTenant!.typeDescription,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade400,
                  onPressed: () {
                    setState(() {
                      _selectedTenant = null;
                      _tenantSearchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _selectTenant(ContactSearchModel contact) {
    setState(() {
      _selectedTenant = contact;
      _tenantSearchController.text = contact.title;
      _showTenantSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _performTenantSearch(String query) {
    _tenantSearchTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _tenantSearchResults = [];
        _isSearchingTenant = false;
        _showTenantSearchResults = false;
      });
      return;
    }
    
    setState(() {
      _showTenantSearchResults = true;
    });
    
    _tenantSearchTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearchingTenant = true;
      });
      
      try {
        // Web'deki gibi: user_contacts=true ve birden fazla type parametresi
        // Kiralayan araması için type=201,202,203,204,205,206 kullanılıyor
        final results = await _contactRepository.searchContacts(
          query: query,
          size: 6,
          userContacts: true,
          types: [201, 202, 203, 204, 205, 206], // Web'deki gibi birden fazla type
        );
        
        if (mounted) {
          setState(() {
            _tenantSearchResults = results;
            _isSearchingTenant = false;
          });
        }
      } catch (e) {
        print('❌ Tenant search error: $e');
        if (mounted) {
          setState(() {
            _tenantSearchResults = [];
            _isSearchingTenant = false;
          });
          
          // Hata mesajını göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Arama hatası: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  Widget _buildRentalValueField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _rentalValueController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TextInputFormatter.withFunction(_formatNumberInput),
        ],
        onChanged: (value) {
          // Otomatik hesaplama
          _calculateCommissions();
          // Eğer komisyon oranları doluysa, onları da güncelle
          if (_lessorCommissionRateController.text.isNotEmpty) {
            _calculateLessorCommissionFromRate();
          }
          if (_tenantCommissionRateController.text.isNotEmpty) {
            _calculateTenantCommissionFromRate();
          }
        },
        decoration: InputDecoration(
          hintText: 'Kiralama değerini giriniz',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.attach_money_rounded,
              color: Color(0xFFE53935),
              size: 20,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildLessorCommissionFields() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _lessorCommissionRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              onChanged: (value) {
                // Otomatik hesaplama
                _calculateLessorCommissionFromRate();
              },
              decoration: InputDecoration(
                hintText: '%0 +KDV',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _calculateLessorCommissionFromRate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Icon(Icons.calculate_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildLessorCommissionAmountField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _lessorCommissionAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction(_formatNumberInput),
              ],
              onChanged: (value) {
                // Otomatik hesaplama
                _calculateLessorCommissionFromAmount();
                _calculateCommissions();
              },
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _calculateLessorCommissionFromAmount,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Icon(Icons.calculate_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildLessorCommissionExcludingVATField() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kiraya Veren Komisyon (KDV\'siz):',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${_formatNumber(_lessorCommissionExcludingVAT, includeDecimals: true)}₺',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTenantCommissionFields() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _tenantCommissionRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              onChanged: (value) {
                // Otomatik hesaplama
                _calculateTenantCommissionFromRate();
              },
              decoration: InputDecoration(
                hintText: '%100 +KDV',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _calculateTenantCommissionFromRate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Icon(Icons.calculate_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildTenantCommissionAmountField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE53935).withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _tenantCommissionAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction(_formatNumberInput),
              ],
              onChanged: (value) {
                // Otomatik hesaplama
                _calculateTenantCommissionFromAmount();
                _calculateCommissions();
              },
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _calculateTenantCommissionFromAmount,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: const Icon(Icons.calculate_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildTenantCommissionExcludingVATField() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Kiracı Komisyon (KDV\'siz):',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${_formatNumber(_tenantCommissionExcludingVAT, includeDecimals: true)}₺',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCommissionFields() {
    return Column(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Toplam Komisyon (KDV Dahil):',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_formatNumber(_totalCommissionIncludingVAT, includeDecimals: true)}₺',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Toplam Komisyon (KDV\'siz):',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_formatNumber(_totalCommissionExcludingVAT, includeDecimals: true)}₺',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Komisyon bilgileri KDV dahil olarak girilmelidir',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _calculateLessorCommissionFromRate() {
    final rentalValue = _parseNumber(_rentalValueController.text);
    if (rentalValue == 0) return;
    
    final rateText = _lessorCommissionRateController.text
        .replaceAll('%', '')
        .replaceAll('+KDV', '')
        .replaceAll(' ', '')
        .trim();
    
    if (rateText.isEmpty) {
      _lessorCommissionAmountController.clear();
      _calculateCommissions();
      return;
    }
    
    // Virgülü noktaya çevir
    final rate = double.tryParse(rateText.replaceAll(',', '.')) ?? 0;
    
    if (rate > 0) {
      final amountIncludingVAT = (rentalValue * rate) / 100;
      _lessorCommissionAmountController.text = _formatNumber(amountIncludingVAT);
      _calculateCommissions();
    } else {
      _lessorCommissionAmountController.clear();
      _calculateCommissions();
    }
  }

  void _calculateLessorCommissionFromAmount() {
    final rentalValue = _parseNumber(_rentalValueController.text);
    if (rentalValue == 0) return;
    
    final amountIncludingVAT = _parseNumber(_lessorCommissionAmountController.text);
    
    if (amountIncludingVAT > 0) {
      final rate = (amountIncludingVAT / rentalValue) * 100;
      _lessorCommissionRateController.text = '%${_formatPercentage(rate)} +KDV';
    } else {
      _lessorCommissionRateController.clear();
    }
  }

  void _calculateTenantCommissionFromRate() {
    final rentalValue = _parseNumber(_rentalValueController.text);
    if (rentalValue == 0) return;
    
    final rateText = _tenantCommissionRateController.text
        .replaceAll('%', '')
        .replaceAll('+KDV', '')
        .replaceAll(' ', '')
        .trim();
    
    if (rateText.isEmpty) {
      _tenantCommissionAmountController.clear();
      _calculateCommissions();
      return;
    }
    
    // Virgülü noktaya çevir
    final rate = double.tryParse(rateText.replaceAll(',', '.')) ?? 0;
    
    if (rate > 0) {
      final amountIncludingVAT = (rentalValue * rate) / 100;
      _tenantCommissionAmountController.text = _formatNumber(amountIncludingVAT);
      _calculateCommissions();
    } else {
      _tenantCommissionAmountController.clear();
      _calculateCommissions();
    }
  }

  void _calculateTenantCommissionFromAmount() {
    final rentalValue = _parseNumber(_rentalValueController.text);
    if (rentalValue == 0) return;
    
    final amountIncludingVAT = _parseNumber(_tenantCommissionAmountController.text);
    
    if (amountIncludingVAT > 0) {
      final rate = (amountIncludingVAT / rentalValue) * 100;
      _tenantCommissionRateController.text = '%${_formatPercentage(rate)} +KDV';
    } else {
      _tenantCommissionRateController.clear();
    }
  }

  void _calculateCommissions() {
    // Kiraya Veren Komisyon (KDV dahil)
    final lessorAmountIncludingVAT = _parseNumber(_lessorCommissionAmountController.text);
    
    // Kiracı Komisyon (KDV dahil)
    final tenantAmountIncludingVAT = _parseNumber(_tenantCommissionAmountController.text);
    
    // KDV hariç hesaplamaları
    _lessorCommissionExcludingVAT = lessorAmountIncludingVAT / (1 + _vatRate);
    _tenantCommissionExcludingVAT = tenantAmountIncludingVAT / (1 + _vatRate);
    
    // Toplam komisyonlar
    _totalCommissionIncludingVAT = lessorAmountIncludingVAT + tenantAmountIncludingVAT;
    _totalCommissionExcludingVAT = _lessorCommissionExcludingVAT + _tenantCommissionExcludingVAT;
    
    setState(() {});
  }

  // Number formatting helpers
  String _formatNumber(double value, {bool includeDecimals = false}) {
    if (includeDecimals) {
      final formatter = NumberFormat('#,##0.00', 'tr_TR');
      return formatter.format(value);
    } else {
      final formatter = NumberFormat('#,##0', 'tr_TR');
      return formatter.format(value);
    }
  }

  double _parseNumber(String input) {
    if (input.isEmpty) return 0;
    // Nokta ve virgülü temizle, sadece sayıları al
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatInputNumber(String value) {
    if (value.isEmpty) return '';
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return '';
    final number = int.tryParse(cleaned) ?? 0;
    return _formatNumber(number.toDouble());
  }

  // Custom TextInputFormatter for number formatting with cursor position preservation
  TextEditingValue _formatNumberInput(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    
    final number = int.tryParse(cleaned) ?? 0;
    final formatted = _formatNumber(number.toDouble());
    
    // Cursor pozisyonunu hesapla - basit yaklaşım
    final oldCleaned = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final oldLength = oldCleaned.length;
    final newLength = cleaned.length;
    
    int offset = formatted.length;
    
    // Eğer karakter eklendiyse veya silindiyse
    if (oldLength != newLength) {
      final diff = newLength - oldLength;
      final oldFormatted = oldValue.text.isEmpty ? '' : _formatInputNumber(oldValue.text);
      final oldFormattedLength = oldFormatted.length;
      
      // Cursor pozisyonunu tahmin et
      if (diff > 0) {
        // Karakter eklendi - cursor'ı sona yakın tut
        offset = formatted.length;
      } else {
        // Karakter silindi - cursor'ı başa yakın tut
        offset = (oldFormattedLength + diff).clamp(0, formatted.length);
      }
    } else {
      // Aynı uzunluk - cursor pozisyonunu koru
      offset = newValue.selection.baseOffset.clamp(0, formatted.length);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  String _formatPercentage(double value) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return formatter.format(value);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFE53935),
                const Color(0xFFE53935).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildListingDropdown() {
    return GestureDetector(
      onTap: _showListingPicker,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedListing != null
                      ? _getListingDisplayText(_selectedListing!)
                      : 'Kapatmak istediğiniz ilanı seçiniz',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _selectedListing != null 
                        ? const Color(0xFF1F2937) 
                        : Colors.grey.shade400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

