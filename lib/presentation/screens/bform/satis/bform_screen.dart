import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/presentation/widgets/bform/bform_assignment_panel.dart';
import 'package:dio/dio.dart';

class BformScreen extends StatefulWidget {
  const BformScreen({super.key});

  @override
  State<BformScreen> createState() => _BformScreenState();
}

class _BformScreenState extends State<BformScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;

  // Filtre için state değişkenleri ekleyelim
  String selectedYear = '2024';
  String selectedMonth = 'Aralık';
  final List<String> years = ['2024', '2023', '2022'];
  final List<String> months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];

  // Grafik verilerini tutan değişken
  List<double> chartData = [450000, 520000, 542200, 480000, 510000];

  // Tarih seçici için state değişkenleri
  DateTime? startDate;
  DateTime? endDate;

  // API related variables
  late final BformApiRepository _bformRepository;
  List<BformApiModel> _bforms = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';

  @override
  void initState() {
    super.initState();
    _bformRepository = BformApiRepository(dio: Dio());

    _rotationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMoreData &&
          !_isLoading) {
        _loadBforms(isLoadMore: true);
      }
    });

    // Initial load
    _loadBforms();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBforms({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (_currentPage >= _totalPages) {
        setState(() => _hasMoreData = false);
        return;
      }
      setState(() => _isLoading = true);
    }

    final result = await _bformRepository.getBforms(
      page: _currentPage,
      limit: 10,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: _selectedStatus,
      startDate: startDate,
      endDate: endDate,
      formType: 'sale-request', // Satış Talepleri için
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
          if (!isLoadMore) _bforms.clear();
        });
      },
      (response) {
        setState(() {
          _isLoading = false;
          if (!isLoadMore) {
            _bforms = response.data;
          } else {
            _bforms.addAll(response.data);
          }
          _currentPage = response.page + 1;
          _totalPages = response.totalPages;
          _hasMoreData = response.page < response.totalPages;
        });
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
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Satış Talepleri');
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
        title: 'Satış Talepleri',
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
                // Modern Date Picker Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Date Picker Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: () {
                                DatePicker.showDateTimePicker(
                                  context,
                                  showTitleActions: true,
                                  minTime: DateTime(2020, 1, 1),
                                  maxTime: DateTime(2025, 12, 31),
                                  onConfirm: (date) {
                                    setState(() {
                                      if (startDate == null) {
                                        startDate = date;
                                      } else if (endDate == null) {
                                        endDate = date;
                                      } else {
                                        startDate = date;
                                        endDate = null;
                                      }
                                      _currentPage = 1;
                                      _bforms.clear();
                                      _hasMoreData = true;
                                    });
                                    _loadBforms();
                                  },
                                  currentTime: DateTime.now(),
                                  locale: LocaleType.tr,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 20, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startDate == null
                                            ? "Başlangıç - Bitiş Aralığı Seçiniz"
                                            : endDate == null
                                                ? "Başlangıç: ${startDate!.toString().substring(0, 16)}"
                                                : "${startDate!.toString().substring(0, 16)} - ${endDate!.toString().substring(0, 16)}",
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    startDate = null;
                                    endDate = null;
                                    _currentPage = 1;
                                    _bforms.clear();
                                    _hasMoreData = true;
                                  });
                                  _loadBforms();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Text(
                                    "Filtreyi Temizle",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search and Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down,
                                      color: Colors.grey[600]),
                                  items: [
                                    "Tümü",
                                    "Arandı",
                                    "Devam Ediyor",
                                    "Görüşülmedi"
                                  ]
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: TextStyle(
                                                    color: Colors.grey[700])),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStatus = value!;
                                      _currentPage = 1;
                                      _bforms.clear();
                                      _hasMoreData = true;
                                    });
                                    _loadBforms();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                    _currentPage = 1;
                                    _bforms.clear();
                                    _hasMoreData = true;
                                  });
                                  _loadBforms();
                                },
                                decoration: InputDecoration(
                                  hintText: "Başvuru Ara",
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.grey[500]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
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
                // Form List
                Expanded(
                  child: _isLoading && _bforms.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: Colors.red[400]),
                                  SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Colors.red[600], fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => _loadBforms(),
                                    child: Text('Tekrar Dene'),
                                  ),
                                ],
                              ),
                            )
                          : _bforms.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Başvuru bulunamadı',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _bforms.length + (_hasMoreData ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _bforms.length) {
                                      return _isLoading
                                          ? Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : _hasMoreData
                                              ? Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(16),
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          _loadBforms(
                                                              isLoadMore: true),
                                                      child: Text(
                                                          'Daha Fazla Yükle'),
                                                    ),
                                                  ),
                                                )
                                              : SizedBox.shrink();
                                    }
                                    final bform = _bforms[index];
                                    return _buildFormCard(bform);
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

  Widget _buildFormCard(BformApiModel bform) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showBformAssignmentDetailSheet(
              context: context,
              bform: bform,
              repository: _bformRepository,
              formType: 'sale-request',
              onSaved: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Durum kaydı kaydedildi'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
                setState(() {
                  _currentPage = 1;
                  _bforms.clear();
                  _hasMoreData = true;
                });
                _loadBforms();
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Row with Red Accent
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bform.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bform.mail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info Grid - Clean White Background
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // First Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.phone_outlined,
                              "İletişim Bilgileri",
                              bform.contactInfo,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.category_outlined,
                              "İlan Tipi",
                              _getListingTypeDisplay(bform.listingType),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Second Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.home,
                              "Gayrimenkul Türü",
                              bform.propertyTypeDisplay,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.location_city,
                              "İl/İlçe/Mahalle",
                              bform.districtText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Third Row - Message if exists
                      if (bform.message != null && bform.message!.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: _buildCleanInfoCard(
                                Icons.message_outlined,
                                "Mesaj",
                                bform.message!,
                              ),
                            ),
                          ],
                        ),
                      if (bform.message != null && bform.message!.isNotEmpty)
                        const SizedBox(height: 16),
                      // Fourth Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.person,
                              "İlgili Kişi",
                              bform.relatedPersonName,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.badge_outlined,
                              "İlgili Kişi Tipi",
                              bform.relatedPersonType,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status and Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bform.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              bform.statusDisplay,
                              style: TextStyle(
                                color: bform.statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Başvuru Tarihi",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bform.formattedDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                bform.formattedTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getListingTypeDisplay(String? listingType) {
    if (listingType == null || listingType.isEmpty) {
      return '-';
    }
    switch (listingType.toLowerCase()) {
      case 'satilik':
        return 'Satılık';
      case 'kiralik':
        return 'Kiralık';
      default:
        return listingType.toUpperCase();
    }
  }

  Widget _buildCleanInfoCard(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
