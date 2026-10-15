import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/myfiles/my_files_repository.dart';
import 'package:zecorner/models/myfiles/my_file_model.dart';
import 'package:zecorner/presentation/screens/myfiles/add_my_file_screen.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';

class MyFilesScreen extends StatefulWidget {
  const MyFilesScreen({Key? key}) : super(key: key);

  @override
  State<MyFilesScreen> createState() => _MyFilesScreenState();
}

const Color _myFilesBrandRed = Color(0xFFE53935);
const Color _myFilesProgressTrack = Color(0xFFFFEBEE);

class _MyFilesScreenState extends State<MyFilesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final MyFilesRepository _repository;
  List<MyFileModel> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  String search = '';
  int? _downloadingFileId;
  int? _deletingFileId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _repository = MyFilesRepository(dio: Dio());

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

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMoreData &&
          !_isLoading) {
        _loadFiles(isLoadMore: true);
      }
    });

    _loadFiles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

    final result = await _repository.getMyFiles(
      page: _currentPage,
      pageSize: 10,
      search: search.isEmpty ? null : search,
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

  Future<void> _refresh() async {
    setState(() {
      _currentPage = 1;
      _files.clear();
      _hasMoreData = true;
    });
    await _loadFiles();
  }

  String _savedFilesLocationHint() {
    if (Platform.isIOS) {
      return 'Dosyalar uygulamasında: Uygulamam > Zecorner > Downloads';
    }
    if (Platform.isAndroid) {
      return 'Dosyalar / İndirilenler > Zecorner (veya uygulama klasörü)';
    }
    return 'Uygulama belgeleri klasörü';
  }

  Future<void> _downloadFile(MyFileModel file) async {
    if (_downloadingFileId != null || _deletingFileId != null) return;

    HapticFeedback.lightImpact();
    setState(() => _downloadingFileId = file.id);

    try {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) => Theme(
          data: Theme.of(ctx).copyWith(
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: _myFilesBrandRed,
              circularTrackColor: _myFilesProgressTrack,
            ),
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: _myFilesBrandRed,
                    backgroundColor: _myFilesProgressTrack,
                    strokeWidth: 3.2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'İndiriliyor…\n${file.fileName}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final result = await _repository.downloadFile(file);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('İndirme hatası: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          (savedPath) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF2E7D32),
                duration: const Duration(seconds: 5),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosya kaydedildi: ${file.fileName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _savedFilesLocationHint(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedPath,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beklenmeyen hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFileId = null);
    }
  }

  Future<void> _confirmDelete(MyFileModel file) async {
    if (_deletingFileId != null || _downloadingFileId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dosyayı sil'),
        content: Text('"${file.title}" silinsin mi? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingFileId = file.id);
    final result = await _repository.deleteMyFile(file.id);
    if (!mounted) return;
    setState(() => _deletingFileId = null);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        setState(() => _files.removeWhere((f) => f.id == file.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya silindi'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Dosyalarım');
        },
      ),
      appBar: AdminPanelAppBar(
        title: 'Dosyalarım',
        onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Dosya ara...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading && _files.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _files.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _refresh,
                                child: const Text('Tekrar dene'),
                              ),
                            ],
                          ),
                        )
                      : _files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Henüz dosya bulunmuyor',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _files.length + (_isLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _files.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return _buildFileCard(_files[index]);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddMyFileScreen()),
          );
          if (created == true && mounted) await _refresh();
        },
        backgroundColor: _myFilesBrandRed,
        child: const Icon(Icons.add, color: Colors.white),
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
                  return const AdminNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_advisor')) {
                  return const DanismanNavbar(currentIndex: 0);
                } else if (userRoleCodes.contains('role_office_broker') ||
                    userRoleCodes.contains('role_office_assistant')) {
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

  Widget _buildFileCard(MyFileModel file) {
    final busy = _downloadingFileId == file.id || _deletingFileId == file.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _myFilesBrandRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.insert_drive_file, color: _myFilesBrandRed),
        ),
        title: Text(
          file.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          file.fileName.isNotEmpty ? file.fileName : file.subTitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _myFilesBrandRed,
                    backgroundColor: _myFilesProgressTrack,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: _myFilesBrandRed),
                    tooltip: 'İndir',
                    onPressed: () => _downloadFile(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Sil',
                    onPressed: () => _confirmDelete(file),
                  ),
                ],
              ),
      ),
    );
  }
}
