import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:zecorner/models/bform/bform_api_model.dart';
import 'package:zecorner/infrastructure/bform/bform_api_repository.dart';
import 'package:zecorner/presentation/screens/bform/ofis/add_bform_screen.dart';
import 'package:zecorner/presentation/widgets/bform/bform_assignment_panel.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class BformScreen extends StatefulWidget {
  final String? formType; // 'office', 'advisor', 'sale-request', 'blacklist'
  final String?
      pageTitle; // Sayfa başlığı (opsiyonel, formType'a göre otomatik belirlenir)

  const BformScreen({super.key, this.formType, this.pageTitle});

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
      formType: widget.formType,
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
          // Ofis başvurularında blacklist=true olanları client-side da filtrele
          final filteredData = widget.formType == 'office'
              ? response.data.where((b) => b.blacklist != true).toList()
              : response.data;
          if (!isLoadMore) {
            _bforms = filteredData;
          } else {
            _bforms.addAll(filteredData);
          }
          _currentPage = response.page + 1;
          _totalPages = response.totalPages;
          _hasMoreData = response.page < response.totalPages;
        });
      },
    );
  }

  // Form tipine göre sayfa başlığını döndür
  String _getPageTitle() {
    if (widget.pageTitle != null) {
      return widget.pageTitle!;
    }
    switch (widget.formType) {
      case 'office':
        return 'Ofis Başvuruları';
      case 'advisor':
        return 'Danışman Başvuruları';
      case 'sale-request':
        return 'Satış Talepleri';
      case 'blacklist':
        return 'Kara Liste';
      default:
        return 'Başvuru Formları';
    }
  }

  // Form tipine göre currentPage değerini döndür
  String _getCurrentPage() {
    switch (widget.formType) {
      case 'office':
        return 'Ofis Başvuruları';
      case 'advisor':
        return 'Danışman Başvuruları';
      case 'sale-request':
        return 'Satış Talepleri';
      case 'blacklist':
        return 'Kara Liste';
      default:
        return 'Başvuru Formları';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = _getPageTitle();
    final currentPage = _getCurrentPage();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: currentPage);
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
        title: pageTitle,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      floatingActionButton: widget.formType == 'office'
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddBformScreen(),
                  ),
                );
                if (result == true) {
                  // Refresh list after adding
                  setState(() {
                    _currentPage = 1;
                    _bforms.clear();
                    _hasMoreData = true;
                  });
                  _loadBforms();
                }
              },
              backgroundColor: const Color(0xFFE53935),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              label: const Text(
                "Başvuru Ekle",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
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

  // ─── Bottom Sheet Detail ─────────────────────────────────────────

  void _showBformDetail(BformApiModel bform) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
        height: MediaQuery.of(sheetContext).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE53935).withOpacity(0.15),
                              const Color(0xFFE53935).withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          size: 40,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name & Status
                    Center(
                      child: Column(
                        children: [
                          Text(
                            bform.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: bform.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: bform.statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  bform.statusDisplay,
                                  style: TextStyle(
                                    color: bform.statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildSheetDetailItem(
                            icon: Icons.person_rounded,
                            label: 'Ad Soyad',
                            value: bform.fullName,
                          ),
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.email_rounded,
                            label: 'E-posta',
                            value: bform.mail.isNotEmpty ? bform.mail : '-',
                          ),
                          _buildSheetDivider(),
                          _buildPhoneCallTile(bform),
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.school_rounded,
                            label: 'Eğitim',
                            value: bform.educationDescription ?? '-',
                          ),
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.work_rounded,
                            label: 'Meslek',
                            value: bform.professionDescription ?? '-',
                          ),
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.location_city_rounded,
                            label: 'İl / İlçe',
                            value: bform.districtText.isNotEmpty ? bform.districtText : '-',
                          ),
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.person_pin_rounded,
                            label: 'İlgili Kişi',
                            value: bform.relatedPersonName,
                          ),
                          if (bform.rcTypeDescription != null) ...[
                            _buildSheetDivider(),
                            _buildSheetDetailItem(
                              icon: Icons.badge_rounded,
                              label: 'İlgili Kişi Tipi',
                              value: bform.rcTypeDescription!,
                            ),
                          ],
                          _buildSheetDivider(),
                          _buildSheetDetailItem(
                            icon: Icons.event_rounded,
                            label: 'Başvuru Tarihi',
                            value: DateFormat('dd.MM.yyyy HH:mm').format(bform.createdAt),
                          ),
                          if (bform.updatedAt != null) ...[
                            _buildSheetDivider(),
                            _buildSheetDetailItem(
                              icon: Icons.update_rounded,
                              label: 'Güncelleme Tarihi',
                              value: DateFormat('dd.MM.yyyy HH:mm').format(bform.updatedAt!),
                            ),
                          ],
                          if (bform.rating != null) ...[
                            _buildSheetDivider(),
                            _buildSheetDetailItem(
                              icon: Icons.star_rounded,
                              label: 'Puan',
                              value: bform.rating.toString(),
                            ),
                          ],
                          if (bform.utmCampaign != null && bform.utmCampaign!.isNotEmpty) ...[
                            _buildSheetDivider(),
                            _buildSheetDetailItem(
                              icon: Icons.campaign_rounded,
                              label: 'Kampanya',
                              value: bform.utmCampaign!,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    BformAssignmentPanel(
                      bform: bform,
                      repository: _bformRepository,
                      formType: widget.formType ?? 'office',
                      onSaved: () {
                        // Detay sheet'i kapat → listeye dön + yenile
                        Navigator.of(sheetContext).pop();
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
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    // Üst satır: Düzenle + Sil
                    Row(
                      children: [
                        // Düzenle
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                AppRouter.editBform,
                                arguments: bform,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Düzenle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sil
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Silme işlemi eklenecek
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silme işlemi yakında eklenecek'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete_rounded, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Sil',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Alt satır: Kara Liste (tam genişlik)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showBlacklistConfirmDialog(bform);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bform.blacklist == true
                              ? const Color(0xFF059669) // Yeşil - zaten kara listede, çıkar
                              : const Color(0xFF1F2937), // Koyu - kara listeye ekle
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              bform.blacklist == true
                                  ? Icons.remove_circle_rounded
                                  : Icons.flag_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              bform.blacklist == true
                                  ? 'Kara Listeden Çıkar'
                                  : 'Kara Listeye Ekle',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
      },
    );
  }

  void _showBlacklistConfirmDialog(BformApiModel bform) {
    final isCurrentlyBlacklisted = bform.blacklist == true;
    final actionText = isCurrentlyBlacklisted ? 'Kara Listeden Çıkar' : 'Kara Listeye Ekle';
    final descText = isCurrentlyBlacklisted
        ? 'Bu başvuruyu kara listeden çıkarmak istediğinize emin misiniz?'
        : 'Bu başvuruyu kara listeye eklemek istediğinize emin misiniz?';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCurrentlyBlacklisted
                        ? const Color(0xFF059669).withOpacity(0.1)
                        : const Color(0xFF1F2937).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCurrentlyBlacklisted ? Icons.remove_circle_rounded : Icons.flag_rounded,
                    color: isCurrentlyBlacklisted
                        ? const Color(0xFF059669)
                        : const Color(0xFF1F2937),
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  descText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 16),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildConfirmRow('Ad Soyad:', bform.fullName),
                      const SizedBox(height: 10),
                      _buildConfirmRow('E-posta:', bform.mail),
                      const SizedBox(height: 10),
                      _buildConfirmRow('Durum:', bform.statusDisplay),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _performBlacklistToggle(bform);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentlyBlacklisted
                              ? const Color(0xFF059669)
                              : const Color(0xFF1F2937),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isCurrentlyBlacklisted ? 'Evet, Çıkar' : 'Evet, Ekle',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performBlacklistToggle(BformApiModel bform) async {
    final newBlacklistStatus = !(bform.blacklist == true);

    // Loading göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(newBlacklistStatus ? 'Kara listeye ekleniyor...' : 'Kara listeden çıkarılıyor...'),
          ],
        ),
        backgroundColor: const Color(0xFF1F2937),
        duration: const Duration(seconds: 10),
      ),
    );

    final result = await _bformRepository.toggleBlacklist(
      formId: bform.id,
      blacklist: newBlacklistStatus,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Hata: ${failure.message}')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(newBlacklistStatus
                    ? 'Başvuru kara listeye eklendi'
                    : 'Başvuru kara listeden çıkarıldı'),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Listeyi yenile
        setState(() {
          _currentPage = 1;
          _bforms.clear();
          _hasMoreData = true;
        });
        _loadBforms();
      },
    );
  }

  bool _canCallBform(BformApiModel bform) {
    return bform.currentStatus.toLowerCase() == 'not-interviewed' &&
        bform.phone.isNotEmpty;
  }

  Future<void> _launchPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    if (cleaned.isEmpty || cleaned == '-') return;

    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon uygulaması bulunamadı'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPhoneCallTile(BformApiModel bform) {
    final phone = bform.phone.isNotEmpty ? bform.phone : '-';
    final canCall = _canCallBform(bform);

    if (!canCall) {
      return _buildSheetDetailItem(
        icon: Icons.phone_rounded,
        label: 'Telefon',
        value: phone,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchPhone(bform.phone),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFFE53935).withOpacity(0.12),
                const Color(0xFFE53935).withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE53935).withOpacity(0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Telefon',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Aramak için dokunun',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ara',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
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

  Widget _buildSheetDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey.shade200, height: 1),
    );
  }

  // ─── Card Widget ──────────────────────────────────────────────────

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
          onTap: () => _showBformDetail(bform),
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
                          Icons.business,
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
                            child: _canCallBform(bform)
                                ? _buildCallableContactCard(bform)
                                : _buildCleanInfoCard(
                                    Icons.phone_outlined,
                                    "İletişim Bilgileri",
                                    bform.contactInfo,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.home,
                              "Konut Türü",
                              bform.propertyTypeDisplay,
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
                              Icons.location_city,
                              "İl/İlçe/Mahalle",
                              bform.districtText,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.person,
                              "İlgili Kişi",
                              bform.relatedPersonName,
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

  Widget _buildCallableContactCard(BformApiModel bform) {
    return GestureDetector(
      onTap: () => _launchPhone(bform.phone),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE53935).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hemen Ara',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              bform.phone,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
