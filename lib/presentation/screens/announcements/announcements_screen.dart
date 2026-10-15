import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/cubit/announcement_cubit.dart';
import 'package:zecorner/infrastructure/announcement/announcement_api_repository.dart';
import 'package:zecorner/models/announcement/announcement_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/danisman_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/broker_navbar.dart';
import 'package:zecorner/presentation/widgets/navbar/francahise_navbar.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  late AnnouncementCubit _announcementCubit;
  String search = '';

  @override
  void initState() {
    super.initState();
    _announcementCubit = AnnouncementCubit(AnnouncementApiRepository());
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Önce contact types'ı yükle, sonra announcements'ı yükle
    await _announcementCubit.loadContactTypes();
    await _announcementCubit.loadAnnouncements(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _announcementCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _announcementCubit.loadMoreAnnouncements();
    }
  }

  String formatDateRange(Announcement announcement) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return '${formatter.format(announcement.startTime.toLocal())} - ${formatter.format(announcement.endTime.toLocal())}';
  }

  Widget _buildContent(AnnouncementState state) {
    if (state is AnnouncementLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE53935),
        ),
      );
    } else if (state is AnnouncementLoaded) {
      if (state.allAnnouncements.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.announcement_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz duyuru bulunmuyor',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aşağı çekerek yenileyin',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      return ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.allAnnouncements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, i) {
          final announcement = state.allAnnouncements[i];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/edit-announcement',
                arguments: {
                  'id': announcement.id,
                  'title': announcement.title,
                  'category': announcement.categoryDescription,
                  'startTime': announcement.startTime,
                  'endTime': announcement.endTime,
                  'contactTypes': announcement.contactTypes,
                  'state': announcement.state,
                },
              );
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey[200]!, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF23263B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Kategori
                        Text(
                          announcement.categoryDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Contact Types (Roller)
                        if (_announcementCubit.contactTypes.isNotEmpty && announcement.contactTypes.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: () {
                                  // Tüm roller seçiliyse sadece "Herkes" göster
                                  if (announcement.contactTypes.length == _announcementCubit.contactTypes.length) {
                                    return [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          'Herkes',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ];
                                  }
                                  
                                  // Maksimum 3 rol göster
                                  final visibleRoles = announcement.contactTypes.take(3).toList();
                                  final hasMore = announcement.contactTypes.length > 3;
                                  
                                  final widgets = visibleRoles.map((contactTypeId) {
                                    final contactTypeName = _announcementCubit.getContactTypeName(contactTypeId);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        contactTypeName,
                                        style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                  
                                  // Eğer daha fazla rol varsa "..." ekle
                                  if (hasMore) {
                                    widgets.add(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.10),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          '...',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return widgets;
                                }(),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        // Tarih aralığı
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              formatDateRange(announcement),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF23263B),
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
          );
        },
      );
    } else if (state is AnnouncementError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.failure.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aşağı çekerek yenileyin',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _announcementCubit.loadAnnouncements(refresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                    ),
                    child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _announcementCubit,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
      // Role sistemine göre sidebar seçimi
      drawer: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // RoleSidebar - API'den gelen role ve permission'lara göre dinamik sidebar
          return RoleSidebar(currentPage: 'Duyurular');
        },
      ),
      drawerScrimColor: Colors.black54,
      drawerEdgeDragWidth: 0,
        appBar: AdminPanelAppBar(
          title: "Duyurular",
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Add Button Section
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (v) {
                          setState(() => search = v);
                          _announcementCubit.searchAnnouncements(v);
                        },
                        decoration: InputDecoration(
                          hintText: 'Duyuru Ara...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/add-announcement');
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: const Text(
                          'Yeni Duyuru Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Kartlar
              Expanded(
                child: BlocConsumer<AnnouncementCubit, AnnouncementState>(
                  listener: (context, state) {
                    if (state is AnnouncementError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.failure.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await _announcementCubit.refreshAnnouncements();
                      },
                      color: const Color(0xFFE53935),
                      child: _buildContent(state),
                    );
                  },
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
                  print('Announcements Screen - Bottom Navbar - User Role Codes: $userRoleCodes');
                  
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
      ),
    );
  }
}
