import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';
import 'package:zecorner/router/app_router.dart';
import 'package:zecorner/infrastructure/contact/contacts_api_repository.dart';
import 'package:zecorner/infrastructure/contact/contact_api_repository.dart';
import 'package:zecorner/models/contact/contacts_api_model.dart';
import 'package:zecorner/models/contact/refcontact_type_model.dart';
import 'package:zecorner/core/error/failures.dart';
import 'package:zecorner/presentation/widgets/status/app_status_view.dart';

// Person model
class Person {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String personType;
  final String companyName;
  /// Bağlı ofis / üst kişi contact_no (BAMMA tamsayı; metin gönderilmemeli)
  final int? connectedContactNo;
  final String city;
  final String district;
  final String tcNumber;
  final String birthDate;
  final String address;
  final String profession;
  final String experience;
  final String education;
  final bool isActive;
  /// ISO ülke kodu (uyruk — API `nationality`)
  final String nationality;
  /// ISO ülke kodu (adres ülkesi — API `country`)
  final String? country;
  final List<Map<String, dynamic>>? attachments;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.personType,
    required this.companyName,
    this.connectedContactNo,
    required this.city,
    required this.district,
    required this.tcNumber,
    required this.birthDate,
    required this.address,
    required this.profession,
    required this.experience,
    required this.education,
    required this.isActive,
    this.nationality = '',
    this.country,
    this.attachments,
  });

  String get fullName => '$firstName $lastName';
}

// ContactsApiModel'i Person'a dönüştüren extension
extension ContactsApiModelToPerson on ContactsApiModel {
  Person toPerson() {
    final displayCity = (provinceName?.trim().isNotEmpty == true)
        ? provinceName!
        : (city ?? '');
    final displayDistrict = (districtName?.trim().isNotEmpty == true)
        ? districtName!
        : (district ?? '');
    final first = name.trim().isNotEmpty
        ? name
        : (title.trim().isNotEmpty ? title.split(' ').first : '');
    final last = surname.trim().isNotEmpty
        ? surname
        : (title.trim().contains(' ')
            ? title.split(' ').skip(1).join(' ')
            : '');

    return Person(
      id: contactNo.toString(),
      firstName: first,
      lastName: last,
      email: eMail,
      phone: tel,
      personType: typeDescription,
      companyName: connectedContactTitle ?? '',
      connectedContactNo: connectedContact,
      city: displayCity,
      district: displayDistrict,
      tcNumber: tcIdNumber ?? '',
      birthDate: birthday ?? '',
      attachments: detailAttachments,
      address: address ?? '',
      profession: professionDescription ?? '',
      experience: sectoralExperience ?? '',
      education: educationDescription ?? '',
      isActive: status == 1,
      nationality: nationality,
      country: country,
    );
  }
}

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen>
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
  late final AnimationController _pulseController;

  final ContactsApiRepository _contactRepository = ContactsApiRepository();
  final ContactApiRepository _contactTypeRepository = ContactApiRepository();
  List<ContactsApiModel> _contacts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedPersonType = 'Tümü';
  int? _selectedPersonTypeCode;
  int _currentPage = 1;
  int _loadRequestId = 0;
  bool _hasMore = true;
  static const int _pageSize = 200;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _personTypeSearchController =
      TextEditingController();
  List<ContactTypeModel> _contactTypes = [];
  Timer? _searchTimer;

  int get _activeFilterCount => _selectedPersonTypeCode == null ? 0 : 1;

  String _fold(String value) {
    return value
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool _matchesSelectedType(ContactsApiModel contact) {
    if (_selectedPersonTypeCode == null && _selectedPersonType == 'Tümü') {
      return true;
    }
    if (_selectedPersonTypeCode != null &&
        contact.type == _selectedPersonTypeCode) {
      return true;
    }
    return _fold(contact.typeDescription) == _fold(_selectedPersonType);
  }

  /// API + istemci güvenlik süzmesi
  List<ContactsApiModel> get _visibleContacts {
    var list = _contacts.where(_matchesSelectedType).toList();
    final q = _fold(_searchQuery.trim());
    if (q.isEmpty) return list;

    bool has(String? value) => _fold(value ?? '').contains(q);
    list = list.where((c) {
      return has(c.title) ||
          has(c.name) ||
          has(c.surname) ||
          has(c.eMail) ||
          has(c.tel) ||
          c.contactNo.toString().contains(q) ||
          has(c.typeDescription) ||
          has(c.connectedContactTitle) ||
          has(c.provinceName) ||
          has(c.districtName);
    }).toList();
    return list;
  }

  @override
  void initState() {
    super.initState();
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

    // Scroll listener ekle
    _scrollController.addListener(_onScroll);

    // Kullanıcı tiplerini yükle
    _loadPersonTypes();
    
    // API'den contactları yükle
    _loadContacts();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _personTypeSearchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // API: web ile aynı `/api/get-contacts/`
  Future<void> _loadContacts({
    bool refresh = false,
    bool keepPreviousListWhileLoading = false,
  }) async {
    if (_isLoading && !refresh) return;

    if (refresh) {
      _currentPage = 1;
    }

    final requestId = ++_loadRequestId;
    final page = _currentPage;
    final search = _searchQuery.trim();
    final typeCode = _selectedPersonTypeCode;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (refresh) {
        _hasMore = true;
        if (!keepPreviousListWhileLoading) _contacts = [];
      }
    });

    try {
      final result = await _contactRepository.getContacts(
        page: page,
        limit: _pageSize,
        search: search.isNotEmpty ? search : null,
        types: typeCode,
        useGetContacts: true,
      );

      if (!mounted || requestId != _loadRequestId) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = _getErrorMessage(failure);
            if (refresh) _contacts = [];
          });
        },
        (contactsResponse) {
          final incoming = contactsResponse.contacts;
          final existing = _contacts.map((c) => c.contactNo).toSet();
          final fresh = incoming
              .where((c) => !existing.contains(c.contactNo))
              .toList();
          final reported = contactsResponse.totalPages;
          final reachedEnd = incoming.isEmpty ||
              incoming.length < _pageSize ||
              (reported > 0 && page >= reported) ||
              (!refresh && page > 1 && fresh.isEmpty);

          setState(() {
            _isLoading = false;
            _hasMore = !reachedEnd;
            if (refresh || page == 1) {
              _contacts = incoming;
            } else {
              _contacts = [..._contacts, ...fresh];
            }
          });
        },
      );
    } catch (e) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Beklenmeyen hata: $e';
      });
    }
  }

  Future<void> _updateContactStatus(
      ContactsApiModel contact, bool isActive) async {
    final result = await _contactRepository.updateContactStatus(
      contactId: contact.contactNo,
      isActive: isActive,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(failure)),
            backgroundColor: Colors.red,
          ),
        );
      },
      (success) {
        if (success) {
          // Contact durumunu güncelle
          setState(() {
            final index =
                _contacts.indexWhere((c) => c.contactNo == contact.contactNo);
            if (index != -1) {
              _contacts[index] = ContactsApiModel(
                contactNo: contact.contactNo,
                title: contact.title,
                name: contact.name,
                surname: contact.surname,
                type: contact.type,
                tcIdNumber: contact.tcIdNumber,
                taxNo: contact.taxNo,
                taxOffice: contact.taxOffice,
                nationality: contact.nationality,
                sex: contact.sex,
                eMail: contact.eMail,
                tel: contact.tel,
                status: isActive ? 1 : 0,
                updatedAt: contact.updatedAt,
                createdAt: contact.createdAt,
                source: contact.source,
                typeDescription: contact.typeDescription,
                isCompany: contact.isCompany,
                isEmployee: contact.isEmployee,
                isAgency: contact.isAgency,
                birthday: contact.birthday,
                professionCode: contact.professionCode,
                professionDescription: contact.professionDescription,
                educationCode: contact.educationCode,
                educationDescription: contact.educationDescription,
                whereYouHeardUs: contact.whereYouHeardUs,
                sectoralExperience: contact.sectoralExperience,
                picture: contact.picture,
                marketingCommunicationPermission:
                    contact.marketingCommunicationPermission,
                address: contact.address,
                district: contact.district,
                postCode: contact.postCode,
                city: contact.city,
                country: contact.country,
                addressSource: contact.addressSource,
                provinceCode: contact.provinceCode,
                provinceName: contact.provinceName,
                districtCode: contact.districtCode,
                districtName: contact.districtName,
                quarterCode: contact.quarterCode,
                quarterName: contact.quarterName,
                connectedContact: contact.connectedContact,
                connectedContactTitle: contact.connectedContactTitle,
                connectedContactType: contact.connectedContactType,
                connectedContactDescription:
                    contact.connectedContactDescription,
                isCustomer: contact.isCustomer,
                slug: contact.slug,
                detailAttachments: contact.detailAttachments,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Kişi durumu ${isActive ? "aktif" : "pasif"} olarak güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    } else {
      return 'Hata: ${failure.message}';
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      _loadContacts(refresh: true, keepPreviousListWhileLoading: true);
    });
  }

  Future<void> _loadPersonTypes() async {
    try {
      final result = await _contactTypeRepository.getContactTypes();
      result.fold(
        (failure) {
          setState(() => _contactTypes = []);
        },
        (response) {
          final list = response.contactTypes
              .where((t) => t.status == null || t.status == 1)
              .toList();
          list.sort((a, b) => a.description.compareTo(b.description));
          setState(() => _contactTypes = list);
        },
      );
    } catch (_) {
      setState(() => _contactTypes = []);
    }
  }

  void _onScroll() {
    if (_isLoading || !_hasMore || _contacts.isEmpty) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _currentPage++);
    await _loadContacts();
  }

  void _onPersonTypeChanged({int? typeCode, required String typeName}) {
    if (_selectedPersonTypeCode == typeCode &&
        _selectedPersonType == typeName) {
      return;
    }
    setState(() {
      _selectedPersonTypeCode = typeCode;
      _selectedPersonType = typeName;
    });
    _loadContacts(refresh: true);
  }

  void _clearPersonTypeFilter() {
    _onPersonTypeChanged(typeCode: null, typeName: 'Tümü');
  }

  void _showPersonTypePicker() {
    _personTypeSearchController.clear();

    int? draftCode = _selectedPersonTypeCode;
    String draftName = _selectedPersonType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = _fold(_personTypeSearchController.text.trim());
            final visible = query.isEmpty
                ? _contactTypes
                : _contactTypes
                    .where((t) => _fold(t.description).contains(query))
                    .toList();

            Widget typeTile({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              IconData icon = Icons.badge_outlined,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onTap,
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
                            icon,
                            size: 20,
                            color: selected ? _primary : _textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected ? _primary : _textPrimary,
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
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
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
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Kişi Türü',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _personTypeSearchController,
                      onChanged: (v) {
                        setSheetState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Tür ara...',
                        hintStyle: const TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _textMuted,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      children: [
                        if (query.isEmpty)
                          typeTile(
                            label: 'Tümü',
                            selected: draftCode == null,
                            icon: Icons.people_outline_rounded,
                            onTap: () => setSheetState(() {
                              draftCode = null;
                              draftName = 'Tümü';
                            }),
                          ),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'Tür bulunamadı',
                                style: TextStyle(color: _textSecondary),
                              ),
                            ),
                          )
                        else
                          ...visible.map(
                            (type) => typeTile(
                              label: type.description,
                              selected: draftCode == type.code,
                              onTap: () => setSheetState(() {
                                draftCode = type.code;
                                draftName = type.description;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _clearPersonTypeFilter();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: const BorderSide(
                                color: _primary,
                                width: 1.4,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                              _onPersonTypeChanged(
                                typeCode: draftCode,
                                typeName: draftName,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                  ),
                ],
              ),
            );
          },
        );
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
          return RoleSidebar(currentPage: 'Kişiler');
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
        title: "Kişiler",
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
                Expanded(child: _buildPersonList()),
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
                      hintText: 'Ad, e-posta, ofis ara...',
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
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
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
                      onTap: _showPersonTypePicker,
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
                  onTap: () {
                    Navigator.pushNamed(context, AppRouter.addPerson);
                  },
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
          if (_selectedPersonType != 'Tümü') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(
                  _selectedPersonType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
                avatar: const Icon(
                  Icons.badge_rounded,
                  size: 16,
                  color: _primary,
                ),
                deleteIcon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _primary,
                ),
                onDeleted: _clearPersonTypeFilter,
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

  Widget _buildPersonList() {
    final visible = _visibleContacts;

    if (_isLoading && (_contacts.isEmpty || visible.isEmpty)) {
      return const AppStatusView.loading(
        title: 'Kişiler hazırlanıyor.',
        message: 'Kişi listesi yüklenirken lütfen bekleyin.',
      );
    }

    if (_errorMessage.isNotEmpty && _contacts.isEmpty) {
      return AppStatusView.error(
        message: _errorMessage,
        onRetry: () => _loadContacts(refresh: true),
      );
    }

    if (visible.isEmpty) {
      return AppStatusView.missing(
        title: _searchQuery.isNotEmpty || _selectedPersonType != 'Tümü'
            ? 'Kişi bulunamadı'
            : 'Kişi kaydı bulunamadı',
        message: _searchQuery.isNotEmpty || _selectedPersonType != 'Tümü'
            ? 'Filtreyi değiştirip tekrar deneyin.'
            : 'Henüz listelenecek bir kişi kaydı yok.',
        icon: Icons.badge_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          _loadContacts(refresh: true, keepPreviousListWhileLoading: true),
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
          return _buildPersonCard(visible[index]);
        },
      ),
    );
  }

  Widget _buildPersonCard(ContactsApiModel contact) {
    final locationParts = <String>[
      if ((contact.provinceName ?? '').trim().isNotEmpty)
        contact.provinceName!.trim(),
      if ((contact.districtName ?? '').trim().isNotEmpty)
        contact.districtName!.trim(),
    ];
    final location = locationParts.isEmpty
        ? 'Konum yok'
        : locationParts.join(' / ');

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
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.editPerson,
              arguments: contact.toPerson(),
            );
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
                            contact.title,
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
                            'Kişi No: ${contact.contactNo}',
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
                      onTap: () =>
                          _updateContactStatus(contact, !contact.isActive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: contact.isActive
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: contact.isActive
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
                                color: contact.isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              contact.isActive ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: contact.isActive
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
                              Icons.business_outlined,
                              'Bağlı Broker',
                              contact.connectedContactTitle ?? 'Belirtilmemiş',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoTile(
                              Icons.place_outlined,
                              'İl / İlçe',
                              location,
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
                              Icons.badge_outlined,
                              size: 16,
                              color: _primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contact.typeDescription,
                                style: const TextStyle(
                                  color: _primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoTile(
                              Icons.email_outlined,
                              'E-posta',
                              contact.displayEmail,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoTile(
                              Icons.phone_outlined,
                              'Telefon',
                              contact.displayPhone,
                            ),
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
