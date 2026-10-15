import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:zecorner/presentation/screens/list/listings_screen.dart';
import '../../../core/utils/image_utils.dart';
import '../../../models/list/media_model.dart';
import '../../../models/list/property_model.dart' as list_property;
import '../../../models/list/listing_panel_model.dart';
import '../../../infrastructure/list/listing_update_service.dart';
import '../../../models/list/listing_update_request.dart';
import '../../../core/error/failures.dart';
import '../../../infrastructure/contact/contact_search_repository.dart';
import '../../../models/contact/contact_search_model.dart';

// Editable listing model that extends from ListingsScreen
class EditableListing {
  final String id;
  final String title;
  final String location;
  final String district;
  final String neighborhood;
  final String price;
  final String type;
  final String status;
  final String consultant;
  final String area;
  final String rooms;
  final String description;
  final String currency;
  final String imageUrl;
  final String calender;
  final int viewCount;
  final bool isActive;
  final bool internal; // Internal property
  final String? coverPicture; // API'den gelen cover picture
  final String? picture; // API'den gelen picture
  final List<MediaModel> medias; // Medias listesi
  final Map<String, list_property.PropertyModel> properties; // Properties map

  EditableListing({
    required this.id,
    required this.title,
    required this.location,
    required this.district,
    required this.neighborhood,
    required this.price,
    required this.type,
    required this.status,
    required this.consultant,
    required this.area,
    required this.rooms,
    required this.description,
    required this.currency,
    required this.imageUrl,
    required this.calender,
    required this.viewCount,
    required this.isActive,
    required this.internal,
    this.coverPicture,
    this.picture,
    required this.medias,
    required this.properties,
  });

  // Convert from Listing to EditableListing
  factory EditableListing.fromListing(Listing listing) {
    return EditableListing(
      id: listing.id,
      title: listing.title,
      location: listing.location,
      district: listing.district,
      neighborhood: listing.neighborhood,
      price: listing.price.replaceAll('₺', '').replaceAll('.', ''),
      type: listing.type,
      status: listing.status,
      consultant: listing.consultant,
      area: listing.area,
      rooms: listing.rooms,
      description: 'Detaylı açıklama burada yer alacak...', // Default description
      currency: 'TL',
      imageUrl: listing.imageUrl,
      calender: listing.calender,
      viewCount: listing.viewCount,
      isActive: listing.isActive,
      internal: false, // Default value
      coverPicture: listing.coverPicture,
      picture: listing.picture,
      medias: listing.medias,
      properties: {}, // Default empty properties map
    );
  }

  // Convert from ListingPanelModel to EditableListing
  factory EditableListing.fromListingPanelModel(ListingPanelModel listing) {
    return EditableListing(
      id: listing.id,
      title: listing.title,
      location: listing.provinceName,
      district: listing.districtName,
      neighborhood: listing.quarterName,
      price: listing.price.toString(),
      type: listing.type,
      status: listing.displayState,
      consultant: listing.contactTitle,
      area: listing.area,
      rooms: listing.rooms,
      description: 'Detaylı açıklama burada yer alacak...', // Default description
      currency: listing.currency,
      imageUrl: listing.imageUrl,
      calender: listing.formattedDate,
      viewCount: listing.viewCount,
      isActive: listing.state == 'LIVE',
      internal: listing.internal,
      coverPicture: listing.coverPicture,
      picture: listing.picture,
      medias: listing.medias,
      properties: listing.properties.map((key, value) => MapEntry(key, value as list_property.PropertyModel)),
    );
  }

  // Convert to Listing for updating state
  Listing toListing() {
    return Listing(
      id: id,
      title: title,
      location: location,
      district: district,
      neighborhood: neighborhood,
      price: _formatPrice(price, currency),
      calender: calender,
      type: type,
      status: status,
      consultant: consultant,
      area: area,
      rooms: rooms,
      viewCount: viewCount,
      imageUrl: imageUrl,
      isActive: isActive,
      coverPicture: coverPicture,
      picture: picture,
      medias: medias,
    );
  }

  String _formatPrice(String price, String currency) {
    // Simple price formatting
    try {
      final numPrice = double.parse(price);
      if (currency == 'TL') {
        return '₺${numPrice.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            )}';
      } else {
        return '$currency ${numPrice.toStringAsFixed(0)}';
      }
    } catch (e) {
      return '₺$price';
    }
  }
}

class EditListingScreen extends StatefulWidget {
  final String? listingId;
  final Listing? listing; // Direct listing data
  final Function(Listing)? onListingUpdated; // Callback for updates
  final Function(String)? onListingDeleted; // Callback for deletions

  const EditListingScreen({
    super.key, 
    this.listingId,
    this.listing,
    this.onListingUpdated,
    this.onListingDeleted,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedListingType = '';
  String _selectedCurrency = '';
  String _selectedStatus = '';
  bool _isLoading = true;
  bool _isSaving = false;
  EditableListing? _currentListing;
  bool _hasChanges = false;
  int selectedIndex = 0; // Fotoğraf seçimi için
  late PageController _pageController; // PageView controller

  // API service
  final ListingUpdateService _listingUpdateService = ListingUpdateService();
  List<ListingState> _listingStates = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadListingData();

    // Add listeners to detect changes
    _titleController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _loadListingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // If listing data is provided directly, use it
      if (widget.listing != null) {
        _currentListing = EditableListing.fromListing(widget.listing!);
        await _loadListingStates();
        _populateFields();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Otherwise, fetch from API
      if (widget.listingId != null) {
        final result = await _listingUpdateService.getListingDetail(widget.listingId!);
        
        result.fold(
          (failure) {
            _showErrorSnackBar(_getFailureMessage(failure));
            setState(() {
              _isLoading = false;
            });
          },
          (listing) async {
            _currentListing = EditableListing.fromListingPanelModel(listing);
            await _loadListingStates();
            _populateFields();
            setState(() {
              _isLoading = false;
            });
          },
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading listing data: $e');
      _showErrorSnackBar('Veri yüklenirken hata oluştu: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadListingStates() async {
    try {
      final result = await _listingUpdateService.getListingStates();
      result.fold(
        (failure) {
          print('❌ Error loading listing states: ${_getFailureMessage(failure)}');
          // Use default states if API fails
          _listingStates = [
            ListingState(id: '1', name: 'Yayında', code: 'LIVE', description: 'Yayında'),
            ListingState(id: '2', name: 'Taslak', code: 'DRAFT', description: 'Taslak'),
            ListingState(id: '3', name: 'Onay Bekliyor', code: 'PENDING', description: 'Onay Bekliyor'),
            ListingState(id: '4', name: 'Kiralandı', code: 'RENTED', description: 'Kiralandı'),
            ListingState(id: '5', name: 'Satıldı', code: 'SOLD', description: 'Satıldı'),
            ListingState(id: '6', name: 'İptal', code: 'CANCELLED', description: 'İptal'),
            ListingState(id: '7', name: 'Süresi Doldu', code: 'EXPIRED', description: 'Süresi Doldu'),
          ];
        },
        (states) {
          _listingStates = states;
        },
      );
    } catch (e) {
      print('❌ Error loading listing states: $e');
      // Use default states
      _listingStates = [
        ListingState(id: '1', name: 'Yayında', code: 'LIVE', description: 'Yayında'),
        ListingState(id: '2', name: 'Taslak', code: 'DRAFT', description: 'Taslak'),
        ListingState(id: '3', name: 'Onay Bekliyor', code: 'PENDING', description: 'Onay Bekliyor'),
        ListingState(id: '4', name: 'Kiralandı', code: 'RENTED', description: 'Kiralandı'),
        ListingState(id: '5', name: 'Satıldı', code: 'SOLD', description: 'Satıldı'),
        ListingState(id: '6', name: 'İptal', code: 'CANCELLED', description: 'İptal'),
        ListingState(id: '7', name: 'Süresi Doldu', code: 'EXPIRED', description: 'Süresi Doldu'),
      ];
    }
  }

  void _populateFields() {
    if (_currentListing != null) {
      _titleController.text = _currentListing!.title;
      _priceController.text = _currentListing!.price;
      _descriptionController.text = _currentListing!.description;
      
      // Map API type to display type
      if (_currentListing!.type.toLowerCase() == 'kiralik') {
        _selectedListingType = 'Kiralık';
      } else if (_currentListing!.type.toLowerCase() == 'satilik') {
        _selectedListingType = 'Satılık';
      } else {
        _selectedListingType = 'Satılık'; // default
      }
      
      _selectedCurrency = _currentListing!.currency;
      _selectedStatus = _currentListing!.status;
      
      // Debug: Print coverPicture ID and ImageUtils info
      print('🔍 CoverPicture ID: ${_currentListing!.coverPicture}');
      print('🔍 ImageUrl: ${_currentListing!.imageUrl}');
      print('🔍 Medias count: ${_currentListing!.medias.length}');
      if (_currentListing!.coverPicture != null) {
        print('🔍 ImageUtils.isValidS3Id: ${ImageUtils.isValidS3Id(_currentListing!.coverPicture)}');
        print('🔍 ImageUtils.getCoverImageUrl: ${ImageUtils.getCoverImageUrl(_currentListing!.coverPicture)}');
      }
      if (_currentListing!.medias.isNotEmpty) {
        print('🔍 === MEDIAS DETAYLARI ===');
        for (int i = 0; i < _currentListing!.medias.length; i++) {
          var media = _currentListing!.medias[i];
          print('🔍   [$i] Type: ${media.type}, Cover: ${media.isCover}, Standard: ${media.standart}');
          if (ImageUtils.isValidS3Id(media.standart)) {
            print('🔍   [$i] URL: ${ImageUtils.getCoverImageUrl(media.standart)}');
          }
        }
        print('🔍 === MEDIAS SON ===');
      } else {
        print('⚠️ HİÇ MEDIAS YOK!');
      }
      
      // Test _getImagesList() fonksiyonunu çağır
      final testImages = _getImagesList();
      print('🧪 Test _getImagesList() sonucu: ${testImages.length} resim');
      for (int i = 0; i < testImages.length; i++) {
        print('🧪   [$i] ${testImages[i]}');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveListing() async {
    if (_currentListing == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create properties list for API
      final properties = _currentListing!.properties.values
          .map((prop) => PropertyUpdateModel.fromPropertyModel(prop))
          .toList();

      // Map display type to API type
      String apiType = 'satilik'; // default
      if (_selectedListingType == 'Kiralık') {
        apiType = 'kiralik';
      } else if (_selectedListingType == 'Satılık') {
        apiType = 'satilik';
      }
      
      // Create update request
      final updateRequest = ListingUpdateRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0,
        currency: _selectedCurrency,
        type: apiType,
        internal: _currentListing!.internal,
        properties: properties,
      );

      // Update listing via API
      final result = await _listingUpdateService.updateListing(
        _currentListing!.id,
        updateRequest,
      );

      result.fold(
        (failure) {
          _showErrorSnackBar(_getFailureMessage(failure));
          setState(() {
            _isSaving = false;
          });
        },
        (response) {
          if (response.success) {
            // Update local listing
            final updatedListing = EditableListing(
              id: _currentListing!.id,
              title: _titleController.text,
              location: _currentListing!.location,
              district: _currentListing!.district,
              neighborhood: _currentListing!.neighborhood,
              price: _priceController.text,
              type: _selectedListingType,
              status: _selectedStatus,
              consultant: _currentListing!.consultant,
              area: _currentListing!.area,
              rooms: _currentListing!.rooms,
              description: _descriptionController.text,
              currency: _selectedCurrency,
              imageUrl: _currentListing!.imageUrl,
              calender: _currentListing!.calender,
              viewCount: _currentListing!.viewCount,
              isActive: _currentListing!.isActive,
              internal: _currentListing!.internal,
              coverPicture: _currentListing!.coverPicture,
              picture: _currentListing!.picture,
              medias: _currentListing!.medias,
              properties: _currentListing!.properties,
            );

            // Call callback if provided
            if (widget.onListingUpdated != null) {
              widget.onListingUpdated!(updatedListing.toListing());
            }

            setState(() {
              _isSaving = false;
            });
            
            // Success message and navigate back to listings screen
            _showSuccessSnackBar('İlan başarıyla güncellendi');
            
            // Wait for snackbar to show, then navigate to listings screen
            Future.delayed(const Duration(milliseconds: 500), () {
              // Pop back to listings screen (remove all intermediate screens)
              Navigator.of(context).pushNamedAndRemoveUntil(
                'listings',
                (route) => route.settings.name == 'home' || route.isFirst,
              );
            });
          } else {
            _showErrorSnackBar(response.message);
            setState(() {
              _isSaving = false;
            });
          }
        },
      );
    } catch (e) {
      print('❌ Error saving listing: $e');
      _showErrorSnackBar('İlan kaydedilirken hata oluştu: $e');
      setState(() {
        _isSaving = false;
      });
    }
  }


  String _getFailureMessage(Failure failure) {
    if (failure is AuthFailure) {
      return 'Oturum hatası: ${failure.message}';
    } else if (failure is ServerFailure) {
      return 'Sunucu hatası: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Ağ hatası: ${failure.message}';
    } else {
      return 'Hata: ${failure.message}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Fiyatı düzgün formatlayarak gösterir (örn: "2.000.000 TL")
  String _formatDisplayPrice(String priceStr, String currency) {
    // Önce string'den sadece sayıları al
    String digitsOnly = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return priceStr; // Eğer sayı yoksa orijinal string'i döndür
    }
    
    // String'i integer'a çevir
    int? price = int.tryParse(digitsOnly);
    
    if (price == null) {
      return priceStr; // Parse edilemezse orijinal string'i döndür
    }
    
    // NumberFormat ile formatla (Türkçe binlik ayırıcı: nokta)
    final formatter = NumberFormat('#,###', 'tr_TR');
    String formatted = formatter.format(price);
    
    // Para birimi ekle
    return '$formatted $currency';
  }

  /// Özet/Onay Dialogu - İlan kapatma öncesi son onay
  void _showClosingConfirmationDialog({
    required BuildContext context,
    required String closeType,
    required double closingPrice,
    required double sellerCommissionWithKDV,
    required double sellerCommissionNoKDV,
    required double buyerCommissionWithKDV,
    required double buyerCommissionNoKDV,
  }) {
    final totalCommissionWithKDV = sellerCommissionWithKDV + buyerCommissionWithKDV;
    final totalCommissionNoKDV = sellerCommissionNoKDV + buyerCommissionNoKDV;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Uyarı
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE53935).withOpacity(0.1),
                        const Color(0xFFF44336).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFE53935),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bu işlem geri alınamaz.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Onaylıyor musunuz?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content - Özet Bilgiler
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (closeType == 'Satıldı') ...[
                          // İlan Fiyatı
                          _buildSummaryRow(
                            'İlan Fiyatı',
                            '${_formatNumberWithDecimal(closingPrice)}₺',
                            isHighlight: true,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Divider
                          Divider(color: Colors.grey[300], thickness: 1),
                          
                          const SizedBox(height: 20),
                          
                          // Alıcı Komisyon
                          Text(
                            'Alıcı Komisyon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'KDV Dahil',
                            '${_formatNumberWithDecimal(buyerCommissionWithKDV)}₺',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'KDV\'siz',
                            '${_formatNumberWithDecimal(buyerCommissionNoKDV)}₺',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Satıcı Komisyon
                          Text(
                            'Satıcı Komisyon',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'KDV Dahil',
                            '${_formatNumberWithDecimal(sellerCommissionWithKDV)}₺',
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'KDV\'siz',
                            '${_formatNumberWithDecimal(sellerCommissionNoKDV)}₺',
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Divider - Kalınzw
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[400]!,
                                  Colors.grey[300]!,
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Toplam Komisyon
                          Text(
                            'Toplam Komisyon',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow(
                            'KDV Dahil',
                            '${_formatNumberWithDecimal(totalCommissionWithKDV)}₺',
                            isHighlight: true,
                            highlightColor: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'KDV\'siz',
                            '${_formatNumberWithDecimal(totalCommissionNoKDV)}₺',
                            isHighlight: true,
                            highlightColor: Colors.grey[700]!,
                          ),
                        ] else ...[
                          // Sadece kapanış tipi bilgisi
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 48,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'İlan "$closeType" olarak kapatılacaktır.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Footer - Butonlar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.pop(context); // Ana modalı da kapat
                            
                            // TODO: API entegrasyonu
                            _showSuccessSnackBar('İlan kapatma işlemi için API entegrasyonu bekleniyor');
                            
                            // API hazır olduğunda burası kullanılacak:
                            // final closeData = {
                            //   'closeType': closeType,
                            //   'closingPrice': closingPrice,
                            //   'sellerCommissionWithKDV': sellerCommissionWithKDV,
                            //   'buyerCommissionWithKDV': buyerCommissionWithKDV,
                            // };
                            // await _closeListingWithAPI(closeData);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shadowColor: const Color(0xFFE53935).withOpacity(0.3),
                          ),
                          child: const Text(
                            'Onayla',
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Özet satırı widget builder
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight 
            ? (highlightColor ?? const Color(0xFFE53935)).withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isHighlight
            ? Border.all(
                color: (highlightColor ?? const Color(0xFFE53935)).withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 15 : 14,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
              color: isHighlight 
                  ? Colors.grey[900]
                  : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight 
                  ? (highlightColor ?? const Color(0xFFE53935))
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Sayı formatlaması - Web'deki gibi (nokta binlik, virgül ondalık)
  String _formatNumberWithDecimal(double value) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return formatter.format(value);
  }
  
  /// Sayı formatlaması - Sadece binlik ayırıcı (ondalık yok)
  String _formatNumberWithoutDecimal(double value) {
    final formatter = NumberFormat('#,##0', 'tr_TR');
    return formatter.format(value);
  }
  
  /// Input'tan sayıyı parse et (nokta ve virgülü temizle)
  double _parseNumberFromInput(String input) {
    if (input.isEmpty) return 0;
    // Nokta ve virgülü temizle, sadece sayıları al
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
  
  /// Input'a sayı formatı uygula (nokta binlik ayırıcı)
  String _formatInputNumber(String value) {
    if (value.isEmpty) return '';
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return '';
    final number = int.tryParse(cleaned) ?? 0;
    return _formatNumberWithoutDecimal(number.toDouble());
  }

  /// İlan Kapat Modal'ı göster - Web tasarımı ile aynı (Dinamik Alanlar)
  void _showCloseListingModal(BuildContext context) {
    // İlan fiyatını al ve formatla
    String initialPrice = '0';
    if (_currentListing != null && _currentListing!.price.isNotEmpty) {
      // Fiyat string'inden sadece sayıları al
      String priceDigits = _currentListing!.price.replaceAll(RegExp(r'[^\d]'), '');
      if (priceDigits.isNotEmpty) {
        int? priceValue = int.tryParse(priceDigits);
        if (priceValue != null && priceValue > 0) {
          // Formatlanmış şekilde set et
          initialPrice = _formatNumberWithoutDecimal(priceValue.toDouble());
        }
      }
    }
    
    // Modal için state değişkenleri - StatefulBuilder dışında tutuluyor
    String selectedCloseType = 'Süresi Dolmuş';
    final TextEditingController sellerCommissionRateController = TextEditingController(text: '2');
    final TextEditingController buyerCommissionRateController = TextEditingController(text: '2');
    final TextEditingController closingPriceController = TextEditingController(text: initialPrice);
    
    // Contact arama için controller ve repository - Modal dışında tutuluyor
    final ContactSearchRepository contactRepository = ContactSearchRepository();
    final TextEditingController buyerSearchController = TextEditingController();
    Timer? buyerSearchTimer;
    
    // Contact arama state değişkenleri - StatefulBuilder dışında tutuluyor
    ContactSearchModel? selectedBuyer;
    List<ContactSearchModel> buyerSearchResults = [];
    bool isSearchingBuyer = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // Komisyon hesaplamaları - Input'lardan parse et
            double sellerRate = _parseNumberFromInput(sellerCommissionRateController.text);
            double buyerRate = _parseNumberFromInput(buyerCommissionRateController.text);
            double closingPrice = _parseNumberFromInput(closingPriceController.text);
            
            // Hesaplamalar - Web'deki mantık ile aynı
            double sellerCommissionWithKDV = (closingPrice * sellerRate / 100) * 1.20;
            double sellerCommissionNoKDV = closingPrice * sellerRate / 100;
            double buyerCommissionWithKDV = (closingPrice * buyerRate / 100) * 1.20;
            double buyerCommissionNoKDV = closingPrice * buyerRate / 100;
            
            // Hesaplama fonksiyonu
            void calculateCommissions() {
              if (context.mounted) {
                setModalState(() {
                  // setModalState içinde hesaplamalar otomatik güncellenir
                });
              }
            }
            
            // Buyer arama fonksiyonu
            void performBuyerSearch(String query) {
              if (!context.mounted) return;
              
              buyerSearchTimer?.cancel();
              
              if (query.isEmpty) {
                buyerSearchResults = [];
                isSearchingBuyer = false;
                if (context.mounted) {
                  setModalState(() {});
                }
                return;
              }
              
              buyerSearchTimer = Timer(const Duration(milliseconds: 500), () async {
                if (!context.mounted) return;
                
                isSearchingBuyer = true;
                if (context.mounted) {
                  setModalState(() {});
                }
                
                try {
                  final results = await contactRepository.searchContacts(
                    query: query,
                    size: 10,
                    type: '',
                  );
                  
                  if (!context.mounted) return;
                  
                  buyerSearchResults = results;
                  isSearchingBuyer = false;
                  if (context.mounted) {
                    setModalState(() {});
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  
                  buyerSearchResults = [];
                  isSearchingBuyer = false;
                  if (context.mounted) {
                    setModalState(() {});
                  }
                }
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'İlan Kapat',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Alıcı Müşterimm Card
                          const Text(
                            'Alıcı Müşterimm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'AM',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Müşteri Bilgisi
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alıcı Müşterimm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mülk Sahibi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 28),
                          
                          // Kapanış Tipi
                          const Text(
                            'Kapanış Tipi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE53935),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              value: selectedCloseType,
                              items: [
                                'Süresi Dolmuş',
                                'Satıldı',
                                'İptal Edildi',
                              ].map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  selectedCloseType = value ?? 'Süresi Dolmuş';
                                });
                              },
                            ),
                          ),
                          
                          // Dinamik alanlar - Kapanış tipine göre
                          if (selectedCloseType == 'Satıldı') ...[
                            const SizedBox(height: 28),
                            
                            // Alıcı Arama Kutusu
                            const Text(
                              'Alıcı',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: buyerSearchController,
                              onChanged: (value) {
                                performBuyerSearch(value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Kişi no ya da isim ile arayınız.',
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.search, color: Color(0xFFE53935)),
                                suffixIcon: buyerSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          buyerSearchController.clear();
                                          buyerSearchResults = [];
                                          selectedBuyer = null;
                                          setModalState(() {});
                                          performBuyerSearch('');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE53935),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            
                            // Arama sonuçları
                            if (buyerSearchController.text.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: isSearchingBuyer
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFE53935),
                                          ),
                                        ),
                                      )
                                    : buyerSearchResults.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.search_off,
                                                    color: Colors.grey,
                                                    size: 48,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Sonuç bulunamadı',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Farklı bir arama terimi deneyin',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              // Sonuç sayısı
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: const BorderRadius.only(
                                                    topLeft: Radius.circular(12),
                                                    topRight: Radius.circular(12),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.people,
                                                      color: Colors.grey[600],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${buyerSearchResults.length} kişi bulundu',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Sonuç listesi
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: buyerSearchResults.length,
                                                itemBuilder: (context, index) {
                                                  final contact = buyerSearchResults[index];
                                                  final isSelected = selectedBuyer?.contactNo == contact.contactNo;
                                                  
                                                  return InkWell(
                                                    onTap: () {
                                                      selectedBuyer = contact;
                                                      buyerSearchController.text = contact.title;
                                                      buyerSearchResults = [];
                                                      setModalState(() {});
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: isSelected ? const Color(0xFFFFEBEE) : Colors.white,
                                                        border: index < buyerSearchResults.length - 1 
                                                            ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                                                            : null,
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
                                                                Text(
                                                                  contact.typeDescription,
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (isSelected)
                                                            Container(
                                                              padding: const EdgeInsets.all(4),
                                                              decoration: const BoxDecoration(
                                                                color: Color(0xFFE53935),
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons.check,
                                                                color: Colors.white,
                                                                size: 16,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                              ),
                            
                            // Seçilen kişi gösterimi
                            if (selectedBuyer != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE53935), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE53935).withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: const Color(0xFFE53935),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Seçilen Alıcı",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFFE53935),
                                          ),
                                        ),
                                        const Spacer(),
                                        InkWell(
                                          onTap: () {
                                            selectedBuyer = null;
                                            buyerSearchController.clear();
                                            setModalState(() {});
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Color(0xFFE53935),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: const Color(0xFFE53935),
                                          child: selectedBuyer!.picture != null
                                              ? ClipOval(
                                                  child: Image.network(
                                                    selectedBuyer!.picture!,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Text(
                                                        selectedBuyer!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
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
                                                  selectedBuyer!.title.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedBuyer!.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Color(0xFFE53935),
                                                ),
                                              ),
                                              if (selectedBuyer!.email.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.email,
                                                        color: Colors.grey[600],
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        selectedBuyer!.email,
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.work,
                                                      color: Colors.grey[600],
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      selectedBuyer!.typeDescription,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
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
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 28),
                            
                            // Satış Değeri
                            const Text(
                              'Satış Değeri',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: closingPriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                if (!context.mounted) return;
                                // Formatla ve güncelle
                                final formatted = _formatInputNumber(value);
                                if (formatted != value) {
                                  closingPriceController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                                if (context.mounted) {
                                  setModalState(() {});
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE53935),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 28),
                            
                            // Satıcı Komisyon Oranı
                            const Text(
                              'Satıcı Komisyon Oranı',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: sellerCommissionRateController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (context.mounted) {
                                        setModalState(() {});
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: '%2 +KDV',
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixText: '% +KDV',
                                      suffixStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE53935),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    calculateCommissions();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Hesapla',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Satıcı Komisyon
                            const Text(
                              'Satıcı Komisyon',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatNumberWithoutDecimal(sellerCommissionWithKDV),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          calculateCommissions();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53935),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Hesapla',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // KDV dahil olmayan uyarısı
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[700], size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Komisyon bilgileri KDV dahil olarak girilmelidir',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Satıcı Komisyonu (KDV'siz)
                            const Text(
                              'Satıcı Komisyonu (KDV\'siz)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_formatNumberWithDecimal(sellerCommissionNoKDV)}₺',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 28),
                            
                            // Alıcı Komisyon Oranı
                            const Text(
                              'Alıcı Komisyon Oranı',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: buyerCommissionRateController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (context.mounted) {
                                        setModalState(() {});
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: '%2 +KDV',
                                      filled: true,
                                      fillColor: Colors.white,
                                      suffixText: '% +KDV',
                                      suffixStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE53935),
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    calculateCommissions();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Hesapla',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Alıcı Komisyon
                            const Text(
                              'Alıcı Komisyon',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatNumberWithDecimal(buyerCommissionWithKDV),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          calculateCommissions();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53935),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Hesapla',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // KDV dahil olmayan uyarısı
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[700], size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Komisyon bilgileri KDV dahil olarak girilmelidir',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Alıcı Komisyonu (KDV'siz)
                            const Text(
                              'Alıcı Komisyonu (KDV\'siz)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_formatNumberWithDecimal(buyerCommissionNoKDV)}₺',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 28),
                            
                            // Toplam Komisyon (KDV Dahil)
                            const Text(
                              'Toplam Komisyon (KDV Dahil)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_formatNumberWithDecimal(sellerCommissionWithKDV + buyerCommissionWithKDV)}₺',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Toplam Komisyon (KDV'siz)
                            const Text(
                              'Toplam Komisyon (KDV\'siz)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_formatNumberWithDecimal(sellerCommissionNoKDV + buyerCommissionNoKDV)}₺',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom Button - Tek büyük buton
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Sadece "Satıldı" ise özet göster
                          if (selectedCloseType == 'Satıldı') {
                            Navigator.pop(context);
                            _showClosingConfirmationDialog(
                              context: context,
                              closeType: selectedCloseType,
                              closingPrice: double.tryParse(closingPriceController.text) ?? 0,
                              sellerCommissionWithKDV: sellerCommissionWithKDV,
                              sellerCommissionNoKDV: sellerCommissionNoKDV,
                              buyerCommissionWithKDV: buyerCommissionWithKDV,
                              buyerCommissionNoKDV: buyerCommissionNoKDV,
                            );
                          } else {
                            // Diğer tipler için direkt kapat
                            Navigator.pop(context);
                            _showClosingConfirmationDialog(
                              context: context,
                              closeType: selectedCloseType,
                              closingPrice: 0,
                              sellerCommissionWithKDV: 0,
                              sellerCommissionNoKDV: 0,
                              buyerCommissionWithKDV: 0,
                              buyerCommissionNoKDV: 0,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                        ),
                        child: const Text(
                          'İlanı Kapat',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Modal kapandığında timer ve controller'ları güvenli bir şekilde temizle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          buyerSearchTimer?.cancel();
          buyerSearchTimer = null;
        } catch (e) {
          // Timer zaten iptal edilmiş olabilir
        }
        
        try {
          buyerSearchController.dispose();
        } catch (e) {
          // Controller zaten dispose edilmiş olabilir
        }
        
        try {
          sellerCommissionRateController.dispose();
        } catch (e) {
          // Controller zaten dispose edilmiş olabilir
        }
        
        try {
          buyerCommissionRateController.dispose();
        } catch (e) {
          // Controller zaten dispose edilmiş olabilir
        }
        
        try {
          closingPriceController.dispose();
        } catch (e) {
          // Controller zaten dispose edilmiş olabilir
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "İlan Düzenle",
            style: TextStyle(
              color: Color.fromRGBO(238, 46, 36, 1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE53935),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "İlan Düzenle",
          style: TextStyle(
            color: Color.fromRGBO(238, 46, 36, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Taslak',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          // Sadece "Yayında" olan ilanlar için "İlanı Kapat" butonu göster
          if (_currentListing != null && _currentListing!.status == 'Yayında')
            TextButton(
              onPressed: _isSaving ? null : () {
                // İlan Kapat Modal
                _showCloseListingModal(context);
              },
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'İlanı Kapat',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Listing Info Card
            if (_currentListing != null)
              // Container(
              //   margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE53935).withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(12),
              //     border: Border.all(
              //       color: const Color(0xFFE53935).withOpacity(0.3),
              //       width: 1,
              //     ),
              //   ),
              //   child: Row(
              //     children: [
              //       ClipRRect(
              //         borderRadius: BorderRadius.circular(8),
              //         child: Image.network(
              //           _currentListing!.imageUrl,
              //           width: 80,
              //           height: 60,
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //       const SizedBox(width: 12),
              //       Expanded(
              //         child: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             Text(
              //               'Düzenlenen İlan',
              //               style: TextStyle(
              //                 color: const Color(0xFFE53935),
              //                 fontSize: 12,
              //                 fontWeight: FontWeight.w600,
              //               ),
              //             ),
              //             const SizedBox(height: 4),
              //             Text(
              //               _currentListing!.title,
              //               style: const TextStyle(
              //                 fontWeight: FontWeight.w600,
              //                 fontSize: 14,
              //               ),
              //               maxLines: 1,
              //               overflow: TextOverflow.ellipsis,
              //             ),
              //             Text(
              //               '${_currentListing!.location} / ${_currentListing!.district}',
              //               style: TextStyle(
              //                 color: Colors.grey[600],
              //                 fontSize: 12,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Container(
              //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              //         decoration: BoxDecoration(
              //           color: _getStatusColor(_currentListing!.status),
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //         child: Text(
              //           _currentListing!.status,
              //           style: const TextStyle(
              //             color: Colors.white,
              //             fontSize: 11,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

            // Form Container
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İlan Başlığı
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "İlan Başlığı",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          onChanged: (value) {
                            setState(() => _hasChanges = true);
                          },
                          decoration: InputDecoration(
                            hintText: "İlan başlığını girin",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFE53935),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // İlan Durumu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "İlan Durumu",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            value: _selectedStatus.isNotEmpty &&
                                    _listingStates.any((state) => state.name == _selectedStatus)
                                ? _selectedStatus : null,
                            items: _listingStates
                                .map((state) => DropdownMenuItem(
                                      value: state.name,
                                      child: Text(state.name),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _selectedStatus = value ?? '';
                                  _hasChanges = true;
                                });
                              }
                            },
                            hint: const Text("İlan Durumu Seçin"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // İlan Tipi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "İlan Tipi",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            value: _selectedListingType.isNotEmpty &&
                                    ["Satılık", "Kiralık", ].contains(_selectedListingType)
                                ? _selectedListingType : null,
                            items: ["Satılık", "Kiralık", ]
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (mounted) {
                                setState(() {
                                  _selectedListingType = value ?? '';
                                  _hasChanges = true;
                                });
                              }
                            },
                            hint: const Text("İlan Tipi Seçin"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Fiyat ve Para Birimi
                    Row(
                      children: [
                        // Para Birimi
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Para Birimi",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<String>(
                                  dropdownColor: Colors.white,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE53935),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  value: _selectedCurrency.isNotEmpty &&
                                          ["TL", "USD", "EUR"].contains(_selectedCurrency)
                                      ? _selectedCurrency : null,
                                  items: ["TL", "USD", "EUR"]
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedCurrency = value ?? '';
                                        _hasChanges = true;
                                      });
                                    }
                                  },
                                  hint: const Text("Para Birimi"),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Fiyat
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Fiyat",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Fiyat girin",
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE53935),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // İlan Açıklaması
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "İlan Açıklaması",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: "İlan açıklamasını girin...",
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE53935),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE53935)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "İptal",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : () async {
                              // Değişiklik yapılmamış kontrolü
                              if (!_hasChanges) {
                                _showErrorSnackBar('Lütfen önce bir değişiklik yapın!');
                                return;
                              }

                              // Validation
                              if (_titleController.text.isEmpty) {
                                _showErrorSnackBar('Lütfen ilan başlığını girin');
                                return;
                              }

                              if (_priceController.text.isEmpty) {
                                _showErrorSnackBar('Lütfen fiyat girin');
                                return;
                              }

                              if (_selectedCurrency.isEmpty) {
                                _showErrorSnackBar('Lütfen para birimi seçin');
                                return;
                              }

                              if (_selectedStatus.isEmpty) {
                                _showErrorSnackBar('Lütfen ilan durumu seçin');
                                return;
                              }

                              // Save changes
                              await _saveListing();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (_hasChanges && !_isSaving) ? const Color(0xFFE53935) : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Güncelle",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // İlan Önizleme Bölümü - ilan_detail_screen.dart tasarımı ile
            if (_currentListing != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Büyük görsel - Tam genişlik (ilan_detail_screen.dart'dan)
                  SizedBox(
                    height: 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _getImagesList().length,
                      onPageChanged: (index) {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => openGallery(index),
                          child: _buildMainImage(_getImagesList()[index]),
                        );
                      },
                    ),
                  ),
                  // Diğer içerik padding ile
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Küçük görseller galerisi
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _getImagesList().length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              print('🖼️ Thumbnail oluşturuluyor: $i / ${_getImagesList().length}');
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = i;
                                  });
                                  _pageController.animateToPage(
                                    i,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: selectedIndex == i
                                            ? Colors.red
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _buildThumbnailImage(_getImagesList()[i]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Başlık ve fiyat
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isNotEmpty ? _titleController.text : 'İlan Başlığı Yok',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _priceController.text.isNotEmpty && _selectedCurrency.isNotEmpty
                                ? _formatDisplayPrice(_priceController.text, _selectedCurrency)
                                : 'Fiyat Belirtilmemiş',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.red[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_currentListing!.location}, ${_currentListing!.district}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 15)
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "İlan No: ${_currentListing!.id}",
                          style: TextStyle(color: Colors.grey[500], fontSize: 13)
                        ),
                        const SizedBox(height: 14),
                        // Satılık etiketi ve öne çıkan bilgiler
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                _selectedStatus.isNotEmpty ? _selectedStatus.toUpperCase() : 'BELİRTİLMEMİŞ',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)
                              ),
                              backgroundColor: Colors.red[600],
                            ),
                            // Row(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     // Beğeni Butonu
                            //     Container(
                            //       decoration: BoxDecoration(
                            //         color: Colors.white,
                            //         borderRadius: BorderRadius.circular(12),
                            //         border: Border.all(
                            //           color: Colors.grey[200]!, 
                            //           width: 1
                            //         ),
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black.withOpacity(0.04),
                            //             blurRadius: 4,
                            //             offset: const Offset(0, 2),
                            //           ),
                            //         ],
                            //       ),
                            //       child: Material(
                            //         color: Colors.transparent,
                            //         child: InkWell(
                            //           borderRadius: BorderRadius.circular(12),
                            //           onTap: () {
                            //             // Beğeni işlemi
                            //           },
                            //           child: Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 12, vertical: 8),
                            //             child: Row(
                            //               mainAxisSize: MainAxisSize.min,
                            //               children: [
                            //                 Icon(
                            //                   Icons.favorite_border,
                            //                   color: Colors.red[600],
                            //                   size: 18,
                            //                 ),
                            //                 const SizedBox(width: 6),
                            //                 Text(
                            //                   "Beğeni",
                            //                   style: TextStyle(
                            //                     color: Colors.red[600],
                            //                     fontSize: 13,
                            //                     fontWeight: FontWeight.w500,
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     const SizedBox(width: 8),
                            //     // Paylaş Butonu
                            //     Container(
                            //       decoration: BoxDecoration(
                            //         color: Colors.white,
                            //         borderRadius: BorderRadius.circular(12),
                            //         border: Border.all(color: Colors.grey[200]!, width: 1),
                            //         boxShadow: [
                            //           BoxShadow(
                            //             color: Colors.black.withOpacity(0.04),
                            //             blurRadius: 4,
                            //             offset: const Offset(0, 2),
                            //           ),
                            //         ],
                            //       ),
                            //       child: Material(
                            //         color: Colors.transparent,
                            //         child: InkWell(
                            //           borderRadius: BorderRadius.circular(12),
                            //           onTap: () {
                            //             // Paylaş işlemi
                            //           },
                            //           child: Padding(
                            //             padding: const EdgeInsets.symmetric(
                            //                 horizontal: 12, vertical: 8),
                            //             child: Row(
                            //               mainAxisSize: MainAxisSize.min,
                            //               children: [
                            //                 Icon(
                            //                   Icons.share,
                            //                   color: Colors.red[600],
                            //                   size: 18,
                            //                 ),
                            //                 const SizedBox(width: 6),
                            //                 Text(
                            //                   "Paylaş",
                            //                   style: TextStyle(
                            //                     color: Colors.red[600],
                            //                     fontSize: 13,
                            //                     fontWeight: FontWeight.w500,
                            //                   ),
                            //                 ),
                            //               ],
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Bilgi tablosu - Tam genişlik
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: _buildTopPropertyWidgets(),
                    ),
                  ),
                  // Devam eden içerik padding ile
                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                  // Genel Özellikler kutusu - Tam genişlik
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Genel Özellikler",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        _OzellikSatiriPreview(icon: Icons.square_foot, label: "m² (Brüt)", value: _currentListing!.area, isBold: true),
                        _OzellikSatiriPreview(icon: Icons.square_foot, label: "m² (Net)", value: (_currentListing!.area.isNotEmpty) ? (int.tryParse(_currentListing!.area) != null ? (int.parse(_currentListing!.area) - 12).toString() : "90") : "90", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.apartment, label: "Bina Yaşı", value: "Zemin Kat", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.meeting_room, label: "Oda Sayısı", value: _currentListing!.rooms, isBold: true),
                        _OzellikSatiriPreview(icon: Icons.meeting_room, label: "Bulunduğu Kat", value: "Zemin Kat", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.format_list_numbered, label: "Kat Sayısı", value: "30 ve üzeri", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.fireplace, label: "Isıtma", value: "Merkezi", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.bathtub, label: "Banyo Sayısı", value: "3", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.balcony, label: "Balkon", value: "Var", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.local_parking, label: "Otopark", value: "Açık Otopark", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.chair, label: "Eşyalı", value: "Hayır", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.money_off, label: "Aidat (TL)", value: "Yok", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.wb_sunny, label: "Cephe", value: "Batı", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.check_circle, label: "Krediye Uygun", value: "Evet", isBold: true),
                        _OzellikSatiriPreview(icon: Icons.assignment_turned_in, label: "Tapu Durumu", value: "Kat Mülkiyeti", isBold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
          ],
        ),
      ),
    );
  }


  // Fotoğraf listesi oluştur - ilan_detail_screen.dart'dan birebir kopyalandı
  List<String> _getImagesList() {
    print('🔄 _getImagesList() çağrıldı');
    if (_currentListing == null) {
      print('⚠️ _currentListing null!');
      return [];
    }
    
    List<String> imageList = [];
    
    // Önce medias listesinden resimler al
    if (_currentListing!.medias.isNotEmpty) {
      print('🖼️ Medias bulundu: ${_currentListing!.medias.length} adet');
      
      // Önce cover resmi bul
      final coverMedia = _currentListing!.medias.firstWhere(
        (media) => media.isCover && media.type == 'image',
        orElse: () => _currentListing!.medias.first,
      );
      
      // Cover resmi ekle
      if (ImageUtils.isValidS3Id(coverMedia.standart)) {
        imageList.add(ImageUtils.getCoverImageUrl(coverMedia.standart!));
        print('🖼️ Cover resim eklendi: ${coverMedia.standart}');
      }
      
      // Diğer resimleri ekle
      for (var media in _currentListing!.medias) {
        if (media.type == 'image' && !media.isCover && ImageUtils.isValidS3Id(media.standart)) {
          imageList.add(ImageUtils.getCoverImageUrl(media.standart!));
          print('🖼️ Resim eklendi: ${media.standart}');
        }
      }
    }
    
    // Fallback: Cover picture var mı?
    if (imageList.isEmpty && _currentListing!.coverPicture != null && ImageUtils.isValidS3Id(_currentListing!.coverPicture)) {
      imageList.add(ImageUtils.getCoverImageUrl(_currentListing!.coverPicture));
      print('🖼️ Fallback cover resim kullanıldı');
    }
    
    // Fallback: Picture var mı?
    if (imageList.isEmpty && _currentListing!.picture != null && ImageUtils.isValidS3Id(_currentListing!.picture)) {
      imageList.add(ImageUtils.getCoverImageUrl(_currentListing!.picture));
      print('🖼️ Fallback picture kullanıldı');
    }
    
    // Eğer sadece 1 resim varsa, farklı resimler oluştur
    if (imageList.length == 1) {
      // Cover picture ve picture'ı ayrı ayrı ekle
      if (_currentListing!.coverPicture != null && 
          ImageUtils.isValidS3Id(_currentListing!.coverPicture) &&
          _currentListing!.coverPicture != _currentListing!.picture) {
        imageList.add(ImageUtils.getCoverImageUrl(_currentListing!.coverPicture));
        print('🖼️ Cover picture eklendi: ${_currentListing!.coverPicture}');
      }
      
      if (_currentListing!.picture != null && 
          ImageUtils.isValidS3Id(_currentListing!.picture) &&
          _currentListing!.picture != _currentListing!.coverPicture) {
        imageList.add(ImageUtils.getCoverImageUrl(_currentListing!.picture));
        print('🖼️ Picture eklendi: ${_currentListing!.picture}');
      }
      
      // Eğer hala az resim varsa, farklı varyasyonlar dene
      if (imageList.length < 3) {
        final baseId = _currentListing!.coverPicture ?? _currentListing!.picture ?? '';
        if (baseId.isNotEmpty) {
          // Farklı varyasyonlar dene
          final variations = [
            '${baseId}_1',
            '${baseId}_2', 
            '${baseId}_3',
            '${baseId}_thumb',
            '${baseId}_small',
          ];
          
          for (var variation in variations) {
            if (imageList.length >= 4) break; // Maksimum 4 resim
            if (ImageUtils.isValidS3Id(variation)) {
              imageList.add(ImageUtils.getCoverImageUrl(variation));
              print('🖼️ Varyasyon resim eklendi: $variation');
            }
          }
        }
      }
    }
    
    // Eğer hiç resim yoksa placeholder ekle
    if (imageList.isEmpty) {
      imageList.add("assets/logo/ilan.png");
      print('🖼️ Placeholder resim kullanıldı');
    }
    
    print('🖼️ Toplam ${imageList.length} resim hazırlandı');
    return imageList;
  }

  
  /// Ana sayfa için resim widget'i - ilan_detail_screen.dart'dan alındı
  Widget _buildMainImage(String imageUrl) {
    // Asset resimse
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 220,
            color: Colors.grey[300],
            child: const Icon(
              Icons.home_outlined,
              size: 60,
              color: Colors.white,
            ),
          );
        },
      );
    }
    
    // Network resimse
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 220,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 220,
          color: Colors.grey[300],
          child: const Icon(
            Icons.home_outlined,
            size: 60,
            color: Colors.white,
          ),
        );
      },
    );
  }

  /// Thumbnail için resim widget'i - ilan_detail_screen.dart'dan alındı
  Widget _buildThumbnailImage(String imageUrl) {
    // Asset resimse
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 70,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.white,
            ),
          );
        },
      );
    }
    
    // Network resimse
    return Image.network(
      imageUrl,
      width: 70,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.image,
            color: Colors.white,
          ),
        );
      },
    );
  }

  /// Gallery için resim widget'i - ilan_detail_screen.dart'dan alındı
  Widget _buildGalleryImage(String imageUrl) {
    // Asset resimse
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 60,
            ),
          );
        },
      );
    }
    
    // Network resimse
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.broken_image,
            color: Colors.white,
            size: 60,
          ),
        );
      },
    );
  }

  /// Galeri açma fonksiyonu - ilan_detail_screen.dart'dan alındı
  void openGallery(int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        PageController controller = PageController(initialPage: initialIndex);
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                PageView.builder(
                  controller: controller,
                  itemCount: _getImagesList().length,
                  itemBuilder: (context, i) => Center(
                    child: InteractiveViewer(
                      child: _buildGalleryImage(_getImagesList()[i]),
                    ),
                  ),
                  onPageChanged: (i) {
                    setState(() {
                      selectedIndex = i;
                    });
                  },
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Üst kısım için property widget'ları (kısa özet) - ilan_detail_screen.dart'dan alındı
  List<Widget> _buildTopPropertyWidgets() {
    if (_currentListing == null) return [const Text('Veri yok')];
    
    List<Widget> widgets = [];
    
    // Temel bilgileri göster
    widgets.addAll([
      _DetailRowPreview(
        icon: Icons.square_foot,
        label: "m²",
        value: _currentListing!.area.isNotEmpty ? _currentListing!.area : '-'
      ),
      _DetailRowPreview(
        icon: Icons.meeting_room,
        label: "Oda Sayısı",
        value: _currentListing!.rooms.isNotEmpty ? _currentListing!.rooms : '-'
      ),
      _DetailRowPreview(
        icon: Icons.layers,
        label: "Kat",
        value: "Zemin Kat"
      ),
      _DetailRowPreview(
        icon: Icons.apartment,
        label: "Bina Yaşı",
        value: "3"
      ),
      _DetailRowPreview(
        icon: Icons.fireplace,
        label: "Isıtma",
        value: "Merkezi"
      ),
    ]);
    
    return widgets;
  }
}

class IlanPreviewCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String district;
  final String imageUrl;
  final String status;
  final String type;
  final String description;

  const IlanPreviewCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.district,
    required this.imageUrl,
    required this.status,
    required this.type,
    required this.description,
  });

  /// Fiyatı düzgün formatlayarak gösterir (örn: "2.000.000 TL")
  String _formatPrice(String priceStr) {
    // Önce string'den sadece sayıları al
    String digitsOnly = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return priceStr; // Eğer sayı yoksa orijinal string'i döndür
    }
    
    // String'i integer'a çevir
    int? price = int.tryParse(digitsOnly);
    
    if (price == null) {
      return priceStr; // Parse edilemezse orijinal string'i döndür
    }
    
    // NumberFormat ile formatla (Türkçe binlik ayırıcı: nokta)
    final formatter = NumberFormat('#,###', 'tr_TR');
    String formatted = formatter.format(price);
    
    // TL ekle
    return '$formatted TL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 48, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Yayında'
                            ? Colors.green
                            : status == 'Taslak'
                                ? Colors.orange
                                : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$location / $district',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListingDetailPreview extends StatefulWidget {
  final String title;
  final String price;
  final String location;
  final String district;
  final String imageUrl;
  final String? coverPicture; // API'den gelen cover picture
  final String status;
  final String type;
  final String description;
  final String grossArea;
  final String netArea;
  final String buildingAge;
  final String roomCount;
  final String floorCount;
  final String heating;
  final String portfolioNo;

  const ListingDetailPreview({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.district,
    required this.imageUrl,
    this.coverPicture,
    required this.status,
    required this.type,
    required this.description,
    required this.grossArea,
    required this.netArea,
    required this.buildingAge,
    required this.roomCount,
    required this.floorCount,
    required this.heating,
    required this.portfolioNo,
  });

  @override
  State<ListingDetailPreview> createState() => _ListingDetailPreviewState();
}

class _ListingDetailPreviewState extends State<ListingDetailPreview> {
  @override
  void initState() {
    super.initState();
  }

  /// Fiyatı düzgün formatlayarak gösterir (örn: "2.000.000 TL")
  String _formatPrice(String priceStr) {
    // Önce string'den sadece sayıları al
    String digitsOnly = priceStr.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return priceStr; // Eğer sayı yoksa orijinal string'i döndür
    }
    
    // String'i integer'a çevir
    int? price = int.tryParse(digitsOnly);
    
    if (price == null) {
      return priceStr; // Parse edilemezse orijinal string'i döndür
    }
    
    // NumberFormat ile formatla (Türkçe binlik ayırıcı: nokta)
    final formatter = NumberFormat('#,###', 'tr_TR');
    String formatted = formatter.format(price);
    
    // TL ekle (fiyat stringinde zaten para birimi varsa tekrar eklenmez)
    if (priceStr.contains('TL') || priceStr.contains('USD') || priceStr.contains('EUR')) {
      return formatted;
    }
    return '$formatted TL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotoğraf galerisi kaldırıldı - üstte ayrı galeri var
            const SizedBox(height: 10),
            // Başlık, fiyat, konum, portföy no
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatPrice(widget.price),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFFE53935)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.location}, ${widget.district}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Portföy No: ${widget.portfolioNo}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Satılık etiketi ve butonlar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      widget.status.isNotEmpty ? widget.status : "SATILIK",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.red[600],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Bilgi tablosu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    _DetailRowPreview(
                        icon: Icons.square_foot,
                        label: "m² (Brüt)",
                        value: widget.grossArea),
                    _DetailRowPreview(
                        icon: Icons.square_foot,
                        label: "m² (Net)",
                        value: widget.netArea),
                    _DetailRowPreview(
                        icon: Icons.apartment,
                        label: "Bina Yaşı",
                        value: widget.buildingAge),
                    _DetailRowPreview(
                        icon: Icons.meeting_room,
                        label: "Oda Sayısı",
                        value: widget.roomCount),
                    _DetailRowPreview(
                        icon: Icons.format_list_numbered,
                        label: "Kat Sayısı",
                        value: widget.floorCount),
                    _DetailRowPreview(
                        icon: Icons.fireplace,
                        label: "Isıtma",
                        value: widget.heating),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Genel Özellikler kutusu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Container(
                margin: const EdgeInsets.only(top: 0, bottom: 16, left: 8, right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Genel Özellikler",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                            fontSize: 16)),
                    const SizedBox(height: 10),
                    _OzellikSatiriPreview(icon: Icons.square_foot, label: "m² (Brüt)", value: widget.grossArea, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.square_foot, label: "m² (Net)", value: widget.netArea, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.apartment, label: "Bina Yaşı", value: widget.buildingAge, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.meeting_room, label: "Oda Sayısı", value: widget.roomCount, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.meeting_room, label: "Bulunduğu Kat", value: widget.buildingAge, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.format_list_numbered, label: "Kat Sayısı", value: widget.floorCount, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.fireplace, label: "Isıtma", value: widget.heating, isBold: true),
                    _OzellikSatiriPreview(icon: Icons.bathtub, label: "Banyo Sayısı", value: "3", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.balcony, label: "Balkon", value: "Var", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.local_parking, label: "Otopark", value: "Açık Otopark", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.chair, label: "Eşyalı", value: "Hayır", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.money_off, label: "Aidat (TL)", value: "Yok", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.wb_sunny, label: "Cephe", value: "Batı", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.check_circle, label: "Krediye Uygun", value: "Evet", isBold: true),
                    _OzellikSatiriPreview(icon: Icons.assignment_turned_in, label: "Tapu Durumu", value: "Kat Mülkiyeti", isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRowPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRowPreview({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[700], size: 22),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OzellikSatiriPreview extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  const _OzellikSatiriPreview({required this.icon, required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red[700], size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}