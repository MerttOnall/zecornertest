import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/infrastructure/users/users_repository.dart';
import 'package:zecorner/presentation/screens/users/add_user_screen.dart';
import 'package:zecorner/presentation/screens/users/edit_user_screen.dart';
import 'package:zecorner/presentation/screens/users/edit_user_args.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/users/users_model.dart';
import 'package:zecorner/core/error/failures.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with TickerProviderStateMixin {
  static const Color _primary = Color(0xFFE53935);
  static const Color _primaryLight = Color(0xFFFFEBEE);
  static const Color _textPrimary = Color(0xFF1A1D2E);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _surface = Color(0xFFF8F9FB);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;

  final UsersRepository _usersRepository = UsersRepository();
  final ContactApiRepository _contactRepository = ContactApiRepository();
  List<UserModel> _users = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedStatus = 'Tümü';
  int _loadRequestId = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _statusOptions = ['Tümü', 'Aktif', 'Pasif'];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _loadUsers(refresh: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Karttaki Aktif/Pasif rozeti ile aynı alan: `status == 1`.
  bool _matchesStatus(UserModel user, String status) {
    switch (status) {
      case 'Aktif':
        return user.isActive;
      case 'Pasif':
        return !user.isActive;
      default:
        return true;
    }
  }

  /// Durum sunucudan gelir; arama yalnızca o listenin içinde.
  List<UserModel> get _visibleUsers {
    final matched =
        _users.where((user) => _matchesStatus(user, _selectedStatus));
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return matched.toList();
    return matched.where((u) {
      return u.title.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.tel.toLowerCase().contains(q) ||
          u.contactNo.toString().contains(q) ||
          u.roleDescription.toLowerCase().contains(q);
    }).toList();
  }

  int get _activeFilterCount => _selectedStatus == 'Tümü' ? 0 : 1;

  Future<void> _loadUsers({
    bool refresh = false,
    bool keepPreviousListWhileLoading = false,
  }) async {
    // Yenileme dışında, devam eden yüklemeyi bozma
    if (_isLoading && !refresh) return;

    final requestId = ++_loadRequestId;
    final status = _selectedStatus;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (refresh && !keepPreviousListWhileLoading) {
        _users = [];
      }
    });

    try {
      const pageSize = 100;
      const maxPages = 30;
      final collected = <UserModel>[];
      final seenIds = <String>{};
      var page = 1;
      var totalPages = 1;

      while (page <= totalPages && page <= maxPages) {
        final result = await _usersRepository.getUsers(
          page: page,
          limit: pageSize,
          status: status,
        );

        if (!mounted || requestId != _loadRequestId) return;

        final failed = result.fold<Failure?>((failure) => failure, (_) => null);
        if (failed != null) {
          if (collected.isEmpty) {
            setState(() {
              _isLoading = false;
              _errorMessage = _getErrorMessage(failed);
              if (refresh) _users = [];
            });
            return;
          }
          break;
        }

        final response = result.getOrElse(
          () => UsersResponseModel(
            users: const [],
            totalCount: 0,
            totalPages: 1,
            page: page,
          ),
        );
        var newOnPage = 0;
        for (final user in response.users) {
          if (!seenIds.add(user.userId)) continue;
          newOnPage++;
          if (_matchesStatus(user, status)) collected.add(user);
        }

        final reportedPages = response.totalPages < 1 ? 1 : response.totalPages;
        totalPages = reportedPages;
        final lastPage = response.users.isEmpty ||
            response.users.length < pageSize ||
            page >= reportedPages ||
            newOnPage == 0;
        if (lastPage) break;
        page++;
      }

      if (!mounted || requestId != _loadRequestId) return;

      setState(() {
        _isLoading = false;
        _users = collected;
      });
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  Future<void> _updateUserStatus(UserModel user, bool isActive) async {
    final result = await _contactRepository.updateContactStatus(
      contactId: user.contactNo,
      isActive: isActive,
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(failure)),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        if (!success || !mounted) return;
        setState(() {
          final index = _users.indexWhere((u) => u.userId == user.userId);
          if (index != -1) {
            _users[index] = UserModel(
              userId: user.userId,
              userStatus: isActive ? 1 : 0,
              contactNo: user.contactNo,
              title: user.title,
              type: user.type,
              email: user.email,
              tel: user.tel,
              status: isActive ? 1 : 0,
              picture: user.picture,
              roles: user.roles,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kullanıcı durumu ${isActive ? "aktif" : "pasif"} olarak güncellendi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is AuthFailure) {
      return 'Kimlik doğrulama hatası: ${failure.message}';
    } else if (failure is NetworkFailure) {
      return 'Ağ bağlantısı hatası: ${failure.message}';
    } else if (failure is ServerFailure) {
      return 'Sunucu hatası: ${failure.message}';
    }
    return 'Hata: ${failure.message}';
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  void _onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
    _loadUsers(refresh: true);
  }

  void _clearStatusFilter() {
    if (_selectedStatus == 'Tümü') return;
    _onStatusChanged('Tümü');
  }

  EditUserArgs _convertToEditUserArgs(UserModel userModel) {
    final nameParts = userModel.title.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return EditUserArgs(
      id: userModel.userId,
      firstName: firstName,
      lastName: lastName,
      email: userModel.email,
      phone: userModel.tel == '0' ? '' : userModel.tel,
      userNumber: userModel.contactNo.toString(),
      role: userModel.roleDescription,
      isActive: userModel.isActive,
    );
  }

  void _showFilterSheet() {
    String draftStatus = _selectedStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtreler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                        color: _textSecondary,
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Durum',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._statusOptions.map((status) {
                    final selected = draftStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setSheetState(() => draftStatus = status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? _primary.withOpacity(0.4)
                                    : _border,
                              ),
                              color: selected ? _primaryLight : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  status == 'Aktif'
                                      ? Icons.check_circle_outline_rounded
                                      : status == 'Pasif'
                                          ? Icons.pause_circle_outline_rounded
                                          : Icons.people_outline_rounded,
                                  color: selected ? _primary : _textMuted,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? _primary
                                          : _textPrimary,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: _primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _onStatusChanged('Tümü');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary, width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Temizle',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _onStatusChanged(draftStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Uygula',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAddUser() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AddUserScreen(),
      ),
    );
    if (mounted) {
      _loadUsers(refresh: true, keepPreviousListWhileLoading: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return RoleSidebar(currentPage: 'Kullanıcılar');
        },
      ),
      onDrawerChanged: (isOpened) {
        setState(() => _isDrawerOpen = isOpened);
      },
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
      appBar: AdminPanelAppBar(
        title: 'Kullanıcılar',
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
                _buildFilterBar(),
                Expanded(child: _buildUserList()),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Ad, e-posta, telefon ara...',
                      hintStyle: const TextStyle(
                        color: _textMuted,
                        fontSize: 14.5,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _textMuted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _showFilterSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.tune_rounded, color: _primary),
                      ),
                    ),
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_activeFilterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Material(
                color: _primary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _openAddUser,
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedStatus != 'Tümü') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(
                  _selectedStatus,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                avatar: Icon(
                  _selectedStatus == 'Aktif'
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_filled_rounded,
                  size: 16,
                  color: _primary,
                ),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _primary,
                ),
                onDeleted: _clearStatusFilter,
                backgroundColor: _primaryLight,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final visible = _visibleUsers;

    if (_isLoading && _users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: _textMuted),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 15, color: _textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadUsers(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[350]),
            const SizedBox(height: 16),
            const Text(
              'Kullanıcı bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedStatus != 'Tümü'
                  ? 'Filtreyi değiştirip tekrar deneyin'
                  : 'Henüz listelenecek kullanıcı yok',
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          _loadUsers(refresh: true, keepPreviousListWhileLoading: true),
      color: _primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: visible.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
            );
          }
          return _buildUserCard(visible[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isActive = user.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final args = _convertToEditUserArgs(user);
            await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                settings: RouteSettings(arguments: args),
                builder: (context) => const EditUserScreen(),
              ),
            );
            if (mounted) {
              _loadUsers(
                refresh: true,
                keepPreviousListWhileLoading: true,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
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
                            user.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Kişi No: ${user.contactNo}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _updateUserStatus(user, !isActive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF10B981).withOpacity(0.35)
                                : const Color(0xFFEF4444).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                                fontSize: 12,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              Icons.email_outlined,
                              'E-posta',
                              user.email,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoTile(
                              Icons.phone_outlined,
                              'Telefon',
                              user.tel == '0' ? 'Belirtilmemiş' : user.tel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              size: 16,
                              color: _primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.roleDescription,
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                color: _textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
