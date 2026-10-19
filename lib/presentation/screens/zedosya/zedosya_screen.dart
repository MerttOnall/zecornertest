import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/screens/zedosya/edit_zedosya_screen.dart';
import 'package:zecorner/presentation/screens/zedosya/add_zedosya_screen.dart';
import 'package:zecorner/models/zedosya/zedosya_api_model.dart';
import 'package:zecorner/infrastructure/zedosya/zedosya_api_repository.dart';
import 'package:dio/dio.dart';
import 'package:zecorner/core/utils/image_utils.dart';

class ZeDosyaScreen extends StatefulWidget {
  const ZeDosyaScreen({Key? key}) : super(key: key);

  @override
  State<ZeDosyaScreen> createState() => _ZeDosyaScreenState();
}

class _ZeDosyaScreenState extends State<ZeDosyaScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // API related variables
  late final ZeDosyaApiRepository _zeDosyaRepository;
  List<ZeDosyaApiModel> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  final List<String> categories = ['Hepsi', 'Word', 'Excel', 'PNG'];
  String selectedCategory = 'Hepsi';
  String search = '';

  /// Ekleme, indirme ve düzenleme yalnız admin. Diğer ünvanlar listeyi görür.
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _canManage = context.read<AuthCubit>().isAdmin;
    _loadAccess();

    // Initialize repository
    _zeDosyaRepository = ZeDosyaApiRepository(dio: Dio());

    // Search listener
    _searchController.addListener(() {
      if (_searchController.text != search) {
        setState(() {
          search = _searchController.text;
          _currentPage = 1;
          _files.clear();
          _hasMoreData = true;
        });
        _loadFiles();
      }
    });

    // Scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && 
          _hasMoreData && !_isLoading) {
        _loadFiles(isLoadMore: true);
      }
    });

    // Initial load
    _loadFiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final roles = prefs.getStringList('userRoleCodes') ?? [];
    final permissions = (prefs.getString('userPermissions') ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    final isAdmin = prefs.getBool('userIsAdmin') == true ||
        roles.contains('role_admin') ||
        (mounted && context.read<AuthCubit>().isAdmin);
    if (!mounted) return;
    setState(() {
      _canManage = RoleSidebar.allows(
        'admin_only',
        isAdmin: isAdmin,
        roleCodes: roles,
        permissions: permissions,
      );
    });
  }

  Future<void> _loadFiles({bool isLoadMore = false}) async {
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

    final result = await _zeDosyaRepository.getZeDosyaFiles(
      page: _currentPage,
      limit: 10,
      search: search.isEmpty ? null : search,
      category: selectedCategory,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
          if (!isLoadMore) _files.clear();
        });
      },
      (response) {
        setState(() {
          _isLoading = false;
          if (!isLoadMore) {
            _files = response.data;
          } else {
            _files.addAll(response.data);
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
      // Role sistemine göre sidebar seçimi
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'ZeDosya');
        },
      ),
      appBar: AdminPanelAppBar(
        title: "ZeDosya",
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern Header with Gradient
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red[600]!,
                      Colors.red[700]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dosyalarınız',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_files.length} dosya',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Modern Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                        child: TextField(
                          controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Dosyalarda ara...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          prefixIcon: Container(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Category Filter Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kategoriler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == selectedCategory;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategory = category;
                                _currentPage = 1;
                                _files.clear();
                                _hasMoreData = true;
                              });
                              _loadFiles();
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red[600] : Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected ? Colors.red[600]! : Colors.grey[200]!,
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  Text(
                                    category,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
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
              ),
            ),
            
            if (_canManage)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red[600]!, Colors.red[700]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (context) => const AddZeDosyaScreen()),
                        );
                        if (created == true && mounted) {
                          setState(() {
                            _currentPage = 1;
                            _files.clear();
                            _hasMoreData = true;
                          });
                          _loadFiles();
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Yeni Dosya Ekle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Files List
            _isLoading && _files.isEmpty
                ? SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadFiles(),
                                child: Text('Tekrar Dene'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _files.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == _files.length) {
                                    return _isLoading
                                        ? Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        : _hasMoreData
                                            ? Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(16),
                                                  child: ElevatedButton(
                                                    onPressed: () => _loadFiles(isLoadMore: true),
                                                    child: Text('Daha Fazla Yükle'),
                                                  ),
                                                ),
                                              )
                                            : SizedBox.shrink();
                                  }
                                  final file = _files[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: ModernFileCard(
                                      file: file,
                                      canManage: _canManage,
                                      onUpdated: () {
                                        setState(() {
                                          _currentPage = 1;
                                          _files.clear();
                                          _hasMoreData = true;
                                        });
                                        _loadFiles();
                                      },
                                    ),
                                  );
                                },
                                childCount: _files.length + (_hasMoreData ? 1 : 0),
                              ),
                            ),
                          ),
          ],
        ),
      ),
      // Role sistemine göre navbar seçimi
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
                
                // Web sitesindeki mantığa göre navbar seçimi
                if (userRoleCodes.contains('role_admin')) {
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') || userRoleCodes.contains('role_office_assistant')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_form_applications') || userRoleCodes.contains('role_form_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_sale_applications') || userRoleCodes.contains('role_sale_applications_admin')) {
                  return const BrokerNavbar(currentIndex: 0);
                } else {
                  return const FrancahiseNavbar(currentIndex: 0);
                }
              },
            );
          }
          return const AdminNavbar(currentIndex: 0);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Dosya bulunamadı',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirmeyi deneyin',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class ModernFileCard extends StatefulWidget {
  final ZeDosyaApiModel file;
  final bool canManage;
  final VoidCallback? onUpdated;

  const ModernFileCard({
    required this.file,
    this.canManage = false,
    this.onUpdated,
    Key? key,
  }) : super(key: key);

  @override
  State<ModernFileCard> createState() => _ModernFileCardState();
}

class _ModernFileCardState extends State<ModernFileCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color getTypeColor() {
    switch (widget.file.subTitle.toLowerCase()) {
      case 'word':
        return const Color(0xFF1976D2);
      case 'excel':
        return const Color(0xFF43A047);
      case 'png':
        return const Color(0xFFE53935);
      default:
        return Colors.grey[400]!;
    }
  }

  IconData getTypeIcon() {
    switch (widget.file.subTitle.toLowerCase()) {
      case 'word':
        return Icons.description_rounded;
      case 'excel':
        return Icons.grid_on_rounded;
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _downloadFile(ZeDosyaApiModel file) async {
    try {
      HapticFeedback.lightImpact();
      
      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'İndiriliyor...',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );

      // Repository oluştur ve dosyayı indir
      final repository = ZeDosyaApiRepository(dio: Dio());
      final result = await repository.downloadFile(file);

      // Loading dialog'u kapat
      Navigator.of(context).pop();

      result.fold(
        (failure) {
          // Hata durumu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İndirme hatası: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (filePath) {
          // Başarılı indirme
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dosya başarıyla indirildi: ${file.fileName}'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Loading dialog'u kapat
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: getTypeColor().withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey[100]!,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // Dosya detayına git
                  print('File tapped: ${widget.file.title}');
                },
                onTapDown: (_) {
                  _animationController.forward();
                },
                onTapUp: (_) {
                  _animationController.reverse();
                },
                onTapCancel: () {
                  _animationController.reverse();
                },
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // File Icon/Thumbnail with Modern Design
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              getTypeColor().withOpacity(0.1),
                              getTypeColor().withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: getTypeColor().withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ImageUtils.isValidS3Id(widget.file.thumbnail)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.file.thumbnailUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: getTypeColor(),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      getTypeIcon(),
                                      color: getTypeColor(),
                                      size: 32,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                getTypeIcon(),
                                color: getTypeColor(),
                                size: 32,
                              ),
                      ),
                      SizedBox(width: 20),
                      
                      // File Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.file.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: getTypeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: getTypeColor().withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.file.subTitle.toUpperCase(),
                                style: TextStyle(
                                  color: getTypeColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (widget.canManage)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: getTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: getTypeColor().withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.download_rounded,
                                color: getTypeColor(),
                                size: 20,
                              ),
                              onPressed: () => _downloadFile(widget.file),
                              tooltip: 'İndir',
                              padding: EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: getTypeColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: getTypeColor().withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.edit_rounded,
                                color: getTypeColor(),
                                size: 20,
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final updated = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditZeDosyaScreen(file: widget.file),
                                  ),
                                );
                                if (updated == true) {
                                  widget.onUpdated?.call();
                                }
                              },
                              tooltip: 'Düzenle',
                              padding: EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
