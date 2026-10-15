import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zecorner/presentation/widgets/admin-panel/admin_panel_appbar.dart';
import 'package:zecorner/presentation/widgets/role-sidebar/role_sidebar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zecorner/core/cubit/auth_cubit.dart';
import 'package:zecorner/presentation/widgets/animated_background_widget.dart';
import 'package:zecorner/presentation/widgets/navbar/admin_navbar.dart';

// Pending approval person model
class PendingPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String connectedOffice;
  final String status; // 'pending' or 'edit_requested'
  final String? avatarUrl;
  final String? coverLetter; // Ön Yazı
  final String? howDidYouHear; // Firmamızı nereden duydunuz
  final String? references; // Referanslar
  final bool hasContactPermission; // İletişim İzni
  final bool hasCriminalRecord; // Sabıka Kaydı
  final bool hasDiplomaDoc; // Mezuniyet Belgesi
  final bool hasTaxDoc; // Vergi Levhası
  final bool hasProfessionalCert; // Mesleki Yeterlilik Belgesi
  final bool hasPropertyTradeCert; // Taşınmaz Ticareti Yetki Belgesi

  PendingPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.connectedOffice,
    required this.status,
    this.avatarUrl,
    this.coverLetter,
    this.howDidYouHear,
    this.references,
    this.hasContactPermission = false,
    this.hasCriminalRecord = false,
    this.hasDiplomaDoc = false,
    this.hasTaxDoc = false,
    this.hasProfessionalCert = false,
    this.hasPropertyTradeCert = false,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();
}

class PersonApproveScreen extends StatefulWidget {
  const PersonApproveScreen({super.key});

  @override
  State<PersonApproveScreen> createState() => _PersonApproveScreenState();
}

class _PersonApproveScreenState extends State<PersonApproveScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Mock data - Replace with API calls
  List<PendingPerson> _pendingPersons = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock data - Replace with actual API call
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _pendingPersons = [
          PendingPerson(
            id: '1001',
            firstName: 'Ahmet',
            lastName: 'Yılmaz',
            email: 'ahmet.yilmaz@example.com',
            phone: '+90 (532) 123-4567',
            role: 'Danışman',
            connectedOffice: 'Merkez Ofis',
            status: 'pending',
            coverLetter: 'asddsddsasdada',
            howDidYouHear: 'Sosyal medya aracılığıyla',
            references: 'Ali Veli - 0532 123 4567',
            hasContactPermission: false,
            hasCriminalRecord: true,
            hasDiplomaDoc: true,
            hasTaxDoc: true,
            hasProfessionalCert: true,
            hasPropertyTradeCert: false,
          ),
          PendingPerson(
            id: '1002',
            firstName: 'Ayşe',
            lastName: 'Kaya',
            email: 'ayse.kaya@example.com',
            phone: '+90 (533) 987-6543',
            role: 'Broker',
            connectedOffice: 'İstanbul Ofis',
            status: 'pending',
            hasContactPermission: true,
            hasCriminalRecord: true,
            hasDiplomaDoc: true,
            hasTaxDoc: true,
            hasProfessionalCert: true,
            hasPropertyTradeCert: true,
          ),
          PendingPerson(
            id: '1003',
            firstName: 'Mehmet',
            lastName: 'Demir',
            email: 'mehmet.demir@example.com',
            phone: '+90 (534) 555-1234',
            role: 'Danışman',
            connectedOffice: 'Ankara Ofis',
            status: 'edit_requested',
            hasContactPermission: true,
            hasCriminalRecord: false,
            hasDiplomaDoc: false,
            hasTaxDoc: false,
            hasProfessionalCert: false,
            hasPropertyTradeCert: false,
          ),
        ];
        _isLoading = false;
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

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

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _statusLabel(PendingPerson person) {
    return person.status == 'pending' ? 'Onay Bekliyor' : 'Düzenleme İstendi';
  }

  bool _matchesCard(PendingPerson person, String query) {
    bool has(String? value) => _fold(value ?? '').contains(query);
    if (has(person.fullName) ||
        has(person.firstName) ||
        has(person.lastName) ||
        has(person.role) ||
        has(person.email) ||
        has(person.phone) ||
        has(person.connectedOffice) ||
        has(person.id) ||
        has(_statusLabel(person))) {
      return true;
    }

    final queryDigits = _digits(query);
    if (queryDigits.isEmpty) return false;
    return _digits(person.phone).contains(queryDigits) ||
        person.id.contains(queryDigits);
  }

  List<PendingPerson> get _visiblePersons {
    final query = _fold(_searchQuery.trim());
    if (query.isEmpty) return _pendingPersons;
    return _pendingPersons.where((p) => _matchesCard(p, query)).toList();
  }

  void _handleReject(PendingPerson person) {
    // Implement reject API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${person.fullName} reddedildi.'),
          ),
        ],
      ),
              backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
          ),
    );
    
    setState(() {
      _pendingPersons.removeWhere((p) => p.id == person.id);
    });
  }

  void _handleDirectApprove(PendingPerson person) {
    // Implement direct approve - create user immediately
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${person.fullName} direkt olarak kullanıcı oluşturuldu!'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    
    setState(() {
      _pendingPersons.removeWhere((p) => p.id == person.id);
    });
  }

  void _handleApproveWithPayment(PendingPerson person) {
    // Implement approve with payment redirect
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.payment, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${person.fullName} ödeme adımına yönlendiriliyor...'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    
    setState(() {
      _pendingPersons.removeWhere((p) => p.id == person.id);
    });
  }

  void _handleRequestEdit(PendingPerson person) {
    // Request edit from user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('${person.fullName} için düzenleme istendi.'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    
    setState(() {
      _pendingPersons.removeWhere((p) => p.id == person.id);
    });
  }

  void _handleView(PendingPerson person) {
    // Show person details
    _showPersonDetails(person);
  }


  void _showPersonDetails(PendingPerson person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPersonDetailsSheet(person),
    );
  }

  Widget _buildPersonDetailsSheet(PendingPerson person) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Modern Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE53935), Colors.red[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
              children: [
                CircleAvatar(
                      radius: 32,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    person.initials,
                    style: const TextStyle(
                      color: Colors.white,
                          fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                        person.role,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No: ${person.id}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Details Section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(
                    icon: Icons.badge_outlined,
                    title: 'Kişi No',
                    value: person.id,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.email_outlined,
                    title: 'E-posta',
                    value: person.email,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.phone_outlined,
                    title: 'Telefon',
                    value: person.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.business_outlined,
                    title: 'Bağlı Ofis',
                    value: person.connectedOffice,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    icon: Icons.info_outlined,
                    title: 'Durum',
                    value: person.status == 'pending' 
                        ? 'Onay Bekliyor' 
                        : 'Düzenleme İstendi',
                    valueColor: person.status == 'pending' 
                        ? const Color(0xFFFF9800) 
                        : const Color(0xFF2196F3),
                  ),
                  
                  // Ön Yazı
                  if (person.coverLetter != null && person.coverLetter!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Ön Yazı'),
                    const SizedBox(height: 12),
                    _buildTextAreaItem(person.coverLetter!),
                  ],
                  
                  // Firmamızı nereden duydunuz
                  if (person.howDidYouHear != null && person.howDidYouHear!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Firmamızı nereden duydunuz?'),
                    const SizedBox(height: 12),
                    _buildTextAreaItem(person.howDidYouHear!),
                  ],
                  
                  // Referanslar
                  if (person.references != null && person.references!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Referanslar'),
                    const SizedBox(height: 12),
                    _buildTextAreaItem(person.references!),
                  ],
                  
                  // İletişim İzni
                  const SizedBox(height: 24),
                  _buildSectionTitle('İletişim İzni'),
                  const SizedBox(height: 12),
                  _buildPermissionItem(
                    person.hasContactPermission 
                        ? 'İletişim izni verildi.' 
                        : 'İletişim izni verilmedi.',
                    person.hasContactPermission,
                  ),
                  
                  // Belgeler
                  const SizedBox(height: 24),
                  _buildSectionTitle('Belgeler'),
                  const SizedBox(height: 16),
                  _buildDocumentItem('Sabıka Kaydı', person.hasCriminalRecord),
                  _buildDocumentItem('Mezuniyet Belgesi', person.hasDiplomaDoc),
                  _buildDocumentItem('Vergi Levhası', person.hasTaxDoc),
                  _buildDocumentItem('Mesleki Yeterlilik Belgesi', person.hasProfessionalCert),
                  
                  // Taşınmaz Ticareti Yetki Belgesi - Special Warning
                  if (!person.hasPropertyTradeCert) ...[
                    const SizedBox(height: 6),
          Container(
                      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE53935).withOpacity(0.08),
                            const Color(0xFFE53935).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE53935).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
            ),
            child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53935).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Eksik Belge',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lütfen Taşınmaz Ticareti Yetki Belgesi dosyasını yükleyin.',
                      style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons Section - Modern 2x2 Grid
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[100]!,
                  Colors.white,
                ],
                      ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Onayla (Direkt) + Onayla (Ödeme)
                Row(
                  children: [
                    // Button 1: Onayla (Direkt)
                    Expanded(
                      child: _buildCompactButton(
                        icon: Icons.person_add_rounded,
                        label: 'Onayla\n(Direkt)',
                        gradientColors: const [Color(0xFF4CAF50), Color(0xFF43A047)],
                        textColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          _handleDirectApprove(person);
                        },
                  ),
                ),
                const SizedBox(width: 12),
                    // Button 2: Onayla (Ödeme)
                Expanded(
                      child: _buildCompactOutlineButton(
                        icon: Icons.payment_rounded,
                        label: 'Onayla\n(Ödeme)',
                        borderColor: const Color(0xFFE53935),
                        textColor: const Color(0xFFE53935),
                        onTap: () {
                      Navigator.pop(context);
                          _handleApproveWithPayment(person);
                    },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Row 2: Reddet + Düzenleme İste
                Row(
                  children: [
                    // Button 3: Reddet
                    Expanded(
                      child: _buildCompactButton(
                        icon: Icons.cancel_rounded,
                        label: 'Reddet',
                        gradientColors: const [Color(0xFFE53935), Color(0xFFD32F2F)],
                        textColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          _handleReject(person);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Button 4: Düzenleme İste
                    Expanded(
                      child: _buildCompactOutlineButton(
                        icon: Icons.edit_note_rounded,
                        label: 'Düzenleme\nİste',
                        borderColor: const Color(0xFFE53935),
                        textColor: const Color(0xFFE53935),
                        onTap: () {
                          Navigator.pop(context);
                          _handleRequestEdit(person);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53935).withOpacity(0.15),
                  const Color(0xFFE53935).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFE53935),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          return RoleSidebar(currentPage: 'Onay Bekleyen Kişiler');
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
        title: "Onay Bekleyen Kişiler",
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
                // Premium Search Section
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      decoration: InputDecoration(
                        hintText: "Arayın...",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFFE53935).withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                        suffixIcon: _searchController.text.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Color(0xFFE53935),
                                        size: 16,
                                      ),
                                    ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                  ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Pending Persons List
                Expanded(
                  child: _buildPendingPersonsList(),
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

  Widget _buildPendingPersonsList() {
    final visible = _visiblePersons;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
        ),
      );
    }

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Arama kriterlerinize uygun kişi bulunamadı'
                  : 'Onay bekleyen kişi bulunmamaktadır',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Arama terimlerinizi değiştirerek tekrar deneyin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadMockData();
      },
      color: const Color(0xFFE53935),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          return _buildPendingPersonCard(visible[index]);
        },
      ),
    );
  }

  Widget _buildPendingPersonCard(PendingPerson person) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleView(person),
      child: Column(
        children: [
          // Header with Avatar and Name
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE53935), Colors.red[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    person.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              person.role,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                // Person ID Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No: ${person.id}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

              // Contact Information - Compact
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                    _buildCompactInfoRow(
                        Icons.email_outlined,
                        'E-posta',
                        person.email,
                      ),
                      const SizedBox(height: 12),
                    _buildCompactInfoRow(
                        Icons.phone_outlined,
                        'Telefon',
                        person.phone,
                      ),
                      const SizedBox(height: 12),
                    _buildCompactInfoRow(
                        Icons.business_outlined,
                        'Bağlı Ofis',
                        person.connectedOffice,
                      ),
                const SizedBox(height: 16),

                    // Status Badge - Centered
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: person.status == 'pending'
                            ? const Color(0xFFFF9800).withOpacity(0.15)
                            : const Color(0xFF2196F3).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: person.status == 'pending'
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            person.status == 'pending'
                                ? Icons.pending_outlined
                                : Icons.edit_outlined,
                            size: 16,
                            color: person.status == 'pending'
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            person.status == 'pending'
                                ? 'Onay Bekliyor'
                                : 'Düzenleme İstendi',
                            style: TextStyle(
                              color: person.status == 'pending'
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFF2196F3),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE53935).withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAreaItem(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE53935).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.format_quote,
              size: 16,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String text, bool hasPermission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPermission 
              ? [
                  const Color(0xFF4CAF50).withOpacity(0.12),
                  const Color(0xFF4CAF50).withOpacity(0.08),
                ]
              : [
                  Colors.grey[100]!,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPermission 
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasPermission 
                ? const Color(0xFF4CAF50).withOpacity(0.1)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasPermission 
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPermission ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: hasPermission ? const Color(0xFF4CAF50) : Colors.grey[600],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: hasPermission 
                    ? const Color(0xFF2E7D32)
                    : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String label, bool hasDocument) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: hasDocument
              ? [
                  Colors.white,
                  const Color(0xFF4CAF50).withOpacity(0.03),
                ]
              : [
                  Colors.white,
                  Colors.grey[50]!,
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDocument 
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasDocument 
                ? const Color(0xFF4CAF50).withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasDocument
                    ? [
                        const Color(0xFFE53935).withOpacity(0.12),
                        const Color(0xFFE53935).withOpacity(0.08),
                      ]
                    : [
                        Colors.grey[200]!,
                        Colors.grey[150]!,
                      ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_rounded,
              color: hasDocument ? const Color(0xFFE53935) : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: hasDocument ? const Color(0xFF1F2937) : Colors.grey[500],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: hasDocument
                  ? const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    )
                  : LinearGradient(
                      colors: [Colors.grey[300]!, Colors.grey[200]!],
                    ),
              shape: BoxShape.circle,
              boxShadow: hasDocument
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              hasDocument ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Button Helpers for 2x2 Grid
  Widget _buildCompactButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: textColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: 0.3,
                    ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOutlineButton({
    required IconData icon,
    required String label,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: textColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

