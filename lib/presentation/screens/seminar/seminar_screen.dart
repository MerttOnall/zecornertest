import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/infrastructure/seminar/seminar_repository.dart';
import 'package:zecorner/models/seminar/seminar_model.dart';
import 'package:zecorner/presentation/screens/seminar/widgets/seminar_event_card.dart';
import 'package:zecorner/presentation/screens/seminar/widgets/seminar_manage_card.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/router/app_router.dart';

enum SeminarListStyle { showcase, manage }

class SeminarScreen extends StatefulWidget {
  final String? type;
  final String title;
  final String currentPage;
  final SeminarListStyle style;

  const SeminarScreen({
    Key? key,
    this.type,
    this.title = 'Seminer ve Eğitimler',
    this.currentPage = 'Seminer ve Eğitimler',
    this.style = SeminarListStyle.showcase,
  }) : super(key: key);

  @override
  State<SeminarScreen> createState() => _SeminarScreenState();
}

class _SeminarScreenState extends State<SeminarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SeminarRepository _seminarRepository = SeminarRepository();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isDrawerOpen = false;
  bool _canManage = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Seminar> _seminars = [];

  int _page = 1;
  int _totalCount = 0;
  String? _typeFilter;
  Timer? _searchDebounce;

  bool get _isEducationPage => widget.type == 'education';
  bool get _hasFixedType => widget.type == 'event' || widget.type == 'education';
  bool get _isManage => widget.style == SeminarListStyle.manage;
  int get _pageSize => _hasFixedType ? 12 : 10;

  @override
  void initState() {
    super.initState();
    _typeFilter = widget.type;
    _scrollController.addListener(_onScroll);
    _canManage = context.read<AuthCubit>().isAdmin;
    _loadAccess();
    _loadSeminars(refresh: true);
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasMore => _seminars.length < _totalCount;

  void _onScroll() {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _loadSeminars();
    }
  }

  Future<void> _loadSeminars({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      setState(() {
        if (_seminars.isEmpty) _isLoading = true;
        _errorMessage = null;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _seminarRepository.getSeminars(
        page: _page,
        pageSize: _pageSize,
        type: _hasFixedType ? widget.type : _typeFilter,
        searchText: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = failure.message;
          });
        },
        (response) {
          setState(() {
            if (refresh) {
              _seminars = response.data;
            } else {
              _seminars = [..._seminars, ...response.data];
            }
            _totalCount = response.totalCount;
            _page = refresh ? 2 : _page + 1;
            _isLoading = false;
            _isLoadingMore = false;
            _errorMessage = null;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = 'Seminerler yüklenirken bir hata oluştu: $e';
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadSeminars(refresh: true);
    });
    setState(() {});
  }

  void _onTypeFilterChanged(String? type) {
    if (_typeFilter == type) return;
    setState(() => _typeFilter = type);
    _loadSeminars(refresh: true);
  }

  void _openDetail(Seminar seminar) {
    Navigator.pushNamed(
      context,
      AppRouter.seminarDetail,
      arguments: seminar,
    );
  }

  void _showSeminarOptionsMenu(BuildContext context, Seminar seminar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined, color: Color(0xFFE53935)),
              title: const Text('Detay', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _openDetail(seminar);
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFE53935)),
              title: const Text('Düzenle', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.editSeminar, arguments: seminar);
              },
            ),
            Divider(height: 1, color: Colors.grey[200]),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, seminar);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Seminar seminar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Semineri Sil'),
        content: Text('${seminar.title} seminerini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Seminer silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          final authCubit = context.read<AuthCubit>();
          return FutureBuilder<List<String>>(
            future: authCubit.getUserRoleCodes(),
            builder: (context, snapshot) {
              final userRoleCodes = snapshot.data ?? [];
              if (userRoleCodes.contains('role_admin')) {
                return const AdminNavbar(currentIndex: 0);
              } else if (userRoleCodes.contains('role_advisor')) {
                return const DanismanNavbar(currentIndex: 0);
              } else if (userRoleCodes.contains('role_office_broker') ||
                  userRoleCodes.contains('role_office_assistant')) {
                return const BrokerNavbar(currentIndex: 0);
              }
              return const FrancahiseNavbar(currentIndex: 0);
            },
          );
        }
        return const AdminNavbar(currentIndex: 0);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7FB),
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: widget.currentPage);
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() => _isDrawerOpen = isOpened);
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: widget.title,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      floatingActionButton: _isManage && _canManage
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFE53935),
              onPressed: () => Navigator.pushNamed(context, AppRouter.addSeminar),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Yeni Etkinlik',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: _buildNavbar(),
      body: GestureDetector(
        onTap: () {
          if (_isDrawerOpen) {
            _scaffoldKey.currentState?.closeDrawer();
          }
          FocusScope.of(context).unfocus();
        },
        child: AbsorbPointer(
          absorbing: _isDrawerOpen,
          child: RefreshIndicator(
            onRefresh: () => _loadSeminars(refresh: true),
            color: const Color(0xFFE53935),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        _SearchField(
                          controller: _searchController,
                          hintText: _hasFixedType || _isManage
                              ? 'Arayın...'
                              : 'Seminer, eğitim veya etkinlik ara...',
                          searchIconTrailing: _hasFixedType || _isManage,
                          highlightedBorder: _hasFixedType,
                          onChanged: _onSearchChanged,
                          onClear: () {
                            _searchController.clear();
                            _loadSeminars(refresh: true);
                            setState(() {});
                          },
                        ),
                        if (!_hasFixedType && !_isManage) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _TypeChip(
                                label: 'Tümü',
                                selected: _typeFilter == null,
                                onTap: () => _onTypeFilterChanged(null),
                              ),
                              const SizedBox(width: 8),
                              _TypeChip(
                                label: 'Etkinlik',
                                selected: _typeFilter == 'event',
                                onTap: () => _onTypeFilterChanged('event'),
                              ),
                              const SizedBox(width: 8),
                              _TypeChip(
                                label: 'Eğitim',
                                selected: _typeFilter == 'education',
                                onTap: () => _onTypeFilterChanged('education'),
                              ),
                            ],
                          ),
                        ],
                        if (_isManage && !_isLoading && _seminars.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 14, left: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$_totalCount kayıt',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFE53935)),
                    ),
                  )
                else if (_errorMessage != null && _seminars.isEmpty)
                  SliverFillRemaining(child: _ErrorState(
                    message: _errorMessage!,
                    onRetry: () => _loadSeminars(refresh: true),
                  ))
                else if (_seminars.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      title: _isManage
                          ? 'Henüz etkinlik veya eğitim yok'
                          : (_isEducationPage
                              ? 'Henüz eğitim yok'
                              : 'Henüz seminer yok'),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _seminars.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE53935),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          final seminar = _seminars[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: _isManage ? 12 : 16),
                            child: _isManage
                                ? SeminarManageCard(
                                    seminar: seminar,
                                    onTap: () => _openDetail(seminar),
                                    onOptionsPressed: _canManage
                                        ? () => _showSeminarOptionsMenu(
                                              context,
                                              seminar,
                                            )
                                        : null,
                                  )
                                : SeminarEventCard(
                                    seminar: seminar,
                                    showTypeBadge: !_hasFixedType,
                                    showInstructors: true,
                                    showQuotaBar: !_isEducationPage,
                                    showCta: _canManage,
                                    onTap: () => _openDetail(seminar),
                                    onCtaPressed: _canManage
                                        ? () => _openDetail(seminar)
                                        : null,
                                  ),
                          );
                        },
                        childCount: _seminars.length + (_isLoadingMore ? 1 : 0),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;
  final bool searchIconTrailing;
  final bool highlightedBorder;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Seminer, eğitim veya etkinlik ara...',
    this.searchIconTrailing = false,
    this.highlightedBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: searchIconTrailing
              ? null
              : const Icon(Icons.search_rounded, color: Color(0xFFE53935)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClear,
                )
              : (searchIconTrailing
                  ? const Icon(Icons.search_rounded, color: Color(0xFFE53935))
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: highlightedBorder
                ? const BorderSide(color: Color(0xFFE53935), width: 1.4)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: highlightedBorder
                ? const BorderSide(color: Color(0xFFE53935), width: 1.4)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.6),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: searchIconTrailing ? 18 : 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE53935) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFE53935) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({this.title = 'Henüz seminer yok'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 48,
                color: const Color(0xFFE53935).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filtreleri değiştirin veya aşağı çekerek yenileyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
