import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/models/list/listing_panel_model.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/list/listing_update_service.dart';
import 'package:zecorner/infrastructure/list/my_listings_repository.dart';

class TransactionDetailScreen extends StatefulWidget {
  final ListingPanelModel listing;

  const TransactionDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ListingUpdateService _listingService = ListingUpdateService();
  final MyListingsRepository _listingsRepository = MyListingsRepository();
  
  ListingPanelModel? _listing;
  bool _isLoading = false;
  bool _isDeciding = false;

  @override
  void initState() {
    super.initState();
    _listing = widget.listing;
    _loadListingDetail();
  }

  Future<void> _loadListingDetail() async {
      setState(() {
        _isLoading = true;
      });

    try {
      final result = await _listingService.getListingDetail(widget.listing.id);

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hata: ${failure.message}'),
                backgroundColor: const Color(0xFFE53935),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        },
        (listing) {
          setState(() {
            _isLoading = false;
            _listing = listing;
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlan detayı yüklenirken hata oluştu: $e'),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _approveListing() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kırmızı Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'İşlem Bildirimini Onayla',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Beyaz İçerik
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt
                      const Text(
                        'İşlemi onaylıyorsunuz, emin misiniz?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Hayır',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isDeciding
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _submitApprove();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Evet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _rejectListing() async {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kırmızı Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'İşlem Bildirimini Reddet',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Beyaz İçerik
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prompt
                      const Text(
                        'Bu işlemi gerçekleştirmek istediğinize emin misiniz?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Text Input - Kırmızı border
                      TextField(
                        controller: reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Reddetme nedeni',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Vazgeç',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final reason = reasonController.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lütfen reddetme nedeni giriniz'),
                                      backgroundColor: Color(0xFFE53935),
                                    ),
                                  );
                                  return;
                                }
                                
                                Navigator.pop(context);
                                _submitReject(reason);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Onayla',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Future<void> _submitApprove() async {
    final listingId = _listing?.id ?? widget.listing.id;
    if (_isDeciding || listingId.trim().isEmpty) return;
    setState(() => _isDeciding = true);
    final result = await _listingsRepository.approveClosureListing(listingId);
    if (!mounted) return;
    setState(() => _isDeciding = false);
    result.fold(
      (failure) => _showDecisionMessage(failure.message, const Color(0xFFE53935)),
      (message) => Navigator.pop(context, message),
    );
  }

  Future<void> _submitReject(String reason) async {
    final listingId = _listing?.id ?? widget.listing.id;
    if (_isDeciding || listingId.trim().isEmpty) return;
    setState(() => _isDeciding = true);
    final result = await _listingsRepository.rejectClosureListing(
      listingId,
      message: reason,
    );
    if (!mounted) return;
    setState(() => _isDeciding = false);
    result.fold(
      (failure) => _showDecisionMessage(failure.message, const Color(0xFFE53935)),
      (message) => Navigator.pop(context, message),
    );
  }

  void _showDecisionMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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

  String _formatPropertyValue(String code, dynamic property) {
    // PropertyModel'den numberValue veya value al
    // PropertyModel'de stringValue yok, sadece value ve numberValue var
    final numberValue = property.numberValue;
    final value = property.value;
    
    // Önce numberValue kontrol et
    if (numberValue != null) {
      return numberValue.toString();
    }
    
    // Özel formatlamalar için value kullan
    final val = value?.toString() ?? '';
    switch (code) {
      case 'oda-sayisi':
        if (val.contains('oda-sayisi-')) {
          final roomCode = val.replaceAll('oda-sayisi-', '');
          switch (roomCode) {
            case '10':
              return 'Stüdyo (1+0)';
            case '11':
              return '1+1';
            case '21':
              return '2+1';
            case '31':
              return '3+1';
            case '41':
              return '4+1';
            case '51':
              return '5+1';
            default:
              return roomCode;
          }
        }
        return val;
      case 'isitma':
        final heating = val.replaceAll('isitma-', '').replaceAll('-', ' ');
        if (heating.isEmpty || heating == 'yok') return 'Yok';
        return heating.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
      case 'bina-yasi':
        final age = val.replaceAll('bina-yasi-', '');
        if (age.isEmpty) return '-';
        return '$age yıl';
      case 'kat-sayisi':
        final floors = val.replaceAll('kat-sayisi-', '');
        if (floors.isEmpty) return '-';
        return floors;
      case 'banyo-sayisi':
        final bathrooms = val.replaceAll('banyo-sayisi-', '');
        if (bathrooms.isEmpty) return '-';
        return bathrooms;
      case 'balkon':
        final balcony = val.replaceAll('balkon-', '').replaceAll('-', ' ');
        if (balcony == 'var') return 'Var';
        if (balcony == 'yok') return 'Yok';
        return balcony.isEmpty ? '-' : balcony;
      case 'esyali':
        final furnished = val.replaceAll('esyali-', '').replaceAll('-', ' ');
        if (furnished == 'evet') return 'Evet';
        if (furnished == 'hayir' || furnished == 'hayır') return 'Hayır';
        return furnished.isEmpty ? '-' : furnished;
      case 'aidat-tl':
        if (numberValue != null && numberValue! > 0) {
          return '₺${NumberFormat('#,##0.00', 'tr_TR').format(numberValue)}';
        }
        return '-';
      case 'depozito-tl':
        if (numberValue != null && numberValue! > 0) {
          return '₺${NumberFormat('#,##0.00', 'tr_TR').format(numberValue)}';
        }
        return '-';
      default:
        // Eğer value boşsa veya sadece code içeriyorsa, numberValue varsa onu göster
        if (val.isEmpty || val == code) {
          if (numberValue != null) {
            return numberValue.toString();
          }
          return '-';
        }
        return val;
    }
  }

  String _formatPropertyLabel(String code) {
    switch (code) {
      case 'm2-brut':
        return 'm² (Brüt)';
      case 'm2-net':
        return 'm² (Net)';
      case 'acik-alan-m2':
        return 'Açık Alan (m²)';
      case 'oda-sayisi':
        return 'Oda Sayısı';
      case 'bina-yasi':
        return 'Bina Yaşı';
      case 'kat-sayisi':
        return 'Kat Sayısı';
      case 'isitma':
        return 'Isıtma';
      case 'banyo-sayisi':
        return 'Banyo Sayısı';
      case 'balkon':
        return 'Balkon';
      case 'esyali':
        return 'Eşyalı';
      case 'aidat-tl':
        return 'Aidat (TL)';
      case 'depozito-tl':
        return 'Depozito (TL)';
      case 'tasinmaz-numarasi':
        return 'Taşınmaz Numarası';
      default:
        return code.replaceAll('-', ' ').split(' ').map((word) {
          return word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE53935),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'İlan Detayı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
          ),
        ),
      );
    }

    final listing = _listing!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: RoleSidebar(currentPage: 'İşlem Bildirim Onayları'),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'İlan Detayı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Başlık, Portföy No, Görüntülenme
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık ve Portföy No
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Portföy No: ${listing.listingNo}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Görüntülenme ve Butonlar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility, size: 14, color: const Color(0xFFE53935)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${listing.viewCount} kez görüntülendi',
                                    style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Onayla ve Reddet Butonları
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: _isDeciding ? null : _rejectListing,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE53935),
                                    side: const BorderSide(color: Color(0xFFE53935)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Reddet', style: TextStyle(fontSize: 13)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isDeciding ? null : _approveListing,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Onayla', style: TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Resim - İlan kartındaki fotoğrafı kullan
                  _buildListingImage(listing, widget.listing),

                  // İlan Bilgileri
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tarih
                        Text(
                          'İlan Tarihi: ${_formatDate(listing.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Konum
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: Colors.grey.shade600),
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

                        // Tip ve Fiyat
                        Row(
                          children: [
                            Container(
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
                            const Spacer(),
                            Text(
                              listing.formattedPrice,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Satış Bilgileri
                  _buildSalesInfo(listing),

                  // İlan Açıklaması
                  _buildDescription(listing),

                  // Genel Özellikler
                  _buildGeneralFeatures(listing),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: const AdminNavbar(currentIndex: 0, onTap: null),
    );
  }

  Widget _buildListingImage(ListingPanelModel? listing, ListingPanelModel originalListing) {
    // Önce API'den gelen listing'in coverPicture'ını dene, yoksa orijinal listing'den al
    final coverPicture = listing?.coverPicture ?? originalListing.coverPicture;
    final imageUrl = ImageUtils.getCoverImageUrl(coverPicture);
    
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
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
            height: 300,
            color: Colors.grey.shade200,
            child: Icon(Icons.home, size: 64, color: Colors.grey.shade400),
          );
        },
      );
    } else {
      return Container(
        height: 300,
        color: Colors.grey.shade200,
        child: Icon(Icons.home, size: 64, color: Colors.grey.shade400),
      );
    }
  }

  Widget _buildSalesInfo(ListingPanelModel listing) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Satış Bilgileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 20),
          // Tek sütunlu layout (mobile için daha uygun)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Ev Sahibi:', listing.contactTitle),
              const SizedBox(height: 16),
              _buildInfoRow('Danışman:', listing.contactTitle),
              const SizedBox(height: 16),
              _buildInfoRow('Kapanış Fiyatı:', _formatPrice(listing.closingPrice)),
              const SizedBox(height: 16),
              _buildInfoRow('Kiralama Tarihi:', _formatDate(listing.createdAt)),
              const SizedBox(height: 16),
              _buildInfoRow('Satıcıdan Alınan Komisyon (KDV Dahil):', _formatPrice(listing.closingPrice)),
              const SizedBox(height: 16),
              _buildInfoRow('Toplam Komisyon (KDV Dahil):', _formatPrice(listing.closingPrice)),
              const SizedBox(height: 16),
              _buildInfoRow('Müşteriden Alınan Komisyon (KDV Dahil):', '₺0,00'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(String? price) {
    if (price == null || price.isEmpty) return '₺0,00';
    try {
      final priceValue = double.parse(price);
      return '₺${NumberFormat('#,##0.00', 'tr_TR').format(priceValue)}';
    } catch (e) {
      return '₺$price';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildDescription(ListingPanelModel listing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlan Açıklaması',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Açıklama bulunmuyor', // API'den gelecek
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralFeatures(ListingPanelModel listing) {
    final properties = listing.properties;
    
    // Önemli özellikleri filtrele
    final importantProperties = [
      'm2-brut',
      'm2-net',
      'acik-alan-m2',
      'oda-sayisi',
      'bina-yasi',
      'kat-sayisi',
      'isitma',
      'banyo-sayisi',
      'balkon',
      'esyali',
      'aidat-tl',
      'depozito-tl',
      'tasinmaz-numarasi',
    ];

    final filteredProperties = properties.entries
        .where((entry) => importantProperties.contains(entry.key))
        .toList();

    if (filteredProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genel Özellikler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 20),
          // İki sütunlu layout - mobile uyumlu
          LayoutBuilder(
            builder: (context, constraints) {
              // Küçük ekranlarda tek sütun, büyük ekranlarda iki sütun
              if (constraints.maxWidth < 400) {
                return Column(
                  children: filteredProperties
                      .map((entry) => _buildFeatureRow(entry.key, entry.value))
                      .toList(),
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: filteredProperties
                            .where((entry) => filteredProperties.indexOf(entry) % 2 == 0)
                            .map((entry) => _buildFeatureRow(entry.key, entry.value))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: filteredProperties
                            .where((entry) => filteredProperties.indexOf(entry) % 2 == 1)
                            .map((entry) => _buildFeatureRow(entry.key, entry.value))
                            .toList(),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String code, dynamic property) {
    final label = _formatPropertyLabel(code);
    final value = _formatPropertyValue(code, property);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

