import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/core/utils/image_utils.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/infrastructure/myoffice/myoffice_api_repository.dart';
import 'package:zecorner/infrastructure/office_persons/office_persons_api_repository.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/models/myoffice/myoffice_api_model.dart';
import 'package:zecorner/models/office_persons/office_persons_api_model.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';
import 'package:zecorner/router/app_router.dart';

// Person model for office staff
class OfficePerson {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String office;
  final String personNo;
  final String userType;
  final String status;
  final int? statusCode;
  final String registrationDate;
  final String personCount;
  final bool isActive;

  OfficePerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.office,
    required this.personNo,
    required this.userType,
    required this.status,
    this.statusCode,
    required this.registrationDate,
    required this.personCount,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName';
}

class MyofficesScreen extends StatefulWidget {
  const MyofficesScreen({super.key});

  @override
  State<MyofficesScreen> createState() => _MyofficesScreenState();
}

class _MyofficesScreenState extends State<MyofficesScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  late final AnimationController _rotationController;
  late final AnimationController _floatingController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // API related variables
  late final MyOfficeApiRepository _myOfficeRepository;
  late final OfficePersonsApiRepository _officePersonsRepository;
  late final ContactApiRepository _contactTypeRepository;
  MyOfficeApiModel? _myOffice;
  List<OfficePersonsApiModel> _officePersons = [];
  bool _isLoading = true;
  bool _isLoadingPersons = true;
  String? _errorMessage;
  String? _personsErrorMessage;

  // Search and filter — web "Ofise Bağlı Kişiler" ile aynı tür sırası
  static const String _noTypeSelected = 'Seçilen Kişi türü yok...';
  static const List<String> _preferredPersonTypeOrder = [
    'Broker',
    'Gayrimenkul Danışmanı',
    'Takım Lideri',
    'Ofis Asistanı',
    'Broker Asistanı',
    'Gayrimenkul Danışmanı (Eğitim Aşamasında)',
    'Gayrimenkul Danışmanı Asistanı',
    'Ofis Direktörü',
    'Saha Direktörü',
  ];
  static const Map<String, int> _fallbackTypeCodes = {
    'Broker': 10,
    'Gayrimenkul Danışmanı': 11,
    'Ofis Asistanı': 12,
    'Takım Lideri': 13,
    'Saha Direktörü': 19,
  };

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  String _searchQuery = '';
  String _selectedUserType = _noTypeSelected;
  int? _selectedTypeCode;
  List<ContactTypeModel> _personTypes = [];

  @override
  void initState() {
    super.initState();

    _myOfficeRepository = MyOfficeApiRepository(
      dio: Dio(),
    );

    _officePersonsRepository = OfficePersonsApiRepository();
    _contactTypeRepository = ContactApiRepository();

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

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _loadPersonTypes();
    _loadMyOffice();
    _loadOfficePersons();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _rotationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonTypes() async {
    final result = await _contactTypeRepository.getContactTypes();
    result.fold(
      (failure) {
        print('❌ Ofis kişi türleri yüklenemedi: ${failure.message}');
        _applyFallbackPersonTypes();
      },
      (response) {
        final active = response.contactTypes
            .where((t) => t.status == null || t.status == 1)
            .toList();

        final matched = <ContactTypeModel>[];
        for (final name in _preferredPersonTypeOrder) {
          ContactTypeModel? found;
          for (final type in active) {
            if (type.description.trim().toLowerCase() == name.toLowerCase()) {
              found = type;
              break;
            }
          }
          if (found != null) {
            matched.add(found);
          } else if (_fallbackTypeCodes.containsKey(name)) {
            matched.add(
              ContactTypeModel(
                code: _fallbackTypeCodes[name]!,
                description: name,
                isCompany: false,
                isEmployee: true,
                isAgency: false,
                isCustomer: false,
                isAdmin: false,
                isAgencyEmployee: true,
                status: 1,
              ),
            );
          }
        }

        if (matched.isEmpty) {
          _applyFallbackPersonTypes();
          return;
        }

        if (mounted) {
          setState(() => _personTypes = matched);
        }
        print('✅ Ofis kişi türleri: ${matched.map((t) => '${t.code}:${t.description}').join(', ')}');
      },
    );
  }

  void _applyFallbackPersonTypes() {
    final fallback = _preferredPersonTypeOrder
        .where((name) => _fallbackTypeCodes.containsKey(name))
        .map(
          (name) => ContactTypeModel(
            code: _fallbackTypeCodes[name]!,
            description: name,
            isCompany: false,
            isEmployee: true,
            isAgency: false,
            isCustomer: false,
            isAdmin: false,
            isAgencyEmployee: true,
            status: 1,
          ),
        )
        .toList();
    if (mounted) {
      setState(() => _personTypes = fallback);
    }
  }

  Future<void> _loadMyOffice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _myOfficeRepository.getMyOffice();
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(failure);
        });
      },
      (myOffice) {
        setState(() {
          _isLoading = false;
          _myOffice = myOffice;
        });
      },
    );
  }

  Future<void> _loadOfficePersons() async {
    setState(() {
      _isLoadingPersons = true;
      _personsErrorMessage = null;
    });

    final selectedTypes = _getSelectedTypes();
    final result = await _officePersonsRepository.getOfficePersons(
      page: 1,
      limit: 200,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      types: selectedTypes,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingPersons = false;
          _personsErrorMessage = _getErrorMessage(failure);
        });
      },
      (response) {
        setState(() {
          _isLoadingPersons = false;
          _officePersons = response.contacts;
        });
      },
    );
  }

  /// Seçim yoksa boş liste → API'ye types gönderilmez (ofisteki herkes).
  List<int> _getSelectedTypes() {
    if (_selectedTypeCode != null) {
      return [_selectedTypeCode!];
    }
    return const [];
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    setState(() => _searchQuery = value);
    _searchTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadOfficePersons();
    });
  }

  void _onUserTypeChanged(String? value) {
    if (value == null) return;

    int? code;
    if (value != _noTypeSelected) {
      for (final type in _personTypes) {
        if (type.description == value) {
          code = type.code;
          break;
        }
      }
      code ??= _fallbackTypeCodes[value];
    }

    setState(() {
      _selectedUserType = value;
      _selectedTypeCode = code;
    });
    _loadOfficePersons();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else {
      return 'Beklenmeyen bir hata oluştu.';
    }
  }

  Widget _buildMyOfficeCard() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppStatusView.loading(
          title: 'Ofis bilgileri hazırlanıyor.',
          message: 'Ofis kaydınız yüklenirken lütfen bekleyin.',
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppStatusView.error(
          message: _errorMessage,
          onRetry: _loadMyOffice,
        ),
      );
    }

    if (_myOffice == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppStatusView.missing(
          title: 'Ofis bilgisi bulunamadı',
          message: 'Ofis kaydınız şu anda görüntülenemiyor.',
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Send MyOfficeApiModel directly for better data access
            Navigator.pushNamed(
                context, AppRouter.myOfficeEditt,
                arguments: _myOffice!);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profil Resmi (from detail.picture via S3)
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _myOffice!.detail.picture != null &&
                                ImageUtils.isValidS3Id(_myOffice!.detail.picture)
                            ? Image.network(
                                ImageUtils.getCoverImageUrl(_myOffice!.detail.picture),
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[50],
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.business_outlined,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[50],
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.business_outlined,
                                  size: 32,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // İsim ve Bilgiler
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _myOffice!.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _myOffice!.displayAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildProfileInfoItem(
                            "VD:",
                            _myOffice!.displayTaxOffice,
                          ),
                          const SizedBox(height: 4),
                          _buildProfileInfoItem(
                            "VN:",
                            _myOffice!.displayTaxNo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
          return RoleSidebar(currentPage: 'Ofisim');
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
        title: "Ofise Bağlı Kişiler",
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
            child: Stack(
              children: [
                // Sağ üst animasyon
                Positioned(
                  right: -150,
                  top: -150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFE53935).withOpacity(0.05),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Sol alt animasyon
                Positioned(
                  left: -120,
                  bottom: -120,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_rotationController.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value * 0.8,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFE53935).withOpacity(0.05),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Orta animasyon
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 200,
                  top: MediaQuery.of(context).size.height / 2 - 200,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(
                        [_rotationController, _pulseAnimation]),
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * math.pi,
                        child: Transform.scale(
                          scale: _pulseAnimation.value * 0.9,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.07),
                            const Color(0xFFE53935).withOpacity(0.04),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profil Kartı
                      _buildMyOfficeCard(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: "Arayın...",
                                prefixIcon: const Icon(
                                  Icons.search_outlined,
                                  color: Color(0xFFE53935),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.grey[500],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _onSearchChanged('');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  dropdownColor: Colors.white,
                                  value: _dropdownValue,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: _dropdownItems
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _onUserTypeChanged,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              AppRouter.myOfficeAdd,
                            );
                            if (result == true && mounted) {
                              _loadOfficePersons();
                            }
                          },
                          icon: const Icon(Icons.add,
                              size: 30, color: Colors.white),
                          label: const Text("Yeni Kişi Oluştur",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      _buildOfficePersonsList(),
                    ],
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

  List<String> get _dropdownItems {
    final items = <String>[_noTypeSelected];
    if (_personTypes.isNotEmpty) {
      items.addAll(_personTypes.map((t) => t.description));
    } else {
      items.addAll(
        _preferredPersonTypeOrder.where(_fallbackTypeCodes.containsKey),
      );
    }
    return items;
  }

  String get _dropdownValue {
    final items = _dropdownItems;
    if (items.contains(_selectedUserType)) return _selectedUserType;
    return _noTypeSelected;
  }



  Widget _buildOfficePersonsList() {
    if (_isLoadingPersons) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppStatusView.loading(
          title: 'Kişiler hazırlanıyor.',
          message: 'Ofis çalışanları yüklenirken lütfen bekleyin.',
        ),
      );
    }

    if (_personsErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppStatusView.error(
          message: _personsErrorMessage,
          onRetry: _loadOfficePersons,
        ),
      );
    }

    if (_officePersons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: AppStatusView.missing(
          title: 'Ofise bağlı kişi bulunamadı',
          message: 'Bu ofise kayıtlı bir çalışan görünmüyor.',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _officePersons.length,
      itemBuilder: (context, index) {
        final person = _officePersons[index];
        return _buildOfficePersonCard(person);
      },
    );
  }

  Widget _buildOfficePersonCard(OfficePersonsApiModel person) {
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
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Convert to OfficePerson for navigation
            OfficePerson officePerson = OfficePerson(
              id: person.contactNo.toString(),
              firstName: person.name ?? '',
              lastName: person.surname ?? '',
              email: person.displayEmail,
              office: person.connectedContactTitle ?? 'Zecorner Prestige Office',
              personNo: person.contactNo.toString(),
              userType: person.userType,
              status: person.statusText,
              statusCode: person.status,
              registrationDate: '${person.formattedCreatedDate}\n${person.formattedCreatedTime}',
              personCount: person.experience,
              isActive: person.isActive,
            );
            final result = await Navigator.pushNamed(
              context,
              AppRouter.myOfficeEdit,
              arguments: officePerson,
            );
            if (!mounted) return;
            if (result == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kişi güncellendi'),
                  backgroundColor: Color(0xFF128A52),
                ),
              );
            }
            _loadOfficePersons();
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
                      // Profile Image
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: person.profileImageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  person.profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
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
                              person.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              person.displayEmail,
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
                      // Right side - Only Date (Status moved to bottom)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Kayıt Tarihi
                          Text(
                            "Kayıt Tarihi",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            person.formattedCreatedDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            person.formattedCreatedTime,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
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
                              Icons.badge_outlined,
                              "No",
                              person.contactNo.toString(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.person_outline,
                              "Kullanıcı Tipi",
                              person.userType,
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
                              Icons.phone_outlined,
                              "Telefon",
                              person.displayPhone,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCleanInfoCard(
                              Icons.business_outlined,
                              "Bağlı Ofis/Broker",
                              person.connectedContactTitle ?? 'Zecorner Prestige Office',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      
                      // Status Badge - Simple and Clear
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(person.statusBackgroundColorValue),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(person.statusColorValue).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(person.statusColorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              person.statusText,
                              style: TextStyle(
                                color: Color(person.statusColorValue),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Ödeme Yap Button - Full Width Below Status
                      if (person.isPaymentPending) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context, 
                                AppRouter.paymentDetail,
                                arguments: {
                                  'contactNo': person.contactNo,
                                  'contactName': person.fullName,
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.credit_card_rounded,
                              size: 20,
                            ),
                            label: const Text(
                              'Ödeme Yap',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              shadowColor: const Color(0xFFE53935).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
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

  // Profil bilgi öğesi widget'ı
  Widget _buildProfileInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
