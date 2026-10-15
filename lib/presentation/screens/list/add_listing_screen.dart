import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:zecorner/presentation/screens/list/listings_screen.dart';
import 'package:zecorner/infrastructure/realestate/myrealestate_repo.dart';
import 'package:zecorner/infrastructure/listing/listing_api_repository.dart';
import 'package:zecorner/models/realestate/myrealestate_model.dart';

// New listing model for creating listings
class NewListing {
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

  NewListing({
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
  });

  // Convert to Listing for adding to state
  Listing toListing() {
    // Generate a unique ID
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
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
      isActive: isActive, medias: [],
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

class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key});

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();
  final TextEditingController _consultantController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  RealEstateModel? _selectedPortfolio;
  List<RealEstateModel> _allPortfolios = [];
  List<RealEstateModel> _filteredPortfolios = [];
  bool _isLoadingPortfolios = false;
  final MyRealEstateRepository _portfolioRepository = MyRealEstateRepository();

  final TextEditingController _ilanTipiController = TextEditingController();
  final FocusNode _ilanTipiFocusNode = FocusNode();
  String? _selectedIlanTipi;
  List<Map<String, String>> _allIlanTipleri = [
    {"label": "Kiralık", "value": "kiralik"},
    {"label": "Satılık", "value": "satilik"},
  ];
  List<Map<String, String>> _filteredIlanTipleri = [];
  OverlayEntry? _ilanTipiOverlayEntry;
  final GlobalKey _ilanTipiFieldKey = GlobalKey();

  String _selectedListingType = '';
  String _selectedCurrency = '';
  String _selectedStatus = '';
  String _selectedPropertyType = 'Kiralık'; // Kiralık or Satılık
  bool _showOnlyZeOnline = false;
  bool _hasChanges = false;
  
  // Özellikler (Properties)
  String? _selectedTapuDurumu; // Satılık için
  String? _selectedKrediyeUygun; // Satılık için
  final TextEditingController _depozitController = TextEditingController(); // Kiralık için

  // Location dropdown selections
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  List<String> _districts = [];
  List<String> _neighborhoods = [];

  // Cities data
  final List<String> _cities = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Konya',
    'Şanlıurfa',
    'Gaziantep',
    'Kocaeli'
  ];

  // Get state manager
  final ListingsState _listingsState = ListingsState();

  @override
  void initState() {
    super.initState();

    // Add listeners to detect changes
    _titleController.addListener(_onFieldChanged);
    _priceController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _areaController.addListener(_onFieldChanged);
    _roomsController.addListener(_onFieldChanged);
    _consultantController.addListener(_onFieldChanged);
    _portfolioController.addListener(_onPortfolioChanged);
    _ilanTipiController.addListener(_onIlanTipiChanged);
    _ilanTipiFocusNode.addListener(_onIlanTipiFocus);

    // Set default values
    _selectedStatus = 'Taslak';
    _selectedCurrency = 'TL';
    _selectedListingType = 'Konut';
    _filteredIlanTipleri = _allIlanTipleri;
    
    // API'den portföyleri yükle
    _loadPortfolios();
  }
  
  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoadingPortfolios = true;
    });
    
    final result = await _portfolioRepository.getAllMyRealEstates();
    
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isLoadingPortfolios = false;
          });
          _showErrorMessage('Portföyler yüklenemedi: ${failure.message}');
        }
      },
      (response) {
        if (mounted) {
          setState(() {
            _allPortfolios = response.realEstates;
            _filteredPortfolios = response.realEstates;
            _isLoadingPortfolios = false;
          });
        }
      },
    );
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _onPortfolioChanged() {
    final query = _portfolioController.text.toLowerCase();
    setState(() {
      _filteredPortfolios = query.isEmpty
        ? _allPortfolios
        : _allPortfolios.where((p) => p.title.toLowerCase().contains(query)).toList();
    });
  }

  void _showPortfolioModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Portföy Seç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _portfolioController,
                      decoration: InputDecoration(
                        hintText: 'Ara',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          _onPortfolioChanged();
                        });
                      },
                    ),
                  ),
                  // Portfolio List
                  Expanded(
                    child: _isLoadingPortfolios
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE53935),
                            ),
                          )
                        : _filteredPortfolios.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Portföy bulunamadı',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredPortfolios.length,
                                itemBuilder: (context, index) {
                                  final portfolio = _filteredPortfolios[index];
                                  final isSelected = _selectedPortfolio?.id == portfolio.id;
                                  
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedPortfolio = portfolio;
                                        _portfolioController.clear();
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? const Color(0xFFE53935).withOpacity(0.1)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? const Color(0xFFE53935)
                                              : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE53935).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.home_work,
                                              color: Color(0xFFE53935),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              portfolio.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFFE53935),
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
        );
      },
    );
  }

  void _onIlanTipiChanged() {
    final query = _ilanTipiController.text.toLowerCase();
    setState(() {
      _filteredIlanTipleri = query.isEmpty
        ? _allIlanTipleri
        : _allIlanTipleri.where((t) => t['label']!.toLowerCase().contains(query)).toList();
    });
    if (_ilanTipiFocusNode.hasFocus) {
      _showIlanTipiOverlay();
    } else {
      _removeIlanTipiOverlay();
    }
  }

  void _onIlanTipiFocus() {
    if (_ilanTipiFocusNode.hasFocus) {
      setState(() {
        _filteredIlanTipleri = _allIlanTipleri;
      });
      _showIlanTipiOverlay();
    } else {
      _removeIlanTipiOverlay();
    }
  }

  void _showIlanTipiOverlay() {
    if (_ilanTipiOverlayEntry != null) return;
    final RenderBox box = _ilanTipiFieldKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    _ilanTipiOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 220),
            child: _filteredIlanTipleri.isEmpty
                ? Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Text("Seçenek Bulunamadı", style: TextStyle(color: Colors.grey[600])),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredIlanTipleri.length,
                    itemBuilder: (context, i) {
                      final t = _filteredIlanTipleri[i];
                      return ListTile(
                        leading: Icon(Icons.category, color: Color(0xFFE53935)),
                        title: Text(t['label']!),
                        onTap: () {
                          setState(() {
                            _selectedIlanTipi = t['value']; // value: "kiralik" or "satilik"
                            _ilanTipiController.text = t['label']!; // label: "Kiralık" or "Satılık"
                          });
                          _removeIlanTipiOverlay();
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_ilanTipiOverlayEntry!);
  }

  void _removeIlanTipiOverlay() {
    _ilanTipiOverlayEntry?.remove();
    _ilanTipiOverlayEntry = null;
  }

  @override
  void dispose() {
    _portfolioController.dispose();
    _ilanTipiOverlayEntry?.remove();
    _ilanTipiFocusNode.dispose();
    _ilanTipiController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _consultantController.dispose();
    _depozitController.dispose();
    super.dispose();
  }

  // Helper method to get districts for selected city
  List<String> _getDistrictsForCity(String city) {
    switch (city) {
      case 'İstanbul':
        return [
          'Kadıköy',
          'Beşiktaş',
          'Üsküdar',
          'Şişli',
          'Beyoğlu',
          'Fatih',
          'Bakırköy',
          'Maltepe'
        ];
      case 'Ankara':
        return [
          'Çankaya',
          'Keçiören',
          'Yenimahalle',
          'Mamak',
          'Sincan',
          'Etimesgut',
          'Altındağ'
        ];
      case 'İzmir':
        return [
          'Konak',
          'Bornova',
          'Karşıyaka',
          'Buca',
          'Çiğli',
          'Gaziemir',
          'Balçova'
        ];
      case 'Bursa':
        return [
          'Osmangazi',
          'Nilüfer',
          'Yıldırım',
          'Mudanya',
          'Gemlik',
          'İnegöl'
        ];
      case 'Antalya':
        return [
          'Muratpaşa',
          'Kepez',
          'Konyaaltı',
          'Aksu',
          'Döşemealtı',
          'Alanya'
        ];
      default:
        return ['Merkez', 'Centrum', 'Şehir Merkezi'];
    }
  }

  // Helper method to get neighborhoods for selected district
  List<String> _getNeighborhoodsForDistrict(String district) {
    switch (district) {
      case 'Kadıköy':
        return [
          'Caferağa',
          'Fenerbahçe',
          'Göztepe',
          'Bostancı',
          'Suadiye',
          'Erenköy'
        ];
      case 'Beşiktaş':
        return [
          'Levent',
          'Etiler',
          'Ortaköy',
          'Bebek',
          'Arnavutköy',
          'Kuruçeşme'
        ];
      case 'Üsküdar':
        return [
          'Salacak',
          'Kuzguncuk',
          'Çengelköy',
          'Beylerbeyi',
          'Kandilli',
          'Vaniköy'
        ];
      case 'Çankaya':
        return [
          'Kızılay',
          'Bahçelievler',
          'Çayyolu',
          'Ümitköy',
          'Bilkent',
          'Konutkent'
        ];
      case 'Konak':
        return [
          'Alsancak',
          'Karataş',
          'Güzelyalı',
          'Hatay',
          'Basmane',
          'Kemeraltı'
        ];
      default:
        return ['1. Mahalle', '2. Mahalle', '3. Mahalle', 'Merkez Mahalle'];
    }
  }

  Future<void> _createListing() async {
    // Validation
    if (_selectedPortfolio == null) {
      _showErrorMessage('Lütfen portföy seçin');
      return;
    }
    if (_selectedIlanTipi == null) {
      _showErrorMessage('Lütfen ilan tipi seçin');
      return;
    }
    if (_titleController.text.isEmpty) {
      _showErrorMessage('Lütfen ilan başlığını girin');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      _showErrorMessage('Lütfen ilan açıklaması girin');
      return;
    }
    if (_priceController.text.isEmpty) {
      _showErrorMessage('Lütfen fiyat girin');
      return;
    }

    try {
      double.parse(_priceController.text);
    } catch (e) {
      _showErrorMessage('Lütfen geçerli bir fiyat girin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Properties array hazırla (sadece dolu olanlar)
      List<Map<String, dynamic>> properties = [];
      
      if (_selectedIlanTipi == 'kiralik') {
        // Depozito (TL)
        if (_depozitController.text.trim().isNotEmpty) {
          try {
            final depozito = double.parse(_depozitController.text.trim());
            properties.add({
              'code': 'depozito',
              'number_value': depozito,
            });
          } catch (e) {
            print('⚠️ Depozito değeri sayıya çevrilemedi: ${_depozitController.text}');
          }
        }
      }
      
      if (_selectedIlanTipi == 'satilik') {
        // Krediye Uygun
        if (_selectedKrediyeUygun != null) {
          properties.add({
            'code': 'krediye-uygun',
            'value': _selectedKrediyeUygun == 'Evet' ? 'krediye-uygun-evet' : 'krediye-uygun-hayir',
          });
        }
        
        // Tapu Durumu
        if (_selectedTapuDurumu != null) {
          final tapuMap = {
            'Kat Mülkiyeti': 'tapu-durumu-kat-mulkiyeti',
            'Kat İrtifakı': 'tapu-durumu-kat-irtifaki',
            'Hisseli Tapu': 'tapu-durumu-hisseli-tapu',
            'Müstakil Tapulu': 'tapu-durumu-mustakil-tapulu',
            'Arsa Tapulu': 'tapu-durumu-arsa-tapulu',
            'Bilinmiyor': 'tapu-durumu-bilinmiyor',
          };
          
          properties.add({
            'code': 'tapu-durumu',
            'value': tapuMap[_selectedTapuDurumu] ?? 'tapu-durumu-bilinmiyor',
          });
        }
      }
      
      // API için request data hazırla
      final listingData = {
        'real_estate': _selectedPortfolio!.id, // Portfolio ID (real_estate field)
        'type': _selectedIlanTipi, // "kiralik" or "satilik"
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'currency': _selectedCurrency,
        'internal': _showOnlyZeOnline, // Sadece Ze-Online'da göster
        'properties': properties, // ✅ Properties array
      };

      print('🔄 Creating listing...');
      print('📋 Listing Data: $listingData');

      final repository = ListingApiRepository(dio: Dio());
      final result = await repository.createListing(listingData);

      setState(() {
        _isLoading = false;
      });

      result.fold(
        (failure) {
          _showErrorMessage(failure.message);
        },
        (response) {
          // Başarılı modal göster
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
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
                      // Success Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFFE53935),
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      const Text(
                        'İlan Oluşturuldu',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Message
                      Text(
                        'İlanınız başarıyla oluşturulmuştur, ilanınız onaylandıktan sonra yayınlanacaktır.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // OK Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(context).pop(); // Close screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Tamam',
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
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Beklenmeyen bir hata oluştu: $e');
    }
  }
  
  bool _isLoading = false;

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          "İlan Oluştur",
          style: TextStyle(
            color: Color.fromRGBO(238, 46, 36, 1),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_hasChanges)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Değişiklik var',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ze-Online Switch kutusu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Row(
                children: [
                  Switch(
                    value: _showOnlyZeOnline,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyZeOnline = value;
                        _hasChanges = true;
                      });
                    },
                    activeColor: const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Sadece Ze-Online'da göster",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text('Bilgi'),
                          content: const Text('Bu seçenek aktif olduğunda ilanınız sadece zeonline panelinde görünür olacaktır.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Tamam',style: TextStyle(color: Color(0xFFE53935)),),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Portföy kutusu (Modal ile)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Portföy", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  SizedBox(height: 8),
                  if (_selectedPortfolio == null)
                    InkWell(
                      onTap: _showPortfolioModal,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _isLoadingPortfolios ? "Portföyler yükleniyor..." : "Ara",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Spacer(),
                            Icon(Icons.search, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE53935)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.home_work, color: Color(0xFFE53935)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedPortfolio!.title, 
                              style: TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                            onPressed: () {
                              setState(() {
                                _selectedPortfolio = null;
                                _portfolioController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // İlan Tipi kutusu (OverlayEntry ile autocomplete)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("İlan Tipi", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  SizedBox(height: 8),
                  if (_selectedIlanTipi == null)
                    TextFormField(
                      key: _ilanTipiFieldKey,
                      controller: _ilanTipiController,
                      focusNode: _ilanTipiFocusNode,
                      decoration: InputDecoration(
                        hintText: "İlan Tipi Seçin",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Color(0xFFE53935)),
                          SizedBox(width: 8),
                          Expanded(child: Text(_ilanTipiController.text, style: TextStyle(fontWeight: FontWeight.w600))),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                            onPressed: () {
                              setState(() {
                                _selectedIlanTipi = null;
                                _ilanTipiController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Özellikler (Properties) - Kiralık için
            if (_selectedIlanTipi == 'kiralik')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Color(0xFFE53935), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Özellikler",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Depozito (TL) TextField
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Depozito (TL)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _depozitController,
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _onFieldChanged(),
                          decoration: InputDecoration(
                            hintText: "Depozito tutarını girin",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_selectedIlanTipi == 'kiralik') SizedBox(height: 16),
            
            // Özellikler (Properties) - Satılık için
            if (_selectedIlanTipi == 'satilik')
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Color(0xFFE53935), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Özellikler",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Krediye Uygun Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Krediye Uygun", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedKrediyeUygun,
                          onChanged: (value) {
                            setState(() {
                              _selectedKrediyeUygun = value;
                              _hasChanges = true;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Seçiniz",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: Color(0xFFE53935),
                          items: ["Evet", "Hayır"].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          )).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Tapu Durumu Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tapu Durumu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTapuDurumu,
                          onChanged: (value) {
                            setState(() {
                              _selectedTapuDurumu = value;
                              _hasChanges = true;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Seçiniz",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                          iconEnabledColor: Color(0xFFE53935),
                          items: [
                            "Kat Mülkiyeti",
                            "Kat İrtifakı", 
                            "Hisseli Tapu",
                            "Müstakil Tapulu",
                            "Arsa Tapulu",
                            "Bilinmiyor"
                          ].map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          )).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_selectedIlanTipi == 'satilik') SizedBox(height: 16),
            
            // İlan Başlığı kutusu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("İlan Başlığı", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "İlan başlığını girin",
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // İlan Açıklaması kutusu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("İlan Açıklaması", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  SizedBox(height: 8),
                  Container(
                    height: 120,
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (value) => _onFieldChanged(),
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
                          borderSide: BorderSide(
                            color: Color(0xFFE53935),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Para Birimi ve Fiyat kutusu
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Para Birimi", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: ["TL", "USD", "EUR"].contains(_selectedCurrency) ? _selectedCurrency : null,
                        onChanged: (value) {
                          setState(() {
                            _selectedCurrency = value ?? '';
                            _hasChanges = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Para Birimi",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        dropdownColor: Colors.white,
                        iconEnabledColor: Color(0xFFE53935),
                        items: ["TL", "USD", "EUR"].map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        )).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Fiyat", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Fiyat",
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // İlan Oluştur butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "İlan Oluştur",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Action Buttons
            // Row(
            //   children: [
            //     Expanded(
            //       child: OutlinedButton(
            //         onPressed: () => Navigator.pop(context),
            //         style: OutlinedButton.styleFrom(
            //           side: BorderSide(color: Color(0xFFE53935)),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           padding: EdgeInsets.symmetric(vertical: 16),
            //         ),
            //         child: Text(
            //           "İptal",
            //           style: TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.w600,
            //             color: Color(0xFFE53935),
            //           ),
            //         ),
            //       ),
            //     ),
            //     SizedBox(width: 16),
            //     Expanded(
            //       child: ElevatedButton(
            //         onPressed: () async {
            //           // Show loading
            //           showDialog(
            //             context: context,
            //             barrierDismissible: false,
            //             builder: (context) => Center(
            //               child: CircularProgressIndicator(
            //                 color: Color(0xFFE53935),
            //               ),
            //             ),
            //           );

            //           // Create listing
            //           await _createListing();

            //           // Close loading dialog
            //           Navigator.pop(context);
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Color(0xFFE53935),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(8),
            //           ),
            //           padding: EdgeInsets.symmetric(vertical: 16),
            //         ),
            //         child: Text(
            //           "İlan Oluştur",
            //           style: TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.w600,
            //             color: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (value) => _onFieldChanged(),
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
            value: value.isNotEmpty && items.contains(value) ? value : null,
            items: items.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            )).toList(),
            onChanged: onChanged,
            hint: Text(hint),
          ),
        ),
      ],
    );
  }
} 